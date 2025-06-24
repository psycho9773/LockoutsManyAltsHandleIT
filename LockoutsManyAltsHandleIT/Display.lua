-- Display.lua
local addonName, addon = ...
if not _G.LMAHI then
    _G.LMAHI = addon
end

function LMAHI.UpdateDisplay()
    if not LMAHI.mainFrame or not LMAHI.lockoutScrollFrame or not LMAHI.lockoutContent or not LMAHI.charFrame then
        return
    end

    -- Clear existing UI elements
    for _, label in ipairs(LMAHI.lockoutLabels or {}) do
        label:Hide()
    end
    for _, button in ipairs(LMAHI.collapseButtons or {}) do
        button:Hide()
    end
    LMAHI.lockoutLabels = {}
    LMAHI.collapseButtons = {}

    -- Get sorted character list
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters or {}) do
        table.insert(charList, charName)
    end
    if #charList == 0 then
        local emptyLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, -10)
        emptyLabel:SetText("No characters found. Log in to each alt to register.")
        emptyLabel:Show()
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
    LMAHI.currentPage = LMAHI.currentPage or 1
    local startIndex = (LMAHI.currentPage - 1) * charsPerPage + 1
    local endIndex = math.min(startIndex + charsPerPage - 1, #charList)
    LMAHI.maxPages = math.ceil(#charList / charsPerPage)

    local displayChars = {}
    for i = startIndex, endIndex do
        table.insert(displayChars, charList[i])
    end

    -- Character and realm labels
    local charWidth = 96.9
    local charLabels = {}
    for i, charName in ipairs(displayChars) do
        local playerName = charName:match("^(.-)-") or charName
        local realmName = charName:match("-(.+)$") or "Unknown"

        -- Character name label (class-colored)
        local charLabel = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        charLabel:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", 10 + (i-1) * charWidth, -10)
        charLabel:SetText(playerName)
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        charLabel:Show()
        table.insert(LMAHI.lockoutLabels, charLabel)
        charLabels[i] = charLabel

        -- Realm name label (faction-colored)
        local realmLabel = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        realmLabel:SetPoint("TOPLEFT", charLabel, "BOTTOMLEFT", 0, -2)
        realmLabel:SetText(realmName)
        local factionColor = LMAHI_SavedData.factionColors[charName] or { r = 1, g = 1, b = 1 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(LMAHI.lockoutLabels, realmLabel)
    end

    -- Lockout sections
    local offsetY = -30
    if not LMAHI.lockoutTypes or #LMAHI.lockoutTypes == 0 then
        local noTypesLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        noTypesLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, offsetY)
        noTypesLabel:SetText("No lockout types defined.")
        noTypesLabel:Show()
        table.insert(LMAHI.lockoutLabels, noTypesLabel)
        offsetY = offsetY - 20
    else
        for lockoutTypeIndex, lockoutType in ipairs(LMAHI.lockoutTypes) do
            local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType]
            local collapseButton = CreateFrame("Button", nil, LMAHI.lockoutContent)
            collapseButton:SetSize(16, 16)
            collapseButton:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 5, offsetY)
            collapseButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            collapseButton:SetScript("OnClick", function()
                LMAHI_SavedData.collapsedSections[lockoutType] = not isCollapsed
                LMAHI.UpdateDisplay()
            end)
            collapseButton:Show()
            table.insert(LMAHI.collapseButtons, collapseButton)

            local sectionHeader = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            sectionHeader:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 25, offsetY)
            sectionHeader:SetText(lockoutType:gsub("^%l", string.upper))
            sectionHeader:Show()
            table.insert(LMAHI.lockoutLabels, sectionHeader)

            offsetY = offsetY - 25
            if not isCollapsed then
                local lockouts = LMAHI.lockoutData[lockoutType] or {}
                if #lockouts == 0 then
                    local noLockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    noLockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 35, offsetY)
                    noLockoutLabel:SetText("No " .. lockoutType .. " found")
                    noLockoutLabel:Show()
                    table.insert(LMAHI.lockoutLabels, noLockoutLabel)
                    offsetY = offsetY - 20
                else
                    for lockoutIndex, lockout in ipairs(lockouts) do
                        if not lockout.name or not lockout.id or lockout.id <= 0 then
                        else
                            local lockoutLabel = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                            lockoutLabel:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 35, offsetY)
                            lockoutLabel:SetText(lockout.name)
                            if lockoutType == "custom" then
                                lockoutLabel:SetTextColor(0.9, 0.7, 0.1)
                            end
                            lockoutLabel:Show()
                            table.insert(LMAHI.lockoutLabels, lockoutLabel)

                            -- Tooltip for lockout label REMOVED for this version interfered with previous page button


                            for i, charName in ipairs(displayChars) do
                                local indicator = CreateFrame("CheckButton", nil, LMAHI.lockoutContent)
                                indicator:SetSize(16, 16)
                                indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 204 + (i-1) * charWidth + (charWidth - 16) / 2, offsetY)
                                local isLocked = LMAHI_SavedData.lockouts[charName] and LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] or false
                                indicator:SetNormalTexture("Interface\\Buttons\\UI-RadioButton")
                                indicator:SetCheckedTexture("Interface\\Buttons\\UI-RadioButton")
                                indicator:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
                                indicator:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
                                indicator:GetNormalTexture():SetVertexColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2, 1)
                                indicator:GetCheckedTexture():SetVertexColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2, 1)
                                indicator:SetChecked(isLocked)
                                indicator:Show()
                                table.insert(LMAHI.lockoutLabels, indicator)

                                -- Tooltip and highlight for indicator
                                indicator:SetScript("OnEnter", function()
                                    GameTooltip:SetOwner(indicator, "ANCHOR_RIGHT")
                                    GameTooltip:SetText(charName .. " - " .. lockout.name)
                                    GameTooltip:AddLine(isLocked and "Locked" or "Available", isLocked and 1 or 0, isLocked and 0 or 1, 0)
                                    GameTooltip:Show()
                                    LMAHI.highlightFrame:SetPoint("TOPLEFT", indicator, "TOPLEFT", -2, 2)
                                    LMAHI.highlightFrame:SetSize(18, 18)
                                    LMAHI.highlightFrame:SetBackdrop({
                                        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                        tile = true, tileSize = 16, edgeSize = 8,
                                        insets = { left = 2, right = 2, top = 2, bottom = 2 },
                                    })
                                    LMAHI.highlightFrame:SetBackdropColor(0.1, 0.1, 0.3, 0.5)
                                    LMAHI.highlightFrame:Show()
                                end)
                                indicator:SetScript("OnLeave", function()
                                    GameTooltip:Hide()
                                    LMAHI.highlightFrame:Hide()
                                end)

                                -- Click to toggle lockout (for testing)
                                indicator:SetScript("OnClick", function()
                                    LMAHI_SavedData.lockouts[charName][tostring(lockout.id)] = not isLocked
                                    LMAHI.UpdateDisplay()
                                end)
                            end
                            offsetY = offsetY - 20
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
