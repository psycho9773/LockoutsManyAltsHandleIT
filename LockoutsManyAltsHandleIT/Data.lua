-- Data.lua
local addonName, addon = ...
local LMAHI = _G.LMAHI

-- Lockout data
LMAHI.lockoutData = {
    custom = LMAHI_SavedData.customLockouts or {
        { id = 99999, name = "Custom Task 1", reset = "weekly" },
        { id = 99998, name = "Custom Task 2", reset = "daily" },
    },
    raids = {
        { id = 1273, name = "Nerub-ar Palace", reset = "weekly" },
        { id = 1207, name = "Amirdrassil, the Dream's Hope", reset = "weekly" },
    },
    dungeons = {
        { id = 2, name = "Ara-Kara, City of Echoes", reset = "daily" },
        { id = 6, name = "The Dawnbreaker", reset = "daily" },
    },
    quests = {
        { id = 83347, name = "Urge to Surge", reset = "weekly" },
        { id = 83346, name = "Reduce, Reuse, Resell", reset = "weekly" },
        { id = 83345, name = "Many Jobs, Handle It!", reset = "weekly" },
    },
    rares = {
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
    },
    currencies = {
        { id = 3056, name = "Resonating Crystal", reset = "weekly" },
        { id = 3008, name = "Valorstones", reset = "weekly" },
    },
}

-- Constants
LMAHI.maxCharsPerPage = 10
LMAHI.maxPages = 10
LMAHI.currentPage = 1
LMAHI.lockoutTypes = { "custom", "raids", "dungeons", "quests", "rares", "currencies" }

LMAHI.CLASS_COLORS = {
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["DRUID"] = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["MAGE"] = { r = 0.25, g = 0.78, b = 0.92 },
    ["MONK"] = { r = 0.00, g = 1.00, b = 0.59 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["PRIEST"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["ROGUE"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["SHAMAN"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["WARLOCK"] = { r = 0.53, g = 0.53, b = 0.93 },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["EVOKER"] = { r = 0.20, g = 0.58, b = 0.50 },
}

LMAHI.FACTION_COLORS = {
    ["Alliance"] = { r = 0.2, g = 0.4, b = 1.0 },
    ["Horde"] = { r = 0.95, g = 0.2, b = 0.2 },
}