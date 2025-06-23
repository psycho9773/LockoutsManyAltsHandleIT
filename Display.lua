local addonName, addon = ...
local LMAHI = _G.LMAHI or {} -- Fallback to prevent nil errors

LMAHI.currentPage = LMAHI.currentPage or 1
LMAHI.maxCharsPerPage = 10
LMAHI.maxPages = 1
LMAHI.lockoutLabels = LMAHI.lockoutLabels or {}
LMAHI.collapseButtons = LMAHI.collapseButtons or {}
LMAHI.sectionHeaders = LMAHI.sectionHeaders or {}
LMAHI.hoverRegions = LMAHI.hoverRegions or {}

local charLabels = {}
local realmLabels = {}
local lockoutIndicators = {}

LMAHI.FACTION_COLORS = {
    Alliance = { r = 0.0, g = 0.4, b = 1.0 },
    Horde = { r = 1.0, g = 0.0, b = 0.0 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}

local CHAR_WIDTH = 95 -- Matches Core.lua (1208px / ~10 chars)
local CHAR_HEIGHT = 28
local LOCKOUT_HEIGHT = 19
local SECTION_HEADER_HEIGHT = 20
local SECTION_SPACING = 7

function LMAHI.CalculateContentHeight()
    local height = 20
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        height = height + SECTION_HEADER_HEIGHT
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            height = height + (#(LMAHI.lockoutData[lockoutType] or {}) * LOCKOUT_HEIGHT) + SECTION_SPACING
        else
            height = height + SECTION_SPACING
        end
    end
    return math.max(400, height)
end

function LMAHI.SetCollapseIconRotation(button, isCollapsed)
    if button.icon then
        button.icon:SetTexCoord(0, 1, 0, 1)
        button.icon:SetTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    end
end

function LMAHI.UpdateDisplay()
    if not LMAHI.mainFrame or not LMAHI.charFrame or not LMAHI.lockoutContent or not LMAHI.highlightFrame or not LMAHI.lockoutScrollFrame then
        return
    end

    -- Clear existing UI elements
    for _, label in ipairs(charLabels) do
        label:Hide()
    end
    for _, label in ipairs(realmLabels) do
        label:Hide()
    end
    for _, indicator in ipairs(lockoutIndicators) do
        indicator:Hide()
    end
    for _, label in ipairs(LMAHI.lockoutLabels) do
        label:Hide()
    end
    for _, button in ipairs(LMAHI.collapseButtons) do
        button:Hide()
    end
    for _, header in ipairs(LMAHI.sectionHeaders) do
        header:Hide()
    end
    for _, region in ipairs(LMAHI.hoverRegions) do
        region:Hide()
    end
    charLabels = {}
    realmLabels = {}
    lockoutIndicators = {}
    LMAHI.lockoutLabels = {}
    LMAHI.collapseButtons = {}
    LMAHI.sectionHeaders = {}
    LMAHI.hoverRegions = {}

    -- Get sorted character list
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        table.insert(charList, charName)
    end
    table.sort(charList, function(a, b)
        local aIndex = LMAHI_SavedData.charOrder[a] or 999
        local bIndex = LMAHI_SavedData.charOrder[b] or 1010
        if aIndex == bIndex then
            return a < b
        end
        return aIndex < bIndex
    end)

    -- Calculate pagination
    LMAHI.maxPages = math.ceil(#charList / LMAHI.maxCharsPerPage)
    LMAHI.currentPage = math.max(1, math.min(LMAHI.currentPage, LMAHI.maxPages))
    local startIndex = (LMAHI.currentPage - 1) * LMAHI.maxCharsPerPage + 1
    local endIndex = math.min(startIndex + LMAHI.maxCharsPerPage - 1, #charList)

    -- Display character labels
    for i = startIndex, endIndex do
        local charName = charList[i]
        local charIndex = i - startIndex + 1
        local xOffset = (charIndex - 1) * CHAR_WIDTH

        local charDisplayName, realmName = strsplit("-", charName)
        local charLabel = LMAHI.charFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        charLabel:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", xOffset + 10, -8)
        charLabel:SetText(charDisplayName or "Unknown")
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        charLabel:Show()
        table.insert(charLabels, charLabel)

        local realmLabel = LMAHI.charFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        realmLabel:SetPoint("TOPLEFT", charLabel, "BOTTOMLEFT", 0, -2)
        realmLabel:SetText(realmName or "Unknown")
        local faction = LMAHI_SavedData.factions[charName] or "Alliance"
        local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(realmLabels, realmLabel)
    end

    -- Set lockout content height
    local contentHeight = LMAHI.CalculateContentHeight()
    LMAHI.lockoutContent:SetHeight(contentHeight)

    -- Initialize highlight frame backdrop
    LMAHI.highlightFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0) -- Transparent when not active

    -- Display lockout sections
    local yOffset = -10
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType] or false

        -- Section header
        local sectionHeader = LMAHI.lockoutContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        sectionHeader:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 30, yOffset)
        sectionHeader:SetText(lockoutType:gsub("^%l", string.upper))
        sectionHeader:Show()
        table.insert(LMAHI.sectionHeaders, sectionHeader)

        -- Collapse button
        local collapseButton = CreateFrame("Button", nil, LMAHI.lockoutContent)
        collapseButton:SetSize(20, 20)
        collapseButton:SetPoint("LEFT", sectionHeader, "LEFT", -25, 0)
        collapseButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        collapseButton.icon = collapseButton:GetNormalTexture()
        collapseButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        collapseButton.lockoutType = lockoutType
        collapseButton:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() + 1)
        collapseButton:SetScript("OnClick", function(self)
            LMAHI_SavedData.collapsedSections[self.lockoutType] = not LMAHI_SavedData.collapsedSections[self.lockoutType]
            LMAHI.SetCollapseIconRotation(self, LMAHI_SavedData.collapsedSections[self.lockoutType])
            LMAHI.UpdateDisplay()
        end)
        collapseButton:Show()
        table.insert(LMAHI.collapseButtons, collapseButton)

        yOffset = yOffset - SECTION_HEADER_HEIGHT

        if not isCollapsed then
            -- Sort lockouts
            local lockoutList = {}
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                table.insert(lockoutList, lockout)
            end
            if lockoutType == "custom" then
                table.sort(lockoutList, function(a, b)
                    local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                    local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
                    if aIndex == bIndex then
                        return a.id < b.id
                    end
                    return aIndex < bIndex
                end)
            end

            -- Display lockouts
            for _, lockout in ipairs(lockoutList) do
                local lockoutId = tostring(lockout.id)
                local lockoutName = lockout.name

                -- Lockout label
                local lockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, yOffset)
                lockoutLabel:SetText(lockoutName)
                lockoutLabel:Show()
                table.insert(LMAHI.lockoutLabels, lockoutLabel)

                -- Hover region
                local hoverRegion = CreateFrame("Button", nil, LMAHI.lockoutContent)
                hoverRegion:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 0, yOffset)
                hoverRegion:SetSize(1155, LOCKOUT_HEIGHT + 4)
                hoverRegion:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() + 2)
                hoverRegion:EnableMouse(true)
                hoverRegion:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
                hoverRegion:GetHighlightTexture():SetBlendMode("ADD")
                hoverRegion:GetHighlightTexture():SetAlpha(0.005)
                hoverRegion:SetScript("OnEnter", function(self)
                    LMAHI.highlightFrame:ClearAllPoints()
                    LMAHI.highlightFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 8, 0)
                    LMAHI.highlightFrame:SetSize(1155, LOCKOUT_HEIGHT - 7)
                    LMAHI.highlightFrame:SetBackdropColor(0.8, 0.8, 0.8, 0.09) -- light gray highlight
                    LMAHI.highlightFrame:Show()
                end)
                hoverRegion:SetScript("OnLeave", function()
                    LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0)
                    LMAHI.highlightFrame:SetBackdropBorderColor(0, 0, 0, 0)
                    LMAHI.highlightFrame:Hide()
                end)
                hoverRegion:Show()
                table.insert(LMAHI.hoverRegions, hoverRegion)

                -- Lockout indicators
                for i = startIndex, endIndex do
                    local charName = charList[i]
                    local charIndex = i - startIndex + 1
                    local xOffset = 200 + (charIndex - 1) * CHAR_WIDTH

                    local isLocked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][lockoutId] or false
                    local indicator = CreateFrame("Button", nil, LMAHI.lockoutContent)
                    indicator:SetSize(16, 16)
                    indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", xOffset + 30, yOffset + 2)
                    indicator:SetNormalTexture("Interface\\Buttons\\UI-RadioButton")
                    indicator:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
                    if isLocked then
                        indicator:GetNormalTexture():SetVertexColor(1, 0, 0, 1) -- Red for killed or completed
                    else
                        indicator:GetNormalTexture():SetVertexColor(0, 1, 0, 1) -- Green for available
                    end
                    indicator:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    indicator.charName = charName
                    indicator.lockoutId = lockoutId
                    indicator:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() + 3)
                    indicator:SetScript("OnClick", function(self)
                        LMAHI_SavedData.lockouts[self.charName][self.lockoutId] = not LMAHI_SavedData.lockouts[self.charName][self.lockoutId]
                        LMAHI.UpdateDisplay()
                    end)
                    indicator:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(lockoutName)
                        GameTooltip:AddLine("Character: " .. (select(1, strsplit("-", charName)) or "Unknown"))
                        GameTooltip:AddLine("Status: " .. (LMAHI_SavedData.lockouts[charName][lockoutId] and "Killed or completed" or "Available"))
                        GameTooltip:Show()
                    end)
                    indicator:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                    indicator:Show()
                    table.insert(lockoutIndicators, indicator)
                end

                yOffset = yOffset - LOCKOUT_HEIGHT
            end
            yOffset = yOffset - SECTION_SPACING
        else
            yOffset = yOffset - SECTION_SPACING
        end
    end -- Close the lockoutType for loop
end -- Close the UpdateDisplay function