local addonName, addon = ...
local LMAHI = _G.LMAHI

-- Safeguard to ensure LMAHI exists
if not LMAHI then
    print("LMAHI Error: Addon namespace not initialized. Ensure Core.lua loads first.")
    return
end

function LMAHI.CalculateContentHeight()
    local height = 20 -- Initial padding
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        height = height + 30 -- Section header height
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            height = height + (#(LMAHI.lockoutData[lockoutType] or {}) * (20 + 10)) + 10
        else
            height = height + 5
        end
    end
    return height
end

function LMAHI.SaveCharacterData()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    if not LMAHI_SavedData.characters[charName] then
        LMAHI_SavedData.characters[charName] = true
        LMAHI_SavedData.lockouts[charName] = {}
        local _, class = UnitClass("player")
        local classColor = LMAHI.CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
        LMAHI_SavedData.classColors[charName] = classColor
        local faction = UnitFactionGroup("player")
        LMAHI_SavedData.factions[charName] = faction
        local maxOrder = 0
        for _, order in pairs(LMAHI_SavedData.charOrder) do
            if type(order) == "number" and order > maxOrder then
                maxOrder = order
            end
        end
        LMAHI_SavedData.charOrder[charName] = maxOrder + 1
        print("LMAHI Debug: New character", charName, "assigned charOrder", maxOrder + 1)
    end
    -- Initialize lockouts for all characters
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        if not LMAHI_SavedData.lockouts[charName] then
            LMAHI_SavedData.lockouts[charName] = {}
        end
        for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                local lockoutId = tostring(lockout.id)
                if LMAHI_SavedData.lockouts[charName][lockoutId] == nil then
                    LMAHI_SavedData.lockouts[charName][lockoutId] = false
                end
            end
        end
    end
end

function LMAHI.CheckLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    if not LMAHI_SavedData.lockouts[charName] then
        LMAHI_SavedData.lockouts[charName] = {}
    end
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        print("LMAHI Debug: Checking lockout type:", lockoutType, "for", charName)
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            local lockoutId = tostring(lockout.id)
            -- Only initialize if not set to preserve other characters' states
            if LMAHI_SavedData.lockouts[charName][lockoutId] == nil then
                LMAHI_SavedData.lockouts[charName][lockoutId] = false
            end
            if lockoutType == "raids" or lockoutType == "dungeons" then
                local found = false
                for i = 1, GetNumSavedInstances() do
                    local name, _, reset, _, lockedState = GetSavedInstanceInfo(i)
                    if lockout.name == name then
                        LMAHI_SavedData.lockouts[charName][lockoutId] = lockedState and reset > 0
                        found = true
                        print("LMAHI Debug: Checked", lockoutType, lockout.name, "(ID:", lockout.id, ") for", charName, "->", LMAHI_SavedData.lockouts[charName][lockoutId])
                    end
                end
                if not found then
                    -- Only update if previously true to avoid resetting valid states
                    if LMAHI_SavedData.lockouts[charName][lockoutId] then
                        print("LMAHI Debug: No saved instance found for", lockoutType, lockout.name, "(ID:", lockout.id, ") for", charName, "-> retaining state")
                    end
                end
            elseif lockoutType == "quests" or lockoutType == "rares" or (lockoutType == "custom" and lockout.reset ~= "none") then
                local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)
                LMAHI_SavedData.lockouts[charName][lockoutId] = isCompleted
                print("LMAHI Debug: Checked", lockoutType, lockout.name, "(ID:", lockout.id, ") for", charName, "->", isCompleted)
            elseif lockoutType == "currencies" then
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(lockout.id)
                local isCompleted = currencyInfo and currencyInfo.quantity > 0
                LMAHI_SavedData.lockouts[charName][lockoutId] = isCompleted
                print("LMAHI Debug: Checked", lockoutType, lockout.name, "(ID:", lockout.id, ") for", charName, "->", isCompleted)
            end
        end
    end
end

function LMAHI.InitializeLockouts()
    for charName, _ in pairs(LMAHI_SavedData.characters) do
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
end

function LMAHI.CleanLockouts()
    for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
        for lockoutId, _ in pairs(lockouts) do
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

function LMAHI.CheckResetTimers()
    local serverTime = GetServerTime()
    local dateTable = C_DateAndTime.GetCurrentCalendarTime()
    local weekday = dateTable.weekday -- 1=Sunday, 2=Monday, ..., 7=Saturday
    local hours, minutes = dateTable.hour, dateTable.minute
    local timeInSeconds = hours * 3600 + minutes * 60

    -- Weekly reset: Tuesday at 10 AM server time
    local weeklyResetTime = 10 * 3600 -- 10 AM in seconds
    local secondsSinceSunday = (weekday - 1) * 86400 + timeInSeconds
    local secondsUntilTuesday = (3 - weekday) * 86400 + weeklyResetTime - timeInSeconds
    if weekday > 3 then
        secondsUntilTuesday = secondsUntilTuesday + 7 * 86400
    elseif weekday == 3 and timeInSeconds >= weeklyResetTime then
        secondsUntilTuesday = secondsUntilTuesday + 7 * 86400
    end
    local nextWeeklyReset = serverTime + secondsUntilTuesday

    -- Daily reset: 3 AM server time (adjustable based on region)
    local dailyResetTime = 3 * 3600 -- 3 AM in seconds
    local secondsUntilDailyReset = dailyResetTime - timeInSeconds
    if secondsUntilDailyReset <= 0 then
        secondsUntilDailyReset = secondsUntilDailyReset + 86400
    end
    local nextDailyReset = serverTime + secondsUntilDailyReset

    -- Check if weekly reset has occurred
    if LMAHI_SavedData.lastWeeklyReset < serverTime and serverTime >= nextWeeklyReset - 86400 then
        print("LMAHI Debug: Weekly reset detected at", dateTable.month .. "/" .. dateTable.monthDay .. "/" .. dateTable.year .. " " .. hours .. ":" .. minutes)
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
            for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                if lockoutType == "raids" or lockoutType == "dungeons" or lockoutType == "quests" or (lockoutType == "custom" and LMAHI.lockoutData[lockoutType]) then
                    for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                        if lockoutType == "quests" or lockoutType == "raids" or lockoutType == "dungeons" or (lockoutType == "custom" and lockout.reset == "weekly") then
                            local lockoutId = tostring(lockout.id)
                            lockouts[lockoutId] = false
                            print("LMAHI Debug: Reset", lockoutType, lockout.name, "(ID:", lockout.id, ") for", charName)
                        end
                    end
                end
            end
        end
        LMAHI_SavedData.lastWeeklyReset = nextWeeklyReset
    end

    -- Check if daily reset has occurred
    if LMAHI_SavedData.lastDailyReset < serverTime and serverTime >= nextDailyReset - 86400 then
        print("LMAHI Debug: Daily reset detected at", dateTable.month .. "/" .. dateTable.monthDay .. "/" .. dateTable.year .. " " .. hours .. ":" .. minutes)
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
            for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                if lockoutType == "rares" or (lockoutType == "custom" and LMAHI.lockoutData[lockoutType]) then
                    for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                        if lockoutType == "rares" or (lockoutType == "custom" and lockout.reset == "daily") then
                            local lockoutId = tostring(lockout.id)
                            lockouts[lockoutId] = false
                            print("LMAHI Debug: Reset", lockoutType, lockout.name, "(ID:", lockout.id, ") for", charName)
                        end
                    end
                end
            end
        end
        LMAHI_SavedData.lastDailyReset = nextDailyReset
    end
end
