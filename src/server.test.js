const createServer = require("./server");
const supertest = require("supertest");
const assert = require("assert");

describe("server", () => {
  it("should respond 200 with Hello World", async () => {
    const server = createServer();
    const response = await supertest(server).get("/").expect(200);

    assert.match(response.text, /^Hello World/);
  });
});
