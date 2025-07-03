/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

use servo::{
    EventLoopWaker, JSValue, JavaScriptEvaluationError, LoadStatus, RenderingContext, Servo,
    ServoBuilder, SoftwareRenderingContext, WebView, WebViewBuilder, WebViewDelegate,
};
use std::cell::{Cell, RefCell};
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use anyhow::Error;
use dpi::PhysicalSize;

pub struct ServoTest {
    servo: Servo,
}

impl Drop for ServoTest {
    fn drop(&mut self) {
        self.servo.start_shutting_down();
        while self.servo.spin_event_loop() {
            std::thread::sleep(Duration::from_millis(1));
        }
        self.servo.deinit();
    }
}

impl ServoTest {
    pub fn new() -> Self {
        let rendering_context = Rc::new(
            SoftwareRenderingContext::new(PhysicalSize {
                width: 500,
                height: 500,
            })
            .expect("Could not create SoftwareRenderingContext"),
        );
        assert!(rendering_context.make_current().is_ok());

        #[derive(Clone)]
        struct EventLoopWakerImpl(Arc<AtomicBool>);
        impl EventLoopWaker for EventLoopWakerImpl {
            fn clone_box(&self) -> Box<dyn EventLoopWaker> {
                Box::new(self.clone())
            }

            fn wake(&self) {
                self.0.store(true, Ordering::Relaxed);
            }
        }

        let user_event_triggered = Arc::new(AtomicBool::new(false));
        let servo = ServoBuilder::new(rendering_context.clone())
            .event_loop_waker(Box::new(EventLoopWakerImpl(user_event_triggered)))
            .build();
        Self { servo }
    }

    pub fn servo(&self) -> &Servo {
        &self.servo
    }

    /// Spin the Servo event loop until one of:
    ///  - The given callback returns `Ok(false)`.
    ///  - The given callback returns an `Error`, in which case the `Error` will be returned.
    ///  - Servo has indicated that shut down is complete and we cannot spin the event loop
    ///    any longer.
    // The dead code exception here is because not all test suites that use `common` also
    // use `spin()`.
    #[allow(dead_code)]
    pub fn spin(&self, callback: impl Fn() -> Result<bool, Error> + 'static) -> Result<(), Error> {
        let mut keep_going = true;
        while keep_going {
            std::thread::sleep(Duration::from_millis(1));
            if !self.servo.spin_event_loop() {
                return Ok(());
            }
            let result = callback();
            match result {
                Ok(result) => keep_going = result,
                Err(error) => return Err(error),
            }
        }

        Ok(())
    }
}

pub fn evaluate_javascript(
    servo_test: &ServoTest,
    webview: WebView,
    script: &str,
) -> Result<JSValue, JavaScriptEvaluationError> {
    let load_webview = webview.clone();
    let _ = servo_test.spin(move || Ok(load_webview.load_status() != LoadStatus::Complete));

    let saved_result = Rc::new(RefCell::new(None));
    let callback_result = saved_result.clone();
    webview.evaluate_javascript(script.to_string(), move |result| {
        *callback_result.borrow_mut() = Some(result)
    });

    let spin_result = saved_result.clone();
    let _ = servo_test.spin(move || Ok(spin_result.borrow().is_none()));

    (*saved_result.borrow())
        .clone()
        .expect("Should have waited until value available")
}

#[derive(Default)]
pub struct WebViewDelegateImpl {
    url_changed: Cell<bool>,
}

impl WebViewDelegateImpl {
    pub fn reset(&self) {
        self.url_changed.set(false);
    }
}

impl WebViewDelegate for WebViewDelegateImpl {
    fn notify_url_changed(&self, _webview: servo::WebView, _url: url::Url) {
        self.url_changed.set(true);
    }
}

pub fn run_script_on(servo_test: &ServoTest, script: &str) -> Result<JSValue, JavaScriptEvaluationError> {
    let delegate = Rc::new(WebViewDelegateImpl::default());
    let webview = WebViewBuilder::new(servo_test.servo())
        .delegate(delegate.clone())
        .build();
    evaluate_javascript(servo_test, webview.clone(), &script)
}
