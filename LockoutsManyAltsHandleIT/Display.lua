-- Display.lua

local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

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
    else
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
            bgFile = "Interface\\Buttons\\WHITE8X8", --  Solid fill background
            edgeFile = "Interface\\Buttons\\WHITE8X8", --  Thin border texture
            edgeSize = 1.5,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        LMAHI.currentCharHighlight:SetBackdropColor(0, 0, 0, 0.01) --  fill color (RGBA)
        LMAHI.currentCharHighlight:SetBackdropBorderColor(0.6, 0.8, 1, 0.7) --  border color (RGBA)
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
        elseif label:IsObjectType("CheckButton") then
            ReleaseCheckButton(label)
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
        else
        end
    end
    if #charList == 0 then
        local emptyLabel = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, -10)
        emptyLabel:SetText("No characters found. Log in to each alt to register.")
        emptyLabel:SetTextColor(1, 1, 1, 1) -- White for empty message
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

    -- Update character and realm labels (no pooling, fresh creation)
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
        local factionColor = LMAHI_SavedData.factionColors[charName] or { r = 1, g = 1, b = 1 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(LMAHI.lockoutLabels, realmLabel)
        LMAHI.cachedCharLabels[i + #displayChars] = realmLabel

        -- Highlight current character
        if currentCharIndex and currentCharIndex == startIndex + i - 1 and LMAHI.currentCharHighlight then
            LMAHI.currentCharHighlight:SetPoint("TOPLEFT", charLabel, "TOPLEFT", -5, 5)
            LMAHI.currentCharHighlight:SetSize(94 + 6, 20 + 13) -- Slightly larger than character column
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

for _, header in pairs(LMAHI.cachedSectionHeaders) do
    if header:IsObjectType("FontString") then
        header:Hide()
        header:ClearAllPoints()
        header:SetText("")
    end
end
LMAHI.cachedSectionHeaders = {}

if not LMAHI.lockoutTypes or #LMAHI.lockoutTypes == 0 then
    local noTypesLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noTypesLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, offsetY)
    noTypesLabel:SetText("No lockout types defined.")
    noTypesLabel:SetTextColor(1, 1, 1, 1)
    noTypesLabel:Show()
    table.insert(LMAHI.lockoutLabels, noTypesLabel)
    offsetY = offsetY - 20
    headerCount = 1
else
    for lockoutTypeIndex, lockoutType in ipairs(LMAHI.lockoutTypes) do
        if not lockoutType then break end

        local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType]

        local collapseButton = AcquireButton(LMAHI.lockoutContent)
        collapseButton:SetSize(20, 20)
        collapseButton:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 5, offsetY)
        collapseButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up"
                                        or "Interface\\Buttons\\UI-MinusButton-Up")
        collapseButton:Show()

        collapseButton:SetScript("OnEnter", function(self)
            if not IsElementInView(self, LMAHI.lockoutScrollFrame) then return end
            local collapsedNow = LMAHI_SavedData.collapsedSections[lockoutType]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -35, 5)
            GameTooltip:SetText(collapsedNow and "Expand" or "Collapse", 0.9, 0.7, 0.1)
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
        sectionHeader:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 27, offsetY - 1)
        sectionHeader:SetText(lockoutType:gsub("^%l", string.upper))
        sectionHeader:SetTextColor(1, 1, 1, 1)
        sectionHeader:Show()
        table.insert(LMAHI.lockoutLabels, sectionHeader)
        LMAHI.cachedSectionHeaders[lockoutType] = sectionHeader

        headerCount = headerCount + 1
        offsetY = offsetY - 15
        if not isCollapsed then
            local lockouts = LMAHI.lockoutData[lockoutType] or {}

            if lockoutType == "custom" then
                local sortedLockouts = {}
                for _, lockout in ipairs(lockouts) do
                    table.insert(sortedLockouts, lockout)
                end
                table.sort(sortedLockouts, function(a, b)
                    local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                    local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1000
                    return aIndex < bIndex or (aIndex == bIndex and a.id < b.id)
                end)
                lockouts = sortedLockouts
            end

            if #lockouts == 0 then
                local noLockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                noLockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 15, offsetY)
                noLockoutLabel:SetText("No " .. lockoutType .. " found")
                noLockoutLabel:SetTextColor(1, 1, 1, 1)
                noLockoutLabel:Show()
                table.insert(LMAHI.lockoutLabels, noLockoutLabel)
                offsetY = offsetY - 14
            else
                offsetY = offsetY - 10
                for lockoutIndex, lockout in ipairs(lockouts) do
                    if lockout.name and lockout.id and lockout.id > 0 then
                        local lockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                        lockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 15, offsetY)
                        lockoutLabel:SetWidth(145)
                        lockoutLabel:SetText(lockout.name)
                        lockoutLabel:SetTextColor(0.9, 0.7, 0.1)
                        lockoutLabel:SetWordWrap(false)
                        lockoutLabel:SetMaxLines(1)
                        lockoutLabel:SetJustifyH("LEFT")
                        lockoutLabel:Show()

                        lockoutLabel:SetScript("OnEnter", function()
                            if not IsElementInView(lockoutLabel, LMAHI.lockoutScrollFrame) then return end
                            GameTooltip:SetOwner(lockoutLabel, "ANCHOR_TOPLEFT", -5, -24)
                            GameTooltip:SetText(lockout.name)
                            GameTooltip:Show()
                        end)

                        lockoutLabel:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)

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
                            local indicator = AcquireCheckButton(LMAHI.lockoutContent)
                            indicator:SetSize(16, 16)
                            indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT",
                                230 + (i-1) * 96 + (94 - 16) / -6, offsetY + 2)

                            local isLocked = LMAHI_SavedData.lockouts[charName]
                                and LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] or false

                            indicator:GetNormalTexture():SetVertexColor(isLocked and 0.8 or 0.2,
                                                                       isLocked and 0.2 or 0.8,
                                                                       0.2, 1)
                            indicator:GetCheckedTexture():SetVertexColor(isLocked and 0.8 or 0.2,
                                                                        isLocked and 0.2 or 0.8,
                                                                        0.2, 1)
                            indicator:SetChecked(isLocked)

                            indicator:SetScript("OnEnter", function()
                                if not IsElementInView(indicator, LMAHI.lockoutScrollFrame) then return end
                                GameTooltip:SetOwner(indicator, "ANCHOR_TOP")
                                GameTooltip:AddLine(isLocked and "Locked" or "Available",
                                                    isLocked and 1 or 0,
                                                    isLocked and 0 or 1,
                                                    0)
                                GameTooltip:Show()
                            end)
                            indicator:SetScript("OnLeave", function()
                                GameTooltip:Hide()
                            end)

                            indicator:SetScript("OnClick", function()
                                LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}
                                LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = not isLocked
                                LMAHI.UpdateDisplay()
                            end)

                            table.insert(LMAHI.lockoutLabels, indicator)
                        end

                        offsetY = offsetY - 18
                    end
                end
            end
        end
        offsetY = offsetY - 10
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
        else
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

LMAHI.eventFrame = LMAHI.eventFrame or CreateFrame("Frame")
LMAHI.eventFrame:RegisterEvent("PLAYER_LOGIN")
LMAHI.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LMAHI.eventFrame:SetScript("OnEvent", function(self, event)
    HandleLogin()
end)
