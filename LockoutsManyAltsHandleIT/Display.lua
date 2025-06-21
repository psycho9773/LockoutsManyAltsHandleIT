-- Display.lua
local addonName, addon = ...
local LMAHI = _G.LMAHI

-- Update character list display
function LMAHI.UpdateCharDisplay()
    for _, child in ipairs({ LMAHI.charListContent:GetChildren() }) do
        child:Hide()
    end
    for _, fontString in ipairs({ LMAHI.charListContent:GetRegions() }) do
        if fontString:IsObjectType("FontString") then
            fontString:Hide()
        end
    end

    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters) do
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

    local yOffset = 0
    for i, charName in ipairs(charList) do
        if i > (LMAHI.currentPage - 1) * LMAHI.maxCharsPerPage and i <= LMAHI.currentPage * LMAHI.maxCharsPerPage then
            local charText = LMAHI.charListContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            charText:SetPoint("TOPLEFT", LMAHI.charListContent, "TOPLEFT", 10, yOffset)
            local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
            charText:SetTextColor(classColor.r, classColor.g, classColor.b)
            charText:SetText(charName)
            charText:Show()

            local upButton = CreateFrame("Button", nil, LMAHI.charListContent)
            upButton:SetSize(20, 20)
            upButton:SetPoint("TOPLEFT", LMAHI.charListContent, "TOPLEFT", 300, yOffset)
            upButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Quest-Up")
            upButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Quest-Down")
            upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            upButton:SetScript("OnClick", function()
                local currentIndex = LMAHI_SavedData.charOrder[charName]
                if currentIndex > 1 then
                    for otherChar, index in pairs(LMAHI_SavedData.charOrder) do
                        if index == currentIndex - 1 then
                            LMAHI_SavedData.charOrder[otherChar] = currentIndex
                            LMAHI_SavedData.charOrder[charName] = currentIndex - 1
                            break
                        end
                    end
                    LMAHI.NormalizeCharOrder()
                    LMAHI.UpdateCharDisplay()
                    LMAHI.UpdateDisplay()
                end
            end)
            upButton:Show()

            local downButton = CreateFrame("Button", nil, LMAHI.charListContent)
            downButton:SetSize(20, 20)
            downButton:SetPoint("TOPLEFT", upButton, "TOPRIGHT", 5, 0)
            downButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Spellbook-Down")
            downButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Spellbook-Down")
            downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            downButton:SetScript("OnClick", function()
                local currentIndex = LMAHI_SavedData.charOrder[charName]
                local maxIndex = 0
                for _, index in pairs(LMAHI_SavedData.charOrder) do
                    if index > maxIndex then
                        maxIndex = index
                    end
                end
                if currentIndex < maxIndex then
                    for otherChar, index in pairs(LMAHI_SavedData.charOrder) do
                        if index == currentIndex + 1 then
                            LMAHI_SavedData.charOrder[otherChar] = currentIndex
                            LMAHI_SavedData.charOrder[charName] = currentIndex + 1
                            break
                        end
                    end
                    LMAHI.NormalizeCharOrder()
                    LMAHI.UpdateCharDisplay()
                    LMAHI.UpdateDisplay()
                end
            end)
            downButton:Show()

            local deleteButton = CreateFrame("Button", nil, LMAHI.charListContent)
            deleteButton:SetSize(20, 20)
            deleteButton:SetPoint("TOPLEFT", downButton, "TOPRIGHT", 5, 0)
            deleteButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            deleteButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
            deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            deleteButton:SetScript("OnClick", function()
                LMAHI_SavedData.characters[charName] = nil
                LMAHI_SavedData.lockouts[charName] = nil
                LMAHI_SavedData.classColors[charName] = nil
                LMAHI_SavedData.factions[charName] = nil
                LMAHI_SavedData.charOrder[charName] = nil
                LMAHI.NormalizeCharOrder()
                LMAHI.UpdateCharDisplay()
                LMAHI.UpdateDisplay()
            end)
            deleteButton:Show()

            yOffset = yOffset - 25
        end
    end
    LMAHI.charListContent:SetHeight(-yOffset)
end

-- Update custom input display
function LMAHI.UpdateCustomInputDisplay()
    for _, child in ipairs({ LMAHI.customInputScrollContent:GetChildren() }) do
        child:Hide()
    end
    for _, fontString in ipairs({ LMAHI.customInputScrollContent:GetRegions() }) do
        if fontString:IsObjectType("FontString") then
            fontString:Hide()
        end
    end

    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
        table.insert(customList, lockout)
    end
    table.sort(customList, function(a, b)
        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
        if aIndex == bIndex then
            return a.id < b.id
        end
        return aIndex < bIndex
    end)

    local yOffset = 0
    for _, lockout in ipairs(customList) do
        local lockoutText = LMAHI.customInputScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lockoutText:SetPoint("TOPLEFT", LMAHI.customInputScrollContent, "TOPLEFT", 10, yOffset)
        lockoutText:SetText(string.format("%s (%d, %s)", lockout.name, lockout.id, lockout.reset))
        lockoutText:Show()

        local upButton = CreateFrame("Button", nil, LMAHI.customInputScrollContent)
        upButton:SetSize(20, 20)
        upButton:SetPoint("TOPLEFT", LMAHI.customInputScrollContent, "TOPLEFT", 300, yOffset)
        upButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Quest-Up")
        upButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Quest-Down")
        upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        upButton:SetScript("OnClick", function()
            local currentIndex = LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)]
            if currentIndex > 1 then
                for otherId, index in pairs(LMAHI_SavedData.customLockoutOrder) do
                    if index == currentIndex - 1 then
                        LMAHI_SavedData.customLockoutOrder[otherId] = currentIndex
                        LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)] = currentIndex - 1
                        break
                    end
                end
                LMAHI.NormalizeCustomLockoutOrder()
                LMAHI.UpdateCustomInputDisplay()
                LMAHI.UpdateDisplay()
            end
        end)
        upButton:Show()

        local downButton = CreateFrame("Button", nil, LMAHI.customInputScrollContent)
        downButton:SetSize(20, 20)
        downButton:SetPoint("TOPLEFT", upButton, "TOPRIGHT", 5, 0)
        downButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Spellbook-Down")
        downButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Spellbook-Down")
        downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        downButton:SetScript("OnClick", function()
            local currentIndex = LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)]
            local maxIndex = 0
            for _, index in pairs(LMAHI_SavedData.customLockoutOrder) do
                if index > maxIndex then
                    maxIndex = index
                end
            end
            if currentIndex < maxIndex then
                for otherId, index in pairs(LMAHI_SavedData.customLockoutOrder) do
                    if index == currentIndex + 1 then
                        LMAHI_SavedData.customLockoutOrder[otherId] = currentIndex
                        LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)] = currentIndex + 1
                        break
                    end
                end
                LMAHI.NormalizeCustomLockoutOrder()
                LMAHI.UpdateCustomInputDisplay()
                LMAHI.UpdateDisplay()
            end
        end)
        downButton:Show()

        local deleteButton = CreateFrame("Button", nil, LMAHI.customInputScrollContent)
        deleteButton:SetSize(20, 20)
        deleteButton:SetPoint("TOPLEFT", downButton, "TOPRIGHT", 5, 0)
        deleteButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        deleteButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
        deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        deleteButton:SetScript("OnClick", function()
            for i, l in ipairs(LMAHI.lockoutData.custom) do
                if l.id == lockout.id then
                    table.remove(LMAHI.lockoutData.custom, i)
                    break
                end
            end
            LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
            LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)] = nil
            for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
                lockouts[tostring(lockout.id)] = nil
            end
            LMAHI.NormalizeCustomLockoutOrder()
            LMAHI.UpdateCustomInputDisplay()
            LMAHI.UpdateDisplay()
        end)
        deleteButton:Show()

        yOffset = yOffset - 25
    end
    LMAHI.customInputScrollContent:SetHeight(-yOffset)
end

-- Update lockout display
function LMAHI.UpdateLockoutDisplay()
    for _, child in ipairs({ LMAHI.lockoutContent:GetChildren() }) do
        child:Hide()
    end
    for _, fontString in ipairs({ LMAHI.lockoutContent:GetRegions() }) do
        if fontString:IsObjectType("FontString") then
            fontString:Hide()
        end
    end

    local yOffset = -10
    local categoryHeights = {}

    -- First pass: Calculate height for each category
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        local height = 30 -- Header height
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            local lockouts = {}
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType]) do
                table.insert(lockouts, lockout)
            end
            if lockoutType == "custom" then
                table.sort(lockouts, function(a, b)
                    local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                    local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
                    if aIndex == bIndex then
                        return a.id < b.id
                    end
                    return aIndex < bIndex
                end)
            end
            height = height + (#lockouts * 20) + 10 -- Lockouts (20 each) + spacing
        end
        categoryHeights[lockoutType] = height
    end

    -- Second pass: Render with correct offsets
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        local sectionHeader = LMAHI.lockoutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        sectionHeader:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 30, yOffset)
        sectionHeader:SetText(lockoutType:gsub("^%l", string.upper))
        sectionHeader:Show()

        local collapseButton = CreateFrame("Button", nil, LMAHI.lockoutContent)
        collapseButton:SetSize(20, 20)
        collapseButton:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, yOffset)
        collapseButton:SetNormalTexture(LMAHI_SavedData.collapsedSections[lockoutType] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        collapseButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        collapseButton:SetScript("OnClick", function()
            LMAHI_SavedData.collapsedSections[lockoutType] = not LMAHI_SavedData.collapsedSections[lockoutType]
            collapseButton:SetNormalTexture(LMAHI_SavedData.collapsedSections[lockoutType] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            LMAHI.UpdateLockoutDisplay()
        end)
        collapseButton:Show()

        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            local lockouts = {}
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType]) do
                table.insert(lockouts, lockout)
            end
            if lockoutType == "custom" then
                table.sort(lockouts, function(a, b)
                    local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                    local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
                    if aIndex == bIndex then
                        return a.id < b.id
                    end
                    return aIndex < bIndex
                end)
            end

            local lockoutOffset = yOffset - 30
            for _, lockout in ipairs(lockouts) do
                local lockoutNameText = LMAHI.lockoutContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                lockoutNameText:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 30, lockoutOffset)
                lockoutNameText:SetText(lockout.name)
                lockoutNameText:Show()

                local charList = {}
                for charName, _ in pairs(LMAHI_SavedData.characters) do
                    table.insert(charList, charName)
                end
                table.sort(charList, function(a, b)
                    local aIndex = LMAHI_SavedData.charOrder[a] or 999
                    bIndex = LMAHI_SavedData.charOrder[b] or 1010
                    if aIndex == bIndex then
                        return a < b
                    end
                    return aIndex < bIndex
                end)

                local startIndex = (LMAHI.currentPage - 1) * LMAHI.maxCharsPerPage + 1
                local endIndex = LMAHI.currentPage * LMAHI.maxCharsPerPage
                for i, charName in ipairs(charList) do
                    if i >= startIndex and i <= endIndex then
                        local lockoutText = LMAHI.lockoutContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        lockoutText:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 30 + (i - startIndex) * 100, lockoutOffset)
                        local locked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] or false
                        lockoutText:SetText(locked and "X" or "-")
                        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
                        lockoutText:SetTextColor(classColor.r, classColor.g, classColor.b)
                        lockoutText:Show()

                        lockoutText:SetScript("OnEnter", function(self)
                            LMAHI.highlightLine:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 0, lockoutOffset)
                            LMAHI.highlightLine:SetWidth(LMAHI.lockoutContent:GetWidth())
                            LMAHI.highlightLine:Show()
                            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                            GameTooltip:SetText(string.format("%s\n%s", lockout.name, charName))
                            GameTooltip:Show()
                        end)
                        lockoutText:SetScript("OnLeave", function()
                            LMAHI.highlightLine:Hide()
                            GameTooltip:Hide()
                        end)
                    end
                end
                lockoutOffset = lockoutOffset - 20
            end
        end

        yOffset = yOffset - categoryHeights[lockoutType]
    end

    LMAHI.lockoutContent:SetHeight(LMAHI.CalculateContentHeight())
    LMAHI.lockoutScrollFrame:SetVerticalScroll(0)
end

-- Update main display
function LMAHI.UpdateDisplay()
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters) do
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

    for _, child in ipairs({ LMAHI.charFrame:GetChildren() }) do
        child:Hide()
    end
    for _, fontString in ipairs({ LMAHI.charFrame:GetRegions() }) do
        if fontString:IsObjectType("FontString") then
            fontString:Hide()
        end
    end

    local yOffset = -40
    local startIndex = (LMAHI.currentPage - 1) * LMAHI.maxCharsPerPage + 1
    local endIndex = LMAHI.currentPage * LMAHI.maxCharsPerPage
    for i, charName in ipairs(charList) do
        if i >= startIndex and i <= endIndex then
            local charText = LMAHI.charFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            charText:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", 30, yOffset)
            local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
            charText:SetTextColor(classColor.r, classColor.g, classColor.b)
            charText:SetText(charName)
            charText:Show()
            yOffset = yOffset - 20
        end
    end

    LMAHI.UpdateLockoutDisplay()
end

-- Update settings display
function LMAHI.UpdateSettingsDisplay()
    LMAHI.UpdateCharDisplay()
end

LMAHI.mainFrame:SetScript("OnShow", function()
    LMAHI.UpdateDisplay()
end)
