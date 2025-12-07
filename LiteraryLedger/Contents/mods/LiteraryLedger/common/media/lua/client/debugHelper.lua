-- Events.OnFillContainer.Add(onFillContainer)

-- local ISInventoryPage_pre_refreshBackpacks = ISInventoryPage.refreshBackpacks
-- function ISInventoryPage:refreshBackpacks()
--     ISInventoryPage_pre_refreshBackpacks(self)

--     if self.onCharacter then return end

--     for _, button in ipairs(self.backpacks) do
--         local inv = button and button.inventory
--         print("Container type: ", inv:getType())
--     end

-- end

-- Reference the core chunk mapping script
local chunkData = require("core")

local function testChunkList()
    local testIDs = {
        10531478,
        10541478,
        10531477,
        10561478,
        10571478,
        10571477,
        10531474,
        10531473,
        10541473,
        10571474,
        10571473,
        10561473,
        10551476,
        10561475,
        10561474,
        10571475,
        99999999 -- invalid
    }

    for _, chunkId in ipairs(testIDs) do
        print("Checking chunk ID:", chunkId)

        if chunkData.chunkToZones[chunkId] then
            print("  Business zones:")
            for _, bzKey in ipairs(chunkData.chunkToZones[chunkId]) do
                print("    -", bzKey)
            end
        else
            print("  No business zone found")
        end

        if chunkData.chunkToStreetZones[chunkId] then
            print("  Street zones:")
            for _, info in ipairs(chunkData.chunkToStreetZones[chunkId]) do
                print("    - Street:", info.streetZone.displayName, "Business zone:", info.businessZoneKey)
            end
        else
            print("  No street zone found")
        end

        print("-------------------------------------------------")
    end
end

-- Run the test when map zones are loaded
-- Events.OnLoad.Add(testChunkList)
