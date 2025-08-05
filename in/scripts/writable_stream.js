function target(input) {
    const writableStream = new WritableStream({
        write(chunk) {
            let x = chunk;
            console.log(x);
        },
    });

    const writer = writableStream.getWriter();

    writer.write(input)
        .then(() => writer.close())
        .catch(err => {
           new Error(`Sink error: ${err}`);
        });
}
target("input")