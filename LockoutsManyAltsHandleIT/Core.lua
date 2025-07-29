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
    minimapPos = { angle = math.rad(145) },
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
    frameHeight = 402,
    selectionFrameCollapsed = {},
    lockoutVisibility = {},
    previousLockoutVisibility = {
        WLK = {}, DF = {}, LGN = {}, CAT = {}, WOD = {},
        WOW = {}, TBC = {}, SL = {}, BFA = {}, MOP = {}
    }
}

-- Initialize lockoutData
LMAHI.lockoutData = LMAHI.lockoutData or {}
LMAHI.FACTION_COLORS = {
    Horde    = { r = 0.95, g = 0.2, b = 0.2 },
    Alliance = { r = 0.2, g = 0.4, b = 1.0 },
    Neutral  = { r = 0.8, g = 0.8, b = 0.8 },
}

-- Frame variables
local mainFrame, charFrame, lockoutScrollFrame, lockoutContent, settingsFrame, customInputFrame
local highlightFrame
local charListScrollFrame, charListContent, customInputScrollFrame, customInputScrollContent
local sectionHeaders = {}
local lockoutLabels = {}
local collapseButtons = {}
local resizeButton

-- Initialize for first time account logged in to current expansion
LMAHI.eventFrame = LMAHI.eventFrame or CreateFrame("Frame")
LMAHI.eventFrame:RegisterEvent("ADDON_LOADED")
LMAHI.eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LMAHI_SavedData = LMAHI_SavedData or { initialized = false }

        if LMAHI.InitializeData then
            LMAHI.InitializeData()
        end

        if not LMAHI_SavedData.initialized then
            LMAHI_SavedData.initialized = true

            LMAHI_SavedData.expansionVisibility = {
                TWW  = true, DF   = false, LGN  = false, SL   = false,
                BFA  = false, WOW = false, WOD = false, TBC  = false,
                CAT  = false, WLK = false, MOP = false,
            }

            LMAHI_SavedData.sectionVisibility = {
                raids = true, custom = true, rares = true,
                currencies = true, quests = true, dungeons = true,
            }

            LMAHI_SavedData.selectionFrameCollapsed = {
                WLK = true, DF = true, MOP = true, LGN = true, SL = true,
                BFA = true, CAT = true, TBC = true, WOD = true, WOW = true,
                TWW_raids = false, TWW_dungeons = false,
                TWW_quests = false, TWW_rares = false, TWW_currencies = false,
            }

            LMAHI_SavedData.previousLockoutVisibility = {
                WLK = {}, DF = {}, LGN = {}, CAT = {}, WOD = {},
                WOW = {}, TBC = {}, SL = {}, BFA = {}, MOP = {}
            }

            LMAHI_SavedData.customLockoutOrder = {}
            LMAHI_SavedData.factions = {}
            LMAHI_SavedData.classColors = {}
            LMAHI_SavedData.lockoutVisibility = {}
        end

        if LMAHI.UpdateDisplay then
            LMAHI.UpdateDisplay()
        end
    end
end)


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
LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(145) }

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
    local a = LMAHI_SavedData.minimapPos.angle or math.rad(145)
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
    "Type in the Name (Quest or Rare) and ID., select a reset type",
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
tinsert(UISpecialFrames, settingsFrame)
settingsFrame:SetSize(415, 500)
settingsFrame:SetPoint(
    LMAHI_SavedData.settingsFramePos.point,
    UIParent,
    LMAHI_SavedData.settingsFramePos.relativePoint,
    LMAHI_SavedData.settingsFramePos.x,
    LMAHI_SavedData.settingsFramePos.y
)
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:SetFrameLevel(100)
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

-- CreateLockoutSelectionFrame
function LMAHI.CreateLockoutSelectionFrame()
    local frame = CreateFrame("Frame", "LMAHILockoutSelectionFrame", UIParent, "BasicFrameTemplateWithInset")
    tinsert(UISpecialFrames, "LMAHILockoutSelectionFrame")
    frame:SetSize(400, 640)
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

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -3)
    title:SetText("|cff99ccffLockout|r |cffADADADSelection|r |cff99ccffSettings|r")

    -- Lockout selection panel container
    local lockoutSelectionContent = CreateFrame("Frame", "LMAHILockoutSelectionContent", LMAHILockoutSelectionFrame, "BackdropTemplate")
    lockoutSelectionContent:SetSize(345, 190)
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
    topSection:SetSize(330, 60)

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
    local lines = {
        "Show or Hide the sections on the Main Page",
        "by checking or unchecking the boxes ABOVE.",
        "-----------------------------------------------",
        "Show or Hide ALL lockouts of an Expansion",
        "by checking or unchecking the boxes BELOW.",
        "To HIDE specific lockouts, the Expansion box",
		"MUST be checked, THEN lockouts can be hidden",
		"in the collapsable sections below them.",
    }
    local caption = lockoutSelectionContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    caption:SetPoint("TOP", topSection, "BOTTOM", 0, 2)
    caption:SetWidth(320)
    caption:SetText(table.concat(lines, "\n"))
    caption:SetJustifyH("CENTER")
    caption:SetTextColor(0.9, 0.9, 0.9, 0.9)
    caption:SetSpacing(3)
    caption:Show()

    lockoutSelectionContent.sectionCheckboxes = sectionCheckboxes

    -- Scroll frame starts below top section
    local scrollFrame = CreateFrame("ScrollFrame", "LMAHI_SelectionScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", topSection, "BOTTOMLEFT", 10, -130)
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
    -- Initialize all sections as collapsed by default
    local function InitializeCollapsedState()
        LMAHI_SavedData.selectionFrameCollapsed["custom"] = LMAHI_SavedData.selectionFrameCollapsed["custom"] or true
        local expansions = {
            "TWW", "DF", "SL", "BFA", "LGN", "WOD", "MOP", "CAT", "WLK", "TBC", "WOW"
        }
        for _, expId in ipairs(expansions) do
            LMAHI_SavedData.selectionFrameCollapsed[expId] = LMAHI_SavedData.selectionFrameCollapsed[expId] or true
            for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                if lockoutType ~= "custom" then
                    local typeKey = expId .. "_" .. lockoutType
                    LMAHI_SavedData.selectionFrameCollapsed[typeKey] = LMAHI_SavedData.selectionFrameCollapsed[typeKey] or true
                end
            end
        end
    end
    InitializeCollapsedState()

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
    LMAHI_SavedData.expansionVisibility = LMAHI_SavedData.expansionVisibility or {}
    LMAHI_SavedData.previousLockoutVisibility = LMAHI_SavedData.previousLockoutVisibility or {}
    LMAHI_SavedData.expansionVisibilityModified = LMAHI_SavedData.expansionVisibilityModified or false

    local function UpdateContentLayout()
        local yOffset = -20
        local checkboxes = frame.checkboxes or {}
        local collapseButtons = frame.collapseButtons or {}
        local nameLabels = frame.nameLabels or {}
        local expCheckboxes = frame.expCheckboxes or {}

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
        for _, checkbox in pairs(expCheckboxes) do
            checkbox:ClearAllPoints()
            checkbox:Hide()
        end

        -- Handle Custom section with collapse button and lockouts
        local customKey = "custom"
        local customButton = collapseButtons[customKey] or CreateFrame("Button", nil, content)
        customButton:SetSize(25, 25)
        customButton:SetPoint("TOPLEFT", content, "TOPLEFT", 35, yOffset -4)
        customButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        customButton:GetNormalTexture():SetSize(25, 25)
        customButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
        customButton:GetPushedTexture():SetSize(22, 22)
        customButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        customButton:GetHighlightTexture():SetSize(22, 22)
        local isCustomCollapsed = LMAHI_SavedData.selectionFrameCollapsed[customKey]
        customButton:SetNormalTexture(isCustomCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        customButton:GetNormalTexture():SetSize(22, 22)
        if not collapseButtons[customKey] then
            collapseButtons[customKey] = customButton
        end
        customButton:Show()

        local customLabel = nameLabels[customKey] or content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
        customLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 70, yOffset -8)
        customLabel:SetText("Custom")
        customLabel:SetWidth(300)
        customLabel:SetJustifyH("LEFT")
        customLabel:SetTextColor(1, 1, 1)
        if not nameLabels[customKey] then
            nameLabels[customKey] = customLabel
        end
        customLabel:Show()
        yOffset = yOffset - 20

        customButton:SetScript("OnClick", function(self)
            LMAHI_SavedData.selectionFrameCollapsed[customKey] = not LMAHI_SavedData.selectionFrameCollapsed[customKey]
            self:SetNormalTexture(LMAHI_SavedData.selectionFrameCollapsed[customKey] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            self:GetNormalTexture():SetSize(25, 25)
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
                checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", 55, yOffset - 5)
                checkbox:SetSize(22, 22)
                checkbox.Text:SetText(lockout.name)
                checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 10, 0)
                checkbox.Text:SetFontObject("GameFontNormal")
                checkbox.Text:SetWidth(300)
                checkbox.Text:SetJustifyH("LEFT")
                checkbox.Text:SetTextColor(0.9, 0.7, 0.1)
                checkbox:SetChecked(LMAHI_SavedData.lockoutVisibility[lockoutKey] == true)
                checkbox.lockoutType = "custom"
                checkbox.lockoutId = lockout.id
                if not checkboxes[lockoutKey] then
                    checkboxes[lockoutKey] = checkbox
                    checkbox:SetScript("OnClick", function(self)
                        LMAHI_SavedData.lockoutVisibility[lockoutKey] = self:GetChecked() or nil
                        if LMAHI.UpdateDisplay then
                            LMAHI.UpdateDisplay()
                        end
                    end)
                end
                checkbox:Show()
                yOffset = yOffset - 20
            end
            yOffset = yOffset - 10
        else
            yOffset = yOffset - 15
        end

        local expansionNames = {
            TWW = "The War Within",
            DF = "Dragonflight",
            SL = "Shadowlands",
            BFA = "Battle for Azeroth",
            LGN = "Legion",
            WOD = "Warlords of Draenor",
            MOP = "Mists of Pandaria",
            CAT = "Cataclysm",
            WLK = "Wrath of the Lich King",
            TBC = "The Burning Crusade",
            WOW = "World of Warcraft"
        }

        StaticPopupDialogs["LMAHI_CONFIRM_CLEAR_CHECKS"] = {
            text = "This will remove all |cffffd700checkmarks|r in the\n   %s section, including any\n that have been manually unselected.\nAre you sure you want to clear everything?",
            button1 = "Yes",
            button2 = "Cancel",
            OnAccept = function(self, data)
                local expansionId = data
                -- Clear lockout visibility for this expansion
                for key in pairs(LMAHI_SavedData.lockoutVisibility or {}) do
                    if string.match(key, "^" .. expansionId .. "_") then
                        LMAHI_SavedData.lockoutVisibility[key] = nil
                    end
                end
                -- Clear expansion visibility
                LMAHI_SavedData.expansionVisibility[expansionId] = false
                LMAHI_SavedData.expansionVisibilityModified = true
                -- Update all relevant checkboxes
                for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                    if lockoutType ~= "custom" then
                        local lockouts = LMAHI.lockoutData[lockoutType] or {}
                        for _, lockout in ipairs(lockouts) do
                            if lockout.expansion == expansionId then
                                local lockoutKey = expansionId .. "_" .. lockoutType .. "_" .. lockout.id
                                local checkbox = checkboxes[lockoutKey]
                                if checkbox then
                                    checkbox:SetChecked(false)
                                end
                            end
                        end
                    end
                end
                -- Update the expansion checkbox
                local expCheckbox = expCheckboxes[expansionId]
                if expCheckbox then
                    expCheckbox:SetChecked(false)
                end
                if LMAHI.UpdateDisplay then
                    LMAHI.UpdateDisplay()
                end
                UpdateContentLayout() -- Refresh layout to ensure checkbox states are updated
            end,
            OnCancel = function(self, data)
                local expansionId = data
                local expCheckbox = expCheckboxes[expansionId]
                if expCheckbox then
                    expCheckbox:SetChecked(LMAHI_SavedData.expansionVisibility[expansionId] == true)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }

        -- Handle expansions
        local expansions = {
            { name = "The War Within", id = "TWW", color = {0.9, 0.5, 0.1} },
            { name = "Dragonflight", id = "DF", color = {0.7, 0.8, 0.8} },
            { name = "Shadowlands", id = "SL", color = {1, 0.9, 0.9} },
            { name = "Battle for Azeroth", id = "BFA", color = {0.3, 0.5, 1} },
            { name = "Legion", id = "LGN", color = {0.1, 0.9, 0} },
            { name = "Warlords of Draenor", id = "WOD", color = {0.6, 0.3, 0} },
            { name = "Mists of Pandaria", id = "MOP", color = {0, 0.7, 0.2} },
            { name = "Cataclysm", id = "CAT", color = {0.9, 0.3, 0} },
            { name = "Wrath of the Lich King", id = "WLK", color = {0, 0.3, 0.7} },
            { name = "The Burning Crusade", id = "TBC", color = {0.3, 0.6, 0} },
            { name = "World of Warcraft", id = "WOW", color = {0.9, 0.6, 0} },
        }

        for _, expansion in ipairs(expansions) do
            local expCheckbox = expCheckboxes[expansion.id] or CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            expCheckbox:SetSize(25, 25)
            expCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset )
            -- Set checked state explicitly, treating nil as false
            expCheckbox:SetChecked(LMAHI_SavedData.expansionVisibility[expansion.id] == true)

            if not expCheckboxes[expansion.id] then
                expCheckboxes[expansion.id] = expCheckbox
                expCheckbox:SetScript("OnClick", function(self)
                    local isChecked = self:GetChecked()
                    LMAHI_SavedData.expansionVisibility[expansion.id] = isChecked
                    LMAHI_SavedData.expansionVisibilityModified = true
                    if not isChecked then
                        local name = expansion.name
                        local r, g, b = expansion.color[1], expansion.color[2], expansion.color[3]
                        local hex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
                        local coloredName = hex .. name .. "|r"
                        local popup = StaticPopup_Show("LMAHI_CONFIRM_CLEAR_CHECKS", coloredName, nil, expansion.id)
                        if popup then
                            popup:ClearAllPoints()
                            popup:SetPoint("LEFT", self, "RIGHT", -30, 65)
                        end
                    else
                        LMAHI_SavedData.previousLockoutVisibility[expansion.id] = LMAHI_SavedData.previousLockoutVisibility[expansion.id] or {}
                        for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
                            if lockoutType ~= "custom" then
                                local lockouts = LMAHI.lockoutData[lockoutType] or {}
                                for _, lockout in ipairs(lockouts) do
                                    if lockout.expansion == expansion.id then
                                        local lockoutKey = expansion.id .. "_" .. lockoutType .. "_" .. lockout.id
                                        LMAHI_SavedData.lockoutVisibility[lockoutKey] = LMAHI_SavedData.previousLockoutVisibility[expansion.id][lockoutKey] or true
                                        local checkbox = checkboxes[lockoutKey]
                                        if checkbox then
                                            checkbox:SetChecked(true)
                                        end
                                    end
                                end
                            end
                        end
                        if LMAHI.UpdateDisplay then
                            LMAHI.UpdateDisplay()
                        end
                        UpdateContentLayout() -- Refresh layout to reflect changes
                    end
                end)
            end
            expCheckbox:Show()

            local expButton = collapseButtons[expansion.id] or CreateFrame("Button", nil, content)
            expButton:SetSize(25, 25)
            expButton:SetPoint("TOPLEFT", content, "TOPLEFT", 35, yOffset)
            expButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
            expButton:GetNormalTexture():SetSize(25, 25)
            expButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
            expButton:GetPushedTexture():SetSize(25, 25)
            expButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            expButton:GetHighlightTexture():SetSize(25, 25)
            local isCollapsed = LMAHI_SavedData.selectionFrameCollapsed[expansion.id]
            expButton:SetNormalTexture(isCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
            expButton:GetNormalTexture():SetSize(25, 25)
            expButton.expansion = expansion.id
            if not collapseButtons[expansion.id] then
                collapseButtons[expansion.id] = expButton
            end
            expButton:Show()

            local expLabel = nameLabels[expansion.id] or content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
            expLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 70, yOffset - 4)
            expLabel:SetText(expansion.name)
            expLabel:SetWidth(300)
            expLabel:SetJustifyH("LEFT")
            expLabel:SetTextColor(expansion.color[1], expansion.color[2], expansion.color[3])
            if not nameLabels[expansion.id] then
                nameLabels[expansion.id] = expLabel
            end
            expLabel:Show()
            yOffset = yOffset - 20

            expButton:SetScript("OnClick", function(self)
                LMAHI_SavedData.selectionFrameCollapsed[expansion.id] = not LMAHI_SavedData.selectionFrameCollapsed[expansion.id]
                self:SetNormalTexture(LMAHI_SavedData.selectionFrameCollapsed[expansion.id] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                self:GetNormalTexture():SetSize(25, 25)
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
                            typeButton:SetSize(22, 22)
                            typeButton:SetPoint("TOPLEFT", content, "TOPLEFT", 45, yOffset -5)
                            typeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                            typeButton:GetNormalTexture():SetSize(22, 22)
                            typeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
                            typeButton:GetPushedTexture():SetSize(22, 22)
                            typeButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
                            typeButton:GetHighlightTexture():SetSize(22, 22)
                            local typeCollapsed = LMAHI_SavedData.selectionFrameCollapsed[typeKey]
                            typeButton:SetNormalTexture(typeCollapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                            typeButton:GetNormalTexture():SetSize(22, 22)
                            typeButton.expansion = expansion.id
                            typeButton.lockoutType = lockoutType
                            if not collapseButtons[typeKey] then
                                collapseButtons[typeKey] = typeButton
                            end
                            typeButton:Show()

                            local typeLabel = nameLabels[typeKey] or content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
                            typeLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 75, yOffset - 8)
                            typeLabel:SetText(lockoutType:gsub("^%l", string.upper))
                            typeLabel:SetWidth(110)
                            typeLabel:SetJustifyH("LEFT")
                            typeLabel:SetTextColor(1, 1, 1)
                            if not nameLabels[typeKey] then
                                nameLabels[typeKey] = typeLabel
                            end
                            typeLabel:Show()
                            yOffset = yOffset - 20

                            typeButton:SetScript("OnClick", function(self)
                                LMAHI_SavedData.selectionFrameCollapsed[typeKey] = not LMAHI_SavedData.selectionFrameCollapsed[typeKey]
                                self:SetNormalTexture(LMAHI_SavedData.selectionFrameCollapsed[typeKey] and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
                                self:GetNormalTexture():SetSize(22, 22)
                                UpdateContentLayout()
                                if LMAHI.UpdateDisplay then
                                    LMAHI.UpdateDisplay()
                                end
                            end)

                            if not typeCollapsed then
                                for _, lockout in ipairs(lockouts) do
                                    if lockout.expansion == expansion.id then
                                        local lockoutKey = expansion.id .. "_" .. lockoutType .. "_" .. lockout.id
                                        local checkbox = checkboxes[lockoutKey] or CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                                        checkbox:SetPoint("TOPLEFT", content, "TOPLEFT", 58, yOffset - 7)
                                        checkbox:SetSize(25, 25)
                                        checkbox.Text:SetText(lockout.name)
                                        checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 7, 1)
                                        checkbox.Text:SetFontObject("GameFontNormal")
                                        checkbox.Text:SetWidth(300)
                                        checkbox.Text:SetJustifyH("LEFT")
                                        checkbox.Text:SetTextColor(0.9, 0.7, 0.1)
                                        checkbox:SetChecked(LMAHI_SavedData.lockoutVisibility[lockoutKey] == true)
                                        checkbox.expansion = expansion.id
                                        checkbox.lockoutType = lockoutType
                                        checkbox.lockoutId = lockout.id
                                        if not checkboxes[lockoutKey] then
                                            checkboxes[lockoutKey] = checkbox
                                            checkbox:SetScript("OnClick", function(self)
                                                LMAHI_SavedData.lockoutVisibility[lockoutKey] = self:GetChecked() or nil
                                                if LMAHI.UpdateDisplay then
                                                    LMAHI.UpdateDisplay()
                                                end
                                            end)
                                        end
                                        checkbox:Show()
                                        yOffset = yOffset - 22   -- moves each lockout in each expansion r d q r c apart
                                    end
                                end
                            end
                            yOffset = yOffset - 5   -- moves each expansion r d q r c apart
                        end
                    end
                end
            end
            yOffset = yOffset - 10   -- moves each expansion apart
        end

        content:SetHeight(-yOffset + 20)
        frame.checkboxes = checkboxes
        frame.collapseButtons = collapseButtons
        frame.nameLabels = nameLabels
        frame.expCheckboxes = expCheckboxes
    end

    -- Ensure initial checkbox states are set correctly after frame creation
    frame:SetScript("OnShow", function()
        -- Reinitialize expansionVisibility only if not modified by user
        local expansions = {
            "TWW", "DF", "SL", "BFA", "LGN", "WOD", "MOP", "CAT", "WLK", "TBC", "WOW"
        }
        if not LMAHI_SavedData.expansionVisibilityModified then
            for _, expId in ipairs(expansions) do
                LMAHI_SavedData.expansionVisibility[expId] = (expId == "TWW")
            end
        end
        for _, expId in ipairs(expansions) do
            local checkbox = frame.expCheckboxes[expId]
            if checkbox then
                checkbox:SetChecked(LMAHI_SavedData.expansionVisibility[expId] == true)
            end
        end
        UpdateContentLayout() -- Refresh layout to ensure consistency
    end)

    UpdateContentLayout()
    return frame
end



-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    local charName = UnitName("player") .. "-" .. GetRealmName()

    if event == "ADDON_LOADED" and arg1 == addonName then
        if LMAHI.InitializeData then
            LMAHI.InitializeData()
        end

        -- SavedVariables initialization
        LMAHI_SavedData.minimapPos = LMAHI_SavedData.minimapPos or { angle = math.rad(145) }
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
        LMAHI_SavedData.lockoutVisibility = LMAHI_SavedData.lockoutVisibility or {}
        LMAHI_SavedData.currentPage = LMAHI_SavedData.currentPage or 1
        LMAHI_SavedData.lockoutVisibilityModified = LMAHI_SavedData.lockoutVisibilityModified or false

        LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts

        -- Initialize lockoutVisibility only if not modified
        if not LMAHI_SavedData.lockoutVisibilityModified then
            for _, lockoutType in ipairs({"raids", "dungeons"}) do
                for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                    local lockoutKey = (lockout.expansion or "TWW") .. "_" .. lockoutType .. "_" .. lockout.id
                    LMAHI_SavedData.lockoutVisibility[lockoutKey] = LMAHI_SavedData.lockoutVisibility[lockoutKey] or (lockout.expansion == "TWW")
                end
            end
            LMAHI_SavedData.lockoutVisibilityModified = true
        end

        -- Character ordering
        local charList = {}
        for charName, _ in pairs(LMAHI_SavedData.characters) do
            table.insert(charList, charName)
        end
        table.sort(charList, function(a, b)
            local aIndex = LMAHI_SavedData.charOrder[a] or 999
            local bIndex = LMAHI_SavedData.charOrder[b] or 1000
            if aIndex == bIndex then return a < b end
            return aIndex < bIndex
        end)
        local newCharOrder = {}
        for i, charName in ipairs(charList) do
            newCharOrder[charName] = i
        end
        LMAHI_SavedData.charOrder = newCharOrder

        UpdateButtonPosition()
        if LMAHI.InitializeLockouts then LMAHI.InitializeLockouts() end
        if LMAHI.SaveCharacterData then LMAHI.SaveCharacterData() end
        if LMAHI.CheckLockouts then LMAHI.CheckLockouts() end

        LMAHI.currentPage = LMAHI_SavedData.currentPage
        mainFrame:SetScale(LMAHI_SavedData.zoomLevel)
        settingsFrame:SetScale(LMAHI_SavedData.zoomLevel)
        customInputFrame:SetScale(LMAHI_SavedData.zoomLevel)
        mainFrame:Hide()
        Utilities.StartGarbageCollector()

    elseif event == "PLAYER_LOGIN" then
        UpdateButtonPosition()
        if LMAHI.SaveCharacterData then LMAHI.SaveCharacterData() end
        if LMAHI.CheckLockouts then LMAHI.CheckLockouts() end
        LMAHI.currentPage = LMAHI_SavedData.currentPage
        mainFrame:Hide()

    elseif event == "PLAYER_LOGOUT" then
        LMAHI_SavedData.currentPage = LMAHI.currentPage
        if LMAHI.SaveCharacterData then LMAHI.SaveCharacterData() end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_END" or event == "QUEST_TURNED_IN"
        or event == "LFG_LOCK_INFO_RECEIVED" or event == "UPDATE_INSTANCE_INFO" then

        if LMAHI.SaveCharacterData then LMAHI.SaveCharacterData() end

        LMAHI_SavedData.lockouts = LMAHI_SavedData.lockouts or {}
        LMAHI_SavedData.lockouts[charName] = LMAHI_SavedData.lockouts[charName] or {}

        -- Preserve non-raid/dungeon lockouts
        local nonRaidLockouts = {}
        for key, data in pairs(LMAHI_SavedData.lockouts[charName]) do
            if type(data) ~= "table" or (data.type and data.type ~= "raid" and data.type ~= "dungeon") then
                nonRaidLockouts[key] = data
            end
        end

        -- Clear existing lockouts and repopulate with non-raid data
        LMAHI_SavedData.lockouts[charName] = nonRaidLockouts

        -- Map dungeon names to UI lockout IDs
        local raidNameToId = {}
        local dungeonNameToId = {}
        for _, lockout in ipairs(LMAHI.lockoutData["raids"] or {}) do
            raidNameToId[lockout.name] = lockout.id
        end
        for _, lockout in ipairs(LMAHI.lockoutData["dungeons"] or {}) do
            dungeonNameToId[lockout.name] = lockout.id
        end

        -- Process saved instances
        for i = 1, GetNumSavedInstances() do
            local name, instanceId, reset, difficultyId, locked, _, _, _, _, _, numEncounters = GetSavedInstanceInfo(i)
            if locked then
                local lockoutId = raidNameToId[name] or dungeonNameToId[name]
                if lockoutId then
                    local lockoutType = raidNameToId[name] and "raid" or "dungeon"
                    local validDifficulty = lockoutType == "raid" and (difficultyId == 14 or difficultyId == 15 or difficultyId == 16 or difficultyId == 17) or
                                          lockoutType == "dungeon" and (difficultyId == 2 or difficultyId == 8 or difficultyId == 23)
                    if validDifficulty then
                        local difficultyLabel = lockoutType == "raid" and
                            (difficultyId == 17 and "Lfr" or difficultyId == 14 and "N" or difficultyId == 15 and "H" or "M") or
                            (difficultyId == 23 and "L" or difficultyId == 2 and "H" or "M0")
                        local diffLockoutId = tostring(lockoutId) .. "-" .. difficultyLabel
                        local lockoutData = {
                            name = name,
                            numEncounters = numEncounters,
                            id = lockoutId,
                            difficultyId = difficultyId,
                            difficultyLabel = difficultyLabel,
                            encounters = {},
                            reset = reset,
                            type = lockoutType,
                        }
                        for j = 1, numEncounters do
                            local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                            lockoutData.encounters[j] = { name = bossName or ("Boss " .. j), isKilled = isKilled }
                        end
                        LMAHI_SavedData.lockouts[charName][diffLockoutId] = lockoutData
                        print("LMAHI Debug: Saved", lockoutType, "lockout for", charName, name, "LockoutID:", diffLockoutId, "DifficultyID:", difficultyId, "InstanceID:", instanceId)
                    end
                end
            end
        end

        -- Process Mythic+ data for current character
        if C_MythicPlus and C_MythicPlus.GetRunHistory then
            local runHistory = C_MythicPlus.GetRunHistory(false, true) or {}
            for _, run in ipairs(runHistory) do
                local lockoutId = dungeonNameToId[run.mapChallengeModeID]
                if lockoutId then
                    local diffLockoutId = tostring(lockoutId) .. "-M+"
                    LMAHI_SavedData.lockouts[charName][diffLockoutId] = {
                        name = run.mapName,
                        id = lockoutId,
                        difficultyId = 8,
                        difficultyLabel = "M+",
                        type = "dungeon",
                        mythicPlusLevel = run.level,
                    }
                    print("LMAHI Debug: Saved Mythic+ lockout for", charName, run.mapName, "LockoutID:", diffLockoutId, "Level:", run.level)
                end
            end
        end

        LMAHI_SavedData.currentPage = LMAHI.currentPage
        if LMAHI.CheckLockouts then LMAHI.CheckLockouts(event, arg1) end
        if mainFrame:IsShown() then
            ThrottledUpdateDisplay()
        end
    end
end)

-- Optional: reset check timer
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    lastResetCheckTime = lastResetCheckTime + elapsed
    if lastResetCheckTime >= resetCheckThrottle then
        if LMAHI.CheckResetTimers then
            LMAHI.CheckResetTimers()
        end
        lastResetCheckTime = 0
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

-- Memory Tracker Frame

local memFrame = CreateFrame("Frame", "LMAHIMemoryFrame", UIParent)
memFrame:SetFrameStrata("DIALOG")
memFrame:SetSize(160, 15)
memFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 125, -4)
memFrame.bg = memFrame:CreateTexture(nil, "BACKGROUND")
memFrame.bg:SetAllPoints()
memFrame.bg:SetColorTexture(0, 0, 0, 0.1)
memFrame.text = memFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
memFrame.text:SetPoint("LEFT", memFrame, "LEFT")
memFrame.text:SetTextColor(1, 1, 1)
memFrame:Hide()

-- CPU Tracker Frame
local cpuFrame = CreateFrame("Frame", "LMAHICPUFrame", UIParent)
cpuFrame:SetFrameStrata("DIALOG")
cpuFrame:SetSize(160, 15)
cpuFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 125, -19)
cpuFrame.bg = cpuFrame:CreateTexture(nil, "BACKGROUND")
cpuFrame.bg:SetAllPoints()
cpuFrame.bg:SetColorTexture(0, 0, 0, 0.1)
cpuFrame.text = cpuFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
cpuFrame.text:SetPoint("LEFT", cpuFrame, "LEFT")
cpuFrame.text:SetTextColor(1, 1, 1)
cpuFrame:Hide()

-- Storage for active tickers
local memTicker = nil
local cpuTicker = nil

-- Start tracking performance
local function StartPerformanceTracking()
    UpdateAddOnMemoryUsage()
    memTicker = C_Timer.NewTicker(1, function()
        UpdateAddOnMemoryUsage()
        local mem = GetAddOnMemoryUsage(addonName)
        memFrame.text:SetText(string.format("LMAHI Mem: %.2f MB", mem / 1024))
    end)

    local lastCPU = 0
    cpuTicker = C_Timer.NewTicker(1, function()
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
cpuFrame.text:SetText(string.format("LMAHI CPU:   %.1f%%", percent))
    end)

    memFrame:Show()
    cpuFrame:Show()
end

-- Stop tracking performance
local function StopPerformanceTracking()
    if memTicker then memTicker:Cancel() end
    if cpuTicker then cpuTicker:Cancel() end
    memFrame:Hide()
    cpuFrame:Hide()
end

local trackingEnabled = false

local trackingEnabled = false

-- Create the button frame
local toggleButton = CreateFrame("Button", "CustomMTToggle", UIParent, "BackdropTemplate")
toggleButton:SetFrameStrata("DIALOG")
toggleButton:SetSize(40, 20)
toggleButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 73, -4)

toggleButton:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 1, edgeSize = 1,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
toggleButton:SetBackdropColor(0.4, 0, 0, 0.5) 

local font = toggleButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
font:SetPoint("BOTTOM", -2, 4)
font:SetJustifyH("CENTER")
font:SetJustifyV("MIDDLE")
font:SetText("OFF")
font:SetTextColor(1, 0, 0)  
toggleButton.font = font

-- Interactivity
toggleButton:SetScript("OnClick", function()
    trackingEnabled = not trackingEnabled
    if trackingEnabled then
        StartPerformanceTracking()
        font:SetText("ON")
        font:SetTextColor(0, 1, 0)  
        toggleButton:SetBackdropColor(0, 0.4, 0, 0.5)  
    else
        StopPerformanceTracking()
        font:SetText("OFF")
        font:SetTextColor(1, 0, 0)  
        toggleButton:SetBackdropColor(0.4, 0, 0, 0.5) 
    end
end)

-- Main frame hookup
LMAHI.mainFrame = mainFrame

-- Sleep state tracking
function LMAHI_Enable()
    if LMAHI.mainFrame then
        LMAHI.mainFrame:Show()
    end
    _G.LMAHI_Sleeping = false
    print("LMAHI activated")

    -- ✅ Seed visibility when waking for the first time
    if not LMAHI_SavedData.defaultLockoutsSeeded then
        LMAHI_SavedData.lockoutVisibility = LMAHI_SavedData.lockoutVisibility or {}

        for _, lockoutType in ipairs({ "raids", "dungeons", "quests", "rares", "currencies" }) do
            for _, lockout in ipairs(LMAHI.lockoutData[lockoutType] or {}) do
                if lockout.expansion == "TWW" and type(lockout.id) == "number" then
                    local key = "TWW_" .. lockoutType .. "_" .. lockout.id
                    LMAHI_SavedData.lockoutVisibility[key] = true
                end
            end
        end

        for _, lockout in ipairs(LMAHI.lockoutData.custom or {}) do
            if lockout.id then
                local key = "Custom_" .. lockout.id
                LMAHI_SavedData.lockoutVisibility[key] = true
            end
        end

        LMAHI_SavedData.defaultLockoutsSeeded = true
        print("✅ TWW visibility seeded during wakeup.")
    end

    -- Reinitialize expansionVisibility only if not modified by user
    if not LMAHI_SavedData.expansionVisibilityModified then
        local expansions = {
            "TWW", "DF", "SL", "BFA", "LGN", "WOD", "MOP", "CAT", "WLK", "TBC", "WOW"
        }
        for _, expId in ipairs(expansions) do
            LMAHI_SavedData.expansionVisibility[expId] = (expId == "TWW")
        end
    end

    -- Refresh selection frame if it exists
    if LMAHI.lockoutSelectionFrame and LMAHI.lockoutSelectionFrame.expCheckboxes then
        local expansions = {
            "TWW", "DF", "SL", "BFA", "LGN", "WOD", "MOP", "CAT", "WLK", "TBC", "WOW"
        }
        for _, expId in ipairs(expansions) do
            local checkbox = LMAHI.lockoutSelectionFrame.expCheckboxes[expId]
            if checkbox then
                checkbox:SetChecked(LMAHI_SavedData.expansionVisibility[expId] == true)
            end
        end
    end

    LMAHI:ResetCaches()
    if LMAHI.SaveCharacterData then
        LMAHI.SaveCharacterData()
    end
    if LMAHI.CheckLockouts then
        LMAHI.CheckLockouts()
    end
    if LMAHI.UpdateDisplay then
        LMAHI.UpdateDisplay()
    end
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

