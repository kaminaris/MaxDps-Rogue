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
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
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

local priority_rotation
local trinket_sync_slot
local effective_spend_cp
local single_target
local regen_saturated
local not_pooling
local scent_effective_max_stacks
local scent_saturation
local deathmark_ma_condition
local deathmark_kingsbane_condition
local deathmark_condition
local dot_finisher_condition
local use_filler
local use_caustic_filler
local base_trinket_condition
local shiv_condition
local shiv_kingsbane_condition


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
    priority_rotation = false
    effective_spend_cp = ComboPointsMax - 1 * (talents[classtable.HandofFate] and talents[classtable.HandofFate] or 1)
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Stealth end
    end
    --if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (debuff[classtable.SliceandDiceDeBuff].refreshable and not buff[classtable.IndiscriminateCarnageBuff].up) and cooldown[classtable.SliceandDice].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.SliceandDice end
    --end
end
function Assassination:cds()
    deathmark_ma_condition = not talents[classtable.MasterAssassin] or debuff[classtable.GarroteDeBuff].up
    deathmark_kingsbane_condition = not talents[classtable.Kingsbane] or cooldown[classtable.Kingsbane].remains <= 2
    deathmark_condition = not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.SliceandDiceBuff].remains >5 and debuff[classtable.RuptureDeBuff].up and buff[classtable.EnvenomBuff].up and not debuff[classtable.DeathmarkDeBuff].up and deathmark_ma_condition and deathmark_kingsbane_condition
    Assassination:items()
    if (MaxDps:CheckSpellUsable(classtable.Deathmark, 'Deathmark')) and (( deathmark_condition and ttd >= 10 ) or MaxDps:boss() and ttd <= 20) and cooldown[classtable.Deathmark].ready then
        MaxDps:GlowCooldown(classtable.Deathmark, cooldown[classtable.Deathmark].ready)
    end
    Assassination:shiv()
    if (MaxDps:CheckSpellUsable(classtable.Kingsbane, 'Kingsbane')) and (( debuff[classtable.ShivDeBuff].up or cooldown[classtable.Shiv].remains <6 ) and buff[classtable.EnvenomBuff].up and ( cooldown[classtable.Deathmark].remains >= 50 or debuff[classtable.DeathmarkDeBuff].up ) or MaxDps:boss() and ttd <= 15) and cooldown[classtable.Kingsbane].ready then
        MaxDps:GlowCooldown(classtable.Kingsbane, cooldown[classtable.Kingsbane].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThistleTea, 'ThistleTea')) and (not buff[classtable.ThistleTeaBuff].up and ( ( ( EnergyDeficit >= 100 + EnergyRegenCombined or cooldown[classtable.ThistleTea].charges >= 3 ) and debuff[classtable.ShivDeBuff].remains >= 4 ) or targets >= 4 and debuff[classtable.ShivDeBuff].remains >= 6 ) or ( not buff[classtable.ThistleTeaBuff].up or EnergyDeficit >100 ) and ttd <cooldown[classtable.ThistleTea].charges * 6) and cooldown[classtable.ThistleTea].ready then
        MaxDps:GlowCooldown(classtable.ThistleTea, cooldown[classtable.ThistleTea].ready)
    end
    Assassination:misc_cds()
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.MasterAssassin].remains == 0) then
        Assassination:vanish()
    end
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and (not buff[classtable.EdgeCaseBuff].up and cooldown[classtable.Deathmark].remains >10 and not buff[classtable.DarkestNightBuff].up and calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( not_pooling or debuff[classtable.AmplifyingPoisonDeBuff].count >= 20 or not single_target ) and not buff[classtable.VanishBuff].up and ( not cooldown[classtable.Kingsbane].ready or not single_target ) and not cooldown[classtable.Deathmark].ready) and cooldown[classtable.ColdBlood].ready then
        MaxDps:GlowCooldown(classtable.ColdBlood, cooldown[classtable.ColdBlood].ready)
    end
end
function Assassination:core_dot()
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and (ComboPointsDeficit >= 1 and ( debuff[classtable.GarroteDeBuff].remains <= 1 ) and debuff[classtable.GarroteDeBuff].refreshable and ttd - debuff[classtable.GarroteDeBuff].remains >12) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( debuff[classtable.RuptureDeBuff].remains <= 1 ) and debuff[classtable.RuptureDeBuff].refreshable and ttd - debuff[classtable.RuptureDeBuff].remains >( 4 + ( (talents[classtable.DashingScoundrel] and talents[classtable.DashingScoundrel] or 0) * 5 ) + ( regen_saturated and 1 or 0 * 6 ) ) and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrimsonTempest, 'CrimsonTempest')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and debuff[classtable.CrimsonTempestDeBuff].refreshable and buff[classtable.MomentumofDespairBuff].remains >6 and single_target) and cooldown[classtable.CrimsonTempest].ready then
        if not setSpell then setSpell = classtable.CrimsonTempest end
    end
end
function Assassination:aoe_dot()
    scent_effective_max_stacks = 20--( targets * (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 0) * 2 ) >20
    dot_finisher_condition = calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( debuff[classtable.RuptureDeBuff].refreshable or debuff[classtable.GarroteDeBuff].refreshable  )
    if (MaxDps:CheckSpellUsable(classtable.CrimsonTempest, 'CrimsonTempest')) and (targets >= 2 and dot_finisher_condition and debuff[classtable.CrimsonTempestDeBuff].refreshable and ttd - debuff[classtable.CrimsonTempestDeBuff].remains >6) and cooldown[classtable.CrimsonTempest].ready then
        if not setSpell then setSpell = classtable.CrimsonTempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and (ComboPointsDeficit >= 1 and ( debuff[classtable.GarroteDeBuff].remains <= 1 ) and debuff[classtable.GarroteDeBuff].refreshable and not regen_saturated and ttd - debuff[classtable.GarroteDeBuff].remains >12) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (dot_finisher_condition and debuff[classtable.RuptureDeBuff].refreshable and ( not debuff[classtable.KingsbaneDeBuff].up or buff[classtable.ColdBloodBuff].up ) and ( not regen_saturated and ( (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 0) == 2 or (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 0) <= 1 and ( buff[classtable.IndiscriminateCarnageBuff].up or ttd - debuff[classtable.RuptureDeBuff].remains >15 ) ) ) and ttd - debuff[classtable.RuptureDeBuff].remains >( 7 + ( (talents[classtable.DashingScoundrel] and talents[classtable.DashingScoundrel] or 0) * 5 ) + ( regen_saturated and 1 or 0 * 6 ) ) and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (dot_finisher_condition and debuff[classtable.RuptureDeBuff].refreshable and ( not debuff[classtable.KingsbaneDeBuff].up or buff[classtable.ColdBloodBuff].up ) and regen_saturated and not scent_saturation and ttd - debuff[classtable.RuptureDeBuff].remains >19 and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and (debuff[classtable.GarroteDeBuff].refreshable and ComboPointsDeficit >= 1 and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].remains <= buff[classtable.GarroteBuff].duration and targets >= 3 ) and ( debuff[classtable.GarroteDeBuff].remains <= buff[classtable.GarroteBuff].duration * 2 and targets >= 3 ) and ( ttd - debuff[classtable.GarroteDeBuff].remains ) >4 and buff[classtable.MasterAssassin].remains == 0) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
end
function Assassination:direct()
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (not buff[classtable.DarkestNightBuff].up and calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( not_pooling or debuff[classtable.AmplifyingPoisonDeBuff].count >= 20 or calculateEffectiveComboPoints(ComboPoints) >ComboPointsMax or not single_target ) and not buff[classtable.VanishBuff].up) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (buff[classtable.DarkestNightBuff].up and calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    use_filler = ComboPointsDeficit >1 or not_pooling or not single_target
    use_caustic_filler = talents[classtable.CausticSpatter] and debuff[classtable.RuptureDeBuff].up and ( not debuff[classtable.CausticSpatterDeBuff].up or debuff[classtable.CausticSpatterDeBuff].remains <= 2 ) and ComboPointsDeficit >1 and not single_target
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and (use_caustic_filler) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (use_caustic_filler) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.EchoingReprimand, 'EchoingReprimand')) and (use_filler or MaxDps:boss() and ttd <20) and cooldown[classtable.EchoingReprimand].ready then
        MaxDps:GlowCooldown(classtable.EchoingReprimand, cooldown[classtable.EchoingReprimand].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and (use_filler and not priority_rotation and ( targets >= 3 - ( talents[classtable.MomentumofDespair] and talents[classtable.ThrownPrecision] or 0 ) or buff[classtable.CleartheWitnessesBuff].up and not talents[classtable.ViciousVenoms] )) and cooldown[classtable.FanofKnives].ready then
        if not setSpell then setSpell = classtable.FanofKnives end
    end
    if (MaxDps:CheckSpellUsable(classtable.FanofKnives, 'FanofKnives')) and (not debuff[classtable.DeadlyPoisonDebuffDeBuff].up and ( not priority_rotation or debuff[classtable.GarroteDeBuff].up or debuff[classtable.RuptureDeBuff].up ) and use_filler and targets >= 3 - ( talents[classtable.MomentumofDespair] and talents[classtable.ThrownPrecision] or 0 )) and cooldown[classtable.FanofKnives].ready then
        if not setSpell then setSpell = classtable.FanofKnives end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (use_filler and ( buff[classtable.BlindsideBuff].up or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) ) and ( not debuff[classtable.KingsbaneDeBuff].up or not debuff[classtable.DeathmarkDeBuff].up or buff[classtable.BlindsideBuff].up )) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and (not debuff[classtable.DeadlyPoisonDebuffDeBuff].up and not debuff[classtable.AmplifyingPoisonDeBuff].up and use_filler and targets == 2) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mutilate, 'Mutilate')) and (use_filler) and cooldown[classtable.Mutilate].ready then
        if not setSpell then setSpell = classtable.Mutilate end
    end
end
function Assassination:items()
end
function Assassination:misc_cds()
end
function Assassination:shiv()
    shiv_condition = not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up
    shiv_kingsbane_condition = talents[classtable.Kingsbane] and buff[classtable.EnvenomBuff].up and shiv_condition
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (talents[classtable.ArterialPrecision] and shiv_condition and targets >= 4 and debuff[classtable.CrimsonTempestDeBuff].up) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (not talents[classtable.LightweightShiv] and shiv_kingsbane_condition and ( debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.KingsbaneDeBuff].remains <8 or not debuff[classtable.KingsbaneDeBuff].up and cooldown[classtable.Kingsbane].remains >= 24 ) and ( not talents[classtable.CrimsonTempest] or single_target or debuff[classtable.CrimsonTempestDeBuff].up )) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (talents[classtable.LightweightShiv] and shiv_kingsbane_condition and ( debuff[classtable.KingsbaneDeBuff].up or cooldown[classtable.Kingsbane].remains <= 1 )) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (talents[classtable.ArterialPrecision] and shiv_condition and debuff[classtable.DeathmarkDeBuff].up) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (not talents[classtable.Kingsbane] and not talents[classtable.ArterialPrecision] and shiv_condition and ( not talents[classtable.CrimsonTempest] or single_target or debuff[classtable.CrimsonTempestDeBuff].up )) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (MaxDps:boss() and ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
end
function Assassination:stealthed()
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (not debuff[classtable.DeathstalkersMarkDeBuff].up and talents[classtable.DeathstalkersMark] and ( debuff[classtable.DeathstalkersMarkDeBuff].count  == 0 or not buff[classtable.DarkestNightBuff].up )) and cooldown[classtable.Ambush].ready then
        if not setSpell then setSpell = classtable.Ambush end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shiv, 'Shiv')) and (talents[classtable.Kingsbane] and ( debuff[classtable.KingsbaneDeBuff].up or cooldown[classtable.Kingsbane].ready ) and ( not debuff[classtable.ShivDeBuff].up and debuff[classtable.ShivDeBuff].remains <1 ) and buff[classtable.EnvenomBuff].up) and cooldown[classtable.Shiv].ready then
        if not setSpell then setSpell = classtable.Shiv end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and debuff[classtable.KingsbaneDeBuff].up and buff[classtable.EnvenomBuff].remains <= 3 and ( debuff[classtable.DeathstalkersMarkDeBuff].up or buff[classtable.EdgeCaseBuff].up or buff[classtable.ColdBloodBuff].up )) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and buff[classtable.MasterAssassinAuraBuff].up and single_target and ( debuff[classtable.DeathstalkersMarkDeBuff].up or buff[classtable.EdgeCaseBuff].up or buff[classtable.ColdBloodBuff].up )) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and buff[classtable.IndiscriminateCarnageBuff].up and debuff[classtable.RuptureDeBuff].refreshable and ( not regen_saturated or not scent_saturation or not debuff[classtable.RuptureDeBuff].up ) and ttd >15) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( debuff[classtable.GarroteDeBuff].remains <12 or debuff[classtable.GarroteDeBuff].remains <= 1 or ( buff[classtable.IndiscriminateCarnageBuff].up and debuff[classtable.GarroteDeBuff].count  <1 ) ) and not single_target and ttd - debuff[classtable.GarroteDeBuff].remains >2) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
    if (MaxDps:CheckSpellUsable(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].remains <12 or not single_target and buff[classtable.MasterAssassinAuraBuff].remains <3 ) and ComboPointsDeficit >= 1 + 2 * (talents[classtable.ShroudedSuffocation] and talents[classtable.ShroudedSuffocation] or 1 )) and cooldown[classtable.Garrote].ready then
        if not setSpell then setSpell = classtable.Garrote end
    end
end
function Assassination:vanish()
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not buff[classtable.FateboundLuckyCoinBuff].up and ( buff[classtable.FateboundCoinTailsBuff].count >= 5 or buff[classtable.FateboundCoinHeadsBuff].count >= 5 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and not talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains <4 ) and ComboPointsDeficit >= ( targets >4 and 1 or 0)) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and targets >2) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (talents[classtable.MasterAssassin] and talents[classtable.Kingsbane] and debuff[classtable.KingsbaneDeBuff].remains <= 3 and debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.DeathmarkDeBuff].remains <= 3 and debuff[classtable.DeathmarkDeBuff].up) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and targets >2 and ( ttd - debuff[classtable.VanishDeBuff].remains >15 or math.huge >20 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.ImprovedGarrote] and talents[classtable.MasterAssassin] and not debuff[classtable.RuptureDeBuff].refreshable and debuff[classtable.GarroteDeBuff].remains >3 and debuff[classtable.DeathmarkDeBuff].up and ( debuff[classtable.ShivDeBuff].up or debuff[classtable.DeathmarkDeBuff].remains <4 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains <4 ) and math.huge >30) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
    MaxDps:GlowCooldown(classtable.ThistleTea, false)
    MaxDps:GlowCooldown(classtable.ColdBlood, false)
    MaxDps:GlowCooldown(classtable.EchoingReprimand, false)
    MaxDps:GlowCooldown(classtable.Vanish, false)
    MaxDps:GlowCooldown(classtable.Kingsbane, false)
    MaxDps:GlowCooldown(classtable.Deathmark, false)
end

function Assassination:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Stealth end
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    single_target = targets <2
    regen_saturated = EnergyRegenCombined >15
    not_pooling = ( debuff[classtable.DeathmarkDeBuff].up or debuff[classtable.KingsbaneDeBuff].up or debuff[classtable.ShivDeBuff].up ) or ( buff[classtable.EnvenomBuff].up and buff[classtable.EnvenomBuff].remains <= 1 ) or EnergyPerc >= ( 40 + 30 * (talents[classtable.HandofFate] and talents[classtable.HandofFate] or 0) - 15 * (talents[classtable.ViciousVenoms] and talents[classtable.ViciousVenoms] or 0) ) or MaxDps:boss() and ttd <= 20
    scent_effective_max_stacks = 20-- ( targets * (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 1) * 2 ) >20
    scent_saturation = buff[classtable.ScentofBloodBuff].count >= scent_effective_max_stacks
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) or buff[classtable.MasterAssassin].remains >0) then
        Assassination:stealthed()
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (not buff[classtable.SliceandDiceBuff].up and debuff[classtable.RuptureDeBuff].up and ComboPoints >= 1 and ( not buff[classtable.IndiscriminateCarnageBuff].up or single_target )) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    if (MaxDps:CheckSpellUsable(classtable.Envenom, 'Envenom')) and (buff[classtable.SliceandDiceBuff].up and buff[classtable.SliceandDiceBuff].remains <5 and ComboPoints >= 5) and cooldown[classtable.Envenom].ready then
        if not setSpell then setSpell = classtable.Envenom end
    end
    Assassination:cds()
    Assassination:core_dot()
    if (not single_target) then
        Assassination:aoe_dot()
    end
    Assassination:direct()
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
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
    classtable.SliceandDiceDeBuff = 0
    classtable.IndiscriminateCarnageBuff = 385754
    classtable.GarroteDeBuff = 703
    classtable.SliceandDiceBuff = 315496
    classtable.RuptureDeBuff = 1943
    classtable.EnvenomBuff = 32645
    classtable.DeathmarkDeBuff = 360194
    classtable.ShivDeBuff = 319504
    classtable.ThistleTeaBuff = 381623
    classtable.EdgeCaseBuff = 0
    classtable.DarkestNightBuff = 0
    classtable.AmplifyingPoisonDeBuff = 383414
    classtable.VanishBuff = 11327
    classtable.CrimsonTempestDeBuff = 121411
    classtable.MomentumofDespairBuff = 0
    classtable.DeBuff = 0
    classtable.KingsbaneDeBuff = 385627
    classtable.ColdBloodBuff = 382245
    classtable.CausticSpatterDeBuff = 421976
    classtable.CleartheWitnessesBuff = 0
    classtable.DeadlyPoisonDebuffDeBuff = 2818
    classtable.BlindsideBuff = 121153
    classtable.DeathstalkersMarkDeBuff = 0
    classtable.MasterAssassinAuraBuff = 356735
    classtable.FateboundLuckyCoinBuff = 0
    classtable.FateboundCoinTailsBuff = 0
    classtable.FateboundCoinHeadsBuff = 0
    classtable.VanishDeBuff = 0
    classtable.ScentofBloodBuff = 394080
    setSpell = nil
    ClearCDs()

    Assassination:precombat()

    Assassination:callaction()
    if setSpell then return setSpell end
end
