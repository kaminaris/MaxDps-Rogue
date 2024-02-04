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

local trinket_sync_slot
local single_target
local regen_saturated
local not_pooling
local sepsis_sync_remains
local deathmark_ma_condition
local deathmark_kingsbane_condition
local deathmark_condition
local use_filler
local scent_effective_max_stacks
local scent_saturation

local Assassination = {}

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
    local itemID = GetInventoryItemID('player', slot)
    local startTime, duration, enable = GetItemCooldown(itemID)
    if duration == 0 then return true else return false end
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
			return MaxDps.FrameData.cpMaxSpend
		end
	end
	return comboPoints
end


function Rogue:PoisonedBleeds(timeShift)
	local poisoned = 0
	local usedNamePlates = false
	for i, frame in pairs(C_NamePlate.GetNamePlates()) do
		usedNamePlates = true
		local unit = frame.UnitFrame.unit
		if frame:IsVisible() then
			--MaxDps:CollectAura(unit, timeShift, debuff, 'PLAYER|HARMFUL')
			--if debuff[classtable.DeadlyPoisonDot].up then
			--	poisoned = poisoned +
			--			debuff[classtable.Rupture].count +
			--			debuff[classtable.MutilatedFlesh].count +
			--			debuff[classtable.SerratedBoneSpike].count +
			--			debuff[classtable.Garrote].count +
			--			debuff[classtable.InternalBleeding].count
			--end
            if debuff[classtable.DeadlyPoisonDot].up then
                for index=0,40 do
                    local auraData = C_UnitAuras.GetAuraDataBySlot(unit, index)
                    if auraData then
                        if (auraData.spellId == classtable.Rupture or
                            auraData.spellId == classtable.MutilatedFlesh or
                            auraData.spellId == classtable.SerratedBoneSpike or
                            auraData.spellId == classtable.Garrote or
                            auraData.spellId == classtable.InternalBleeding
                        ) then
                            poisoned = poisoned + 1
                        end
                    end
                end
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


local function PreCombatUpdate()
end

function Assassination:precombat()
    --if (MaxDps:FindSpell(classtable.ApplyPoison) and CheckSpellCosts(classtable.ApplyPoison, 'ApplyPoison')) and cooldown[classtable.ApplyPoison].ready then
    --    return classtable.ApplyPoison
    --end
    --if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
    --    return classtable.Flask
    --end
    --if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
    --    return classtable.Augmentation
    --end
    --if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
    --    return classtable.Food
    --end
    --if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
    --    return classtable.SnapshotStats
    --end
    --if (MaxDps:FindSpell(classtable.Stealth) and CheckSpellCosts(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
    --    return classtable.Stealth
    --end
    --if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and cooldown[classtable.SliceandDice].ready then
    --    return classtable.SliceandDice
    --end
end
function Assassination:cds()
    deathmark_ma_condition = not talents[classtable.MasterAssassin] or debuff[classtable.GarroteDeBuff].up
    deathmark_kingsbane_condition = not talents[classtable.Kingsbane] or cooldown[classtable.Kingsbane].remains <= 2
    deathmark_condition = not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and debuff[classtable.RuptureDeBuff].up and buff[classtable.EnvenomBuff].up and not debuff[classtable.DeathmarkDeBuff].up and deathmark_ma_condition and deathmark_kingsbane_condition
    if (MaxDps:FindSpell(classtable.Sepsis) and CheckSpellCosts(classtable.Sepsis, 'Sepsis') and talents[classtable.Sepsis]) and (debuff[classtable.RuptureDeBuff].remains >20 and ( not talents[classtable.ImprovedGarrote] and debuff[classtable.GarroteDeBuff].up or talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].up and debuff[classtable.GarroteDeBuff].remains <= 1 ) and ( ttd >10 or ttd <10 )) and cooldown[classtable.Sepsis].ready then
        return classtable.Sepsis
    end
    local itemsCheck = Assassination:items()
    if itemsCheck then
        return itemsCheck
    end
    if (MaxDps:FindSpell(classtable.Deathmark) and CheckSpellCosts(classtable.Deathmark, 'Deathmark')) and (deathmark_condition or ttd <= 20) and cooldown[classtable.Deathmark].ready then
        return classtable.Deathmark
    end
    local shivCheck = Assassination:shiv()
    if shivCheck then
        return shivCheck
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance')) and (talents[classtable.Kingsbane] and buff[classtable.EnvenomBuff].up and ( cooldown[classtable.Deathmark].remains >= 50 or deathmark_condition )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.Kingsbane) and CheckSpellCosts(classtable.Kingsbane, 'Kingsbane') and talents[classtable.Kingsbane]) and (( debuff[classtable.ShivDeBuff].up or cooldown[classtable.Shiv].remains <6 ) and buff[classtable.EnvenomBuff].up and ( cooldown[classtable.Deathmark].remains >= 50 or debuff[classtable.DeathmarkDeBuff].up ) or ttd <= 15) and cooldown[classtable.Kingsbane].ready then
        return classtable.Kingsbane
    end
    if (MaxDps:FindSpell(classtable.ThistleTea) and CheckSpellCosts(classtable.ThistleTea, 'ThistleTea')) and (not buff[classtable.ThistleTeaBuff].up and ( EnergyDeficit >= 100 + EnergyRegenCombined and ( not talents[classtable.Kingsbane] or cooldown[classtable.ThistleTea].charges >= 2 ) or ( debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.KingsbaneDeBuff].remains <6 or not talents[classtable.Kingsbane] and debuff[classtable.DeathmarkDeBuff].up ) or ttd <cooldown[classtable.ThistleTea].charges * 6 )) and cooldown[classtable.ThistleTea].ready then
        return classtable.ThistleTea
    end
    local misc_cdsCheck = Assassination:misc_cds()
    if misc_cdsCheck then
        return misc_cdsCheck
    end
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.MasterAssassin].remains == 0) then
        local vanishCheck = Assassination:vanish()
        if vanishCheck then
            return Assassination:vanish()
        end
    end
    if (MaxDps:FindSpell(classtable.ColdBlood) and CheckSpellCosts(classtable.ColdBlood, 'ColdBlood')) and (ComboPoints >= 4) and cooldown[classtable.ColdBlood].ready then
        return classtable.ColdBlood
    end
end
function Assassination:direct()
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= 4 + (cooldown[classtable.Deathmark].ready and 1 or 0) and ( not_pooling or debuff[classtable.AmplifyingPoisonDeBuff].count >= 20 or calculateEffectiveComboPoints(ComboPoints) >ComboPointsMax or not single_target )) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    use_filler = ComboPointsDeficit >1 or not_pooling or not single_target
    if (MaxDps:FindSpell(classtable.Mutilate) and CheckSpellCosts(classtable.Mutilate, 'Mutilate')) and (talents[classtable.CausticSpatter] and debuff[classtable.RuptureDeBuff].up and ( not debuff[classtable.CausticSpatterDeBuff].up or debuff[classtable.CausticSpatterDeBuff].remains <= 2 ) and use_filler and not single_target) and cooldown[classtable.Mutilate].ready then
        return classtable.Mutilate
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (talents[classtable.CausticSpatter] and debuff[classtable.RuptureDeBuff].up and ( not debuff[classtable.CausticSpatterDeBuff].up or debuff[classtable.CausticSpatterDeBuff].remains <= 2 ) and use_filler and not single_target) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.SerratedBoneSpike) and CheckSpellCosts(classtable.SerratedBoneSpike, 'SerratedBoneSpike')) and (use_filler and not debuff[classtable.SerratedBoneSpikeDebuffDeBuff].up) and cooldown[classtable.SerratedBoneSpike].ready then
        return classtable.SerratedBoneSpike
    end
    if (MaxDps:FindSpell(classtable.SerratedBoneSpike) and CheckSpellCosts(classtable.SerratedBoneSpike, 'SerratedBoneSpike')) and (use_filler and not debuff[classtable.SerratedBoneSpikeDebuffDeBuff].up) and cooldown[classtable.SerratedBoneSpike].ready then
        return classtable.SerratedBoneSpike
    end
    if (MaxDps:FindSpell(classtable.SerratedBoneSpike) and CheckSpellCosts(classtable.SerratedBoneSpike, 'SerratedBoneSpike')) and (use_filler and buff[classtable.MasterAssassin].remains <0.8 and ( ttd <= 5 or cooldown[classtable.SerratedBoneSpike].maxCharges - cooldown[classtable.SerratedBoneSpike].charges <= 0.25 )) and cooldown[classtable.SerratedBoneSpike].ready then
        return classtable.SerratedBoneSpike
    end
    if (MaxDps:FindSpell(classtable.SerratedBoneSpike) and CheckSpellCosts(classtable.SerratedBoneSpike, 'SerratedBoneSpike')) and (use_filler and buff[classtable.MasterAssassin].remains <0.8 and not single_target and debuff[classtable.ShivDeBuff].up) and cooldown[classtable.SerratedBoneSpike].ready then
        return classtable.SerratedBoneSpike
    end
    if (MaxDps:FindSpell(classtable.EchoingReprimand) and CheckSpellCosts(classtable.EchoingReprimand, 'EchoingReprimand')) and (use_filler or ttd <20) and cooldown[classtable.EchoingReprimand].ready then
        return classtable.EchoingReprimand
    end
    if (MaxDps:FindSpell(classtable.FanofKnives) and CheckSpellCosts(classtable.FanofKnives, 'FanofKnives')) and (use_filler and ( targets >= 2 + (IsStealthed() or buff[classtable.ShadowDanceBuff].up and 1 or 0) + (talents[classtable.DragontemperedBlades] and 1 or 0) )) and cooldown[classtable.FanofKnives].ready then
        return classtable.FanofKnives
    end
    if (MaxDps:FindSpell(classtable.FanofKnives) and CheckSpellCosts(classtable.FanofKnives, 'FanofKnives')) and (use_filler and targets >= 3) and cooldown[classtable.FanofKnives].ready then
        return classtable.FanofKnives
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (use_filler and ( buff[classtable.BlindsideBuff].up or buff[classtable.SepsisBuffBuff].remains <= 1 or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) ) and ( not debuff[classtable.KingsbaneDeBuff].up or not debuff[classtable.DeathmarkDeBuff].up or buff[classtable.BlindsideBuff].up )) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.Mutilate) and CheckSpellCosts(classtable.Mutilate, 'Mutilate')) and (use_filler and targets == 2) and cooldown[classtable.Mutilate].ready then
        return classtable.Mutilate
    end
    if (MaxDps:FindSpell(classtable.Mutilate) and CheckSpellCosts(classtable.Mutilate, 'Mutilate')) and (use_filler) and cooldown[classtable.Mutilate].ready then
        return classtable.Mutilate
    end
end
function Assassination:dot()
    scent_effective_max_stacks = ( targets * (talents[classtable.ScentofBlood] and 1 or 0) * 2 )
    scent_saturation = buff[classtable.ScentofBloodBuff].count >= (scent_effective_max_stacks and 1 or 0)
    if (MaxDps:FindSpell(classtable.CrimsonTempest) and CheckSpellCosts(classtable.CrimsonTempest, 'CrimsonTempest') and talents[classtable.CrimsonTempest]) and (targets >= 3 + (MaxDps.tier and MaxDps.tier[31].count >= 4) and debuff[classtable.CrimsonTempest].refreshable and debuff[classtable.CrimsonTempest].remains <= 1 and calculateEffectiveComboPoints(ComboPoints) >= 4 and EnergyRegenCombined >25 and not cooldown[classtable.Deathmark].ready and ttd - buff[classtable.CrimsonTempest].remains >6) and cooldown[classtable.CrimsonTempest].ready then
        return classtable.CrimsonTempest
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and (ComboPointsDeficit >= 1 and ( debuff[classtable.Garrote].remains <= 1 ) and debuff[classtable.Garrote].refreshable and ttd - debuff[classtable.Garrote].remains >12) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and (ComboPointsDeficit >= 1 and ( debuff[classtable.Garrote].remains <= 1 ) and debuff[classtable.Garrote].refreshable and not regen_saturated and targets >= 2 and ttd - debuff[classtable.Garrote].remains >12) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= 4 and ( debuff[classtable.Rupture].remains <= 1 ) and debuff[classtable.Rupture].refreshable and ttd - debuff[classtable.Rupture].remains >( 4 + ( (talents[classtable.DashingScoundrel] and 1 or 0) * 5 ) + ( regen_saturated and 1 or 0 * 6 ) )) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= 4 and ( debuff[classtable.Rupture].remains <= 1 ) and debuff[classtable.Rupture].refreshable and ( not regen_saturated or not scent_saturation ) and ttd - debuff[classtable.Rupture].remains >( 4 + ( (talents[classtable.DashingScoundrel] and 1 or 0) * 5 ) + ( regen_saturated and 1 or 0 * 6 ) )) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and (debuff[classtable.Garrote].refreshable and ComboPointsDeficit >= 1 and ( debuff[classtable.Garrote].remains <= 1 or debuff[classtable.Garrote].remains <= debuff[classtable.Garrote].duration and targets >= 3 ) and ( debuff[classtable.Garrote].remains <= debuff[classtable.Garrote].duration * 2 and targets >= 3 ) and ( ttd - debuff[classtable.Garrote].remains ) >4 and buff[classtable.MasterAssassin].remains == 0) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
end
function Assassination:items()
end
function Assassination:misc_cds()
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (MaxDps:Bloodlust() or ttd <30 or debuff[classtable.DeathmarkDeBuff].up) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
end
function Assassination:shiv()
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.Kingsbane] and not talents[classtable.LightweightShiv] and buff[classtable.EnvenomBuff].up and not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up and ( debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.KingsbaneDeBuff].remains <8 or cooldown[classtable.Kingsbane].remains >= 24 ) and ( not talents[classtable.CrimsonTempest] or single_target or debuff[classtable.CrimsonTempestDeBuff].up ) or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.Kingsbane] and talents[classtable.LightweightShiv] and buff[classtable.EnvenomBuff].up and not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up and ( debuff[classtable.KingsbaneDeBuff].up or cooldown[classtable.Kingsbane].remains <= 1 ) or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.ArterialPrecision] and not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up and debuff[classtable.DeathmarkDeBuff].up or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.Sepsis] and not talents[classtable.Kingsbane] and not talents[classtable.ArterialPrecision] and not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up and ( ( cooldown[classtable.Shiv].charges >0.9 + talents[classtable.LightweightShiv] and sepsis_sync_remains >5 ) or debuff[classtable.SepsisDeBuff].up or debuff[classtable.DeathmarkDeBuff].up or ttd <= cooldown[classtable.Shiv].charges * 8 )) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (not talents[classtable.Kingsbane] and not talents[classtable.ArterialPrecision] and not talents[classtable.Sepsis] and not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up and ( not talents[classtable.CrimsonTempest] or single_target or debuff[classtable.CrimsonTempestDeBuff].up ) or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
end
function Assassination:stealthed()
    --if (MaxDps:FindSpell(classtable.PoolResource) and CheckSpellCosts(classtable.PoolResource, 'PoolResource')) and cooldown[classtable.PoolResource].ready then
    --    return classtable.PoolResource
    --end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.Kingsbane] and ( debuff[classtable.KingsbaneDeBuff].up or cooldown[classtable.Kingsbane].up ) and ( not debuff[classtable.ShivDeBuff].up and debuff[classtable.ShivDeBuff].remains <1 ) and buff[classtable.EnvenomBuff].up) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Kingsbane) and CheckSpellCosts(classtable.Kingsbane, 'Kingsbane') and talents[classtable.Kingsbane]) and (buff[classtable.ShadowDanceBuff].remains >= 2 and buff[classtable.EnvenomBuff].up) and cooldown[classtable.Kingsbane].ready then
        return classtable.Kingsbane
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= 4 and debuff[classtable.KingsbaneDeBuff].up and buff[classtable.EnvenomBuff].remains <= 3) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= 4 and buff[classtable.MasterAssassinAuraBuff].up and not buff[classtable.ShadowDanceBuff].up and single_target) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    if (MaxDps:FindSpell(classtable.CrimsonTempest) and CheckSpellCosts(classtable.CrimsonTempest, 'CrimsonTempest') and talents[classtable.CrimsonTempest]) and (targets >= 3 + (MaxDps.tier and MaxDps.tier[31].count >= 4) and debuff[classtable.CrimsonTempest].refreshable and calculateEffectiveComboPoints(ComboPoints) >= 4 and not cooldown[classtable.Deathmark].ready and ttd - buff[classtable.CrimsonTempest].remains >6) and cooldown[classtable.CrimsonTempest].ready then
        return classtable.CrimsonTempest
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( debuff[classtable.Garrote].remains <( 12 - buff[classtable.SepsisBuffBuff].remains ) or debuff[classtable.Garrote].remains <= 1 or ( buff[classtable.IndiscriminateCarnageBuff].up and debuff[classtable.Garrote].count <targets ) ) and not single_target and ttd - debuff[classtable.Garrote].remains >2) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( debuff[classtable.Garrote].remains <= 1 or debuff[classtable.Garrote].remains <14 or not single_target and buff[classtable.MasterAssassinAuraBuff].remains <3 ) and ComboPointsDeficit >= 1 + 2 * talents[classtable.ShroudedSuffocation]) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= 4 and ( debuff[classtable.Rupture].remains <= 1 ) and ( buff[classtable.ShadowDanceBuff].up or debuff[classtable.DeathmarkDeBuff].up )) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
end
function Assassination:vanish()
    --if (MaxDps:FindSpell(classtable.PoolResource) and CheckSpellCosts(classtable.PoolResource, 'PoolResource')) and cooldown[classtable.PoolResource].ready then
    --    return classtable.PoolResource
    --end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance')) and (not talents[classtable.Kingsbane] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].up and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains <12 or cooldown[classtable.Deathmark].remains >60 ) and ComboPointsDeficit >= ( targets >4 )) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.ShadowDance) and CheckSpellCosts(classtable.ShadowDance, 'ShadowDance')) and (not talents[classtable.Kingsbane] and not talents[classtable.ImprovedGarrote] and talents[classtable.MasterAssassin] and not debuff[classtable.RuptureDeBuff].refreshable and debuff[classtable.GarroteDeBuff].remains >3 and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains >60 ) and ( debuff[classtable.ShivDeBuff].up or debuff[classtable.DeathmarkDeBuff].remains <4 or debuff[classtable.SepsisDeBuff].up ) and debuff[classtable.SepsisDeBuff].remains <3) and cooldown[classtable.ShadowDance].ready then
        return classtable.ShadowDance
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and not talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].up and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains <4 ) and ComboPointsDeficit >= ( targets >4 )) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    --if (MaxDps:FindSpell(classtable.PoolResource) and CheckSpellCosts(classtable.PoolResource, 'PoolResource')) and cooldown[classtable.PoolResource].ready then
    --    return classtable.PoolResource
    --end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].up and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and targets >2) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (talents[classtable.MasterAssassin] and talents[classtable.Kingsbane] and debuff[classtable.KingsbaneDeBuff].remains <= 3 and debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.DeathmarkDeBuff].remains <= 3 and debuff[classtable.DeathmarkDeBuff].up) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.ImprovedGarrote] and talents[classtable.MasterAssassin] and not debuff[classtable.RuptureDeBuff].refreshable and debuff[classtable.GarroteDeBuff].remains >3 and debuff[classtable.DeathmarkDeBuff].up and ( debuff[classtable.ShivDeBuff].up or debuff[classtable.DeathmarkDeBuff].remains <4 or debuff[classtable.SepsisDeBuff].up ) and debuff[classtable.SepsisDeBuff].remains <3) and cooldown[classtable.Vanish].ready then
        return classtable.Vanish
    end
end

function Rogue:Assassination()
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
    PoisonedBleeds = Rogue:PoisonedBleeds(1)
    EnergyRegenCombined = EnergyRegen + PoisonedBleeds * 7 % (2 * SpellHaste)
    classtable.GarroteDeBuff = 703
    classtable.RuptureDeBuff = 1943
    classtable.EnvenomBuff = 32645
    classtable.DeathmarkDeBuff = 360194
    classtable.ShivDeBuff = 319504
    classtable.ThistleTeaBuff = 381623
    classtable.KingsbaneDeBuff = 385627
    classtable.AmplifyingPoisonDeBuff = 383414
    classtable.CausticSpatterDeBuff = 421976
    classtable.SerratedBoneSpikeDebuffDeBuff = 394036 --
    classtable.BlindsideBuff = 121153
    classtable.SepsisBuffBuff = 375939 --
    classtable.ScentofBloodBuff = 394080 --
    classtable.CrimsonTempestDeBuff = 121411
    classtable.SepsisDeBuff = 385408 --
    classtable.ShadowDanceBuff = 185422
    classtable.MasterAssassinAuraBuff = 256735
    classtable.IndiscriminateCarnageBuff = 385754 --385747
    classtable.SliceandDiceBuff = 315496
    PreCombatUpdate()
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up or buff[classtable.BlindsideBuff].up)) then
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
    single_target = targets <2
    regen_saturated = EnergyRegenCombined >35
    if (MaxDps.tier and MaxDps.tier[31].count >= 4) then
        not_pooling = ( debuff[classtable.DeathmarkDeBuff].up or debuff[classtable.KingsbaneDeBuff].up or buff[classtable.ShadowDanceBuff].up or debuff[classtable.ShivDeBuff].up or cooldown[classtable.ThistleTea].fullRecharge <20 ) or ( buff[classtable.EnvenomBuff].up and buff[classtable.EnvenomBuff].remains <= 2 ) or EnergyPerc >= 80 or ttd <= 90
    end
    if not (MaxDps.tier and MaxDps.tier[31].count >= 4) then
        not_pooling = ( debuff[classtable.DeathmarkDeBuff].up or debuff[classtable.KingsbaneDeBuff].up or buff[classtable.ShadowDanceBuff].up or debuff[classtable.ShivDeBuff].up or cooldown[classtable.ThistleTea].fullRecharge <20 ) or EnergyPerc >= 80
    end
    if cooldown[classtable.Deathmark].remains >cooldown[classtable.Sepsis].remains and cooldown[classtable.Deathmark].remains <ttd then
        sepsis_sync_remains = cooldown[classtable.Deathmark].remains
    else
        sepsis_sync_remains = cooldown[classtable.Sepsis].remains
    end
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) or buff[classtable.MasterAssassin].remains >0) then
        local stealthedCheck = Assassination:stealthed()
        if stealthedCheck then
            return Assassination:stealthed()
        end
    end
    local cdsCheck = Assassination:cds()
    if cdsCheck then
        return cdsCheck
    end
    if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and (not buff[classtable.SliceandDiceBuff].up and debuff[classtable.RuptureDeBuff].up and ComboPoints >= 2 or not talents[classtable.CutTotheChase] and buff[classtable.SliceandDiceBuff].refreshable and ComboPoints >= 4) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (talents[classtable.CutTotheChase] and buff[classtable.SliceandDiceBuff].up and buff[classtable.SliceandDiceBuff].remains <5 and ComboPoints >= 4) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    local dotCheck = Assassination:dot()
    if dotCheck then
        return dotCheck
    end
    local directCheck = Assassination:direct()
    if directCheck then
        return directCheck
    end
    if (MaxDps:FindSpell(classtable.ArcanePulse) and CheckSpellCosts(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        return classtable.ArcanePulse
    end
    local itemsCheck = Assassination:items()
    if itemsCheck then
        return itemsCheck
    end
    local shivCheck = Assassination:shiv()
    if shivCheck then
        return shivCheck
    end
    local misc_cdsCheck = Assassination:misc_cds()
    if misc_cdsCheck then
        return misc_cdsCheck
    end
    if (not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and buff[classtable.MasterAssassin].remains == 0) then
        local vanishCheck = Assassination:vanish()
        if vanishCheck then
            return Assassination:vanish()
        end
    end

end
