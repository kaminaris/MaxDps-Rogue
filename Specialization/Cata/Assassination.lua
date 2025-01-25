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

local Assassination = {}

local trinket_sync_slot
local regen_saturated
local single_target
local cold_blood_casted
local priority_rotation
local not_pooling
local use_filler


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
    if (MaxDps:CheckSpellUsable(classtable.TolVirPotion, 'TolVirPotion')) and (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.TolVirPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.TolVirPotion end
    end
end
function Assassination:st()
    use_filler = ComboPointsDeficit >1 or not_pooling or not single_target
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (ComboPoints >1 and buff[classtable.OverkillBuff].up and debuff[classtable.RuptureDeBuff].refreshable and ttd - debuff[classtable.RuptureDeBuff].remains >20 or ComboPoints >1 and ttd >6 and debuff[classtable.RuptureDeBuff].refreshable) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (targethealthPerc >35 and ComboPoints >4 and Energy >80 and buff[classtable.EnvenomBuff].up or targethealthPerc >35 and not buff[classtable.EnvenomBuff].up and Energy >55 and ComboPoints >4) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and (use_filler and targets >= 5) and cooldown[classtable.FanofKnives].ready then
        if not setSpell then setSpell = classtable.FanofKnives end
    end
    if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and (use_filler and targets >= 3) and cooldown[classtable.FanofKnives].ready then
        if not setSpell then setSpell = classtable.FanofKnives end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and (not debuff[classtable.DeadlyPoisonDebuffDeBuff].up and ( ComboPointsDeficit >1 or not_pooling or not single_target ) and targets == 2) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and (use_filler and ( ( targethealthPerc >35 ) or ( targethealthPerc <35 and not false ) )) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and (false and use_filler and targethealthPerc <35) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (targethealthPerc <35 and ComboPoints == 5 and Energy >65) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
end
function Assassination:cds()
    if (MaxDps:CheckSpellUsable(classtable.Vendetta, 'Vendetta')) and (cooldown[classtable.Vendetta].charges == 2 and debuff[classtable.GarroteDeBuff].duration >6) and cooldown[classtable.Vendetta].ready then
        if not setSpell then setSpell = classtable.Vendetta end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and (debuff[classtable.VendettaDeBuff].up and ComboPoints == 5 or ttd <= 120 and ComboPoints == 5) and cooldown[classtable.ColdBlood].ready then
        if not setSpell then setSpell = classtable.ColdBlood end
    end
    if (MaxDps:CheckSpellUsable(classtable.Vendetta, 'Vendetta')) and (ttd >30 and buff[classtable.SliceandDiceBuff].up and debuff[classtable.RuptureDeBuff].up) and cooldown[classtable.Vendetta].ready then
        if not setSpell then setSpell = classtable.Vendetta end
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (Energy <50 and not buff[classtable.StealthBuff].up and not buff[classtable.OverkillBuff].up) and cooldown[classtable.Vanish].ready then
        if not setSpell then setSpell = classtable.Vanish end
    end
    Assassination:misc_cds()
end
function Assassination:misc_cds()
    if (MaxDps:CheckSpellUsable(classtable.TolVirPotion, 'TolVirPotion')) and (MaxDps:Bloodlust(1) and ttd <= 120) and cooldown[classtable.TolVirPotion].ready then
        if not setSpell then setSpell = classtable.TolVirPotion end
    end
end
function Assassination:defensives()
    if (MaxDps:CheckSpellUsable(classtable.CloakofShadows, 'CloakofShadows')) and (healthPerc <= 20 and not buff[classtable.CloakofShadowsBuff].up) and cooldown[classtable.CloakofShadows].ready then
        if not setSpell then setSpell = classtable.CloakofShadows end
    end
    if (MaxDps:CheckSpellUsable(classtable.Evasion, 'Evasion')) and (healthPerc <= 35 and not buff[classtable.EvasionBuff].up) and cooldown[classtable.Evasion].ready then
        if not setSpell then setSpell = classtable.Evasion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recuperate, 'Recuperate')) and (healthPerc <30 and ComboPoints >= 3) and cooldown[classtable.Recuperate].ready then
        if not setSpell then setSpell = classtable.Recuperate end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
end

function Assassination:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (not buff[classtable.SliceandDiceBuff].up) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    Assassination:st()
    regen_saturated = EnergyRegenCombined >false
    single_target = targets <2
    if (MaxDps.spellHistory[1] == classtable.ColdBlood) then
        cold_blood_casted = 1
    end
    priority_rotation = priority_rotation
    if ( debuff[classtable.ShivDeBuff].up or cooldown[classtable.ThistleTea].fullRecharge <20 ) or ( buff[classtable.EnvenomBuff].up and buff[classtable.EnvenomBuff].remains <= 2 ) or EnergyPerc >= 80 or ttd <= 90 then
        not_pooling = ( debuff[classtable.ShivDeBuff].up or cooldown[classtable.ThistleTea].fullRecharge <20 ) or ( buff[classtable.EnvenomBuff].up and buff[classtable.EnvenomBuff].remains <= 2 ) or EnergyPerc >= 80 or ttd <= 90
    end
    if (MaxDps:CheckSpellUsable(classtable.ExposeArmor, 'ExposeArmor')) and (false and ComboPoints >= 4) and cooldown[classtable.ExposeArmor].ready then
        if not setSpell then setSpell = classtable.ExposeArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and ((talents[classtable.CutTotheChase] and true or false) and buff[classtable.SliceandDiceBuff].up and buff[classtable.SliceandDiceBuff].remains <5 and ComboPoints >= 2) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recuperate, 'Recuperate')) and (healthPerc <30 and ComboPoints >= 3) and cooldown[classtable.Recuperate].ready then
        if not setSpell then setSpell = classtable.Recuperate end
    end
    Assassination:cds()
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (debuff[classtable.DispellableEnrageDeBuff].up) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (false) then
        Assassination:defensives()
    end
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
    classtable.SliceandDiceBuff = 6774
    classtable.EnvenomBuff = 57993
    classtable.OverkillBuff = 58427
    classtable.GarroteBuff = 48676
    classtable.VendettaBuff = 79140
    classtable.RuptureBuff = 1943
    classtable.StealthBuff = 1784
    classtable.CloakofShadowsBuff = 31224
    classtable.EvasionBuff = 26669
    classtable.DeadlyPoisonDotDeBuff = 2818
    classtable.GarroteDeBuff = 48676
    classtable.RuptureDeBuff = 1943
    classtable.VendettaDeBuff = 79140
    classtable.TolVirPotion = 58145
    classtable.Garrote = 703
    classtable.Rupture = 1943
    classtable.Envenom = 32645
    classtable.FanofKnives = 51723
    classtable.Mutilate = 1329
    classtable.Backstab = 53
    classtable.Vendetta = 79140
    classtable.ColdBlood = 14177
    classtable.Vanish = 1856
    classtable.CloakofShadows = 31224
    classtable.Evasion = 5277
    classtable.Recuperate = 73651
    classtable.Stealth = 1784
    classtable.SliceandDice = 5171
    classtable.ExposeArmor = 8647
    classtable.Kick = 1766
    classtable.Shiv = 5938
    classtable.ThistleTea = 7676

    local function debugg()
        talents[classtable.CutTotheChase] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Assassination:precombat()

    Assassination:callaction()
    if setSpell then return setSpell end
end
