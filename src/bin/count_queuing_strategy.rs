#[macro_use]
extern crate afl;
extern crate servo;

use std::sync::OnceLock;

use servo_js_fuzz::{ServoTest, run_script_on};
thread_local! {
  static SERVO_LOCK: OnceLock<ServoTest> = OnceLock::new();
}

const SCRIPT_FORMAT: &str = r#"
async function target(input) {
    const queueingStrategy = new ByteLengthQueuingStrategy({ highWaterMark: input });

    const readableStream = new ReadableStream(
        {
            start(controller) {
            controller.enqueue(new TextEncoder().encode("fixed_text"));
            controller.close();
            }
        },
        queueingStrategy,
    );
    for await (const chunk of readableStream) {
        const size = queueingStrategy.size(chunk);
    }
}
target(%input%);
"#;

fn main() {
    fuzz!(|data: &[u8]| {
        let input_data = u64::from_le_bytes(data.try_into().expect("Wrong length"));
        SERVO_LOCK.with(|cell| {
            let servo_test = cell.get_or_init(|| ServoTest::new());
            let script = SCRIPT_FORMAT.replace("%input%", &format!("{:?}", input_data));
            let _ = run_script_on(servo_test, &script);
        });
    });
}
