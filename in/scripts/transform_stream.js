const transformStream = new TransformStream({
  transform(chunk, controller) {
    controller.enqueue(chunk.toString().toUpperCase());
  }
});

const writer = transformStream.writable.getWriter();
const reader = transformStream.readable.getReader();

writer.write("input")
  .then(() => writer.write("world"))
  .then(() => writer.close())
  .then(function read() {
    return reader.read().then(({ done, value }) => {
      if (done) return;
      console.log(value);
      return read();
    });
});