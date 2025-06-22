local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

print("LMAHI Debug: Data.lua loaded")

-- Define lockout types and data
LMAHI.lockoutTypes = LMAHI.lockoutTypes or { "raid", "dungeon", "custom" }
LMAHI.lockoutData = LMAHI.lockoutData or {
    raid = {},
    dungeon = {},
    custom = {},
}

-- Initialize customLockoutOrder safely
LMAHI_SavedData = LMAHI_SavedData or {}
LMAHI_SavedData.customLockoutOrder = LMAHI_SavedData.customLockoutOrder or {}
print("LMAHI Debug: Data.lua initialized, lockoutTypes:", table.concat(LMAHI.lockoutTypes, ", "))
