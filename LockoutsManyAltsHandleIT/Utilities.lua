local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

LMAHI.FACTION_COLORS = {
    Alliance = { r = 0.0, g = 0.4, b = 1.0 },
    Horde = { r = 1.0, g = 0.0, b = 0.0 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}

function LMAHI.SaveCharacterData()
    print("LMAHI Debug: SaveCharacterData called (stub)")
    -- Placeholder: Implement character data saving logic
end

function LMAHI.CheckLockouts()
    print("LMAHI Debug: CheckLockouts called (stub)")
    -- Placeholder: Implement lockout checking logic
end

function LMAHI.CleanLockouts()
    print("LMAHI Debug: CleanLockouts called (stub)")
    -- Placeholder: Implement lockout cleaning logic
end

function LMAHI.NormalizeCustomLockoutOrder()
    print("LMAHI Debug: NormalizeCustomLockoutOrder called (stub)")
    -- Placeholder: Implement order normalization logic
end
