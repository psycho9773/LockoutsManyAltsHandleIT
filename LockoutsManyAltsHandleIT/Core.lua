-- Core.lua
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
}

-- Initialize lockoutData
LMAHI.lockoutData = LMAHI.lockoutData or {}
LMAHI.FACTION_COLORS = {
    Horde = { r = 1, g = 0, b = 0 },
    Alliance = { r = 0, g = 0, b = 1 },
    Neutral = { r = 0.8, g = 0.8, b = 0.8 },
}

-- Frame variables
local mainFrame, charFrame, lockoutScrollFrame, lockoutContent, settingsFrame, customInputFrame
local highlightFrame
local charListScrollFrame, charListContent, customInputScrollFrame, customInputScrollContent
local sectionHeaders = {}
local lockoutLabels = {}
local collapseButtons = {}

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

-- Create main frame
mainFrame = CreateFrame("Frame", "LMAHI_Frame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_Frame")
mainFrame:SetSize(1208, 402)
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
mainFrame:Hide()
mainFrame:SetScale(LMAHI_SavedData.zoomLevel or 1)
mainFrame.CloseButton:SetFrameLevel(149) -- Ensure below settingsFrame
mainFrame.CloseButton:SetScript("OnClick", function()
    mainFrame:Hide()
    settingsFrame:Hide()
    customInputFrame:Hide()
end)

local titleLabel = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
titleLabel:SetPoint("TOP", mainFrame, "TOP", 0, -3)
titleLabel:SetText("|cffADADAD---[ |r |cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r |cffADADAD ]---|r")
titleLabel:SetTextColor(0.6, 0.8, 0.9)

local authorLabel = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
authorLabel:SetPoint("LEFT", titleLabel, "RIGHT", 10, 0)
authorLabel:SetText("|cffADADADBy: Psycho|r")
authorLabel:SetTextColor(173/255, 173/255, 173/255)

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
zoomInButton:SetSize(26, 26)
zoomInButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 27, 2)
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
zoomOutButton:SetSize(26, 26)
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
customInputButton:SetPoint("TOPLEFT", zoomInButton, "TOPRIGHT", 35, -35)
customInputButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
customInputButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
customInputButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
local goldOverlay = customInputButton:CreateTexture(nil, "ARTWORK", nil, 1)
goldOverlay:SetColorTexture(1, 0.85, 0, 0.2)
goldOverlay:SetAllPoints(customInputButton:GetNormalTexture())
customInputButton:SetScript("OnClick", function()
    customInputFrame:SetShown(not customInputFrame:IsShown())
    if customInputFrame:IsShown() then
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
settingsButton:SetPoint("TOPLEFT", customInputButton, "TOPRIGHT", 15, 0)
settingsButton:SetNormalTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
settingsButton:SetPushedTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
local settingsOverlay = settingsButton:CreateTexture(nil, "ARTWORK", nil, 1)
settingsOverlay:SetColorTexture(1, 0.85, 0, 0.2)
settingsOverlay:SetAllPoints(settingsButton:GetNormalTexture())
settingsButton:SetScript("OnClick", function()
    settingsFrame:SetShown(not settingsFrame:IsVisible())
    if settingsFrame:IsVisible() then
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
leftArrow:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 171, -23)
leftArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
leftArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
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
rightArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
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

-- Character Paged frame
charFrame = CreateFrame("Frame", "LMAHI_CharFrame", mainFrame, "BackdropTemplate")
charFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 204, -28)
charFrame:SetSize(969, 40)
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
lockoutContent:SetHeight(314)
lockoutContent:SetFrameLevel(mainFrame:GetFrameLevel() + 2)
lockoutContent:Show()

-- Highlight frame
highlightFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
highlightFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 3)
highlightFrame:EnableMouse(false)
highlightFrame:Hide()

-- Custom input frame
customInputFrame = CreateFrame("Frame", "LMAHI_CustomInputFrame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_CustomInputFrame")
customInputFrame:SetSize(500, 500)
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
customInputFrame.CloseButton:SetSize(24, 24) -- Explicitly set size
customInputFrame.CloseButton:SetPoint("TOPRIGHT", customInputFrame, "TOPRIGHT", 0, 0) -- Align top-right
customInputFrame.CloseButton:SetFrameLevel(155) -- Above customInputScrollContent (153)
customInputFrame.CloseButton:EnableMouse(true) -- Ensure clickable
customInputFrame.CloseButton:Enable() -- Ensure button is not disabled
customInputFrame.CloseButton:SetNormalTexture("Interface\\Buttons\\UIPanelCloseButton")
customInputFrame.CloseButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
customInputFrame.CloseButton:SetScript("OnClick", function()
    customInputFrame:Hide()
end)


local customInputTitle = customInputFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
customInputTitle:SetPoint("TOP", customInputFrame, "TOP", 0, -3)
customInputTitle:SetText("|cff99ccffCustom|r |cffADADADLockout|r |cff99ccffInput|r")
customInputTitle:SetTextColor(0.6, 0.8, 0.9)

local customInputContent = CreateFrame("Frame", nil, customInputFrame, "BackdropTemplate")
customInputContent:SetSize(460, 120)
customInputContent:SetPoint("TOPLEFT", customInputFrame, "TOPLEFT", 20, -30)
customInputContent:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
customInputContent:SetBackdropColor(0, 0, 0, 1)
customInputContent:SetFrameLevel(customInputFrame:GetFrameLevel() + 1)
customInputContent:Show()

local nameLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
nameLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 65, -10)
nameLabel:SetText("Name of Your Lockout")
nameLabel:Show()

local nameInput = CreateFrame("EditBox", nil, customInputContent, "InputBoxTemplate")
nameInput:SetSize(180, 20)
nameInput:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 45, -29)
nameInput:SetMaxLetters(30)
nameInput:SetAutoFocus(false)
nameInput:Show()

local idLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
idLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 253, -10)
idLabel:SetText("Custom Input")
idLabel:Show()

local idInput = CreateFrame("EditBox", nil, customInputContent, "InputBoxTemplate")
idInput:SetSize(100, 20)
idInput:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 240, -29)
idInput:SetNumeric(true)
idInput:SetMaxLetters(10)
idInput:SetAutoFocus(false)
idInput:Show()

local tipLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
tipLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 60, -60)
tipLabel:SetText("Type in the Custom Name and ID\nor Custom Lockout\n\nPress Ctrl+C to copy\nthen Ctrl+V to paste")
tipLabel:SetTextColor(0.9, 0.9, 0.9, 0.9)
tipLabel:Show()

local resetLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
resetLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 359, -10)
resetLabel:SetText("Reset Type")
resetLabel:Show()

local resetDropdown = CreateFrame("Frame", "LMAHI_ResetDropdown", customInputContent, "UIDropDownMenuTemplate")
resetDropdown:SetPoint("TOPLEFT", resetLabel, "TOPRIGHT", -98, -25)
UIDropDownMenu_SetWidth(resetDropdown, 100)
local resetOptions = {
    { text = "Weekly", value = "weekly" },
    { text = "Daily", value = "daily" },
    { text = "None", value = "none" },
}
UIDropDownMenu_Initialize(resetDropdown, function(self)
    for _, option in ipairs(resetOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.func = function(self)
            UIDropDownMenu_SetSelectedValue(resetDropdown, self.value)
            UIDropDownMenu_SetText(resetDropdown, self.text)
        end
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetSelectedValue(resetDropdown, "weekly")
UIDropDownMenu_SetText(resetDropdown, "Weekly")

local addButton = CreateFrame("Button", nil, customInputContent, "UIPanelButtonTemplate")
addButton:SetSize(300, 24)
addButton:SetPoint("TOPLEFT", resetLabel, "BOTTOM", -320, -120)
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

    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        if lockout.id == id then
            print("LMAHI: This Custom ID is already in use.")
            return
        end
    end

    table.insert(LMAHI.lockoutData.custom, { id = id, name = name, reset = reset })
    LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
    LMAHI_SavedData.customLockoutOrder[tostring(id)] = #LMAHI.lockoutData.custom

    for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
        lockouts[tostring(id)] = false
    end

    nameInput:SetText("")
    idInput:SetText("")
    UIDropDownMenu_SetSelectedValue(resetDropdown, "weekly")
    UIDropDownMenu_SetText(resetDropdown, "Weekly")

    LMAHI.NormalizeCustomLockoutOrder()
    LMAHI.UpdateCustomInputDisplay()
    ThrottledUpdateDisplay()
end)

customInputScrollFrame = CreateFrame("ScrollFrame", "LMAHI_CustomInputScrollFrame", customInputFrame, "UIPanelScrollFrameTemplate")
customInputScrollFrame:SetSize(450, 280)
customInputScrollFrame:SetPoint("BOTTOMLEFT", customInputFrame, "BOTTOMLEFT", 2, 0)
customInputScrollFrame:EnableMouseWheel(true)
customInputScrollFrame:SetFrameLevel(customInputFrame:GetFrameLevel() + 2)
customInputScrollFrame:Show()

customInputScrollContent = CreateFrame("Frame", nil, customInputScrollFrame)
customInputScrollFrame:SetScrollChild(customInputScrollContent)
customInputScrollContent:SetSize(440, 280)
customInputScrollContent:SetFrameLevel(customInputScrollFrame:GetFrameLevel() + 1)
customInputScrollContent:Show()

customInputScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 30
    self:SetVerticalScroll(math.max(0, math.min(currentScroll - delta * scrollAmount, maxScroll)))
end)

-- Settings frame
settingsFrame = CreateFrame("Frame", "LMAHI_SettingsFrame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, settingsFrame:GetName())
settingsFrame:SetSize(440, 441)
settingsFrame:SetPoint(LMAHI_SavedData.settingsFramePos.point, UIParent, LMAHI_SavedData.settingsFramePos.relativePoint, LMAHI_SavedData.settingsFramePos.x, LMAHI_SavedData.settingsFramePos.y)
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:SetFrameLevel(200)
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    LMAHI_SavedData.settingsFramePos = { point = point, relativeTo = "UIParent", relativePoint = relativePoint, x = x, y = y }
end)
settingsFrame:Hide()
settingsFrame:SetScale(LMAHI_SavedData.zoomLevel or 1)

local settingsTitle = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
settingsTitle:SetPoint("TOP", settingsFrame, "TOP", 0, -3)
settingsTitle:SetText("|cff99ccffCharacter|r |cffADADADOrder|r |cff99ccffSettings|r")
settingsTitle:SetTextColor(0.6, 0.8, 0.9)

charListScrollFrame = CreateFrame("ScrollFrame", "LMAHI_CharListScrollFrame", settingsFrame, "UIPanelScrollFrameTemplate")
charListScrollFrame:SetSize(380, 340)
charListScrollFrame:SetPoint("TOP", settingsFrame, "TOP", 0, -50)
charListScrollFrame:SetFrameLevel(settingsFrame:GetFrameLevel() + 2)
charListScrollFrame:Show()

charListContent = CreateFrame("Frame", nil, charListScrollFrame)
charListScrollFrame:SetScrollChild(charListContent)
charListContent:SetSize(360, 340)
charListContent:Show()

charListScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 30
    self:SetVerticalScroll(math.max(0, math.min(current - delta * scrollAmount, maxScroll)))
end)

-- Minimap button
local minimapButton = CreateFrame("Button", "LMAHI_MinimapButton", Minimap)
minimapButton:SetSize(28, 28)
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 5)
minimapButton:RegisterForDrag("RightButton")
minimapButton:SetClampedToScreen(true)

local radius = 105
local texture = minimapButton:CreateTexture(nil, "BACKGROUND")
texture:SetTexture("975738")
texture:SetAllPoints()
minimapButton.texture = texture

local maskTexture = minimapButton:CreateMaskTexture()
maskTexture:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
maskTexture:SetAllPoints()
texture:AddMaskTexture(maskTexture)

local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Common\\GoldRing")
border:SetSize(30, 30)
border:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)

local function UpdateButtonPosition()
    if not LMAHI_SavedData.minimapPos or not LMAHI_SavedData.minimapPos.angle then
        LMAHI_SavedData.minimapPos = { angle = math.rad(45) }
    end
    local angle = LMAHI_SavedData.minimapPos.angle
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

minimapButton:SetScript("OnDragStart", function(self)
    self.dragging = true
end)
minimapButton:SetScript("OnDragStop", function(self)
    self.dragging = false
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local x = (px / scale - mx)
    local y = (py / scale - my)
    local angle = math.atan2(y, x)
    LMAHI_SavedData.minimapPos.angle = angle
    UpdateButtonPosition()
end)
minimapButton:SetScript("OnUpdate", function(self)
    if self.dragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        minimapButton:SetPoint("CENTER", Minimap, "CENTER", px / scale - mx, py / scale - my)
    end
end)
minimapButton:SetScript("OnClick", function()
    mainFrame:SetShown(not mainFrame:IsShown())
    if mainFrame:IsShown() then
        LMAHI.SaveCharacterData()
        LMAHI.CheckLockouts()
        ThrottledUpdateDisplay()
    end
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r")
    GameTooltip:AddLine("|cff00ff00Left click|r |cffffffff to open|r")
    GameTooltip:AddLine("|cffFF9933Right click|r |cffffffff to drag|r")
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LMAHI.InitializeData()
        LMAHI_SavedData.customLockouts = LMAHI_SavedData.customLockouts or {}
        LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts
        UpdateButtonPosition()
        LMAHI.InitializeLockouts()
        LMAHI.SaveCharacterData()
        LMAHI.CheckLockouts()
        LMAHI.currentPage = 1
        mainFrame:SetScale(LMAHI_SavedData.zoomLevel)
        settingsFrame:SetScale(LMAHI_SavedData.zoomLevel)
        customInputFrame:SetScale(LMAHI_SavedData.zoomLevel)
        mainFrame:Hide()
    elseif event == "PLAYER_LOGIN" then
        UpdateButtonPosition()
        LMAHI.SaveCharacterData()
        LMAHI.CheckLockouts()
        mainFrame:Hide()
    end
end)

eventFrame:SetScript("OnUpdate", function(self, elapsed)
    lastResetCheckTime = lastResetCheckTime + elapsed
    if lastResetCheckTime >= resetCheckThrottle then
        LMAHI.CheckResetTimers()
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
mainFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(45) }
        LMAHI_SavedData.framePos = LMAHI_SavedData.framePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.settingsFramePos = LMAHI_SavedData.settingsFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.customInputFramePos = LMAHI_SavedData.customInputFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.zoomLevel = LMAHI_SavedData.zoomLevel or 1
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
        LMAHI.CheckLockouts()
        mainFrame:Hide()
    elseif event == "PLAYER_LOGOUT" then
        LMAHI.SaveCharacterData()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_END" or event == "QUEST_TURNED_IN" or event == "LFG_LOCK_INFO_RECEIVED" or event == "UPDATE_INSTANCE_INFO" or event == "CURRENCY_DISPLAY_UPDATE" then
        LMAHI.SaveCharacterData()
        LMAHI.CheckLockouts()
        if mainFrame:IsShown() then
            ThrottledUpdateDisplay()
        end
    end
end)

-- Slash commands
SLASH_LMAHI1 = "/lmahi"
SlashCmdList["LMAHI"] = function()
    mainFrame:SetShown(not mainFrame:IsShown())
    if mainFrame:IsShown() then
        LMAHI.SaveCharacterData()
        LMAHI.CheckLockouts()
        ThrottledUpdateDisplay()
    end
end

SLASH_LMAHIRESET1 = "/lmahireset"
SlashCmdList["LMAHIRESET"] = function()
    LMAHI.CleanLockouts()
    LMAHI.InitializeLockouts()
    LMAHI.SaveCharacterData()
    LMAHI.CheckResetTimers()
    print("LMAHI: Lockout data cleaned and reset for all characters.")
    ThrottledUpdateDisplay()
end

SLASH_LMAHIDEBUG1 = "/lmahidebug"
SlashCmdList["LMAHIDEBUG"] = function(msg)
    if msg == "resetquests" then
        for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
            for _, lockout in ipairs(LMAHI.lockoutData.quests or {}) do
                local lockoutId = tostring(lockout.id)
                lockouts[lockoutId] = false
            end
        end
        ThrottledUpdateDisplay()
        return
    end
end

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

-- Update custom input display
function LMAHI.UpdateCustomInputDisplay()
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
        table.insert(customList, lockout)
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

    local offsetY = -10
    for i, lockout in ipairs(customList) do
        local button = CreateFrame("Button", nil, LMAHI.customInputScrollContent)
        button:SetSize(315, 24)
        button:SetPoint("TOPLEFT", LMAHI.customInputScrollContent, "TOPLEFT", 20, offsetY - ((i-1) * 25))
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:GetNormalTexture():SetVertexColor(0.08, 0.08, 0.08, 1)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button:Show()
        table.insert(customLockoutLabels, button)

        local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("RIGHT", button, "RIGHT", -10, 0)
        label:SetText(string.format("%s ID %d, %s", lockout.name, lockout.id, lockout.reset))
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
                LMAHI.UpdateCustomInputDisplay()
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

        removeButton:SetScript("OnClick", function(self)
            StaticPopupDialogs["LMAHI_CONFIRM_REMOVE_LOCKOUT_" .. lockout.id] = {
                text = string.format("Do you want to remove\n%s ID: %d, %s\nfrom customization?", lockout.name, lockout.id, lockout.reset),
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    for i, l in ipairs(LMAHI.lockoutData.custom) do
                        if l.id == self.lockoutId then
                            table.remove(LMAHI.lockoutData.custom, i)
                            LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
                            LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] = nil
                            for charName, lockouts in pairs(LMAHI_SavedData.lockouts) do
                                lockouts[tostring(self.lockoutId)] = nil
                            end
                            LMAHI.NormalizeCustomLockoutOrder()
                            LMAHI.UpdateCustomInputDisplay()
                            ThrottledUpdateDisplay()
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
        end)

        removeButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove Custom Lockout")
            GameTooltip:Show()
        end)

        removeButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        table.insert(removeCustomButtons, removeButton)
        offsetY = offsetY - 25
    end
end

-- Update settings display
function LMAHI.UpdateSettingsDisplay()
    if not LMAHI.charListContent then
        return
    end

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
        local bIndex = LMAHI_SavedData.charOrder[b] or 1000
        if aIndex == bIndex then
            return a < b
        end
        return aIndex < bIndex
    end)

    local contentHeight = math.max(340, #charList * 30)
    LMAHI.charListContent:SetHeight(contentHeight)

    for i, charName in ipairs(charList) do
        local button = CreateFrame("Button", nil, LMAHI.charListContent)
        button:SetSize(300, 25)
        button:SetPoint("TOPLEFT", LMAHI.charListContent, "TOPLEFT", 10, -((i-1) * 30 + 10))
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:GetNormalTexture():SetVertexColor(0.1, 0.1, 0.1, 1)
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button:Show()
        table.insert(charButtons, button)

        local charDisplayName, realmName = strsplit("-", charName)
        local charLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        charLabel:SetPoint("LEFT", button, "LEFT", 5, 0)
        charLabel:SetText(charDisplayName or "Unknown")
        local classColor = LMAHI_SavedData.classColors[charName] or { r = 1, g = 1, b = 1 }
        charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        charLabel:Show()
        table.insert(charNameLabels, charLabel)

        local realmLabel = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        realmLabel:SetPoint("LEFT", charLabel, "RIGHT", 6, 0)
        realmLabel:SetText(realmName or "")
        local faction = LMAHI_SavedData.factions[charName] or "Neutral"
        local factionColor = LMAHI.FACTION_COLORS[faction] or { r = 0.8, g = 0.8, b = 0.8 }
        realmLabel:SetTextColor(factionColor.r, factionColor.g, factionColor.b)
        realmLabel:Show()
        table.insert(settingRealmLabels, realmLabel)

        local orderInput = CreateFrame("EditBox", nil, LMAHI.charListContent, "InputBoxTemplate")
        orderInput:SetSize(40, 20)
        orderInput:SetPoint("LEFT", button, "RIGHT", 10, 0)
        orderInput:SetNumeric(true)
        orderInput:SetMaxLetters(3)
        orderInput:SetText(tostring(LMAHI_SavedData.charOrder[charName] or i))
        orderInput:SetAutoFocus(false)
        orderInput.charName = charName
        orderInput:SetScript("OnEnterPressed", function(self)
            local newOrder = tonumber(self:GetText())
            if newOrder and newOrder >= 1 and newOrder <= #charList then
                local newCharOrder = {}
                local currentOrder = 1
                for _, otherChar in ipairs(charList) do
                    if otherChar == self.charName then
                        newCharOrder[self.charName] = newOrder
                    else
                        if currentOrder == newOrder then
                            currentOrder = currentOrder + 1
                        end
                        newCharOrder[otherChar] = currentOrder
                        currentOrder = currentOrder + 1
                    end
                end
                LMAHI_SavedData.charOrder = newCharOrder
                LMAHI.UpdateSettingsDisplay()
                ThrottledUpdateDisplay()
            end
            self:SetText(tostring(LMAHI_SavedData.charOrder[self.charName] or i))
            self:ClearFocus()
        end)
        orderInput:Show()
        table.insert(charOrderInputs, orderInput)

        local removeButton = CreateFrame("Button", nil, LMAHI.charListContent, "UIPanelButtonTemplate")
        removeButton:SetSize(60, 24)
        removeButton:SetPoint("LEFT", orderInput, "RIGHT", 5, 0)
        removeButton:SetText("Remove")
        removeButton.charName = charName
        removeButton:Show()

        removeButton:SetScript("OnClick", function(self)
            StaticPopupDialogs["LMAHI_CONFIRM_REMOVE_CHAR_" .. charName] = {
                text = string.format("Do you want to remove\n%s\n", charName),
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    LMAHI_SavedData.characters[charName] = nil
                    LMAHI_SavedData.lockouts[charName] = nil
                    LMAHI_SavedData.charOrder[charName] = nil
                    LMAHI_SavedData.classColors[charName] = nil
                    LMAHI_SavedData.factions[charName] = nil
                    LMAHI.UpdateSettingsDisplay()
                    LMAHI.SaveCharacterData()
                    ThrottledUpdateDisplay()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("LMAHI_CONFIRM_REMOVE_CHAR_" .. charName)
        end)

        removeButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove Character")
            GameTooltip:Show()
        end)

        removeButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        table.insert(removeButtons, removeButton)
    end
end
