local frame = CreateFrame("Frame")
local function Send(msg)
  if IsInGroup() then
    local group = "INSTANCE_CHAT"
    if IsInRaid() then group = "RAID" end
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then group = "PARTY" end
    SendChatMessage(msg, group)
  else
    print(msg);
  end
end
local function ShareSpellCooldown(spellID)
  if spellID then
    local spellLink = C_Spell.GetSpellLink(spellID)
    local spellCooldown = C_Spell.GetSpellCooldown(spellID)
    -- local isSpellKnown = IsPlayerSpell(spellID)
    if spellCooldown and spellCooldown.startTime and spellCooldown.duration > 0 then
      local remaining = spellCooldown.startTime + spellCooldown.duration - GetTime()
      Send(string.format("Cooldown of %s: %.1f seconds remaining", spellLink, remaining))
    -- elseif spellLink and isSpellKnown == false then
      -- Send(string.format("Spell not known - %s", spellLink))    
    elseif spellLink then
      Send(string.format("Ready to cast %s", spellLink))
    else
      Send(string.format("unk error on spell %s", spellID))    
    end
  end
end
local function ShareBuffInfo(auraData)
  if auraData and auraData.spellId then
    local spellLink = C_Spell.GetSpellLink(auraData.spellId)  
    if auraData.duration and auraData.duration > 0 then
        Send(string.format("Buffed with %s: %.1f seconds remaining", spellLink, auraData.expirationTime - GetTime()))
    else
        Send(string.format("Buffed with %s", spellLink))
    end
  end
end
local function ShareItemCooldown(item)
  local start, duration, enable = GetItemCooldown(item)
  if start and duration then
    local remainingCD = start + duration - GetTime();
    local itemName, itemLink = C_Item.GetItemInfo(item)
    if remainingCD < 0 then
      Send(string.format("Ready to use %s", itemLink))
    else
      Send(string.format("Cooldown of %s: %.1f seconds remaining", itemLink, remainingCD))
    end
  end  
end
local function ShareBuff(auraId, unit)
  for _, auraType in ipairs({"HELPFUL", "HARMFUL"}) do
    for i=1,100 do
      local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, auraType);
      if auraData and auraData.auraInstanceID == auraId then
          local unitLink = string.format("|cffffff00|Hunit:%s|h[%s]|h|r", UnitGUID(unit), UnitName(unit))
          local spellLink = C_Spell.GetSpellLink(auraData.spellId)  
          if auraData.duration and auraData.duration > 0 then
              Send(string.format("%s Buffed with %s: %.1f seconds remaining", unitLink, spellLink, auraData.expirationTime - GetTime()))
          else
              Send(string.format("%s Buffed with %s", unitLink, spellLink))
          end
      end
    end
  end
end
local function ShareCooldown()
  local owner = GameTooltip:GetOwner()
  if owner and owner.auraType then
    local buffType = 'HARMFUL'
    if owner.auraType == 'Buff' then buffType = 'HELPFUL' end
    local auraData = C_UnitAuras.GetAuraDataByIndex('player', owner.buttonInfo.index, buffType);
    ShareBuffInfo(auraData)
  elseif owner and owner.action and owner:GetName() and owner:GetName():find("Button") then
    local actionType, id = GetActionInfo(owner.action);
    if actionType == "spell" then
      local spellName, spellID = GameTooltip:GetSpell()
      ShareSpellCooldown(spellID)
    elseif actionType == "macro" then
      ShareSpellCooldown(id)
    elseif actionType == "item" then
      ShareItemCooldown(id)
    else
      print(actionType);
    end
  elseif owner and owner.unit then
    ShareBuff(owner.auraInstanceID, owner.unit)
  end
end

local isCtrlPressed = false
frame:SetScript("OnUpdate", function(self)
  if IsControlKeyDown() and not isCtrlPressed then
    isCtrlPressed = true
    ShareCooldown()
  elseif not IsControlKeyDown() then
    isCtrlPressed = false
  end
end)

frame:Show()