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
local DanseMacabreSpellList

local Subtlety = {}

local algethar_puzzle_box_precombat_cast
local priority_rotation
local trinket_sync_slot
local snd_condition
local ruptures_before_flag
local racial_sync
local secret_condition
local skip_rupture


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
    --if (MaxDps:CheckSpellUsable(classtable.ApplyPoison, 'ApplyPoison')) and cooldown[classtable.ApplyPoison].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.ApplyPoison end
    --end
    algethar_puzzle_box_precombat_cast = 3
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (buff[classtable.SliceandDiceBuff].refreshable) and cooldown[classtable.SliceandDice].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    priority_rotation = false
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Stealth end
    end
end
function Subtlety:build()
    if (MaxDps:CheckSpellUsable(classtable.ShurikenStorm, 'ShurikenStorm')) and (targets >= 2 + ( talents[classtable.Gloomblade] and buff[classtable.LingeringShadowBuff].remains >= 6 and 1 or 0 or buff[classtable.PerforatedVeinsBuff].up and 1 or 0 ) - ( not debuff[classtable.FindWeaknessDeBuff].up and not talents[classtable.ImprovedBackstab] and 1 or 0 ) and ( buff[classtable.FlawlessFormBuff].up or not talents[classtable.UnseenBlade] )) and cooldown[classtable.ShurikenStorm].ready then
        if not setSpell then setSpell = classtable.ShurikenStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenStorm, 'ShurikenStorm')) and (buff[classtable.CleartheWitnessesBuff].up and ( not buff[classtable.SymbolsofDeathBuff].up or not talents[classtable.Inevitability] ) and ( buff[classtable.LingeringShadowBuff].remains <= 6 or not talents[classtable.LingeringShadow] )) and cooldown[classtable.ShurikenStorm].ready then
        if not setSpell then setSpell = classtable.ShurikenStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Gloomblade, 'Gloomblade')) and cooldown[classtable.Gloomblade].ready then
        if not setSpell then setSpell = classtable.Gloomblade end
    end
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
end
function Subtlety:cds()
    ruptures_before_flag = targets <= 4 or talents[classtable.InvigoratingShadowdust] and not talents[classtable.FollowtheBlood] or ( talents[classtable.ReplicatingShadows] and ( targets >= 5 and debuff[classtable.RuptureDeBuff].count  >= targets - 2 ) ) or not talents[classtable.ReplicatingShadows]
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and (not talents[classtable.SecretTechnique] and ComboPoints >= 6) and cooldown[classtable.ColdBlood].ready then
        MaxDps:GlowCooldown(classtable.ColdBlood, cooldown[classtable.ColdBlood].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Sepsis, 'Sepsis')) and (snd_condition and ( cooldown[classtable.ShadowBlades].remains <= 3 and cooldown[classtable.SymbolsofDeath].remains <= 3 or ttd <= 12 )) and cooldown[classtable.Sepsis].ready then
        MaxDps:GlowCooldown(classtable.Sepsis, cooldown[classtable.Sepsis].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Flagellation, 'Flagellation')) and (snd_condition and ruptures_before_flag and ComboPoints >= 5 and ttd >10 and ( cooldown[classtable.ShadowBlades].remains <= 2 or ttd <= 24 ) and ( not talents[classtable.InvigoratingShadowdust] or cooldown[classtable.SymbolsofDeath].remains <= 3 or buff[classtable.SymbolsofDeathBuff].remains >3 )) and cooldown[classtable.Flagellation].ready then
        MaxDps:GlowCooldown(classtable.Flagellation, cooldown[classtable.Flagellation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SymbolsofDeath, 'SymbolsofDeath')) and (not talents[classtable.InvigoratingShadowdust] and snd_condition and ( buff[classtable.ShadowBladesBuff].up or cooldown[classtable.ShadowBlades].remains >20 )) and cooldown[classtable.SymbolsofDeath].ready then
        MaxDps:GlowCooldown(classtable.SymbolsofDeath, cooldown[classtable.SymbolsofDeath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SymbolsofDeath, 'SymbolsofDeath')) and (talents[classtable.InvigoratingShadowdust] and snd_condition and buff[classtable.SymbolsofDeathBuff].remains <= 3 and not buff[classtable.TheRottenBuff].up and ( cooldown[classtable.Flagellation].remains >10 or cooldown[classtable.Flagellation].ready and cooldown[classtable.ShadowBlades].remains >= 20 or buff[classtable.ShadowDanceBuff].remains >= 2 )) and cooldown[classtable.SymbolsofDeath].ready then
        MaxDps:GlowCooldown(classtable.SymbolsofDeath, cooldown[classtable.SymbolsofDeath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBlades, 'ShadowBlades')) and (snd_condition and ComboPoints <= 1 and ( buff[classtable.FlagellationBuffBuff].up or not talents[classtable.Flagellation] ) or ttd <= 20) and cooldown[classtable.ShadowBlades].ready then
        MaxDps:GlowCooldown(classtable.ShadowBlades, cooldown[classtable.ShadowBlades].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EchoingReprimand, 'EchoingReprimand')) and (snd_condition and ComboPointsDeficit >= 3 and ( not talents[classtable.TheRotten] or not talents[classtable.Reverberation] or buff[classtable.ShadowDanceBuff].up )) and cooldown[classtable.EchoingReprimand].ready then
        MaxDps:GlowCooldown(classtable.EchoingReprimand, cooldown[classtable.EchoingReprimand].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenTornado, 'ShurikenTornado')) and (snd_condition and buff[classtable.SymbolsofDeathBuff].up and ComboPoints <= 2 and not buff[classtable.PremeditationBuff].up and ( not talents[classtable.Flagellation] or cooldown[classtable.Flagellation].remains >20 ) and targets >= 3) and cooldown[classtable.ShurikenTornado].ready then
        MaxDps:GlowCooldown(classtable.ShurikenTornado, cooldown[classtable.ShurikenTornado].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenTornado, 'ShurikenTornado')) and (snd_condition and not buff[classtable.ShadowDanceBuff].up and not buff[classtable.FlagellationBuffBuff].up and not buff[classtable.FlagellationPersistBuff].up and not buff[classtable.ShadowBladesBuff].up and targets <= 2 and not (targets >1)) and cooldown[classtable.ShurikenTornado].ready then
        MaxDps:GlowCooldown(classtable.ShurikenTornado, cooldown[classtable.ShurikenTornado].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (buff[classtable.ShadowDanceBuff].up and talents[classtable.InvigoratingShadowdust] and talents[classtable.UnseenBlade] and ( ComboPointsDeficit >1 ) and ( cooldown[classtable.Flagellation].remains >= 60 or not talents[classtable.Flagellation] or ttd <= ( 30 * cooldown[classtable.Vanish].charges ) ) and cooldown[classtable.SecretTechnique].remains >= 10) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowDance, 'ShadowDance')) and (not buff[classtable.ShadowDanceBuff].up and ( talents[classtable.InvigoratingShadowdust] and buff[classtable.ShadowBladesBuff].up and ( ( talents[classtable.DeathstalkersMark] and buff[classtable.SubterfugeBuff].up ) or ( debuff[classtable.RuptureDeBuff].up and snd_condition and talents[classtable.UnseenBlade] ) ) ) or MaxDps:boss() and ttd <= 8) and cooldown[classtable.ShadowDance].ready then
        MaxDps:GlowCooldown(classtable.ShadowDance, cooldown[classtable.ShadowDance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.GoremawsBite, 'GoremawsBite')) and (snd_condition and ComboPointsDeficit >= 3 and ( not cooldown[classtable.ShadowDance].ready or talents[classtable.DoubleDance] and buff[classtable.ShadowDanceBuff].up and not talents[classtable.InvigoratingShadowdust] or targets <4 and not talents[classtable.InvigoratingShadowdust] or talents[classtable.TheRotten] or (targets >1) )) and cooldown[classtable.GoremawsBite].ready then
        MaxDps:GlowCooldown(classtable.GoremawsBite, cooldown[classtable.GoremawsBite].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThistleTea, 'ThistleTea')) and (not buff[classtable.ThistleTeaBuff].up and ( buff[classtable.ShadowDanceBuff].remains >= 6 ) or ( not buff[classtable.ThistleTeaBuff].up or EnergyDeficit >100 ) and ttd <= ( 6 * cooldown[classtable.ThistleTea].charges )) and cooldown[classtable.ThistleTea].ready then
        MaxDps:GlowCooldown(classtable.ThistleTea, cooldown[classtable.ThistleTea].ready)
    end
    racial_sync = buff[classtable.ShadowBladesBuff].up or not talents[classtable.ShadowBlades] and buff[classtable.SymbolsofDeathBuff].up or MaxDps:boss() and ttd <20
end
function Subtlety:items()
end
function Subtlety:finish()
    secret_condition = ( ( buff[classtable.DanseMacabreBuff].count >= 3 ) or not talents[classtable.DanseMacabre] or ( talents[classtable.UnseenBlade] and buff[classtable.ShadowDanceBuff].up and ( buff[classtable.EscalatingBladeBuff].count >= 2 or buff[classtable.ShadowBladesBuff].up ) ) )
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (not debuff[classtable.RuptureDeBuff].up and ttd - debuff[classtable.RuptureDeBuff].remains >6) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    skip_rupture = buff[classtable.ThistleTeaBuff].up and targets == 1 or buff[classtable.ShadowDanceBuff].up and ( targets == 1 or debuff[classtable.RuptureDeBuff].up and targets >= 2 ) or buff[classtable.DarkestNightBuff].up
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (( not skip_rupture or priority_rotation ) and ttd - debuff[classtable.RuptureDeBuff].remains >6 and debuff[classtable.RuptureDeBuff].refreshable) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoupdeGrace, 'CoupdeGrace')) and (debuff[classtable.FazedDeBuff].up and buff[classtable.ShadowDanceBuff].up) and cooldown[classtable.CoupdeGrace].ready then
        if not setSpell then setSpell = classtable.CoupdeGrace end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and (secret_condition and cooldown[classtable.SecretTechnique].ready) and cooldown[classtable.ColdBlood].ready then
        MaxDps:GlowCooldown(classtable.ColdBlood, cooldown[classtable.ColdBlood].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SecretTechnique, 'SecretTechnique')) and (secret_condition and ( not talents[classtable.ColdBlood] or cooldown[classtable.ColdBlood].remains >buff[classtable.ShadowDanceBuff].remains - 2 or not talents[classtable.ImprovedShadowDance] )) and cooldown[classtable.SecretTechnique].ready then
        if not setSpell then setSpell = classtable.SecretTechnique end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (not skip_rupture and buff[classtable.FinalityRuptureBuff].up and ( cooldown[classtable.SymbolsofDeath].remains <= 3 or buff[classtable.SymbolsofDeathBuff].up )) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackPowder, 'BlackPowder')) and (not priority_rotation and talents[classtable.DeathstalkersMark] and targets >= 3 and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.BlackPowder].ready then
        if not setSpell then setSpell = classtable.BlackPowder end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackPowder, 'BlackPowder')) and (not priority_rotation and talents[classtable.UnseenBlade] and ( ( buff[classtable.EscalatingBladeBuff].count == 4 and not buff[classtable.ShadowDanceBuff].up and cooldown[classtable.ShadowBlades].remains <25 ) or targets >= 3 and not buff[classtable.FlawlessFormBuff].up or ( not CheckDanseMacabre(classtable.FlawlessForm) and buff[classtable.ShadowDanceBuff].up and talents[classtable.ShurikenTornado] and targets >= 3 ) )) and cooldown[classtable.BlackPowder].ready then
        if not setSpell then setSpell = classtable.BlackPowder end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoupdeGrace, 'CoupdeGrace')) and (debuff[classtable.FazedDeBuff].up) and cooldown[classtable.CoupdeGrace].ready then
        if not setSpell then setSpell = classtable.CoupdeGrace end
    end
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
end
function Subtlety:stealth_cds()
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.InvigoratingShadowdust] and not talents[classtable.Subterfuge] and ComboPointsDeficit >= 3 and ( not debuff[classtable.RuptureDeBuff].up or ( buff[classtable.ShadowBladesBuff].up and buff[classtable.SymbolsofDeathBuff].up ) or talents[classtable.Premeditation] or MaxDps:boss() and ttd <10 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not buff[classtable.ShadowDanceBuff].up and talents[classtable.InvigoratingShadowdust] and talents[classtable.DeathstalkersMark] and ( ComboPointsDeficit >1 or buff[classtable.ShadowBladesBuff].up ) and ( cooldown[classtable.Flagellation].remains >= 60 or not talents[classtable.Flagellation] or ttd <= ( 30 * cooldown[classtable.Vanish].charges ) ) and cooldown[classtable.SecretTechnique].remains >= 10) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowDance, 'ShadowDance')) and (debuff[classtable.RuptureDeBuff].up and snd_condition and ( buff[classtable.SymbolsofDeathBuff].remains >= 6 and not buff[classtable.FlagellationBuffBuff].up or buff[classtable.SymbolsofDeathBuff].up and buff[classtable.ShadowBladesBuff].up or buff[classtable.ShadowBladesBuff].up and not talents[classtable.InvigoratingShadowdust] ) and cooldown[classtable.SecretTechnique].remains <10 + 12 * (not talents[classtable.InvigoratingShadowdust] and 1 or 0) and ( not talents[classtable.TheFirstDance] or ( ComboPointsDeficit >= 7 and not buff[classtable.ShadowBladesBuff].up or buff[classtable.ShadowBladesBuff].up ) )) and cooldown[classtable.ShadowDance].ready then
        MaxDps:GlowCooldown(classtable.ShadowDance, cooldown[classtable.ShadowDance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (not talents[classtable.InvigoratingShadowdust] and talents[classtable.Subterfuge] and ComboPointsDeficit >= 3 and ( buff[classtable.SymbolsofDeathBuff].up or cooldown[classtable.SymbolsofDeath].remains >= 3 )) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and (Energy >= 40 and ComboPointsDeficit >3) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
end
function Subtlety:stealthed()
    if (MaxDps:CheckSpellUsable(classtable.Shadowstrike, 'Shadowstrike')) and (talents[classtable.DeathstalkersMark] and not debuff[classtable.DeathstalkersMarkDeBuff].up and not buff[classtable.DarkestNightBuff].up) and cooldown[classtable.Shadowstrike].ready then
        if not setSpell then setSpell = classtable.Shadowstrike end
    end
    if (buff[classtable.DarkestNightBuff].up and ComboPoints == ComboPointsMax or calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax and not buff[classtable.DarkestNightBuff].up or buff[classtable.ShurikenTornadoBuff].up and ComboPointsDeficit <= 2 and not buff[classtable.DarkestNightBuff].up or ( ComboPointsDeficit <= 1 + (talents[classtable.DeathstalkersMark] and talents[classtable.DeathstalkersMark] or 0) ) and not buff[classtable.DarkestNightBuff].up) then
        Subtlety:finish()
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstrike, 'Shadowstrike')) and (( not CheckDanseMacabre(classtable.Shadowstrike) and buff[classtable.ShadowBladesBuff].up ) or ( talents[classtable.UnseenBlade] and targets >= 2 )) and cooldown[classtable.Shadowstrike].ready then
        if not setSpell then setSpell = classtable.Shadowstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenStorm, 'ShurikenStorm')) and (not buff[classtable.PremeditationBuff].up and targets >= 4) and cooldown[classtable.ShurikenStorm].ready then
        if not setSpell then setSpell = classtable.ShurikenStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Gloomblade, 'Gloomblade')) and (buff[classtable.LingeringShadowBuff].remains >= 10 and buff[classtable.ShadowBladesBuff].up and targets == 1) and cooldown[classtable.Gloomblade].ready then
        if not setSpell then setSpell = classtable.Gloomblade end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstrike, 'Shadowstrike')) and cooldown[classtable.Shadowstrike].ready then
        if not setSpell then setSpell = classtable.Shadowstrike end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
    MaxDps:GlowCooldown(classtable.ColdBlood, false)
    MaxDps:GlowCooldown(classtable.Sepsis, false)
    MaxDps:GlowCooldown(classtable.Flagellation, false)
    MaxDps:GlowCooldown(classtable.SymbolsofDeath, false)
    MaxDps:GlowCooldown(classtable.ShadowBlades, false)
    MaxDps:GlowCooldown(classtable.EchoingReprimand, false)
    MaxDps:GlowCooldown(classtable.ShurikenTornado, false)
    MaxDps:GlowCooldown(classtable.Vanish, false)
    MaxDps:GlowCooldown(classtable.ShadowDance, false)
    MaxDps:GlowCooldown(classtable.GoremawsBite, false)
    MaxDps:GlowCooldown(classtable.ThistleTea, false)
    MaxDps:GlowCooldown(classtable.Shadowmeld, false)
end

function Subtlety:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready then
        if not setSpell then setSpell = classtable.Stealth end
    end
    if (MaxDps:CheckSpellUsable(classtable.Kick, 'Kick')) and cooldown[classtable.Kick].ready then
        MaxDps:GlowCooldown(classtable.Kick, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    snd_condition = buff[classtable.SliceandDiceBuff].up
    Subtlety:cds()
    Subtlety:items()
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'SliceandDice')) and (ComboPoints >= 1 and not snd_condition) and cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end
    if ((IsStealthed() or buff[classtable.ShadowDanceBuff].up or buff[classtable.SubterfugeBuff].up)) then
        Subtlety:stealthed()
            if buff[classtable.ShadowDanceBuff].up and MaxDps.spellHistory[1] then
                if talents[classtable.DanseMacabre] and not DanseMacabreSpellList then DanseMacabreSpellList = {} end
                table.insert(DanseMacabreSpellList,table.getn(DanseMacabreSpellList)+1,MaxDps.spellHistory[1])
            else
                DanseMacabreSpellList = {}
            end
    end
    Subtlety:stealth_cds()
    if (buff[classtable.DarkestNightBuff].up and ComboPoints == ComboPointsMax or calculateEffectiveComboPoints(ComboPoints) >= ComboPointsMax and not buff[classtable.DarkestNightBuff].up or ( ComboPointsDeficit <= 1 + (talents[classtable.DeathstalkersMark] and talents[classtable.DeathstalkersMark] or 0) or ttd <= 1 and calculateEffectiveComboPoints(ComboPoints) >= 3 ) and not buff[classtable.DarkestNightBuff].up) then
        Subtlety:finish()
    end
    if (EnergyDeficit <= 20 + (talents[classtable.Vigor] and talents[classtable.Vigor] or 0) * 25 + (talents[classtable.ThistleTea] and talents[classtable.ThistleTea] or 0) * 20 + (talents[classtable.Shadowcraft] and talents[classtable.Shadowcraft] or 0) * 20) then
        Subtlety:build()
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
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
    classtable.LingeringShadowBuff = 385960
    classtable.PerforatedVeinsBuff = 394254
    classtable.FindWeaknessDeBuff = 316220
    classtable.FlawlessFormBuff = 0
    classtable.CleartheWitnessesBuff = 0
    classtable.SymbolsofDeathBuff = 212283
    classtable.RuptureDeBuff = 1943
    classtable.ShadowBladesBuff = 121471
    classtable.TheRottenBuff = 394203
    classtable.ShadowDanceBuff = 185422
    classtable.FlagellationBuffBuff = 394758
    classtable.PremeditationBuff = 343173
    classtable.FlagellationPersistBuff = 384631
    classtable.SubterfugeBuff = 115192
    classtable.ThistleTeaBuff = 381623
    classtable.DanseMacabreBuff = 0
    classtable.EscalatingBladeBuff = 0
    classtable.DarkestNightBuff = 0
    classtable.FazedDeBuff = 0
    classtable.FinalityRuptureBuff = 385951
    classtable.DeathstalkersMarkDeBuff = 0
    classtable.ShurikenTornadoBuff = 277925
    classtable.SliceandDiceBuff = 315496
    setSpell = nil
    ClearCDs()

    Subtlety:precombat()

    Subtlety:callaction()
    if setSpell then return setSpell end
end
