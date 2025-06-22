local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

LMAHI.lockoutTypes = LMAHI.lockoutTypes or { "raid", "dungeon", "custom" }
LMAHI.lockoutData = LMAHI.lockoutData or {
    raid = {},
    dungeon = {},
    custom = LMAHI_SavedData.customLockouts or {},
}

function LMAHI.InitializeLockouts()
    print("LMAHI Debug: InitializeLockouts called")
    LMAHI.lockoutData.raid = LMAHI.lockoutData.raid or {}
    LMAHI.lockoutData.dungeon = LMAHI.lockoutData.dungeon or {}
    LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts or {}
end
