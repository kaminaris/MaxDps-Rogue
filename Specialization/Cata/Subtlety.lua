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
local DanseMacabreSpellList

local Subtlety = {}



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


local function CheckDanseMacabre(spell)
	return false
end




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
    MaxDps:GlowCooldown(classtable.ShadowDance, false)
    MaxDps:GlowCooldown(classtable.Vanish, false)
end

function Subtlety:callaction()
    --if (MaxDps:CheckSpellUsable(classtable.ApplyPoison, 'ApplyPoison')) and cooldown[classtable.ApplyPoison].ready then
        --if not setSpell then setSpell = classtable.ApplyPoison end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and (not in_combat or MaxDps:Bloodlust() or ttd <30) and cooldown[classtable.TolvirPotion].ready then
        --if not setSpell then setSpell = classtable.TolvirPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
        if not setSpell then setSpell = classtable.Stealth end
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.TricksoftheTrade, 'TricksoftheTrade')) and ((MaxDps.tier and MaxDps.tier[12].count >= 4) or (MaxDps.tier and MaxDps.tier[13].count >= 2)) and cooldown[classtable.TricksoftheTrade].ready then
        if not setSpell then setSpell = classtable.TricksoftheTrade end
    end
    if (MaxDps:CheckSpellUsable(classtable.PoolEnergy, 'PoolEnergy')) and cooldown[classtable.PoolEnergy].ready then
        if not setSpell then setSpell = classtable.PoolEnergy end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowDance, 'ShadowDance')) and (Energy >85 and ComboPoints <5 and not buff[classtable.StealthedBuff].up) and cooldown[classtable.ShadowDance].ready then
        MaxDps:GlowCooldown(classtable.ShadowDance, cooldown[classtable.ShadowDance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PoolEnergy, 'PoolEnergy')) and cooldown[classtable.PoolEnergy].ready then
        if not setSpell then setSpell = classtable.PoolEnergy end
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (timeInCombat >10 and Energy >60 and ComboPoints <= 1 and cooldown[classtable.Shadowstep].remains <= 0 and not buff[classtable.ShadowDanceBuff].up and not buff[classtable.MasterofSubtletyBuff].up and not buff[classtable.FindWeaknessBuff].up) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstep, 'Shadowstep')) and (buff[classtable.StealthedBuff].up or buff[classtable.ShadowDanceBuff].up) and cooldown[classtable.Shadowstep].ready then
        if not setSpell then setSpell = classtable.Shadowstep end
    end
    if (MaxDps:CheckSpellUsable(classtable.Premeditation, 'Premeditation')) and (( ComboPoints <= 3 and cooldown[classtable.HonorAmongThieves].remains >1.75 ) or ComboPoints <= 2) and cooldown[classtable.Premeditation].ready then
        if not setSpell then setSpell = classtable.Premeditation end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (ComboPoints <= 4) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.Preparation, 'Preparation')) and (cooldown[classtable.Vanish].remains >60) and cooldown[classtable.Preparation].ready then
        if not setSpell then setSpell = classtable.Preparation end
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains <3 and ComboPoints == 5) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints == 5 and not debuff[classtable.RuptureDeBuff].up) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recuperate, 'Recuperate')) and (ComboPoints == 5 and debuff[classtable.RecuperateDeBuff].remains <3) and cooldown[classtable.Recuperate].ready then
        if not setSpell then setSpell = classtable.Recuperate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (ComboPoints == 5 and debuff[classtable.RuptureDeBuff].remains >1) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hemorrhage, 'Hemorrhage')) and (ComboPoints <4 and ( debuff[classtable.HemorrhageDeBuff].remains <4 or position_front )) and cooldown[classtable.Hemorrhage].ready then
        if not setSpell then setSpell = classtable.Hemorrhage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hemorrhage, 'Hemorrhage')) and (ComboPoints <5 and Energy >80 and ( debuff[classtable.HemorrhageDeBuff].remains <4 or position_front )) and cooldown[classtable.Hemorrhage].ready then
        if not setSpell then setSpell = classtable.Hemorrhage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and (ComboPoints <4) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and (ComboPoints <5 and Energy >80) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
end
function Rogue:Subtlety()
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
    classtable.bloodlust = 0
    classtable.StealthedBuff = 0
    classtable.ShadowDanceBuff = 185422
    classtable.MasterofSubtletyBuff = 0
    classtable.FindWeaknessBuff = 0
    classtable.SliceandDiceBuff = 315496
    classtable.RuptureDeBuff = 1943
    classtable.RecuperateDeBuff = 0
    classtable.HemorrhageDeBuff = 0
    setSpell = nil
    ClearCDs()

    Subtlety:callaction()
    if setSpell then return setSpell end
end
