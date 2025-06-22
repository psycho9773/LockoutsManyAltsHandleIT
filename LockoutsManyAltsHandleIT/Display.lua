local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

-- Local references to frames from Core.lua
local mainFrame = LMAHI.mainFrame
local charFrame = LMAHI.charFrame
local lockoutScrollFrame = LMAHI.lockoutScrollFrame
local lockoutContent = LMAHI.lockoutContent
local highlightFrame = LMAHI.highlightFrame
local sectionHeaders = LMAHI.sectionHeaders
local lockoutLabels = LMAHI.lockoutLabels
local collapseButtons = LMAHI.collapseButtons

-- UI element tables
local charLabels = {}
local realmLabels = {}
local lockoutIndicators = {}
local highlightLine

-- Constants
local CHAR_WIDTH = 100 -- Reduced to fit 10 characters
local LOCKOUT_WIDTH = 35 -- Adjusted proportionally
local ROW_HEIGHT = 30
local CHARS_PER_PAGE = 10 -- Match previous layout

function LMAHI.UpdateDisplay()
    print("LMAHI Debug: Entering UpdateDisplay")
    if not mainFrame or not charFrame or not lockoutScrollFrame or not lockoutContent then
        print("LMAHI Debug: Required frames are nil")
        return
    end

    -- Clear existing elements
    for _, label in ipairs(charLabels) do
        label:Hide()
    end
    for _, label in ipairs(realmLabels) do
        label:Hide()
    end
    for _, indicator in ipairs(lockoutIndicators) do
        indicator:Hide()
    end
    for _, header in ipairs(sectionHeaders) do
        header:Hide()
    end
    for _, button in ipairs(collapseButtons) do
        button:Hide()
    end
    charLabels = {}
    realmLabels = {}
    lockoutIndicators = {}
    sectionHeaders = {}
    collapseButtons = {}

    -- Ensure frames are visible
    charFrame:Show()
    lockoutScrollFrame:Show()
    lockoutContent:Show()
    print("LMAHI Debug: Frames set to visible - charFrame:", charFrame:IsVisible(), "lockoutScrollFrame:", lockoutScrollFrame:IsVisible(), "lockoutContent:", lockoutContent:IsVisible())

    -- Get character list
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        table.insert(charList, charName)
    end

    -- Debug charOrder values
    print("LMAHI Debug: charOrder values:")
    for _, charName in ipairs(charList) do
        print("  ", charName, ":", LMAHI_SavedData.charOrder[charName] or "nil")
    end

    -- Sort characters safely
    table.sort(charList, function(a, b)
        local aIndex = tonumber(LMAHI_SavedData.charOrder[a]) or math.huge
        local bIndex = tonumber(LMAHI_SavedData.charOrder[b]) or math.huge
        if aIndex == bIndex then
            return a < b
        end
        return aIndex < bIndex
    end)

    -- Calculate pagination
    LMAHI.currentPage = LMAHI.currentPage or 1
    local startIndex = (LMAHI.currentPage - 1) * CHARS_PER_PAGE + 1
    local endIndex = math.min(startIndex + CHARS_PER_PAGE - 1, #charList)
    LMAHI.maxPages = math.ceil(#charList / CHARS_PER_PAGE)
    print("LMAHI Debug: Pagination - currentPage:", LMAHI.currentPage, "startIndex:", startIndex, "endIndex:", endIndex, "maxPages:", LMAHI.maxPages)

    -- Display characters horizontally
    local charOffsetX = 10
    for i = startIndex, endIndex do
        local charName = charList[i]
        local charDisplayName, realmName = strsplit("-", charName)

        -- Character label
        local charLabel = charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        charLabel:SetPoint("TOPLEFT", charFrame, "TOPLEFT", charOffsetX + ((i - startIndex) * CHAR_WIDTH), -10)
        charLabel:SetText(charDisplayName or "Unknown")
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        charLabel:Show()
        table.insert(charLabels, charLabel)

        -- Realm label (below character name)
        local realmLabel = charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        realmLabel:SetPoint("TOPLEFT", charLabel, "BOTTOMLEFT", 0, -5)
        realmLabel:SetText(realmName or "Unknown")
        local faction = LMAHI_SavedData.factions[charName] or "Alliance"
        local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(realmLabels, realmLabel)

        print("LMAHI Debug: Added charLabel:", charDisplayName, "realmLabel:", realmName, "at x:", charOffsetX + ((i - startIndex) * CHAR_WIDTH))
    end

    -- Display lockouts
    local offsetY = -10
    local totalHeight = 10
    local lockoutOffsetX = 10

    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType] or false

        -- Section header
        local header = lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        header:SetPoint("TOPLEFT", lockoutContent, "TOPLEFT", lockoutOffsetX, offsetY)
        header:SetText(lockoutType:gsub("^%l", string.upper))
        header:SetTextColor(1, 0.8, 0)
        header:Show()
        table.insert(sectionHeaders, header)

        -- Collapse button
        local collapseButton = CreateFrame("Button", nil, lockoutContent)
        collapseButton:SetSize(16, 16)
        collapseButton:SetPoint("LEFT", header, "RIGHT", 5, 0)
        collapseButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        collapseButton:SetPushedTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Down" or "Interface\\Buttons\\UI-MinusButton-Down")
        collapseButton:SetScript("OnClick", function()
            LMAHI_SavedData.collapsedSections[lockoutType] = not isCollapsed
            LMAHI.UpdateDisplay()
        end)
        collapseButton:Show()
        table.insert(collapseButtons, collapseButton)

        offsetY = offsetY - ROW_HEIGHT
        totalHeight = totalHeight + ROW_HEIGHT

        if not isCollapsed then
            local lockouts = LMAHI.lockoutData[lockoutType] or {}
            local sortedLockouts = {}
            for _, lockout in ipairs(lockouts) do
                table.insert(sortedLockouts, lockout)
            end
            table.sort(sortedLockouts, function(a, b)
                local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
                if aIndex == bIndex then
                    return a.id < b.id
                end
                return aIndex < bIndex
            end)

            for _, lockout in ipairs(sortedLockouts) do
                -- Lockout label
                local lockoutLabel = lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                lockoutLabel:SetPoint("TOPLEFT", lockoutContent, "TOPLEFT", lockoutOffsetX + 20, offsetY)
                lockoutLabel:SetText(lockout.name or "Unknown")
                lockoutLabel:SetTextColor(1, 1, 1)
                lockoutLabel:Show()
                table.insert(lockoutLabels, lockoutLabel)

                -- Lockout indicators
                for i = startIndex, endIndex do
                    local charName = charList[i]
                    local indicator = lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    indicator:SetPoint("TOPLEFT", lockoutContent, "TOPLEFT", lockoutOffsetX + CHAR_WIDTH + ((i - startIndex) * LOCKOUT_WIDTH), offsetY)
                    local isLocked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][tostring(lockout.id)]
                    indicator:SetText(isLocked and "x" or "o")
                    indicator:SetTextColor(isLocked and 1 or 0, isLocked and 0 or 1, 0)
                    indicator:Show()
                    table.insert(lockoutIndicators, indicator)
                end

                offsetY = offsetY - ROW_HEIGHT
                totalHeight = totalHeight + ROW_HEIGHT
            end
        end
    end

    -- Update scroll content height
    lockoutContent:SetHeight(totalHeight)
    lockoutScrollFrame:SetScrollChild(lockoutContent)

    -- Highlight line
    if not highlightLine then
        highlightLine = CreateFrame("Frame", nil, highlightFrame, "BackdropTemplate")
        highlightLine:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 0,
        })
        highlightLine:SetBackdropColor(1, 1, 0, 0.3)
        highlightLine:SetHeight(ROW_HEIGHT)
        highlightLine:SetFrameLevel(highlightFrame:GetFrameLevel() + 7)
        highlightLine:Hide()
    end

    -- Add mouseover highlight
    for _, lockoutLabel in ipairs(lockoutLabels) do
        local button = CreateFrame("Button", nil, lockoutContent)
        button:SetPoint("TOPLEFT", lockoutLabel, "TOPLEFT", -10, 0)
        button:SetSize(lockoutContent:GetWidth(), ROW_HEIGHT)
        button:SetScript("OnEnter", function()
            highlightLine:SetPoint("TOPLEFT", lockoutContent, "TOPLEFT", 0, lockoutLabel:GetTop() - lockoutContent:GetTop())
            highlightLine:SetPoint("TOPRIGHT", lockoutContent, "TOPRIGHT", 0, lockoutLabel:GetTop() - lockoutContent:GetTop())
            highlightLine:Show()
        end)
        button:SetScript("OnLeave", function()
            highlightLine:Hide()
        end)
        button:SetFrameLevel(lockoutContent:GetFrameLevel() + 1)
    end

    print("LMAHI Debug: Exiting UpdateDisplay, chars:", #charLabels, "lockouts:", #lockoutLabels, "indicators:", #lockoutIndicators)
end

-- Expose UpdateDisplay globally
_G["LMAHI_UpdateDisplay"] = LMAHI.UpdateDisplay
