// THE PACK TOPS GO BLANK (owner, 2026-10-19: "the set name baked onto the
// crinkled top of the 19 sets' pack images comes off; the renderer leaves it
// blank and the PC session re-renders and re-uploads").
//
//   * tools/pack-sprites/render.ps1 leaves the top seal blank unless -Title is
//     passed (PackRender3D draws no title for an empty string). Read statically:
//     PowerShell and System.Drawing do not run here.
//   * tools/pack-sprites/write-ids.js MERGES a partial upload (the 57 re-rendered
//     sprites) into build/pack-art/ids.json: it RUNS here in a scratch tree, and
//     must keep the set icons, rarity icons and case art, replace the 57, and
//     list the new ids for sharing. It used to rebuild the file from the upload
//     alone, which refused a partial upload and dropped `cases` on a full one.
//   * The Cursor job for the owner's PC is written (tools/cursor/tasks/pack-tops.md).
//
// Fails on 3863d14.
//
//   node tools/verify/pack-tops.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => (fs.existsSync(path.join(ROOT, p)) ? fs.readFileSync(path.join(ROOT, p), "utf8").split("\r\n").join("\n") : "");
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
console.log("pack-tops: blank pack tops by default; a partial re-upload keeps every other id");

const ps = read("tools/pack-sprites/render.ps1").replace(/^\s*#[^\n]*$/gm, "");
const cs = read("tools/pack-sprites/PackRender3D.cs");
check(/\[switch\]\$Title\b/.test(ps), "render.ps1 has a -Title switch (off unless passed)");
check(/\$sealText = ""\s*if \(\$Title\) \{ \$sealText = \[string\]\$job\.title \}/.test(ps)
  && /\[PackRender3D\]::Render\([^)]*\$sealText\)/.test(ps) && !/::Render\([^)]*\$job\.title/.test(ps),
  "...and hands the renderer an empty title unless it is set (the name is not baked on by default)");
check(/static void BuildTitleMask\(string text\)\s*\{\s*mFill = null; mLine = null;\s*if \(string\.IsNullOrEmpty\(text\)\) return;/.test(cs)
  && /if \(!face && y > 0 && mFill != null\)/.test(cs),
  "PackRender3D prints nothing on the seal for an empty title");
const task = read("tools/cursor/tasks/pack-tops.md");
check(/render\.ps1/.test(task) && /write-ids\.js/.test(task) && /gen-pack-art\.js/.test(task) && /upload_image/.test(task)
  && /share-list-new\.txt/.test(task) && !/render\.ps1" -Title/.test(task),
  "the Cursor job re-renders without -Title, uploads, records the ids and regenerates MinePackArt only once they load");

// write-ids.js, run in a scratch tree against a copy of the real ids.json.
const ids = JSON.parse(read("build/pack-art/ids.json") || "{}");
check(Object.keys(ids.packs || {}).length === 19 && Object.keys(ids.cases || {}).length > 0, "read build/pack-art/ids.json");
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "mfc-pack-tops-"));
try {
  fs.mkdirSync(path.join(tmp, "tools", "pack-sprites"), { recursive: true });
  fs.copyFileSync(path.join(ROOT, "tools/pack-sprites/write-ids.js"), path.join(tmp, "tools/pack-sprites/write-ids.js"));
  fs.mkdirSync(path.join(tmp, "build", "pack-art"), { recursive: true });
  fs.writeFileSync(path.join(tmp, "build/pack-art/ids.json"), JSON.stringify(ids, null, 2));
  for (const d of ["art/pack-sprites", "art/icons/sets", "art/icons/rarity"]) fs.mkdirSync(path.join(tmp, d), { recursive: true });
  const lines = [];
  let n = 0;
  for (const [set, bands] of Object.entries(ids.packs)) {
    for (const band of Object.keys(bands)) {
      fs.writeFileSync(path.join(tmp, `art/pack-sprites/${set}Pack_${band}.png`), "");
      n += 1;
      lines.push(JSON.stringify({ [`http://localhost:7421/art/pack-sprites/${set}Pack_${band}.png`]: `rbxassetid://9${String(n).padStart(13, "0")}` }));
    }
  }
  for (const set of Object.keys(ids.sets)) fs.writeFileSync(path.join(tmp, `art/icons/sets/${set}SetIcon.png`), "");
  for (const r of Object.keys(ids.rarity)) fs.writeFileSync(path.join(tmp, `art/icons/rarity/Rarity_${r}.png`), "");
  let out = "", code = 0;
  try {
    out = execFileSync("node", [path.join(tmp, "tools/pack-sprites/write-ids.js")], { input: lines.join("\n"), encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
  } catch (e) {
    code = e.status || 1;
    out = String(e.stdout || "") + String(e.stderr || "");
  }
  check(code === 0 && /84 files, 84 distinct ids, 57 new/.test(out), "a 57-sprite re-upload is accepted", out.trim().split("\n")[0]);
  const after = code === 0 ? JSON.parse(fs.readFileSync(path.join(tmp, "build/pack-art/ids.json"), "utf8")) : {};
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  check(same(after.cases, ids.cases) && same(after.sets, ids.sets) && same(after.rarity, ids.rarity),
    "...the case art, set icons and rarity icons keep their ids");
  let replaced = 0;
  for (const [set, bands] of Object.entries(after.packs || {})) {
    for (const [b, id] of Object.entries(bands)) if (/^rbxassetid:\/\/9/.test(id) && id !== ids.packs[set][b]) replaced++;
  }
  check(replaced === 57, "...the 57 pack sprites take their new ids", String(replaced));
  const share = path.join(tmp, "build/pack-art/share-list-new.txt");
  const shareLines = fs.existsSync(share) ? fs.readFileSync(share, "utf8").trim().split("\n").filter((l) => !l.startsWith("#")) : [];
  check(shareLines.length === 57 && shareLines.every((l) => /^9\d+\t\w+Pack_/.test(l)), "...and the 57 to share are listed", String(shareLines.length));
  // A file with no id anywhere is still refused.
  fs.writeFileSync(path.join(tmp, "art/pack-sprites/NewSetPack_1-2star.png"), "");
  let refused = false;
  try {
    execFileSync("node", [path.join(tmp, "tools/pack-sprites/write-ids.js")], { input: lines.join("\n"), encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] });
  } catch (e) {
    refused = /no id for:[\s\S]*NewSetPack_1-2star/.test(String(e.stderr || ""));
  }
  check(refused, "a sprite with no id, old or new, is still refused");
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}

console.log(fail === 0 ? ">>> pack-tops OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
