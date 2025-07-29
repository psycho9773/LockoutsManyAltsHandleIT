
-- Display.lua
-
local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

-- Initialize saved variables early to prevent nil errors
LMAHI_SavedData = LMAHI_SavedData or {}
LMAHI_SavedData.sectionVisibility = LMAHI_SavedData.sectionVisibility or {
    custom = true,
    raids = true,
    dungeons = true,
    quests = true,
    rares = true,
    currencies = true
}
LMAHI_SavedData.expansionVisibility = LMAHI_SavedData.expansionVisibility or {
    TWW = true,
    DF = true,
    SL = true,
    BFA = true,
    LGN = true,
    WOD = true,
    MOP = true,
    CAT = true,
    WLK = true,
    TBC = true,
    WOW = true
}
LMAHI_SavedData.previousLockoutVisibility = LMAHI_SavedData.previousLockoutVisibility or {}

LMAHI.currentPage = LMAHI.currentPage or 1
LMAHI.maxCharsPerPage = 10
LMAHI.maxPages = nil -- Calculate dynamically
LMAHI.lockoutLabels = LMAHI.lockoutLabels or {}
LMAHI.collapseButtons = LMAHI.collapseButtons or {}
LMAHI.hoverRegions = LMAHI.hoverRegions or {}
LMAHI.lastUpdateTime = LMAHI.lastUpdateTime or 0
LMAHI.updateThrottle = 0.5 -- Throttle updates to every 0.5 seconds
LMAHI.cachedCharList = LMAHI.cachedCharList or {}
LMAHI.cachedCharLabels = LMAHI.cachedCharLabels or {}
LMAHI.cachedSectionHeaders = LMAHI.cachedSectionHeaders or {}
LMAHI.lastDisplayChars = LMAHI.lastDisplayChars or {}
LMAHI.canPagePrevious = false -- Flag for Core.lua to disable Previous button
LMAHI.canPageNext = false -- Flag for Core.lua to disable Next button

-- Object pools for reusing UI elements (excluding character labels)
local buttonPool = {} -- Used for collapse buttons
local checkButtonPool = {}
local hoverRegionPool = {} -- Pool for hover regions

-- Pool management functions
local function AcquireButton(parent)
    local btn = next(buttonPool)
    if btn then
        buttonPool[btn] = nil
        btn:SetParent(parent)
        btn:ClearAllPoints()
        btn:SetSize(0, 0)
        btn:SetFrameLevel(0)
        btn:SetNormalTexture("")
        btn:SetHighlightTexture("")
        btn:EnableMouse(false)
        btn:Hide()
        return btn
    end
    btn = CreateFrame("Button", nil, parent)
    return btn
end

local function ReleaseButton(btn)
    btn:Hide()
    btn:ClearAllPoints()
    btn:SetSize(0, 0)
    btn:SetNormalTexture("")
    btn:SetHighlightTexture("")
    btn:EnableMouse(false)
    btn:SetFrameLevel(0)
    btn:SetScript("OnEnter", nil)
    btn:SetScript("OnLeave", nil)
    btn:SetScript("OnClick", nil)
    buttonPool[btn] = true
end

local function AcquireCheckButton(parent)
    local cb = next(checkButtonPool)
    if cb then
        checkButtonPool[cb] = nil
        cb:SetParent(parent)
        cb:Show()
        return cb
    end
    cb = CreateFrame("CheckButton", nil, parent)
    cb:SetNormalTexture("Interface\\Buttons\\UI-RadioButton")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-RadioButton")
    cb:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
    cb:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
    return cb
end

local function ReleaseCheckButton(cb)
    cb:Hide()
    cb:ClearAllPoints()
    cb:SetChecked(false)
    cb:SetScript("OnEnter", nil)
    cb:SetScript("OnLeave", nil)
    cb:SetScript("OnClick", nil)
    cb:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
    cb:GetCheckedTexture():SetVertexColor(1, 1, 1, 1)
    checkButtonPool[cb] = true
end

local function AcquireHoverRegion(parent)
    local region = next(hoverRegionPool)
    if region then
        hoverRegionPool[region] = nil
        region:SetParent(parent)
        region:ClearAllPoints()
        region:SetSize(0, 0)
        region:SetFrameLevel(0)
        region:SetNormalTexture("")
        region:SetHighlightTexture("")
        region:EnableMouse(false)
        region:Hide()
        return region
    end
    region = CreateFrame("Button", nil, parent)
    return region
end

local function ReleaseHoverRegion(region)
    region:Hide()
    region:ClearAllPoints()
    region:SetSize(0, 0)
    region:SetNormalTexture("")
    region:SetHighlightTexture("")
    region:EnableMouse(false)
    region:SetScript("OnEnter", nil)
    region:SetScript("OnLeave", nil)
    hoverRegionPool[region] = true
end

-- Function to update paging button states
local function UpdatePagingButtons()
    local leftArrow = LMAHI.leftArrow -- Use stored reference
    local rightArrow = LMAHI.rightArrow
    if leftArrow and rightArrow then
        leftArrow:SetEnabled(LMAHI.canPagePrevious)
        rightArrow:SetEnabled(LMAHI.canPageNext)
    end
end

function LMAHI.UpdateDisplay()
    local startTime = debugprofilestop() -- Profile execution time
    local currentTime = GetTime()
    if currentTime - LMAHI.lastUpdateTime < LMAHI.updateThrottle then
        return
    end
    LMAHI.lastUpdateTime = currentTime

    if not LMAHI.mainFrame or not LMAHI.lockoutScrollFrame or not LMAHI.lockoutContent or not LMAHI.charFrame or not LMAHI.highlightFrame then
        return
    end

    -- Create highlight frame for current character if not exists
    if not LMAHI.currentCharHighlight and LMAHI.charFrame then
        LMAHI.currentCharHighlight = CreateFrame("Frame", nil, LMAHI.charFrame, "BackdropTemplate")
        LMAHI.currentCharHighlight:SetFrameLevel(LMAHI.charFrame:GetFrameLevel() + 1)
        if LMAHI.currentCharHighlight.SetBackdrop then
            LMAHI.currentCharHighlight:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1.5,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            LMAHI.currentCharHighlight:SetBackdropColor(0, 0, 0, 0.01)
            LMAHI.currentCharHighlight:SetBackdropBorderColor(0.6, 0.8, 1, 0.7)
            LMAHI.currentCharHighlight:Hide()
        end
    end

    -- Ensure currentPage is valid
    if not LMAHI.currentPage or LMAHI.currentPage < 1 then
        LMAHI.currentPage = 1
    end

    -- Reset highlight frames
    LMAHI.highlightFrame:Hide()
    LMAHI.highlightFrame:ClearAllPoints()
    LMAHI.highlightFrame:SetSize(0, 0)
    LMAHI.highlightFrame:SetBackdrop(nil)
    LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0)
    LMAHI.highlightFrame:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() + 1)

    if LMAHI.currentCharHighlight then
        LMAHI.currentCharHighlight:Hide()
        LMAHI.currentCharHighlight:ClearAllPoints()
        LMAHI.currentCharHighlight:SetSize(0, 0)
    end

    -- Release dynamic elements
    for _, label in ipairs(LMAHI.lockoutLabels) do
        if label:IsObjectType("FontString") then
            label:Hide()
            label:ClearAllPoints()
            label:SetText("")
            label:EnableMouse(false)
            label:SetScript("OnEnter", nil)
            label:SetScript("OnLeave", nil)
        elseif label:IsObjectType("CheckButton") then
            ReleaseCheckButton(label)
        elseif label:IsObjectType("Button") then
            ReleaseButton(label)
        end
    end
    for _, button in ipairs(LMAHI.collapseButtons) do
        ReleaseButton(button)
    end
    for _, region in ipairs(LMAHI.hoverRegions) do
        ReleaseHoverRegion(region)
    end
    LMAHI.lockoutLabels = {}
    LMAHI.collapseButtons = {}
    LMAHI.hoverRegions = {}

    -- Clear all children from charFrame except currentCharHighlight
    for _, child in ipairs({LMAHI.charFrame:GetChildren()}) do
        if child ~= LMAHI.currentCharHighlight then
            child:Hide()
            child:ClearAllPoints()
            if child:IsObjectType("FontString") then
                child:SetText("")
            end
        end
    end

    -- Get sorted character list
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        if charName and type(charName) == "string" then
            table.insert(charList, charName)
        end
    end
    if #charList == 0 then
        local emptyLabel = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, -10)
        emptyLabel:SetText("No characters found. Log in to each alt to register.")
        emptyLabel:SetTextColor(1, 1, 1, 1)
        emptyLabel:Show()
        table.insert(LMAHI.lockoutLabels, emptyLabel)
        LMAHI.lockoutContent:SetHeight(30)
        LMAHI.lockoutScrollFrame:UpdateScrollChildRect()
        LMAHI.canPagePrevious = false
        LMAHI.canPageNext = false
        UpdatePagingButtons()
        return
    end

    table.sort(charList, function(a, b)
        local aIndex = LMAHI_SavedData.charOrder[a] or 999
        local bIndex = LMAHI_SavedData.charOrder[b] or 1000
        return aIndex < bIndex or (aIndex == bIndex and a < b)
    end)

    -- Pagination
    local charsPerPage = LMAHI.maxCharsPerPage or 10
    LMAHI.maxPages = math.max(1, math.ceil(#charList / charsPerPage))
    LMAHI.currentPage = math.max(1, math.min(LMAHI.currentPage, LMAHI.maxPages))
    LMAHI.canPagePrevious = LMAHI.currentPage > 1
    LMAHI.canPageNext = LMAHI.currentPage < LMAHI.maxPages
    local startIndex = (LMAHI.currentPage - 1) * charsPerPage + 1
    local endIndex = math.min(startIndex + charsPerPage - 1, #charList)

    local displayChars = {}
    for i = startIndex, endIndex do
        table.insert(displayChars, charList[i])
    end

    -- Get current character
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    local currentCharIndex = nil
    for i, charName in ipairs(charList) do
        if charName == currentChar then
            currentCharIndex = i
            break
        end
    end

    -- Update character and realm labels
    LMAHI.cachedCharLabels = {}
    local charLabelCount = 0
    for i, charName in ipairs(displayChars) do
        local playerName = charName:match("^(.-)-") or charName
        local realmName = charName:match("-(.+)$") or "Unknown"

        local charLabel = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        charLabel:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", 8 + (i-1) * 96, -8)
        charLabel:SetText(playerName)
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        charLabel:Show()
        table.insert(LMAHI.lockoutLabels, charLabel)
        LMAHI.cachedCharLabels[i] = charLabel

        local realmLabel = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        realmLabel:SetPoint("TOPLEFT", charLabel, "BOTTOMLEFT", 0, -2)
        realmLabel:SetText(realmName)
        local faction = LMAHI_SavedData.factions[charName] or "Neutral"
        local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(LMAHI.lockoutLabels, realmLabel)
        LMAHI.cachedCharLabels[i + #displayChars] = realmLabel

        -- Highlight current character
        if currentCharIndex and currentCharIndex == startIndex + i - 1 and LMAHI.currentCharHighlight then
            LMAHI.currentCharHighlight:SetPoint("TOPLEFT", charLabel, "TOPLEFT", -5, 5)
            LMAHI.currentCharHighlight:SetSize(94 + 6, 20 + 13)
            LMAHI.currentCharHighlight:Show()
        end

        charLabelCount = charLabelCount + 2
    end

    LMAHI.cachedCharList = charList
    LMAHI.lastDisplayChars = displayChars

    -- Initialize highlight frame backdrop (for lockout rows)
    LMAHI.highlightFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0)

    -- Lockout sections
    local offsetY = -30
    local headerCount = 0

    -- Helper function to check if an element is within the visible scroll frame area
    local function IsElementInView(element, scrollFrame)
        if not element:IsVisible() then return false end
        local elementTop = element:GetTop()
        local elementBottom = element:GetBottom()
        local scrollFrameTop = scrollFrame:GetTop() + 5
        local scrollFrameBottom = scrollFrame:GetBottom() - 5
        return elementBottom and elementTop and scrollFrameBottom and scrollFrameTop and
               elementBottom >= scrollFrameBottom and elementTop <= scrollFrameTop
    end

    -- Process all lockout types, starting with Custom
    local lockoutTypesDisplay = {"custom"}
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        if lockoutType ~= "custom" then
            table.insert(lockoutTypesDisplay, lockoutType)
        end
    end

    for _, lockoutType in ipairs(lockoutTypesDisplay) do
        if not LMAHI_SavedData.sectionVisibility then
            LMAHI_SavedData.sectionVisibility = {
                custom = true,
                raids = true,
                dungeons = true,
                quests = true,
                rares = true,
                currencies = true
            }
        end
        if LMAHI_SavedData.sectionVisibility[lockoutType] ~= false then
            local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType]
            local collapseButton = AcquireButton(LMAHI.lockoutContent)
            collapseButton:SetSize(20, 20)
            collapseButton:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 25, offsetY)
            collapseButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            collapseButton:GetNormalTexture():SetSize(20, 20)
            collapseButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            collapseButton:GetHighlightTexture():SetSize(20, 20)
            collapseButton:Show()

            collapseButton:SetScript("OnEnter", function(self)
                if not IsElementInView(self, LMAHI.lockoutScrollFrame) then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -35, 5)
                GameTooltip:SetText(isCollapsed and "Expand" or "Collapse", 0.9, 0.7, 0.1)
                GameTooltip:Show()
            end)
            collapseButton:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            collapseButton:SetScript("OnClick", function()
                LMAHI_SavedData.collapsedSections[lockoutType] = not LMAHI_SavedData.collapsedSections[lockoutType]
                LMAHI.UpdateDisplay()
            end)

            table.insert(LMAHI.collapseButtons, collapseButton)

            local sectionHeader = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
            sectionHeader:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 50, offsetY - 1)
            sectionHeader:SetText(lockoutType:gsub("^%l", string.upper))
            sectionHeader:SetTextColor(1, 1, 1, 1)
            sectionHeader:Show()
            table.insert(LMAHI.lockoutLabels, sectionHeader)
            LMAHI.cachedSectionHeaders[lockoutType] = sectionHeader

            headerCount = headerCount + 1
            offsetY = offsetY - 25

            if not isCollapsed then
                local lockouts = lockoutType == "custom" and (LMAHI_SavedData.customLockouts or {}) or (LMAHI.lockoutData[lockoutType] or {})
                local sortedLockouts = {}
                for _, lockout in ipairs(lockouts) do
                    if lockoutType == "custom" or LMAHI_SavedData.expansionVisibility[lockout.expansion or "TWW"] ~= false then
                        table.insert(sortedLockouts, lockout)
                    end
                end
                if lockoutType == "custom" then
                    table.sort(sortedLockouts, function(a, b)
                        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1000
                        return aIndex < bIndex or (aIndex == bIndex and a.id < b.id)
                    end)
                end

                if #sortedLockouts == 0 then
                    local noLockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    noLockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 30, offsetY)
                    noLockoutLabel:SetText("No " .. lockoutType .. " found")
                    noLockoutLabel:SetTextColor(1, 1, 1, 1)
                    noLockoutLabel:Show()
                    table.insert(LMAHI.lockoutLabels, noLockoutLabel)
                    offsetY = offsetY - 15
                else
                    offsetY = offsetY + 1
                    for lockoutIndex, lockout in ipairs(sortedLockouts) do
                        local lockoutKey = lockoutType == "custom" and ("Custom_" .. lockout.id) or ((lockout.expansion or "TWW") .. "_" .. lockoutType .. "_" .. lockout.id)
                        if lockout.name and lockout.id and lockout.id > 0 and LMAHI_SavedData.lockoutVisibility[lockoutKey] == true then
                            local lockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                            lockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 30, offsetY)
                            lockoutLabel:SetWidth(170)
                            lockoutLabel:SetText(lockout.name)
                            lockoutLabel:SetTextColor(0.9, 0.7, 0.1)
                            lockoutLabel:SetWordWrap(false)
                            lockoutLabel:SetMaxLines(1)
                            lockoutLabel:SetJustifyH("LEFT")
                            lockoutLabel:Show()

                            table.insert(LMAHI.lockoutLabels, lockoutLabel)

                            local hoverRegion = AcquireHoverRegion(LMAHI.lockoutContent)
                            hoverRegion:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 0, offsetY)
                            hoverRegion:SetSize(1155, 10)
                            hoverRegion:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() - 1)
                            hoverRegion:EnableMouse(true)
                            hoverRegion:Show()
                            hoverRegion:SetScript("OnEnter", function(self)
                                if not IsElementInView(self, LMAHI.lockoutScrollFrame) then return end
                                LMAHI.highlightFrame:ClearAllPoints()
                                LMAHI.highlightFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 8, 0)
                                LMAHI.highlightFrame:SetSize(1155, 10)
                                LMAHI.highlightFrame:SetBackdropColor(0.3, 0.3, 0.3, .3)
                                LMAHI.highlightFrame:Show()
                            end)
                            hoverRegion:SetScript("OnLeave", function()
                                LMAHI.highlightFrame:Hide()
                                LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0)
                            end)
                            table.insert(LMAHI.hoverRegions, hoverRegion)

                            for i, charName in ipairs(displayChars) do
                                if lockoutType == "currencies" then
                                    local currencyAmount = nil
                                    local lockoutId = tostring(lockout.id)
                                    local isAccountWide = lockout.isAccountWide or false

                                    if charName == currentChar then
                                        local info = C_CurrencyInfo.GetCurrencyInfo(lockout.id)
                                        if info then
                                            currencyAmount = info.quantity ~= 0 and info.quantity or nil
                                            isAccountWide = info.isAccountWide or lockout.isAccountWide or false
                                            LMAHI_SavedData.currencyInfo[charName] = LMAHI_SavedData.currencyInfo[charName] or {}
                                            LMAHI_SavedData.currencyInfo[charName][lockoutId] = currencyAmount
                                        else
                                            currencyAmount = nil
                                        end
                                    else
                                        currencyAmount = (LMAHI_SavedData.currencyInfo[charName] and LMAHI_SavedData.currencyInfo[charName][lockoutId]) or nil
                                        if currencyAmount == 0 then currencyAmount = nil end
                                    end

                                    if currencyAmount then
                                        local amountLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                                        amountLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 205 + (i-1) * 96, offsetY)
                                        amountLabel:SetWidth(80)
                                        amountLabel:SetJustifyH("CENTER")
                                        amountLabel:SetText(tostring(currencyAmount))
                                        if isAccountWide then
                                            amountLabel:SetTextColor(0.6, 0.8, 1, 1) -- Blue for account-wide
                                        else
                                            amountLabel:SetTextColor(1, 1, 1, 1) -- White for character-specific
                                        end
                                        amountLabel:Show()
                                        table.insert(LMAHI.lockoutLabels, amountLabel)
                                    else
                                        -- Display blank for missing or zero currency
                                        local amountLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                                        amountLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 205 + (i-1) * 96, offsetY - 2)
                                        amountLabel:SetWidth(80)
                                        amountLabel:SetJustifyH("CENTER")
                                        amountLabel:SetText("")
                                        amountLabel:SetTextColor(1, 1, 1, 1)
                                        amountLabel:Show()
                                        table.insert(LMAHI.lockoutLabels, amountLabel)
                                    end
									
-- Display for Raids and Dungeons
elseif lockoutType == "raids" or lockoutType == "dungeons" then
    local difficulties, difficultyIds, colorCodes
    if lockoutType == "raids" then
        difficulties = lockout.expansion == "CAT" and {"N", "H"} or {"Lfr", "N", "H", "M"}
        difficultyIds = lockout.expansion == "CAT" and {14, 15} or {17, 14, 15, 16}
        colorCodes = lockout.expansion == "CAT" and {"|cff00ff00", "|cffffff00"} or {"|cff3399ff", "|cff00ff00", "|cffffff00", "|cffff8000"}
    else -- lockoutType == "dungeons"
        local legacyExpansions = {["DF"] = true, ["SL"] = true, ["BFA"] = true, ["LGN"] = true, ["WOD"] = true, ["MOP"] = true, ["CAT"] = true, ["WLK"] = true, ["TBC"] = true, ["WOW"] = true}
        if lockout.expansion == "TWW" then
            difficulties = {"H", "M0", "M+"}
            difficultyIds = {2, 8, 8} -- Heroic, Mythic, Mythic+
            colorCodes = {"|cffffff00", "|cffff8000", "|cffa335ee"} -- Yellow, Orange, Purple
        else -- Legacy expansions
            difficulties = {"H", "M"}
            difficultyIds = {2, 23} -- Heroic, Legacy Mythic
            colorCodes = {"|cffffff00", "|cffff8000"} -- Yellow, Orange
        end
    end
    local baseX = 210 + (i-1) * 96
    local hitboxWidth = 20
    local activeDifficulties = {}
    local lockoutKey = lockoutType == "custom" and ("Custom_" .. lockout.id) or ((lockout.expansion or "TWW") .. "_" .. lockoutType .. "_" .. lockout.id)

    for j, difficulty in ipairs(difficulties) do
        local diffLockoutId = tostring(lockout.id) .. "-" .. difficulty
        local isLocked = false
        local colorCode = colorCodes[j]
        local mythicPlusLevel = nil

        if charName == currentChar then
            local instanceIndex
            for k = 1, GetNumSavedInstances() do
                local name, id, _, diff = GetSavedInstanceInfo(k)
                if name == lockout.name and diff == difficultyIds[j] and difficulty ~= "M+" then
                    instanceIndex = k
                    break
                end
            end
            if instanceIndex then
                local _, _, _, _, _, _, _, _, _, _, numEncounters = GetSavedInstanceInfo(instanceIndex)
                local bossesKilled = 0
                for k = 1, numEncounters do
                    local _, _, isKilled = GetSavedInstanceEncounterInfo(instanceIndex, k)
                    if isKilled then bossesKilled = bossesKilled + 1 end
                end
                isLocked = true
                if bossesKilled == numEncounters then
                    colorCode = "|cffff0000" -- Completed
                elseif bossesKilled > 0 then
                    colorCode = "|cff808080" -- Partial
                end
            elseif difficulty == "M+" and lockout.expansion == "TWW" then
                -- Check Mythic+ run history for TWW dungeons
                local runHistory = C_MythicPlus and C_MythicPlus.GetRunHistory and C_MythicPlus.GetRunHistory(false, true) or {}
                for _, run in ipairs(runHistory) do
                    if run.mapChallengeModeID == lockout.id then
                        mythicPlusLevel = run.level
                        colorCode = "|cffa335ee" -- Purple for M+
                        break
                    end
                end
            end
        else
            isLocked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][diffLockoutId] or false
            if difficulty == "M+" then
                mythicPlusLevel = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][diffLockoutId] and LMAHI_SavedData.lockouts[charName][diffLockoutId].mythicPlusLevel or nil
            end
            if isLocked then
                colorCode = "|cffff0000" -- Completed for other characters
            end
        end

        local coloredText = colorCode .. difficulty .. "|r"
        table.insert(activeDifficulties, { difficulty = difficulty, lockoutId = diffLockoutId, difficultyId = difficultyIds[j], isLocked = isLocked, mythicPlusLevel = mythicPlusLevel })

        -- Create individual font string for each difficulty
        local statusLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        statusLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", baseX + (j-1) * hitboxWidth, offsetY)
        statusLabel:SetWidth(hitboxWidth)
        statusLabel:SetJustifyH("CENTER")
        statusLabel:SetText(coloredText)
        statusLabel:EnableMouse(true)
        statusLabel.lockoutId = lockout.id
        statusLabel.lockoutName = lockout.name
        statusLabel.difficultyData = activeDifficulties[j]
        statusLabel.lockoutType = lockoutType
        statusLabel.lockoutKey = lockoutKey
        statusLabel.charName = charName
        statusLabel:SetScript("OnEnter", function(self)
            print("LMAHI Debug: OnEnter triggered for", self.lockoutName, self.difficultyData.difficulty, "Char:", self.charName, "LockoutID:", self.lockoutId, "DiffID:", self.difficultyData.difficultyId)

            if not IsElementInView(self, LMAHI.lockoutScrollFrame) or not self:IsVisible() or not MouseIsOver(self) or LMAHI_SavedData.collapsedSections[self.lockoutType] or LMAHI_SavedData.lockoutVisibility[self.lockoutKey] ~= true then
                print("LMAHI Debug: Tooltip blocked - InView:", IsElementInView(self, LMAHI.lockoutScrollFrame), "Visible:", self:IsVisible(), "Hovered:", MouseIsOver(self), "Collapsed:", LMAHI_SavedData.collapsedSections[self.lockoutType], "Visibility:", LMAHI_SavedData.lockoutVisibility[self.lockoutKey])
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self.lockoutName .. " (" .. self.difficultyData.difficulty .. ")", 1, 1, 1)

            -- Debug: Print available lockout keys
            if LMAHI_SavedData.lockouts[self.charName] then
                print("LMAHI Debug: Lockout keys for", self.charName, ":")
                for key, _ in pairs(LMAHI_SavedData.lockouts[self.charName]) do
                    print("  -", key, "(type:", type(key), ")")
                end
            end

            local savedLockoutId = self.difficultyData.lockoutId
            local lockoutData = LMAHI_SavedData.lockouts[tostring(self.charName)] and LMAHI_SavedData.lockouts[tostring(self.charName)][savedLockoutId]

            if lockoutData and type(lockoutData) == "table" and self.difficultyData.difficulty ~= "M+" then
                print("LMAHI Debug: Lockout data found for", self.charName, self.lockoutName, self.difficultyData.difficulty)
                local bossesKilled = 0
                for k = 1, lockoutData.numEncounters do
                    local bossName = lockoutData.encounters[k] and lockoutData.encounters[k].name or ("Boss " .. k)
                    local isKilled = lockoutData.encounters[k] and lockoutData.encounters[k].isKilled or false
                    GameTooltip:AddLine(bossName .. ": " .. (isKilled and "Killed" or "Available"), isKilled and 1 or 0, isKilled and 0 or 1, 0)
                    if isKilled then bossesKilled = bossesKilled + 1 end
                end
                GameTooltip:AddLine("Progress: " .. bossesKilled .. "/" .. lockoutData.numEncounters, 1, 1, 0)
                if lockoutData.reset > 0 then
                    GameTooltip:AddLine("Resets in: " .. SecondsToTime(lockoutData.reset), 0.8, 0.8, 0.8)
                end
            elseif self.difficultyData.difficulty == "M+" and self.difficultyData.mythicPlusLevel then
                GameTooltip:AddLine("Last Mythic+ Level: " .. self.difficultyData.mythicPlusLevel, 1, 1, 0)
            elseif self.charName == currentChar then
                local instanceIndex
                for k = 1, GetNumSavedInstances() do
                    local name, id, reset, diff = GetSavedInstanceInfo(k)
                    if name == self.lockoutName and diff == self.difficultyData.difficultyId then
                        instanceIndex = k
                        break
                    end
                end
                if instanceIndex then
                    print("LMAHI Debug: Live instance data found for", self.lockoutName, self.difficultyData.difficulty)
                    local _, _, reset, _, _, _, _, _, _, _, numEncounters = GetSavedInstanceInfo(instanceIndex)
                    local bossesKilled = 0
                    for k = 1, numEncounters do
                        local bossName, _, isKilled = GetSavedInstanceEncounterInfo(instanceIndex, k)
                        GameTooltip:AddLine((bossName or ("Boss " .. k)) .. ": " .. (isKilled and "Killed" or "Available"), isKilled and 1 or 0, isKilled and 0 or 1, 0)
                        if isKilled then bossesKilled = bossesKilled + 1 end
                    end
                    GameTooltip:AddLine("Progress: " .. bossesKilled .. "/" .. numEncounters, 1, 1, 0)
                    if reset > 0 then
                        GameTooltip:AddLine("Resets in: " .. SecondsToTime(reset), 0.8, 0.8, 0.8)
                    end
                end
            end
            GameTooltip:Show()
        end)
        statusLabel:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        statusLabel:Show()
        table.insert(LMAHI.lockoutLabels, statusLabel)
    end
                                else
                                    local indicator = AcquireCheckButton(LMAHI.lockoutContent)
                                    indicator:SetSize(16, 16)
                                    indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 200 + (i-1) * 96 + (94 - 16) / 2, offsetY + 1)
                                    local isLocked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] or false
                                    indicator:GetNormalTexture():SetVertexColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2, 1)
                                    indicator:GetCheckedTexture():SetVertexColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2, 1)
                                    indicator:SetChecked(isLocked)
                                    indicator:SetScript("OnEnter", function(self)
                                        if not IsElementInView(self, LMAHI.lockoutScrollFrame) then return end
                                        GameTooltip:SetOwner(self, "ANCHOR_TOP")
                                        GameTooltip:AddLine(isLocked and "Locked" or "Available", isLocked and 1 or 0, isLocked and 0 or 1, 0)
                                        GameTooltip:Show()
                                    end)
                                    indicator:SetScript("OnLeave", function()
                                        GameTooltip:Hide()
                                    end)
                                    indicator:SetScript("OnClick", function()
                                        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
                                        if isLocked then
                                            LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = nil
                                        else
                                            LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = true
                                        end
                                        LMAHI.UpdateDisplay()
                                    end)
                                    table.insert(LMAHI.lockoutLabels, indicator)
                                end
                            end
                            offsetY = offsetY - 18
                        end
                    end
                    offsetY = offsetY - 5
                end
            end
        end
    end

    LMAHI.lockoutContent:SetHeight(math.abs(offsetY) + 20)
    LMAHI.lockoutScrollFrame:UpdateScrollChildRect()

    -- Update paging button states
    UpdatePagingButtons()

    local endTime = debugprofilestop()
end

-- Reset caches on UI open to prevent corruption
function LMAHI:ResetCaches()
    LMAHI.cachedCharList = {}
    LMAHI.cachedCharLabels = {}
    LMAHI.cachedSectionHeaders = {}
    LMAHI.lastDisplayChars = {}
end

-- Update highlight on login or character switch
local function HandleLogin()
    LMAHI:ResetCaches()

    -- Get sorted character list
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        if charName and type(charName) == "string" then
            table.insert(charList, charName)
        end
    end

    if #charList > 0 then
        table.sort(charList, function(a, b)
            local aIndex = LMAHI_SavedData.charOrder[a] or 999
            local bIndex = LMAHI_SavedData.charOrder[b] or 1000
            return aIndex < bIndex or (aIndex == bIndex and a < b)
        end)

        -- Find current character's page
        local currentChar = UnitName("player") .. "-" .. GetRealmName()
        local currentCharIndex = nil
        for i, charName in ipairs(charList) do
            if charName == currentChar then
                currentCharIndex = i
                break
            end
        end

        if currentCharIndex then
            local charsPerPage = LMAHI.maxCharsPerPage or 10
            LMAHI.currentPage = math.max(1, math.ceil(currentCharIndex / charsPerPage))
        else
            LMAHI.currentPage = 1
        end
    else
        LMAHI.currentPage = 1
    end

    LMAHI.UpdateDisplay()
end
