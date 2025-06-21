local addonName, addon = ...
local LMAHI = _G.LMAHI

LMAHI.lockoutTypes = {
    "custom",
    "raids",
    "dungeons",
    "quests",
    "rares",
    "currencies",
}

LMAHI.lockoutData = {
    custom = {}, -- Initialize as empty; populated in Core.lua
    raids = {
        { id = 1, name = "Amirdrassil, the Dream's Hope" },
        { id = 2, name = "Vault of the Incarnates" },
        { id = 3, name = "Aberrus, the Shadowed Crucible" },
        { id = 4, name = "Nerub-ar Palace" },
    },
    dungeons = {
        { id = 101, name = "The Nokhud Offensive" },
        { id = 102, name = "Brackenhide Hollow" },
        { id = 103, name = "Halls of Infusion" },
        { id = 104, name = "Algeth'ar Academy" },
        { id = 105, name = "Ruby Life Pools" },
        { id = 106, name = "Neltharus" },
        { id = 107, name = "The Azure Vault" },
        { id = 108, name = "Uldaman: Legacy of Tyr" },
        { id = 109, name = "Dawn of the Infinite" },
    },
    quests = {
        { id = 70627, name = "Aiding the Accord" },
        { id = 70893, name = "Aiding the Accord: Dragonbane Keep" },
        { id = 71210, name = "Aiding the Accord: The Hunt" },
        { id = 72068, name = "Aiding the Accord: The Isles Call" },
    },
    rares = {
        { id = 69928, name = "Zaqali Elders" },
        { id = 73166, name = "Aurostor the Hibernator" },
    },
    currencies = {
        { id = 2245, name = "Flightstones" },
        { id = 2003, name = "Dragon Isles Supplies" },
        { id = 2122, name = "Storm Sigil" },
        { id = 2118, name = "Elemental Overflow" },
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
