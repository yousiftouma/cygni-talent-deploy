const http = require("http");

const port = process.env.PORT ?? 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, "OK");
  res.write(Buffer.from("Hello World 3!"));
  res.end();
});

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

server.on("error", (err) => {
  console.error(err);
});
