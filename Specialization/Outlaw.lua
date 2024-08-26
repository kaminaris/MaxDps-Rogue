local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

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

local Outlaw = {}

local rtb_reroll
local ambush_condition
local finish_condition
local blade_flurry_sync

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

local function calculateRtbBuffMin()
    local buffs = MaxDps.FrameData.buff
    local rollTheBonesBuffMin = 0
    if buffs[classtable.SkullAndCrossbones].duration then
        if buffs[classtable.SkullAndCrossbones].duration < rollTheBonesBuffMin then
            rollTheBonesBuffMin = buffs[classtable.SkullAndCrossbones].duration
        end
    end
    if buffs[classtable.TrueBearing].duration then
        if buffs[classtable.TrueBearing].duration < rollTheBonesBuffMin then
            rollTheBonesBuffMin = buffs[classtable.TrueBearing].duration
        end
    end
    if buffs[classtable.RuthlessPrecision].duration then
        if buffs[classtable.RuthlessPrecision].duration < rollTheBonesBuffMin then
            rollTheBonesBuffMin = buffs[classtable.RuthlessPrecision].duration
        end
    end
    if buffs[classtable.GrandMelee].duration then
        if buffs[classtable.GrandMelee].duration < rollTheBonesBuffMin then
            rollTheBonesBuffMin = buffs[classtable.GrandMelee].duration
        end
    end
    if buffs[classtable.BuriedTreasure].duration then
        if buffs[classtable.BuriedTreasure].duration < rollTheBonesBuffMin then
            rollTheBonesBuffMin = buffs[classtable.BuriedTreasure].duration
        end
    end
    if buffs[classtable.Broadside].duration then
        if buffs[classtable.Broadside].duration < rollTheBonesBuffMin then
            rollTheBonesBuffMin = buffs[classtable.Broadside].duration
        end
    end
    return rollTheBonesBuffMin
end

function Outlaw:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
    --    return classtable.Stealth
    --end
    --if (MaxDps:CheckSpellUsable(classtable.AdrenalineRush, 'AdrenalineRush')) and (talents[classtable.ImprovedAdrenalineRush] and not buff[classtable.AdrenalineRushBuff].up) and cooldown[classtable.AdrenalineRush].ready then
    --    return classtable.AdrenalineRush
    --end
    --if (MaxDps:CheckSpellUsable(classtable.RolltheBones, 'RolltheBones')) and (not buff[classtable.RolltheBonesBuff].up) and cooldown[classtable.RolltheBones].ready then
    --    return classtable.RolltheBones
    --end
    --if (MaxDps:CheckSpellUsable(classtable.AdrenalineRush, 'AdrenalineRush')) and (talents[classtable.ImprovedAdrenalineRush] and not buff[classtable.AdrenalineRushBuff].up) and cooldown[classtable.AdrenalineRush].ready then
    --    return classtable.AdrenalineRush
    --end
    --if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].refreshable) and cooldown[classtable.SliceandDice].ready then
    --    return classtable.SliceandDice
    --end
end
function Outlaw:build()
    if (MaxDps:CheckSpellUsable(classtable.EchoingReprimand, 'EchoingReprimand')) and cooldown[classtable.EchoingReprimand].ready then
        MaxDps:GlowCooldown(classtable.EchoingReprimand, cooldown[classtable.EchoingReprimand].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (talents[classtable.HiddenOpportunity] and buff[classtable.AudacityBuff].up) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:CheckSpellUsable(classtable.PistolShot, 'PistolShot')) and (talents[classtable.FantheHammer] and talents[classtable.Audacity] and talents[classtable.HiddenOpportunity] and buff[classtable.OpportunityBuff].up and not buff[classtable.AudacityBuff].up) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:CheckSpellUsable(classtable.PistolShot, 'PistolShot')) and (talents[classtable.FantheHammer] and buff[classtable.OpportunityBuff].up and ( buff[classtable.OpportunityBuff].count >= buff[classtable.OpportunityBuff].maxStacks or buff[classtable.OpportunityBuff].remains <2 )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:CheckSpellUsable(classtable.PistolShot, 'PistolShot')) and (talents[classtable.FantheHammer] and buff[classtable.OpportunityBuff].up and ( ComboPointsDeficit >= ( 1 + ( (talents[classtable.QuickDraw] and talents[classtable.QuickDraw] or 0) + buff[classtable.BroadsideBuff].duration ) * ( (talents[classtable.FantheHammer] and talents[classtable.FantheHammer] or 0) + 1 ) ) or ComboPoints <= (talents[classtable.Ruthlessness] and talents[classtable.Ruthlessness] or 0) )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:CheckSpellUsable(classtable.PistolShot, 'PistolShot')) and (not talents[classtable.FantheHammer] and buff[classtable.OpportunityBuff].up and ( EnergyDeficit >EnergyRegen * 1.5 or ComboPointsDeficit <= 1 + buff[classtable.BroadsideBuff].duration or talents[classtable.QuickDraw] or talents[classtable.Audacity] and not buff[classtable.AudacityBuff].up )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (talents[classtable.HiddenOpportunity]) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:CheckSpellUsable(classtable.SinisterStrike, 'SinisterStrike')) and cooldown[classtable.SinisterStrike].ready then
        return classtable.SinisterStrike
    end
end
function Outlaw:cds()
    if (MaxDps:CheckSpellUsable(classtable.AdrenalineRush, 'AdrenalineRush')) and (not buff[classtable.AdrenalineRushBuff].up and ( not finish_condition or not talents[classtable.ImprovedAdrenalineRush] ) or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and talents[classtable.Crackshot] and talents[classtable.ImprovedAdrenalineRush] and ComboPoints <= 2) and cooldown[classtable.AdrenalineRush].ready then
        MaxDps:GlowCooldown(classtable.AdrenalineRush, cooldown[classtable.AdrenalineRush].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeFlurry, 'BladeFlurry')) and (targets >= 2 and buff[classtable.BladeFlurryBuff].remains <gcd) and cooldown[classtable.BladeFlurry].ready then
        MaxDps:GlowCooldown(classtable.BladeFlurry, cooldown[classtable.BladeFlurry].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeFlurry, 'BladeFlurry')) and (talents[classtable.DeftManeuvers] and not finish_condition and ( targets >= 3 and ComboPointsDeficit == targets + buff[classtable.BroadsideBuff].duration or targets >= 5 )) and cooldown[classtable.BladeFlurry].ready then
        MaxDps:GlowCooldown(classtable.BladeFlurry, cooldown[classtable.BladeFlurry].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RolltheBones, 'RolltheBones')) and (rtb_reroll or calculateRtbBuffCount() == 0 or calculateRtbBuffMax() <= 7 and cooldown[classtable.Vanish].ready and talents[classtable.Crackshot]) and cooldown[classtable.RolltheBones].ready then
        MaxDps:GlowCooldown(classtable.RolltheBones, cooldown[classtable.RolltheBones].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KeepItRolling, 'KeepItRolling')) and (calculateRtbBuffCount() >= 4 and ( calculateRtbBuffMin() <2 or buff[classtable.BroadsideBuff].up )) and cooldown[classtable.KeepItRolling].ready then
        MaxDps:GlowCooldown(classtable.KeepItRolling, cooldown[classtable.KeepItRolling].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.GhostlyStrike, 'GhostlyStrike')) and (ComboPoints <ComboPointsMax) and cooldown[classtable.GhostlyStrike].ready then
        MaxDps:GlowCooldown(classtable.GhostlyStrike, cooldown[classtable.GhostlyStrike].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.KillingSpree, 'KillingSpree')) and (finish_condition and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.KillingSpree].ready then
        MaxDps:GlowCooldown(classtable.KillingSpree, cooldown[classtable.KillingSpree].ready)
    end
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( not talents[classtable.Crackshot] or cooldown[classtable.BetweentheEyes].ready )) then
        local stealth_cdsCheck = Outlaw:stealth_cds()
        if stealth_cdsCheck then
            return Outlaw:stealth_cds()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThistleTea, 'ThistleTea')) and (not buff[classtable.ThistleTeaBuff].up and ( EnergyDeficit >= 150 or ttd <cooldown[classtable.ThistleTea].charges * 6 )) and cooldown[classtable.ThistleTea].ready then
        MaxDps:GlowCooldown(classtable.ThistleTea, cooldown[classtable.ThistleTea].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BladeRush, 'BladeRush')) and (EnergyTimeToMax >4 and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up)) and cooldown[classtable.BladeRush].ready then
        MaxDps:GlowCooldown(classtable.BladeRush, cooldown[classtable.BladeRush].ready)
    end
end
function Outlaw:finish()
    if (MaxDps:CheckSpellUsable(classtable.BetweentheEyes, 'BetweentheEyes')) and (not talents[classtable.Crackshot] and ( buff[classtable.BetweentheEyesBuff].remains <4 or talents[classtable.ImprovedBetweentheEyes] or talents[classtable.GreenskinsWickers] ) and not buff[classtable.GreenskinsWickersBuff].up) and cooldown[classtable.BetweentheEyes].ready then
        return classtable.BetweentheEyes
    end
    if (MaxDps:CheckSpellUsable(classtable.BetweentheEyes, 'BetweentheEyes')) and (talents[classtable.Crackshot] and ( cooldown[classtable.Vanish].remains >45 or talents[classtable.UnderhandedUpperHand] and talents[classtable.WithoutATrace] and ( buff[classtable.AdrenalineRushBuff].remains >10 or not buff[classtable.AdrenalineRushBuff].up and cooldown[classtable.AdrenalineRush].remains >45 ) ) and ( targets >8 or math.huge <targets )) and cooldown[classtable.BetweentheEyes].ready then
        return classtable.BetweentheEyes
    end
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].remains <ttd and buff[classtable.SliceandDiceBuff].refreshable) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and cooldown[classtable.ColdBlood].ready then
        MaxDps:GlowCooldown(classtable.ColdBlood, cooldown[classtable.ColdBlood].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CoupdeGrace, 'CoupdeGrace')) and cooldown[classtable.CoupdeGrace].ready then
        return classtable.CoupdeGrace
    end
    if (MaxDps:CheckSpellUsable(classtable.Dispatch, 'Dispatch')) and cooldown[classtable.Dispatch].ready then
        return classtable.Dispatch
    end
end
function Outlaw:stealth()
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and (finish_condition) and cooldown[classtable.ColdBlood].ready then
        MaxDps:GlowCooldown(classtable.ColdBlood, cooldown[classtable.ColdBlood].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BetweentheEyes, 'BetweentheEyes')) and (finish_condition and talents[classtable.Crackshot] and ( not buff[classtable.ShadowmeldBuff].up or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) )) and cooldown[classtable.BetweentheEyes].ready then
        return classtable.BetweentheEyes
    end
    if (MaxDps:CheckSpellUsable(classtable.Dispatch, 'Dispatch')) and (finish_condition) and cooldown[classtable.Dispatch].ready then
        return classtable.Dispatch
    end
    if (MaxDps:CheckSpellUsable(classtable.PistolShot, 'PistolShot')) and (talents[classtable.Crackshot] and (talents[classtable.FantheHammer] and talents[classtable.FantheHammer] or 0) >= 2 and buff[classtable.OpportunityBuff].count >= 6 and ( buff[classtable.BroadsideBuff].up and ComboPoints <= 1 or buff[classtable.GreenskinsWickersBuff].up )) and cooldown[classtable.PistolShot].ready then
        return classtable.PistolShot
    end
    if (MaxDps:CheckSpellUsable(classtable.Ambush, 'Ambush')) and (talents[classtable.HiddenOpportunity]) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
end
function Outlaw:stealth_cds()
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (talents[classtable.UnderhandedUpperHand] and talents[classtable.Subterfuge] and ( buff[classtable.AdrenalineRushBuff].up or not talents[classtable.WithoutATrace] and talents[classtable.Crackshot] ) and ( finish_condition or not talents[classtable.Crackshot] and ( ambush_condition or not talents[classtable.HiddenOpportunity] ) )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.UnderhandedUpperHand] and talents[classtable.Crackshot] and finish_condition) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.UnderhandedUpperHand] and not talents[classtable.Crackshot] and talents[classtable.HiddenOpportunity] and not buff[classtable.AudacityBuff].up and buff[classtable.OpportunityBuff].count <buff[classtable.OpportunityBuff].maxStacks and ambush_condition) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.UnderhandedUpperHand] and not talents[classtable.Crackshot] and not talents[classtable.HiddenOpportunity] and talents[classtable.FatefulEnding] and ( not buff[classtable.FateboundLuckyCoinBuff].up and ( buff[classtable.FateboundCoinTailsBuff].count >= 5 or buff[classtable.FateboundCoinHeadsBuff].count >= 5 ) or buff[classtable.FateboundLuckyCoinBuff].up and not cooldown[classtable.BetweentheEyes].ready )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.UnderhandedUpperHand] and not talents[classtable.Crackshot] and not talents[classtable.HiddenOpportunity] and not talents[classtable.FatefulEnding] and talents[classtable.TakeEmBySurprise] and not buff[classtable.TakeEmBySurpriseBuff].up) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and (finish_condition and not cooldown[classtable.Vanish].ready) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
end

function Outlaw:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
        return classtable.Stealth
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    rtb_reroll = ( (buff[classtable.BuriedTreasureBuff].duration) + (buff[classtable.GrandMeleeBuff].duration) and targets <2 and math.huge >12 and 1 <2 )
    if talents[classtable.LoadedDice] then
        rtb_reroll = buff[classtable.LoadedDiceBuff].up
    end
    local rtb_buffs_longer = 0
    local rtb_buffs_normal = 1
    rtb_reroll = rtb_reroll and rtb_buffs_longer == 0 or rtb_buffs_normal == 0 and rtb_buffs_longer >= 1 and calculateRtbBuffCount() <6 and calculateRtbBuffMax() <= 39 and not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.LoadedDiceBuff].up
    if not ( targets >12 or (targets >1) and ( math.huge - targets ) <6 or ttd >12 ) or ttd <12 then
        rtb_reroll = not ( targets >12 or (targets >1) and ( math.huge - targets ) <6 or ttd >12 ) or ttd <12
    end
    ambush_condition = ( talents[classtable.HiddenOpportunity] or ComboPointsDeficit >= 2 + (talents[classtable.ImprovedAmbush] and talents[classtable.ImprovedAmbush] or 0) + buff[classtable.BroadsideBuff].duration ) and Energy >= 50
    finish_condition = calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax - 1 - ( (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and talents[classtable.Crackshot] or ( talents[classtable.HandofFate] or talents[classtable.FlawlessForm] ) and talents[classtable.HiddenOpportunity] and ( buff[classtable.AudacityBuff].up or buff[classtable.OpportunityBuff].up ) and 1 or 0)
    blade_flurry_sync = targets <2 and math.huge >20 or buff[classtable.BladeFlurryBuff].remains >gcd
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
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        return classtable.ArcanePulse
    end
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( not talents[classtable.Crackshot] or cooldown[classtable.BetweentheEyes].ready )) then
        local stealth_cdsCheck = Outlaw:stealth_cds()
        if stealth_cdsCheck then
            return Outlaw:stealth_cds()
        end
    end
end
function Rogue:Outlaw()
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    classtable.SkullAndCrossbones = 199603
    classtable.TrueBearing = 193359
    classtable.RuthlessPrecision = 193357
    classtable.GrandMelee = 193358
    classtable.BuriedTreasure = 199600
    classtable.Broadside = 193356
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.AdrenalineRushBuff = 13750
    classtable.RolltheBonesBuff = 0
    classtable.AudacityBuff = 386270
    classtable.OpportunityBuff = 195627
    classtable.BroadsideBuff = 193356
    classtable.BladeFlurryBuff = 13877
    classtable.ThistleTeaBuff = 381623
    classtable.BetweentheEyesBuff = 315341
    classtable.GreenskinsWickersBuff = 394131
    classtable.SliceandDiceBuff = 315496
    classtable.ShadowmeldBuff = 58984
    classtable.FateboundLuckyCoinBuff = 0
    classtable.FateboundCoinTailsBuff = 0
    classtable.FateboundCoinHeadsBuff = 0
    classtable.TakeEmBySurpriseBuff = 0
    classtable.BuriedTreasureBuff = 199600
    classtable.GrandMeleeBuff = 193358
    classtable.LoadedDiceBuff = 256171

    local precombatCheck = Outlaw:precombat()
    if precombatCheck then
        return Outlaw:precombat()
    end

    local callactionCheck = Outlaw:callaction()
    if callactionCheck then
        return Outlaw:callaction()
    end
end
