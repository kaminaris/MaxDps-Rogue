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

local rtb_reroll
local ambush_condition
local finish_condition
local blade_flurry_sync
local vanish_opportunity_condition
local shadow_dance_condition

local Outlaw = {}

local function CheckSpellCosts(spell,spellstring)
    --if MaxDps.learnedSpells[spell] == nil then
    --	return false
    --end
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
			return aura
		end
	end
	return false
end


local function calculateEffectiveComboPoints(comboPoints)
	if comboPoints > 1 and comboPoints < 6 then
		local aura = echoingReprimandUp(comboPoints)
		if aura then
			return ComboPointsMax
		end
	end
	return comboPoints
end


local function calculateRtbBuffCount()
    local buffs = MaxDps.FrameData.buff
    local rollTheBonesBuffCount = 0
    if buffs[classtable.SkullAndCrossbones].up then rollTheBonesBuffCount = rollTheBonesBuffCount + 1 end
    if buffs[classtable.TrueBearing].up        then rollTheBonesBuffCount = rollTheBonesBuffCount + 1 end
    if buffs[classtable.RuthlessPrecision].up  then rollTheBonesBuffCount = rollTheBonesBuffCount + 1 end
    if buffs[classtable.GrandMelee].up         then rollTheBonesBuffCount = rollTheBonesBuffCount + 1 end
    if buffs[classtable.BuriedTreasure].up     then rollTheBonesBuffCount = rollTheBonesBuffCount + 1 end
    if buffs[classtable.Broadside].up          then rollTheBonesBuffCount = rollTheBonesBuffCount + 1 end
    return rollTheBonesBuffCount
end


local function calculateRtbBuffMax()
    local buffs = MaxDps.FrameData.buff
    local rollTheBonesBuffMax = 0
    if buffs[classtable.SkullAndCrossbones].duration then
        if buffs[classtable.SkullAndCrossbones].duration > rollTheBonesBuffMax then
            rollTheBonesBuffMax = buffs[classtable.SkullAndCrossbones].duration
        end
    end
    if buffs[classtable.TrueBearing].duration then
        if buffs[classtable.TrueBearing].duration > rollTheBonesBuffMax then
            rollTheBonesBuffMax = buffs[classtable.TrueBearing].duration
        end
    end
    if buffs[classtable.RuthlessPrecision].duration then
        if buffs[classtable.RuthlessPrecision].duration > rollTheBonesBuffMax then
            rollTheBonesBuffMax = buffs[classtable.RuthlessPrecision].duration
        end
    end
    if buffs[classtable.GrandMelee].duration then
        if buffs[classtable.GrandMelee].duration > rollTheBonesBuffMax then
            rollTheBonesBuffMax = buffs[classtable.GrandMelee].duration
        end
    end
    if buffs[classtable.BuriedTreasure].duration then
        if buffs[classtable.BuriedTreasure].duration > rollTheBonesBuffMax then
            rollTheBonesBuffMax = buffs[classtable.BuriedTreasure].duration
        end
    end
    if buffs[classtable.Broadside].duration then
        if buffs[classtable.Broadside].duration > rollTheBonesBuffMax then
            rollTheBonesBuffMax = buffs[classtable.Broadside].duration
        end
    end
    return rollTheBonesBuffMax
end


local function PreCombatUpdate()
end

function Outlaw:precombat()
    if (MaxDps:FindSpell(classtable.ApplyPoison) and CheckSpellCosts(classtable.ApplyPoison, 'ApplyPoison')) and cooldown[classtable.ApplyPoison].ready then
        return classtable.ApplyPoison
    end
    if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
        return classtable.Flask
    end
    if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
        return classtable.Augmentation
    end
    if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
        return classtable.Food
    end
    if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
        return classtable.SnapshotStats
    end
    if (MaxDps:FindSpell(classtable.BladeFlurry) and CheckSpellCosts(classtable.BladeFlurry, 'BladeFlurry')) and (talents[classtable.UnderhandedUpperHand]) and cooldown[classtable.BladeFlurry].ready then
        return classtable.BladeFlurry
    end
    if (MaxDps:FindSpell(classtable.RolltheBones) and CheckSpellCosts(classtable.RolltheBones, 'RolltheBones')) and cooldown[classtable.RolltheBones].ready then
        return classtable.RolltheBones
    end
    if (MaxDps:FindSpell(classtable.AdrenalineRush) and CheckSpellCosts(classtable.AdrenalineRush, 'AdrenalineRush')) and (talents[classtable.ImprovedAdrenalineRush]) and cooldown[classtable.AdrenalineRush].ready then
        return classtable.AdrenalineRush
    end
    if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    if (MaxDps:FindSpell(classtable.Stealth) and CheckSpellCosts(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
        return classtable.Stealth
    end
end
function Outlaw:build()
    if (MaxDps:FindSpell(classtable.EchoingReprimand) and CheckSpellCosts(classtable.EchoingReprimand, 'EchoingReprimand')) and cooldown[classtable.EchoingReprimand].ready then
        return classtable.EchoingReprimand
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (talents[classtable.HiddenOpportunity] and buff[classtable.AudacityBuff].up) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.PistolShot) and CheckSpellCosts(classtable.PistolShot, 'PistolShot')) and (talents[classtable.FantheHammer] and talents[classtable.Audacity] and talents[classtable.HiddenOpportunity] and buff[classtable.OpportunityBuff].up and not buff[classtable.AudacityBuff]) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:FindSpell(classtable.PistolShot) and CheckSpellCosts(classtable.PistolShot, 'PistolShot')) and (talents[classtable.FantheHammer] and buff[classtable.OpportunityBuff].up and ( buff[classtable.OpportunityBuff].count >= 1 or buff[classtable.OpportunityBuff].remains <2 )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:FindSpell(classtable.PistolShot) and CheckSpellCosts(classtable.PistolShot, 'PistolShot')) and (talents[classtable.FantheHammer] and buff[classtable.OpportunityBuff].up and ( ComboPointsDeficit >= ( 1 + ( talents[classtable.QuickDraw] + buff[classtable.BroadsideBuff].duration ) * ( talents[classtable.FantheHammer] + 1 ) ) or ComboPoints <= talents[classtable.Ruthlessness] )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:FindSpell(classtable.PistolShot) and CheckSpellCosts(classtable.PistolShot, 'PistolShot')) and (not talents[classtable.FantheHammer] and buff[classtable.OpportunityBuff].up and ( EnergyDeficit >EnergyRegen * 1.5 or ComboPointsDeficit <= 1 + buff[classtable.BroadsideBuff].duration or talents[classtable.QuickDraw] or talents[classtable.Audacity] and not buff[classtable.AudacityBuff] )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:FindSpell(classtable.PoolResource) and CheckSpellCosts(classtable.PoolResource, 'PoolResource')) and cooldown[classtable.PoolResource].ready then
        return classtable.PoolResource
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (talents[classtable.HiddenOpportunity]) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.SinisterStrike) and CheckSpellCosts(classtable.SinisterStrike, 'SinisterStrike')) and cooldown[classtable.SinisterStrike].ready then
        return classtable.SinisterStrike
    end
end
function Outlaw:cds()
    if (MaxDps:FindSpell(classtable.AdrenalineRush) and CheckSpellCosts(classtable.AdrenalineRush, 'AdrenalineRush')) and (not buff[classtable.AdrenalineRushBuff] and ( not finish_condition or not talents[classtable.ImprovedAdrenalineRush] ) or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and talents[classtable.Crackshot] and talents[classtable.ImprovedAdrenalineRush] and ComboPoints <= 2) and cooldown[classtable.AdrenalineRush].ready then
        return classtable.AdrenalineRush
    end
    if (MaxDps:FindSpell(classtable.BladeFlurry) and CheckSpellCosts(classtable.BladeFlurry, 'BladeFlurry')) and (( targets >= 2 - (talents[classtable.UnderhandedUpperHand] and 1 or 0) and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.AdrenalineRushBuff].up ) and buff[classtable.BladeFlurryBuff].remains <gcd) and cooldown[classtable.BladeFlurry].ready then
        return classtable.BladeFlurry
    end
    if (MaxDps:FindSpell(classtable.BladeFlurry) and CheckSpellCosts(classtable.BladeFlurry, 'BladeFlurry')) and (talents[classtable.DeftManeuvers] and not finish_condition and ( targets >= 3 and ComboPointsDeficit == targets + buff[classtable.BroadsideBuff].duration or targets >= 5 )) and cooldown[classtable.BladeFlurry].ready then
        return classtable.BladeFlurry
    end
    if (MaxDps:FindSpell(classtable.RolltheBones) and CheckSpellCosts(classtable.RolltheBones, 'RolltheBones')) and (rtb_reroll or calculateRtbBuffCount() == 0 or calculateRtbBuffMax() <= 2 and (MaxDps.tier and MaxDps.tier[31].count >= 4) or calculateRtbBuffMax() <= 7 and ( cooldown[classtable.ShadowDance].ready or cooldown[classtable.Vanish].ready )) and cooldown[classtable.RolltheBones].ready then
        return classtable.RolltheBones
    end
    if (MaxDps:FindSpell(classtable.KeepItRolling) and CheckSpellCosts(classtable.KeepItRolling, 'KeepItRolling') and talents[classtable.KeepItRolling]) and (not rtb_reroll and calculateRtbBuffCount() >= 3 + (MaxDps.tier and MaxDps.tier[31].count >= 4) and ( not buff[classtable.ShadowDanceBuff].up or calculateRtbBuffCount() >= 6 )) and cooldown[classtable.KeepItRolling].ready then
        return classtable.KeepItRolling
    end
    if (MaxDps:FindSpell(classtable.GhostlyStrike) and CheckSpellCosts(classtable.GhostlyStrike, 'GhostlyStrike') and talents[classtable.GhostlyStrike]) and (calculateEffectiveComboPoints(ComboPoints) <ComboPointsMax) and cooldown[classtable.GhostlyStrike].ready then
        return classtable.GhostlyStrike
    end
    if (MaxDps:FindSpell(classtable.Sepsis) and CheckSpellCosts(classtable.Sepsis, 'Sepsis')) and (talents[classtable.Crackshot] and cooldown[classtable.BetweentheEyes].ready and finish_condition and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) or not talents[classtable.Crackshot] and ttd >11 and buff[classtable.BetweentheEyesBuff].up or ttd <11) and cooldown[classtable.Sepsis].ready then
        return classtable.Sepsis
    end
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( not talents[classtable.Crackshot] or cooldown[classtable.BetweentheEyes].ready )) then
        local stealth_cdsCheck = Outlaw:stealth_cds()
        if stealth_cdsCheck then
            return Outlaw:stealth_cds()
        end
    end
    if (MaxDps:FindSpell(classtable.ThistleTea) and CheckSpellCosts(classtable.ThistleTea, 'ThistleTea')) and (not buff[classtable.ThistleTeaBuff] and ( EnergyDeficit >= 100 or ttd <cooldown[classtable.ThistleTea].charges * 6 )) and cooldown[classtable.ThistleTea].ready then
        return classtable.ThistleTea
    end
    if (MaxDps:FindSpell(classtable.BladeRush) and CheckSpellCosts(classtable.BladeRush, 'BladeRush')) and (EnergyTimeToMax >4 and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.BladeRush].ready then
        return classtable.BladeRush
    end
    if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (MaxDps:Bloodlust() or ttd <30 or buff[classtable.AdrenalineRushBuff].up) and cooldown[classtable.Potion].ready then
        return classtable.Potion
    end
end
function Outlaw:finish()
    if (MaxDps:FindSpell(classtable.BetweentheEyes) and CheckSpellCosts(classtable.BetweentheEyes, 'BetweentheEyes')) and (not talents[classtable.Crackshot] and ( buff[classtable.BetweentheEyesBuff].remains <4 or talents[classtable.ImprovedBetweentheEyes] or talents[classtable.GreenskinsWickers] or (MaxDps.tier and MaxDps.tier[30].count >= 4) ) and not buff[classtable.GreenskinsWickersBuff]) and cooldown[classtable.BetweentheEyes].ready then
        return classtable.BetweentheEyes
    end
    if (MaxDps:FindSpell(classtable.BetweentheEyes) and CheckSpellCosts(classtable.BetweentheEyes, 'BetweentheEyes')) and (talents[classtable.Crackshot] and ( cooldown[classtable.Vanish].remains >45 and cooldown[classtable.ShadowDance].remains >12 )) and cooldown[classtable.BetweentheEyes].ready then
        return classtable.BetweentheEyes
    end
    if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains <ttd and buff[classtable.SliceandDice].refreshable) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    if (MaxDps:FindSpell(classtable.KillingSpree) and CheckSpellCosts(classtable.KillingSpree, 'KillingSpree')) and (debuff[classtable.GhostlyStrikeDeBuff].up or not talents[classtable.GhostlyStrike]) and cooldown[classtable.KillingSpree].ready then
        return classtable.KillingSpree
    end
    if (MaxDps:FindSpell(classtable.ColdBlood) and CheckSpellCosts(classtable.ColdBlood, 'ColdBlood')) and cooldown[classtable.ColdBlood].ready then
        return classtable.ColdBlood
    end
    if (MaxDps:FindSpell(classtable.Dispatch) and CheckSpellCosts(classtable.Dispatch, 'Dispatch')) and cooldown[classtable.Dispatch].ready then
        return classtable.Dispatch
    end
end
function Outlaw:stealth()
    if (MaxDps:FindSpell(classtable.BladeFlurry) and CheckSpellCosts(classtable.BladeFlurry, 'BladeFlurry')) and (talents[classtable.Subterfuge] and talents[classtable.HiddenOpportunity] and targets >= 2 and buff[classtable.BladeFlurryBuff].remains <gcd) and cooldown[classtable.BladeFlurry].ready then
        return classtable.BladeFlurry
    end
    if (MaxDps:FindSpell(classtable.ColdBlood) and CheckSpellCosts(classtable.ColdBlood, 'ColdBlood')) and (finish_condition) and cooldown[classtable.ColdBlood].ready then
        return classtable.ColdBlood
    end
    if (MaxDps:FindSpell(classtable.BetweentheEyes) and CheckSpellCosts(classtable.BetweentheEyes, 'BetweentheEyes')) and (finish_condition and talents[classtable.Crackshot] and ( not buff[classtable.ShadowmeldBuff] or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) )) and cooldown[classtable.BetweentheEyes].ready then
        return classtable.BetweentheEyes
    end
    if (MaxDps:FindSpell(classtable.Dispatch) and CheckSpellCosts(classtable.Dispatch, 'Dispatch')) and (finish_condition) and cooldown[classtable.Dispatch].ready then
        return classtable.Dispatch
    end
    if (MaxDps:FindSpell(classtable.PistolShot) and CheckSpellCosts(classtable.PistolShot, 'PistolShot')) and (talents[classtable.Crackshot] and talents[classtable.FantheHammer] >= 2 and buff[classtable.OpportunityBuff].count >= 6 and ( buff[classtable.BroadsideBuff].up and ComboPoints <= 1 or buff[classtable.GreenskinsWickersBuff].up )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (talents[classtable.HiddenOpportunity]) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    vanish_opportunity_condition = not talents[classtable.ShadowDance] and talents[classtable.FantheHammer] + talents[classtable.QuickDraw] + talents[classtable.Audacity] <talents[classtable.CounttheOdds] + talents[classtable.KeepItRolling]
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (talents[classtable.HiddenOpportunity] and not talents[classtable.Crackshot] and not buff[classtable.AudacityBuff] and ( vanish_opportunity_condition or buff[classtable.OpportunityBuff].count < 1 ) and ambush_condition) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (( not talents[classtable.HiddenOpportunity] or talents[classtable.Crackshot] ) and finish_condition) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance') and talents[classtable.ShadowDance]) and (talents[classtable.Crackshot] and finish_condition) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    shadow_dance_condition = buff[classtable.BetweentheEyesBuff].up and ( not talents[classtable.HiddenOpportunity] or not buff[classtable.AudacityBuff] and ( talents[classtable.FantheHammer] <2 or not buff[classtable.OpportunityBuff] ) ) and not talents[classtable.Crackshot]
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance') and talents[classtable.ShadowDance]) and (not talents[classtable.KeepItRolling] and shadow_dance_condition and buff[classtable.SliceandDiceBuff].up and ( finish_condition or talents[classtable.HiddenOpportunity] ) and ( not talents[classtable.HiddenOpportunity] or not cooldown[classtable.Vanish].ready )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance') and talents[classtable.ShadowDance]) and (talents[classtable.KeepItRolling] and shadow_dance_condition and ( cooldown[classtable.KeepItRolling].remains <= 30 or cooldown[classtable.KeepItRolling].remains >120 and ( finish_condition or talents[classtable.HiddenOpportunity] ) )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.Shadowmeld) and CheckSpellCosts(classtable.Shadowmeld, 'Shadowmeld')) and (finish_condition and not cooldown[classtable.Vanish].ready and not cooldown[classtable.ShadowDance].ready) and cooldown[classtable.Shadowmeld].ready then
        return classtable.Shadowmeld
    end
end
function Outlaw:stealth_cds()
    vanish_opportunity_condition = not talents[classtable.ShadowDance] and (talents[classtable.FantheHammer] and 1 or 0) + (talents[classtable.QuickDraw] and 1 or 0) + (talents[classtable.Audacity] and 1 or 0) <(talents[classtable.CounttheOdds] and 1 or 0) + (talents[classtable.KeepItRolling] and 1 or 0)
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (talents[classtable.HiddenOpportunity] and not talents[classtable.Crackshot] and not buff[classtable.AudacityBuff] and ( vanish_opportunity_condition or buff[classtable.OpportunityBuff].count < 1 ) and ambush_condition) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (( not talents[classtable.HiddenOpportunity] or talents[classtable.Crackshot] ) and finish_condition) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance') and talents[classtable.ShadowDance]) and (talents[classtable.Crackshot] and finish_condition) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    shadow_dance_condition = buff[classtable.BetweentheEyesBuff].up and ( not talents[classtable.HiddenOpportunity] or not buff[classtable.AudacityBuff] and ( talents[classtable.FantheHammer] <2 or not buff[classtable.OpportunityBuff] ) ) and not talents[classtable.Crackshot]
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance') and talents[classtable.ShadowDance]) and (not talents[classtable.KeepItRolling] and shadow_dance_condition and buff[classtable.SliceandDiceBuff].up and ( finish_condition or talents[classtable.HiddenOpportunity] ) and ( not talents[classtable.HiddenOpportunity] or not cooldown[classtable.Vanish].ready )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance') and talents[classtable.ShadowDance]) and (talents[classtable.KeepItRolling] and shadow_dance_condition and ( cooldown[classtable.KeepItRolling].remains <= 30 or cooldown[classtable.KeepItRolling].remains >120 and ( finish_condition or talents[classtable.HiddenOpportunity] ) )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.Shadowmeld) and CheckSpellCosts(classtable.Shadowmeld, 'Shadowmeld')) and (finish_condition and not cooldown[classtable.Vanish].ready and not cooldown[classtable.ShadowDance].ready) and cooldown[classtable.Shadowmeld].ready then
        return classtable.Shadowmeld
    end
end

function Rogue:Outlaw()
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
    classtable.SkullAndCrossbones = 199603
    classtable.TrueBearing = 193359
    classtable.RuthlessPrecision = 193357
    classtable.GrandMelee = 193358
    classtable.BuriedTreasure = 199600
    classtable.Broadside = 193356
    classtable.AudacityBuff = 386270
    classtable.OpportunityBuff = 195627
    classtable.BroadsideBuff = 193356
    classtable.AdrenalineRushBuff = 13750
    classtable.BladeFlurryBuff = 13877
    classtable.ShadowDanceBuff = 185422
    classtable.BetweentheEyesBuff = 315341
    classtable.ThistleTeaBuff = 381623
    classtable.GreenskinsWickersBuff = 394131
    classtable.SliceandDiceBuff = 315496
    classtable.GhostlyStrikeDeBuff = 196937
    classtable.ShadowmeldBuff = 58984
    PreCombatUpdate()
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up or buff[classtable.AudacityBuff].up)) then
        classtable.Ambush = 430023
    else
        classtable.Ambush = 8676
    end

    --if (MaxDps:FindSpell(classtable.Stealth) and CheckSpellCosts(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
    --    return classtable.Stealth
    --end
    --if (MaxDps:FindSpell(classtable.Kick) and CheckSpellCosts(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
    --    return classtable.Kick
    --end
    local rtb_buffs_will_lose = ( (buff[classtable.BuriedTreasureBuff].duration) + (buff[classtable.GrandMeleeBuff].duration) and targets <2 and 1 or 0)
    if talents[classtable.Crackshot] and not (MaxDps.tier and MaxDps.tier[31].count >= 4) then
        rtb_reroll = ( not (buff[classtable.TrueBearingBuff].duration) and talents[classtable.HiddenOpportunity] or not (buff[classtable.BroadsideBuff].duration) and not talents[classtable.HiddenOpportunity] ) and rtb_buffs_will_lose <= 1
    end
    if talents[classtable.Crackshot] and (MaxDps.tier and MaxDps.tier[31].count >= 4) then
        rtb_reroll = ( rtb_buffs_will_lose <= 1 + buff[classtable.LoadedDiceBuff].duration )
    end
    if not talents[classtable.Crackshot] and talents[classtable.HiddenOpportunity] then
        rtb_reroll = not (buff[classtable.SkullandCrossbonesBuff].duration) and ( rtb_buffs_will_lose <2 + (buff[classtable.GrandMeleeBuff].duration) and targets <2)
    end
    local rtb_buffs_longer = 0
    local rtb_buffs_normal = 1
    rtb_reroll = rtb_reroll and rtb_buffs_longer == 0 or rtb_buffs_normal == 0 and rtb_buffs_longer >= 1 and calculateRtbBuffCount() <6 and calculateRtbBuffMax() <= 39 and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.LoadedDiceBuff].up
    if ttd <12 then
        rtb_reroll = false
    end
    ambush_condition = ( talents[classtable.HiddenOpportunity] or ComboPointsDeficit >= 2 + (talents[classtable.ImprovedAmbush] and 1 or 0) + buff[classtable.BroadsideBuff].duration ) and Energy >= 50
    finish_condition = calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax - 1 - ( (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and talents[classtable.Crackshot] and 1 or 0 )
    --blade_flurry_sync = targets <2 and TODO or buff[classtable.BladeFlurryBuff].remains >gcd
    local cdsCheck = Outlaw:cds()
    if cdsCheck then
        return cdsCheck
    end
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up)) then
        local stealthCheck = Outlaw:stealth()
        if stealthCheck then
            return Outlaw:stealth()
        end
    end
    if (finish_condition) then
        local finishCheck = Outlaw:finish()
        if finishCheck then
            return Outlaw:finish()
        end
    end
    local buildCheck = Outlaw:build()
    if buildCheck then
        return buildCheck
    end
    if (MaxDps:FindSpell(classtable.ArcanePulse) and CheckSpellCosts(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        return classtable.ArcanePulse
    end
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( not talents[classtable.Crackshot] or cooldown[classtable.BetweentheEyes].ready )) then
        local stealth_cdsCheck = Outlaw:stealth_cds()
        if stealth_cdsCheck then
            return Outlaw:stealth_cds()
        end
    end

end
