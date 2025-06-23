local addonName, addon = ...
local LMAHI = _G.LMAHI or {}

-- Safeguard to ensure LMAHI is initialized
if not _G.LMAHI then
    print("LMAHI Error: Addon namespace not initialized in Data.lua. Ensure Core.lua loads first.")
    _G.LMAHI = LMAHI
end

LMAHI.lockoutTypes = {
    "custom",
    "raids",
    "dungeons",
    "quests",
    "rares",
    "currencies",
}

LMAHI.lockoutData = {
    custom = LMAHI_SavedData and LMAHI_SavedData.customLockouts or {},
    raids = {
        { id = 1, name = "Amirdrassil, the Dream's Hope", reset = "weekly" },
        { id = 2, name = "Vault of the Incarnates", reset = "weekly" },
        { id = 3, name = "Aberrus, the Shadowed Crucible", reset = "weekly" },
        { id = 4, name = "Nerub-ar Palace", reset = "weekly" },
    },
    dungeons = {
        { id = 101, name = "The Nokhud Offensive", reset = "weekly" },
        { id = 102, name = "Brackenhide Hollow", reset = "weekly" },
        { id = 103, name = "Halls of Infusion", reset = "weekly" },
        { id = 104, name = "Algeth'ar Academy", reset = "weekly" },
        { id = 105, name = "Ruby Life Pools", reset = "weekly" },
        { id = 106, name = "Neltharus", reset = "weekly" },
        { id = 107, name = "The Azure Vault", reset = "weekly" },
        { id = 108, name = "Uldaman: Legacy of Tyr", reset = "weekly" },
        { id = 109, name = "Dawn of the Infinite", reset = "weekly" },
    },
    quests = {
        { id = 70627, name = "Aiding the Accord", reset = "weekly" },
        { id = 70893, name = "Aiding the Accord: Dragonbane Keep", reset = "weekly" },
        { id = 71210, name = "Aiding the Accord: The Hunt", reset = "weekly" },
        { id = 72068, name = "Aiding the Accord: The Isles Call", reset = "weekly" },
    },
    rares = {
        { id = 69928, name = "Zaqali Elders", reset = "daily" },
        { id = 73166, name = "Aurostor the Hibernator", reset = "daily" },
        { id = 84884, name = "The Junk-Wall", reset = "daily" },
        { id = 84895, name = "Slugger the Smart", reset = "daily" },
    },
    currencies = {
        { id = 2245, name = "Flightstones", reset = "none" },
        { id = 2003, name = "Dragon Isles Supplies", reset = "none" },
        { id = 2122, name = "Storm Sigil", reset = "none" },
        { id = 2118, name = "Elemental Overflow", reset = "none" },
    },
}

LMAHI.FACTION_COLORS = {
    Alliance = { r = 0.0, g = 0.4, b = 1.0 },
    Horde = { r = 1.0, g = 0.0, b = 0.0 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}

LMAHI.CLASS_COLORS = {
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
    EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
    MONK = { r = 0.00, g = 1.00, b = 0.59 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
}
