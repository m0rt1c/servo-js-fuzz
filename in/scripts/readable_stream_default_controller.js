function target(input) {
    const stream = new ReadableStream({
        start(controller) {
            controller.enqueue(new TextEncoder().encode(input));
            controller.close();
        },
        pull(controller) {
        },
        cancel() {
        },
    });

    const reader = stream.getReader();

    reader.read().then(({ value, done }) => {
        if (done) {
            console.log("Stream finished.");
            return;
        }

        const text = new TextDecoder().decode(value);
        console.log("Read value:", text);
    });
}
target("input")