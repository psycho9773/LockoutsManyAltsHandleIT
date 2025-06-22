local addonName, addon = ...
_G.LMAHI = _G.LMAHI or {}

-- Initialize LMAHI_SavedData globally
LMAHI_SavedData = LMAHI_SavedData or {
    characters = {},
    lockouts = {},
    charOrder = {},
    classColors = {},
    factions = {},
    collapsedSections = {},
    customLockoutOrder = {},
}
print("LMAHI Debug: Core.lua loaded, LMAHI_SavedData initialized")

local mainFrame
local charFrame
local lockoutScrollFrame
local lockoutContent
local highlightFrame
local prevPageButton
local nextPageButton

function LMAHI:OnLoad()
    print("LMAHI Debug: OnLoad called")
    LMAHI.currentPage = LMAHI.currentPage or 1
    LMAHI.maxPages = LMAHI.maxPages or 1
end

function LMAHI:CreateMainFrame()
    print("LMAHI Debug: Creating main frame")
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
    print("LMAHI Debug: charFrame created, visible:", charFrame:IsVisible())

    lockoutScrollFrame = CreateFrame("ScrollFrame", "LMAHI_LockoutScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    lockoutScrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -64)
    lockoutScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", 200, 24)
    lockoutScrollFrame:Show()
    print("LMAHI Debug: lockoutScrollFrame created, visible:", lockoutScrollFrame:IsVisible())

    lockoutContent = CreateFrame("Frame", "LMAHI_LockoutContent", lockoutScrollFrame)
    lockoutContent:SetSize(192, 314)
    lockoutScrollFrame:SetScrollChild(lockoutContent)
    lockoutContent:Show()
    print("LMAHI Debug: lockoutContent created, visible:", lockoutContent:IsVisible())

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
    prevPageButton:SetPoint("TOPLEFT", charFrame, "TOPLEFT", 5, 5)
    prevPageButton:SetText("<")
    prevPageButton:SetScript("OnClick", function()
        if LMAHI.currentPage > 1 then
            LMAHI.currentPage = LMAHI.currentPage - 1
            print("LMAHI Debug: Previous page clicked, currentPage:", LMAHI.currentPage)
            LMAHI.UpdateDisplay()
            LMAHI.UpdateNavButtons()
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
            LMAHI.UpdateNavButtons()
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
    -- List characters
    local charList = {}
    for k, _ in pairs(LMAHI_SavedData.characters or {}) do
        table.insert(charList, k)
    end
    print("Characters:", #charList > 0 and table.concat(charList, ", ") or "nil")
    -- List charOrder
    local orderList = {}
    for k, v in pairs(LMAHI_SavedData.charOrder or {}) do
        table.insert(orderList, k .. "=" .. v)
    end
    print("charOrder:", #orderList > 0 and table.concat(orderList, ", ") or "nil")
    -- List lockoutTypes
    print("lockoutTypes:", LMAHI.lockoutTypes and table.concat(LMAHI.lockoutTypes, ", ") or "nil")
    -- List lockoutData
    for _, lockoutType in ipairs(LMAHI.lockoutTypes or {}) do
        print("lockoutData[" .. lockoutType .. "]:")
        for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
            print("  ", lockout.name, "id:", lockout.id)
        end
    end
    -- List lockouts
    for charName, lockouts in pairs(LMAHI_SavedData.lockouts or {}) do
        print("lockouts[" .. charName .. "]:")
        for id, locked in pairs(lockouts) do
            if locked then
                print("  ", id, ":", locked)
            end
        end
    end
end
