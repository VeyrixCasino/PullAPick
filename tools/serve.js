// Static server for the tools/ pages, so they can be opened and DRIVEN rather
// than snapshotted.
//
// Owner, 2026-10-05: "make mine map and tool actuaually work so i can see what
// your talking about with this change". A file:// page renders but cannot be
// clicked, typed into or read by the preview tooling, so every claim about
// those pages was unverifiable. This makes them real pages on localhost.
//
// Started via .claude/launch.json, never by hand.
const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const PORT = Number(process.env.PORT || 7421);

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".ico": "image/x-icon",
};

http.createServer((req, res) => {
  let rel = decodeURIComponent(req.url.split("?")[0]);
  if (rel === "/") rel = "/tools/index.html";

  // Stay inside the repo. A served path that escapes ROOT is refused rather
  // than normalised into something surprising.
  const full = path.join(ROOT, rel);
  if (!full.startsWith(ROOT)) {
    res.writeHead(403).end("outside the repo");
    return;
  }
  fs.readFile(full, (err, buf) => {
    if (err) {
      res.writeHead(404, { "content-type": "text/plain" });
      res.end("not found: " + rel);
      console.log("404 " + rel);
      return;
    }
    res.writeHead(200, {
      "content-type": TYPES[path.extname(full).toLowerCase()] || "application/octet-stream",
      // These pages are regenerated constantly; a cached copy is a lie.
      "cache-control": "no-store",
    });
    res.end(buf);
    console.log("200 " + rel);
  });
}).listen(PORT, () => console.log("tools server on http://localhost:" + PORT));
