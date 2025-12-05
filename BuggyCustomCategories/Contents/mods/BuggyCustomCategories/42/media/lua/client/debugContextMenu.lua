-- ======================================================
-- Mod: Literature Categories + Debug Print
-- ======================================================

-- ==========================
-- DEBUG PRINT CONTEXT MENU
-- ==========================
local function printItemDetails(player, context, items)
    if #items ~= 1 then return end  -- only handle single item

    local item = items[1]
    if type(item) == "table" and item.items then
        item = item.items[1]  -- unwrap loot container items
    end
    if not instanceof(item, "InventoryItem") then return end

    context:addOption("Print Item Details", item, function()
        print("=== ITEM DETAILS ===")
        print("DisplayName:", item:getDisplayName())
        print("Category:", item:getCategory())
        print("Type:", item:getType())
        print("Icon:", item:getIcon():getName())
        print("===================")
    end)
end

-- Events.OnFillInventoryObjectContextMenu.Add(printItemDetails)