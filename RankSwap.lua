local addonName, ns = ...

-- Initialize SavedVariables table to remember LibDBIcon position
RankSwapDB = RankSwapDB or { profile = { minimap = { hide = false } } }

local frame = CreateFrame("Frame")
frame:RegisterEvent("TRAINER_CLOSED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")

local function GetHighestSpellRankID(spellId)
    local spellName = C_Spell.GetSpellName(spellId)
    if not spellName then return nil end

    local highestId = spellId
    local numTabs = C_SpellBook.GetNumSpellBookSkillLines() or 0
    for tabIndex = 1, numTabs do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(tabIndex)
        if skillLineInfo then
            local offset = skillLineInfo.itemIndexOffset or 0
            local numSpells = skillLineInfo.numSpellBookItems or 0
            for i = 1, numSpells do
                local index = offset + i
                local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(index, Enum.SpellBookSpellBank.Player)
                if spellBookItemInfo and spellBookItemInfo.spellID then
                    local bookSpellName = C_Spell.GetSpellName(spellBookItemInfo.spellID)
                    if bookSpellName == spellName then
                        highestId = spellBookItemInfo.spellID
                    end
                end
            end
        end
    end
    return highestId
end

local function GetFormattedSpellName(spellId)
    local name = C_Spell.GetSpellName(spellId)
    if not name then return "Unknown Spell" end
    
    local subtext = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellId)
    if subtext and subtext ~= "" then
        return string.format("%s (%s)", name, subtext)
    end
    return name
end

local function ScanAndSwapActionBars()
    print("|cff00ff00[RankSwap]:|r Scanning action bars for outdated spell ranks...")
    local updatedCount = 0

    for slot = 1, 120 do
        local actionType, id, subType = GetActionInfo(slot)
        if actionType == "spell" and id then
            local highestId = GetHighestSpellRankID(id)
            if highestId and highestId ~= id then
                local oldName = GetFormattedSpellName(id)
                local newName = GetFormattedSpellName(highestId)
                
                C_Spell.PickupSpell(highestId)
                PlaceAction(slot)
                ClearCursor()
                
                updatedCount = updatedCount + 1
                
                local barNum = math.floor((slot - 1) / 12) + 1
                local btnNum = ((slot - 1) % 12) + 1
                
                print(string.format("|cff00ff00[RankSwap]:|r Updated Bar %d, Button %d from %s to %s.", barNum, btnNum, oldName, newName))
            end
        end
    end
    
    if updatedCount == 0 then
        print("|cff00ff00[RankSwap]:|r Scan complete. All action bar spells are already at maximum rank.")
    else
        print(string.format("|cff00ff00[RankSwap]:|r Finished! Upgraded %d action bar slot(s).", updatedCount))
    end
end

-- ==========================================
-- HUNTER AMMO CHECKER & POPUP MODULE
-- ==========================================

local lastNotifiedTier = 0 -- 0: Normal, 1: Warned (<200), 2: Critical (<50)

-- Create a lightweight, reusable popup alert frame
local ammoPopup = CreateFrame("Frame", "RankSwapAmmoPopup", UIParent, "BasicFrameTemplateWithInset")
ammoPopup:SetSize(320, 130)
ammoPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
ammoPopup:SetMovable(true)
ammoPopup:EnableMouse(true)
ammoPopup:RegisterForDrag("LeftButton")
ammoPopup:SetScript("OnDragStart", ammoPopup.StartMoving)
ammoPopup:SetScript("OnDragStop", ammoPopup.StopMovingOrSizing)
ammoPopup:Hide()

ammoPopup.title = ammoPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ammoPopup.title:SetPoint("TOP", ammoPopup, "TOP", 0, -6)
ammoPopup.title:SetText("|cffff0000RankSwap: Ammo Alert!|r")

ammoPopup.text = ammoPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ammoPopup.text:SetPoint("TOPLEFT", ammoPopup, "TOPLEFT", 16, -35)
ammoPopup.text:SetPoint("BOTTOMRIGHT", ammoPopup, "BOTTOMRIGHT", -16, 40)
ammoPopup.text:SetJustifyH("CENTER")
ammoPopup.text:SetWordWrap(true)

local closeButton = CreateFrame("Button", nil, ammoPopup, "GameMenuButtonTemplate")
closeButton:SetSize(100, 25)
closeButton:SetPoint("BOTTOM", ammoPopup, "BOTTOM", 0, 10)
closeButton:SetText("Dismiss")
closeButton:SetScript("OnClick", function()
    ammoPopup:Hide()
end)

local function CheckHunterAmmo()
    local _, englishClass = UnitClass("player")
    if englishClass ~= "HUNTER" then return end

    local totalAmmoCount = 0

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                local _, _, _, _, _, _, itemSubType = C_Item.GetItemInfo(itemInfo.hyperlink)
                if itemSubType == "Arrow" or itemSubType == "Bullet" then
                    totalAmmoCount = totalAmmoCount + itemInfo.stackCount
                end
            end
        end
    end

    -- Determine current tier
    local currentTier = 0
    if totalAmmoCount > 0 and totalAmmoCount < 50 then
        currentTier = 2 -- Critical
    elseif totalAmmoCount >= 50 and totalAmmoCount < 200 then
        currentTier = 1 -- Warning
    else
        lastNotifiedTier = 0 -- Reset if restocked above 200
        ammoPopup:Hide()
        return
    end

    -- Only notify if we cross into a worse tier
    if currentTier > lastNotifiedTier then
        lastNotifiedTier = currentTier
        
        if currentTier == 2 then
            local msg = string.format("CRITICAL AMMO WARNING!\nYou only have %d arrows/bullets left! Restock immediately!", totalAmmoCount)
            print(string.format("|cffff0000[RankSwap]:|r %s", msg))
            ammoPopup.text:SetText(string.format("|cffff0000Only %d arrows/bullets remaining!|r\nRestock before entering combat!", totalAmmoCount))
            ammoPopup:Show()
        elseif currentTier == 1 then
            local msg = string.format("Low ammo detected! Only %d arrows/bullets remaining.", totalAmmoCount)
            print(string.format("|cffffaa00[RankSwap]:|r %s", msg))
            ammoPopup.text:SetText(string.format("|cffffaa00Low Ammo Alert:|r You have %d arrows/bullets left.", totalAmmoCount))
            ammoPopup:Show()
        end
    end
end

-- Debounce flag to prevent double-scanning
local isScanning = false

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
        local dbIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
        
        if LDB and dbIcon then
            local rankSwapLDB = LDB:NewDataObject("RankSwap", {
                type = "data source",
                text = "RankSwap",
                icon = "Interface\\Icons\\Spell_Nature_Regeneration",
                OnClick = function(self, button)
                    if button == "RightButton" then
                        print("|cff00ff00[RankSwap]:|r Use left-click to manually scan action bars.")
                    else
                        ScanAndSwapActionBars()
                    end
                end,
                OnEnter = function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    GameTooltip:SetText("RankSwap", 1, 1, 1)
                    GameTooltip:AddLine("Will automatically update your action bar spells to the highest learned rank when closing a class trainer.", 0.8, 0.8, 0.8, true)
                    GameTooltip:AddLine(" ", 1, 1, 1)
                    GameTooltip:AddLine("|cff00ff00Left-Click:|r Scan action bars now", 0.2, 1, 0.2)
                    GameTooltip:Show()
                end,
                OnLeave = function(self)
                    GameTooltip:Hide()
                end,
            })
            dbIcon:Register("RankSwap", rankSwapLDB, RankSwapDB.profile.minimap)
        end
        
        C_Timer.After(2.0, CheckHunterAmmo)
        
    elseif event == "TRAINER_CLOSED" then
        if not isScanning then
            isScanning = true
            C_Timer.After(0.3, function()
                ScanAndSwapActionBars()
                -- Reset the lock after a brief moment
                C_Timer.After(1.0, function()
                    isScanning = false
                end)
            end)
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        CheckHunterAmmo()
    end
end)
-- ==========================================
-- ADDON COMPARTMENT HOOKS
-- ==========================================

function RankSwap_OnAddonCompartmentClick(addonName, mouseButton)
    if mouseButton == "RightButton" then
        print("|cff00ff00[RankSwap]:|r Use left-click to manually scan action bars.")
    else
        ScanAndSwapActionBars()
    end
end

function RankSwap_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("RankSwap", 1, 1, 1)
    GameTooltip:AddLine("Automatically updates your action bar spells to the highest learned rank when closing a class trainer.", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Scan action bars now", 0.2, 1, 0.2)
    GameTooltip:Show()
end

function RankSwap_OnAddonCompartmentLeave(addonName, button)
    GameTooltip:Hide()
end

-- Slash command to force a test scan manually (/rs)
_G["SLASH_RANKSWAP1"] = "/rs"
SlashCmdList["RANKSWAP"] = function(msg)
    ScanAndSwapActionBars()
end