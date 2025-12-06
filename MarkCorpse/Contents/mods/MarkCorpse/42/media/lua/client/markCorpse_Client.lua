local ISInventoryPage_pre_refreshBackpacks = ISInventoryPage.refreshBackpacks

-- Helper: if a corpse, ensure _marked exists and return isCorpse, modData, marked state, and corpse ID
local function initOrGetDataFromCorpse(button)
    local inv = button and button.inventory
    local parent = inv and inv:getParent()
    local isCorpse = false
    if not parent or parent:getObjectName() ~= "DeadBody" then
        return isCorpse, nil, false, nil
    end

    isCorpse = true
    local modData = parent:getModData()
    if modData._marked == nil then
        modData._marked = false
    end
    
    local corpseID = parent:getID() or 0
    return isCorpse, modData, modData._marked, corpseID
end

-- Helper: create a yellow overlay for a button
local function createButtonOverlay(button)
    local overlay = ISPanel:new(0, 0, button:getWidth(), button:getHeight())
    overlay.backgroundColor = { r = 1, g = 1, b = 0, a = 0.4 } -- yellow
    overlay:initialise()
    overlay:instantiate()
    overlay.onMouseDown = function() return false end
    overlay.onMouseUp   = function() return false end
    overlay.onMouseMove = function() return false end
    button:addChild(overlay)
    return overlay
end

-- Update visual and layout of the buttons using a single sort
local function refreshAndReorderButtons(page)
    local buttonData = {}
    for idx, button in ipairs(page.backpacks) do
        local isCorpse, modData, isMarked, corpseID = initOrGetDataFromCorpse(button)

        -- Overlay visible only for unmarked corpses
        if button._overlay then
            button._overlay:setVisible(isCorpse and not isMarked)
        end

        table.insert(buttonData, {
            btn = button,
            isCorpse = isCorpse,
            isMarked = isMarked,
            corpseID = corpseID,
            originalIdx = idx
        })
    end

    table.sort(buttonData, function(a, b)
        if a.isCorpse and not a.isMarked then
            if b.isCorpse and not b.isMarked then
                return a.corpseID > b.corpseID
            end
            return true
        elseif b.isCorpse and not b.isMarked then
            return false
        end

        if a.isCorpse and a.isMarked then
            if b.isCorpse and b.isMarked then
                return a.corpseID > b.corpseID
            end
            return false
        elseif b.isCorpse and b.isMarked then
            return true
        end

        return a.originalIdx < b.originalIdx
    end)

    for idx, entry in ipairs(buttonData) do
        entry.btn:setY((idx - 1) * page.buttonSize)
    end
end

function ISInventoryPage:refreshBackpacks()
    ISInventoryPage_pre_refreshBackpacks(self)

    if self.onCharacter then return end

    for _, button in ipairs(self.backpacks) do
        -- Create overlay once
        if not button._overlay then
            button._overlay = createButtonOverlay(button)
        end

        -- Hook double-click once
        if not button._dblClickMarkCorpseHooked then
            local origOnMouseDoubleClick = button.onMouseDoubleClick
            button.onMouseDoubleClick = function(selfBtn, x, y)
                local isCorpse, modData, isMarked, _ = initOrGetDataFromCorpse(selfBtn)
                if isCorpse then
                    modData._marked = not isMarked
                end

                if origOnMouseDoubleClick then
                    origOnMouseDoubleClick(selfBtn, x, y)
                end

                -- Refresh overlays and order immediately
                refreshAndReorderButtons(selfBtn.inventoryPage or self)
            end
            button._dblClickMarkCorpseHooked = true
        end
    end

    -- Refresh all buttons once per update
    refreshAndReorderButtons(self)
end
