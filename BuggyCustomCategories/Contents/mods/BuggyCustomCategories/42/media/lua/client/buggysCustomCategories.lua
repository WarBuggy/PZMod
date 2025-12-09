local unmatchedItems = {}

-- ============================================================
-- RULES STRUCTURE
-- Each type has: compareByIcon, compareByName
-- ============================================================
local typeRules = {

    Literature = {
        compareByIcon = {
            { "ComicBook", "Literature_ComicBook" },
            { "Book_Photography", "Literature_PhotoBook" },
            { "Book_Picture1", "Literature_PictureBook" },
            { "MagazineWordsearch", "Literature_Wordsearch" },
            { "MagazineCrossword", "Literature_Crossword" },
            { "Newspaper", "Literature_Newspaper" },
            { "RPGmanual", "Literature_RPGManual" },
            { "Novel1", "Literature_Paperback" },
            { "Recipe", "Literature_Receipe" },
            { "Paperwork_Graph_Crumpled", "Literature_Receipe" },
            { "Catalogue", "Literature_Catalogue" },
            { "Magazine", "Literature_Magazine" },
            { "Book", "Literature_Book" },
            { "IDcard", "Memento_ID_Card" },
            { "BusinessCard", "Memento_Business_Card" },
            { "ParkingTicket", "Memento_Parking_Ticket" },
            { "StockCertificate", "Memento_Stock_Certificate" },
            { "Diary", "Memento_Diary" },
            { "Passport", "Memento_Passport" },
            { "Photo_", "Memento_Photo" },
        },

        compareByName = {
            { "Wordsearch", "Literature_Word_Search" },
            { "Crossword", "Literature_Crossword" },
            { "Doodle", "Memento_Doodle" },
            { "Photograph", "Memento_Photograph" },
            { "Postcard", "Memento_Postcard" },
            { "Card", "Memento_Card" },
        }
    },

    Normal = {
        compareByIcon = {
            { "CreditCard", "Memento_Credit_Card" },
        },
        compareByName = {}
    },

    Clothing = {
        compareByIcon = {
            { "Locket", "Memento_Locket" },
        },
        compareByName = {}
    },
}

-- ============================================================
-- MAIN CATEGORY ASSIGNMENT
-- ============================================================
local function assignCustomCategories()
    local items = getAllItems()
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local typeString = item:getTypeString()
        local rules = typeRules[typeString]
        local category = nil

        local iconString = tostring(item:getIcon())
        local displayName = item:getDisplayName()

        -- =============================
        -- SPECIAL CASES FOR LITERATURE
        -- =============================
        if typeString == "Literature" then
            -- Skill book
            if string.len(item:getSkillTrained()) > 0 then
                category = "Literature_BookSkill"

            -- Magazine teaches recipes
            elseif item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
                category = "Literature_MagazineSkill"
            end
        end

        -- =============================
        -- GENERIC RULE SYSTEM (only if category not yet assigned)
        -- =============================
        if not category and rules then
            local iconRules = rules.compareByIcon or {}
            local nameRules = rules.compareByName or {}

            -- 1. compare by ICON
            for _, rule in ipairs(iconRules) do
                local key, suffix = rule[1], rule[2]
                if iconString and string.find(iconString, key, 1, true) then
                    category = suffix
                    break
                end
            end

            -- 2. compare by NAME
            if not category then
                for _, rule in ipairs(nameRules) do
                    local key, suffix = rule[1], rule[2]
                    if displayName and string.find(displayName, key, 1, true) then
                        category = suffix
                        break
                    end
                end
            end
        end

        -- =============================
        -- UNMATCHED → SAVE
        -- =============================
        if not category then
            table.insert(unmatchedItems, {
                type = typeString,
                icon = iconString,
                name = displayName
            })
        else
            item:DoParam("DisplayCategory = BCC_" .. category)
        end
    end
end

-- ============================================================
-- PRINT UNMATCHED AFTER WORLD LOAD
-- ============================================================
local function printUnmatchedItems()
    print("=== Unmatched Items ===")
    for i, info in ipairs(unmatchedItems) do
        print(i .. ". Name: " .. info.name ..
              " | Type: " .. info.type ..
              " | Icon: " .. info.icon)
    end
    print("=== Total unmatched: " .. #unmatchedItems .. " ===")
end

Events.OnGameBoot.Add(assignCustomCategories)
--Events.OnLoad.Add(printUnmatchedItems)


-- Storage for filtered NORMAL items
local normalFiltered = {}

-- Words to detect (already lowercase)
local keywords = {
    "credit",
    "badge",
    "locket",
}

-- Helper: check if any keyword appears in text (already lowercase)
local function containsKeyword(textLower)
    if not textLower then return false end
    for _, word in ipairs(keywords) do
        if string.find(textLower, word, 1, true) then
            return true
        end
    end
    return false
end

-- STEP 1: Collect during game boot
local function collectFilteredNormalItems()
    local items = getAllItems()
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if item:getTypeString() == "Normal" then
            local iconString = tostring(item:getIcon()) or ""
            local displayName = item:getDisplayName() or ""

            -- Lower-case versions
            local iconLower = string.lower(iconString)
            local nameLower = string.lower(displayName)

            -- Check both
            if containsKeyword(iconLower) or containsKeyword(nameLower) then
                table.insert(normalFiltered, {
                    icon = iconString,
                    name = displayName,
                })
            end
        end
    end
end

-- STEP 2: Print after game loads
local function printFilteredNormalItems()
    print("=== FILTERED NORMAL ITEMS (credit/badge/locket) ===")
    for i, info in ipairs(normalFiltered) do
        print(i .. ". " .. info.icon .. " | " .. info.name)
    end
    print("=== Total matches: " .. #normalFiltered .. " ===")
end

--Events.OnGameBoot.Add(collectFilteredNormalItems)
--Events.OnLoad.Add(printFilteredNormalItems)


-- Set (unique list) of non-literature types
local nonLiteratureTypes = {}

local function collectNonLiteratureTypes()
    local items = getAllItems()
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local typeString = item:getTypeString()

        if typeString ~= "Literature" then
            -- store as a set (keys = types, value = true)
            nonLiteratureTypes[typeString] = true
        end
    end
end

-- Print out unique non-literature types
local function printNonLiteratureTypes()
    print("=== Unique Non-Literature Types ===")
    local count = 0

    for typeName, _ in pairs(nonLiteratureTypes) do
        print("Type: " .. tostring(typeName))
        count = count + 1
    end

    print("=== Total unique non-literature types: " .. count .. " ===")
end

--Events.OnGameBoot.Add(collectNonLiteratureTypes)
--Events.OnLoad.Add(printNonLiteratureTypes)
