-- Title: TargetFrameBuff v0.5 (patched for 32 buffs/debuffs + grid)
-- Notes: Shows up to 32 Buffs & Debuffs on a Target in 8x4 grid
-- Author: lua@lumpn.de (patched by Grok)

local lOriginal_TargetDebuffButton_Update = nil;
local TARGETFRAMEBUFF_MAX_TARGET_DEBUFFS = 32;
local TARGETFRAMEBUFF_MAX_TARGET_BUFFS = 32;

local ICON_SIZE = 24;       -- размер иконок (можно изменить)
local SPACING_H = 3;        -- горизонтальный отступ
local SPACING_V = 2;        -- вертикальный отступ
local ICONS_PER_ROW = 8;    -- иконок в ряду (8x4 = 32)

-- Функция позиционирования группы (баффы или дебаффы) в гриде
local function PositionGroup(prefix, num, startX, startY)
    for i = 1, num do
        local button = getglobal(prefix .. i);
        if (button) then
            button:ClearAllPoints();
            local row = math.floor((i - 1) / ICONS_PER_ROW);
            local col = (i - 1) % ICONS_PER_ROW;
            local x = startX + col * (ICON_SIZE + SPACING_H);
            local y = startY - row * (ICON_SIZE + SPACING_V);
            button:SetPoint("TOPLEFT", "TargetFrame", "BOTTOMLEFT", x, y);
        end
    end
end

-- hook original update-function
function TargetFrameBuff_OnLoad()
    lOriginal_TargetDebuffButton_Update = TargetDebuffButton_Update;
    TargetDebuffButton_Update = TargetFrameBuff_Update;
    
    lOriginal_TargetDebuffButton_Update()
    TargetFrameBuff_Restore();
end

-- use extended update-function
function TargetFrameBuff_Update()
    local num_buff = 0;
    local num_debuff = 0;
    local button, buff;
    for i = 1, TARGETFRAMEBUFF_MAX_TARGET_BUFFS do
        buff = UnitBuff("target", i);
        button = getglobal("TargetFrameBuff" .. i);
        if (buff) then
            getglobal("TargetFrameBuff" .. i .. "Icon"):SetTexture(buff);
            button:Show();
            button.id = i;
            num_buff = i;
        else
            if (button) then
                button:Hide();
            end
        end
    end

    local debuff, debuffApplications, debuffCount;
    for i = 1, TARGETFRAMEBUFF_MAX_TARGET_DEBUFFS do
        debuff, debuffApplications = UnitDebuff("target", i);
        button = getglobal("TargetFrameDebuff" .. i);
        if (debuff) then
            debuffCount = getglobal("TargetFrameDebuff" .. i .. "Count");
            if (debuffApplications > 1) then
                debuffCount:SetText(debuffApplications);
                debuffCount:Show();
            else
                debuffCount:Hide();
            end
            getglobal("TargetFrameDebuff" .. i .. "Icon"):SetTexture(debuff);
            button:Show();
            button.id = i;
            num_debuff = i;
        else
            if (button) then
                button:Hide();
            end
        end
    end
    
    -- Позиционирование групп
    local startX = 5;
    local startY = 32;
    if (UnitIsFriend("player", "target")) then
        -- Баффы сверху, дебаффы снизу
        PositionGroup("TargetFrameBuff", num_buff, startX, startY);
        local primary_rows = (num_buff > 0) and (math.floor((num_buff - 1) / ICONS_PER_ROW) + 1) or 0;
        local sec_startY = startY - primary_rows * (ICON_SIZE + SPACING_V);
        PositionGroup("TargetFrameDebuff", num_debuff, startX, sec_startY);
    else
        -- Дебаффы сверху, баффы снизу
        PositionGroup("TargetFrameDebuff", num_debuff, startX, startY);
        local primary_rows = (num_debuff > 0) and (math.floor((num_debuff - 1) / ICONS_PER_ROW) + 1) or 0;
        local sec_startY = startY - primary_rows * (ICON_SIZE + SPACING_V);
        PositionGroup("TargetFrameBuff", num_buff, startX, sec_startY);
    end
end

function TargetFrameBuff_Restore()
    -- Установка размеров для всех иконок
    for i = 1, TARGETFRAMEBUFF_MAX_TARGET_DEBUFFS do
        local button = getglobal("TargetFrameDebuff" .. i);
        local debuffFrame = getglobal("TargetFrameDebuff" .. i .. "Border");
        if (button) then
            button:SetWidth(ICON_SIZE);
            button:SetHeight(ICON_SIZE);
        end
        if (debuffFrame) then
            debuffFrame:SetWidth(ICON_SIZE + 2);
            debuffFrame:SetHeight(ICON_SIZE + 2);
        end
    end
    
    for i = 1, TARGETFRAMEBUFF_MAX_TARGET_BUFFS do
        local button = getglobal("TargetFrameBuff" .. i);
        if (button) then
            button:SetWidth(ICON_SIZE);
            button:SetHeight(ICON_SIZE);
        end
    end
end