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
    selectionFramePos = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 },
    zoomLevel = 1,
    classColors = {},
    factions = {},
    collapsedSections = {},
    customLockouts = {},
    lastWeeklyReset = 0,
    lastDailyReset = 0,
    frameHeight = 402, -- Default height
    selectionFrameCollapsed = {},
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

-- SavedVariables setup
LMAHI_SavedData = LMAHI_SavedData or {}
LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(45) }

-- Always start in sleep mode
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

-- Toggle sleep mode
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
mainFrame:SetSize(1225, LMAHI_SavedData.frameHeight or 402)
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
    if LMAHI_Disable then
        LMAHI_Disable()
    end
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
    level = math.min(1.2, math.max(0.9, level))
    LMAHI_SavedData.zoomLevel = math.floor(level * 100 + 0.5) / 100
    mainFrame:SetScale(LMAHI_SavedData.zoomLevel)
    settingsFrame:SetScale(LMAHI_SavedData.zoomLevel)
    customInputFrame:SetScale(LMAHI_SavedData.zoomLevel)
    if LMAHI.lockoutSelectionFrame then
        LMAHI.lockoutSelectionFrame:SetScale(LMAHI_SavedData.zoomLevel)
    end
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
GameTooltip:SetOwner(self, "ANCHOR_NONE")
GameTooltip:SetPoint("LEFT", self, "RIGHT", 2, 0)
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
GameTooltip:SetOwner(self, "ANCHOR_NONE")
GameTooltip:SetPoint("LEFT", self, "RIGHT", 2, 0)
    GameTooltip:SetText("Zoom Out")
    GameTooltip:Show()
end)
zoomOutButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Custom lockout input button
local customInputButton = CreateFrame("Button", nil, mainFrame)
customInputButton:SetSize(27, 32)
customInputButton:SetPoint("TOPLEFT", zoomInButton, "TOPRIGHT", 45, -35)

customInputButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
customInputButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
customInputButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

local goldOverlay = customInputButton:CreateTexture(nil, "ARTWORK", nil, 1)
goldOverlay:SetColorTexture(0.6, 0.8, 1, 0.15)
goldOverlay:SetAllPoints(customInputButton:GetNormalTexture())

local borderFrame = CreateFrame("Frame", nil, customInputButton, "BackdropTemplate")
borderFrame:SetPoint("TOPLEFT", customInputButton, "TOPLEFT", -3, 3)
borderFrame:SetPoint("BOTTOMRIGHT", customInputButton, "BOTTOMRIGHT", 3, -3)
borderFrame:SetFrameLevel(customInputButton:GetFrameLevel() + 2)
borderFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
borderFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

customInputButton:SetScript("OnClick", function()
    customInputFrame:SetShown(not customInputFrame:IsShown())
    if customInputFrame:IsShown() and LMAHI.UpdateCustomInputDisplay then
        LMAHI.UpdateCustomInputDisplay()
    end
end)

customInputButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("|cff99ccffCustom|r |cffADADADLockout|r |cff99ccffInput|r")
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
settingsOverlay:SetColorTexture(0.6, 0.8, 1, 0.15)
settingsOverlay:SetAllPoints(settingsButton:GetNormalTexture())

local borderFrame = CreateFrame("Frame", nil, settingsButton, "BackdropTemplate")
borderFrame:SetPoint("TOPLEFT", settingsButton, "TOPLEFT", -3, 3)
borderFrame:SetPoint("BOTTOMRIGHT", settingsButton, "BOTTOMRIGHT", 3, -3)
borderFrame:SetFrameLevel(settingsButton:GetFrameLevel() + 2)
borderFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
borderFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) 


settingsButton:SetScript("OnClick", function()
    settingsFrame:SetShown(not settingsFrame:IsVisible())
    if settingsFrame:IsVisible() and LMAHI.UpdateSettingsDisplay then
        LMAHI.UpdateSettingsDisplay()
    end
end)



settingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("|cff99ccffCharacter|r |cffADADADOrder|r |cff99ccffSettings|r")
    GameTooltip:Show()
end)
settingsButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Lockout selection button
local selectionButton = CreateFrame("Button", nil, mainFrame)
selectionButton:SetSize(27, 32)
selectionButton:SetPoint("TOPLEFT", settingsButton, "TOPRIGHT", -108, 0)

selectionButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
selectionButton:SetPushedTexture("Interface\\Buttons\\UI-OptionsButton")
selectionButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

local selectionOverlay = selectionButton:CreateTexture(nil, "ARTWORK", nil, 1)
selectionOverlay:SetColorTexture(0.6, 0.8, 1, 0.15)
selectionOverlay:SetAllPoints(selectionButton:GetNormalTexture())

local borderFrame = CreateFrame("Frame", nil, selectionButton, "BackdropTemplate")
borderFrame:SetPoint("TOPLEFT", selectionButton, "TOPLEFT", -3, 3)
borderFrame:SetPoint("BOTTOMRIGHT", selectionButton, "BOTTOMRIGHT", 3, -3)
borderFrame:SetFrameLevel(selectionButton:GetFrameLevel() + 2)
borderFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
borderFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

selectionButton:SetScript("OnClick", function()
    if _G.LMAHI_Sleeping then
        print("LMAHI: Addon is in sleep mode. Click the minimap button or use /lmahi to activate.")
        return
    end
    if not LMAHI.lockoutSelectionFrame then
        LMAHI.lockoutSelectionFrame = LMAHI.CreateLockoutSelectionFrame()
    end
    LMAHI.lockoutSelectionFrame:SetShown(not LMAHI.lockoutSelectionFrame:IsShown())
end)

selectionButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("|cff99ccffLockout|r |cffADADADSelection|r |cff99ccffSettings|r")
    GameTooltip:Show()
end)

selectionButton:SetScript("OnLeave", function() GameTooltip:Hide() end)




-- Paging arrows
local leftArrow = CreateFrame("Button", nil, mainFrame)
leftArrow:SetSize(35, 50)
leftArrow:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 178, -23)
leftArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
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
charFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 210, -28)
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
    local scrollAmount = 50
    self:SetVerticalScroll(math.max(0, math.min(current - delta * scrollAmount, maxScroll)))
end)

lockoutContent = CreateFrame("Frame", "LMAHI_LockoutContent", lockoutScrollFrame)
lockoutScrollFrame:SetScrollChild(lockoutContent)
lockoutContent:SetWidth(1192)
lockoutContent:SetHeight(314)
lockoutContent:SetFrameLevel(mainFrame:GetFrameLevel() + 2)
lockoutContent:Show()

-- Custom left scrollbar
local leftScrollTrack = CreateFrame("Frame", "LMAHI_LockoutContent", lockoutScrollFrame)
leftScrollTrack:SetWidth(15)
leftScrollTrack:SetPoint("TOPLEFT", lockoutScrollFrame, "TOPLEFT", -5, -40)
leftScrollTrack:SetPoint("BOTTOMLEFT", lockoutScrollFrame, "BOTTOMLEFT", -5, 40)
leftScrollTrack:SetFrameLevel(lockoutScrollFrame:GetFrameLevel() + 2)

-- Background
leftScrollTrack.texture = leftScrollTrack:CreateTexture("LMAHI_LockoutContent", "BACKGROUND")
leftScrollTrack.texture:SetAllPoints()
leftScrollTrack.texture:SetColorTexture(0.1, 0.1, 0.1, 0.1)

-- Scroll Up button
local scrollUpButton = CreateFrame("Button", nil, leftScrollTrack, "UIPanelScrollUpButtonTemplate")
scrollUpButton:SetPoint("TOPLEFT", leftScrollTrack, "TOPLEFT", 0, 42)
scrollUpButton:SetFrameLevel(leftScrollTrack:GetFrameLevel() + 1)
scrollUpButton:EnableMouse(true)
scrollUpButton:SetScript("OnClick", function()
    local current = lockoutScrollFrame:GetVerticalScroll()
    lockoutScrollFrame:SetVerticalScroll(math.max(0, current - 145))
end)

-- Scroll Down button
local scrollDownButton = CreateFrame("Button", nil, leftScrollTrack, "UIPanelScrollDownButtonTemplate")
scrollDownButton:SetPoint("BOTTOMLEFT", leftScrollTrack, "BOTTOMLEFT", 0, -40)
scrollDownButton:SetFrameLevel(leftScrollTrack:GetFrameLevel() + 1)
scrollDownButton:EnableMouse(true)
scrollDownButton:SetScript("OnClick", function()
    local current = lockoutScrollFrame:GetVerticalScroll()
    local maxScroll = lockoutScrollFrame:GetVerticalScrollRange()
    lockoutScrollFrame:SetVerticalScroll(math.min(maxScroll, current + 145))
end)

-- Scroll thumb (fixed-size Blizzard-style textured knob)
local leftThumb = CreateFrame("Frame", nil, leftScrollTrack)
leftThumb:SetWidth(31)
leftThumb:SetHeight(33) -- Fixed height
leftThumb:SetPoint("TOPLEFT", leftScrollTrack, "TOPLEFT", -7, 30)
leftThumb:SetFrameLevel(leftScrollTrack:GetFrameLevel() + 1)

leftThumb.texture = leftThumb:CreateTexture(nil, "OVERLAY")
leftThumb.texture:SetAllPoints()
leftThumb.texture:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
leftThumb.texture:SetTexCoord(0, 1, 0, 1)

-- Update thumb position + button states
local function UpdateLeftThumb(offset)
    local maxScroll = lockoutScrollFrame:GetVerticalScrollRange()
    local topY = scrollUpButton:GetTop()
    local bottomY = scrollDownButton:GetBottom()
    local thumbHeight = leftThumb:GetHeight()

    -- Movement range for thumb (fixed track)
    local trackHeight = topY - bottomY - 24
    local thumbY = (trackHeight - thumbHeight) * (offset / math.max(1, maxScroll))
    leftThumb:SetPoint("TOPLEFT", leftScrollTrack, "TOPLEFT", -7, -thumbY + 30)

    -- Enable/disable scroll buttons
    scrollUpButton:SetEnabled(offset > 0)
    scrollDownButton:SetEnabled(offset < maxScroll)
end

-- Scroll tracking
lockoutScrollFrame:HookScript("OnVerticalScroll", function(_, offset)
    UpdateLeftThumb(offset)
end)

-- Drag-to-scroll logic
leftThumb:EnableMouse(true)
leftThumb:RegisterForDrag("LeftButton")

leftThumb:SetScript("OnDragStart", function(self)
    self.startY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
    self.startScroll = lockoutScrollFrame:GetVerticalScroll()
end)

leftThumb:SetScript("OnDragStop", function(self)
    self.startY = nil
end)

leftThumb:SetScript("OnUpdate", function(self)
    if self.startY and IsMouseButtonDown("LeftButton") then
        local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local delta = self.startY - currentY
        local maxScroll = lockoutScrollFrame:GetVerticalScrollRange()
        local scrollSpeed = 1
        local trackHeight = scrollUpButton:GetTop() - scrollDownButton:GetBottom() - 24
        local newOffset = math.max(0, math.min(self.startScroll + (delta / trackHeight) * maxScroll, maxScroll))

        lockoutScrollFrame:SetVerticalScroll(newOffset)
        UpdateLeftThumb(newOffset)

        -- Snap anchor when reaching edges
        if newOffset >= maxScroll then
            self.startY = currentY
            self.startScroll = maxScroll
        elseif newOffset <= 0 then
            self.startY = currentY
            self.startScroll = 0
        end
    end
end)


-- Drag function for bottom of mainframe
local resizeArrow = CreateFrame("Frame", "LMAHI_ResizeArrow", mainFrame)
resizeArrow:SetSize(20, 40)
resizeArrow:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMRIGHT", -70, -22)
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
nameInput:SetMaxLetters(24)
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
idInput:SetMaxLetters(6)
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

local resetDropdown = CreateFrame("Frame", "LMAHI_ResetDropdown", customInputContent, "UIDropDownMenuTemplate")
resetDropdown:SetPoint("TOPLEFT", resetLabel, "TOPRIGHT", -110, -15)
UIDropDownMenu_SetWidth(resetDropdown, 100)

local resetOptions = {
    { text = "Weekly", value = "weekly" },
    { text = "Daily", value = "daily" },
    { text = "None", value = "none" },
}
local selectedResetValue = "weekly"
UIDropDownMenu_Initialize(resetDropdown, function(self, level)
    for i, option in ipairs(resetOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.checked = (option.value == selectedResetValue)
        info.func = function()
            selectedResetValue = option.value
            UIDropDownMenu_SetSelectedValue(resetDropdown, option.value)
            _G[resetDropdown:GetName() .. "Text"]:SetText(option.text)
        end
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetSelectedValue(resetDropdown, "weekly")
UIDropDownMenu_SetText(resetDropdown, "Weekly")

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

    for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
        if lockout.id == id then
            print("LMAHI: This Custom ID is already in use.")
            return
        end
    end

    table.insert(LMAHI.lockoutData.custom, { id = id, name = name, reset = reset })
    LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
    LMAHI_SavedData.customLockoutOrder[tostring(id)] = #LMAHI.lockoutData.custom

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

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("RIGHT", button, "RIGHT", -10, 0)
        label:SetText(string.format("|cffffcc00%s|r   |cff99ccffID:|r |cff99ccff%d|r |cffffffff%s|r",
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
text = string.format(
    "Do you want to remove\n|cffffcc00%s|r   |cff99ccffID:|r |cff99ccff%d|r |cffffffff%s|r\nfrom the list?",
    lockout.name, lockout.id, lockout.reset),


        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            for i, l in ipairs(LMAHI.lockoutData.custom) do
                if l.id == self.lockoutId then
                    table.remove(LMAHI.lockoutData.custom, i)
                    LMAHI_SavedData.customLockouts = LMAHI.lockoutData.custom
                    LMAHI_SavedData.customLockoutOrder[tostring(self.lockoutId)] = nil

                    -- Rebuild and sort the custom lockout list
                    local newCustomList = {}
                    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
                        table.insert(newCustomList, lockout)
                    end
                    table.sort(newCustomList, function(a, b)
                        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
                        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1000
                        return aIndex < bIndex or (aIndex == bIndex and a.id < b.id)
                    end)

                    -- Save new order
                    local newCustomLockoutOrder = {}
                    for i, lockout in ipairs(newCustomList) do
                        newCustomLockoutOrder[tostring(lockout.id)] = i
                    end
                    LMAHI_SavedData.customLockoutOrder = newCustomLockoutOrder

                    -- Update displays and save
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
        preferredIndex = 3
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


--   CreateLockoutSelectionFrame 

function LMAHI.CreateLockoutSelectionFrame()
    local frame = CreateFrame("Frame", "LMAHILockoutSelectionFrame", UIParent, "BasicFrameTemplateWithInset")
    tinsert(UISpecialFrames, "LMAHILockoutSelectionFrame")
    frame:SetSize(400, 600)
    frame:SetPoint(LMAHI_SavedData.selectionFramePos.point, UIParent, LMAHI_SavedData.selectionFramePos.relativePoint, LMAHI_SavedData.selectionFramePos.x, LMAHI_SavedData.selectionFramePos.y)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(300)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        LMAHI_SavedData.selectionFramePos = { point = point, relativeTo = "UIParent", relativePoint = relativePoint, x = x, y = y }
    end)
    frame:SetScale(LMAHI_SavedData.zoomLevel or 1)
    frame:Hide()

    -- CloseButton appearance
    frame.CloseButton:SetSize(24, 24)
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.CloseButton:SetNormalTexture("Interface\\Buttons\\UIPanelCloseButton")
    frame.CloseButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    frame.CloseButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -3)
    title:SetText("|cff99ccffLockout|r |cffADADADSelection|r |cff99ccffSettings|r")

-- Lockout selection panel container
local lockoutSelectionContent = CreateFrame("Frame", "LMAHILockoutSelectionContent", LMAHILockoutSelectionFrame, "BackdropTemplate")
lockoutSelectionContent:SetSize(345, 160) -- Slightly taller to make room for caption
lockoutSelectionContent:SetPoint("TOPLEFT", LMAHILockoutSelectionFrame, "TOPLEFT", 28, -25)
lockoutSelectionContent:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 14,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
lockoutSelectionContent:SetBackdropColor(0.1, 0.1, 0.1, 1)
lockoutSelectionContent:SetFrameLevel(LMAHILockoutSelectionFrame:GetFrameLevel() + 1)
lockoutSelectionContent:Show()

-- Section container for checkboxes
local topSection = CreateFrame("Frame", nil, lockoutSelectionContent)
topSection:SetPoint("TOPLEFT", lockoutSelectionContent, "TOPLEFT", 5, -1)
topSection:SetSize(330, 60) -- Two rows layout

-- Checkbox definitions
local sectionCheckboxes = lockoutSelectionContent.sectionCheckboxes or {}
local lockoutTypesDisplay = { "custom", "raids", "dungeons", "quests", "rares", "currencies" }

LMAHI_SavedData.sectionVisibility = LMAHI_SavedData.sectionVisibility or {}

for i, lockoutType in ipairs(lockoutTypesDisplay) do
    local sectionKey = lockoutType
    local checkbox = sectionCheckboxes[sectionKey] or CreateFrame("CheckButton", nil, topSection, "UICheckButtonTemplate")

    local row = math.floor((i - 1) / 3)
    local col = (i - 1) % 3
    checkbox:SetPoint("TOPLEFT", topSection, "TOPLEFT", col * 100 + 10, -row * 25 - 5)
    checkbox:SetSize(25, 25)
    checkbox:SetChecked(LMAHI_SavedData.sectionVisibility[sectionKey] ~= false)

    if not sectionCheckboxes[sectionKey] then
        sectionCheckboxes[sectionKey] = checkbox
        checkbox:SetScript("OnClick", function(self)
            LMAHI_SavedData.sectionVisibility[sectionKey] = self:GetChecked()
            if LMAHI.UpdateDisplay then
                LMAHI.UpdateDisplay()
            end
        end)
    end

    checkbox:Show()

    local label = topSection:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(lockoutType:gsub("^%l", string.upper))
    label:SetWidth(150)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 1, 1)
    checkbox.label = label
    label:Show()
end

-- Instructional label beneath checkboxes
-- Multi-line instructional caption beneath checkboxes
local lines = {
    "Show or Hide the sections on the Main Page",
    "by checking or unchecking the boxes above.",
    "-----------------------------------------------",
    "Using the collapsable sections below,",
    "Show or Hide any lockout on the Main Page,",
	"by checking or unchecking a box.",
}

local caption = lockoutSelectionContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
caption:SetPoint("TOP", topSection, "BOTTOM", 0, 2)
caption:SetWidth(320)
caption:SetText(table.concat(lines, "\n"))
caption:SetJustifyH("CENTER")
caption:SetTextColor(0.9, 0.9, 0.9, 0.9)
caption:SetSpacing(3)
caption:Show()


-- Store reference for reuse
lockoutSelectionContent.sectionCheckboxes = sectionCheckboxes



    -- Scroll frame starts below top section
    local scrollFrame = CreateFrame("ScrollFrame", "LMAHI_SelectionScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", topSection, "BOTTOMLEFT", 0, -100)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local scrollAmount = 32
        self:SetVerticalScroll(math.max(0, math.min(current - delta * scrollAmount, maxScroll)))
    end)

    local content = CreateFrame("Frame", "LMAHI_SelectionContent", scrollFrame)
    scrollFrame:SetScrollChild(content)
    content:SetSize(310, 1)
    content:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)

    LMAHI_SavedData.selectionFrameCollapsed = LMAHI_SavedData.selectionFrameCollapsed or {}
    LMAHI_SavedData.selectionFramePos = LMAHI_SavedData.selectionFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
    LMAHI_SavedData.lockoutVisibility = LMAHI_SavedData.lockoutVisibility or {}
    LMAHI_SavedData.sectionVisibility = LMAHI_SavedData.sectionVisibility or {
        custom = true,
        raids = true,
        dungeons = true,
        quests = true,
        rares = true,
        currencies = true
    }

    local function UpdateContentLayout()
        local yOffset = -10
        local checkboxes = frame.checkboxes or {}
        local collapseButtons = frame.collapseButtons or {}
        local nameLabels = frame.nameLabels or {}

        -- Clear existing positions and hide all
        for _, checkbox in pairs(checkboxes) do
            checkbox:ClearAllPoints()
            checkbox:Hide()
        end
        for _, btn in pairs(collapseButtons) do
            btn:ClearAllPoints()
            btn:Hide()
        end
        for _, label in pairs(nameLabels) do
            label:ClearAllPoints()
            label:Hide()
        end

        -- Handle Custom section with collapse button and lockouts
        local customKey = "custom"
        local customButton = collapseButtons[customKey] or CreateFrame("Button", nil, content)
        customButton:SetSize(20, 20)
        customButton:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
        customButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        customButton:GetNormalTexture():SetSize(20, 20)
        customButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
        customButton:GetPushedTexture():SetSize(20, 20)
        customButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        customButton:GetHighlightTexture():SetSize(20, 20)
        local isCustomCollapsed = LMAHI_SavedData.selectionFrameCollapsed[customKey]
        customButton:SetNormalTexture(isCustomCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        customButton:GetNormalTexture():SetSize(20, 20)
        if not collapseButtons[customKey] then
            collapseButtons[customKey] = customButton
        end
        customButton:Show()

        local customLabel = nameLabels[customKey] or content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
        customLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 35, yOffset -2)
        customLabel:SetText("Custom")
        customLabel:SetWidth(300)
        customLabel:SetJustifyH("LEFT")
        customLabel:SetTextColor(1, 1, 1) -- White
        if not nameLabels[customKey] then
            nameLabels[customKey] = customLabel
        end
        customLabel:Show()
        yOffset = yOffset - 25

        customButton:SetScript("OnClick", function(self)
            LMAHI_SavedData.selectionFrameCollapsed[customKey] = not LMAHI_SavedData.selectionFrameCollapsed[customKey]
            self:SetNormalTexture(LMAHI_SavedData.selectionFrameCollapsed[customKey] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            self:GetNormalTexture():SetSize(20, 20)
            UpdateContentLayout()
            if LMAHI.UpdateDisplay then
                LMAHI.UpdateDisplay()
            end
        end)

        if not isCustomCollapsed then
            local customLockouts = LMAHI_SavedData.customLockouts or {}
            for _, lockout in ipairs(customLockouts) do
                local lockoutKey = "Custom_" .. lockout.id
                local checkbox = checkboxes[lockoutKey] or CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", 25, yOffset)
			    checkbox:SetSize(25, 25)
                checkbox.Text:SetText(lockout.name)
				checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
				checkbox.Text:SetFontObject("GameFontNormal")
                checkbox.Text:SetWidth(300)
                checkbox.Text:SetJustifyH("LEFT")
                checkbox.Text:SetTextColor(0.9, 0.7, 0.1) -- Gold
                checkbox:SetChecked(LMAHI_SavedData.lockoutVisibility[lockoutKey] and true or false)
                checkbox.lockoutType = "custom"
                checkbox.lockoutId = lockout.id
                if not checkboxes[lockoutKey] then
                    checkboxes[lockoutKey] = checkbox
                    checkbox:SetScript("OnClick", function(self)
                        LMAHI_SavedData.lockoutVisibility[lockoutKey] = self:GetChecked()
                        if LMAHI.UpdateDisplay then
                            LMAHI.UpdateDisplay()
                        end
                    end)
                end
                checkbox:Show()
                yOffset = yOffset - 25
            end
            yOffset = yOffset - 10 -- Consistent 10px gap after Custom section
        else
            yOffset = yOffset - 10 -- Consistent 10px gap when collapsed
        end

        -- Handle expansions (The War Within, Dragonflight)
        local expansions = {
            { name = "The War Within", id = "TWW" },
            { name = "Dragonflight", id = "Dragonflight" },
        }

        for _, expansion in ipairs(expansions) do
            local expButton = collapseButtons[expansion.id] or CreateFrame("Button", nil, content)
            expButton:SetSize(20, 20)
            expButton:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
            expButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
            expButton:GetNormalTexture():SetSize(20, 20)
            expButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
            expButton:GetPushedTexture():SetSize(20, 20)
            expButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            expButton:GetHighlightTexture():SetSize(20, 20)
            local isCollapsed = LMAHI_SavedData.selectionFrameCollapsed[expansion.id]
            expButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            expButton:GetNormalTexture():SetSize(20, 20)
            expButton.expansion = expansion.id
            if not collapseButtons[expansion.id] then
                collapseButtons[expansion.id] = expButton
            end
            expButton:Show()

            local expLabel = nameLabels[expansion.id] or content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
            expLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 35, yOffset -2)
            expLabel:SetText(expansion.name)
            expLabel:SetWidth(300)
            expLabel:SetJustifyH("LEFT")
            expLabel:SetTextColor(0.6, 0.8, 1) --  Light blue
            if not nameLabels[expansion.id] then
                nameLabels[expansion.id] = expLabel
            end
            expLabel:Show()
            yOffset = yOffset - 25

            expButton:SetScript("OnClick", function(self)
                LMAHI_SavedData.selectionFrameCollapsed[expansion.id] = not LMAHI_SavedData.selectionFrameCollapsed[expansion.id]
                self:SetNormalTexture(LMAHI_SavedData.selectionFrameCollapsed[expansion.id] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                self:GetNormalTexture():SetSize(20, 20)
                UpdateContentLayout()
                if LMAHI.UpdateDisplay then
                    LMAHI.UpdateDisplay()
                end
            end)

            if not isCollapsed then
                for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                    if lockoutType ~= "custom" then
                        local lockouts = LMAHI.lockoutData[lockoutType] or {}
                        if #lockouts > 0 then
                            local typeKey = expansion.id .. "_" .. lockoutType
                            local typeButton = collapseButtons[typeKey] or CreateFrame("Button", nil, content)
                            typeButton:SetSize(20, 20)
                            typeButton:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yOffset)
                            typeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                            typeButton:GetNormalTexture():SetSize(20, 20)
                            typeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
                            typeButton:GetPushedTexture():SetSize(20, 20)
                            typeButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
                            typeButton:GetHighlightTexture():SetSize(20, 20)
                            local typeCollapsed = LMAHI_SavedData.selectionFrameCollapsed[typeKey]
                            typeButton:SetNormalTexture(typeCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                            typeButton:GetNormalTexture():SetSize(20, 20)
                            typeButton.expansion = expansion.id
                            typeButton.lockoutType = lockoutType
                            if not collapseButtons[typeKey] then
                                collapseButtons[typeKey] = typeButton
                            end
                            typeButton:Show()

                            local typeLabel = nameLabels[typeKey] or content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
                            typeLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 45, yOffset -2)
                            typeLabel:SetText(lockoutType:gsub("^%l", string.upper))
                            typeLabel:SetWidth(110)
                            typeLabel:SetJustifyH("LEFT")
                            typeLabel:SetTextColor(1, 1, 1) -- White
                            if not nameLabels[typeKey] then
                                nameLabels[typeKey] = typeLabel
                            end
                            typeLabel:Show()
                            yOffset = yOffset - 25

                            typeButton:SetScript("OnClick", function(self)
                                LMAHI_SavedData.selectionFrameCollapsed[typeKey] = not LMAHI_SavedData.selectionFrameCollapsed[typeKey]
                                self:SetNormalTexture(LMAHI_SavedData.selectionFrameCollapsed[typeKey] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                                self:GetNormalTexture():SetSize(20, 20)
                                UpdateContentLayout()
                                if LMAHI.UpdateDisplay then
                                    LMAHI.UpdateDisplay()
                                end
                            end)

                            if not typeCollapsed then
                                for _, lockout in ipairs(lockouts) do
                                    if expansion.id == "TWW" then
                                        local lockoutKey = "TWW_" .. lockoutType .. "_" .. lockout.id
                                        local checkbox = checkboxes[lockoutKey] or CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                                        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", 25, yOffset)
									    checkbox:SetSize(25, 25)
                                        checkbox.Text:SetText(lockout.name)
										checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
										checkbox.Text:SetFontObject("GameFontNormal")
                                        checkbox.Text:SetWidth(300)
                                        checkbox.Text:SetJustifyH("LEFT")
                                        checkbox.Text:SetTextColor(0.9, 0.7, 0.1) -- Gold
                                        checkbox:SetChecked(LMAHI_SavedData.lockoutVisibility[lockoutKey] and true or false)
                                        checkbox.expansion = expansion.id
                                        checkbox.lockoutType = lockoutType
                                        checkbox.lockoutId = lockout.id
                                        if not checkboxes[lockoutKey] then
                                            checkboxes[lockoutKey] = checkbox
                                            checkbox:SetScript("OnClick", function(self)
                                                LMAHI_SavedData.lockoutVisibility[lockoutKey] = self:GetChecked()
                                                if LMAHI.UpdateDisplay then
                                                    LMAHI.UpdateDisplay()
                                                end
                                            end)
                                        end
                                        checkbox:Show()
                                        yOffset = yOffset - 25
                                    end
                                end
                            end
                            yOffset = yOffset - 10 -- Consistent 10px gap after sub-section
                        end
                    end
                end
            end
            yOffset = yOffset - 10 -- Consistent 10px gap after expansion
        end

        content:SetHeight(-yOffset + 20)
        frame.checkboxes = checkboxes
        frame.collapseButtons = collapseButtons
        frame.nameLabels = nameLabels
    end

    UpdateContentLayout()
    return frame
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
mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(45) }
        LMAHI_SavedData.framePos = LMAHI_SavedData.framePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.settingsFramePos = LMAHI_SavedData.settingsFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.customInputFramePos = LMAHI_SavedData.customInputFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
        LMAHI_SavedData.selectionFramePos = LMAHI_SavedData.selectionFramePos or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
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
        LMAHI_SavedData.selectionFrameCollapsed = LMAHI_SavedData.selectionFrameCollapsed or {}
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
        Utilities.StartGarbageCollector()
    elseif event == "PLAYER_LOGOUT" then
        if LMAHI.SaveCharacterData then
            LMAHI.SaveCharacterData()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_END" or event == "QUEST_TURNED_IN" or event == "LFG_LOCK_INFO_RECEIVED" or event == "UPDATE_INSTANCE_INFO" then
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
]]

-- Main frame hookup
LMAHI.mainFrame = mainFrame

-- Sleep state tracking
function LMAHI_Enable()
    if LMAHI.mainFrame then
        LMAHI.mainFrame:Show()
    end
    _G.LMAHI_Sleeping = false
    print("LMAHI activated")
    LMAHI:ResetCaches()
    if LMAHI.SaveCharacterData then
        LMAHI.SaveCharacterData()
    end
    if LMAHI.CheckLockouts then
        LMAHI.CheckLockouts()
    end
    LMAHI.UpdateDisplay()
end

function LMAHI_Disable()
    if LMAHI.mainFrame then
        LMAHI.mainFrame:Hide()
    end
    if LMAHI.lockoutSelectionFrame then
        LMAHI.lockoutSelectionFrame:Hide()
    end
    _G.LMAHI_Sleeping = true
    print("LMAHI sleep mode enabled")
    if GameTooltip:IsOwned(LMAHI_MinimapButton) then
        GameTooltip:Hide()
        GameTooltip:SetOwner(LMAHI_MinimapButton, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r")
        GameTooltip:AddLine("|cff00ff00Left click|r to activate")
        GameTooltip:AddLine("|cffFF9933Right click|r to drag")
        GameTooltip:Show()
    end
end

-- Force sleep mode on login every time
C_Timer.After(1, function()
    if LMAHI_Disable then
        LMAHI_Disable()
    end
end)

-- Slash command for selection frame
SLASH_LMAHISELECT1 = "/lmahiselect"
SlashCmdList["LMAHISELECT"] = function()
    if _G.LMAHI_Sleeping then
        print("LMAHI: Addon is in sleep mode. Click the minimap button or use /lmahi to activate.")
        return
    end
    if not LMAHI.lockoutSelectionFrame then
        LMAHI.lockoutSelectionFrame = CreateLockoutSelectionFrame()
    end
    LMAHI.lockoutSelectionFrame:SetShown(not LMAHI.lockoutSelectionFrame:IsShown())
end
