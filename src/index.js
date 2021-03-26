const http = require("http");

const port = process.env.PORT ?? 8080;

const server = http.createServer((req, res) => {
  console.log(`Received request ${req.method.toUpperCase()} ${req.url}`);
  res.writeHead(200, "OK");
  res.write(Buffer.from("Hello World 10!"));
  res.end();
});

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

server.on("error", (err) => {
  console.error(err);
});
