-------------------------------------
-- Sub-zones
-------------------------------------
local subZone_Rosewood_StMartin_Rd_001 = { wx = 1041, wy = 1469, width = 5, height = 6 }
local subZone_Rosewood_StMartin_Rd_002 = { wx = 1054, wy = 1477, width = 3, height = 4 }
local subZone_Rosewood_StMartin_Rd_003 = { wx = 1055, wy = 1468, width = 3, height = 3 }
local subZone_Rosewood_Buck_St_001 = { wx = 1026, wy = 1460, width = 3, height = 4 }

-------------------------------------
-- Street zone
-------------------------------------
local streetZone_Rosewood_StMartin_Rd = {
    displayName = "St Martin's Road",
    subStreetZones = {
        subZone_Rosewood_StMartin_Rd_001,
        subZone_Rosewood_StMartin_Rd_002,
        subZone_Rosewood_StMartin_Rd_003,
    }
}

local streetZone_Rosewood_Buck_St = {
    displayName = "Buck St",
    subStreetZones = {
        subZone_Rosewood_Buck_St_001,
    }
}

-------------------------------------
-- Business zone with self-defined key
-------------------------------------
local businessZone_Rosewood_bookNaked = {
    key = "Rosewood_BookNaked",   -- ★ THIS is the persistent key
    streetZones = { 
        streetZone_Rosewood_StMartin_Rd,
        streetZone_Rosewood_Buck_St,
    },
}

-------------------------------------
-- Export keyed business zones
-------------------------------------
local businessZones = {
    [businessZone_Rosewood_bookNaked.key] = businessZone_Rosewood_bookNaked
}

return {
    businessZones = businessZones
}