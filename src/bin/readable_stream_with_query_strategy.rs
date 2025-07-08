#[macro_use]
extern crate afl;
extern crate servo;
use std::sync::OnceLock;
use servo_js_fuzz::{ServoTest, run_script_on};
use std::str;
thread_local! {
    static SERVO_LOCK: OnceLock<ServoTest> = OnceLock::new();
}

const SCRIPT_FORMAT: &str = r#"
function target(input, inputStr) {
    try {
        const queueingStrategy = new ByteLengthQueuingStrategy({ highWaterMark: input });

        const readableStream = new ReadableStream(
            {
                start(controller) {
                    const text = inputStr.length > 0 ? inputStr : "fixed_text";
                    controller.enqueue(new TextEncoder().encode(text));
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
                
                readNext();
            });
        }

        readNext();
    } catch (e) {
        console.error("Error:", e);
    }
}
target(%input_number%, "%input_str%");
"#;

fn main() {
    fuzz!(|data: &[u8]| {
        if data.len() >= 8 {
            let number = &data[0..8];
            let input_data = u64::from_le_bytes(number.try_into().unwrap());
            let input_str = str::from_utf8(&data[8..]).unwrap_or("");

            SERVO_LOCK.with(|cell| {
                let servo_test = cell.get_or_init(|| ServoTest::new());
                let script = SCRIPT_FORMAT
                    .replace("%input_number%", &format!("{:?}", input_data))
                    .replace("%input_str%", input_str);
                
                match run_script_on(servo_test, &script) {
                    Ok(_) => {},
                    Err(e) => eprintln!("Script execution error: {:?}", e),
                }
            });
        }
    });
}