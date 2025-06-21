-- Utilities.lua
local addonName, addon = ...
local LMAHI = _G.LMAHI

-- Calculate dynamic height for lockout content frame
function LMAHI.CalculateContentHeight()
    local totalItems = 0
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            totalItems = totalItems + #LMAHI.lockoutData[lockoutType]
        end
    end
    local itemHeight = 20
    local sectionHeaderHeight = 30
    local padding = 30
    return math.max(400, (totalItems * itemHeight) + (#LMAHI.lockoutData * sectionHeaderHeight) + padding)
end

-- Clean up invalid lockout IDs
function LMAHI.CleanLockouts()
    local validLockoutIds = {}
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType]) do
            validLockoutIds[tostring(lockout.id)] = true
        end
    end
    for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
        for lockoutId, _ in pairs(lockouts) do
            if not validLockoutIds[lockoutId] then
                LMAHI_SavedData.lockouts[charName][lockoutId] = nil
            end
        end
    end
end

-- Normalize character order
function LMAHI.NormalizeCharOrder()
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        table.insert(charList, charName)
    end
    table.sort(charList, function(a, b)
        local aIndex = LMAHI_SavedData.charOrder[a] or 999
        local bIndex = LMAHI_SavedData.charOrder[b] or 1010
        if aIndex == bIndex then
            return a < b
        end
        return aIndex < bIndex
    end)

    local newCharOrder = {}
    for i, charName in ipairs(charList) do
        newCharOrder[charName] = i
    end
    LMAHI_SavedData.charOrder = newCharOrder
end

-- Normalize custom lockout order
function LMAHI.NormalizeCustomLockoutOrder()
    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
        table.insert(customList, lockout.id)
    end
    table.sort(customList, function(a, b)
        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a)] or 999
        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b)] or 1010
        if aIndex == bIndex then
            return a < b
        end
        return aIndex < bIndex
    end)

    local newCustomLockoutOrder = {}
    for i, lockoutId in ipairs(customList) do
        newCustomLockoutOrder[tostring(lockoutId)] = i
    end
    LMAHI_SavedData.customLockoutOrder = newCustomLockoutOrder
end

-- Initialize lockout data for current character
function LMAHI.InitializeLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    local _, class = UnitClass("player")
    local faction = UnitFactionGroup("player")

    if not LMAHI_SavedData.characters[charName] then
        LMAHI_SavedData.characters[charName] = true
        local charCount = 0
        for _ in pairs(LMAHI_SavedData.characters) do
            charCount = charCount + 1
        end
        LMAHI_SavedData.charOrder[charName] = charCount
        print(string.format("LMAHI: Added new character %s with order %d", charName, charCount))
        LMAHI.NormalizeCharOrder()
    end

    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    LMAHI_SavedData.classColors[charName] = LMAHI.CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
    LMAHI_SavedData.factions[charName] = faction
    for lockoutType, lockouts in pairs(LMAHI.lockoutData) do
        for _, lockout in ipairs(lockouts) do
            local lockoutId = tostring(lockout.id)
            if LMAHI_SavedData.lockouts[charName][lockoutId] == nil then
                LMAHI_SavedData.lockouts[charName][lockoutId] = false
            end
        end
    end

    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
        local lockoutId = tostring(lockout.id)
        if not LMAHI_SavedData.customLockoutOrder[lockoutId] then
            LMAHI_SavedData.customLockoutOrder[lockoutId] = #LMAHI.lockoutData.custom + 1
        end
    end
    LMAHI.NormalizeCustomLockoutOrder()
end

-- Check lockouts
function LMAHI.CheckLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI.InitializeLockouts()
    for lockoutType, lockouts in pairs(LMAHI.lockoutData) do
        for _, lockout in ipairs(lockouts) do
            local lockoutId = tostring(lockout.id)
            if LMAHI_SavedData.lockouts[charName][lockoutId] == true then
                -- Skip if already marked as locked
            else
                local locked = false
                if lockoutType == "raids" or lockoutType == "dungeons" then
                    for i = 1, GetNumSavedInstances() do
                        local name, id, reset, difficulty, lockedState, _, _, _, _, _, _, instanceID = GetSavedInstanceInfo(i)
                        if instanceID == lockout.id and lockedState then
                            locked = true
                            break
                        end
                    end
                elseif lockoutType == "quests" or lockoutType == "rares" or lockoutType == "custom" then
                    locked = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)
                elseif lockoutType == "currencies" then
                    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(lockout.id)
                    if currencyInfo and currencyInfo.quantity >= currencyInfo.maxQuantity then
                        locked = true
                    end
                end
                LMAHI_SavedData.lockouts[charName][lockoutId] = locked
            end
        end
    end
end

-- Save character data
function LMAHI.SaveCharacterData()
    C_Timer.After(0.5, function()
        LMAHI.CheckLockouts()
        LMAHI.UpdateDisplay()
    end)
end