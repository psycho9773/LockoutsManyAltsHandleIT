-- Utilities.lua
local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

function LMAHI.SaveCharacterData()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    local _, class, _, _, _, _, faction = GetPlayerInfoByGUID(UnitGUID("player"))
    local playerFaction = UnitFactionGroup("player") or "Neutral"

    LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.classColors = LMAHI_SavedData.classColors or {}
    LMAHI_SavedData.factions = LMAHI_SavedData.factions or {}
    LMAHI_SavedData.factionColors = LMAHI_SavedData.factionColors or {}
    LMAHI_SavedData.charOrder = LMAHI_SavedData.charOrder or {}
    
    LMAHI_SavedData.characters[charName] = true
    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    LMAHI_SavedData.factions[charName] = playerFaction
    
    -- Store class colors
    local classColor = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
    LMAHI_SavedData.classColors[charName] = { r = classColor.r, g = classColor.g, b = classColor.b }
    
    -- Store faction colors
    local factionColor = playerFaction == "Horde" and { r = 1, g = 0, b = 0 }
        or playerFaction == "Alliance" and { r = 0, g = 0, b = 1 }
        or { r = 0.8, g = 0.8, b = 0.8 }
    LMAHI_SavedData.factionColors[charName] = { r = factionColor.r, g = factionColor.g, b = factionColor.b }
    
    -- Assign or update character order
    if not LMAHI_SavedData.charOrder[charName] then
        local maxOrder = 0
        for _, order in pairs(LMAHI_SavedData.charOrder) do
            maxOrder = math.max(maxOrder, order)
        end
        LMAHI_SavedData.charOrder[charName] = maxOrder + 1
        print("LMAHI Debug: Registered character " .. charName .. " with order " .. (maxOrder + 1))
    end
    
    -- Initialize lockouts for this character
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            local lockoutId = tostring(lockout.id)
            LMAHI_SavedData.lockouts[charName][lockoutId] = LMAHI_SavedData.lockouts[charName][lockoutId] or false
        end
    end
end

function LMAHI.CheckLockouts()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    
    -- Check saved instances
    local numSaved = GetNumSavedInstances()
    for i = 1, numSaved do
        local name, id, _, _, locked, _, _, _, _, _, encounterProgress, _ = GetSavedInstanceInfo(i)
        if locked and id then
            local lockoutId = tostring(id)
            LMAHI_SavedData.lockouts[charName][lockoutId] = true
        end
    end
    
    -- Check world bosses
    local numWorldBosses = GetNumSavedWorldBosses()
    for i = 1, numWorldBosses do
        local name, id, _ = GetSavedWorldBossInfo(i)
        if id then
            local lockoutId = tostring(id)
            LMAHI_SavedData.lockouts[charName][lockoutId] = true
        end
    end
    
    -- Check quests
    local completedQuests = C_QuestLog.GetAllCompletedQuestIDs()
    for _, questId in ipairs(completedQuests or {}) do
        local lockoutId = tostring(questId)
        if LMAHI_SavedData.lockouts[charName][lockoutId] == nil then
            for _, lockout in ipairs(LMAHI.lockoutData.quests or {}) do
                if lockout.id == questId then
                    LMAHI_SavedData.lockouts[charName][lockoutId] = true
                    break
                end
            end
        end
    end
    
    -- Check currencies
    for _, currency in ipairs(LMAHI.lockoutData.currencies or {}) do
        local lockoutId = tostring(currency.id)
        local info = C_CurrencyInfo.GetCurrencyInfo(currency.id)
        if info and info.quantity >= currency.max then
            LMAHI_SavedData.lockouts[charName][lockoutId] = true
        end
    end
    
    -- Check custom lockouts
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        local lockoutId = tostring(lockout.id)
        LMAHI_SavedData.lockouts[charName][lockoutId] = LMAHI_SavedData.lockouts[charName][lockoutId] or false
    end
end

function LMAHI.InitializeLockouts()
    LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
    LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
    
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
        for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                local lockoutId = tostring(lockout.id)
                if lockout.id <= 0 then
                else
                    LMAHI_SavedData.lockouts[charName][lockoutId] = LMAHI_SavedData.lockouts[charName][lockoutId] or false
                end
            end
        end
    end
end

function LMAHI.CleanLockouts()
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
                    if tostring(lockout.id) == lockoutId then
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

function LMAHI.NormalizeCustomLockoutOrder()
    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        table.insert(customList, lockout)
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

function LMAHI.CheckResetTimers()
    local currentTime = time()
    local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()
    local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    
    local nextDailyReset = currentTime + dailyReset
    local nextWeeklyReset = currentTime + weeklyReset
    
    if LMAHI_SavedData.lastDailyReset == 0 or LMAHI_SavedData.lastDailyReset < currentTime then
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts or {}) do
            for _, lockout in ipairs(LMAHI.lockoutData.quests or {}) do
                if lockout.reset == "daily" then
                    local lockoutId = tostring(lockout.id)
                    lockouts[lockoutId] = false
                end
            end
            for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
                if lockout.reset == "daily" then
                    local lockoutId = tostring(lockout.id)
                    lockouts[lockoutId] = false
                end
            end
        end
        LMAHI_SavedData.lastDailyReset = nextDailyReset
    end
    
    if LMAHI_SavedData.lastWeeklyReset == 0 or LMAHI_SavedData.lastWeeklyReset < currentTime then
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts or {}) do
            for _, lockout in ipairs(LMAHI.lockoutData.raids or {}) do
                local lockoutId = tostring(lockout.id)
                lockouts[lockoutId] = false
            end
            for _, lockout in ipairs(LMAHI.lockoutData.worldBosses or {}) do
                local lockoutId = tostring(lockout.id)
                lockouts[lockoutId] = false
            end
            for _, lockout in ipairs(LMAHI.lockoutData.quests or {}) do
                if lockout.reset == "weekly" then
                    local lockoutId = tostring(lockout.id)
                    lockouts[lockoutId] = false
                end
            end
            for _, lockout in ipairs(LMAHI.lockoutData.currencies or {}) do
                local lockoutId = tostring(lockout.id)
                lockouts[lockoutId] = false
            end
            for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
                if lockout.reset == "weekly" then
                    local lockoutId = tostring(lockout.id)
                    lockouts[lockoutId] = false
                end
            end
        end
        LMAHI_SavedData.lastWeeklyReset = nextWeeklyReset
    end
end
