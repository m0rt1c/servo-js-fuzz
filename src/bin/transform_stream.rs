#[macro_use]
extern crate afl;
extern crate servo;

use std::sync::OnceLock;

use servo_js_fuzz::{ServoTest, run_script_on};
thread_local! {
  static SERVO_LOCK: OnceLock<ServoTest> = OnceLock::new();
}

const SCRIPT_FORMAT: &str = r#"
const transformStream = new TransformStream({
  transform(chunk, controller) {
    controller.enqueue(chunk.toString().toUpperCase());
  }
});

const writer = transformStream.writable.getWriter();
const reader = transformStream.readable.getReader();

writer.write("%input%")
  .then(() => writer.write("world"))
  .then(() => writer.close())
  .then(function read() {
    return reader.read().then(({ done, value }) => {
      if (done) return;
      console.log(value);
      return read();
    });
});
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
