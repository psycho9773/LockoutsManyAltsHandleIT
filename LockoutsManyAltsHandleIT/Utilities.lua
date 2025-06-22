local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

LMAHI.FACTION_COLORS = {
    Alliance = { r = 0.0, g = 0.4, b = 1.0 },
    Horde = { r = 1.0, g = 0.0, b = 0.0 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}

function LMAHI.SaveCharacterData()
    print("LMAHI Debug: SaveCharacterData called")
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.charOrder = LMAHI_SavedData.charOrder or {}
    LMAHI_SavedData.classColors = LMAHI_SavedData.classColors or {}
    LMAHI_SavedData.factions = LMAHI_SavedData.factions or {}

    -- Add character
    LMAHI_SavedData.characters[playerName] = true
    LMAHI_SavedData.lockouts[playerName] = LMAHI_SavedData.lockouts[playerName] or {}

    -- Assign unique charOrder index
    if not LMAHI_SavedData.charOrder[playerName] then
        local maxIndex = 0
        for _, index in pairs(LMAHI_SavedData.charOrder) do
            if tonumber(index) then
                maxIndex = math.max(maxIndex, index)
            end
        end
        LMAHI_SavedData.charOrder[playerName] = maxIndex + 1
        print("LMAHI Debug: Assigned charOrder for", playerName, ":", maxIndex + 1)
    end

    -- Set class and faction
    local _, class = UnitClass("player")
    local faction = UnitFactionGroup("player")
    LMAHI_SavedData.classColors[playerName] = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
    LMAHI_SavedData.factions[playerName] = faction or "Neutral"
end

function LMAHI.CheckLockouts()
    print("LMAHI Debug: CheckLockouts called")
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.lockouts[playerName] = LMAHI_SavedData.lockouts[playerName] or {}

    -- Clear existing raid and dungeon lockouts
    for lockoutType, lockouts in pairs(LMAHI.lockoutData or {}) do
        if lockoutType == "raid" or lockoutType == "dungeon" then
            for _, lockout in ipairs(lockouts) do
                LMAHI_SavedData.lockouts[playerName][tostring(lockout.id)] = false
            end
        end
    end

    -- Update lockouts from GetSavedInstanceInfo
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, lockedState, _, _, _, _, _, _, instanceID = GetSavedInstanceInfo(i)
        if lockedState then
            local lockoutType = difficulty == 1 and "dungeon" or "raid"
            LMAHI.lockoutData[lockoutType] = LMAHI.lockoutData[lockoutType] or {}
            local exists = false
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType]) do
                if lockout.id == instanceID then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(LMAHI.lockoutData[lockoutType], { id = instanceID, name = name, reset = reset > 0 and (lockoutType == "raid" and "weekly" or "daily") or "none" })
            end
            LMAHI_SavedData.lockouts[playerName][tostring(instanceID)] = true
        end
    end

    -- Preserve custom lockouts
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        LMAHI_SavedData.lockouts[playerName][tostring(lockout.id)] = LMAHI_SavedData.lockouts[playerName][tostring(lockout.id)] or false
    end
end

function LMAHI.CleanLockouts()
    print("LMAHI Debug: CleanLockouts called (stub)")
    -- Placeholder: Implement lockout cleaning logic
end

function LMAHI.NormalizeCustomLockoutOrder()
    print("LMAHI Debug: NormalizeCustomLockoutOrder called")
    local customList = LMAHI.lockoutData.custom or {}
    local newOrder = {}
    for i, lockout in ipairs(customList) do
        newOrder[tostring(lockout.id)] = i
    end
    LMAHI_SavedData.customLockoutOrder = newOrder
end
