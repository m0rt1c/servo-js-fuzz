function target(input) {
    const queueingStrategy = new CountQueuingStrategy({ highWaterMark: input });

    const writableStream = new WritableStream(
        {
            write(chunk) {
                console.log(chunk);
            },
            close() {
            },
            abort(err) {
                new Error(`Sink error: ${err}`);
            },
        },
        queueingStrategy
    );

    const size = queueingStrategy.size(); // Note: size expects an argument
}
target(1024);