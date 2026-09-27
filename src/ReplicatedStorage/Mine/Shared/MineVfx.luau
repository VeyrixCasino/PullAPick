-- MineVfx: vanity catalog + equip state (nameplates, dig trails, shovel FX, tags).
-- Shop sells LIMITED rows. Inventory has a VFX tab (separate from Gear / Packs).
--
-- Design locks (owner 2026-09-17):
--   - Players keep full Roblox appearance (clothes + accessories).
--   - stripToDefaults is a no-op stub — do not re-enable avatar wipe.
--   - Gear slot "gloves" → "face" (cosmetic face plates).
--   - Gear names: limited shop identities, not random fantasy rolls.
--   - VFX inventory holds owned tags / trails / shovel FX / nameplates.

local MineVfx = {}

MineVfx.KINDS = {
	{ id = "nameplate", label = "Nameplate" },
	{ id = "dig_trail", label = "Dig Trail" },
	{ id = "shovel_fx", label = "Shovel FX" },
	{ id = "tag", label = "Tag" },
}

MineVfx.CATALOG = {
	{ id = "np_plain", kind = "nameplate", name = "Plain", priceCredits = 0, limited = false },
	{ id = "trail_dust", kind = "dig_trail", name = "Dust Puff", priceCredits = 0, limited = false },
	{ id = "shovel_spark", kind = "shovel_fx", name = "Sparks", priceCredits = 0, limited = false },
	{ id = "tag_none", kind = "tag", name = "None", priceCredits = 0, limited = false },
	-- Limited shop SKUs (credits). Expand here; Inventory → VFX equips them.
	{ id = "np_gold", kind = "nameplate", name = "Gilded Plate", priceCredits = 120, limited = true },
	{ id = "trail_ember", kind = "dig_trail", name = "Ember Trail", priceCredits = 180, limited = true },
	{ id = "shovel_rift", kind = "shovel_fx", name = "Rift Sparks", priceCredits = 220, limited = true },
	{ id = "tag_founder", kind = "tag", name = "Founder Tag", priceCredits = 400, limited = true },
	{ id = "tag_vip", kind = "tag", name = "VIP Tag", priceCredits = 0, limited = false },
}

MineVfx.BY_ID = {}
for _, row in ipairs(MineVfx.CATALOG) do
	MineVfx.BY_ID[row.id] = row
end

function MineVfx.def(id)
	return MineVfx.BY_ID[tostring(id or "")]
end

function MineVfx.blankEquip()
	return {
		nameplate = "np_plain",
		dig_trail = "trail_dust",
		shovel_fx = "shovel_spark",
		tag = "tag_none",
	}
end

function MineVfx.normalize(equip)
	equip = type(equip) == "table" and equip or {}
	local blank = MineVfx.blankEquip()
	for kind, fallback in pairs(blank) do
		local id = equip[kind]
		if not (id and MineVfx.def(id)) then
			equip[kind] = fallback
		end
	end
	return equip
end

-- No-op. Avatar wipe was reversed; keep stub so old callers cannot re-strip looks.
function MineVfx.stripToDefaults(_character)
end

return MineVfx
