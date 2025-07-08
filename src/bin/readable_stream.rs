#[macro_use]
extern crate afl;
extern crate servo;

use std::sync::OnceLock;

use servo_js_fuzz::{ServoTest, run_script_on};
thread_local! {
  static SERVO_LOCK: OnceLock<ServoTest> = OnceLock::new();
}

const SCRIPT_FORMAT: &str = r#"
function target(input) {
    const readableStream = new ReadableStream({
        start(controller) {
            controller.enqueue(new TextEncoder().encode(input));
            controller.close();
        }
    });

    const reader = readableStream.getReader();

    function readNext() {
        reader.read().then(({ done, value }) => {
            if (done) return;
            // Process `value` here if needed
            readNext(); // Continue reading if there are more chunks
        });
    }

    readNext();
}
target("%input%")
"#;

fn main() {
    fuzz!(|data: &[u8]| {
        if let Ok(input_data) = std::str::from_utf8(data) {
            SERVO_LOCK.with(|cell| {
                let servo_test = cell.get_or_init(|| ServoTest::new());
                let script = SCRIPT_FORMAT.replace("%input%", input_data);
                let _ = run_script_on(servo_test, &script);
            });
        }
    });
}
