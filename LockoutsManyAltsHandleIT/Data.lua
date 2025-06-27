-- Data.lua
local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

LMAHI.InitializeData = function()
    LMAHI.lockoutTypes = {
        "custom",
        "raids",
        "dungeons",
        "quests",
        "rares",
        "currencies",
    }

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
        { id = 83347, name = "Urge to Surge", reset = "weekly" },
        { id = 83346, name = "Reduce, Reuse, Resell", reset = "weekly" },
        { id = 83345, name = "Many Jobs, Handle It!", reset = "weekly" },
    }

    -- Rares
    LMAHI.lockoutData.rares = {
        { id = 84877, name = "Ephemeral Agent Lathyd", reset = "weekly" },
        { id = 84895, name = "Slugger the Smartfiltered", reset = "weekly" },
        { id = 84907, name = "Chief Foreman Gutso", reset = "weekly" },
        { id = 90491, name = "Scrapchewer", reset = "weekly" },
        { id = 84884, name = "The Junk-Wall", reset = "weekly" },
        { id = 84911, name = "Flyboy Snooty", reset = "weekly" },
        { id = 90488, name = "M.A.G.N.O.", reset = "weekly" },
        { id = 90489, name = "Giovante", reset = "weekly" },
        { id = 90490, name = "Voltstrike the Charged", reset = "weekly" },
        { id = 90492, name = "Darkfuse Precipitant", reset = "weekly" },
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
