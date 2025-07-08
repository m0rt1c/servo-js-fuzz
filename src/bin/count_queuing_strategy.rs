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
    const queueingStrategy = new ByteLengthQueuingStrategy({ highWaterMark: input });

    const readableStream = new ReadableStream(
        {
            start(controller) {
                controller.enqueue(new TextEncoder().encode("fixed_text"));
                controller.close();
            }
        },
        queueingStrategy
    );

    const reader = readableStream.getReader();

    function readNext() {
        reader.read().then(({ done, value }) => {
            if (done) return;
            const size = queueingStrategy.size(value);
            // Do something with size if needed
            readNext();
        });
    }

    readNext();
}
target(%input%);
"#;

fn main() {
    fuzz!(|data: &[u8]| {
        if let Ok(number) = data.try_into() {
            let input_data = u64::from_le_bytes(number);
            SERVO_LOCK.with(|cell| {
                let servo_test = cell.get_or_init(|| ServoTest::new());
                let script = SCRIPT_FORMAT.replace("%input%", &format!("{:?}", input_data));
                let _ = run_script_on(servo_test, &script);
            });
        }
    });
}
