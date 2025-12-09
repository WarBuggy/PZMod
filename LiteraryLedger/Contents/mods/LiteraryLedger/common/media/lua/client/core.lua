local Reflection = require("Starlit/utils/Reflection")
local masterZoneData = require("zoneData/masterZoneData")

-- local DEFAULT_REQUIRED_THRESHOLD = 0.01
-- local sandboxVars = SandboxVars.LiteraryLedger or {}
-- local REQUIRED_THRESHOLD = sandboxVars.Threshold or DEFAULT_REQUIRED_THRESHOLD

local TILE_SCALE = 8  -- each width/height unit = 8 tiles

-- Containers we are interested in
local CONTAINER_TYPES = {
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

-- Rooms we are interested in
local ROOM_TYPES = {
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

local ITEM_TYPES = {
    "Magazine",
    "Comic",
    "Novel",
    "Book_Picture",
    "Book_Photography",
    "RPGmanual",
    "Book",
}

-- These correspond to ITEM_TYPES + the special SkillBook category
local CATEGORY_KEYS = {
    "SkillBook",
}

-- Stores chances (0–1) from sandbox
ITEM_CATEGORY_CHANCES = {}

-- Persistent mod data
local globalModDataName = "BuggyLiteraryLedgerModData"
local modData = ModData.getOrCreate(globalModDataName)
modData.zoneRects = modData.zoneRects or {}  -- stores pre-calculated rects
modData.processedContainers = modData.processedContainers or {}
modData.businessZoneItems = modData.businessZoneItems or {}

function getItemChance(category)
    return ITEM_CATEGORY_CHANCES[category] or 0
end

-- Helper to calculate real rectangle of a sub-zone
local function getSubZoneRealRect(subZone)
    local x1 = subZone.wx * 8
    local y1 = subZone.wy * 8 + 7
    return {
        x1 = x1,
        y1 = y1,
        x2 = x1 + (subZone.width * TILE_SCALE),
        y2 = y1 - (subZone.height * TILE_SCALE)
    }
end

-- Populate all zones and pre-calculate rectangles
local function populateZoneData()
    local allBusinessZones = masterZoneData.allBusinessZones

    for bzKey, bz in pairs(allBusinessZones) do
        modData.zoneRects[bzKey] = {}

        for streetIndex, street in ipairs(bz.streetZones) do
            modData.zoneRects[bzKey][streetIndex] = {}

            for subIndex, sub in ipairs(street.subStreetZones) do
                local rect = getSubZoneRealRect(sub)
                modData.zoneRects[bzKey][streetIndex][subIndex] = rect
            end
        end
    end
end

local function loadCategoryChances()
    local LL = SandboxVars.LiteraryLedger
    if not LL or not LL.ItemChances then
        return -- should never happen, but safe
    end

    local options = LL.ItemChances

    for _, key in ipairs(CATEGORY_KEYS) do
        ITEM_CATEGORY_CHANCES[key] = options[key] or 0
    end
end

local function onGameBoot()
    for _, v in ipairs(ITEM_TYPES) do
        table.insert(CATEGORY_KEYS, v)
    end
    populateZoneData()
    loadCategoryChances()
end

Events.OnGameBoot.Add(onGameBoot)

local containerTypeLookup = {}
for _, t in ipairs(CONTAINER_TYPES) do
    containerTypeLookup[t] = true
end

local roomTypeLookup = {}
for _, t in ipairs(ROOM_TYPES) do
    roomTypeLookup[t] = true
end

-- Returns: x, y, idString
local function getContainerInfo(container)
    if not container then 
        return nil, nil, nil
    end
    local WORLD_PREFIX_STRING = "w"
    local GRID_PREFIX_STRING = "g"
    local MEMORY_PREFIX_STRING = "m"
    
    local parent = container:getParent()

    --------------------------------------------------------------------
    -- PRIMARY: Container inside IsoObject
    --------------------------------------------------------------------
    if parent then
        local square = parent:getSquare()
        if square then
            local x = square:getX()
            local y = square:getY()
            local z = square:getZ()

            -- Container index on this object
            local idx = parent:getContainerIndex(container)

            if idx and idx >= 0 then
                -- World prefix path
                return x, y, string.format(
                    "%s_%d_%d_%d_%d",
                    WORLD_PREFIX_STRING, x, y, z, idx
                )
            else
                -- Parent exists but no valid index (rare)
                return x, y, string.format(
                    "%s_%d_%d_%d_parent_%s",
                    WORLD_PREFIX_STRING, x, y, z, tostring(parent)
                )
            end
        end
    end

    --------------------------------------------------------------------
    -- SECONDARY: Container has source grid but no parent IsoObject
    --------------------------------------------------------------------
    local sourceGrid = container:getSourceGrid()
    if sourceGrid then
        local x = sourceGrid:getX()
        local y = sourceGrid:getY()
        local z = sourceGrid:getZ()

        return x, y, string.format(
            "%s_%d_%d_%d",
            GRID_PREFIX_STRING, x, y, z
        )
    end

    --------------------------------------------------------------------
    -- FINAL FALLBACK: No coordinates, no parent → memory-based ID
    --------------------------------------------------------------------
    return nil, nil, string.format(
        "%s_%s",
        MEMORY_PREFIX_STRING, tostring(container)
    )
end

-- Helper: Check if point (x, y) is inside rectangle
local function pointInRect(x, y, rect)
    return x >= rect.x1 and x <= rect.x2 and y <= rect.y1 and y >= rect.y2
end

-- Returns a random element from a non-empty array
local function chooseRandomItem(array)
    if not array or #array == 0 then
        return nil
    end
    local index = ZombRand(1, #array + 1)  -- ZombRand(a, b) returns integer in [a, b)
    return array[index]
end

-- Returns businessZoneKey, streetZone, subStreetZone if found
local function getZoneFromXY(x, y)
    -- Find the subStreetZone containing the point
    local candidate = nil
    for bzKey, bz in pairs(masterZoneData.allBusinessZones) do
        for streetIndex, street in ipairs(bz.streetZones) do
            for subIndex, sub in ipairs(street.subStreetZones) do
                local rect = modData.zoneRects[bzKey][streetIndex][subIndex]
                if rect and pointInRect(x, y, rect) then
                    candidate = { street = street, sub = sub }
                    break
                end
            end
            if candidate then break end
        end
        if candidate then break end
    end

    if not candidate then
        return nil
    end

    local streetZone = candidate.street

    -- Collect all business zones that include this streetZone
    local businessZonesForStreet = {}
    for bzKey, bz in pairs(masterZoneData.allBusinessZones) do
        for _, street in ipairs(bz.streetZones) do
            if street == streetZone then
                table.insert(businessZonesForStreet, bzKey)
            end
        end
    end

    -- Randomly pick one business zone
    local chosenBZKey = chooseRandomItem(businessZonesForStreet)
    if not chosenBZKey then
        return nil
    end

    return chosenBZKey, streetZone, candidate.sub
end

-- Helper: check if an item is of interest
-- Returns: boolean, category string (if true)
local function isItemOfInterest(item)
    if not item then return false, nil end

    local displayCategory = item:getDisplayCategory() or ""
    if displayCategory == "SkillBook" then
        return true, "SkillBook"
    end

    if displayCategory == "Literature" then
        local icon = item:getIcon()
        if icon then
            local iconString = tostring(icon)
            for _, keyword in ipairs(ITEM_TYPES) do
                local comparedString = "Item_" .. keyword
                if string.find(iconString, comparedString) then
                    return true, keyword
                end
            end
        end
    end

    return false, nil
end

-- Returns a list of items of interest in the container along with their categories
local function processContainerItems(container)
    local itemsOfInterest = {}

    -- Get the container’s inventory
    local items = container:getItems()
    if not items then return itemsOfInterest end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local isInterested, category = isItemOfInterest(item)
            if isInterested then
                table.insert(itemsOfInterest, {
                    item = item,
                    category = category
                })
            end
        end
    end

    return itemsOfInterest
end

local function onFillContainer(roomType, containerType, container)
    -- Ignore non-interesting room or container
    if not roomTypeLookup[roomType] then return end
    if not containerTypeLookup[containerType] then return end
    if not container then return end

    local cx, cy, containerIDString = getContainerInfo(container)
    if not cx or not cy or not containerIDString then return end

    -- Check if container is in a business zone
    local bzKey, streetZone, subStreetZone = getZoneFromXY(cx, cy)
    if not bzKey then return end

    -- If already processed, skip
    if modData.processedContainers[containerIDString] then
        return
    end

    modData.processedContainers[containerIDString] = true

    -- Get interesting items
    local items = processContainerItems(container)
    if #items == 0 then
        return
    end

    ----------------------------------------------------------------------
    -- Ensure business zone data exists
    ----------------------------------------------------------------------
    local bzData = modData.businessZoneItems[bzKey]
    if not bzData then
        bzData = { ready = {}, notReady = {} }
        modData.businessZoneItems[bzKey] = bzData
    end

    local streetName = streetZone and streetZone.name or "Unknown address"

    ----------------------------------------------------------------------
    -- Process each item
    ----------------------------------------------------------------------
    for _, info in ipairs(items) do
        local item = info.item
        local category = info.category

        local chance = getItemChance(category)   -- 0–1
        local displayName = item:getDisplayName() or item:getType()

        -- Roll chance
        local roll = ZombRandFloat(0.0, 1.0)

        if roll <= chance then
            -- Successful → goes into ready list
            table.insert(bzData.ready, {
                name = displayName,
                street = streetName,
                category = category
            })
        else
            -- Failed → goes into notReady list
            table.insert(bzData.notReady, {
                name = displayName,
                street = streetName,
                category = category,
                requiredChance = chance
            })
        end
    end
end

Events.OnFillContainer.Add(onFillContainer)
