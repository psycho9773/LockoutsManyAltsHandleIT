local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

print("LMAHI Debug: Data.lua loaded")

-- Define lockout types and data
LMAHI.lockoutTypes = LMAHI.lockoutTypes or { "raid", "dungeon", "custom" }
LMAHI.lockoutData = LMAHI.lockoutData or {
    raid = {
        { id = 1, name = "Vault of the Incarnates" },
        { id = 2, name = "Aberrus, the Shadowed Crucible" },
    },
    dungeon = {
        { id = 3, name = "Neltharion's Lair" },
        { id = 4, name = "Halls of Valor" },
    },
    custom = {},
}

-- Initialize customLockoutOrder safely
LMAHI_SavedData = LMAHI_SavedData or {}
LMAHI_SavedData.customLockoutOrder = LMAHI_SavedData.customLockoutOrder or {}
print("LMAHI Debug: Data.lua initialized, lockoutTypes:", table.concat(LMAHI.lockoutTypes, ", "), "lockoutData.raid:", #LMAHI.lockoutData.raid, "lockoutData.dungeon:", #LMAHI.lockoutData.dungeon)
