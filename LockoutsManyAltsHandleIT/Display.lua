local addonName, addon = ...
local LMAHI = _G.LMAHI

-- UI element tables
local charLabels = {}
local realmLabels = {}
local lockoutIndicators = {}
local sectionHeaders = {}
local lockoutLabels = {}
local collapseButtons = {}
local charButtons = {}
local charNameLabels = {}
local settingRealmLabels = {}
local charOrderInputs = {}
local removeButtons = {}
local customLockoutLabels = {}
local removeCustomButtons = {}
local customOrderInputs = {}

-- Helper function for collapse icon rotation
function LMAHI.SetCollapseIconRotation(button, isCollapsed)
    local angle = isCollapsed and math.rad(90) or math.rad(270)
    C_Timer.After(0, function()
        if button and button.icon then
            button.icon:SetRotation(angle)
        end
    end)
end

-- Update custom input display
function LMAHI.UpdateCustomInputDisplay()
    if not LMAHI.customInputScrollContent then return end

    for _, label in ipairs(customLockoutLabels) do
        label:Hide()
    end
    for _, button in ipairs(removeCustomButtons) do
        button:Hide()
    end
    for _, input in ipairs(customOrderInputs) do
        input:Hide()
    end
    customLockoutLabels = {}
    removeCustomButtons = {}
    customOrderInputs = {}

    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
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

    local contentHeight = math.max(200, #customList * 25 + 20)
    LMAHI.customInputScrollContent:SetHeight(contentHeight)

    local offsetY = -10
    for i, lockout in ipairs(customList) do
        local button = CreateFrame("Button", nil, LMAHI.customInputScrollContent)
        button:SetSize(315, 22)
        button:SetPoint("TOPLEFT", LMAHI.customInputScrollContent, "TOPLEFT", 20, offsetY - ((i-1) * 25))
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:GetNormalTexture():SetVertexColor(0.08, 0.08, 0.08, 1)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button:Show()
        table.insert(customLockoutLabels, button)

        local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("RIGHT", button, "RIGHT", 0, 0)
        label:SetText(string.format("%s ID %d, %s", lockout.name, lockout.id, lockout.reset))
        label:Show()
        table.insert(customLockoutLabels, label)

        local orderInput = CreateFrame("EditBox", nil, LMAHI.customInputScrollContent, "InputBoxTemplate")
        orderInput:SetSize(40, 20)
        orderInput:SetPoint("LEFT", button, "RIGHT", 10, 0)
        orderInput:SetNumeric(true)
        orderInput:SetMaxLetters(3)
        orderInput:SetText(tostring(LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)] or i))
        orderInput:SetAutoFocus(false)
        orderInput.lockoutId = lockout.id
        orderInput:SetScript("OnEnterPressed", function(self)
            local newOrder = tonumber(self:GetText())
            if newOrder and newOrder >= 1 and newOrder <= #customList then
                local oldOrder = LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] or i
                LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] = newOrder
                
                local tempList = {}
                for _, otherLockout in ipairs(customList) do
                    if otherLockout.id ~= self.lockoutId then
                        table.insert(tempList, { id = otherLockout.id, order = LMAHI_SavedData.customLockoutOrder[tostring(otherLockout.id)] or 999 })
                    end
                end
                table.sort(tempList, function(a, b) return a.order < b.order end)
                
                local newCustomLockoutOrder = {}
                local currentOrder = 1
                
                if newOrder == 1 then
                    newCustomLockoutOrder[tostring(self.lockoutId)] = 1
                    currentOrder = 2
                end
                
                for _, entry in ipairs(tempList) do
                    if currentOrder == newOrder then
                        newCustomLockoutOrder[tostring(self.lockoutId)] = currentOrder
                        currentOrder = currentOrder + 1
                    end
                    newCustomLockoutOrder[tostring(entry.id)] = currentOrder
                    currentOrder = currentOrder + 1
                end
                
                if newOrder > #tempList + 1 then
                    newCustomLockoutOrder[tostring(self.lockoutId)] = newOrder
                end
                
                LMAHI_SavedData.customLockoutOrder = newCustomLockoutOrder
                
                LMAHI.UpdateCustomInputDisplay()
                LMAHI.UpdateDisplay()
            else
                self:SetText(tostring(LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] or i))
            end
            self:ClearFocus()
        end)
        orderInput:Show()
        table.insert(customOrderInputs, orderInput)

        local removeButton = CreateFrame("Button", nil, LMAHI.customInputScrollContent, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("LEFT", orderInput, "RIGHT", 5, 0)
        removeButton:SetText("Remove")
        removeButton.lockoutId = lockout.id
        removeButton:Show()

        removeButton:SetScript("OnClick", function(self)
            local x, y = self:GetCenter()
            local offsetX = 180
            local offsetY = 98
            StaticPopupDialogs["LMAHI_CONFIRM_REMOVE_LOCKOUT_" .. lockout.id] = {
                text = string.format("Do you want to remove\n%s ID: %d, %s\nfrom custom lockouts?", lockout.name, lockout.id, lockout.reset),
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    for j, l in ipairs(LMAHI.lockoutData.custom) do
                        if l.id == self.lockoutId then
                            table.remove(LMAHI.lockoutData.custom, j)
                            LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
                            LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] = nil
                            for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
                                lockouts[tostring(self.lockoutId)] = nil
                            end
                            LMAHI.NormalizeCustomLockoutOrder()
                            LMAHI.UpdateCustomInputDisplay()
                            LMAHI.UpdateDisplay()
                            LMAHI.SaveCharacterData()
                            break
                        end
                    end
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("LMAHI_CONFIRM_REMOVE_LOCKOUT_" .. lockout.id)
            local dialog = StaticPopup_FindVisible("LMAHI_CONFIRM_REMOVE_LOCKOUT_" .. lockout.id)
            if dialog then
                dialog:ClearAllPoints()
                dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
            end
        end)

        removeButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove Custom Lockout")
            GameTooltip:Show()
        end)

        removeButton:SetScript("OnLeave", GameTooltip_Hide)
        table.insert(removeCustomButtons, removeButton)
    end
end

-- Update settings display
function LMAHI.UpdateSettingsDisplay()
    if not LMAHI.charListContent then return end

    for _, button in ipairs(charButtons) do
        button:Hide()
    end
    for _, label in ipairs(charNameLabels) do
        label:Hide()
    end
    for _, label in ipairs(settingRealmLabels) do
        label:Hide()
    end
    for _, input in ipairs(charOrderInputs) do
        input:Hide()
    end
    for _, button in ipairs(removeButtons) do
        button:Hide()
    end
    charButtons = {}
    charNameLabels = {}
    settingRealmLabels = {}
    charOrderInputs = {}
    removeButtons = {}

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

    local contentHeight = math.max(400, #charList * 25 + 20)
    LMAHI.charListContent:SetHeight(contentHeight)
    for i, charName in ipairs(charList) do
        local button = CreateFrame("Button", nil, LMAHI.charListContent)
        button:SetSize(260, 22)
        button:SetPoint("TOPLEFT", LMAHI.charListContent, "TOPLEFT", 0, -((i-1) * 25 + 10))
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:GetNormalTexture():SetVertexColor(0.08, 0.08, 0.08, 1)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button:Show()
        table.insert(charButtons, button)

        local charDisplayName, realmName = strsplit("-", charName)
        local charLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        charLabel:SetPoint("RIGHT", button, "RIGHT", -85, 0)
        charLabel:SetText(charDisplayName or "Unknown")
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        charLabel:Show()
        table.insert(charNameLabels, charLabel)

        local realmLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        realmLabel:SetPoint("LEFT", charLabel, "RIGHT", 6, 0)
        realmLabel:SetText("- " .. (realmName or "Unknown"))
        local faction = LMAHI_SavedData.factions[charName] or "Alliance"
        local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(settingRealmLabels, realmLabel)

        local editBox = CreateFrame("EditBox", nil, LMAHI.charListContent, "InputBoxTemplate")
        editBox:SetSize(40, 20)
        editBox:SetPoint("LEFT", button, "RIGHT", 10, 0)
        editBox:SetNumeric(true)
        editBox:SetMaxLetters(3)
        editBox:SetText(tostring(LMAHI_SavedData.charOrder[charName] or i))
        editBox:SetAutoFocus(false)
        editBox.charName = charName
        editBox:SetScript("OnEnterPressed", function(self)
            local newOrder = tonumber(self:GetText())
            if newOrder and newOrder >= 1 and newOrder <= #charList then
                local oldOrder = LMAHI_SavedData.charOrder[self.charName] or i
                LMAHI_SavedData.charOrder[self.charName] = newOrder
                
                local tempList = {}
                for _, otherChar in ipairs(charList) do
                    if otherChar ~= self.charName then
                        table.insert(tempList, { name = otherChar, order = LMAHI_SavedData.charOrder[otherChar] or 999 })
                    end
                end
                table.sort(tempList, function(a, b) return a.order < b.order end)
                
                local newCharOrder = {}
                local currentOrder = 1
                
                if newOrder == 1 then
                    newCharOrder[self.charName] = 1
                    currentOrder = 2
                end
                
                for _, entry in ipairs(tempList) do
                    if currentOrder == newOrder then
                        newCharOrder[self.charName] = currentOrder
                        currentOrder = currentOrder + 1
                    end
                    newCharOrder[entry.name] = currentOrder
                    currentOrder = currentOrder + 1
                end
                
                if newOrder > #tempList + 1 then
                    newCharOrder[self.charName] = newOrder
                end
                
                LMAHI_SavedData.charOrder = newCharOrder
                
                LMAHI.UpdateSettingsDisplay()
                LMAHI.UpdateDisplay()
            else
                self:SetText(tostring(LMAHI_SavedData.charOrder[self.charName] or i))
            end
            self:ClearFocus()
        end)
        editBox:Show()
        table.insert(charOrderInputs, editBox)

        local removeButton = CreateFrame("Button", nil, LMAHI.charListContent, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 20)
        removeButton:SetPoint("LEFT", editBox, "RIGHT", 5, 0)
        removeButton:SetText("Remove")
        removeButton:Show()

        removeButton:SetScript("OnClick", function(self)
            local x, y = self:GetCenter()
            local offsetX = 180
            local offsetY = 98

            StaticPopupDialogs["LMAHI_CONFIRM_REMOVE_" .. charName] = {
                text = (function()
                    local charDisplayName, realmName = strsplit("-", charName)
                    local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
                    local faction = LMAHI_SavedData.factions[charName] or "Alliance"
                    local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }

                    local classColorHex = string.format("|cff%02x%02x%02x",
                        classColor.r * 255, classColor.g * 255, classColor.b * 255)
                    local factionColorHex = string.format("|cff%02x%02x%02x",
                        factionColor.r * 255, factionColor.g * 255, factionColor.b * 255)

                    return string.format("Do you really want to remove\n%s%s|r  %s%s|r\nfrom this addon!",
                        classColorHex, charDisplayName,
                        factionColorHex, realmName or "Unknown")
                end)(),
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    LMAHI_SavedData.characters[charName] = nil
                    LMAHI_SavedData.lockouts[charName] = nil
                    LMAHI_SavedData.charOrder[charName] = nil
                    LMAHI_SavedData.classColors[charName] = nil
                    LMAHI_SavedData.factions[charName] = nil

                    local newOrder = 1
                    for _, otherChar in ipairs(charList) do
                        if otherChar ~= charName then
                            LMAHI_SavedData.charOrder[otherChar] = newOrder
                            newOrder = newOrder + 1
                        end
                    end

                    LMAHI.UpdateSettingsDisplay()
                    LMAHI.UpdateDisplay()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }

            StaticPopup_Show("LMAHI_CONFIRM_REMOVE_" .. charName)
            local dialog = StaticPopup_FindVisible("LMAHI_CONFIRM_REMOVE_" .. charName)
            if dialog then
                dialog:ClearAllPoints()
                dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
            end
        end)

        removeButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove Character")
            GameTooltip:Show()
        end)

        removeButton:SetScript("OnLeave", GameTooltip_Hide)

        table.insert(removeButtons, removeButton)
    end
end

-- Calculate content height for lockout scroll frame
function LMAHI.CalculateContentHeight()
    local height = 20
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        height = height + 30
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            height = height + (#(LMAHI.lockoutData[lockoutType] or {}) * 20) + 10
        else
            height = height + 5
        end
    end
    return height
end

-- Update display
function LMAHI.UpdateDisplay()
    if not LMAHI.mainFrame or not LMAHI.lockoutData or not LMAHI.lockoutTypes then return end

    local startIndex = (LMAHI.currentPage - 1) * LMAHI.maxCharsPerPage + 1
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

    for _, indicator in ipairs(lockoutIndicators) do
        indicator:Hide()
    end
    lockoutIndicators = {}

    for _, label in ipairs(charLabels) do
        label:Hide()
    end
    charLabels = {}

    for _, label in ipairs(realmLabels) do
        label:Hide()
    end
    realmLabels = {}

    if LMAHI.charFrame then
        LMAHI.charFrame:Show()
        for i = 1, LMAHI.maxCharsPerPage do
            if not charLabels[i] then
                charLabels[i] = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                realmLabels[i] = LMAHI.charFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            end
            local charIndex = startIndex + i - 1
            if charList[charIndex] then
                local charName, realmName = strsplit("-", charList[charIndex])
                charLabels[i]:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", 20 + ((i-1) * 97), -12)
                charLabels[i]:SetText(charName or "Unknown")
                local classColor = LMAHI_SavedData.classColors[charList[charIndex]] or { r = 1, g = 1, b = 1 }
                charLabels[i]:SetTextColor(classColor.r, classColor.g, classColor.b)
                charLabels[i]:Show()
                
                realmLabels[i]:SetPoint("TOPLEFT", LMAHI.charFrame, "TOPLEFT", 20 + ((i-1) * 97), -26)
                realmLabels[i]:SetText(realmName or "Unknown")
                local faction = LMAHI_SavedData.factions[charList[charIndex]] or "Alliance"
                local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
                realmLabels[i]:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
                realmLabels[i]:Show()
            else
                charLabels[i]:Hide()
                realmLabels[i]:Hide()
            end
        end
    end

    if LMAHI.lockoutScrollFrame and LMAHI.lockoutContent then
        LMAHI.lockoutScrollFrame:Show()
        LMAHI.lockoutContent:SetHeight(LMAHI.CalculateContentHeight())
        LMAHI.lockoutContent:SetWidth(LMAHI.lockoutScrollFrame:GetWidth() - 30)
        LMAHI.lockoutContent:Show()

        -- Hide all lockout labels initially
        for _, label in pairs(lockoutLabels) do
            label:Hide()
        end

        local currentOffset = -20
        for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
            if collapseButtons[lockoutType] then
                collapseButtons[lockoutType]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, currentOffset)
                collapseButtons[lockoutType]:Show()
            end
            if sectionHeaders[lockoutType] then
                sectionHeaders[lockoutType]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 40, currentOffset)
                sectionHeaders[lockoutType]:Show()
            end
            currentOffset = currentOffset - 30
            if not LMAHI_SavedData.collapsedSections[lockoutType] then
                local sortedLockouts = {}
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    table.insert(sortedLockouts, lockout)
                end
                if lockoutType == "custom" then
                    table.sort(sortedLockouts, function(a, b)
                        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
                        if aIndex == bIndex then
                            return a.id < b.id
                        end
                        return aIndex < bIndex
                    end)
                end
                for j, lockout in ipairs(sortedLockouts) do
                    local lockoutId = tostring(lockout.id)
                    if not lockoutLabels[lockoutId] then
                        lockoutLabels[lockoutId] = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    end
                    lockoutLabels[lockoutId]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 40, currentOffset - ((j-1) * 20))
                    lockoutLabels[lockoutId]:SetText(lockout.name)
                    lockoutLabels[lockoutId]:Show()
                end
                currentOffset = currentOffset - (#(LMAHI.lockoutData[lockoutType] or {}) * 20)
                currentOffset = currentOffset - 10
            else
                currentOffset = currentOffset - 5
            end
        end

        for i = 1, LMAHI.maxCharsPerPage do
            local charIndex = startIndex + i - 1
            if charList[charIndex] and LMAHI_SavedData.lockouts[charList[charIndex]] then
                local currentOffset = -20
                for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
                    currentOffset = currentOffset - 30
                    if not LMAHI_SavedData.collapsedSections[lockoutType] then
                        local sortedLockouts = {}
                        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                            table.insert(sortedLockouts, lockout)
                        end
                        if lockoutType == "custom" then
                            table.sort(sortedLockouts, function(a, b)
                                local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                                local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
                                if aIndex == bIndex then
                                    return a.id < b.id
                                end
                                return aIndex < bIndex
                            end)
                        end
                        for j, lockout in ipairs(sortedLockouts) do
                            local lockoutId = tostring(lockout.id)
                            local indicator = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                            indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 235 + ((i-1) * 97), currentOffset - ((j-1) * 20))
                            if LMAHI_SavedData.lockouts[charList[charIndex]][lockoutId] then
                                indicator:SetText("X")
                                indicator:SetTextColor(1, 0, 0)
                            else
                                indicator:SetText("O")
                                indicator:SetTextColor(0, 1, 0)
                            end
                            indicator:Show()
                            table.insert(lockoutIndicators, indicator)
                        end
                        currentOffset = currentOffset - (#(LMAHI.lockoutData[lockoutType] or {}) * 20)
                        currentOffset = currentOffset - 10
                    else
                        currentOffset = currentOffset - 5
                    end
                end
            end
        end
    end
end