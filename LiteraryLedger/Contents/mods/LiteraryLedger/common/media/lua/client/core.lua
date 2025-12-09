local Reflection = require("Starlit/utils/Reflection")
local masterZoneData = require("zoneData/masterZoneData")


local PAGE_NUMBER_MIN = 100
local PAGE_NUMBER_MAX = 950

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

local MIN_ITEMS_PER_PAGE = SandboxVars.LiteraryLedger.MinItemPerPage or 5
local MAX_EXTRA_ITEMS_PER_PAGE = SandboxVars.LiteraryLedger.MaxExtraItems or 5 
local MAX_ITEMS_PER_PAGE = MIN_ITEMS_PER_PAGE + MAX_EXTRA_ITEMS_PER_PAGE


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
    for _, key in ipairs(CATEGORY_KEYS) do
        ITEM_CATEGORY_CHANCES[key] = SandboxVars.LiteraryLedger[key] or 0
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

local function getRandomPageNumber(bzData)
    local maxAttempts = PAGE_NUMBER_MAX - PAGE_NUMBER_MIN
    for i = 1, maxAttempts do
        local n = ZombRand(PAGE_NUMBER_MIN, PAGE_NUMBER_MAX + 1)
        if not bzData.usedPageNumbers[n] then
            return n
        end
    end

    -- Fallback if all attempts fail
    return PAGE_NUMBER_MIN - #bzData.pages
end

-- Ensure the business zone data structure exists
local function ensureBusinessZoneData(bzKey)
    local bzData = modData.businessZoneItems[bzKey]
    if not bzData then
        bzData = { 
            pages = {},             -- generated pages
            usedPageNumbers = {},    -- numbers 100–950 already used (lookup table)
            usedPageNumbersList = {}, -- array for random selection
            available = {}          -- items waiting for a page
        }
        modData.businessZoneItems[bzKey] = bzData
    else
        -- Ensure usedPageNumbersList exists
        bzData.usedPageNumbersList = bzData.usedPageNumbersList or {}
    end
    return bzData
end

-- Helper: create page content string from items
local function createPageContentString(pageNumber, pageItems)
    local lines = {}
    table.insert(lines, "Page #" .. pageNumber)
    
    for _, item in ipairs(pageItems) do
        table.insert(lines, item.name .. " - " .. item.street)
    end
    local contentString = table.concat(lines, "\n")  -- join all lines with newlines
    print(contentString)
    return contentString
end

-- Attempt to generate pages while enough items are available
local function tryGeneratePage(bzData)
    while #bzData.available >= MAX_ITEMS_PER_PAGE do
        -- Randomly decide number of items for this page
        local numItems = ZombRand(MIN_ITEMS_PER_PAGE, MAX_ITEMS_PER_PAGE + 1)

        -- Get an unused page number
        local pageNumber = getRandomPageNumber(bzData)

        -- Take `numItems` randomly from the available pool
        local pageItems = {}
        for i = 1, numItems do
            local idx = ZombRand(1, #bzData.available + 1)  -- random index
            table.insert(pageItems, table.remove(bzData.available, idx))
        end

        -- Save the page
        bzData.pages[pageNumber] = createPageContentString(pageNumber, pageItems)
        bzData.usedPageNumbers[pageNumber] = true
        table.insert(bzData.usedPageNumbersList, pageNumber)
    end
end

-- Main container processing function
local function onFillContainer(roomType, containerType, container)
    -- Ignore non-interesting room or container
    if not roomTypeLookup[roomType] or not containerTypeLookup[containerType] or not container then
        return
    end

    local cx, cy, containerIDString = getContainerInfo(container)
    if not cx or not cy or not containerIDString then return end

    local bzKey, streetZone, subStreetZone = getZoneFromXY(cx, cy)
    if not bzKey then return end

    if modData.processedContainers[containerIDString] then return end
    modData.processedContainers[containerIDString] = true

    local items = processContainerItems(container)
    if #items == 0 then return end

    local bzData = ensureBusinessZoneData(bzKey)
    local streetName = streetZone and streetZone.displayName or "Unknown address"

    -- Add items that pass the chance roll to available pool
    local addedCount = 0
    for _, info in ipairs(items) do
        local rollResult = ZombRandFloat(0.0, 1.0)
        local targetRoll = getItemChance(info.category)
        if rollResult  <=  targetRoll then
            local displayName = info.item:getDisplayName() or info.item:getType()
            table.insert(bzData.available, { name = displayName, street = streetName })
            addedCount = addedCount + 1
        end
    end

    -- Only attempt page generation if at least one item was added
    if addedCount > 0 then
        tryGeneratePage(bzData)
    end
end

Events.OnFillContainer.Add(onFillContainer)
