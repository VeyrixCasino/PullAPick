// The plinth is a disc, so fit it as one.
//
// reachFrom() walks the eight corners of a bounding BOX. That is right for the
// tool, which is a box-ish shape, but the plinth is round: its box corners stick
// out to sqrt(6.75^2 + 6.75^2) = 9.55 studs horizontally where the disc itself
// only ever reaches 6.75. Fitting the corners inflates the radius by a factor of
// root two in the horizontal plane -- 10.45 instead of 7.98 -- and every stud of
// that is empty air the camera backs up to make room for.
//
// Measuring the plinth as a cylinder instead: 7.98 radius, 26.8 distance, and
// the subject grows ~31% on screen for nothing.
const fs = require("fs"), path = require("path");
const F = path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineShopView.luau");
const raw = fs.readFileSync(F, "utf8");
const crlf = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");
function one(old, nw) {
  const n = s.split(old).length - 1;
  if (n !== 1) throw new Error("expected 1 match, got " + n + " for: " + old.slice(0, 70));
  s = s.replace(old, nw);
}

one(`		local radius = reachFrom(centre, size)
		if stage then
			local okBox, scf, ssz = pcall(function()
				return stage:GetBoundingBox()
			end)
			-- pcall returns (ok, cf, size); a Model with no parts throws.
			if okBox and scf and ssz then
				radius = math.max(radius, reachFrom(scf, ssz))
			end
		end`,
`		--[[
			The plinth is ROUND, so its box corners are a lie.

			A 13.5-stud disc has a bounding box whose corners reach
			sqrt(6.75^2 + 6.75^2) = 9.55 studs out, where the disc itself never
			passes 6.75. Walking those corners inflated the radius by root two in
			the horizontal plane -- 10.45 against a true 7.98 -- and the camera
			backed up to make room for air that is not there.

			Measured as the cylinder it is: the horizontal reach is the disc
			radius, and only the vertical extremes vary.
		]]
		local function reachFromCylinder(boxCF, boxSize)
			local h = boxSize * 0.5
			local hr = math.max(h.X, h.Z)
			local worst = 0
			for _, sy in ipairs({ -1, 1 }) do
				local dy = (boxCF * CFrame.new(0, h.Y * sy, 0)).Position.Y - aim.Y
				local dxz = (Vector3.new(boxCF.Position.X, aim.Y, boxCF.Position.Z)
					- Vector3.new(aim.X, aim.Y, aim.Z)).Magnitude
				worst = math.max(worst, math.sqrt((dxz + hr) ^ 2 + dy * dy))
			end
			return worst
		end

		local radius = reachFrom(centre, size)
		if stage then
			local okBox, scf, ssz = pcall(function()
				return stage:GetBoundingBox()
			end)
			-- pcall returns (ok, cf, size); a Model with no parts throws.
			if okBox and scf and ssz then
				radius = math.max(radius, reachFromCylinder(scf, ssz))
			end
		end`);

fs.writeFileSync(F, crlf ? s.split("\n").join("\r\n") : s);
console.log("plinth fitted as a cylinder, not a box");
