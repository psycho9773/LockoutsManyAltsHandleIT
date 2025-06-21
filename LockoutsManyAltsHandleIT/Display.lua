-- Display.lua
local LMAHI = _G.LMAHI -- Use global LMAHI set by Core.lua

-- Ensure required variables are initialized
LMAHI.maxCharsPerPage = LMAHI.maxCharsPerPage or 10
LMAHI.currentPage = LMAHI.currentPage or 1
LMAHI.maxPages = LMAHI.maxPages or 1

-- UI element tables
local charLabels = {}
local realmLabels = {}
local lockoutIndicators = {}

-- Update display function
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

    -- Clear existing indicators
    for _, indicator in ipairs(lockoutIndicators) do
        indicator:Hide()
    end
    lockoutIndicators = {}

    -- Clear existing character labels
    for _, label in ipairs(charLabels) do
        label:Hide()
    end
    charLabels = {}

    -- Clear existing realm labels
    for _, label in ipairs(realmLabels) do
        label:Hide()
    end
    realmLabels = {}

    -- Update character frame
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

    -- Update lockout scroll frame
    if LMAHI.lockoutScrollFrame and LMAHI.lockoutContent then
        LMAHI.lockoutScrollFrame:Show()
        LMAHI.lockoutContent:SetHeight(LMAHI.CalculateContentHeight())
        LMAHI.lockoutContent:SetWidth(LMAHI.lockoutScrollFrame:GetWidth() - 30)
        LMAHI.lockoutContent:Show()

        -- Hide all lockout labels
        for _, label in pairs(LMAHI.lockoutLabels) do
            label:Hide()
        end

        local currentOffset = -20
        for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
            if LMAHI.collapseButtons[lockoutType] then
                LMAHI.collapseButtons[lockoutType]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 10, currentOffset)
                LMAHI.collapseButtons[lockoutType]:Show()
            end
            if LMAHI.sectionHeaders[lockoutType] then
                LMAHI.sectionHeaders[lockoutType]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 40, currentOffset - 4)
                LMAHI.sectionHeaders[lockoutType]:Show()
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
                    if not LMAHI.lockoutLabels[lockoutId] then
                        LMAHI.lockoutLabels[lockoutId] = LMAHI.lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    end
                    LMAHI.lockoutLabels[lockoutId]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 40, currentOffset - ((j-1) * 17) - 10) -- 10-pixel drop for lockout names
                    LMAHI.lockoutLabels[lockoutId]:SetText(lockout.name)
                    LMAHI.lockoutLabels[lockoutId]:Show()
                end
                currentOffset = currentOffset - (#(LMAHI.lockoutData[lockoutType] or {}) * 20)
                currentOffset = currentOffset - 10
            else
                currentOffset = currentOffset - 5
            end
        end

        -- Update lockout indicators
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
                            indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 235 + ((i-1) * 97), currentOffset - ((j-1) * 17) - 10) -- 10-pixel drop for indicators
                            local isLocked = LMAHI_SavedData.lockouts[charList[charIndex]][lockoutId]
                            indicator:SetText(isLocked and "x" or "o")
                            indicator:SetTextColor(isLocked and 0.8 or 0.2, isLocked and 0.2 or 0.8, 0.2)
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

    if LMAHI.highlightLine then
        LMAHI.highlightLine:Hide()
    end

    -- Update page navigation
    LMAHI.maxPages = math.ceil(#charList / LMAHI.maxCharsPerPage)
end