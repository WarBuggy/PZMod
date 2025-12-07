local Reflection = require("Starlit/utils/Reflection")
local masterZoneData = require("zoneData/masterZoneData")


local DEFAULT_REQUIRED_THRESHOLD = 0.01
local sandboxVars = SandboxVars.LiteraryLedger or {}
local REQUIRED_THRESHOLD = sandboxVars.Threshold or DEFAULT_REQUIRED_THRESHOLD

-- Global tables
local allChunkIDs = {}           -- businessZoneKey -> set of chunk IDs
local chunkToZones = {}          -- chunkId -> list of businessZoneKey
local chunkToStreetZones = {}    -- chunkId -> list of { businessZoneKey, streetZone }

-- Persistent mod data
local globalModDataName = "BuggyLiteraryLedgerModData"
local modData = ModData.getOrCreate(globalModDataName)
modData.loadedChunks = modData.loadedChunks or {}
modData.businessZoneProgress = modData.businessZoneProgress or {}

---------------------------------------------------------------------------
-- Helper: Expand a subStreetZone into a list of chunk IDs
---------------------------------------------------------------------------
local function expandSubStreetZone(sub)
    local result = {}
    for dx = 0, sub.width - 1 do
        for dy = 0, sub.height - 1 do
            local wx = sub.wx + dx
            local wy = sub.wy - dy       -- PZ coordinate system: height decreases wy
            local chunkId = wx * 10000 + wy
            result[chunkId] = true
        end
    end
    return result
end

---------------------------------------------------------------------------
-- Populate all chunk mappings
---------------------------------------------------------------------------
local function populateChunkData()
    local allBusinessZones = masterZoneData.allBusinessZones

    for bzKey, bz in pairs(allBusinessZones) do
        allChunkIDs[bzKey] = {}

        for _, street in ipairs(bz.streetZones) do
            for _, sub in ipairs(street.subStreetZones) do
                local expanded = expandSubStreetZone(sub)

                for chunkId, _ in pairs(expanded) do
                    -- Add chunk to business zone set
                    allChunkIDs[bzKey][chunkId] = true

                    -- Map chunk to business zones
                    chunkToZones[chunkId] = chunkToZones[chunkId] or {}
                    table.insert(chunkToZones[chunkId], bzKey)

                    -- Map chunk to street zones
                    chunkToStreetZones[chunkId] = chunkToStreetZones[chunkId] or {}
                    table.insert(chunkToStreetZones[chunkId], { businessZoneKey = bzKey, streetZone = street })
                end
            end
        end

        -- Initialize progress if not exists
        modData.businessZoneProgress[bzKey] = modData.businessZoneProgress[bzKey] or {
            loaded = 0,
            total = 0,
            isReady = false
        }
        modData.businessZoneProgress[bzKey].total = 0
        for _ in pairs(allChunkIDs[bzKey]) do
            modData.businessZoneProgress[bzKey].total = modData.businessZoneProgress[bzKey].total + 1
        end
    end
end

Events.OnLoadMapZones.Add(populateChunkData)

---------------------------------------------------------------------------
-- Handle chunk loaded event
---------------------------------------------------------------------------
local function onChunkLoad(chunk)
    local wx = Reflection.getField(chunk, "wx")
    local wy = Reflection.getField(chunk, "wy")
    local chunkId = wx * 10000 + wy
    
    -- Skip if already loaded
    if modData.loadedChunks[chunkId] then 
        return
    end

    -- Mark as loaded
    modData.loadedChunks[chunkId] = true

    -- Update each business zone this chunk belongs to
    local zones = chunkToZones[chunkId]
    if not zones or #zones == 0 then
        return
    end

    for _, bzKey in ipairs(zones) do
        local bzProgress = modData.businessZoneProgress[bzKey]
        if bzProgress then
            if not bzProgress.isReady then
                bzProgress.loaded = bzProgress.loaded + 1
                local percent = bzProgress.loaded / bzProgress.total
                bzProgress.isReady = percent >= REQUIRED_THRESHOLD
                if bzProgress.isReady then
                    print("[DEBUG] LiteraryLedger - Business Zone Ready:", bzKey)
                end
            end
        end
    end
end

Events.LoadChunk.Add(onChunkLoad)

-- Containers we are interested in
local containerTypes = {
    "counter",
    "shelves",
    "cardboardbox",
    "metal_shelves",
    "smallbox",
    "crate",
    "sidetable",
    "dresser",
    "wardrobe",
    "desk",
}
local containerTypeLookup = {}
for _, t in ipairs(containerTypes) do
    containerTypeLookup[t] = true
end

local roomTypes = {
    "closet",
    "laundry",
    "bathroom",
    "livingroom",
    "kitchen",
    "hall",
    "garagestorage",
    "garage",
    "kidsbedroom",
}
local roomTypeLookup = {}
for _, t in ipairs(roomTypes) do
    roomTypeLookup[t] = true
end

local function onFillContainer(roomType, containerType, container)
    -- loot respawn can be on but we are not interested in that
    -- onFillContainer is called on loot respawn 
    -- so we need to track and check only on 1st onFillContainer call

    -- Only track interesting room types and container types
    if not roomTypeLookup[roomType] then return end
    if not containerTypeLookup[containerType] then return end



    if container then
        -- check the items in the container. If there are nothing of interest, skip

        -- insert code to get chunk coord or world coord of the container here

        -- get the interested items and save it to the mod's global modData
    end
end

Events.OnFillContainer.Add(onFillContainer)



-- Export tables for other scripts
return {
    allChunkIDs = allChunkIDs,
    chunkToZones = chunkToZones,
    chunkToStreetZones = chunkToStreetZones,
}
