local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

local mainFrame
local charFrame
local lockoutScrollFrame
local lockoutContent
local highlightFrame
local prevPageButton
local nextPageButton

function LMAHI:OnLoad()
    print("LMAHI Debug: OnLoad called")
    LMAHI_SavedData = LMAHI_SavedData or {
        characters = {},
        lockouts = {},
        charOrder = {},
        classColors = {},
        factions = {},
        collapsedSections = {},
        customLockoutOrder = {},
    }
    LMAHI.currentPage = LMAHI.currentPage or 1
    LMAHI.maxPages = LMAHI.maxPages or 1
end

function LMAHI:CreateMainFrame()
    mainFrame = CreateFrame("Frame", "LMAHI_Frame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(1208, 402)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    mainFrame.TitleText:SetText("Lockouts Many Alts Handle IT")
    mainFrame:Show()

    charFrame = CreateFrame("Frame", "LMAHI_CharFrame", mainFrame, "BackdropTemplate")
    charFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 200, -24)
    charFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", 1208, 378)
    charFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    charFrame:SetBackdropColor(0, 0, 0, 0.8)
    charFrame:Show()

    lockoutScrollFrame = CreateFrame("ScrollFrame", "LMAHI_LockoutScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    lockoutScrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -64)
    lockoutScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", 200, 24)
    lockoutScrollFrame:Show()

    lockoutContent = CreateFrame("Frame", "LMAHI_LockoutContent", lockoutScrollFrame)
    lockoutContent:SetSize(192, 314)
    lockoutScrollFrame:SetScrollChild(lockoutContent)
    lockoutContent:Show()

    highlightFrame = CreateFrame("Frame", nil, lockoutScrollFrame)
    highlightFrame:SetAllPoints(lockoutScrollFrame)
    highlightFrame:SetFrameLevel(lockoutScrollFrame:GetFrameLevel() + 5)
    highlightFrame:Show()

    LMAHI.mainFrame = mainFrame
    LMAHI.charFrame = charFrame
    LMAHI.lockoutScrollFrame = lockoutScrollFrame
    LMAHI.lockoutContent = lockoutContent
    LMAHI.highlightFrame = highlightFrame
    LMAHI.sectionHeaders = {}
    LMAHI.lockoutLabels = {}
    LMAHI.collapseButtons = {}

    -- Navigation buttons
    prevPageButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    prevPageButton:SetSize(30, 30)
    prevPageButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -24)
    prevPageButton:SetText("<")
    prevPageButton:SetScript("OnClick", function()
        if LMAHI.currentPage > 1 then
            LMAHI.currentPage = LMAHI.currentPage - 1
            print("LMAHI Debug: Previous page clicked, currentPage:", LMAHI.currentPage)
            LMAHI.UpdateDisplay()
        end
    end)

    nextPageButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    nextPageButton:SetSize(30, 30)
    nextPageButton:SetPoint("LEFT", prevPageButton, "RIGHT", 5, 0)
    nextPageButton:SetText(">")
    nextPageButton:SetScript("OnClick", function()
        if LMAHI.currentPage < LMAHI.maxPages then
            LMAHI.currentPage = LMAHI.currentPage + 1
            print("LMAHI Debug: Next page clicked, currentPage:", LMAHI.currentPage)
            LMAHI.UpdateDisplay()
        end
    end)

    -- Update button visibility
    local function UpdateNavButtons()
        prevPageButton:SetShown(LMAHI.currentPage > 1)
        nextPageButton:SetShown(LMAHI.currentPage < LMAHI.maxPages)
        print("LMAHI Debug: Nav buttons updated - prev:", LMAHI.currentPage > 1, "next:", LMAHI.currentPage < LMAHI.maxPages)
    end
    mainFrame:SetScript("OnShow", function()
        LMAHI.UpdateDisplay()
        UpdateNavButtons()
    end)
    LMAHI.UpdateNavButtons = UpdateNavButtons
end

local function ThrottledUpdateDisplay()
    print("LMAHI Debug: Calling ThrottledUpdateDisplay")
    if LMAHI.UpdateDisplay then
        LMAHI.UpdateDisplay()
    else
        print("LMAHI Debug: UpdateDisplay is nil")
    end
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        print("LMAHI Debug: ADDON_LOADED")
        LMAHI:OnLoad()
        LMAHI:CreateMainFrame()
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
        ThrottledUpdateDisplay()
    elseif event == "PLAYER_ENTERING_WORLD" then
        print("LMAHI Debug: PLAYER_ENTERING_WORLD")
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
        ThrottledUpdateDisplay()
    elseif event == "PLAYER_LOGOUT" then
        print("LMAHI Debug: PLAYER_LOGOUT")
        if LMAHI.CheckLockouts then
            LMAHI.CheckLockouts()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", OnEvent)

-- Slash command to show the frame
SLASH_LMAHI1 = "/lmahi"
SlashCmdList["LMAHI"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        ThrottledUpdateDisplay()
        LMAHI.UpdateNavButtons()
    end
end

-- Debug command
SLASH_LMAHIDEBUG1 = "/lmahidebug"
SlashCmdList["LMAHIDEBUG"] = function()
    print("LMAHI Debug: Saved Data")
    print("Characters:", LMAHI_SavedData.characters and table.concat(LMAHI_SavedData.characters, ", ") or "nil")
    print("charOrder:", LMAHI_SavedData.charOrder and table.concat(LMAHI_SavedData.charOrder, ", ") or "nil")
    print("lockoutTypes:", LMAHI.lockoutTypes and table.concat(LMAHI.lockoutTypes, ", ") or "nil")
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        print("lockoutData[" .. lockoutType .. "]:")
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            print("  ", lockout.name, "id:", lockout.id)
        end
    end
    for charName, lockouts in pairs(LMAHI_SavedData.lockouts or {}) do
        print("lockouts[" .. charName .. "]:")
        for id, locked in pairs(lockouts) do
            if locked then
                print("  ", id, ":", locked)
            end
        end
    end
end
