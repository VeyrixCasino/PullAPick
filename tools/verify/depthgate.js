// YOU CANNOT BUY DEPTH BY BREAKING ONE BLOCK.
//
// Owner, 2026-10-06: the chunk gate is "to ensure hackers dont break one block
// in every chunk and unlock the depth points".
//
// The hole was real and total. MineDigAuth.canDigLayer ends in an unconditional
// `return true` -- every check above it is dead code -- so a single block broken
// at layer 5000 credited depth 5000 to anyone who could reach it. That ending is
// deliberate for MINING, because refusing a swing only means standing in rock
// that will not break and stops no exploit. The mistake was using the same
// answer for CREDITING.
//
// canCreditDepth is the strict half, and this pins both directions: the cheat
// must fail, and ordinary digging must not. A gate that refuses honest players
// gets turned off in a week, so the second half matters as much as the first.
//
// Run: node tools/verify/depthgate.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const AUTH = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineDigAuth.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("depthgate: depth credit is earned, not reached");

ok(/function MineDigAuth\.canCreditDepth\(/.test(AUTH), "canCreditDepth exists");
ok(/MineConfig\.DIG_CHUNK_LAYERS\s*=\s*\d+/.test(CFG), "DIG_CHUNK_LAYERS is configured");

//[[ The credit site must consult it. Checking the CALL and not just the
// function's existence, because a gate nothing calls is the state this started
// in -- canDigLayer was full of checks that could never run. ]]
ok(/Dig\.Auth\.canCreditDepth\(p, zone\.id, layer\)/.test(SRV),
  "the credit path calls canCreditDepth",
  "a gate nothing calls is how this bug existed in the first place");
ok(/canDigLayer\(p, zone\.id, layer\)\s*\n?\s*and Dig\.Auth\.canCreditDepth/.test(SRV)
  || /canDigLayer[\s\S]{0,120}canCreditDepth/.test(SRV),
  "it gates the same branch that awards deepest");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> depthgate OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const lines = AUTH.split("\n");
const block = (src, head, close) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};
const chunkN = /MineConfig\.DIG_CHUNK_LAYERS\s*=\s*(\d+)/.exec(CFG)[1];
const leadN = /MineDepth\.DIG_LEAD\s*=\s*(\d+)/.exec(
  Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineDepth.luau")))[1];

const harness = `local C = { DIG_CHUNK_LAYERS = ${chunkN} }
local Depth = { DIG_LEAD = ${leadN} }
local MineDigAuth = {}
${block(AUTH, "local function deepestOf(", "end")}
${block(AUTH, "function MineDigAuth.depthPassOf(", "end")}
${block(AUTH, "function MineDigAuth.canCreditDepth(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end
local function profile(deepest, pass)
	return { deepest = { meadow = deepest }, depthPass = pass and { meadow = pass } or nil }
end

-- ------------------------------------------------- the exploit must fail --
check("a fresh player cannot credit depth 5000 from one block",
	not MineDigAuth.canCreditDepth(profile(0), "meadow", 5000))
check("...nor 500", not MineDigAuth.canCreditDepth(profile(0), "meadow", 500))
check("...nor the floor of the second chunk",
	not MineDigAuth.canCreditDepth(profile(0), "meadow", ${chunkN} * 2))

check("one layer past the step allowance is refused",
	not MineDigAuth.canCreditDepth(profile(0), "meadow", ${leadN} + 1))

-- The patient exploit, and the one the chunk rule exists for: don't leap, hop
-- by exactly the largest step allowed, over and over, breaking one block per
-- hop. The step rule alone permits this forever -- 8 layers of credit per block
-- broken. The chunk floor is what stops it, so this must stall, and it must
-- stall at a chunk boundary rather than anywhere else.
do
	local deepest, blocks, stop = 0, 0, nil
	for _ = 1, 400 do
		local want = deepest + ${leadN}
		if MineDigAuth.canCreditDepth(profile(deepest), "meadow", want) then
			deepest = want
			blocks += 1
		else
			stop = want
			break
		end
	end
	check("hopping down by the full step allowance stalls at a chunk floor",
		stop ~= nil and deepest < ${chunkN},
		string.format("%d blocks bought %d layers, then refused at %s",
			blocks, deepest, tostring(stop)))
	local _, why, need = MineDigAuth.canCreditDepth(profile(deepest), "meadow", stop)
	check("...and the refusal says which floor must be cleared first",
		why == "chunk_locked" and need == ${chunkN},
		string.format("%s, floor %s", tostring(why), tostring(need)))
end

-- ------------------------------------------- ordinary digging must pass --
do
	local deepest, blocked = 0, nil
	for layer = 1, 600 do
		if MineDigAuth.canCreditDepth(profile(deepest), "meadow", layer) then
			if layer > deepest then deepest = layer end
		else
			blocked = layer
			break
		end
	end
	check("digging layer by layer to 600 is never refused", blocked == nil,
		blocked and ("blocked at " .. blocked) or ("reached " .. deepest))
end
check("re-digging ground already reached is always allowed",
	MineDigAuth.canCreditDepth(profile(300), "meadow", 120))
check("digging within the step allowance is allowed",
	MineDigAuth.canCreditDepth(profile(100), "meadow", 100 + ${leadN}))

-- --------------------------------------- a depth pass is not punished --
check("an elevator/plaza depth pass lets you credit where it put you",
	MineDigAuth.canCreditDepth(profile(0, 2500), "meadow", 2500))
check("...but not far below where it put you",
	not MineDigAuth.canCreditDepth(profile(0, 2500), "meadow", 4000))

print(fails == 0 and ">>> gate OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "depthgate-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> gate OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> depthgate OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
