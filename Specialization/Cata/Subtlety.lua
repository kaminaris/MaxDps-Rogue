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


function Subtlety:precombat()
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (ComboPoints >= 5) and cooldown[classtable.SliceandDice].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
end
function Subtlety:mr()
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (ComboPoints >= 6 and debuff[classtable.RuptureDeBuff].remains <3) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (buff[classtable.ShadowDanceBuff].up and ComboPoints >= 5) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints >= 5 and debuff[classtable.RuptureDeBuff].remains <3) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (buff[classtable.FindWeaknessBuff].remains <= 3) and cooldown[classtable.Vanish].ready then
        if not setSpell then setSpell = classtable.Vanish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Premeditation, 'Premeditation')) and (buff[classtable.VanishBuff].up) and cooldown[classtable.Premeditation].ready then
        if not setSpell then setSpell = classtable.Premeditation end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (buff[classtable.VanishBuff].up) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
end
function Subtlety:sr()
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (ComboPoints >= 6 and debuff[classtable.RuptureDeBuff].remains <3) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints >= 5 and debuff[classtable.RuptureDeBuff].remains <3) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hemorrhage, 'Hemorrhage')) and (debuff[classtable.HemorrhageDeBuff].remains <3) and cooldown[classtable.Hemorrhage].ready then
        if not setSpell then setSpell = classtable.Hemorrhage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recuperate, 'Recuperate')) and (not buff[classtable.RecuperateBuff].up and EnergyTimeToMax >2.5) and cooldown[classtable.Recuperate].ready then
        if not setSpell then setSpell = classtable.Recuperate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Preparation, 'Preparation')) and (( not buff[classtable.VanishBuff].up and cooldown[classtable.Vanish].remains <5 ) or ( not buff[classtable.ShadowDanceBuff].up and cooldown[classtable.ShadowDance].remains <5 )) and cooldown[classtable.Preparation].ready then
        if not setSpell then setSpell = classtable.Preparation end
    end
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and (ComboPoints <5) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
end
function Subtlety:cooldowns()
    if (MaxDps:CheckSpellUsable(classtable.ShadowDance, 'ShadowDance')) and (cooldown[classtable.ShadowDance].ready) and cooldown[classtable.ShadowDance].ready then
        if not setSpell then setSpell = classtable.ShadowDance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (cooldown[classtable.Vanish].ready and EnergyTimeToMax >2.5) and cooldown[classtable.Vanish].ready then
        if not setSpell then setSpell = classtable.Vanish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstep, 'Shadowstep')) and (buff[classtable.ShadowDanceBuff].up) and cooldown[classtable.Shadowstep].ready then
        if not setSpell then setSpell = classtable.Shadowstep end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (buff[classtable.ShadowDanceBuff].up or buff[classtable.StealthBuff].up) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
end


local function ClearCDs()
end

function Subtlety:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Premeditation, 'Premeditation')) and cooldown[classtable.Premeditation].ready then
        if not setSpell then setSpell = classtable.Premeditation end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints >1 and not debuff[classtable.RuptureDeBuff].up) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hemorrhage, 'Hemorrhage')) and (not debuff[classtable.HemorrhageDeBuff].up) and cooldown[classtable.Hemorrhage].ready then
        if not setSpell then setSpell = classtable.Hemorrhage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowDance, 'ShadowDance')) and (not buff[classtable.ShadowDanceBuff].up) and cooldown[classtable.ShadowDance].ready then
        if not setSpell then setSpell = classtable.ShadowDance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstep, 'Shadowstep')) and cooldown[classtable.Shadowstep].ready then
        if not setSpell then setSpell = classtable.Shadowstep end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (buff[classtable.ShadowstepBuff].up) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recuperate, 'Recuperate')) and (ComboPoints >1 and not buff[classtable.RecupateBuff].up) and cooldown[classtable.Recuperate].ready then
        if not setSpell then setSpell = classtable.Recuperate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (ComboPoints <5 and (IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (ComboPoints >= 5) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
    if (buff[classtable.FindWeaknessBuff].up) then
        Subtlety:mr()
    end
    if (not buff[classtable.FindWeaknessBuff].up) then
        Subtlety:sr()
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
    classtable.RuptureBuff = 1943
    classtable.HemorrhageBuff = 16511
    classtable.ShadowDanceBuff = 51713
    classtable.ShadowstepBuff = 36563
    classtable.VanishBuff = 11327
    classtable.RecuperateBuff = 73651
    classtable.StealthBuff = 1784
    classtable.RuptureDeBuff = 1943
    classtable.HemorrhageDeBuff = 16511
    classtable.SliceandDice = 5171
    classtable.Eviscerate = 2098
    classtable.Rupture = 1943
    classtable.Vanish = 1856
    classtable.Premeditation = 14183
    classtable.Ambush = 8676
    classtable.Hemorrhage = 16511
    classtable.Recuperate = 73651
    classtable.Preparation = 14185
    classtable.ShadowDance = 51713
    classtable.Backstab = 53
    classtable.Shadowstep = 36554

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Subtlety:precombat()

    Subtlety:callaction()
    if setSpell then return setSpell end
end
