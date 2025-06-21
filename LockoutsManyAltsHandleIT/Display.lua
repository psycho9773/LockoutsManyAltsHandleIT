local addonName, addon = ...
local LMAHI = addon

LMAHI.currentPage = LMAHI.currentPage or 1
LMAHI.maxCharsPerPage = 10
LMAHI.maxPages = 1
LMAHI.lockoutLabels = LMAHI.lockoutLabels or {}

local charLabels = {}
local realmLabels = {}
local lockoutIndicators = {}

LMAHI.FACTION_COLORS = {
    Alliance = { r = 0.0, g = 0.4, b = 1.0 },
    Horde = { r = 1.0, g = 0.0, b = 0.0 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}

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
    return math.max(400, height)
end

function LMAHI.UpdateDisplay()
    if not LMAHI.mainFrame or not LMAHI.lockoutData or not LMAHI.lockoutTypes then
        print("LMAHI Debug: UpdateDisplay aborted - missing mainFrame, lockoutData, or lockoutTypes")
        return
    end

    -- Calculate total pages
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
    LMAHI.maxPages = math.ceil(#charList / LMAHI.maxCharsPerPage) or 1
    LMAHI.currentPage = math.max(1, math.min(LMAHI.currentPage, LMAHI.maxPages))
    print("LMAHI Debug: maxPages:", LMAHI.maxPages, "currentPage:", LMAHI.currentPage, "charList count:", #charList)

    local startIndex = (LMAHI.currentPage - 1) * LMAHI.maxCharsPerPage + 1
    print("LMAHI Debug: startIndex:", startIndex)

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
                print("LMAHI Debug: Rendering character", charList[charIndex], "at index", i)
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

        -- Hide all lockout labels and hover regions
        for _, label in pairs(LMAHI.lockoutLabels) do
            label:Hide()
        end
        if LMAHI.hoverRegions then
            for _, region in ipairs(LMAHI.hoverRegions) do
                region:Hide()
            end
        end
        LMAHI.hoverRegions = LMAHI.hoverRegions or {}

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
                    LMAHI.lockoutLabels[lockoutId]:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 40, currentOffset - ((j-1) * 17) - 10)
                    LMAHI.lockoutLabels[lockoutId]:SetText(lockout.name)
                    LMAHI.lockoutLabels[lockoutId]:Show()

                    -- Create hover region for this row
                    local hoverRegion = CreateFrame("Frame", nil, LMAHI.lockoutContent)
                    hoverRegion:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 40, currentOffset - ((j-1) * 17) - 10)
                    hoverRegion:SetSize(LMAHI.lockoutContent:GetWidth() - 40, 17)
                    hoverRegion:EnableMouse(true)
                    hoverRegion:SetScript("OnEnter", function()
                        print("LMAHI Debug: Hovering over lockout row", lockout.name)
                        if LMAHI.highlightLine then
                            LMAHI.highlightLine:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 0, currentOffset - ((j-1) * 17) - 10)
                            LMAHI.highlightLine:SetPoint("TOPRIGHT", LMAHI.lockoutContent, "TOPRIGHT", 0, currentOffset - ((j-1) * 17) - 10)
                            LMAHI.highlightLine:Show()
                        else
                            print("LMAHI Debug: highlightLine is nil in OnEnter, highlighting disabled")
                        end
                    end)
                    hoverRegion:SetScript("OnLeave", function()
                        print("LMAHI Debug: Leaving lockout row", lockout.name)
                        if LMAHI.highlightLine then
                            LMAHI.highlightLine:Hide()
                        end
                    end)
                    hoverRegion:Show()
                    table.insert(LMAHI.hoverRegions, hoverRegion)
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
                            indicator:SetPoint("TOPLEFT", LMAHI.lockoutContent, "TOPLEFT", 235 + ((i-1) * 97), currentOffset - ((j-1) * 17) - 10)
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
end
