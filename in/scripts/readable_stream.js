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
            readNext();
        });
    }

    readNext();
}
target("input");
