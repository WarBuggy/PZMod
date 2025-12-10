local globalModDataName = "BuggyLiteraryLedgerModData"

local TILE_SCALE = 8 -- same scale used in your getSubZoneRealRect

-- Helper: convert sub-zone to real rectangle coordinates
local function getSubZoneRealRect(subZone)
    local x1 = subZone.wx * TILE_SCALE
    local y1 = subZone.wy * TILE_SCALE + (TILE_SCALE - 1)
    return {
        x1 = x1,
        y1 = y1,
        x2 = x1 + (subZone.width * TILE_SCALE),
        y2 = y1 - (subZone.height * TILE_SCALE)
    }
end

-- Helper: Check if point (x, y) is inside rectangle
local function pointInRect(x, y, rect)
    return x >= rect.x1 and x <= rect.x2 and y <= rect.y1 and y >= rect.y2
end

local cityModules = {
    "Rosewood",
    -- add new cities here
}

-- Will contain ALL business zones from all cities (keyed)
local allBusinessZones = {}

-- Will contain ALL loot zones from all cities (keyed)
local allLootZones = {}

for _, moduleName in ipairs(cityModules) do
    local city = require("zoneData/" .. moduleName)

    ------------------------------------------------------------
    -- BUSINESS ZONES
    ------------------------------------------------------------
    if not city or not city.businessZones then
        print("ERROR: City module '" .. moduleName .. "' returned no businessZones")
    else
        -- Since businessZones is now a keyed table, use pairs instead of ipairs
        for key, bz in pairs(city.businessZones) do
            allBusinessZones[key] = bz
        end
    end

    ------------------------------------------------------------
    -- LOOT ZONES (NO processing needed)
    ------------------------------------------------------------
    if not city or not city.lootZones then
        print("ERROR: City module '" .. moduleName .. "' returned no lootZones")
    else
        for key, lz in pairs(city.lootZones) do
            allLootZones[key] = lz
        end
    end
end

return {
    globalModDataName = globalModDataName,
    getSubZoneRealRect = getSubZoneRealRect,
    pointInRect = pointInRect,
    allBusinessZones = allBusinessZones,
    allLootZones = allLootZones,
}