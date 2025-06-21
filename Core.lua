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
}

-- Frame variables
local mainFrame, charFrame, lockoutScrollFrame, lockoutContent, settingsFrame, customInputFrame
local highlightLine, highlightFrame
local charListScrollFrame, charListContent, customInputScrollFrame, customInputScrollContent
local sectionHeaders = {}
local lockoutLabels = {}
local collapseButtons = {}

-- Create main frame
mainFrame = CreateFrame("Frame", "LMAHI_Frame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_Frame")
mainFrame:SetSize(1250, 450)
mainFrame:SetPoint(LMAHI_SavedData.framePos.point, UIParent, LMAHI_SavedData.framePos.relativePoint, LMAHI_SavedData.framePos.x, LMAHI_SavedData.framePos.y)
mainFrame:SetFrameStrata("HIGH")
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
zoomInButton:SetScript("OnLeave", GameTooltip_Hide)

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
zoomOutButton:SetScript("OnLeave", GameTooltip_Hide)

-- Custom input and settings buttons
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
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Custom Lockout Input")
    GameTooltip:Show()
end)
customInputButton:SetScript("OnLeave", GameTooltip_Hide)

local settingsButton = CreateFrame("Button", nil, mainFrame)
settingsButton:SetSize(27, 32)
settingsButton:SetPoint("TOPLEFT", customInputButton, "TOPRIGHT", 15, 0)
settingsButton:SetNormalTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
settingsButton:SetPushedTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
goldOverlay = settingsButton:CreateTexture(nil, "ARTWORK", nil, 1)
goldOverlay:SetColorTexture(1, 0.85, 0, 0.2)
goldOverlay:SetAllPoints(settingsButton:GetNormalTexture())
settingsButton:SetScript("OnClick", function()
    settingsFrame:SetShown(not settingsFrame:IsShown())
    if settingsFrame:IsShown() then
        LMAHI.UpdateSettingsDisplay()
    end
end)
settingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Character Order Settings")
    GameTooltip:Show()
end)
settingsButton:SetScript("OnLeave", GameTooltip_Hide)

-- Navigation arrows
local leftArrow = CreateFrame("Button", nil, mainFrame)
leftArrow:SetSize(40, 50)
leftArrow:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 167, -23)
leftArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
leftArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
leftArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
leftArrow:SetScript("OnClick", function()
    LMAHI.currentPage = math.max(1, LMAHI.currentPage - 1)
    LMAHI.UpdateDisplay()
end)
leftArrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Previous Page")
    GameTooltip:Show()
end)
leftArrow:SetScript("OnLeave", GameTooltip_Hide)

local rightArrow = CreateFrame("Button", nil, mainFrame)
rightArrow:SetSize(40, 50)
rightArrow:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -7, -23)
rightArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
rightArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
rightArrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
rightArrow:SetScript("OnClick", function()
    LMAHI.currentPage = math.min(LMAHI.maxPages, LMAHI.currentPage + 1)
    LMAHI.UpdateDisplay()
end)
rightArrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Next Page")
    GameTooltip:Show()
end)
rightArrow:SetScript("OnLeave", GameTooltip_Hide)

-- Character frame
charFrame = CreateFrame("Frame", "LMAHI_CharFrame", mainFrame, "BackdropTemplate")
charFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 200, -24)
charFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", 1208, 378)
charFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
charFrame:SetBackdropColor(0, 0, 0, 1)
charFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 3)
charFrame:Show()

-- Lockout scroll frame
lockoutScrollFrame = CreateFrame("ScrollFrame", "LMAHI_LockoutScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
lockoutScrollFrame:SetPoint("TOPLEFT", charFrame, "TOPRIGHT", -1195, -50)
lockoutScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -35, 10)
lockoutScrollFrame:EnableMouseWheel(true)
lockoutScrollFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
lockoutScrollFrame:Show()

lockoutScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 30
    local newScroll = math.max(0, math.min(current - delta * scrollAmount, maxScroll))
    self:SetVerticalScroll(newScroll)
end)

lockoutContent = CreateFrame("Frame", "LMAHI_LockoutContent", lockoutScrollFrame)
lockoutScrollFrame:SetScrollChild(lockoutContent)
lockoutContent:SetWidth(lockoutScrollFrame:GetWidth() - 30)
lockoutContent:SetHeight(400) -- Initial height, updated later
lockoutContent:Show()

highlightLine = lockoutContent:CreateTexture(nil, "OVERLAY")
highlightLine:SetTexture("Interface\\Buttons\\WHITE8X8")
highlightLine:SetVertexColor(0.8, 0.8, 0.8, 0.1)
highlightLine:SetHeight(10)
highlightLine:Hide()

highlightFrame = CreateFrame("Frame", nil, lockoutScrollFrame)
highlightFrame:SetAllPoints(lockoutScrollFrame)
highlightFrame:EnableMouse(false)
highlightFrame:SetFrameLevel(lockoutScrollFrame:GetFrameLevel() + 2)

-- Custom input frame
customInputFrame = CreateFrame("Frame", "LMAHI_CustomInputFrame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_CustomInputFrame")
customInputFrame:SetSize(500, 500)
customInputFrame:SetPoint(LMAHI_SavedData.customInputFramePos.point, UIParent, LMAHI_SavedData.customInputFramePos.relativePoint, LMAHI_SavedData.customInputFramePos.x, LMAHI_SavedData.customInputFramePos.y)
customInputFrame:SetFrameStrata("DIALOG")
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

local customInputTitle = customInputFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
customInputTitle:SetPoint("TOP", customInputFrame, "TOP", 0, -3)
customInputTitle:SetText("|cff99ccffCustom|r |cffADADADLockout|r |cff99ccffInput|r")
customInputTitle:SetTextColor(0.6, 0.8, 0.9)

local customInputContent = CreateFrame("Frame", nil, customInputFrame)
customInputContent:SetSize(460, 120)
customInputContent:SetPoint("TOPLEFT", customInputFrame, "TOPLEFT", 10, -30)
customInputContent:Show()

-- Custom input fields Utility Functions
local function SetCollapseIconRotation(button, isCollapsed)
    local angle = isCollapsed and math.rad(90) or math.rad(270)
    C_Timer.After(0, function()
        if button and button.icon then
            button.icon:SetRotation(angle)
        end
    end)
end

local function CalculateContentHeight()
    local totalItems = 0
    for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
        if not LMAHI_SavedData.collapsedSections[lockoutType] then
            totalItems = totalItems + #LMAHI.lockoutData[lockoutType]
        end
    end
    local itemHeight = 20
    local sectionHeaderHeight = 30
    local padding = 30
    return math.max(400, (totalItems * itemHeight) + (#LMAHI.lockoutTypes * sectionHeaderHeight) + padding)
end

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
idLabel:SetText("ID Number")
idLabel:Show()

local idInput = CreateFrame("EditBox", nil, customInputContent, "InputBoxTemplate")
idInput:SetSize(100, 20)
idInput:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 240, -29)
idInput:SetNumeric(true)
idInput:SetMaxLetters(10)
idInput:SetAutoFocus(false)
idInput:Show()

local tipLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
tipLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 60, -58)
tipLabel:SetText("Type in the Name and ID      OR\n\n\Press  Control - C  to copy from somewhere\n\nthen press  Control - V  to paste it in")
tipLabel:SetTextColor(0.9, 0.9, 0.9)
tipLabel:Show()

local resetLabel = customInputContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
resetLabel:SetPoint("TOPLEFT", customInputContent, "TOPLEFT", 359, -10)
resetLabel:SetText("Reset Type")
resetLabel:Show()

local resetDropdown = CreateFrame("Frame", "LMAHI_ResetDropdown", customInputContent, "UIDropDownMenuTemplate")
resetDropdown:SetPoint("LEFT", resetLabel, "RIGHT", -98, -25)
UIDropDownMenu_SetWidth(resetDropdown, 70)
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
            UIDropDownMenu_SetText(resetDropdown, self:GetText())
        end
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetSelectedValue(resetDropdown, "weekly")
UIDropDownMenu_SetText(resetDropdown, "Weekly")

local addButton = CreateFrame("Button", nil, customInputContent, "UIPanelButtonTemplate")
addButton:SetSize(300, 24)
addButton:SetPoint("TOPLEFT", resetLabel, "BOTTOMLEFT", -320, -120)
addButton:SetText("Add Your Lockout to the List Below")
addButton:Show()

addButton:SetScript("OnClick", function()
    local name = nameInput:GetText():trim()
    local id = tonumber(idInput:GetText())
    local reset = UIDropDownMenu_GetSelectedValue(resetDropdown)

    if name == "" or id == nil then
        print("LMAHI: Please enter a valid name and ID.")
        return
    end

    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
        if lockout.id == id then
            print("LMAHI: This ID is already in use.")
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
    LMAHI.UpdateDisplay()
    LMAHI.SaveCharacterData()
end)

customInputScrollFrame = CreateFrame("ScrollFrame", "LMAHI_CustomInputScrollFrame", customInputFrame, "UIPanelScrollFrameTemplate")
customInputScrollFrame:SetSize(450, 280)
customInputScrollFrame:SetPoint("TOPLEFT", customInputContent, "BOTTOMLEFT", 2, -60)
customInputScrollFrame:EnableMouseWheel(true)
customInputScrollFrame:SetFrameLevel(customInputFrame:GetFrameLevel() + 2)
customInputScrollFrame:Show()

customInputScrollContent = CreateFrame("Frame", nil, customInputScrollFrame)
customInputScrollFrame:SetScrollChild(customInputScrollContent)
customInputScrollContent:SetSize(440, 400)
customInputScrollContent:Show()

customInputScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 30
    local newScroll = math.max(0, math.min(current - delta * scrollAmount, maxScroll))
    self:SetVerticalScroll(newScroll)
end)

-- Settings frame
settingsFrame = CreateFrame("Frame", "LMAHI_SettingsFrame", UIParent, "BasicFrameTemplateWithInset")
tinsert(UISpecialFrames, "LMAHI_SettingsFrame")
settingsFrame:SetFrameLevel(10)
settingsFrame:SetSize(440, 380)
settingsFrame:SetPoint(LMAHI_SavedData.settingsFramePos.point, UIParent, LMAHI_SavedData.settingsFramePos.relativePoint, LMAHI_SavedData.settingsFramePos.x, LMAHI_SavedData.settingsFramePos.y)
settingsFrame:SetFrameStrata("DIALOG")
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

local settingsTitle = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighLightLarge")
settingsTitle:SetPoint("TOP", settingsFrame, "TOP", 0, -3)
settingsTitle:SetText("|cff99ccffCharacter|r |cffADADADOrder|r |cff99ccffSettings|r |cffADADADFor|r |cff99ccffThis|r |cffADADADAddon|r")
settingsTitle:SetTextColor(0.6, 0.8, 0.9)

charListScrollFrame = CreateFrame("ScrollFrame", "LMAHI_CharListScrollFrame", settingsFrame, "UIPanelScrollFrameTemplate")
charListScrollFrame:SetSize(380, 340)
charListScrollFrame:SetPoint("TOP", settingsFrame, "TOP", 0, -30)
charListScrollFrame:SetFrameLevel(settingsFrame:GetFrameLevel() + 2)
charListScrollFrame:Show()

charListContent = CreateFrame("Frame", nil, charListScrollFrame)
charListScrollFrame:SetScrollChild(charListContent)
charListContent:SetSize(240, 400)
charListContent:Show()

charListScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local scrollAmount = 30
    local newScroll = math.max(0, math.min(current - delta * scrollAmount, maxScroll))
    self:SetVerticalScroll(newScroll)
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

local mask = minimapButton:CreateMaskTexture()
mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mask:SetAllPoints()
texture:AddMaskTexture(mask)

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
        local x = (px / scale - mx)
        local y = (py / scale - my)
        local angle = math.atan2(y, x)
        local newX = math.cos(angle) * radius
        local newY = math.sin(angle) * radius
        self:SetPoint("CENTER", Minimap, "CENTER", newX, newY)
    end
end)
minimapButton:SetScript("OnClick", function()
    mainFrame:SetShown(not mainFrame:IsShown())
    if mainFrame:IsShown() then
        LMAHI.SaveCharacterData()
        LMAHI.UpdateDisplay()
    end
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff99ccffLockouts|r|cffADADADMany|r|cff99ccffAlts|r|cffADADADHandle|r|cff99ccffIT|r")
    GameTooltip:AddLine("|cff00E800Left click|r |cffffffffto open|r")
    GameTooltip:AddLine("|cffFF9933Right click|r |cffffffffto drag|r")
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", GameTooltip_Hide)

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        UpdateButtonPosition()
        LMAHI.InitializeLockouts()
        LMAHI.SaveCharacterData()
        LMAHI.currentPage = 1
        mainFrame:SetScale(LMAHI_SavedData.zoomLevel)
        settingsFrame:SetScale(LMAHI_SavedData.zoomLevel)
        customInputFrame:SetScale(LMAHI_SavedData.zoomLevel)

        -- Initialize collapse buttons and section headers
        local currentOffset = -20
        for _, lockoutType in ipairs(LMAHI.lockoutTypes) do
            local isCollapsed = LMAHI_SavedData.collapsedSections[lockoutType]

            local collapseButton = CreateFrame("Button", nil, lockoutContent)
            collapseButton:SetSize(24, 24)
            collapseButton:SetPoint("TOPLEFT", lockoutContent, "TOPLEFT", 10, currentOffset)

            local icon = collapseButton:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
            collapseButton.icon = icon

            SetCollapseIconRotation(collapseButton, isCollapsed)

            collapseButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            collapseButton:SetFrameLevel(lockoutContent:GetFrameLevel() + 3)

            collapseButton:SetScript("OnClick", function(self)
                local nowCollapsed = not LMAHI_SavedData.collapsedSections[lockoutType]
                LMAHI_SavedData.collapsedSections[lockoutType] = nowCollapsed

                SetCollapseIconRotation(self, nowCollapsed)

                if GameTooltip:IsOwned(self) then
                    local label = nowCollapsed and "Expand" or "Collapse"
                    GameTooltip:SetText(label .. " " .. lockoutType:gsub("^%l", string.upper))
                end

                lockoutContent:SetHeight(CalculateContentHeight())
                LMAHI.UpdateDisplay()
            end)

            collapseButton:SetScript("OnShow", function(self)
                local collapsed = LMAHI_SavedData.collapsedSections[lockoutType]
                SetCollapseIconRotation(self, collapsed)
            end)

            collapseButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local label = LMAHI_SavedData.collapsedSections[lockoutType] and "Expand" or "Collapse"
                GameTooltip:SetText(label .. " " .. lockoutType:gsub("^%l", string.upper))
                GameTooltip:Show()
            end)

            collapseButton:SetScript("OnLeave", GameTooltip_Hide)
            collapseButtons[lockoutType] = collapseButton

            local header = lockoutContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
            header:SetPoint("TOPLEFT", lockoutContent, "TOPLEFT", 40, currentOffset)
            header:SetText(lockoutType:gsub("^%l", string.upper))
            header:Show()
            sectionHeaders[lockoutType] = header

            currentOffset = currentOffset - 30

            if not isCollapsed then
                currentOffset = currentOffset - (#LMAHI.lockoutData[lockoutType] * 20)
            end
            currentOffset = currentOffset - 10
        end

        LMAHI.UpdateDisplay()
    elseif event == "PLAYER_LOGIN" then
        UpdateButtonPosition()
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
        LMAHI_SavedData.collapsedSections = LMAHI_SavedData.collapsedSections or {}
        LMAHI_SavedData.customLockouts = LMAHI_SavedData.customLockouts or {}
        LMAHI.lockoutData.custom = LMAHI_SavedData.customLockouts
    elseif event == "PLAYER_LOGOUT" then
        LMAHI.CheckLockouts()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_END" or event == "QUEST_TURNED_IN" or event == "LFG_LOCK_INFO_RECEIVED" or event == "UPDATE_INSTANCE_INFO" or event == "CURRENCY_DISPLAY_UPDATE" then
        LMAHI.SaveCharacterData()
    end
end)

-- Slash commands
SLASH_LMAHI1 = "/lmahi"
SlashCmdList["LMAHI"] = function()
    mainFrame:SetShown(not mainFrame:IsShown())
    if mainFrame:IsShown() then
        LMAHI.SaveCharacterData()
        LMAHI.UpdateDisplay()
    end
end

SLASH_LMAHIRESET1 = "/lmahireset"
SlashCmdList["LMAHIRESET"] = function()
    LMAHI.CleanLockouts()
    LMAHI.InitializeLockouts()
    LMAHI.SaveCharacterData()
    print("LMAHI: Lockout data cleaned and reset for current character.")
end

SLASH_LMAHIDEBUG1 = "/lmahidebug"
SlashCmdList["LMAHIDEBUG"] = function()
    print("Debug: Saved Instances")
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, lockedState, _, _, _, _, _, _, instanceID = GetSavedInstanceInfo(i)
        print(string.format("Instance: %s | ID: %d | LevelID: %s | Locked: %s", name, id, instanceID, lockedState))
    end
    print("Debug: Current Character Order")
    local charList = {}
    for charName, _ in pairs(LMAHI_SavedData.characters) do
        table.insert(charList, charName)
    end
    table.sort(charList, function(a, b)
        local aIndex = LMAHI_SavedData.charOrder[a] or 0
        local bIndex = LMAHI_SavedData.charOrder[b] or 0
        if aIndex == bIndex then
            return a < b
        end
        return aIndex < bIndex
    end)
    for i, charName in ipairs(charList) do
        print(string.format("%s: Order %d", charName, LMAHI_SavedData.charOrder[charName] or 0))
    end
    print("Debug: Custom Lockouts")
    local customList = {}
    for _, lockout in ipairs(LMAHI.lockoutData.custom) do
        table.insert(customList, lockout)
    end
    table.sort(customList, function(a, b)
        local aIndex = LMAHI_SavedData.customLockoutOrder[tostring(a.id)] or 999
        local bIndex = LMAHI_SavedData.customLockoutOrder[tostring(b.id)] or 1010
        if aIndex == bIndex then
            return a.id < b
        end
        return aIndex < bIndex
    end)
    for _, lockout in ipairs(customList) do
        print(string.format("Name: %s | ID: %d | Reset: %s | Order: %d", lockout.name, lockout.id, lockout.reset, LMAHI_SavedData.customLockoutOrder[tostring(lockout.id)] or 0))
    end
end

-- Expose frames to addon namespace for access in other files
LMAHI.mainFrame = mainFrame
LMAHI.charFrame = charFrame
LMAHI.lockoutScrollFrame = lockoutScrollFrame
LMAHI.lockoutContent = lockoutContent
LMAHI.settingsFrame = settingsFrame
LMAHI.customInputFrame = customInputFrame
LMAHI.highlightLine = highlightLine
LMAHI.highlightFrame = highlightFrame
LMAHI.charListScrollFrame = charListScrollFrame
LMAHI.charListContent = charListContent
LMAHI.customInputScrollFrame = customInputScrollFrame
LMAHI.customInputScrollContent = customInputScrollContent
LMAHI.sectionHeaders = sectionHeaders
LMAHI.lockoutLabels = lockoutLabels
LMAHI.collapseButtons = collapseButtons