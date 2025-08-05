const list = document.createElement("ul");
document.body.appendChild(list);

function sendMessage(message, writableStream) {
  const defaultWriter = writableStream.getWriter();
  const encoder = new TextEncoder();
  const encoded = encoder.encode(message);

  let chain = Promise.resolve();

  encoded.forEach(chunk => {
    chain = chain
      .then(() => defaultWriter.ready)
      .then(() => defaultWriter.write(chunk))
      .then(() => {
        console.log("Chunk written to sink.");
      });
  });

  chain
    .then(() => defaultWriter.ready)
    .then(() => defaultWriter.close())
    .then(() => {
      console.log("All chunks written");
    })
    .catch(err => {
      console.log("Error:", err);
    });
}

const decoder = new TextDecoder("utf-8");
const queuingStrategy = new CountQueuingStrategy({ highWaterMark: 1 });
let result = "";

const writableStream = new WritableStream(
  {
    write(chunk) {
      return new Promise((resolve) => {
        const buffer = new ArrayBuffer(1);
        const view = new Uint8Array(buffer);
        view[0] = chunk;
        const decoded = decoder.decode(view, { stream: true });

        const listItem = document.createElement("li");
        listItem.textContent = `Chunk decoded: ${decoded}`;
        list.appendChild(listItem);

        result += decoded;
        resolve();
      });
    },
    close() {
      const listItem = document.createElement("li");
      listItem.textContent = `[MESSAGE RECEIVED] ${result}`;
      list.appendChild(listItem);
    },
    abort(err) {
     new Error(`Sink error: ${err}`);
    },
  },
  queuingStrategy
);

sendMessage("input", writableStream);