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
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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
local className, classFilename, classId = UnitClass('player')
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

local Assassination = {}



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


function Rogue:PoisonedBleeds()
	local poisoned = 0
	local usedNamePlates = false
	for i, frame in pairs(C_NamePlate.GetNamePlates()) do
		usedNamePlates = true
		if frame:IsVisible() then
			if debuff[classtable.DeadlyPoisonDot].up then
				poisoned = poisoned +
						debuff[classtable.Rupture].count +
						debuff[classtable.MutilatedFlesh].count +
						debuff[classtable.SerratedBoneSpike].count +
						debuff[classtable.Garrote].count +
						debuff[classtable.InternalBleeding].count
			end
		end
	end
	if not usedNamePlates then
		poisoned = debuff[classtable.Rupture].count +
				debuff[classtable.MutilatedFlesh].count +
				debuff[classtable.SerratedBoneSpike].count +
				debuff[classtable.Garrote].count +
				debuff[classtable.InternalBleeding].count
	end
	return poisoned
end


function Assassination:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.ApplyPoison, 'ApplyPoison')) and cooldown[classtable.ApplyPoison].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.ApplyPoison end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and cooldown[classtable.TolvirPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.TolvirPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Stealth end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
    MaxDps:GlowCooldown(classtable.Vanish, false)
end

function Assassination:single()
    if (MaxDps:CheckSpellUsable(classtable.Preparation, 'Preparation') and talents[classtable.Preparation]) and ((talents[classtable.Preparation] and true or false) and not buff[classtable.VanishBuff].up and cooldown[classtable.Vanish].remains >60) and cooldown[classtable.Preparation].ready then
        if not setSpell then setSpell = classtable.Preparation end
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (timeInCombat >10 and not buff[classtable.StealthedBuff].up) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.TricksoftheTrade, 'TricksoftheTrade')) and ((MaxDps.tier and MaxDps.tier[13].count >= 2)) and cooldown[classtable.TricksoftheTrade].ready then
        if not setSpell then setSpell = classtable.TricksoftheTrade end
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains <2) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    if (MaxDps:CheckSpellUsable(classtable.Dispatch, 'Dispatch')) and (debuff[classtable.RuptureDeBuff].remains <2 and Energy >90) and cooldown[classtable.Dispatch].ready then
        if not setSpell then setSpell = classtable.Dispatch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and (debuff[classtable.RuptureDeBuff].remains <2 and Energy >90) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (debuff[classtable.RuptureDeBuff].remains <2 or ( ComboPoints == 5 and debuff[classtable.RuptureDeBuff].remains <3 )) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Vendetta, 'Vendetta')) and cooldown[classtable.Vendetta].ready then
        if not setSpell then setSpell = classtable.Vendetta end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (ComboPoints >= 4 and buff[classtable.EnvenomBuff].remains <1) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (ComboPoints >4) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (ComboPoints >= 2 and buff[classtable.SliceandDiceBuff].remains <3) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Dispatch, 'Dispatch')) and (ComboPoints <5) and cooldown[classtable.Dispatch].ready then
        if not setSpell then setSpell = classtable.Dispatch end
    end
    if (MaxDps:CheckSpellUsable(classtable.TricksoftheTrade, 'TricksoftheTrade')) and cooldown[classtable.TricksoftheTrade].ready then
        if not setSpell then setSpell = classtable.TricksoftheTrade end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
end

function Assassination:aoe()
    if targets >= 3 and targets <= 7 then
        -- Apply Rupture (2-3 Combo Points)
        if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints >= 2 and ComboPoints <= 3 and debuff[classtable.RuptureDeBuff].remains < 2) and cooldown[classtable.Rupture].ready then
            if not setSpell then setSpell = classtable.Rupture end
        end

        -- Reapply Slice and Dice if missing
        if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains < 2) and cooldown[classtable.SliceandDice].ready then
            if not setSpell then setSpell = classtable.SliceandDice end
        end

        -- Cast Envenom to maintain Slice and Dice
        if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (ComboPoints >= 2 and buff[classtable.SliceandDiceBuff].remains < 3) and cooldown[classtable.Envenom].ready then
            if not setSpell then setSpell = classtable.Envenom end
        end

        -- Cast Fan of Knives
        if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and cooldown[classtable.FanofKnives].ready then
            if not setSpell then setSpell = classtable.FanofKnives end
        end
    elseif targets >= 8 then
        -- Cast Crimson Tempest (5 Combo Points)
        if (MaxDps:CheckSpellUsable(classtable.CrimsonTempest, 'CrimsonTempest')) and (ComboPoints == 5) and cooldown[classtable.CrimsonTempest].ready then
            if not setSpell then setSpell = classtable.CrimsonTempest end
        end

        -- Reapply Slice and Dice if missing
        if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains < 2) and cooldown[classtable.SliceandDice].ready then
            if not setSpell then setSpell = classtable.SliceandDice end
        end

        -- Cast Envenom to maintain Slice and Dice
        if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (ComboPoints >= 2 and buff[classtable.SliceandDiceBuff].remains < 3) and cooldown[classtable.Envenom].ready then
            if not setSpell then setSpell = classtable.Envenom end
        end

        -- Cast Fan of Knives
        if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and cooldown[classtable.FanofKnives].ready then
            if not setSpell then setSpell = classtable.FanofKnives end
        end
    end
end

function Assassination:callaction()
    if targets > 3 then
        Assassination:aoe()
    end
    Assassination:single()
end

function Rogue:Assassination()
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
    PoisonedBleeds = Rogue:PoisonedBleeds()
    EnergyRegenCombined = EnergyRegen + PoisonedBleeds * 7 % (2 * SpellHaste)
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.Preparation] = 1
    end

    classtable.VanishBuff = 11327
    classtable.StealthedBuff = 1784
    classtable.SliceandDiceBuff = 5171
    classtable.EnvenomBuff = 32645
    classtable.DeadlyPoisonDot = 2818
    classtable.RuptureDeBuff = 1943
    classtable.MutilatedFlesh = 385767
    classtable.SerratedBoneSpike = 385767
    classtable.Garrote = 703
    classtable.InternalBleeding = 154953

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Assassination:precombat()

    Assassination:callaction()
    if setSpell then return setSpell end
end
