--!strict
local PlaceConfig = {}
PlaceConfig.MAIN_PLACE_ID = 136170535919017
PlaceConfig.EXCHANGE_PLACE_ID = 136342807367156
PlaceConfig.AFK_PLACE_ID = 121960354995134
local attrId = tonumber(game:GetAttribute('AFK_PLACE_ID'))
if attrId and attrId > 0 then PlaceConfig.AFK_PLACE_ID = attrId end
function PlaceConfig.isConfigured(placeId) return type(placeId) == 'number' and placeId > 0 end
function PlaceConfig.exchangeReady() return PlaceConfig.isConfigured(PlaceConfig.EXCHANGE_PLACE_ID) end
function PlaceConfig.afkReady() return PlaceConfig.isConfigured(PlaceConfig.AFK_PLACE_ID) end
function PlaceConfig.isExchange() return PlaceConfig.exchangeReady() and game.PlaceId == PlaceConfig.EXCHANGE_PLACE_ID end
function PlaceConfig.isMain() return game.PlaceId == PlaceConfig.MAIN_PLACE_ID end
function PlaceConfig.isAfk() return PlaceConfig.afkReady() and game.PlaceId == PlaceConfig.AFK_PLACE_ID end
function PlaceConfig.role()
	if PlaceConfig.isAfk() then return 'afk'
	elseif PlaceConfig.isExchange() then return 'exchange'
	elseif PlaceConfig.isMain() then return 'main'
	else return 'unknown' end
end
print(string.format('[PlaceConfig] placeId=%d role=%s AFK_ID=%d', game.PlaceId, PlaceConfig.role(), PlaceConfig.AFK_PLACE_ID))
return PlaceConfig
