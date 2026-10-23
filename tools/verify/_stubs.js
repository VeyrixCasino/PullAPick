// Roblox stand-ins on top of _shared.js's prelude, for checks that load
// MineConfig (and so Vector3, UDim2, Color3.new(...).R, game:GetService and
// MineDepth:Clone()) or a server module (game:GetService("ReplicatedStorage")
// .Mine.Shared). Append after Shared.prelude(...), before the test.
//
//   const lua = Shared.prelude(ROOT, mods, folders) + Stubs.ROBLOX + test;
module.exports.ROBLOX = `
do
	local function dt()
		return setmetatable({}, { __index = function()
			return function()
				return setmetatable({ X = 0, Y = 0, Z = 0, Magnitude = 0 }, {
					__index = function() return 0 end,
					__add = function(a) return a end, __sub = function(a) return a end,
					__mul = function(a) return a end,
				})
			end
		end })
	end
	Vector3, Vector2, CFrame, UDim2, UDim = dt(), dt(), dt(), dt(), dt()
	NumberSequence, ColorSequence, NumberRange, TweenInfo, BrickColor = dt(), dt(), dt(), dt(), dt()
	ColorSequenceKeypoint, NumberSequenceKeypoint, Rect, Font, PhysicalProperties = dt(), dt(), dt(), dt(), dt()
	Color3 = {
		new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
		fromRGB = function(r, g, b) return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 } end,
		fromHSV = function() return { R = 0, G = 0, B = 0 } end,
		fromHex = function() return { R = 0, G = 0, B = 0 } end,
	}
	task = { wait = function() end, spawn = function() end, delay = function() end, defer = function() end }
	local function node(name)
		local n = { Name = name }
		n.IsStudio = function() return false end
		n.IsServer = function() return true end
		n.IsClient = function() return false end
		n.WaitForChild = function(_, c)
			if c == "Shared" then return SHARED end
			return node(c)
		end
		n.FindFirstChild = n.WaitForChild
		return n
	end
	game = { GetService = function(_, s) return node(s) end }
	local find = SHARED.FindFirstChild
	SHARED.FindFirstChild = function(self, n)
		local m = find(self, n)
		if m and not m.Clone then
			m.Clone = function(me) return { Name = me.Name, Destroy = function() end } end
			m.Destroy = function() end
		end
		return m
	end
	SHARED.WaitForChild = function(self, n)
		return SHARED.FindFirstChild(self, n) or error("no stub for Shared." .. tostring(n))
	end
end
`;

// The modules a check needs to load MineConfig, the chests and the charms.
module.exports.ECONOMY_MODULES = [
  "MineConfig", "MineDepth", "MineBags", "MineShopEconomy", "MineBagNames", "MineLaunch",
  "MineZoneChests", "MineChestRanks", "MineZonePacks", "MinePackConfig", "Mine1PacksData",
  "Mine1ChestsData", "MinePotions", "MineCases", "MinePackArt", "MineSetPacks", "MineSetPets",
  "MineEnchants", "MineTemper", "MineIcons", "MineSkillData", "MineStats", "MineCharms",
  "MineOrePouch", "MineSetChests",
];
