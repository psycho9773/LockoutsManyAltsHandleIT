-- Display.lua

local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

LMAHI.currentPage = LMAHI.currentPage or 1
LMAHI.maxCharsPerPage = 10
LMAHI.maxPages = 1
LMAHI.lockoutLabels = LMAHI.lockoutLabels or {}
LMAHI.collapseButtons = LMAHI.collapseButtons or {}
LMAHI.hoverRegions = LMAHI.hoverRegions or {}

-- Object pools for reusing UI elements
local fontStringPool = {}
local buttonPool = {} -- Used for collapse buttons only
local checkButtonPool = {}

-- Pool management functions
local function AcquireFontString(parent)
    local fs = next(fontStringPool)
    if fs then
        fontStringPool[fs] = nil
        fs:SetParent(parent)
        fs:Show()
        -- print("Acquired FontString: " .. tostring(fs) .. " for parent: " .. tostring(parent)) -- Debug: Uncomment to log
        return fs
    end
    fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- print("Created new FontString: " .. tostring(fs) .. " for parent: " .. tostring(parent)) -- Debug: Uncomment to log
    return fs
end

local function ReleaseFontString(fs)
    fs:Hide()
    fs:ClearAllPoints()
    fs:SetText("")
    -- Do not reset color to allow explicit setting on acquire
    fs:SetFontObject("GameFontNormal")
    fontStringPool[fs] = true
    -- print("Released FontString: " .. tostring(fs)) -- Debug: Uncomment to log
end

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
        -- print("Acquired button: " .. tostring(btn) .. " for collapse button") -- Debug: Uncomment to log
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
    -- print("Released button: " .. tostring(btn) .. " to buttonPool") -- Debug: Uncomment to log
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

function LMAHI.UpdateDisplay()
    if not LMAHI.mainFrame or not LMAHI.lockoutScrollFrame or not LMAHI.lockoutContent or not LMAHI.charFrame or not LMAHI.highlightFrame then
        return
    end

    -- Reset highlight frame at the start of update
    LMAHI.highlightFrame:Hide()
    LMAHI.highlightFrame:ClearAllPoints()
    LMAHI.highlightFrame:SetSize(0, 0)
    LMAHI.highlightFrame:SetBackdrop(nil) -- Clear backdrop for Frame
    LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0)
    LMAHI.highlightFrame:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() + 1) -- Ensure highlight frame is above content

    -- Release all currently used elements back to pools
    for _, label in ipairs(LMAHI.lockoutLabels) do
        if label:IsObjectType("FontString") then
            ReleaseFontString(label)
        elseif label:IsObjectType("CheckButton") then
            ReleaseCheckButton(label)
        end
    end
    for _, button in ipairs(LMAHI.collapseButtons) do
        ReleaseButton(button)
    end
    for _, region in ipairs(LMAHI.hoverRegions) do
        region:Hide()
        region:ClearAllPoints()
        region:SetSize(0, 0)
        region:SetFrameLevel(0)
        region:SetNormalTexture("")
        region:SetHighlightTexture("")
        region:EnableMouse(false)
        region:SetScript("OnEnter", nil)
        region:SetScript("OnLeave", nil)
        -- print("Released hover region: " .. tostring(region)) -- Debug: Uncomment to log
    end
    LMAHI.lockoutLabels = {}
    LMAHI.collapseButtons = {}
    LMAHI.hoverRegions = {}

    -- Get sorted character list
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        table.insert(charList, charName)
    end
    if #charList == 0 then
        local emptyLabel = AcquireFontString(LMAHI.lockoutContent)
        emptyLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, -10)
        emptyLabel:SetText("No characters found. Log in to each alt to register.")
        emptyLabel:SetTextColor(1, 1, 1, 1) -- White for empty message
        table.insert(LMAHI.lockoutLabels, emptyLabel)
        return
    end

    table.sort(charList, function(a, b)
        local aIndex = LMAHI_SavedData.charOrder[a] or 999
        local bIndex = LMAHI_SavedData.charOrder[b] or 1000
        return aIndex < bIndex or (aIndex == bIndex and a < b)
    end)

    -- Pagination
    local charsPerPage = 10
    LMAHI.currentPage = math.max(1, math.min(LMAHI.currentPage, math.ceil(#charList / charsPerPage)))
    local startIndex = (LMAHI.currentPage - 1) * charsPerPage + 1
    local endIndex = math.min(startIndex + charsPerPage - 1, #charList)
    LMAHI.maxPages = math.ceil(#charList / charsPerPage)

    local displayChars = {}
    for i = startIndex, endIndex do
        table.insert(displayChars, charList[i])
    end

    -- Character and realm labels
    local charWidth = 94
    local charLabels = {}
    for i, charName in ipairs(displayChars) do
        local playerName = charName:match("^(.-)-") or charName
        local realmName = charName:match("-(.+)$") or "Unknown"

        -- Character name label (class-colored)
        local charLabel = AcquireFontString(LMAHI.charFrame)
        charLabel:SetFontObject("GameFontNormal")
        charLabel:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", 12 + (i-1) * charWidth, -8)
        charLabel:SetText(playerName)
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        table.insert(LMAHI.lockoutLabels, charLabel)
        charLabels[i] = charLabel

        -- Realm name label (faction-colored)
        local realmLabel = AcquireFontString(LMAHI.charFrame)
        realmLabel:SetFontObject("GameFontNormalSmall")
        realmLabel:SetPoint("TOPLEFT", charLabel, "BOTTOMLEFT", 0, -2)
        realmLabel:SetText(realmName)
        local factionColor = LMAHI_SavedData.factionColors[charName] or { r = 1, g = 1, b = 1 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        table.insert(LMAHI.lockoutLabels, realmLabel)
    end

    -- Initialize highlight frame backdrop
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
    if not LMAHI.lockoutTypes or #LMAHI.lockoutTypes == 0 then
        local noTypesLabel = AcquireFontString(LMAHI.lockoutContent)
        noTypesLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, offsetY)
        noTypesLabel:SetText("No lockout types defined.")
        noTypesLabel:SetTextColor(1, 1, 1, 1) -- White for no types message
        table.insert(LMAHI.lockoutLabels, noTypesLabel)
        offsetY = offsetY - 20
    else
        for lockoutTypeIndex, lockoutType in ipairs(LMAHI.lockoutTypes) do
            local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType]
            local collapseButton = AcquireButton(LMAHI.lockoutContent)
            collapseButton:SetSize(20, 20)
            collapseButton:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 5, offsetY)
            collapseButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            collapseButton:Show()

            -- Collapse buttons and headers
            collapseButton:SetScript("OnEnter", function(self)
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

            local sectionHeader = AcquireFontString(LMAHI.lockoutContent)
            sectionHeader:SetFontObject("GameFontHighlightLarge")
            sectionHeader:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 27, offsetY - 1)
            sectionHeader:SetText(lockoutType:gsub("^%l", string.upper))
            sectionHeader:SetTextColor(1, 1, 1, 1) -- White for section headers
            table.insert(LMAHI.lockoutLabels, sectionHeader)

            offsetY = offsetY - 15

            -- Lockout id and indicator section to display
            if not isCollapsed then
                local lockouts = LMAHI.lockoutData[lockoutType] or {}
                if lockoutType == "custom" then
                    -- Sort custom lockouts based on customLockoutOrder
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
                    local noLockoutLabel = AcquireFontString(LMAHI.lockoutContent)
                    noLockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 15, offsetY)
                    noLockoutLabel:SetText("No " .. lockoutType .. " found")
                    noLockoutLabel:SetTextColor(1, 1, 1, 1) -- White for no lockouts message
                    table.insert(LMAHI.lockoutLabels, noLockoutLabel)
                    offsetY = offsetY - 14
                else
                    offsetY = offsetY - 10
                    for lockoutIndex, lockout in ipairs(lockouts) do
                        if lockout.name and lockout.id and lockout.id > 0 then
                            local lockoutLabel = AcquireFontString(LMAHI.lockoutContent)
                            lockoutLabel:SetFontObject("GameFontNormal")
                            lockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 15, offsetY)
                            lockoutLabel:SetText(lockout.name)
                            lockoutLabel:SetTextColor(0.9, 0.7, 0.1) -- Gold for all lockout ID names
                            -- print("Set lockout label color to gold for " .. lockoutType .. ": " .. lockout.name) -- Debug: Uncomment to log
                            table.insert(LMAHI.lockoutLabels, lockoutLabel)

                            -- Hover region for highlight (create fresh button, no pooling)
                            local hoverRegion = CreateFrame("Button", nil, LMAHI.lockoutContent)
                            hoverRegion:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 0, offsetY)
                            hoverRegion:SetSize(1155, 10) -- Match highlightFrame height
                            hoverRegion:SetFrameLevel(LMAHI.lockoutContent:GetFrameLevel() - 1)
                            hoverRegion:EnableMouse(true)
                            hoverRegion:Show()
                            hoverRegion:SetScript("OnEnter", function(self)
                                LMAHI.highlightFrame:ClearAllPoints()
                                LMAHI.highlightFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 8, 0)
                                LMAHI.highlightFrame:SetSize(1155, 10) -- Desired height
                                LMAHI.highlightFrame:SetBackdropColor(0.4, 0.4, 0.4, 0.2) -- Desired color
                                LMAHI.highlightFrame:Show()
                            end)
                            hoverRegion:SetScript("OnLeave", function()
                                LMAHI.highlightFrame:Hide()
                                LMAHI.highlightFrame:SetBackdropColor(0, 0, 0, 0)
                            end)
                            table.insert(LMAHI.hoverRegions, hoverRegion)
                            -- print("Created hover region: " .. tostring(hoverRegion) .. " for lockout " .. lockout.name) -- Debug: Uncomment to log

                            for i, charName in ipairs(displayChars) do
                                local indicator = AcquireCheckButton(LMAHI.lockoutContent)
                                indicator:SetSize(16, 16)
                                indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 230 + (i-1) * charWidth + (charWidth - 16) / -10, offsetY + 2)
                                local isLocked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] or false
                                indicator:GetNormalTexture():SetVertexColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2, 1)
                                indicator:GetCheckedTexture():SetVertexColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2, 1)
                                indicator:SetChecked(isLocked)
                                indicator:SetScript("OnEnter", function()
                                    GameTooltip:SetOwner(indicator, "ANCHOR_TOP")
                                    GameTooltip:AddLine(isLocked and "Locked" or "Available", isLocked and 1 or 0, isLocked and 0 or 1, 0)
                                    GameTooltip:Show()
                                end)
                                indicator:SetScript("OnLeave", function()
                                    GameTooltip:Hide()
                                end)
                                indicator:SetScript("OnClick", function()
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
end
