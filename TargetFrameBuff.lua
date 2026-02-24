-- TargetFrameBuff.lua v2.1 - Кастомное окошко для баффов цели
-- /tbf toggle / reset / cols 6-12

local frameName = "TargetBuffWindow"
local MAX_BUFFS = 40
local ICON_SIZE_BASE = 24
local SPACING = 3
local cols = 8

local frame, container, titleText
local buffs = {}

local function CreateBuffButton(id)
    local button = CreateFrame("Button", frameName .. "Buff" .. id, container)
    button:SetWidth(ICON_SIZE_BASE)
    button:SetHeight(ICON_SIZE_BASE)
    button:Hide()

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    button.icon = icon

    local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 2)
    count:Hide()
    button.count = count

    button:SetScript("OnEnter", function()
        if UnitExists("target") then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetUnitBuff("target", id)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", GameTooltip.Hide)

    buffs[id] = button
    return button
end

local function UpdateBuffs()
    if not UnitExists("target") then
        for _, b in pairs(buffs) do if b then b:Hide() end end
        return
    end

    local num = 0
    for i = 1, MAX_BUFFS do
        local texture, applications = UnitBuff("target", i)
        local btn = buffs[i] or CreateBuffButton(i)

        if texture then
            btn.icon:SetTexture(texture)
            if applications > 1 then
                btn.count:SetText(applications)
                btn.count:Show()
            else
                btn.count:Hide()
            end
            btn:Show()
            num = i
        else
            btn:Hide()
        end
    end

    -- Репозиционирование
    local w = container:GetWidth()
    local iconSize = math.floor((w + SPACING) / (cols + (cols-1)*SPACING/cols)) -- авто-размер
    local rows = math.ceil(num / cols)

    for i = 1, num do
        local btn = buffs[i]
        btn:SetWidth(iconSize)
        btn:SetHeight(iconSize)
        btn:ClearAllPoints()
        local r = math.floor((i-1)/cols)
        local c = (i-1) % cols
        btn:SetPoint("TOPLEFT", c * (iconSize + SPACING), -r * (iconSize + SPACING))
    end

    container:SetHeight(rows * (iconSize + SPACING) + 10)
end

local function OnLoad()
    frame = CreateFrame("Frame", frameName, UIParent)
    frame:SetSize(240, 140)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = {left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(0,0,0,0.6)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    local header = CreateFrame("Button", nil, frame)
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", -8, -8)
    header:SetHeight(20)
    header:SetScript("OnMouseDown", frame.StartMoving)
    header:SetScript("OnMouseUp", frame.StopMovingOrSizing)

    titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("CENTER")
    titleText:SetText("Target Buffs (cols: "..cols..")")

    container = CreateFrame("Frame", nil, frame)
    container:SetPoint("TOPLEFT", 8, -30)
    container:SetPoint("BOTTOMRIGHT", -8, 8)

    -- Grip resize
    local grip = CreateFrame("Button", nil, frame)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetSize(16,16)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() UpdateBuffs() end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_AURA")
    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_AURA" and unit == "target") then
            UpdateBuffs()
        end
    end)

    -- Слэш-команды
    SLASH_TARGETBUFF1 = "/tbf"
    SlashCmdList["TARGETBUFF"] = function(msg)
        msg = string.lower(msg or "")
        if msg == "toggle" or msg == "" then
            frame:SetShown(not frame:IsShown())
            if frame:IsShown() then UpdateBuffs() end
            print("TargetBuffWindow: " .. (frame:IsShown() and "visible" or "hidden"))
        elseif msg == "reset" then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER")
            frame:SetSize(240, 140)
            cols = 8
            titleText:SetText("Target Buffs (cols: "..cols..")")
            UpdateBuffs()
            print("TargetBuffWindow reset")
        elseif string.match(msg, "^cols %d+$") then
            local n = tonumber(string.match(msg, "%d+"))
            if n and n >= 4 and n <= 12 then
                cols = n
                titleText:SetText("Target Buffs (cols: "..cols..")")
                UpdateBuffs()
                print("Columns set to " .. cols)
            end
        end
    end

    print("|cff88ff88TargetFrameBuff loaded. /tbf toggle / reset / cols 8|r")
    UpdateBuffs()
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == "TargetFrameBuff" then
        OnLoad()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)