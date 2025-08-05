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
            readNext();
        });
    }

    readNext();
}
target(1024);
