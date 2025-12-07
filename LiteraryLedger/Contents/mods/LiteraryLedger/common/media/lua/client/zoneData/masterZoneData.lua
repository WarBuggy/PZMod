local cityModules = {
    "Rosewood",
    -- add new cities here
}

-- This table will contain ALL business zones from ALL cities:
-- Example:
-- {
--     Rosewood_BookNaked = { ... },
--     Rosewood_FireDept = { ... },
-- }
local allBusinessZones = {}

for _, moduleName in ipairs(cityModules) do
    local city = require("zoneData/" .. moduleName)

    if not city or not city.businessZones then
        print("ERROR: City module '" .. moduleName .. "' returned no businessZones")
    else
        -- Since businessZones is now a keyed table, use pairs instead of ipairs
        for key, bz in pairs(city.businessZones) do
            allBusinessZones[key] = bz
        end
    end
end

return {
    allBusinessZones = allBusinessZones,
}