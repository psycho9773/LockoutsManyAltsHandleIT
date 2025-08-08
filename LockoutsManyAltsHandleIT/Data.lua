-- Data.lua

local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

-- Define lockout types
LMAHI.lockoutTypes = {
    "custom",
    "raids",
    "dungeons",
    "quests",
    "rares",
    "currencies",
}

-- Initialize lockout data
LMAHI.InitializeData = function()
    LMAHI.lockoutData = LMAHI.lockoutData or {}
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        LMAHI.lockoutData[lockoutType] = LMAHI.lockoutData[lockoutType] or {}
    end

--  Abreviations  "TWW", "DF", "SL", "BFA", "LGN", "WOD", "MOP", "CAT", "WLK", "TBC", "WOW"

    -- Raids
    LMAHI.lockoutData.raids = {
        { id = 1273, name = "Nerub-ar Palace", reset = "weekly", expansion = "TWW" },
        { id = 2003, name = "Liberation of Undermine", reset = "weekly", expansion = "TWW" },
        { id = 2002, name = "Manaforge Omega", reset = "weekly", expansion = "TWW" },
        { id = 1207, name = "Amirdrassil, the Dream's Hope", reset = "weekly", expansion = "DF" },
        { id = 1234, name = "Vault of the Incarnates", reset = "weekly", expansion = "DF" },
        { id = 5678, name = "Aberrus, the Shadowed Crucible", reset = "weekly", expansion = "DF" },
        { id = 2296, name = "Castle Nathria", reset = "weekly", expansion = "SL" },
        { id = 2450, name = "Sanctum of Domination", reset = "weekly", expansion = "weekly", expansion = "SL" },
        { id = 2481, name = "Sepulcher of the First Ones", reset = "weekly", expansion = "SL" },
		{ id = 1861, name = "Uldir", reset = "weekly", expansion = "BFA" },
		{ id = 2070, name = "Battle of Dazar'alor", reset = "weekly", expansion = "BFA" },
		{ id = 2096, name = "Crucible of Storms", reset = "weekly", expansion = "BFA" },
		{ id = 2164, name = "The Eternal Palace", reset = "weekly", expansion = "BFA" },
		{ id = 2217, name = "Ny'alotha, the Waking City", reset = "weekly", expansion = "BFA" },
		{ id = 1520, name = "The Emerald Nightmare", reset = "weekly", expansion = "LGN" },
		{ id = 1648, name = "Trial of Valor", reset = "weekly", expansion = "LGN" },
		{ id = 1530, name = "The Nighthold", reset = "weekly", expansion = "LGN" },
		{ id = 1676, name = "Tomb of Sargeras", reset = "weekly", expansion = "LGN" },
		{ id = 1712, name = "Antorus, the Burning Throne", reset = "weekly", expansion = "LGN" }, -- All LFR N H M from here up
		{ id = 1228, name = "Highmaul", reset = "weekly", expansion = "WOD" },
		{ id = 1205, name = "Blackrock Foundry", reset = "weekly", expansion = "WOD" },
		{ id = 1448, name = "Hellfire Citadel", reset = "weekly", expansion = "WOD" },
		{ id = 1008, name = "Mogu'shan Vaults", reset = "weekly", expansion = "MOP" },
		{ id = 1009, name = "Heart of Fear", reset = "weekly", expansion = "MOP" },
		{ id = 1010, name = "Terrace of Endless Spring", reset = "weekly", expansion = "MOP" },
		{ id = 1098, name = "Throne of Thunder", reset = "weekly", expansion = "MOP" },
		{ id = 1136, name = "Siege of Orgrimmar", reset = "weekly", expansion = "MOP" },  -- LFR N H for all except SoO got mythic
		{ id = 752, name = "Baradin Hold", reset = "weekly", expansion = "CAT" },
		{ id = 758, name = "Blackwing Descent", reset = "weekly", expansion = "CAT" },
		{ id = 773, name = "The Bastion of Twilight", reset = "weekly", expansion = "CAT" },
		{ id = 754, name = "Throne of the Four Winds", reset = "weekly", expansion = "CAT" },
		{ id = 720, name = "Firelands", reset = "weekly", expansion = "CAT" },
		{ id = 967, name = "Dragon Soul", reset = "weekly", expansion = "CAT" },
		{ id = 249, name = "Onyxia's Lair", reset = "weekly", expansion = "WLK" },
		{ id = 533, name = "Naxxramas", reset = "weekly", expansion = "WLK" },
		{ id = 603, name = "Ulduar", reset = "weekly", expansion = "WLK" },
		{ id = 615, name = "The Obsidian Sanctum", reset = "weekly", expansion = "WLK" },
		{ id = 616, name = "The Eye of Eternity", reset = "weekly", expansion = "WLK" },
		{ id = 624, name = "Vault of Archavon", reset = "weekly", expansion = "WLK" },
		{ id = 631, name = "Icecrown Citadel", reset = "weekly", expansion = "WLK" },
		{ id = 649, name = "Trial of the Crusader", reset = "weekly", expansion = "WLK" },
		{ id = 724, name = "The Ruby Sanctum", reset = "weekly", expansion = "WLK" },
		{ id = 532, name = "Karazhan", reset = "weekly", expansion = "TBC" },
		{ id = 565, name = "Gruul's Lair", reset = "weekly", expansion = "TBC" },
		{ id = 544, name = "Magtheridon's Lair", reset = "weekly", expansion = "TBC" },
		{ id = 548, name = "Serpentshrine Cavern", reset = "weekly", expansion = "TBC" },
		{ id = 550, name = "Tempest Keep", reset = "weekly", expansion = "TBC" },
		{ id = 534, name = "Hyjal Summit", reset = "weekly", expansion = "TBC" },
		{ id = 564, name = "Black Temple", reset = "weekly", expansion = "TBC" },
		{ id = 580, name = "Sunwell Plateau", reset = "weekly", expansion = "TBC" },
		{ id = 409, name = "Molten Core", reset = "weekly", expansion = "WOW" },
		{ id = 469, name = "Blackwing Lair", reset = "weekly", expansion = "WOW" },
		{ id = 509, name = "Ruins of Ahn'Qiraj", reset = "weekly", expansion = "WOW" },
		{ id = 531, name = "Temple of Ahn'Qiraj", reset = "weekly", expansion = "WOW" },
    }

    -- Dungeons
    LMAHI.lockoutData.dungeons = {
        { id = 2549, name = "The Rookery", reset = "daily", expansion = "TWW" },
        { id = 2550, name = "The Stonevault", reset = "daily", expansion = "TWW" },
        { id = 2551, name = "Priory of the Sacred Flame", reset = "daily", expansion = "TWW" },
        { id = 2552, name = "City of Threads", reset = "daily", expansion = "TWW" },
        { id = 2553, name = "Cinderbrew Meadery", reset = "daily", expansion = "TWW" },
        { id = 2554, name = "Darkflame Cleft", reset = "daily", expansion = "TWW" },
        { id = 2555, name = "The Dawnbreaker", reset = "daily", expansion = "TWW" },
        { id = 2556, name = "Ara-Kara, City of Echoes", reset = "daily", expansion = "TWW" },
        { id = 2557, name = "Operation: Floodgate", reset = "daily", expansion = "TWW" },
        { id = 2558, name = "Eco-Dome Al’dani", reset = "daily", expansion = "TWW" },
		{ id = 2451, name = "Uldaman: Legacy of Tyr", reset = "daily", expansion = "DF" },
        { id = 2515, name = "Neltharus", reset = "daily", expansion = "DF" },
        { id = 2516, name = "The Nokhud Offensive", reset = "daily", expansion = "DF" },
        { id = 2517, name = "The Azure Vault", reset = "daily", expansion = "DF" },
        { id = 2518, name = "Algeth’ar Academy", reset = "daily", expansion = "DF" },
        { id = 2519, name = "Brackenhide Hollow", reset = "daily", expansion = "DF" },
        { id = 2520, name = "Ruby Life Pools", reset = "daily", expansion = "DF" },
        { id = 2521, name = "Halls of Infusion", reset = "daily", expansion = "DF" },
        { id = 2569, name = "Dawn of the Infinite: Galakrond's Fall", reset = "daily", expansion = "DF" },
        { id = 2570, name = "Dawn of the Infinite: Murozond's Rise", reset = "daily", expansion = "DF" },
		{ id = 2284, name = "Sanguine Depths", reset = "daily", expansion = "SL" },
        { id = 2285, name = "Spires of Ascension", reset = "daily", expansion = "SL" },
        { id = 2286, name = "The Necrotic Wake", reset = "daily", expansion = "SL" },
        { id = 2287, name = "Halls of Atonement", reset = "daily", expansion = "SL" },
        { id = 2289, name = "Plaguefall", reset = "daily", expansion = "SL" },
        { id = 2290, name = "Mists of Tirna Scithe", reset = "daily", expansion = "SL" },
        { id = 2291, name = "De Other Side", reset = "daily", expansion = "SL" },
        { id = 2293, name = "Theater of Pain", reset = "daily", expansion = "SL" },
        { id = 2441, name = "Tazavesh, the Veiled Market", reset = "daily", expansion = "SL" },
		{ id = 1594, name = "The MOTHERLODE!!", reset = "daily", expansion = "BFA" },
		{ id = 1754, name = "Freehold", reset = "daily", expansion = "BFA" },
		{ id = 1762, name = "Kings' Rest", reset = "daily", expansion = "BFA" },
		{ id = 1763, name = "Atal'Dazar", reset = "daily", expansion = "BFA" },
		{ id = 1771, name = "Tol Dagor", reset = "daily", expansion = "BFA" },
		{ id = 1822, name = "Siege of Boralus", reset = "daily", expansion = "BFA" },
		{ id = 1841, name = "The Underrot", reset = "daily", expansion = "BFA" },
		{ id = 1862, name = "Waycrest Manor", reset = "daily", expansion = "BFA" },
		{ id = 1864, name = "Shrine of the Storm", reset = "daily", expansion = "BFA" },
		{ id = 1877, name = "Temple of Sethraliss", reset = "daily", expansion = "BFA" },
		{ id = 2097, name = "Operation: Mechagon", reset = "daily", expansion = "BFA" },
		{ id = 1456, name = "Eye of Azshara", reset = "daily", expansion = "LGN" },
		{ id = 1458, name = "Neltharion's Lair", reset = "daily", expansion = "LGN" },
		{ id = 1466, name = "Darkheart Thicket", reset = "daily", expansion = "LGN" },
		{ id = 1477, name = "Halls of Valor", reset = "daily", expansion = "LGN" },
		{ id = 1492, name = "Maw of Souls", reset = "daily", expansion = "LGN" },
		{ id = 1493, name = "Vault of the Wardens", reset = "daily", expansion = "LGN" },
		{ id = 1501, name = "Black Rook Hold", reset = "daily", expansion = "LGN" },
		{ id = 1516, name = "The Arcway", reset = "daily", expansion = "LGN" },
		{ id = 1544, name = "Assault on Violet Hold", reset = "daily", expansion = "LGN" },
		{ id = 1571, name = "Court of Stars", reset = "daily", expansion = "LGN" },
		{ id = 1651, name = "Return to Karazhan", reset = "daily", expansion = "LGN" },
		{ id = 1677, name = "Cathedral of Eternal Night", reset = "daily", expansion = "LGN" },
		{ id = 1753, name = "Seat of the Triumvirate", reset = "daily", expansion = "LGN" },
		{ id = 1175, name = "Bloodmaul Slag Mines", reset = "daily", expansion = "WOD" },
		{ id = 1195, name = "Iron Docks", reset = "daily", expansion = "WOD" },
		{ id = 1182, name = "Auchindoun", reset = "daily", expansion = "WOD" },
		{ id = 1209, name = "Skyreach", reset = "daily", expansion = "WOD" },
		{ id = 1208, name = "Grimrail Depot", reset = "daily", expansion = "WOD" },
		{ id = 1176, name = "Shadowmoon Burial Grounds", reset = "daily", expansion = "WOD" },
		{ id = 1279, name = "The Everbloom", reset = "daily", expansion = "WOD" },
		{ id = 1358, name = "Upper Blackrock Spire", reset = "daily", expansion = "WOD" },  --mythic was implemented for dungeons
		{ id = 959, name = "Temple of the Jade Serpent", reset = "daily", expansion = "MOP" },
		{ id = 960, name = "Stormstout Brewery", reset = "daily", expansion = "MOP" },
		{ id = 961, name = "Shado-Pan Monastery", reset = "daily", expansion = "MOP" },
		{ id = 962, name = "Mogu'shan Palace", reset = "daily", expansion = "MOP" },
		{ id = 963, name = "Gate of the Setting Sun", reset = "daily", expansion = "MOP" },
		{ id = 964, name = "Siege of Niuzao Temple", reset = "daily", expansion = "MOP" },
		{ id = 1001, name = "Scarlet Halls", reset = "daily", expansion = "MOP" },
		{ id = 1004, name = "Scarlet Monastery", reset = "daily", expansion = "MOP" },
		{ id = 1007, name = "Scholomance", reset = "daily", expansion = "MOP" },
		{ id = 645, name = "Blackrock Caverns", reset = "daily", expansion = "CAT" },
		{ id = 643, name = "Throne of the Tides", reset = "daily", expansion = "CAT" },
		{ id = 725, name = "The Stonecore", reset = "daily", expansion = "CAT" },
		{ id = 657, name = "The Vortex Pinnacle", reset = "daily", expansion = "CAT" },
		{ id = 755, name = "Lost City of the Tol'vir", reset = "daily", expansion = "CAT" },
		{ id = 644, name = "Halls of Origination", reset = "daily", expansion = "CAT" },
		{ id = 670, name = "Grim Batol", reset = "daily", expansion = "CAT" },
		{ id = 859.1, name = "Zul'Aman", reset = "daily", expansion = "CAT" },
		{ id = 859, name = "Zul'Gurub", reset = "daily", expansion = "CAT" },
		{ id = 938, name = "End Time", reset = "daily", expansion = "CAT" },
		{ id = 939, name = "Well of Eternity", reset = "daily", expansion = "CAT" },
		{ id = 940, name = "Hour of Twilight", reset = "daily", expansion = "CAT" },
		{ id = 574, name = "Utgarde Keep", reset = "daily", expansion = "WLK" },
		{ id = 575, name = "Utgarde Pinnacle", reset = "daily", expansion = "WLK" },
		{ id = 576, name = "The Nexus", reset = "daily", expansion = "WLK" },
		{ id = 578, name = "The Oculus", reset = "daily", expansion = "WLK" },
		{ id = 595, name = "The Culling of Stratholme", reset = "daily", expansion = "WLK" },
		{ id = 599, name = "Halls of Stone", reset = "daily", expansion = "WLK" },
		{ id = 600, name = "Drak'Tharon Keep", reset = "daily", expansion = "WLK" },
		{ id = 601, name = "Azjol-Nerub", reset = "daily", expansion = "WLK" },
		{ id = 602, name = "Halls of Lightning", reset = "daily", expansion = "WLK" },
		{ id = 604, name = "Gundrak", reset = "daily", expansion = "WLK" },
		{ id = 608, name = "The Violet Hold", reset = "daily", expansion = "WLK" },
		{ id = 619, name = "Ahn'kahet: The Old Kingdom", reset = "daily", expansion = "WLK" },
		{ id = 632, name = "The Forge of Souls", reset = "daily", expansion = "WLK" },
		{ id = 650, name = "Trial of the Champion", reset = "daily", expansion = "WLK" },
		{ id = 658, name = "Pit of Saron", reset = "daily", expansion = "WLK" },
		{ id = 668, name = "Halls of Reflection", reset = "daily", expansion = "WLK" },
		{ id = 542, name = "The Blood Furnace", reset = "daily", expansion = "TBC" },
		{ id = 543, name = "Hellfire Ramparts", reset = "daily", expansion = "TBC" },
		{ id = 540, name = "The Shattered Halls", reset = "daily", expansion = "TBC" },
		{ id = 547, name = "The Slave Pens", reset = "daily", expansion = "TBC" },
		{ id = 546, name = "The Underbog", reset = "daily", expansion = "TBC" },
		{ id = 545, name = "The Steamvault", reset = "daily", expansion = "TBC" },
		{ id = 557, name = "Mana-Tombs", reset = "daily", expansion = "TBC" },
		{ id = 558, name = "Auchenai Crypts", reset = "daily", expansion = "TBC" },
		{ id = 556, name = "Sethekk Halls", reset = "daily", expansion = "TBC" },
		{ id = 555, name = "Shadow Labyrinth", reset = "daily", expansion = "TBC" },
		{ id = 560, name = "Old Hillsbrad Foothills", reset = "daily", expansion = "TBC" },
		{ id = 269, name = "The Black Morass", reset = "daily", expansion = "TBC" },
		{ id = 554, name = "The Mechanar", reset = "daily", expansion = "TBC" },
		{ id = 553, name = "The Botanica", reset = "daily", expansion = "TBC" },
		{ id = 552, name = "The Arcatraz", reset = "daily", expansion = "TBC" },
		{ id = 585, name = "Magisters' Terrace", reset = "daily", expansion = "TBC" },  -- Heroic implemented for dungeons SFK and Deadmines from classic
		{ id = 764, name = "Shadowfang Keep (CAT)", reset = "daily", expansion = "WOW" },
		{ id = 756, name = "The Deadmines (CAT)", reset = "daily", expansion = "WOW" },
		{ id = 33, name = "Shadowfang Keep", reset = "daily", expansion = "WOW" },
		{ id = 36, name = "The Deadmines", reset = "daily", expansion = "WOW" },	
		{ id = 34, name = "The Stockade", reset = "daily", expansion = "WOW" },
		{ id = 43, name = "Wailing Caverns", reset = "daily", expansion = "WOW" },
		{ id = 47, name = "Razorfen Kraul", reset = "daily", expansion = "WOW" },
		{ id = 48, name = "Blackfathom Deeps", reset = "daily", expansion = "WOW" },
		{ id = 70, name = "Uldaman", reset = "daily", expansion = "WOW" },
		{ id = 90, name = "Gnomeregan", reset = "daily", expansion = "WOW" },
		{ id = 109, name = "The Temple of Atal'Hakkar", reset = "daily", expansion = "WOW" },
		{ id = 129, name = "Razorfen Downs", reset = "daily", expansion = "WOW" },
		{ id = 209, name = "Zul'Farrak", reset = "daily", expansion = "WOW" },
		{ id = 229, name = "Blackrock Spire", reset = "daily", expansion = "WOW" },
		{ id = 230, name = "Blackrock Depths", reset = "daily", expansion = "WOW" },
		{ id = 329, name = "Stratholme", reset = "daily", expansion = "WOW" },
		{ id = 349, name = "Maraudon", reset = "daily", expansion = "WOW" },
		{ id = 389, name = "Ragefire Chasm", reset = "daily", expansion = "WOW" },
		{ id = 429, name = "Dire Maul", reset = "daily", expansion = "WOW" },
    }

    -- Quests
    LMAHI.lockoutData.quests = {
	    { id = 86464, name = "11.2  Devourer Attack: The Atrium", reset = "weekly", expansion = "TWW" },
	    { id = 91855, name = "11.2  Worldsoul: K'aresh World Quests", reset = "weekly", expansion = "TWW" },
		{ id = 88902, name = "11.2  Phase Diving: Restless Souls", reset = "weekly", expansion = "TWW" },
		{ id = 91093, name = "11.2  More Than Just a Phase", reset = "weekly", expansion = "TWW" },
		{ id = 89294, name = "11.2  Special Assignment: Aligned Views", reset = "weekly", expansion = "TWW" },
		{ id = 86447, name = "11.2  Devourer Attack: Eco-dome: Primus", reset = "weekly", expansion = "TWW" },
		{ id = 85863, name = "11.2  Phase Diving: Strange Storms", reset = "weekly", expansion = "TWW" },
        { id = 86775, name = "11.1  Urge to Surge", reset = "weekly", expansion = "TWW" },
        { id = 85879, name = "11.1  Reduce, Reuse, Resell", reset = "weekly", expansion = "TWW" },
        { id = 85869, name = "11.1  Many Jobs, Handle It!", reset = "weekly", expansion = "TWW" },
        { id = 85088, name = "11.1  The Main Event - The Gobfather", reset = "weekly", expansion = "TWW" },
    }

    -- Rares
    LMAHI.lockoutData.rares = {
		{ id = 90593, name = "11.2 Urmag", reset = "weekly", expansion = "TWW" },
		{ id = 90699, name = "11.2 Grubber", reset = "weekly", expansion = "TWW" },
	    { id = 90693, name = "11.2 Shadowguard Portalseer", reset = "weekly", expansion = "TWW" },
	   -- { id = 90692, name = "11.2 Shadowguard Portalseer", reset = "weekly", expansion = "TWW" }, --both show up true ?
        { id = 90488, name = "11.1  M.A.G.N.O.", reset = "weekly", expansion = "TWW" },
        { id = 90489, name = "11.1  Giovante", reset = "weekly", expansion = "TWW" },
        { id = 90490, name = "11.1  Voltstrike the Charged", reset = "weekly", expansion = "TWW" },
        { id = 90491, name = "11.1  Scrapchewer", reset = "weekly", expansion = "TWW" },
        { id = 90492, name = "11.1  Darkfuse Precipitant", reset = "weekly", expansion = "TWW" },
        { id = 84877, name = "11.1  Ephemeral Agent Lathyd", reset = "weekly", expansion = "TWW" },
        { id = 84895, name = "11.1  Slugger the Smart", reset = "weekly", expansion = "TWW" },
        { id = 84907, name = "11.1  Chief Foreman Gutso", reset = "weekly", expansion = "TWW" },
        { id = 84884, name = "11.1  The Junk-Wall", reset = "weekly", expansion = "TWW" },
        { id = 84911, name = "11.1  Flyboy Snooty", reset = "weekly", expansion = "TWW" },
        { id = 87007, name = "11.1  Gallagio Garbage", reset = "daily", expansion = "TWW" },
        { id = 84927, name = "11.1  Candy Stickemup", reset = "daily", expansion = "TWW" },
        { id = 84928, name = "11.1  Grimewick", reset = "daily", expansion = "TWW" },
        { id = 84919, name = "11.1  Tally Doublespeak", reset = "daily", expansion = "TWW" },
        { id = 84920, name = "11.1  V.V. Goosworth", reset = "daily", expansion = "TWW" },
        { id = 84917, name = "11.1  Scrapbeak", reset = "daily", expansion = "TWW" },
        { id = 84926, name = "11.1  Nitro", reset = "daily", expansion = "TWW" },
        { id = 85004, name = "11.1  Swigs Farsight", reset = "daily", expansion = "TWW" },
        { id = 84921, name = "11.1  Thwack", reset = "daily", expansion = "TWW" },
        { id = 84922, name = "11.1  S.A.L.", reset = "daily", expansion = "TWW" },
        { id = 84918, name = "11.1  Ratspit", reset = "daily", expansion = "TWW" },
    }

    -- Currencies
LMAHI.lockoutData.currencies = {

     -- Move these up each exapansion
    { id = 2123, name = "Bloody Tokens", expansion = "TWW" },
	{ id = 1602, name = "Conquest", expansion = "TWW" },
	{ id = 1792, name = "Honor", expansion = "TWW" , isAccountWide = true },
	{ id = 1166, name = "Timewarped", expansion = "TWW", isAccountWide = true },
	{ id = 2032, name = "Trader's Tender", expansion = "TWW" , isAccountWide = true },
	{ id = 2588, name = "Riders of Azeroth Badge", expansion = "TWW" , isAccountWide = true },
	{ id = 3309, name = "Hellstone Shard", expansion = "TWW" , isAccountWide = true },
	{ id = 515, name = "Darkmoon Prize Ticket", expansion = "TWW" , isAccountWide = true },
	-- All of TWW
	{ id = 3149, name = "Displaced Corrupted Memntos", expansion = "TWW", isAccountWide = true },
	{ id = 3218, name = "Empty Kaja'Cola Can", expansion = "TWW", isAccountWide = true },
    { id = 3090, name = "Flame-Blessed Iron", expansion = "TWW", isAccountWide = true },
    { id = 3056, name = "Kej", expansion = "TWW", isAccountWide = true },
	{ id = 3226, name = "Market Research", expansion = "TWW", isAccountWide = true },
	{ id = 3055, name = "Mereldar Derby Mark", expansion = "TWW", isAccountWide = true },
	{ id = 3093, name = "Nerub-ar Finery", expansion = "TWW", isAccountWide = true },
	{ id = 3089, name = "Residual Memories", expansion = "TWW", isAccountWide = true },
	{ id = 2815, name = "Resonance Crystals", expansion = "TWW", isAccountWide = true },
	{ id = 3303, name = "Untethered Coin", expansion = "TWW", isAccountWide = true },
    { id = 3220, name = "Vintage Kaja'Cola Can", expansion = "TWW", isAccountWide = true },
	{ id = 3008, name = "Valorstones", expansion = "TWW", isAccountWide = true },
	{ id = 2803, name = "Undercoin", expansion = "TWW", isAccountWide = true },
	{ id = 3278, name = "Ethereal Strands", expansion = "TWW", isAccountWide = true },
	-- season 3
	{ id = 3028, name = "Restored Coffer Key", expansion = "TWW" },
	{ id = 3284, name = "11.2 Weathered Ethereal Crest", expansion = "TWW" },
	{ id = 3286, name = "11.2 Carved Ethereal Crest", expansion = "TWW" },
	{ id = 3289, name = "11.2 Runed Ethereal Crest", expansion = "TWW" },
	{ id = 3290, name = "11.2 Gilded Ethereal Crest", expansion = "TWW" },	
	{ id = 3141, name = "11.2 Starlight Spark Dust", expansion = "TWW" },		

	-- season 2
    { id = 3107, name = "11.1 Weathered Undermine Crest", expansion = "TWW" },
    { id = 3108, name = "11.1 Carved Undermine Crest", expansion = "TWW" },
    { id = 3109, name = "11.1 Runed Undermine Crest", expansion = "TWW" },
	{ id = 3110, name = "11.1 Gilded Undermine Crest", expansion = "TWW" },
	{ id = 3116, name = "11.1 Essence of Kaja'mite", expansion = "TWW" },





}



    -- Custom lockouts
    LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts or {}

    -- Initialize lockouts for all characters
    if LMAHI.InitializeLockouts then
        LMAHI.InitializeLockouts()
    end
end
