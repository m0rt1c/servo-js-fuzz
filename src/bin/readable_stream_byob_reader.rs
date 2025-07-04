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
    const readableStream = new ReadableStream(
        {
            type: "bytes",
            start(controller) {
            controller.enqueue(new TextEncoder().encode(input));
            controller.close();
            }
        },
        { type: "bytes" }
    );

    let buffer = new ArrayBuffer(200);
    const reader = readableStream.getReader({ mode: "byob" }, buffer);

    let bytesReceived = 0;
    let offset = 0;

    reader
        .read(new Uint8Array(buffer, offset, buffer.byteLength - offset))
        .then(function processText({ done, value }) {
        
        if (done) {
            return;
        }

        buffer = value.buffer;
        offset += value.byteLength;
        bytesReceived += value.byteLength;

        return reader
            .read(new Uint8Array(buffer, offset, buffer.byteLength - offset))
            .then(processText);
        });

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
