const readable = new ReadableStream({
  start(controller) {
    controller.enqueue("input");
    controller.close();
  }
});

const toUpperCase = new TransformStream({
  transform(chunk, controller) {
    controller.enqueue(chunk.toUpperCase());
  }
});

const writable = new WritableStream({
  write(chunk) {
    console.log("Received chunk:", chunk);
  }
});

readable.pipeThrough(toUpperCase).pipeTo(writable).catch(console.error);
