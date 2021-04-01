const createServer = require("./server");

const port = process.env.PORT ?? 8080;
const buildNumber = process.env.BUILD_NUMBER ?? "n/a";

const server = createServer({ buildNumber });

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
