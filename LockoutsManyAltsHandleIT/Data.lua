--- Data.lua

local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

LMAHI.lockoutTypes = {
    "custom",
    "raids",
    "dungeons",
    "quests",
    "rares",
    "currencies",
}

LMAHI.InitializeData = function()
    LMAHI.lockoutData = LMAHI.lockoutData or {}
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        LMAHI.lockoutData[lockoutType] = LMAHI.lockoutData[lockoutType] or {}
    end

    -- Raids
    LMAHI.lockoutData.raids = {
        { id = 1273, name = "Nerub-ar Palace", reset = "weekly" },
        { id = 2003, name = "Liberation of Undermine", reset = "weekly" },
        { id = 2002, name = "Manaforge Omega", reset = "weekly" },
        { id = 1207, name = "Amirdrassil, the Dream's Hope", reset = "weekly" },
        { id = 1234, name = "Vault of the Incarnates", reset = "weekly" },
        { id = 5678, name = "Aberrus, the Shadowed Crucible", reset = "weekly" },
    }

    -- Dungeons
    LMAHI.lockoutData.dungeons = {
        { id = 1001, name = "The Rookery", reset = "daily" },
        { id = 1002, name = "The Stonevault", reset = "daily" },
        { id = 1003, name = "Priory of the Sacred Flame", reset = "daily" },
        { id = 1004, name = "City of Threads", reset = "daily" },
        { id = 1005, name = "Cinderbrew Meadery", reset = "daily" },
        { id = 1006, name = "Darkflame Cleft", reset = "daily" },
        { id = 1007, name = "The Dawnbreaker", reset = "daily" },
        { id = 1008, name = "Ara-Kara, City of Echoes", reset = "daily" },
        { id = 1009, name = "Operation: Floodgate", reset = "daily" },
        { id = 1010, name = "Eco-Dome Al’dani", reset = "daily" },
    }

    -- Quests
    LMAHI.lockoutData.quests = {
        { id = 86775, name = "Urge to Surge", reset = "weekly" },
        { id = 85879, name = "Reduce, Reuse, Resell", reset = "weekly" },
        { id = 85869, name = "Many Jobs, Handle It!", reset = "weekly" },
    }

    -- Rares
    LMAHI.lockoutData.rares = {
        { id = 84877, name = "Ephemeral Agent Lathyd", reset = "weekly" },
        { id = 84895, name = "Slugger the Smart", reset = "weekly" },
        { id = 84907, name = "Chief Foreman Gutso", reset = "weekly" },
        { id = 90491, name = "Scrapchewer", reset = "weekly" },
        { id = 84884, name = "The Junk-Wall", reset = "weekly" },
        { id = 84911, name = "Flyboy Snooty", reset = "weekly" },
        { id = 90488, name = "M.A.G.N.O.", reset = "weekly" },
        { id = 90489, name = "Giovante", reset = "weekly" },
        { id = 90490, name = "Voltstrike the Charged", reset = "weekly" },
        { id = 90492, name = "Darkfuse Precipitant", reset = "weekly" },
        { id = 87007, name = "Gallagio Garbage", reset = "daily" },
        { id = 84927, name = "Candy Stickemup", reset = "daily" },
        { id = 84928, name = "Grimewick", reset = "daily" },
        { id = 84919, name = "Tally Doublespeak", reset = "daily" },
        { id = 84920, name = "V.V. Goosworth", reset = "daily" },
        { id = 84917, name = "Scrapbeak", reset = "daily" },
        { id = 84926, name = "Nitro", reset = "daily" },
        { id = 85004, name = "Swigs Farsight", reset = "daily" },
        { id = 84921, name = "Thwack", reset = "daily" },
        { id = 84922, name = "S.A.L.", reset = "daily" },
        { id = 84918, name = "Ratspit", reset = "daily" },
    }

    -- Currencies
    LMAHI.lockoutData.currencies = {
        { id = 1166, name = "Timewarped Badge", max = 500, reset = "weekly" },
        { id = 1828, name = "Valorstones", max = 2000, reset = "weekly" },
        { id = 3008, name = "Resonance Crystals", max = 1000, reset = "weekly" },
    }

    -- Custom lockouts (populated from saved data)
    LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts or {}

    -- Initialize lockouts for all characters
    if LMAHI.InitializeLockouts then
        LMAHI.InitializeLockouts()
    end
end

function LMAHI.SaveCharacterData()
    local charName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI_SavedData.characters[charName] = true
    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
    local _, class = UnitClass("player")
    local _, _, _, r, g, b = GetClassColor(class)
    LMAHI_SavedData.classColors[charName] = { r = r, g = g, b = b }
    local faction = UnitFactionGroup("player")
    LMAHI_SavedData.factions[charName] = faction

    -- Initialize lockouts for this character
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            local lockoutId = tostring(lockout.id)
            if not LMAHI_SavedData.lockouts[charName][lockoutId] then
                LMAHI_SavedData.lockouts[charName][lockoutId] = false
            end
        end
    end

    -- Ensure all characters have lockout entries for all lockouts
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
        for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                local lockoutId = tostring(lockout.id)
                if not LMAHI_SavedData.lockouts[charName][lockoutId] then
                    LMAHI_SavedData.lockouts[charName][lockoutId] = false
                end
            end
        end
    end
end

function LMAHI.CheckLockouts(event, arg1)
    local charName = UnitName("player") .. "-" .. GetRealmName()
    LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}

    -- Check raid lockouts
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, _, _, _, _, _, numEncounters = GetSavedInstanceInfo(i)
        if locked then
            for _, lockout in ipairs(LMAHI.lockoutData.raids) do
                if lockout.name == name then
                    LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = true
                end
            end
        end
    end

    -- Check dungeon lockouts
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, _, _, _, _, _, numEncounters = GetSavedInstanceInfo(i)
        if locked and difficulty == 23 then -- Mythic difficulty
            for _, lockout in ipairs(LMAHI.lockoutData.dungeons) do
                if lockout.name == name then
                    LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = true
                end
            end
        end
    end

    -- Check quest lockouts
    for _, lockout in ipairs(LMAHI.lockoutData.quests) do
        local lockoutId = tostring(lockout.id)
        local isLocked = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)

        LMAHI_SavedData.lockouts[charName][lockoutId] = isLocked
    end

    -- Check rare lockouts
    for _, lockout in ipairs(LMAHI.lockoutData.rares) do
        local lockoutId = tostring(lockout.id)
        local isLocked = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)

        LMAHI_SavedData.lockouts[charName][lockoutId] = isLocked
    end

    -- Check currency lockouts
    for _, lockout in ipairs(LMAHI.lockoutData.currencies) do
        local lockoutId = tostring(lockout.id)
        local _, currentAmount = C_CurrencyInfo.GetCurrencyInfo(lockout.id)
        local isLocked = currentAmount and currentAmount >= (lockout.max or math.huge)
        LMAHI_SavedData.lockouts[charName][lockoutId] = isLocked
    end

    -- Check custom lockouts (only for current character)
    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
        local lockoutId = tostring(lockout.id)
        local isLocked = C_QuestLog.IsQuestFlaggedCompleted(lockout.id)

        LMAHI_SavedData.lockouts[charName][lockoutId] = isLocked
    end
end

function LMAHI.InitializeLockouts()
    LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts or {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
        for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                local lockoutId = tostring(lockout.id)
                if not LMAHI_SavedData.lockouts[charName][lockoutId] then
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
                lockouts[lockoutId] = nil
            end
        end
    end
end

function LMAHI.CheckResetTimers()
    local currentTime = time()
    local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()

    if weeklyReset <= 0 then
        LMAHI_SavedData.lastWeeklyReset = currentTime + weeklyReset
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
            for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    if lockout.reset == "weekly" then
                        lockouts[tostring(lockout.id)] = false
                    end
                end
            end
        end
    end

    if dailyReset <= 0 then
        LMAHI_SavedData.lastDailyReset = currentTime + dailyReset
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
            for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    if lockout.reset == "daily" then
                        lockouts[tostring(lockout.id)] = false
                    end
                end
            end
        end
    end
end
