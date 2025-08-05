function target(input) {
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
    const reader = readableStream.getReader({ mode: "byob" });

    let bytesReceived = 0;
    let offset = 0;

    function processText({ done, value }) {
        if (done) return;

        buffer = value.buffer;
        offset += value.byteLength;
        bytesReceived += value.byteLength;

        return reader
            .read(new Uint8Array(buffer, offset, buffer.byteLength - offset))
            .then(processText);
    }

    reader
        .read(new Uint8Array(buffer, offset, buffer.byteLength - offset))
        .then(processText);
}
target("input");
