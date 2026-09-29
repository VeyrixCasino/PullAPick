// Does the coin-priced depth gate behave?
//
// Reads the real constants out of MineDepth.luau rather than restating them, so
// this fails when the ladder moves and cannot quietly agree with a stale copy.
// Run: node tools/verify/seams.js
const fs = require("fs");
const path = require("path");

const src = fs.readFileSync(
	path.join(__dirname, "..", "..", "src", "ReplicatedStorage", "Mine", "Shared", "MineDepth.luau"),
	"utf8"
);

function num(name) {
	const m = src.match(new RegExp("MineDepth\\." + name + "\\s*=\\s*([0-9.]+)"));
	if (!m) throw new Error("could not read MineDepth." + name);
	return parseFloat(m[1]);
}
const SEAMS = (() => {
	const m = src.match(/MineDepth\.SEAMS\s*=\s*\{([^}]*)\}/);
	if (!m) throw new Error("could not read MineDepth.SEAMS");
	return m[1].split(",").map((s) => parseInt(s.trim(), 10)).filter(Number.isFinite);
})();

const MINUTES = num("SEAM_MINUTES");
const BPH = num("GATE_BLOCKS_PER_HOUR");
const ZONE = num("GATE_COIN_ZONE");
const DEPTH = num("GATE_COIN_DEPTH");
const POW = num("GATE_COIN_POW");

// Mirrors of the Luau, kept deliberately literal.
const coinValue = (z, L) => Math.pow(ZONE, z - 1) * Math.pow(1 + DEPTH * L, POW);

function gateBand(seam) {
	let lo = 1;
	for (const s of SEAMS) {
		if (s === seam) return [lo, seam - 1];
		lo = s;
	}
	return null;
}

function seamPrice(seam, z) {
	const b = gateBand(seam);
	if (!b) return null;
	const [lo, hi] = b;
	let sum = 0;
	for (let L = lo; L <= hi; L++) sum += coinValue(z, L);
	return Math.floor((sum / (hi - lo + 1)) * BPH * (MINUTES / 60) + 0.5);
}

function bandIncome(seam, z) {
	const [lo, hi] = gateBand(seam);
	let sum = 0;
	for (let L = lo; L <= hi; L++) sum += coinValue(z, L);
	return (sum / (hi - lo + 1)) * BPH;
}

function gateForLayer(layer) {
	let need = null;
	for (const s of SEAMS) if (layer >= s) need = s;
	return need;
}

const key = (zi, seam) => `${zi}:${seam}`;
const ownsSeam = (p, seam, zi) => (p.seams || {})[key(zi, seam)] === true;

function grantReachedSeams(p) {
	p.seams = p.seams || {};
	let granted = 0;
	for (const reached of Object.values(p.deepest || {})) {
		for (const s of SEAMS) {
			if (reached >= s && !ownsSeam(p, s, 1)) {
				p.seams[key(1, s)] = true;
				granted++;
			}
		}
	}
	return granted;
}

let failures = 0;
const check = (name, cond, detail) => {
	if (cond) return;
	failures++;
	console.log("  FAIL  " + name + (detail ? "  -- " + detail : ""));
};

const BREAK = process.argv.includes("--break");

console.log(`ladder: ${SEAMS.join(", ")}`);
console.log(`${MINUTES} min @ ${BPH} blocks/hr, coin = 5^(Z-1) * (1 + ${DEPTH}L)^${POW}\n`);

// 1. Every gate costs SEAM_MINUTES of the band it gates. This is the whole
//    pricing rule; if it drifts, prices were hardcoded somewhere.
for (const s of SEAMS) {
	const mins = (seamPrice(s, 1) / bandIncome(s, 1)) * 60;
	check(`seam ${s} prices to ${MINUTES} min`, Math.abs(mins - MINUTES) < 0.05, `got ${mins.toFixed(2)}`);
}

// 2. The price rule is zone-invariant: the zone term factors out, so a seam is
//    the same number of minutes in Meadow and in Primordium.
for (const s of SEAMS) {
	const a = (seamPrice(s, 1) / bandIncome(s, 1)) * 60;
	const b = (seamPrice(s, 10) / bandIncome(s, 10)) * 60;
	check(`seam ${s} costs the same minutes in every zone`, Math.abs(a - b) < 0.05, `Z1 ${a.toFixed(2)} vs Z10 ${b.toFixed(2)}`);
}

// 3. The surface is free. If this fails the game is bricked for new players:
//    nobody can afford a gate before they have mined anything.
const firstSeam = SEAMS[0];
check("layer 1 needs no seam", gateForLayer(1) === null);
check(`layer ${firstSeam - 1} needs no seam`, gateForLayer(firstSeam - 1) === null);
check(`layer ${firstSeam} needs seam ${firstSeam}`, gateForLayer(firstSeam) === firstSeam);

// 4. Past the last seam depth is open, not blocked. Owning the deepest gate has
//    to cover every layer below it or the mine ends at 10000.
const last = SEAMS[SEAMS.length - 1];
for (const L of [last, last + 1, last + 5000, 100000]) {
	check(`layer ${L} gates on the last seam`, gateForLayer(L) === last, `got ${gateForLayer(L)}`);
}

// 5. gateForLayer is monotone -- a deeper layer never needs a shallower gate.
let prev = 0;
for (let L = 1; L <= last + 2000; L += 7) {
	const g = gateForLayer(L) || 0;
	if (g < prev) { check(`gateForLayer monotone at ${L}`, false, `${prev} -> ${g}`); break; }
	prev = g;
}

// 6. Grandfathering. Nobody loses depth they already dug.
const p = { deepest: { meadow: BREAK ? 0 : 2700 }, seams: {} };
const granted = grantReachedSeams(p);
for (const s of SEAMS.filter((s) => s <= 2700)) {
	check(`deepest 2700 keeps seam ${s}`, ownsSeam(p, s, 1));
}
for (const s of SEAMS.filter((s) => s > 2700)) {
	check(`deepest 2700 is not given seam ${s}`, !ownsSeam(p, s, 1));
}
check("grandfather granted something", granted > 0, `granted ${granted}`);

// 7. Idempotent and add-only: it runs on every load, so a second pass must not
//    grant again and must not revoke.
const before = Object.keys(p.seams).length;
const second = grantReachedSeams(p);
check("grandfather is idempotent", second === 0, `re-granted ${second}`);
check("grandfather never revokes", Object.keys(p.seams).length === before);

// 8. A player who has dug nothing owns nothing.
const fresh = { deepest: {}, seams: {} };
grantReachedSeams(fresh);
check("fresh profile owns no seam", Object.keys(fresh.seams).length === 0);

console.log(failures === 0 ? "\nall checks passed" : `\n${failures} FAILED`);
process.exit(failures === 0 ? 0 : 1);
