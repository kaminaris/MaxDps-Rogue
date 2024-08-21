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

local Assassination = {}

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
local use_filler
local use_caustic_filler
local base_trinket_condition
local shiv_condition
local shiv_kingsbane_condition

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
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
        local itemName = C_Item.GetItemInfo(itemID)
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
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
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


local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Assassination:precombat()
    --if (MaxDps:FindSpell(classtable.ApplyPoison) and CheckSpellCosts(classtable.ApplyPoison, 'ApplyPoison')) and cooldown[classtable.ApplyPoison].ready then
    --    return classtable.ApplyPoison
    --end
    effective_spend_cp = ComboPointsMax - 1
    --if (MaxDps:FindSpell(classtable.Stealth) and CheckSpellCosts(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
    --    return classtable.Stealth
    --end
    --if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].refreshable and not buff[classtable.IndiscriminateCarnageBuff].up) and cooldown[classtable.SliceandDice].ready then
    --    return classtable.SliceandDice
    --end
end
function Assassination:cds()
    deathmark_ma_condition = not talents[classtable.MasterAssassin] or debuff[classtable.GarroteDeBuff].up
    deathmark_kingsbane_condition = not talents[classtable.Kingsbane] or cooldown[classtable.Kingsbane].remains <= 2
    deathmark_condition = not (IsStealthed() or buff[classtable.ShadowDanceBuff].up) and debuff[classtable.RuptureDeBuff].up and buff[classtable.EnvenomBuff].up and not debuff[classtable.DeathmarkDeBuff].up and deathmark_ma_condition and deathmark_kingsbane_condition
    local itemsCheck = Assassination:items()
    if itemsCheck then
        return itemsCheck
    end
    if (MaxDps:FindSpell(classtable.Deathmark) and CheckSpellCosts(classtable.Deathmark, 'Deathmark')) and (( deathmark_condition and ttd >= 10 ) or boss and ttd <= 20) and cooldown[classtable.Deathmark].ready then
        return classtable.Deathmark
    end
    local shivCheck = Assassination:shiv()
    if shivCheck then
        return shivCheck
    end
    if (MaxDps:FindSpell(classtable.Kingsbane) and CheckSpellCosts(classtable.Kingsbane, 'Kingsbane')) and (( debuff[classtable.ShivDeBuff].up or cooldown[classtable.Shiv].remains <6 ) and buff[classtable.EnvenomBuff].up and ( cooldown[classtable.Deathmark].remains >= 50 or debuff[classtable.DeathmarkDeBuff].up ) or boss and ttd <= 15) and cooldown[classtable.Kingsbane].ready then
        return classtable.Kingsbane
    end
    if (MaxDps:FindSpell(classtable.ThistleTea) and CheckSpellCosts(classtable.ThistleTea, 'ThistleTea')) and (not buff[classtable.ThistleTeaBuff].up and ( ( ( EnergyDeficit >= 100 + EnergyRegenCombined or cooldown[classtable.ThistleTea].charges >= 3 ) and debuff[classtable.ShivDeBuff].remains >= 4 ) or targets >= 4 and debuff[classtable.ShivDeBuff].remains >= 6 ) or ttd <cooldown[classtable.ThistleTea].charges * 6) and cooldown[classtable.ThistleTea].ready then
        MaxDps:GlowCooldown(classtable.ThistleTea, cooldown[classtable.ThistleTea].ready)
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
    if (MaxDps:FindSpell(classtable.ColdBlood) and CheckSpellCosts(classtable.ColdBlood, 'ColdBlood')) and (ComboPoints >= 5 and not debuff[classtable.RuptureDeBuff].refreshable and not buff[classtable.EdgeCaseBuff].up and cooldown[classtable.Deathmark].remains >10) and cooldown[classtable.ColdBlood].ready then
        return classtable.ColdBlood
    end
end
function Assassination:direct()
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (not buff[classtable.DarkestNightBuff].up and calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( not_pooling or debuff[classtable.AmplifyingPoisonDeBuff].count >= 20 or calculateEffectiveComboPoints(ComboPoints) >ComboPointsMax or not single_target ) and not buff[classtable.VanishBuff].up) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (buff[classtable.DarkestNightBuff].up and calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    use_filler = ComboPointsDeficit >1 or not_pooling or not single_target
    use_caustic_filler = talents[classtable.CausticSpatter] and debuff[classtable.RuptureDeBuff].up and ( not debuff[classtable.CausticSpatterDeBuff].up or debuff[classtable.CausticSpatterDeBuff].remains <= 2 ) and ComboPointsDeficit >1 and not single_target
    if (MaxDps:FindSpell(classtable.Mutilate) and CheckSpellCosts(classtable.Mutilate, 'Mutilate')) and (use_caustic_filler) and cooldown[classtable.Mutilate].ready then
        return classtable.Mutilate
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (use_caustic_filler) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.EchoingReprimand) and CheckSpellCosts(classtable.EchoingReprimand, 'EchoingReprimand')) and (use_filler or boss and ttd <20) and cooldown[classtable.EchoingReprimand].ready then
        return classtable.EchoingReprimand
    end
    if (MaxDps:FindSpell(classtable.FanofKnives) and CheckSpellCosts(classtable.FanofKnives, 'FanofKnives')) and (use_filler and ( targets >= 3 or buff[classtable.CleartheWitnessesBuff].up )) and cooldown[classtable.FanofKnives].ready then
        return classtable.FanofKnives
    end
    if (MaxDps:FindSpell(classtable.FanofKnives) and CheckSpellCosts(classtable.FanofKnives, 'FanofKnives')) and (use_filler and ( targets >= 2 + (IsStealthed() or buff[classtable.ShadowDanceBuff].up and 1 or 0) + (talents[classtable.DragontemperedBlades] and talents[classtable.DragontemperedBlades] or 0) )) and cooldown[classtable.FanofKnives].ready then
        return classtable.FanofKnives
    end
    if (MaxDps:FindSpell(classtable.FanofKnives) and CheckSpellCosts(classtable.FanofKnives, 'FanofKnives')) and (use_filler and targets >= 3) and cooldown[classtable.FanofKnives].ready then
        return classtable.FanofKnives
    end
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (use_filler and ( buff[classtable.BlindsideBuff].up or (IsStealthed() or buff[classtable.ShadowDanceBuff].up) ) and ( not debuff[classtable.KingsbaneDeBuff].up or not debuff[classtable.DeathmarkDeBuff].up or buff[classtable.BlindsideBuff].up )) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.Mutilate) and CheckSpellCosts(classtable.Mutilate, 'Mutilate')) and (not debuff[classtable.DeadlyPoisonDebuffDeBuff].up and not debuff[classtable.AmplifyingPoisonDeBuff].up and use_filler and targets == 2) and cooldown[classtable.Mutilate].ready then
        return classtable.Mutilate
    end
    if (MaxDps:FindSpell(classtable.Mutilate) and CheckSpellCosts(classtable.Mutilate, 'Mutilate')) and (use_filler) and cooldown[classtable.Mutilate].ready then
        return classtable.Mutilate
    end
end
function Assassination:core_dot()
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and (ComboPointsDeficit >= 1 and ( debuff[classtable.GarroteDeBuff].remains <= 1 ) and debuff[classtable.GarroteDeBuff].refreshable and ttd - debuff[classtable.GarroteDeBuff].remains >12) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( debuff[classtable.RuptureDeBuff].remains <= 1 ) and debuff[classtable.RuptureDeBuff].refreshable and ttd - debuff[classtable.RuptureDeBuff].remains >( (4 + ( (talents[classtable.DashingScoundrel] and talents[classtable.DashingScoundrel] or 0) * 5 ) + ( (regen_saturated and 1 or 0) * 6 )) and 1 or 0) and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
end
function Assassination:aoe_dot()
    if (MaxDps:FindSpell(classtable.CrimsonTempest) and CheckSpellCosts(classtable.CrimsonTempest, 'CrimsonTempest')) and (targets >= 3 and debuff[classtable.CrimsonTempestDeBuff].refreshable and debuff[classtable.CrimsonTempestDeBuff].remains <= 1 and calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and EnergyRegenCombined >25 and ttd - debuff[classtable.CrimsonTempestDeBuff].remains >6) and cooldown[classtable.CrimsonTempest].ready then
        return classtable.CrimsonTempest
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and (ComboPointsDeficit >= 1 and ( debuff[classtable.GarroteDeBuff].remains <= 1 ) and debuff[classtable.GarroteDeBuff].refreshable and not regen_saturated and targets >= 2 and ttd - debuff[classtable.GarroteDeBuff].remains >12) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and ( debuff[classtable.RuptureDeBuff].remains <= 1 ) and debuff[classtable.RuptureDeBuff].refreshable and ( not regen_saturated and ( (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 0) == 2 or (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 0) <= 1 and ( buff[classtable.IndiscriminateCarnageBuff].up or ttd - debuff[classtable.RuptureDeBuff].remains >15 ) ) ) and ttd - debuff[classtable.RuptureDeBuff].remains >( 4 + ( (talents[classtable.DashingScoundrel] and talents[classtable.DashingScoundrel] or 0) * 5 ) + ( (regen_saturated and 1 or 0) * 6 ) ) and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and (debuff[classtable.GarroteDeBuff].refreshable and ComboPointsDeficit >= 1 and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].remains <= buff[classtable.GarroteBuff].duration and targets >= 3 ) and ( debuff[classtable.GarroteDeBuff].remains <= buff[classtable.GarroteBuff].duration * 2 and targets >= 3 ) and ( ttd - debuff[classtable.GarroteDeBuff].remains ) >4 and buff[classtable.MasterAssassin].remains == 0) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
end
function Assassination:items()
end
function Assassination:misc_cds()
end
function Assassination:shiv()
    shiv_condition = not debuff[classtable.ShivDeBuff].up and debuff[classtable.GarroteDeBuff].up and debuff[classtable.RuptureDeBuff].up
    shiv_kingsbane_condition = talents[classtable.Kingsbane] and buff[classtable.EnvenomBuff].up and shiv_condition
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.ArterialPrecision] and shiv_condition and targets >= 4 and debuff[classtable.CrimsonTempestDeBuff].up or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (not talents[classtable.LightweightShiv] and shiv_kingsbane_condition and ( debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.KingsbaneDeBuff].remains <8 or cooldown[classtable.Kingsbane].remains >= 24 ) and ( not talents[classtable.CrimsonTempest] or single_target or debuff[classtable.CrimsonTempestDeBuff].up ) or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.LightweightShiv] and shiv_kingsbane_condition and ( debuff[classtable.KingsbaneDeBuff].up or cooldown[classtable.Kingsbane].remains <= 1 ) or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.ArterialPrecision] and shiv_condition and debuff[classtable.DeathmarkDeBuff].up or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (not talents[classtable.Kingsbane] and not talents[classtable.ArterialPrecision] and shiv_condition and ( not talents[classtable.CrimsonTempest] or single_target or debuff[classtable.CrimsonTempestDeBuff].up ) or ttd <= cooldown[classtable.Shiv].charges * 8) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
end
function Assassination:stealthed()
    if (MaxDps:FindSpell(classtable.Ambush) and CheckSpellCosts(classtable.Ambush, 'Ambush')) and (not debuff[classtable.DeathstalkersMarkDeBuff].up and talents[classtable.DeathstalkersMark] and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Ambush].ready then
        return classtable.Ambush
    end
    if (MaxDps:FindSpell(classtable.Shiv) and CheckSpellCosts(classtable.Shiv, 'Shiv')) and (talents[classtable.Kingsbane] and ( debuff[classtable.KingsbaneDeBuff].up or cooldown[classtable.Kingsbane].ready ) and ( not debuff[classtable.ShivDeBuff].up and debuff[classtable.ShivDeBuff].remains <1 ) and buff[classtable.EnvenomBuff].up) and cooldown[classtable.Shiv].ready then
        return classtable.Shiv
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and debuff[classtable.KingsbaneDeBuff].up and buff[classtable.EnvenomBuff].remains <= 3) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and buff[classtable.MasterAssassinAuraBuff].up and single_target) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    if (MaxDps:FindSpell(classtable.Rupture) and CheckSpellCosts(classtable.Rupture, 'Rupture')) and (calculateEffectiveComboPoints(ComboPoints) >= effective_spend_cp and buff[classtable.IndiscriminateCarnageBuff].up and debuff[classtable.RuptureDeBuff].refreshable and ( not regen_saturated or not scent_saturation or not debuff[classtable.RuptureDeBuff].up )) and cooldown[classtable.Rupture].ready then
        return classtable.Rupture
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( debuff[classtable.GarroteDeBuff].remains <12 or debuff[classtable.GarroteDeBuff].remains <= 1 or ( buff[classtable.IndiscriminateCarnageBuff].up and debuff[classtable.GarroteDeBuff].count  <1 ) ) and not single_target and ttd - debuff[classtable.GarroteDeBuff].remains >2) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
    if (MaxDps:FindSpell(classtable.Garrote) and CheckSpellCosts(classtable.Garrote, 'Garrote')) and ((IsStealthed() or buff[classtable.ShadowDanceBuff].up) and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].remains <12 or not single_target and buff[classtable.MasterAssassinAuraBuff].remains <3 ) and ComboPointsDeficit >= 1 + 2 * talents[classtable.ShroudedSuffocation]) and cooldown[classtable.Garrote].ready then
        return classtable.Garrote
    end
end
function Assassination:vanish()
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not buff[classtable.FateboundLuckyCoinBuff].up and ( buff[classtable.FateboundCoinTailsBuff].count >= 5 or buff[classtable.FateboundCoinHeadsBuff].count >= 5 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and not talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains <4 ) and ComboPointsDeficit >= ( targets >4 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and targets >2) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (talents[classtable.MasterAssassin] and talents[classtable.Kingsbane] and debuff[classtable.KingsbaneDeBuff].remains <= 3 and debuff[classtable.KingsbaneDeBuff].up and debuff[classtable.DeathmarkDeBuff].remains <= 3 and debuff[classtable.DeathmarkDeBuff].up) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.MasterAssassin] and talents[classtable.IndiscriminateCarnage] and talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and targets >2 and ( ttd - debuff[classtable.VanishDeBuff].remains >15 or math.huge >20 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (not talents[classtable.ImprovedGarrote] and talents[classtable.MasterAssassin] and not debuff[classtable.RuptureDeBuff].refreshable and debuff[classtable.GarroteDeBuff].remains >3 and debuff[classtable.DeathmarkDeBuff].up and ( debuff[classtable.ShivDeBuff].up or debuff[classtable.DeathmarkDeBuff].remains <4 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:FindSpell(classtable.Vanish) and CheckSpellCosts(classtable.Vanish, 'Vanish')) and (talents[classtable.ImprovedGarrote] and cooldown[classtable.Garrote].ready and ( debuff[classtable.GarroteDeBuff].remains <= 1 or debuff[classtable.GarroteDeBuff].refreshable ) and ( debuff[classtable.DeathmarkDeBuff].up or cooldown[classtable.Deathmark].remains <4 ) and math.huge >30) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
end

function Assassination:callaction()
    --if (MaxDps:FindSpell(classtable.Stealth) and CheckSpellCosts(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
    --    return classtable.Stealth
    --end
    if (MaxDps:FindSpell(classtable.Kick) and CheckSpellCosts(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    single_target = targets <2
    regen_saturated = EnergyRegenCombined >35
    not_pooling = ( debuff[classtable.DeathmarkDeBuff].up or debuff[classtable.KingsbaneDeBuff].up or debuff[classtable.ShivDeBuff].up ) or ( buff[classtable.EnvenomBuff].up and buff[classtable.EnvenomBuff].remains <= 1 ) or EnergyPerc >= ( 40 + 30 * (talents[classtable.HandofFate] and talents[classtable.HandofFate] or 0) - 15 * (talents[classtable.ViciousVenoms] and talents[classtable.ViciousVenoms] or 0) ) or boss and ttd <= 20
    scent_effective_max_stacks = ( targets * (talents[classtable.ScentofBlood] and talents[classtable.ScentofBlood] or 0) * 2 )
    scent_saturation = buff[classtable.ScentofBloodBuff].count >= scent_effective_max_stacks
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
    if (MaxDps:FindSpell(classtable.SliceandDice) and CheckSpellCosts(classtable.SliceandDice, 'SliceandDice')) and (not buff[classtable.SliceandDiceBuff].up and debuff[classtable.RuptureDeBuff].up and ComboPoints >= 1 and ( not buff[classtable.IndiscriminateCarnageBuff].up or single_target )) and cooldown[classtable.SliceandDice].ready then
        return classtable.SliceandDice
    end
    if (MaxDps:FindSpell(classtable.Envenom) and CheckSpellCosts(classtable.Envenom, 'Envenom')) and (buff[classtable.SliceandDiceBuff].up and buff[classtable.SliceandDiceBuff].remains <5 and ComboPoints >= 5) and cooldown[classtable.Envenom].ready then
        return classtable.Envenom
    end
    local core_dotCheck = Assassination:core_dot()
    if core_dotCheck then
        return core_dotCheck
    end
    if (not single_target) then
        local aoe_dotCheck = Assassination:aoe_dot()
        if aoe_dotCheck then
            return Assassination:aoe_dot()
        end
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
    PoisonedBleeds = Rogue:PoisonedBleeds()
    EnergyRegenCombined = EnergyRegen + PoisonedBleeds * 7 % (2 * SpellHaste)
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.IndiscriminateCarnageBuff = 385754
    classtable.GarroteDeBuff = 703
    classtable.RuptureDeBuff = 1943
    classtable.EnvenomBuff = 32645
    classtable.DeathmarkDeBuff = 360194
    classtable.ShivDeBuff = 319504
    classtable.ThistleTeaBuff = 381623
    classtable.EdgeCaseBuff = 0
    classtable.DarkestNightBuff = 0
    classtable.AmplifyingPoisonDeBuff = 383414
    classtable.VanishBuff = 11327
    classtable.CausticSpatterDeBuff = 421976
    classtable.CleartheWitnessesBuff = 0
    classtable.BlindsideBuff = 121153
    classtable.KingsbaneDeBuff = 385627
    classtable.DeadlyPoisonDebuffDeBuff = 2818
    classtable.CrimsonTempestDeBuff = 121411
    classtable.DeathstalkersMarkDeBuff = 0
    classtable.MasterAssassinAuraBuff = 356735
    classtable.FateboundLuckyCoinBuff = 0
    classtable.FateboundCoinTailsBuff = 0
    classtable.FateboundCoinHeadsBuff = 0
    classtable.VanishDeBuff = 0
    classtable.ScentofBloodBuff = 394080
    classtable.SliceandDiceBuff = 315496

    local precombatCheck = Assassination:precombat()
    if precombatCheck then
        return Assassination:precombat()
    end

    local callactionCheck = Assassination:callaction()
    if callactionCheck then
        return Assassination:callaction()
    end
end
