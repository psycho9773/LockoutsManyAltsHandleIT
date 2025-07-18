-- Core.lua

-- Keep ALL HEADERS HEX and everything else r, g, b for colors of text

local addonName, addon = ...
_G.LMAHI = addon -- Expose addon namespace globally


-- Initialize SavedVariables

LMAHI_SavedData = LMAHI_SavedData or {
    characters = {},
    lockouts = {},
    charOrder = {},
    customLockoutOrder = {},
    minimapPos = { angle = math.rad(45) },
    framePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 },
    settingsFramePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 },
    customInputFramePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 },
    zoomLevel = 1,
    classColors = {},
    factions = {},
    collapsedSections = {},
    customLockouts = {},
    lastWeeklyReset = 0,
    lastDailyReset = 0,
    frameHeight = 402, -- Default height
}

-- Initialize lockoutData

LMAHI.lockoutData = LMAHI.lockoutData or {}
LMAHI.FACTION_COLORS = {
    Horde = { r = 0.95, g = 0.2, b = 0.2 },
    Alliance = { r = 0.2, g = 0.4, b = 1.0 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}



-- Frame variables

local mainFrame, charFrame, lockoutScrollFrame, lockoutContent, settingsFrame, customInputFrame
local highlightFrame
local charListScrollFrame, charListContent, customInputScrollFrame, customInputScrollContent
local sectionHeaders = {}
local lockoutLabels = {}
local collapseButtons = {}
local resizeButton

-- Throttle for UpdateDisplay

local lastUpdateTime = 0
local updateThrottle = 0.1
local lastResetCheckTime = 0
local resetCheckThrottle = 1

local function ThrottledUpdateDisplay()
    local currentTime = GetTime()
    if currentTime - lastUpdateTime >= updateThrottle then
        lastUpdateTime = currentTime
        if LMAHI.UpdateDisplay then
            LMAHI.UpdateDisplay()
        end
    end
end

--  SavedVariables setup

LMAHI_SavedData = LMAHI_SavedData or {}
LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(45) }

--  Always start in sleep mode

_G.LMAHI_Sleeping = true

-- Minimap config
local radius = 105

-- Minimap button frame
local minimapButton = CreateFrame("Button", "LMAHI_MinimapButton", Minimap)
minimapButton:SetSize(28, 28)
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 5)
minimapButton:RegisterForDrag("RightButton")
minimapButton:SetClampedToScreen(true)

-- Icon
local texture = minimapButton:CreateTexture(nil, "BACKGROUND")
texture:SetTexture("975738") -- Use your texture path if custom
texture:SetAllPoints()
minimapButton.texture = texture

-- Circular mask
local mask = minimapButton:CreateMaskTexture()
mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
mask:SetAllPoints()
texture:AddMaskTexture(mask)

-- Gold ring border
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Common\\GoldRing")
border:SetSize(30, 30)
border:SetPoint("CENTER", minimapButton, "CENTER")

-- Position logic
local function UpdateButtonPosition()
    local a = LMAHI_SavedData.minimapPos.angle or math.rad(45)
    local x = math.cos(a) * radius
    local y = math.sin(a) * radius
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Event-based setup
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if addonName == "LockoutsManyAltsHandleIT" then
        UpdateButtonPosition()
    end
end)

-- Drag behavior
minimapButton:SetScript("OnDragStart", function(self)
    self.dragging = true
end)

minimapButton:SetScript("OnDragStop", function(self)
    self.dragging = false
    self:StopMovingOrSizing()
end)

minimapButton:SetScript("OnUpdate", function(self)
    if self.dragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local dx = (px / scale - mx)
        local dy = (py / scale - my)
        local newAngle = math.atan2(dy, dx)

        LMAHI_SavedData.minimapPos.angle = newAngle
        UpdateButtonPosition()
    end
end)

--  Toggle sleep mode
minimapButton:SetScript("OnClick", function()
    if _G.LMAHI_Sleeping then
        if LMAHI_Enable then LMAHI_Enable() end
        _G.LMAHI_Sleeping = false
    else
        if LMAHI_Disable then LMAHI_Disable() end
        _G.LMAHI_Sleeping = true
    end

    -- Refresh tooltip after click
    GameTooltip:Hide()
    GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r")

    if _G.LMAHI_Sleeping then
        GameTooltip:AddLine("|cff00ff00Left click|r to activate")
    else
        GameTooltip:AddLine("|cffFF5555Left click|r to sleep")
    end

    GameTooltip:AddLine("|cffFF9933Right click|r to drag")
    GameTooltip:Show()
end)

-- Tooltip logic
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r")

    if _G.LMAHI_Sleeping then
        GameTooltip:AddLine("|cff00ff00Left click|r to activate")
    else
        GameTooltip:AddLine("|cffFF5555Left click|r to sleep")
    end

    GameTooltip:AddLine("|cffFF9933Right click|r to drag")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", GameTooltip_Hide)


-- Create main frame

mainFrame = CreateFrame("Frame", "LMAHI_Frame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_Frame")
mainFrame:SetSize(1208, LMAHI_SavedData.frameHeight or 402)
mainFrame:SetPoint(LMAHI_SavedData.framePos.point, UIParent, LMAHI_SavedData.framePos.relativePoint, LMAHI_SavedData.framePos.x, LMAHI_SavedData.framePos.y)
mainFrame:SetFrameStrata("HIGH")
mainFrame:SetFrameLevel(100)
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    LMAHI_SavedData.framePos = { point = point, relativeTo = "UIParent", relativePoint = relativePoint, x = x, y = y }
end)
mainFrame.CloseButton:SetScript("OnClick", function()
    -- Fully shut down LMAHI
    if LMAHI_Disable then
        LMAHI_Disable()
    end
    -- Just in case: hide any lingering frames
    settingsFrame:Hide()
    customInputFrame:Hide()
end)

local titleLabel = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
titleLabel:SetPoint("TOP", mainFrame, "TOP", 0, -3)
titleLabel:SetText("|cffADADAD---[ |r |cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r |cffADADAD ]---|r")

local authorLabel = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
authorLabel:SetPoint("LEFT", titleLabel, "RIGHT", 10, 0)
authorLabel:SetText("|cffADADADBy: Psycho|r")

-- Zoom buttons
local zoomStep = 0.01
local function ApplyZoom(level)
    level = math.min(1.5, math.max(0.75, level))
    LMAHI_SavedData.zoomLevel = math.floor(level * 100 + 0.5) / 100
    mainFrame:SetScale(LMAHI_SavedData.zoomLevel)
    settingsFrame:SetScale(LMAHI_SavedData.zoomLevel)
    customInputFrame:SetScale(LMAHI_SavedData.zoomLevel)
end

local zoomInButton = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
zoomInButton:SetSize(28, 28)
zoomInButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 28, 2)
zoomInButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
zoomInButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
zoomInButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
zoomInButton:SetScript("OnClick", function()
    ApplyZoom(LMAHI_SavedData.zoomLevel + zoomStep)
end)
zoomInButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Zoom In")
    GameTooltip:Show()
end)
zoomInButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local zoomOutButton = CreateFrame("Button", nil, mainFrame)
zoomOutButton:SetSize(28, 28)
zoomOutButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 2)
zoomOutButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
zoomOutButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
zoomOutButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
zoomOutButton:SetScript("OnClick", function()
    ApplyZoom(LMAHI_SavedData.zoomLevel - zoomStep)
end)
zoomOutButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Zoom Out")
    GameTooltip:Show()
end)
zoomOutButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Custom lockout input button
local customInputButton = CreateFrame("Button", nil, mainFrame)
customInputButton:SetSize(27, 32)
customInputButton:SetPoint("TOPLEFT", zoomInButton, "TOPRIGHT", 30, -35)
customInputButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
customInputButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
customInputButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
local goldOverlay = customInputButton:CreateTexture(nil, "ARTWORK", nil, 1)
goldOverlay:SetColorTexture(1, 0.85, 0, 0.2)
goldOverlay:SetAllPoints(customInputButton:GetNormalTexture())
customInputButton:SetScript("OnClick", function()
    customInputFrame:SetShown(not customInputFrame:IsShown())
    if customInputFrame:IsShown() and LMAHI.UpdateCustomInputDisplay then
        LMAHI.UpdateCustomInputDisplay()
    end
end)
customInputButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Custom Lockout Input")
    GameTooltip:Show()
end)
customInputButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Character order settings button
local settingsButton = CreateFrame("Button", nil, mainFrame)
settingsButton:SetSize(27, 32)
settingsButton:SetPoint("TOPLEFT", customInputButton, "TOPRIGHT", 14, 0)
settingsButton:SetNormalTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
settingsButton:SetPushedTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
local settingsOverlay = settingsButton:CreateTexture(nil, "ARTWORK", nil, 1)
settingsOverlay:SetColorTexture(1, 0.85, 0, 0.2)
settingsOverlay:SetAllPoints(settingsButton:GetNormalTexture())
settingsButton:SetScript("OnClick", function()
    settingsFrame:SetShown(not settingsFrame:IsVisible())
    if settingsFrame:IsVisible() and LMAHI.UpdateSettingsDisplay then
        LMAHI.UpdateSettingsDisplay()
    end
end)
settingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Character Order Settings")
    GameTooltip:Show()
end)
settingsButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Paging arrows
local leftArrow = CreateFrame("Button", nil, mainFrame)
leftArrow:SetSize(35, 50)
leftArrow:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 163, -23)
leftArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
--leftArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down") -- removed for weird down press behavior
leftArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
leftArrow:SetScript("OnClick", function()
    LMAHI.currentPage = math.max(1, LMAHI.currentPage - 1)
    ThrottledUpdateDisplay()
end)
leftArrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Previous Page")
    GameTooltip:Show()
end)
leftArrow:SetScript("OnLeave", function() GameTooltip:Hide() end)

local rightArrow = CreateFrame("Button", nil, mainFrame)
rightArrow:SetSize(35, 50)
rightArrow:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -23)
rightArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
--rightArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down") -- removed for weird down press behavior
rightArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
rightArrow:SetScript("OnClick", function()
    LMAHI.currentPage = math.min(LMAHI.maxPages or 1, LMAHI.currentPage + 1)
    ThrottledUpdateDisplay()
end)
rightArrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Next Page")
    GameTooltip:Show()
end)
rightArrow:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Store buttons in LMAHI namespace
LMAHI.leftArrow = leftArrow
LMAHI.rightArrow = rightArrow

-- Character Paged frame

charFrame = CreateFrame("Frame", "LMAHI_CharFrame", mainFrame, "BackdropTemplate")
charFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 195, -28)
charFrame:SetSize(980, 40)
charFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
charFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 10,
    edgeSize = 21,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
charFrame:SetBackdropColor(0, 0, 0, 1)
charFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
charFrame:Show()

-- Lockout scroll frame

lockoutScrollFrame = CreateFrame("ScrollFrame", "LMAHI_LockoutScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
lockoutScrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -74)
lockoutScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 10)
lockoutScrollFrame:EnableMouseWheel(true)
lockoutScrollFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
lockoutScrollFrame:SetClipsChildren(false)
lockoutScrollFrame:Show()

lockoutScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 30
    self:SetVerticalScroll(math.max(0, math.min(current - delta * scrollAmount, maxScroll)))
end)

lockoutContent = CreateFrame("Frame", "LMAHI_LockoutContent", lockoutScrollFrame)
lockoutScrollFrame:SetScrollChild(lockoutContent)
lockoutContent:SetWidth(1192)
lockoutContent:SetHeight(314) -- Will be updated dynamically
lockoutContent:SetFrameLevel(mainFrame:GetFrameLevel() + 2)
lockoutContent:Show()

-- Drag function for bottom of mainframe

local resizeArrow = CreateFrame("Frame", "LMAHI_ResizeArrow", mainFrame)
resizeArrow:SetSize(20, 40)
resizeArrow:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMRIGHT", - 70, -22)
resizeArrow:SetFrameStrata("HIGH")
resizeArrow:SetFrameLevel(mainFrame:GetFrameLevel() + 10)
resizeArrow:EnableMouse(true)
resizeArrow:Show()

local arrow = resizeArrow:CreateTexture(nil, "ARTWORK")
arrow:SetAllPoints()
arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
arrow:SetRotation(math.rad(270))
arrow:SetAlpha(.7)

resizeArrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")         
    GameTooltip:ClearAllPoints()                      
    GameTooltip:SetPoint("RIGHT", self, "LEFT", -8, -17)   
    GameTooltip:SetText("Drag to adjust height")
    GameTooltip:Show()
end)

resizeArrow:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local minHeight = 175
local maxHeight = UIParent:GetHeight()

resizeArrow:SetScript("OnMouseDown", function(self)
    self.isDragging = true
    local _, mouseY = GetCursorPosition()
    self.startY = mouseY
    self.startHeight = mainFrame:GetHeight()
    self.scale = mainFrame:GetEffectiveScale()
    maxHeight = UIParent:GetHeight() / self.scale
    SetCursor("SIZE")
end)

resizeArrow:SetScript("OnMouseUp", function(self)
    self.isDragging = false
    ResetCursor()
    LMAHI_SavedData.frameHeight = mainFrame:GetHeight()
    ThrottledUpdateDisplay()
end)

resizeArrow:SetScript("OnUpdate", function(self)
    if self.isDragging then
        local _, currentY = GetCursorPosition()
        local deltaY = (self.startY - currentY) / self.scale * 0.8
        local newHeight = math.max(minHeight, math.min(self.startHeight + deltaY, maxHeight))
        mainFrame:SetHeight(newHeight)
        lockoutContent:SetHeight(newHeight - 74 - 10)
    end
end)

-- Highlight frame for scrolling lockout frame

highlightFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
highlightFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 3)
highlightFrame:EnableMouse(false)
highlightFrame:Hide()

-- UI elements tables

local charLabels = {}
local realmLabels = {}
local charLocks = {}
local lockoutIndicators = {}
local charButtons = {}
local charNameLabels = {}
local settingRealmLabels = {}
local charOrderInputs = {}
local removeButtons = {}
local customLockoutLabels = {}
local removeCustomButtons = {}
local customOrderInputs = {}

-- Custom input frame

customInputFrame = CreateFrame("Frame", "LMAHI_CustomInputFrame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_CustomInputFrame")
customInputFrame:SetSize(515, 515)
customInputFrame:SetPoint(LMAHI_SavedData.customInputFramePos.point, UIParent, LMAHI_SavedData.customInputFramePos.relativePoint, LMAHI_SavedData.customInputFramePos.x, LMAHI_SavedData.customInputFramePos.y)
customInputFrame:SetFrameStrata("DIALOG")
customInputFrame:SetFrameLevel(150)
customInputFrame:EnableMouse(true)
customInputFrame:SetMovable(true)
customInputFrame:RegisterForDrag("LeftButton")
customInputFrame:SetScript("OnDragStart", customInputFrame.StartMoving)
customInputFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    LMAHI_SavedData.customInputFramePos = { point = point, relativeTo = "UIParent", relativePoint = relativePoint, x = x, y = y }
end)
customInputFrame:Hide()
customInputFrame:SetScale(LMAHI_SavedData.zoomLevel or 1)
customInputFrame.CloseButton:SetSize(24, 24)
customInputFrame.CloseButton:SetPoint("TOPRIGHT", customInputFrame, "TOPRIGHT", 0, 0)
customInputFrame.CloseButton:SetFrameLevel(155)
customInputFrame.CloseButton:EnableMouse(true)
customInputFrame.CloseButton:Enable()
customInputFrame.CloseButton:SetNormalTexture("Interface\\Buttons\\UIPanelCloseButton")
customInputFrame.CloseButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
customInputFrame.CloseButton:SetScript("OnClick", function()
    customInputFrame:Hide()
end)

local customInputTitle = customInputFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
customInputTitle:SetPoint("TOP", customInputFrame, "TOP", 0, -3)
customInputTitle:SetText("|cff99ccffCustom|r |cffADADADLockout|r |cff99ccffInput|r")

local customInputContent = CreateFrame("Frame", nil, customInputFrame, "BackdropTemplate")
customInputContent:SetSize(445, 150)
customInputContent:SetPoint("TOPLEFT", customInputFrame, "TOPLEFT", 35, -30)
customInputContent:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 14,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
customInputContent:SetBackdropColor(0.1, 0.1, 0.1, 1)
customInputContent:SetFrameLevel(customInputFrame:GetFrameLevel() + 1)
customInputContent:Show()

local nameLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
nameLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 46, -10)
nameLabel:SetText("Name of the Lockout")
nameLabel:Show()

local nameInput = CreateFrame("EditBox", nil, customInputContent, "InputBoxTemplate")
nameInput:SetSize(180, 20)
nameInput:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 20, -29)
nameInput:SetMaxLetters(30)
nameInput:SetAutoFocus(false)
nameInput:Show()

local idLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
idLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 224, -10)
idLabel:SetText("Custom ID.")
idLabel:Show()

local idInput = CreateFrame("EditBox", nil, customInputContent, "InputBoxTemplate")
idInput:SetSize(100, 20)
idInput:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 211, -29)
idInput:SetNumeric(true)
idInput:SetMaxLetters(10)
idInput:SetAutoFocus(false)
idInput:Show()

local tipLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
tipLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 35, -55)
tipLabel:SetTextColor(0.9, 0.9, 0.9, 0.9)
tipLabel:SetSpacing(3)
local lines = {
    "Type in the Name (quest,rare etc.) and ID., select a reset type",
    "and then press the Add Custom Lockout button below.",
    "Reorganize the Custom Lockout order by typing a number",
    "in the edit box below and then press Enter.",
}
tipLabel:SetText(table.concat(lines, "\n"))

local resetLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
resetLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 340, -10)
resetLabel:SetText("Reset Type")
resetLabel:Show()
-- Create the reset dropdown
local resetDropdown = CreateFrame("Frame", "LMAHI_ResetDropdown", customInputContent, "UIDropDownMenuTemplate")
resetDropdown:SetPoint("TOPLEFT", resetLabel, "TOPRIGHT", -110, -15)
UIDropDownMenu_SetWidth(resetDropdown, 100)
-- Dropdown options
local resetOptions = {
    { text = "Weekly", value = "weekly" },
    { text = "Daily", value = "daily" },
    { text = "None", value = "none" },
}
-- Selected value tracker
local selectedResetValue = "weekly" -- default
-- Initialize dropdown
UIDropDownMenu_Initialize(resetDropdown, function(self, level)
    for i, option in ipairs(resetOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.checked = (option.value == selectedResetValue) -- highlight selected
        info.func = function()
            selectedResetValue = option.value
            UIDropDownMenu_SetSelectedValue(resetDropdown, option.value)
            _G[resetDropdown:GetName() .. "Text"]:SetText(option.text) -- update visible label
        end
        UIDropDownMenu_AddButton(info)
    end
end)
-- Default selection display
UIDropDownMenu_SetSelectedValue(resetDropdown, selectedResetValue)
_G[resetDropdown:GetName() .. "Text"]:SetText("Weekly")
-- Default selection
UIDropDownMenu_SetSelectedValue(resetDropdown, "weekly")
UIDropDownMenu_SetText(resetDropdown, "Weekly")
_G[resetDropdown:GetName() .. "Text"]:SetText("Weekly") --  Initial label fix


local addButton = CreateFrame("Button", nil, customInputContent, "UIPanelButtonTemplate")
addButton:SetSize(300, 24)
addButton:SetPoint("TOPLEFT", resetLabel, "BOTTOM", -300, -95)
addButton:SetText("Add Custom Lockout")
addButton:Show()

addButton:SetScript("OnClick", function()
    local name = nameInput:GetText()
    local id = tonumber(idInput:GetText())
    local reset = UIDropDownMenu_GetSelectedValue(resetDropdown)

    if name == "" or id == nil then
        print("LMAHI: Please enter a valid Custom name and ID.")
        return
    end

    -- Check for duplicate ID only within custom lockouts

    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        if lockout.id == id then
            print("LMAHI: This Custom ID is already in use.")
            return
        end
    end

    table.insert(LMAHI.lockoutData.custom, { id = id, name = name, reset = reset })
    LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
    LMAHI_SavedData.customLockoutOrder[tostring(id)] = #LMAHI.lockoutData.custom

    -- Initialize lockout status for all characters

    for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
        if not lockouts[tostring(id)] then
            lockouts[tostring(id)] = false
        end
    end

    nameInput:SetText("")
    idInput:SetText("")
    UIDropDownMenu_SetSelectedValue(resetDropdown, "weekly")
    UIDropDownMenu_SetText(resetDropdown, "Weekly")

    if LMAHI.UpdateCustomInputDisplay then
        LMAHI.UpdateCustomInputDisplay()
    end
    ThrottledUpdateDisplay()
end)

customInputScrollFrame = CreateFrame("ScrollFrame", "LMAHI_CustomInputScrollFrame", customInputFrame, "UIPanelScrollFrameTemplate")
customInputScrollFrame:SetSize(450, 305)
customInputScrollFrame:SetPoint("TOPLEFT", customInputFrame, "TOPLEFT", 30, -185)
customInputScrollFrame:EnableMouseWheel(true)
customInputScrollFrame:SetFrameLevel(customInputFrame:GetFrameLevel() + 2)
customInputScrollFrame:Show()

customInputScrollContent = CreateFrame("Frame", nil, customInputScrollFrame)
customInputScrollFrame:SetScrollChild(customInputScrollContent)
customInputScrollContent:SetSize(440, 270)
customInputScrollContent:SetFrameLevel(customInputScrollFrame:GetFrameLevel() + 1)
customInputScrollContent:Show()

customInputScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local currentScroll = self:GetVerticalScroll()
    maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 35
    self:SetVerticalScroll(math.max(0, math.min(currentScroll - delta * scrollAmount, maxScroll)))
end)

-- Update custom input display

LMAHI.UpdateCustomInputDisplay = function()
    if not LMAHI.customInputScrollContent then
        return
    end

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
        if lockout.id then
            table.insert(customList, lockout)
        end
    end
    table.sort(customList, function(a, b)
        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1000
        if aIndex == bIndex then
            return a.id < b.id
        end
        return aIndex < bIndex
    end)

    local contentHeight = math.max(280, #customList * 30)
    LMAHI.customInputScrollContent:SetHeight(contentHeight)

    local offsetY = -11
    for i, lockout in ipairs(customList) do
        local button = CreateFrame("Button", nil, LMAHI.customInputScrollContent)
        button:SetSize(330, 25)
        button:SetPoint("TOPLEFT", LMAHI.customInputScrollContent, "TOPLEFT", 5, offsetY - ((i - 1) * 30))
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:GetNormalTexture():SetVertexColor(0.1, 0.1, 0.1, 1)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button:Show()
        table.insert(customLockoutLabels, button)

        local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("RIGHT", button, "RIGHT", -10, 0)
        label:SetText(string.format("%s   |cff99ccffID:|r |cff99ccff%d|r |cffffffff %s|r",
            lockout.name, lockout.id, lockout.reset
        ))
        label:Show()
        table.insert(customLockoutLabels, label)

        local orderInput = CreateFrame("EditBox", nil, LMAHI.customInputScrollContent, "InputBoxTemplate")
        orderInput:SetSize(40, 20)
        orderInput:SetPoint("LEFT", button, "RIGHT", 10, 0)
        orderInput:SetNumeric(true)
        orderInput:SetMaxLetters(3)
        orderInput:SetText(tostring(LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)] or i))
        orderInput.lockoutId = lockout.id
        orderInput:SetScript("OnEnterPressed", function(self)
            local newOrder = tonumber(self:GetText())
            if newOrder and newOrder >= 1 and newOrder <= #customList then
                local newCustomLockoutOrder = {}
                local currentOrder = 1
                for _, otherLockout in ipairs(customList) do
                    if otherLockout.id == self.lockoutId then
                        newCustomLockoutOrder[tostring(self.lockoutId)] = newOrder
                    else
                        if currentOrder == newOrder then
                            currentOrder = currentOrder + 1
                        end
                        newCustomLockoutOrder[tostring(otherLockout.id)] = currentOrder
                        currentOrder = currentOrder + 1
                    end
                end
                LMAHI_SavedData.customLockoutOrder = newCustomLockoutOrder
                if LMAHI.UpdateCustomInputDisplay then
                    LMAHI.UpdateCustomInputDisplay()
                end
                ThrottledUpdateDisplay()
            end
            self:SetText(tostring(LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] or i))
            self:ClearFocus()
        end)
        orderInput:Show()
        table.insert(customOrderInputs, orderInput)

        local removeButton = CreateFrame("Button", nil, LMAHI.customInputScrollContent, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 25)
        removeButton:SetPoint("LEFT", orderInput, "RIGHT", 5, 0)
        removeButton:SetText("Remove")
        removeButton.lockoutId = lockout.id
        removeButton:Show()
        table.insert(removeCustomButtons, removeButton)

        removeButton:SetScript("OnClick", function(self)
            local dialogKey = "LMAHI_CONFIRM_REMOVE_LOCKOUT_" .. lockout.id
            StaticPopupDialogs[dialogKey] = {
                text = string.format("Do you want to remove\n%s ID: %d, %s\nfrom the list?", lockout.name, lockout.id, lockout.reset),
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    for i, l in ipairs(LMAHI.lockoutData.custom) do
                        if l.id == self.lockoutId then
                            table.remove(LMAHI.lockoutData.custom, i)
                            LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
                            LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] = nil
                            -- Normalize customLockoutOrder to remove gaps
                            local newCustomList = {}
                            for _, lockout in ipairs(LMAHI.lockoutData.custom) do
                                table.insert(newCustomList, lockout)
                            end
                            table.sort(newCustomList, function(a, b)
                                local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                                local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1000
                                return aIndex < bIndex or (aIndex == bIndex and a.id < b.id)
                            end)
                            local newCustomLockoutOrder = {}
                            for i, lockout in ipairs(newCustomList) do
                                newCustomLockoutOrder[tostring(lockout.id)] = i
                            end
                            LMAHI_SavedData.customLockoutOrder = newCustomLockoutOrder
                            if LMAHI.UpdateCustomInputDisplay then
                                LMAHI.UpdateCustomInputDisplay()
                            end
                            ThrottledUpdateDisplay()
                            if LMAHI.SaveCharacterData then
                                LMAHI.SaveCharacterData()
                            end
                            break
                        end
                    end
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }

            local popup = StaticPopup_Show(dialogKey)
            if popup then
                popup:ClearAllPoints()
                popup:SetPoint("RIGHT", self, "RIGHT", 40, 60)
            end
        end)
    end
end


-- Settings Frame Main

settingsFrame = CreateFrame("Frame", "LMAHI_SettingsFrame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, settingsFrame:GetName())
settingsFrame:SetSize(415, 500)
settingsFrame:SetPoint(
    LMAHI_SavedData.settingsFramePos.point,
    UIParent,
    LMAHI_SavedData.settingsFramePos.relativePoint,
    LMAHI_SavedData.settingsFramePos.x,
    LMAHI_SavedData.settingsFramePos.y
)
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:SetFrameLevel(200)
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    LMAHI_SavedData.settingsFramePos = {
        point = point,
        relativeTo = "UIParent",
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end)
settingsFrame:Hide()
settingsFrame:SetScale(LMAHI_SavedData.zoomLevel or 1)

local settingsTitle = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
settingsTitle:SetPoint("TOP", settingsFrame, "TOP", 0, -3)
settingsTitle:SetText("|cff99ccffCharacter|r |cffADADADOrder|r |cff99ccffSettings|r")

local settingsInfoContent = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
settingsInfoContent:SetSize(345, 80)
settingsInfoContent:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 35, -25)
settingsInfoContent:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 14,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
settingsInfoContent:SetBackdropColor(0.1, 0.1, 0.1, 1)
settingsInfoContent:SetFrameLevel(settingsFrame:GetFrameLevel() + 1)
settingsInfoContent:Show()

local infoText = settingsInfoContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
infoText:SetPoint("TOPLEFT", settingsInfoContent, "TOPLEFT", 30, -10)
infoText:SetTextColor(0.9, 0.9, 0.9, 0.9)
infoText:SetSpacing(3)
local lines = {
    "To remove a character press the remove button.",
    "To reorder a character, type a number in the ",
    "edit box below next to that character's name", 
    "and then press Enter to apply the change",
}
infoText:SetText(table.concat(lines, "\n"))

charListScrollFrame = CreateFrame("ScrollFrame", "LMAHI_CharListScrollFrame", settingsFrame, "UIPanelScrollFrameTemplate")
charListScrollFrame:SetSize(380, 365)
charListScrollFrame:SetPoint("TOP", settingsFrame, "TOP", -18, -110)
charListScrollFrame:SetFrameLevel(settingsFrame:GetFrameLevel() + 2)
charListScrollFrame:Show()
charListScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 35
    self:SetVerticalScroll(math.max(0, math.min(current - delta * scrollAmount, maxScroll)))
end)

charListContent = CreateFrame("Frame", nil, charListScrollFrame)
charListScrollFrame:SetScrollChild(charListContent)
charListContent:SetSize(360, 360)
charListContent:Show()

-- Update settings display

LMAHI.UpdateSettingsDisplay = function()
    if not LMAHI.charListContent then return end

    for _, v in ipairs({ charButtons, charNameLabels, settingRealmLabels, charOrderInputs, removeButtons }) do
        for _, element in ipairs(v) do element:Hide() end
    end

    charButtons, charNameLabels, settingRealmLabels, charOrderInputs, removeButtons = {}, {}, {}, {}, {}

    local charList = {}
    for charName in pairs(LMAHI_SavedData.characters or {}) do
        table.insert(charList, charName)
    end
    table.sort(charList, function(a, b)
        local aIndex = LMAHI_SavedData.charOrder[a] or 999
        local bIndex = LMAHI_SavedData.charOrder[b] or 1000
        return aIndex == bIndex and a < b or aIndex < bIndex
    end)

    LMAHI.charListContent:SetHeight(math.max(340, #charList * 30))

    for i, charName in ipairs(charList) do
        local button = CreateFrame("Button", nil, LMAHI.charListContent)
        button:SetSize(230, 25)
        button:SetPoint("TOPLEFT", LMAHI.charListContent, "TOPLEFT", 35, -((i - 1) * 30 + 10))
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:GetNormalTexture():SetVertexColor(0.1, 0.1, 0.1, 1)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        table.insert(charButtons, button)
        button:Show()

        local name, realm = strsplit("-", charName)

        local realmLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        realmLabel:SetPoint("RIGHT", button, "RIGHT", -6, 0)
        realmLabel:SetText(realm or "")
        local faction = LMAHI_SavedData.factions[charName] or "Neutral"
        local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(settingRealmLabels, realmLabel)

        local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("RIGHT", realmLabel, "LEFT", -7, 0)
        label:SetText(name or "Unknown")
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        label:SetTextColor(classColor.r, classColor.g, classColor.b)
        label:Show()
        table.insert(charNameLabels, label)

        local orderInput = CreateFrame("EditBox", nil, LMAHI.charListContent, "InputBoxTemplate")
        orderInput:SetSize(40, 20)
        orderInput:SetPoint("LEFT", button, "RIGHT", 10, 0)
        orderInput:SetNumeric(true)
        orderInput:SetMaxLetters(3)
        orderInput:SetText(tostring(LMAHI_SavedData.charOrder[charName] or i))
        orderInput.charName = charName
        orderInput:SetScript("OnEnterPressed", function(self)
            local newOrder = tonumber(self:GetText())
            if newOrder and newOrder >= 1 and newOrder <= #charList then
                local newCharOrder, index = {}, 1
                for _, other in ipairs(charList) do
                    if other == self.charName then
                        newCharOrder[self.charName] = newOrder
                    else
                        if index == newOrder then index = index + 1 end
                        newCharOrder[other] = index
                        index = index + 1
                    end
                end
                LMAHI_SavedData.charOrder = newCharOrder
                LMAHI.UpdateSettingsDisplay()
                ThrottledUpdateDisplay()
            end
            self:SetText(tostring(LMAHI_SavedData.charOrder[self.charName] or i))
            self:ClearFocus()
        end)
        table.insert(charOrderInputs, orderInput)
        orderInput:Show()

        local removeButton = CreateFrame("Button", nil, LMAHI.charListContent, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 25)
        removeButton:SetPoint("LEFT", orderInput, "RIGHT", 5, 0)
        removeButton:SetText("Remove")
        removeButton.charName = charName
        table.insert(removeButtons, removeButton)
        removeButton:Show()

removeButton:SetScript("OnClick", function(self)
    local dialogKey = "LMAHI_CONFIRM_REMOVE_CHAR_" .. self.charName

    -- Add color formatting for name and realm
    local name, realm = strsplit("-", self.charName or "Unknown-Unknown")
    local classColor = LMAHI_SavedData.classColors[self.charName] or { r = 1, g = 1, b = 1 }
    local factionColor = LMAHI.FACTION_COLORS[LMAHI_SavedData.factions[self.charName] or "Neutral"] or { r = 0.8, g = 0.8, b = 0.8 }

    local nameHex = string.format("%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    local realmHex = string.format("%02x%02x%02x", factionColor.r * 255, factionColor.g * 255, factionColor.b * 255)

    local coloredName = "|cff" .. nameHex .. name .. "|r"
    local coloredRealm = "|cff" .. realmHex .. realm .. "|r"
    local coloredFullName = coloredName .. "|cff999999  -  |r" .. coloredRealm

    StaticPopupDialogs[dialogKey] = {
        text = "Do you REALLY want to remove\n" .. coloredFullName .. "\nfrom the character list?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            LMAHI_SavedData.characters[self.charName] = nil
            LMAHI_SavedData.lockouts[self.charName] = nil
            LMAHI_SavedData.classColors[self.charName] = nil
            LMAHI_SavedData.factions[self.charName] = nil
            LMAHI_SavedData.charOrder[self.charName] = nil

            -- Normalize charOrder to remove gaps
            local newCharList = {}
            for char in pairs(LMAHI_SavedData.characters or {}) do
                table.insert(newCharList, char)
            end
            table.sort(newCharList, function(a, b)
                local aIndex = LMAHI_SavedData.charOrder[a] or 999
                local bIndex = LMAHI_SavedData.charOrder[b] or 1000
                return aIndex == bIndex and a < b or aIndex < bIndex
            end)
            local newCharOrder = {}
            for i, char in ipairs(newCharList) do
                newCharOrder[char] = i
            end
            LMAHI_SavedData.charOrder = newCharOrder

            LMAHI.UpdateSettingsDisplay()
            ThrottledUpdateDisplay()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    local popup = StaticPopup_Show(dialogKey)
    if popup then
        popup:ClearAllPoints()
        popup:SetPoint("RIGHT", self, "RIGHT", 40, 55)
    end
  end)
 end
end

-- Event handling

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if LMAHI.InitializeData then
            LMAHI.InitializeData()
        end
        LMAHI_SavedData.customLockouts = LMAHI_SavedData.customLockouts or {}
        LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts
        UpdateButtonPosition()
        if LMAHI.InitializeLockouts then
            LMAHI.InitializeLockouts()
        end
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
        if LMAHI.CheckLockouts then
            LMAHI.CheckLockouts()
        end
        LMAHI.currentPage = 1
        mainFrame:SetScale(LMAHI_SavedData.zoomLevel)
        settingsFrame:SetScale(LMAHI_SavedData.zoomLevel)
        customInputFrame:SetScale(LMAHI_SavedData.zoomLevel)
        mainFrame:SetHeight(LMAHI_SavedData.frameHeight or 402)
        lockoutContent:SetHeight((LMAHI_SavedData.frameHeight or 402) - 74 - 10)
        mainFrame:Hide()
    elseif event == "PLAYER_LOGIN" then
        UpdateButtonPosition()
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
        if LMAHI.CheckLockouts then
            LMAHI.CheckLockouts()
        end
        mainFrame:Hide()
    end
end)

eventFrame:SetScript("OnUpdate", function(self, elapsed)
    lastResetCheckTime = lastResetCheckTime + elapsed
    if lastResetCheckTime >= resetCheckThrottle then
        if LMAHI.CheckResetTimers then
            LMAHI.CheckResetTimers()
        end
        lastResetCheckTime = 0
    end
end)

mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("ENCOUNTER_END")
mainFrame:RegisterEvent("QUEST_TURNED_IN")
mainFrame:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
mainFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
--mainFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(45) }
        LMAHI_SavedData.framePos = LMAHI_SavedData.framePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.settingsFramePos = LMAHI_SavedData.settingsFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.customInputFramePos = LMAHI_SavedData.customInputFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.zoomLevel = LMAHI_SavedData.zoomLevel or 1
        LMAHI_SavedData.frameHeight = LMAHI_SavedData.frameHeight or 402
        LMAHI_SavedData.characters = LMAHI_SavedData.characters or {}
        LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
        LMAHI_SavedData.charOrder = LMAHI_SavedData.charOrder or {}
        LMAHI_SavedData.customLockoutOrder = LMAHI_SavedData.customLockoutOrder or {}
        LMAHI_SavedData.classColors = LMAHI_SavedData.classColors or {}
        LMAHI_SavedData.factions = LMAHI_SavedData.factions or {}
        LMAHI_SavedData.customLockouts = LMAHI_SavedData.customLockouts or {}
        LMAHI_SavedData.lastWeeklyReset = LMAHI_SavedData.lastWeeklyReset or 0
        LMAHI_SavedData.lastDailyReset = LMAHI_SavedData.lastDailyReset or 0
        LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts
        local charList = {}
        for charName, _ in pairs(LMAHI_SavedData.characters) do
            table.insert(charList, charName)
        end
        table.sort(charList, function(a, b)
            local aIndex = LMAHI_SavedData.charOrder[a] or 999
            local bIndex = LMAHI_SavedData.charOrder[b] or 1000
            if aIndex == bIndex then
                return a < b
            end
            return aIndex < bIndex
        end)
        local newCharOrder = {}
        for i, charName in ipairs(charList) do
            newCharOrder[charName] = i
        end
        LMAHI_SavedData.charOrder = newCharOrder
        if LMAHI.CheckLockouts then
            LMAHI.CheckLockouts()
        end
        mainFrame:Hide()

        Utilities.StartGarbageCollector() --  Add the garbage collector here, after setup
    elseif event == "PLAYER_LOGOUT" then
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_END" or event == "QUEST_TURNED_IN" or event == "LFG_LOCK_INFO_RECEIVED" or event == "UPDATE_INSTANCE_INFO" or event == "CURRENCY_DISPLAY_UPDATE" then
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
        if LMAHI.CheckLockouts then
            LMAHI.CheckLockouts(event, arg1)
        end
        if mainFrame:IsShown() then
            ThrottledUpdateDisplay()
        end
    end
end)

-- Expose frames to namespace

LMAHI.mainFrame = mainFrame
LMAHI.charFrame = charFrame
LMAHI.lockoutScrollFrame = lockoutScrollFrame
LMAHI.lockoutContent = lockoutContent
LMAHI.settingsFrame = settingsFrame
LMAHI.customInputFrame = customInputFrame
LMAHI.highlightFrame = highlightFrame
LMAHI.charListScrollFrame = charListScrollFrame
LMAHI.charListContent = charListContent
LMAHI.customInputScrollFrame = customInputScrollFrame
LMAHI.customInputScrollContent = customInputScrollContent
LMAHI.sectionHeaders = sectionHeaders
LMAHI.lockoutLabels = lockoutLabels
LMAHI.collapseButtons = collapseButtons

--[[
-- Memory Usage Tracker (always visible)

local memFrame = CreateFrame("Frame", "LMAHIMemoryFrame", UIParent)
memFrame:SetFrameStrata("DIALOG")
memFrame:SetSize(175, 15)
memFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 75, -4)

memFrame.bg = memFrame:CreateTexture(nil, "BACKGROUND")
memFrame.bg:SetAllPoints()
memFrame.bg:SetColorTexture(0, 0, 0, 0.25)

memFrame.text = memFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
memFrame.text:SetPoint("LEFT", memFrame, "LEFT")
memFrame.text:SetTextColor(1, 1, 1)

-- CPU Usage Tracker (always visible)

local cpuFrame = CreateFrame("Frame", "LMAHICPUFrame", UIParent)
cpuFrame:SetFrameStrata("DIALOG")
cpuFrame:SetSize(225, 15)
cpuFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 75, -19)

cpuFrame.bg = cpuFrame:CreateTexture(nil, "BACKGROUND")
cpuFrame.bg:SetAllPoints()
cpuFrame.bg:SetColorTexture(0, 0, 0, 0.25)

cpuFrame.text = cpuFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
cpuFrame.text:SetPoint("LEFT", cpuFrame, "LEFT")
cpuFrame.text:SetTextColor(1, 1, 1)

-- Update memory usage every second
C_Timer.NewTicker(1, function()
    UpdateAddOnMemoryUsage()
    local mem = GetAddOnMemoryUsage(addonName)
    memFrame.text:SetText(string.format("LMAHI Mem: %.2f MB", mem / 1024))
end)

-- Update CPU usage every second
local lastCPU = 0
C_Timer.NewTicker(1, function()
    UpdateAddOnCPUUsage()
    local currentCPU = GetAddOnCPUUsage(addonName) or 0
    local delta = currentCPU - lastCPU
    lastCPU = currentCPU

    local framerate = GetFramerate() or 60
    local frameTime = 1000 / framerate
    local percent = (delta / frameTime) * 100

    if percent > 10 then
        cpuFrame.text:SetTextColor(1, 0.2, 0.2)
    else
        cpuFrame.text:SetTextColor(1, 1, 1)
    end

    cpuFrame.text:SetText(string.format("LMAHI CPU: %.2f ms/s (%.1f%%)", delta, percent))
end)

]]    -- BLOCKED OFF TO STOP RUNNING

-- Main frame hookup
LMAHI.mainFrame = mainFrame

-- Sleep state tracking
function LMAHI_Enable()
    if LMAHI.mainFrame then
        LMAHI.mainFrame:Show()
    end
    _G.LMAHI_Sleeping = false
    print("LMAHI activated")
    LMAHI:ResetCaches() -- Reset caches to prevent stale data
    if LMAHI.SaveCharacterData then
        LMAHI.SaveCharacterData()
    end
    if LMAHI.CheckLockouts then
        LMAHI.CheckLockouts()
    end
    LMAHI.UpdateDisplay() -- Force immediate update
end

function LMAHI_Disable()
    if LMAHI.mainFrame then
        LMAHI.mainFrame:Hide()
    end
    _G.LMAHI_Sleeping = true
    print(" LMAHI sleep mode enabled")

    -- Optional: Refresh minimap tooltip if hovering
    if GameTooltip:IsOwned(LMAHI_MinimapButton) then
        GameTooltip:Hide()
        GameTooltip:SetOwner(LMAHI_MinimapButton, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r")
        GameTooltip:AddLine("|cff00ff00Left click|r to activate")
        GameTooltip:AddLine("|cffFF9933Right click|r to drag")
        GameTooltip:Show()
    end
end

--  Force sleep mode on login every time
C_Timer.After(1, function()
    if LMAHI_Disable then
        LMAHI_Disable()
    end
end)
