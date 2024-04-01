local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable

local Energy
local EnergyMax
local EnergyDeficit
local EnergyRegen
local EnergyRegenCombined
local EnergyTimeToMax
local EnergyPerc
local ComboPoints
local ComboPointsMax
local ComboPointsDeficit
local PoisonedBleeds
local DanseMacabreSpellList

local Subtlety = {}

local algethar_puzzle_box_precombat_cast
local snd_condition
local priority_rotation
local stealth_threshold
local stealth_helper
local trinket_conditions
local racial_sync
local secret_condition
local premed_snd_condition
local skip_rupture
local shd_threshold
local rotten_cb
local shd_combo_points

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then print('no cost found for ',spellstring) return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = GetItemInfo(tOneitemID)
        local tTwoitemName = GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local echoingReprimand = {
	auras = {
		{
			id = 323558,
			cp = 2
		},
		{
			id = 323559,
			cp = 3
		},
		{
			id = 323560,
			cp = 4
		},
		{
			id = 354835,
			cp = 5
		}
	}
}


local echoingReprimandUp = function(comboPoints)
	local buff = MaxDps.FrameData.buff
	for i in pairs(echoingReprimand.auras) do
		local aura = echoingReprimand.auras[i]
		if buff[aura.id].up and aura.cp == comboPoints then
			return aura
		end
	end
	return false
end


local function calculateEffectiveComboPoints(comboPoints)
	if comboPoints > 1 and comboPoints < 6 then
		local aura = echoingReprimandUp(comboPoints)
		if aura then
			return MaxDps.FrameData.cpMaxSpend
		end
	end
	return comboPoints
end


local function CheckDanseMacabre(spell)
	return false
end

function Subtlety:build()
    if (MaxDps:FindSpell(classtable.ShurikenStorm) and CheckSpellCosts(classtable.ShurikenStorm, 'ShurikenStorm')) and (targets >= 2 + ( (talents[classtable.Gloomblade] and 1 or 0) and (buff[classtable.LingeringShadowBuff].remains >= 6 and 1 or 0) or (buff[classtable.PerforatedVeinsBuff].up and 1 or 0) )) and cooldown[classtable.ShurikenStorm].ready then
        return classtable.ShurikenStorm
    end
    if (MaxDps:FindSpell(classtable.Gloomblade) and CheckSpellCosts(classtable.Gloomblade, 'Gloomblade')) and cooldown[classtable.Gloomblade].ready then
        return classtable.Gloomblade
    end
    if (MaxDps:FindSpell(classtable.Backstab) and CheckSpellCosts(classtable.Backstab, 'Backstab')) and cooldown[classtable.Backstab].ready then
        return classtable.Backstab
    end
end
function Subtlety:cds()
    trinket_conditions = ( not CheckEquipped('WitherbarksBranch') and not CheckEquipped('AshesoftheEmbersoul') or not CheckEquipped('WitherbarksBranch') and CheckTrinketCooldown('Witherbarks Branch') <= 8 or CheckEquipped('WitherbarksBranch') and CheckTrinketCooldown('Witherbarks Branch') <= 8 or CheckEquipped('BandolierofTwistedBlades') or talents[classtable.InvigoratingShadowdust] )
    if (MaxDps:FindSpell(classtable.ColdBlood) and CheckSpellCosts(classtable.ColdBlood, 'ColdBlood')) and (not talents[classtable.SecretTechnique] and ComboPoints >= 5) and cooldown[classtable.ColdBlood].ready then
        return classtable.ColdBlood
    end
    if (MaxDps:FindSpell(classtable.Sepsis) and CheckSpellCosts(classtable.Sepsis, 'Sepsis')) and (snd_condition and ttd >= 16 and ( buff[classtable.PerforatedVeinsBuff].up or not talents[classtable.PerforatedVeins] )) and cooldown[classtable.Sepsis].ready then
        return classtable.Sepsis
    end
    if (MaxDps:FindSpell(classtable.Flagellation) and CheckSpellCosts(classtable.Flagellation, 'Flagellation')) and (snd_condition and ComboPoints >= 5 and ttd >10 and ( trinket_conditions and cooldown[classtable.ShadowBlades].remains <= 3 or ttd <= 28 or cooldown[classtable.ShadowBlades].remains >= 14 and talents[classtable.InvigoratingShadowdust] and talents[classtable.ShadowDance] ) and ( not talents[classtable.InvigoratingShadowdust] or talents[classtable.Sepsis] or not talents[classtable.ShadowDance] or talents[classtable.InvigoratingShadowdust] == 2 and targets >= 2 or cooldown[classtable.SymbolsofDeath].remains <= 3 or buff[classtable.SymbolsofDeathBuff].remains >3 ) and ttd) and cooldown[classtable.Flagellation].ready then
        return classtable.Flagellation
    end
    if (MaxDps:FindSpell(classtable.SymbolsofDeath) and CheckSpellCosts(classtable.SymbolsofDeath, 'SymbolsofDeath')) and (snd_condition and ( not buff[classtable.theRottenBuff].up or not (MaxDps.tier and MaxDps.tier[30].count >= 2) ) and buff[classtable.SymbolsofDeathBuff].remains <= 3 and ( not talents[classtable.Flagellation] or cooldown[classtable.Flagellation].remains >10 or buff[classtable.ShadowDanceBuff].remains >= 2 and talents[classtable.InvigoratingShadowdust] or cooldown[classtable.Flagellation].up and ComboPoints >= 5 and not talents[classtable.InvigoratingShadowdust] )) and cooldown[classtable.SymbolsofDeath].ready then
        return classtable.SymbolsofDeath
    end
    if (MaxDps:FindSpell(classtable.ShadowBlades) and CheckSpellCosts(classtable.ShadowBlades, 'ShadowBlades')) and (snd_condition and ( ComboPoints <= 1 or (MaxDps.tier and MaxDps.tier[31].count >= 4) ) and ( buff[classtable.FlagellationBuffBuff].up or buff[classtable.FlagellationPersistBuff].up or not talents[classtable.Flagellation] )) and cooldown[classtable.ShadowBlades].ready then
        return classtable.ShadowBlades
    end
    if (MaxDps:FindSpell(classtable.EchoingReprimand) and CheckSpellCosts(classtable.EchoingReprimand, 'EchoingReprimand')) and (snd_condition and ComboPointsDeficit >= 3) and cooldown[classtable.EchoingReprimand].ready then
        return classtable.EchoingReprimand
    end
    if (MaxDps:FindSpell(classtable.ShurikenTornado) and CheckSpellCosts(classtable.ShurikenTornado, 'ShurikenTornado')) and (snd_condition and buff[classtable.SymbolsofDeathBuff].up and ComboPoints <= 2 and not buff[classtable.PremeditationBuff].up and ( not talents[classtable.Flagellation] or cooldown[classtable.Flagellation].remains >20 ) and targets >= 3) and cooldown[classtable.ShurikenTornado].ready then
        return classtable.ShurikenTornado
    end
    if (MaxDps:FindSpell(classtable.ShurikenTornado) and CheckSpellCosts(classtable.ShurikenTornado, 'ShurikenTornado')) and (snd_condition and not buff[classtable.ShadowDanceBuff].up and not buff[classtable.FlagellationBuffBuff].up and not buff[classtable.FlagellationPersistBuff].up and not buff[classtable.ShadowBladesBuff].up and targets <= 2 and not (targets >1)) and cooldown[classtable.ShurikenTornado].ready then
        return classtable.ShurikenTornado
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance')) and (not buff[classtable.ShadowDanceBuff].up and ttd <= 8 + (talents[classtable.Subterfuge] and 1 or 0)) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.GoremawsBite) and CheckSpellCosts(classtable.GoremawsBite, 'GoremawsBite')) and (snd_condition and ComboPointsDeficit >= 3 and ( not cooldown[classtable.ShadowDance].up or talents[classtable.ShadowDance] and buff[classtable.ShadowDanceBuff].up and not talents[classtable.InvigoratingShadowdust] or targets <4 and not talents[classtable.InvigoratingShadowdust] or talents[classtable.theRotten] or targets >1 )) and cooldown[classtable.GoremawsBite].ready then
        return classtable.GoremawsBite
    end
    if (MaxDps:FindSpell(classtable.ThistleTea) and CheckSpellCosts(classtable.ThistleTea, 'ThistleTea')) and (( cooldown[classtable.SymbolsofDeath].remains >= 3 or buff[classtable.SymbolsofDeathBuff].up ) and not buff[classtable.ThistleTeaBuff].up and ( EnergyDeficit >= ( 100 ) and ( ComboPointsDeficit >= 2 or targets >= 3 ) or ( cooldown[classtable.ThistleTea].charges >= ( 2.75 - 0.15 * (talents[classtable.InvigoratingShadowdust] and 1 or 0) and cooldown[classtable.Vanish].up ) ) and buff[classtable.ShadowDanceBuff].up and debuff[classtable.RuptureDeBuff].up and targets <3 ) or buff[classtable.ShadowDanceBuff].remains >= 4 and not buff[classtable.ThistleTeaBuff].up and targets >= 3 or not buff[classtable.ThistleTeaBuff].up and ttd <= ( 6 * cooldown[classtable.ThistleTea].charges )) and cooldown[classtable.ThistleTea].ready then
        return classtable.ThistleTea
    end
    if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (MaxDps:Bloodlust() or ttd <30 or buff[classtable.SymbolsofDeathBuff].up and ( buff[classtable.ShadowBladesBuff].up or cooldown[classtable.ShadowBlades].remains <= 10 )) and cooldown[classtable.Potion].ready then
        return classtable.Potion
    end
    racial_sync = buff[classtable.ShadowBladesBuff].up or not talents[classtable.ShadowBlades] and buff[classtable.SymbolsofDeathBuff].up or ttd <20
end
function Subtlety:finish()
    secret_condition = ( CheckDanseMacabre(classtable.Shadowstrike) or CheckDanseMacabre(classtable.ShurikenStorm) ) and ( CheckDanseMacabre(classtable.Eviscerate) or CheckDanseMacabre(classtable.BlackPowder) or CheckDanseMacabre(classtable.Rupture) ) or not talents[classtable.DanseMacabre]
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (not debuff[classtable.RuptureDeBuff].up and ttd - debuff[classtable.Rupture].remains >6) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    premed_snd_condition = talents[classtable.Premeditation] and targets <5
    if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and not premed_snd_condition and targets <6 and not buff[classtable.ShadowDanceBuff].up and buff[classtable.SliceandDiceBuff].remains <ttd and buff[classtable.SliceandDice].refreshable) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    skip_rupture = buff[classtable.ThistleTeaBuff].up and targets == 1 or buff[classtable.ShadowDanceBuff].up and ( targets == 1 or debuff[classtable.RuptureDeBuff].up and targets >= 2 )
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (( not skip_rupture ) and ttd - debuff[classtable.Rupture].remains >6 and debuff[classtable.Rupture].refreshable) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (buff[classtable.FinalityRuptureBuff].up and buff[classtable.ShadowDanceBuff].up and targets <= 4 and not CheckDanseMacabre(classtable.Rupture)) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.ColdBlood) and CheckSpellCosts(classtable.ColdBlood, 'ColdBlood')) and (secret_condition and cooldown[classtable.SecretTechnique].ready) and cooldown[classtable.ColdBlood].ready then
        return classtable.ColdBlood
    end
    if (MaxDps:FindSpell(classtable.SecretTechnique) and CheckSpellCosts(classtable.SecretTechnique, 'SecretTechnique')) and (secret_condition and ( not talents[classtable.ColdBlood] or cooldown[classtable.ColdBlood].remains >buff[classtable.ShadowDanceBuff].remains - 2 or not talents[classtable.ImprovedShadowDance] )) and cooldown[classtable.SecretTechnique].ready then
        return classtable.SecretTechnique
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (not skip_rupture and targets >= 2 and ttd >= ( 2 * ComboPoints ) and debuff[classtable.Rupture].refreshable) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (not skip_rupture and debuff[classtable.Rupture].remains <cooldown[classtable.SymbolsofDeath].remains + 10 and cooldown[classtable.SymbolsofDeath].remains <= 5 and ttd - debuff[classtable.Rupture].remains >cooldown[classtable.SymbolsofDeath].remains + 5) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.BlackPowder) and CheckSpellCosts(classtable.BlackPowder, 'BlackPowder')) and (targets >= 3) and cooldown[classtable.BlackPowder].ready then
        return classtable.BlackPowder
    end
    if (MaxDps:FindSpell(classtable.Eviscerate) and CheckSpellCosts(classtable.Eviscerate, 'Eviscerate')) and cooldown[classtable.Eviscerate].ready then
        return classtable.Eviscerate
    end
end
function Subtlety:stealth_cds()
    shd_threshold = cooldown[classtable.ShadowDance].charges >= 0.75 + (talents[classtable.ShadowDance] and 1 or 0)
    rotten_cb = ( not buff[classtable.theRottenBuff].up or not (MaxDps.tier and MaxDps.tier[30].count >= 2) ) and ( not talents[classtable.ColdBlood] or cooldown[classtable.ColdBlood].remains <4 or cooldown[classtable.ColdBlood].remains >10 )
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (( ComboPointsDeficit >1 or buff[classtable.ShadowBladesBuff].up and talents[classtable.InvigoratingShadowdust] ) and not shd_threshold and ( cooldown[classtable.Flagellation].remains >= 60 or not talents[classtable.Flagellation] or ttd <= ( 30 * cooldown[classtable.Vanish].charges ) ) and ( cooldown[classtable.SymbolsofDeath].remains >3 or not (MaxDps.tier and MaxDps.tier[30].count >= 2) ) and ( cooldown[classtable.SecretTechnique].remains >= 10 or not talents[classtable.SecretTechnique] or cooldown[classtable.Vanish].charges >= 2 and talents[classtable.InvigoratingShadowdust] and ( buff[classtable.theRottenBuff].up or not talents[classtable.theRotten] ) and not (targets >1) )) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    --if (MaxDps:FindSpell(classtable.PoolResource) and CheckSpellCosts(classtable.PoolResource, 'PoolResource')) and (CheckRace('night_elf')) and cooldown[classtable.PoolResource].ready then
    --    return classtable.PoolResource
    --end
    if (MaxDps:FindSpell(classtable.Shadowmeld) and CheckSpellCosts(classtable.Shadowmeld, 'Shadowmeld')) and (Energy >= 40 and EnergyDeficit >= 10 and not shd_threshold and ComboPointsDeficit >4) and cooldown[classtable.Shadowmeld].ready then
        return classtable.Shadowmeld
    end
    shd_combo_points = ComboPointsDeficit >= 3
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance')) and (( debuff[classtable.RuptureDeBuff].up or talents[classtable.InvigoratingShadowdust] ) and rotten_cb and ( not talents[classtable.theFirstDance] or ComboPointsDeficit >= 4 or buff[classtable.ShadowBladesBuff].up ) and ( shd_combo_points and shd_threshold or ( buff[classtable.ShadowBladesBuff].up or cooldown[classtable.SymbolsofDeath].up and not talents[classtable.Sepsis] or buff[classtable.SymbolsofDeathBuff].remains >= 4 and not (MaxDps.tier and MaxDps.tier[30].count >= 2) or not buff[classtable.SymbolsofDeathBuff].up and (MaxDps.tier and MaxDps.tier[30].count >= 2) ) and cooldown[classtable.SecretTechnique].remains <10 + 12 * ( (talents[classtable.InvigoratingShadowdust] and 1 or 0) or (MaxDps.tier and MaxDps.tier[30].count >= 2 and 1 or 0) ) )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
end
function Subtlety:stealthed()
    if (MaxDps:FindSpell(classtable.Shadowstrike) and CheckSpellCosts(classtable.Shadowstrike, 'Shadowstrike')) and (buff[classtable.StealthBuff].up and ( targets <4 )) and cooldown[classtable.Shadowstrike].ready then
        return classtable.Shadowstrike
    end
    if (calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (buff[classtable.ShurikenTornadoBuff].up and ComboPointsDeficit <= 2) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (ComboPointsDeficit <= 1 + ( (talents[classtable.DeeperStratagem] and 1 or 0) or (talents[classtable.SecretStratagem]) and 1 or 0)) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (MaxDps:FindSpell(classtable.Backstab) and CheckSpellCosts(classtable.Backstab, 'Backstab')) and (not buff[classtable.PremeditationBuff].up and buff[classtable.ShadowDanceBuff].remains >= 3 and buff[classtable.ShadowBladesBuff].up and not CheckDanseMacabre(classtable.Backstab) and talents[classtable.DanseMacabre] and targets <= 3 and not buff[classtable.theRottenBuff].up) and cooldown[classtable.Backstab].ready then
        return classtable.Backstab
    end
    if (MaxDps:FindSpell(classtable.Gloomblade) and CheckSpellCosts(classtable.Gloomblade, 'Gloomblade')) and (not buff[classtable.PremeditationBuff].up and buff[classtable.ShadowDanceBuff].remains >= 3 and buff[classtable.ShadowBladesBuff].up and not CheckDanseMacabre(classtable.Gloomblade) and talents[classtable.DanseMacabre] and targets <= 4) and cooldown[classtable.Gloomblade].ready then
        return classtable.Gloomblade
    end
    if (MaxDps:FindSpell(classtable.Shadowstrike) and CheckSpellCosts(classtable.Shadowstrike, 'Shadowstrike')) and (not CheckDanseMacabre(classtable.Shadowstrike) and buff[classtable.ShadowBladesBuff].up) and cooldown[classtable.Shadowstrike].ready then
        return classtable.Shadowstrike
    end
    if (MaxDps:FindSpell(classtable.ShurikenStorm) and CheckSpellCosts(classtable.ShurikenStorm, 'ShurikenStorm')) and (not buff[classtable.PremeditationBuff].up and targets >= 4) and cooldown[classtable.ShurikenStorm].ready then
        return classtable.ShurikenStorm
    end
    if (MaxDps:FindSpell(classtable.Shadowstrike) and CheckSpellCosts(classtable.Shadowstrike, 'Shadowstrike')) and cooldown[classtable.Shadowstrike].ready then
        return classtable.Shadowstrike
    end
end

function Rogue:Subtlety()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyRegen = GetPowerRegenForPowerType(Enum.PowerType.Energy)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    EnergyPerc = (Energy / EnergyMax) * 100
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    classtable.LingeringShadowBuff = 385960
    classtable.PerforatedVeinsBuff = 394254
    classtable.SymbolsofDeathBuff = 212283
    classtable.theRottenBuff = 394203
    classtable.ShadowDanceBuff = 185422
    classtable.FlagellationBuffBuff = 394758
    classtable.FlagellationPersistBuff = 384631
    classtable.PremeditationBuff = 343173
    classtable.ShadowBladesBuff = 121471
    classtable.ThistleTeaBuff = 381623
    classtable.RuptureDeBuff = 1943
    classtable.SliceandDiceBuff = 315496
    classtable.FinalityRuptureBuff = 385951
    classtable.StealthBuff = 115191
    classtable.ShurikenTornadoBuff = 277925
    --PreCombatUpdate()

    --if (MaxDps:FindSpell(classtable.Stealth) and CheckSpellCosts(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
    --    return classtable.Stealth
    --end
    --if (MaxDps:FindSpell(classtable.Kick) and CheckSpellCosts(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
    --    return classtable.Kick
    --end
    snd_condition = buff[classtable.SliceandDiceBuff].up or targets >= ComboPointsMax
    local cdsCheck = Subtlety:cds()
    if cdsCheck then
        return cdsCheck
    end
    if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and (targets <ComboPointsMax and buff[classtable.SliceandDiceBuff].remains <gcd and ttd >6 and ComboPoints >= 4) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up)) then
        local stealthedCheck = Subtlety:stealthed()
        if stealthedCheck then
            if buff[classtable.ShadowDanceBuff].up and MaxDps.spellHistory[1] then
                if talents[classtable.DanseMacabre] and not DanseMacabreSpellList then DanseMacabreSpellList = {} end
                table.insert(DanseMacabreSpellList,table.getn(DanseMacabreSpellList)+1,MaxDps.spellHistory[1])
            else
                DanseMacabreSpellList = {}
            end
            return Subtlety:stealthed()
        end
    end
    --priority_rotation = TODO
    stealth_threshold = 20 + (talents[classtable.Vigor] and 1 or 0) * 25 + (talents[classtable.ThistleTea] and 1 or 0) * 20 + (talents[classtable.Shadowcraft] and 1 or 0) * 20
    stealth_helper = Energy >= stealth_threshold
    if not talents[classtable.Vigor] or talents[classtable.Shadowcraft] then
        stealth_helper = EnergyDeficit <= stealth_threshold
    end
    if (stealth_helper or talents[classtable.InvigoratingShadowdust]) then
        local stealth_cdsCheck = Subtlety:stealth_cds()
        if stealth_cdsCheck then
            return Subtlety:stealth_cds()
        end
    end
    if (calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (ComboPointsDeficit <= 1 or ttd <= 1 and calculateEffectiveComboPoints(ComboPoints) >= 3) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (targets >= 4 and calculateEffectiveComboPoints(ComboPoints) >= 4) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (EnergyDeficit <= stealth_threshold) then
        local buildCheck = Subtlety:build()
        if buildCheck then
            return Subtlety:build()
        end
    end
    if (MaxDps:FindSpell(classtable.ArcanePulse) and CheckSpellCosts(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        return classtable.ArcanePulse
    end
    if (calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (buff[classtable.ShurikenTornadoBuff].up and ComboPointsDeficit <= 2) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end
    if (ComboPointsDeficit <= 1 + ( (talents[classtable.DeeperStratagem] and 1 or 0) or (talents[classtable.SecretStratagem]) and 1 or 0)) then
        local finishCheck = Subtlety:finish()
        if finishCheck then
            return Subtlety:finish()
        end
    end

end
