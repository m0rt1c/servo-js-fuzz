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
target(1024, "input");