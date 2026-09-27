-- NewGear.Catalog: helpers for the limited hat/face prototype.
-- Prototype only. Not wired to drops, rolls, or equipped stats.
local Catalog = {}

Catalog.GRADES = { "SSS", "SS", "S", "A", "B", "C", "D", "F" }

function Catalog.icon(catalogId)
	return string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", tostring(catalogId or 0))
end

function Catalog.faceImage(catalogId)
	return "rbxassetid://" .. tostring(catalogId or 0)
end

function Catalog.list(kind)
	if kind == "faces" then
		return require(script.Parent:WaitForChild("Faces"):WaitForChild("Data"))
	end
	return require(script.Parent:WaitForChild("Hats"):WaitForChild("Data"))
end

function Catalog.byGrade(kind, grade)
	local out = {}
	for _, row in ipairs(Catalog.list(kind)) do
		if not grade or row.g == grade then
			out[#out + 1] = row
		end
	end
	return out
end

return Catalog
