const readableStream = new ReadableStream({
  start(controller) {
    this.current = 1;
  },
  pull(controller) {
    if (this.current <= 5) {
      controller.enqueue(this.current);
      this.current++;
    } else {
      controller.close();
    }
  },
  cancel(reason) {
    console.log('Readable stream cancelled:', reason);
  }
});

const [branch1, branch2] = readableStream.tee();

const rawLogger = new WritableStream({
  write(chunk) {
    console.log(`[RAW] Value from stream: ${chunk}`);
  },
  close() {
    console.log('[RAW] Stream complete.');
  }
});
branch1.pipeTo(rawLogger);

const transformStream = new TransformStream({
  async transform(chunk, controller) {
    await new Promise(res => setTimeout(res, 500)); 
    controller.enqueue(chunk * chunk);
  },
  flush(controller) {
    console.log('[TRANSFORM] Done transforming');
  }
});

const writableStream = new WritableStream({
  write(chunk) {
    console.log(`[OUTPUT] Squared value: ${chunk}`);
  },
  close() {
    console.log('[OUTPUT] Writable stream closed.');
  }
});

branch2
  .pipeThrough(transformStream)
  .pipeTo(writableStream)
  .catch(err => console.error('Pipeline error:', err));
