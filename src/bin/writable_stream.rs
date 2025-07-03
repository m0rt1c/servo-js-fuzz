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
    const writableStream = new WritableStream(
    {
        write(chunk) {
            let x = chunk;
            console.log(x);
        },
    },
    );

    const writer = writableStream.getWriter();

    try {
    writer.write(input);

    await writer.close();
    } catch (error) {
    }
}
target("%input%)")
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
