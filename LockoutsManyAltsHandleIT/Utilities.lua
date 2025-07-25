----- Utilities.lua

local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

LMAHI.SaveCharacterData = function()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    local _, class, _, _, _, _, faction = GetPlayerInfoByGUID(UnitGUID("player"))
    local playerFaction = UnitFactionGroup("player") or "Neutral"

    LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.classColors = LMAHI_SavedData.classColors or {}
    LMAHI_SavedData.factions = LMAHI_SavedData.factions or {}
    LMAHI_SavedData.charOrder = LMAHI_SavedData.charOrder or {}
    
    LMAHI_SavedData.characters[charName] = true
    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    LMAHI_SavedData.factions[charName] = playerFaction
    
    -- Store class colors
    local classColor = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
    LMAHI_SavedData.classColors[charName] = { r = classColor.r, g = classColor.g, b = classColor.b }
    
    -- Assign or update character order
    if not LMAHI_SavedData.charOrder[charName] then
        local maxOrder = 0
        for _, order in pairs(LMAHI_SavedData.charOrder) do
            maxOrder = math.max(maxOrder, order)
        end
        LMAHI_SavedData.charOrder[charName] = maxOrder + 1
        print("LMAHI Debug: Registered character " .. charName .. " with order " .. (maxOrder + 1))
    end
end

LMAHI.CheckLockouts = function(event, questId)
    local charName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}

    -- Clear existing lockouts for the specified types
    for _, lockoutType in ipairs({"custom", "raids", "dungeons", "quests", "rares", "currencies"}) do
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            local lockoutId = tostring(lockout.id)
            LMAHI_SavedData.lockouts[charName][lockoutId] = nil
        end
    end
    
    -- Handle QUEST_TURNED_IN for both quests and rares
    if event == "QUEST_TURNED_IN" and questId then
        for _, lockoutType in ipairs({"quests", "rares"}) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                if lockout.id and lockout.id == questId then
                    local lockoutId = tostring(questId)
                    LMAHI_SavedData.lockouts[charName][lockoutId] = true
                    break
                end
            end
        end
    end
    
    -- Check saved instances
    local numSaved = GetNumSavedInstances()
    for i = 1, numSaved do
        local name, id, _, _, locked, _, _, _, _, _, encounterProgress, _ = GetSavedInstanceInfo(i)
        if locked and id then
            for _, lockout in ipairs(LMAHI.lockoutData.raids) do
                if lockout.id == id then
                    LMAHI_SavedData.lockouts[charName][tostring(id)] = true
                    break
                end
            end
            for _, lockout in ipairs(LMAHI.lockoutData.dungeons) do
                if lockout.id == id then
                    LMAHI_SavedData.lockouts[charName][tostring(id)] = true
                    break
                end
            end
        end
    end
    
    -- Check both quests and rares for completions
    local completedQuests = C_QuestLog.GetAllCompletedQuestIDs() or {}
    for _, qId in ipairs(completedQuests) do
        for _, lockoutType in ipairs({"quests", "rares"}) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                if lockout.id and lockout.id == qId then
                    local lockoutId = tostring(qId)
                    LMAHI_SavedData.lockouts[charName][lockoutId] = true
                    break
                end
            end
        end
    end
    
    -- Check currencies
    for _, currency in ipairs(LMAHI.lockoutData.currencies or {}) do
        if currency.id then
            local lockoutId = tostring(currency.id)
            local info = C_CurrencyInfo.GetCurrencyInfo(currency.id)
            if info and info.quantity >= (currency.max or math.huge) then
                LMAHI_SavedData.lockouts[charName][lockoutId] = true
            end
        end
    end
    
    -- Check custom lockouts
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        if lockout.id and C_QuestLog.IsQuestFlaggedCompleted(lockout.id) then
            local lockoutId = tostring(lockout.id)
            LMAHI_SavedData.lockouts[charName][lockoutId] = true
        end
    end
end

LMAHI.InitializeLockouts = function()
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
    
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    end
end

LMAHI.CleanLockouts = function()
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
    
    -- Initialize lockouts for all characters
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    end
    
    -- Clean up stale lockouts
    for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
        for lockoutId, _ in pairs(lockouts) do
            local isValid = false
            for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    if lockout.id and tostring(lockout.id) == lockoutId then
                        isValid = true
                        break
                    end
                end
                if isValid then break end
            end
            if not isValid then
                lockouts[lockoutId] = nil
            end
        end
    end
end

LMAHI.NormalizeCustomLockoutOrder = function()
    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        if lockout.id then
            table.insert(customList, lockout)
        end
    end
    
    local newOrder = {}
    local usedOrders = {}
    for _, lockout in ipairs(customList) do
        local lockoutId = tostring(lockout.id)
        local order = LMAHI_SavedData.customLockoutOrder[lockoutId] or 999
        while usedOrders[order] do
            order = order + 1
        end
        newOrder[lockoutId] = order
        usedOrders[order] = true
    end
    
    LMAHI_SavedData.customLockoutOrder = newOrder
end

LMAHI.CheckResetTimers = function()
    local currentTime = time()
    local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()
    local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    
    local nextDailyReset = currentTime + dailyReset
    local nextWeeklyReset = currentTime + weeklyReset
    
    -- Only reset if past the recorded reset time and not already reset
    if LMAHI_SavedData.lastDailyReset < currentTime and LMAHI_SavedData.lastDailyReset ~= nextDailyReset then
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts or {}) do
            for _, lockoutType in ipairs({"custom", "dungeons", "rares"}) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    if lockout.reset == "daily" then
                        local lockoutId = tostring(lockout.id)
                        lockouts[lockoutId] = nil
                    end
                end
            end
        end
        LMAHI_SavedData.lastDailyReset = nextDailyReset
        print("LMAHI Debug: Daily reset performed at " .. date("%Y-%m-%d %H:%M:%S", currentTime))
    end
    
    if LMAHI_SavedData.lastWeeklyReset < currentTime and LMAHI_SavedData.lastWeeklyReset ~= nextWeeklyReset then
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts or {}) do
            for _, lockoutType in ipairs({"custom", "raids", "dungeons", "quests", "rares", "currencies"}) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    if lockout.reset == "weekly" then
                        local lockoutId = tostring(lockout.id)
                        lockouts[lockoutId] = nil
                    end
                end
            end
        end
        LMAHI_SavedData.lastWeeklyReset = nextWeeklyReset
        print("LMAHI Debug: Weekly reset performed at " .. date("%Y-%m-%d %H:%M:%S", currentTime))
    end
end

Utilities = Utilities or {}

-- Run garbage collection after 10s, then every 300s
Utilities.StartGarbageCollector = function(initialDelay, repeatInterval)
    initialDelay = initialDelay or 10       -- seconds before first run
    repeatInterval = repeatInterval or 300   -- seconds between runs

    local frame = CreateFrame("Frame")
    local elapsed = 0
    local started = false

    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta

        if not started and elapsed >= initialDelay then
            collectgarbage("collect")
            elapsed = 0
            started = true
        elseif started and elapsed >= repeatInterval then
            collectgarbage("collect")
            elapsed = 0
        end
    end)
end

-- Slash commands

SLASH_LMAHI1 = "/lmahi"
SlashCmdList["LMAHI"] = function()
    mainFrame:SetShown(not mainFrame:IsShown())
    if mainFrame:IsShown() then
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
        if LMAHI.CheckLockouts then
            LMAHI.CheckLockouts()
        end
        ThrottledUpdateDisplay()
    end
end


SLASH_LMAHIWIPE1 = "/lmahiwipe"
SlashCmdList["LMAHIWIPE"] = function()
    StaticPopupDialogs["LMAHIWIPE_CONFIRM"] = {
        text = "Are you sure you want to wipe all saved data?",
        button1 = "Yes",
        button2 = "Cancel",
        OnAccept = function()
            LMAHI_SavedData = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("LMAHIWIPE_CONFIRM")
end

