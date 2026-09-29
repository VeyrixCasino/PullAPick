// Fit the camera to the subject the camera is actually looking at.
//
// setModel aims the camera at `centre` -- the TOOL's bounding-box centre, which
// sits about y = -9.7 because the tool stands on top of the plinth. But the
// radius it fitted against was a sphere measured about the WORLD ORIGIN:
//
//     plinthReach = sqrt(9^2 + 14^2) = 16.64
//
// Measuring the subject from one point and orbiting about another overstates the
// fit badly. With the real models -- plinth 13.5 across sitting at y = -12.3,
// tool 4.1 long at y = -9.65 -- everything that must be in frame is within 7.98
// studs of the aim point, not 16.64. The camera was therefore parked at 56 studs
// instead of 27, framing a 33-stud-wide view around a 4-stud pickaxe. The tool
// rendered; it was just a speck on a large empty plinth.
//
// Measured from the aim point now, against the real union of the plinth and the
// tool, so a taller plinth or a longer tool reframes itself instead of needing
// the constants edited.
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

one(`			Radius, not longest side.

			Distance is fitted against the bounding SPHERE of the plinth plus the
			tool, because the camera orbits: a pick that fits the frame face-on
			swings wider when you drag it side-on, and fitting the longest edge
			alone crops it mid-turn.

			The plinth is 18 studs across and sits 13 below the origin, so it has
			to be in the box or the pedestal falls out of frame on tall screens.
		]]
		local half = size * 0.5
		local toTop = math.max(math.abs(centre.Position.Y + half.Y), 1)
		local plinthReach = math.sqrt(9 * 9 + 14 * 14)
		local radius = math.max(half.Magnitude, toTop, plinthReach)`,
`			RADIUS IS MEASURED FROM WHERE THE CAMERA ACTUALLY LOOKS.

			Distance is fitted against a bounding SPHERE rather than the longest
			side, because the camera orbits: a pick that fits the frame face-on
			swings wider when you drag it side-on, and fitting the longest edge
			alone crops it mid-turn.

			The sphere has to be centred on the point the camera orbits, and it
			was not. The camera aims at \`centre\` -- the TOOL's box centre, about
			y = -9.7, because the tool stands on the plinth -- but the radius was
			sqrt(9^2 + 14^2) = 16.64, a sphere about the WORLD ORIGIN. Measuring
			the subject from one point and orbiting about another overstates the
			fit: everything that must be in frame is within ~8 studs of the aim
			point, so the camera sat at 56 studs instead of 27 and framed a
			33-stud-wide view around a 4-stud pickaxe. The tool was rendering --
			it was a speck on a big empty plinth.

			The union of the plinth and the tool, measured corner by corner from
			the aim point. No magic constants, so a taller plinth or a longer
			tool reframes itself.
		]]
		local aim = centre.Position
		local function reachFrom(boxCF, boxSize)
			local h = boxSize * 0.5
			local worst = 0
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local corner = (boxCF * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						worst = math.max(worst, (corner - aim).Magnitude)
					end
				end
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
				radius = math.max(radius, reachFrom(scf, ssz))
			end
		end
		-- Floor it so a tiny tool on an empty stage cannot put the camera inside
		-- the plinth it is standing on.
		radius = math.max(radius, 4)`);

fs.writeFileSync(F, crlf ? s.split("\n").join("\r\n") : s);
console.log("radius now measured from the aim point against the real plinth+tool union");
