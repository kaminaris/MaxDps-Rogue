local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

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
local timeShift
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

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

local Combat = {}



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
	for i in pairs(echoingReprimand.auras) do
		local aura = echoingReprimand.auras[i]
		if buff[aura.id].up and aura.cp == comboPoints then
			return aura.cp
		end
	end
	return false
end


local function calculateEffectiveComboPoints(comboPoints)
	if comboPoints > 1 and comboPoints < 6 then
		local aura = echoingReprimandUp(comboPoints)
		if aura then
			return aura
		end
	end
	return comboPoints
end


function Combat:precombat()
end
function Combat:build()
    if (MaxDps:CheckSpellUsable(classtable.SinisterStrike, 'SinisterStrike')) and (not buff[classtable.SliceandDiceBuff].up and ComboPoints == 0) and cooldown[classtable.SinisterStrike].ready then
        if not setSpell then setSpell = classtable.SinisterStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (not buff[classtable.SliceandDiceBuff].up and ComboPoints >0) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    if (MaxDps:CheckSpellUsable(classtable.AdrenalineRush, 'AdrenalineRush')) and (buff[classtable.SliceandDiceBuff].up) and cooldown[classtable.AdrenalineRush].ready then
        if not setSpell then setSpell = classtable.AdrenalineRush end
    end
    if (MaxDps:CheckSpellUsable(classtable.RevealingStrike, 'RevealingStrike')) and (ComboPoints <3 and not debuff[classtable.RevealingStrikeDeBuff].up and buff[classtable.SliceandDiceBuff].remains >5) and cooldown[classtable.RevealingStrike].ready then
        if not setSpell then setSpell = classtable.RevealingStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Gouge, 'Gouge')) and (ComboPoints == 4 and debuff[classtable.RevealingStrikeDeBuff].up) and cooldown[classtable.Gouge].ready then
        if not setSpell then setSpell = classtable.Gouge end
    end
    if (MaxDps:CheckSpellUsable(classtable.SinisterStrike, 'SinisterStrike')) and (ComboPoints <5) and cooldown[classtable.SinisterStrike].ready then
        if not setSpell then setSpell = classtable.SinisterStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.KillingSpree, 'KillingSpree')) and (Energy <50 and buff[classtable.DeepInsightBuff].up) and cooldown[classtable.KillingSpree].ready then
        if not setSpell then setSpell = classtable.KillingSpree end
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains <3 and ComboPoints <3 or not buff[classtable.SliceandDiceBuff].up) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
end
function Combat:finish()
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (ComboPoints == 5) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints == 5 and not debuff[classtable.RuptureDeBuff].up and ( MaxDps:boss() or targets == 1 or MaxDps:NumGroupFriends() <= 1 ) and not buff[classtable.DeepInsightBuff].up and not buff[classtable.BladeFlurryBuff].up and not buff[classtable.AdrenalineRushBuff].up and ttd >12 and not MaxDps:Bloodlust()) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (ComboPoints == 5 and ttd <12) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
end
function Combat:cds()
    if (MaxDps:CheckSpellUsable(classtable.AdrenalineRush, 'AdrenalineRush')) and (Energy <80 and cooldown[classtable.KillingSpree].remains >15) and cooldown[classtable.AdrenalineRush].ready then
        if not setSpell then setSpell = classtable.AdrenalineRush end
    end
end
function Combat:defensives()
    if (MaxDps:CheckSpellUsable(classtable.CloakofShadows, 'CloakofShadows')) and (curentHP <= 20 and not buff[classtable.CloakofShadowsBuff].up) and cooldown[classtable.CloakofShadows].ready then
        if not setSpell then setSpell = classtable.CloakofShadows end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evasion, 'Evasion')) and (curentHP <= 35 and not buff[classtable.EvasionBuff].up) and cooldown[classtable.Evasion].ready then
        if not setSpell then setSpell = classtable.Evasion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recuperate, 'Recuperate')) and (curentHP <30 and ComboPoints >= 3 and not buff[classtable.RecuperateBuff].up) and cooldown[classtable.Recuperate].ready then
        if not setSpell then setSpell = classtable.Recuperate end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
end

function Combat:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (debuff[classtable.DispellableEnrageDeBuff].up) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Combat:cds()
    if (ComboPoints == 5) then
        Combat:finish()
    end
    Combat:build()
    Combat:defensives()
    if (MaxDps:CheckSpellUsable(classtable.Redirect, 'Redirect')) and (ttd <5 and targets >2) and cooldown[classtable.Redirect].ready then
        if not setSpell then setSpell = classtable.Redirect end
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeFlurry, 'BladeFlurry')) and (targets >1 and not buff[classtable.BladeFlurryBuff].up) and cooldown[classtable.BladeFlurry].ready then
        if not setSpell then setSpell = classtable.BladeFlurry end
    end
    if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and (targets >5 and Energy <50 and buff[classtable.DeepInsightBuff].up) and cooldown[classtable.FanofKnives].ready then
        if not setSpell then setSpell = classtable.FanofKnives end
    end
end
function Rogue:Combat()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
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
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.SliceandDiceBuff = 0
    classtable.RevealingStrikeDeBuff = 84617
    classtable.DeepInsightBuff = 84747
    classtable.RuptureDeBuff = 1943
    classtable.BladeFlurryBuff = 13877
    classtable.AdrenalineRushBuff = 13750
    classtable.bloodlust = 0
    classtable.CloakofShadowsBuff = 0
    classtable.EvasionBuff = 26669
    classtable.RecuperateBuff = 73651
    classtable.DispellableEnrageDeBuff = 0
    classtable.SinisterStrike = 1752
    classtable.AdrenalineRush = 13750
    classtable.RevealingStrike = 84617
    classtable.Gouge = 1776
    classtable.KillingSpree = 51690
    classtable.Eviscerate = 2098
    classtable.Rupture = 1943
    classtable.BladeFlurry = 13877
    classtable.Evasion = 5277
    classtable.Recuperate = 73651
    classtable.Shiv = 5938
    classtable.Kick = 1766
    classtable.Redirect = 73981

    local function debugg()
    end


    if MaxDps.db.global.debugMode then
        debugg()
    end

    setSpell = nil
    ClearCDs()

    Combat:precombat()

    Combat:callaction()
    if setSpell then return setSpell end
end
