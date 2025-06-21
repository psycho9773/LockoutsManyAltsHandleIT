local addonName, addon = ...
local LMAHI = _G.LMAHI

function LMAHI.CalculateContentHeight()
    local height = 20 -- Initial padding
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        height = height + 30 -- Section header height
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            height = height + (#(LMAHI.lockoutData[lockoutType] or {}) * (20 + 10)) + 10 -- MODIFIED: Added +10 per lockout row for 10-pixel drop
        else
            height = height + 5 -- Collapsed section padding
        end
    end
    return height
end

function LMAHI.SaveCharacterData()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    if not LMAHI_SavedData.characters[charName] then
        LMAHI_SavedData.characters[charName] = true
        LMAHI_SavedData.lockouts[charName] = {}
        LMAHI_SavedData.charOrder[charName] = table.getn(LMAHI_SavedData.characters)
        
        local _, class = UnitClass("player")
        local classColor = LMAHI.CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
        LMAHI_SavedData.classColors[charName] = classColor
        
        local faction = UnitFactionGroup("player")
        LMAHI_SavedData.factions[charName] = faction
    end
    
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            local lockoutId = tostring(lockout.id)
            if not LMAHI_SavedData.lockouts[charName][lockoutId] then
                LMAHI_SavedData.lockouts[charName][lockoutId] = false
            end
        end
    end
end

function LMAHI.CheckLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    if not LMAHI_SavedData.lockouts[charName] then return end

    for i = 1, GetNumSavedInstances() do
        local name, id, reset, _, lockedState = GetSavedInstanceInfo(i)
        for _, lockoutType in ipairs({"raids", "dungeons"}) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                if lockout.name == name then
                    LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = lockedState and reset > 0
                end
            end
        end
    end

    for _, lockout in ipairs(LMAHI.lockoutData.quests or {}) do
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)
        LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = isCompleted
    end

    for _, lockout in ipairs(LMAHI.lockoutData.rares or {}) do
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)
        LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = isCompleted
    end

    for _, lockout in ipairs(LMAHI.lockoutData.currencies or {}) do
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(lockout.id)
        if currencyInfo then
            local isWeeklyCapped = currencyInfo.quantity >= currencyInfo.maxWeeklyQuantity and currencyInfo.maxWeeklyQuantity > 0
            LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = isWeeklyCapped
        end
    end

    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        if lockout.reset == "weekly" then
            local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)
            LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = isCompleted
        end
    end
end

function LMAHI.InitializeLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    if not LMAHI_SavedData.lockouts[charName] then
        LMAHI_SavedData.lockouts[charName] = {}
    end

    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            local lockoutId = tostring(lockout.id)
            if LMAHI_SavedData.lockouts[charName][lockoutId] == nil then
                LMAHI_SavedData.lockouts[charName][lockoutId] = false
            end
        end
    end
end

function LMAHI.CleanLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    if LMAHI_SavedData.lockouts[charName] then
        for lockoutId, _ in pairs(LMAHI_SavedData.lockouts[charName]) do
            local found = false
            for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    if tostring(lockout.id) == lockoutId then
                        found = true
                        break
                    end
                end
                if found then break end
            end
            if not found then
                LMAHI_SavedData.lockouts[charName][lockoutId] = nil
            end
        end
    end
end

function LMAHI.NormalizeCustomLockoutOrder()
    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        table.insert(customList, lockout)
    end
    table.sort(customList, function(a, b)
        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
        if aIndex == bIndex then
            return a.id < b.id
        end
        return aIndex < bIndex
    end)

    local newOrder = {}
    for i, lockout in ipairs(customList) do
        newOrder[tostring(lockout.id)] = i
    end
    LMAHI_SavedData.customLockoutOrder = newOrder
end

function LMAHI.SetCollapseIconRotation(button, isCollapsed)
    local angle = isCollapsed and math.rad(90) or math.rad(270)
    C_Timer.After(0, function()
        if button and button.icon then
            button.icon:SetRotation(angle)
        end
    end)
end