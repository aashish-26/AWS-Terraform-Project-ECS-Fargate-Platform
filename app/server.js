const http = require("http");

const port = process.env.PORT || 8080;

const requestHandler = (req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok" }));
    return;
  }

  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from Azure container demo!");
};

const server = http.createServer(requestHandler);

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});


