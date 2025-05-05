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

local priority_rotation = false
local trinket_sync_slot = false
local stealth = false
local skip_rupture = false
local maintenance = false
local secret = false
local racial_sync = false
local shd_cp = false
local cooldowns_soon = false


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

local frame = CreateFrame("Frame")
local shadowDanceActive = false
local usedSpells = {}

-- List of spells that count for Danse Macabre
local danseMacabreSpells = {
    [185438] = "Shadowstrike",
    [196819] = "Eviscerate",
    [53] = "Backstab",
    [197835] = "Shuriken Storm",
    [1943] = "Rupture",
    [319175] = "Black Powder",
    [280719] = "Secret Technique",
    [212283] = "Symbols of Death",
    [114014] = "Shuriken Toss",
    [200758] = "Gloomblade",
}

-- Function to reset tracking
local function ResetDanseMacabre()
    shadowDanceActive = false
    wipe(usedSpells) -- Clears the table
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            -- Check if Shadow Dance is active
            local shadowDanceFound = false
            for i = 1, 40 do
                local data = C_UnitAuras.GetAuraDataByIndex("player", i)
                local name = data and data.name
                local spellId = data and data.spellId
                if not name then break end
                if spellId == 185422 then -- Shadow Dance spell ID
                    shadowDanceFound = true
                    break
                end
            end

            if shadowDanceFound and not shadowDanceActive then
                shadowDanceActive = true
                wipe(usedSpells) -- Reset spells when Shadow Dance starts
            elseif not shadowDanceFound and shadowDanceActive then
                ResetDanseMacabre()
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, _, destName, _, _, spellId = CombatLogGetCurrentEventInfo()
        if shadowDanceActive and subEvent == "SPELL_CAST_SUCCESS" and danseMacabreSpells[spellId] then
            if not usedSpells[spellId] then
                usedSpells[spellId] = true
                --print("Spell used for Danse Macabre: " .. danseMacabreSpells[spellId])
            end
        end
    end
end)

-- Register events
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function CheckDanseMacabre(spell)
	return (not talents[classtable.DanseMacabre] and true) or (usedSpells[spell] and true) or (not usedSpells[spell] and false)
end


function Subtlety:precombat()
    if (MaxDps:CheckSpellUsable(classtable.InstantPoison, 'InstantPoison')) and not buff[classtable.InstantPoison].up and cooldown[classtable.InstantPoison].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.InstantPoison end
    end
    priority_rotation = false
    if (MaxDps:CheckSpellUsable(classtable.Stealth, 'Stealth')) and cooldown[classtable.Stealth].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Stealth end
    end
end
function Subtlety:build()
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and (buff[classtable.ShadowDanceBuff].up and not CheckDanseMacabre(classtable.Backstab) or not stealth and buff[classtable.ShadowBladesBuff].up) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
    if (MaxDps:CheckSpellUsable(classtable.Gloomblade, 'Gloomblade')) and talents[classtable.Gloomblade] and (buff[classtable.ShadowDanceBuff].up and not CheckDanseMacabre(classtable.Gloomblade) or not stealth and buff[classtable.ShadowBladesBuff].up) and cooldown[classtable.Gloomblade].ready then
        if not setSpell then setSpell = classtable.Gloomblade end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstrike, 'Shadowstrike')) and (debuff[classtable.FindWeaknessDeBuff].remains <= 2 and targets == 2 and talents[classtable.UnseenBlade] or not CheckDanseMacabre(classtable.Shadowstrike) and not talents[classtable.Premeditation]) and cooldown[classtable.Shadowstrike].ready then
        if not setSpell then setSpell = classtable.Shadowstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenTornado, 'ShurikenTornado')) and (buff[classtable.LingeringDarknessBuff].up or talents[classtable.DeathstalkersMark] and cooldown[classtable.ShadowBlades].remains >= 32 and targets >= 3 or talents[classtable.UnseenBlade] and ( not stealth or targets >= 3 ) and ( buff[classtable.SymbolsofDeathBuff].up or not (targets >1) )) and cooldown[classtable.ShurikenTornado].ready then
        MaxDps:GlowCooldown(classtable.ShurikenTornado, cooldown[classtable.ShurikenTornado].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenStorm, 'ShurikenStorm')) and (buff[classtable.CleartheWitnessesBuff].up and ( targets >= 2 or not buff[classtable.SymbolsofDeathBuff].up )) and cooldown[classtable.ShurikenStorm].ready then
        if not setSpell then setSpell = classtable.ShurikenStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstrike, 'Shadowstrike')) and (talents[classtable.DeathstalkersMark] and not debuff[classtable.DeathstalkersMarkDeBuff].up and targets >= 3 and ( buff[classtable.ShadowBladesBuff].up or buff[classtable.PremeditationBuff].up or talents[classtable.TheRotten] )) and cooldown[classtable.Shadowstrike].ready then
        if not setSpell then setSpell = classtable.Shadowstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenStorm, 'ShurikenStorm')) and (talents[classtable.DeathstalkersMark] and targets >= ( 2 + 3 * buff[classtable.ShadowDanceBuff].duration )) and cooldown[classtable.ShurikenStorm].ready then
        if not setSpell then setSpell = classtable.ShurikenStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShurikenStorm, 'ShurikenStorm')) and (talents[classtable.UnseenBlade] and ( buff[classtable.FlawlessFormBuff].up and targets >= 3 and not stealth or buff[classtable.TheRottenBuff].count == 1 and targets >= 6 and buff[classtable.ShadowDanceBuff].up )) and cooldown[classtable.ShurikenStorm].ready then
        if not setSpell then setSpell = classtable.ShurikenStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowstrike, 'Shadowstrike')) and cooldown[classtable.Shadowstrike].ready then
        if not setSpell then setSpell = classtable.Shadowstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.GoremawsBite, 'GoremawsBite')) and (ComboPointsDeficit >= 3) and cooldown[classtable.GoremawsBite].ready then
        MaxDps:GlowCooldown(classtable.GoremawsBite, cooldown[classtable.GoremawsBite].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Gloomblade, 'Gloomblade')) and talents[classtable.Gloomblade] and cooldown[classtable.Gloomblade].ready then
        if not setSpell then setSpell = classtable.Gloomblade end
    end
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
end
function Subtlety:cds()
    if (MaxDps:CheckSpellUsable(classtable.ColdBlood, 'ColdBlood')) and (cooldown[classtable.SecretTechnique].ready and buff[classtable.ShadowDanceBuff].up and ComboPoints >= 6 and secret and ( not talents[classtable.Flagellation] or buff[classtable.FlagellationPersistBuff].up )) and cooldown[classtable.ColdBlood].ready then
        MaxDps:GlowCooldown(classtable.ColdBlood, cooldown[classtable.ColdBlood].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SymbolsofDeath, 'SymbolsofDeath')) and (( buff[classtable.SymbolsofDeathBuff].remains <= 3 and maintenance and ( targets >= 3 or not buff[classtable.FlagellationBuffBuff].up or debuff[classtable.RuptureDeBuff].remains >= 30 ) and ( not talents[classtable.Flagellation] or cooldown[classtable.Flagellation].remains >= 30 - 15 * (talents[classtable.DeathPerception] and 0 or 1) and cooldown[classtable.SecretTechnique].remains <8 or not talents[classtable.DeathPerception] ) or MaxDps:boss() and ttd <= 15 and ( MaxDps:boss() or not buff[classtable.SymbolsofDeathBuff].up ) )) and cooldown[classtable.SymbolsofDeath].ready then
        MaxDps:GlowCooldown(classtable.SymbolsofDeath, cooldown[classtable.SymbolsofDeath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowBlades, 'ShadowBlades')) and (maintenance and shd_cp and buff[classtable.ShadowDanceBuff].up and not buff[classtable.PremeditationBuff].up) and cooldown[classtable.ShadowBlades].ready then
        MaxDps:GlowCooldown(classtable.ShadowBlades, cooldown[classtable.ShadowBlades].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThistleTea, 'ThistleTea')) and (buff[classtable.ShadowDanceBuff].remains >2 and not buff[classtable.ThistleTeaBuff].up) and cooldown[classtable.ThistleTea].ready then
        MaxDps:GlowCooldown(classtable.ThistleTea, cooldown[classtable.ThistleTea].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Flagellation, 'Flagellation') and talents[classtable.Flagellation]) and (ComboPoints >= 5 and cooldown[classtable.ShadowBlades].remains <= 3 or MaxDps:boss() and ttd <= 25) and cooldown[classtable.Flagellation].ready then
        --MaxDps:GlowCooldown(classtable.Flagellation, cooldown[classtable.Flagellation].ready)
        if not setSpell then setSpell = classtable.Flagellation end
    end
end
function Subtlety:fill()
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
    end
end
function Subtlety:finish()

    cooldowns_soon = cooldown[classtable.ShadowBlades].remains <= 13 and cooldown[classtable.Flagellation].remains <10 and ( debuff[classtable.RuptureDeBuff].remains <( cooldown[classtable.ShadowBlades].remains + buff[classtable.ShadowBladesBuff].duration ) )

    if (MaxDps:CheckSpellUsable(classtable.SecretTechnique, 'SecretTechnique')) and (secret) and cooldown[classtable.SecretTechnique].ready then
        if not setSpell then setSpell = classtable.SecretTechnique end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (not skip_rupture and ( not debuff[classtable.RuptureDeBuff].up or debuff[classtable.RuptureDeBuff].refreshable or buff[classtable.FlagellationBuffBuff].up and not buff[classtable.SymbolsofDeathBuff].up and targets <= 2 ) and ttd - debuff[classtable.RuptureDeBuff].remains >6) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (not skip_rupture and not priority_rotation and ttd >= ( 2 * ComboPoints ) and debuff[classtable.RuptureDeBuff].refreshable and targets >= 2) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and (talents[classtable.UnseenBlade] and cooldowns_soon and targets >= 3 and debuff[classtable.RuptureDeBuff].remains <ttd) and cooldown[classtable.Rupture].ready then
        if not setSpell then setSpell = classtable.Rupture end
    end
    if (MaxDps:CheckSpellUsable(classtable.CoupdeGrace, 'CoupdeGrace')) and (debuff[classtable.FazedDeBuff].up and cooldown[classtable.Flagellation].remains >= 20 or ttd <= 10) and cooldown[classtable.CoupdeGrace].ready then
        if not setSpell then setSpell = classtable.CoupdeGrace end
    end
    if (MaxDps:CheckSpellUsable(classtable.BlackPowder, 'BlackPowder')) and (not priority_rotation and maintenance and ( ( ( targets >= 2 and talents[classtable.DeathstalkersMark] and ( not buff[classtable.DarkestNightBuff].up or buff[classtable.ShadowDanceBuff].up and targets >= 5 ) ) or talents[classtable.UnseenBlade] and targets >= 5 ) or cooldown[classtable.CoupdeGrace].ready and targets >= 3 )) and cooldown[classtable.BlackPowder].ready then
        if not setSpell then setSpell = classtable.BlackPowder end
    end
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and (cooldown[classtable.Flagellation].remains >= 10 or targets >= 3) and cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end
end
function Subtlety:stealth_cds()
    if (MaxDps:CheckSpellUsable(classtable.ShadowDance, 'ShadowDance')) and (shd_cp and maintenance and ( cooldown[classtable.SecretTechnique].remains <= 24 or talents[classtable.TheFirstDance] and buff[classtable.ShadowBladesBuff].up ) and ( buff[classtable.SymbolsofDeathBuff].remains >= 6 or buff[classtable.ShadowBladesBuff].remains >= 6 ) or MaxDps:boss() and ttd <= 10) and cooldown[classtable.ShadowDance].ready then
        MaxDps:GlowCooldown(classtable.ShadowDance, cooldown[classtable.ShadowDance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Vanish, 'Vanish')) and (Energy >= 40 and not buff[classtable.SubterfugeBuff].up and calculateEffectiveComboPoints(ComboPoints) <= 3) and cooldown[classtable.Vanish].ready then
        MaxDps:GlowCooldown(classtable.Vanish, cooldown[classtable.Vanish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and (Energy >= 40 and ComboPointsDeficit >= 3) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Kick, false)
    MaxDps:GlowCooldown(classtable.ShurikenTornado, false)
    MaxDps:GlowCooldown(classtable.GoremawsBite, false)
    MaxDps:GlowCooldown(classtable.ColdBlood, false)
    MaxDps:GlowCooldown(classtable.SymbolsofDeath, false)
    MaxDps:GlowCooldown(classtable.ShadowBlades, false)
    MaxDps:GlowCooldown(classtable.ThistleTea, false)
    --MaxDps:GlowCooldown(classtable.Flagellation, false)
    MaxDps:GlowCooldown(classtable.ShadowDance, false)
    MaxDps:GlowCooldown(classtable.Vanish, false)
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
            DanseMacabreSpellList = DanseMacabreSpellList or {}
            table.insert(DanseMacabreSpellList, #DanseMacabreSpellList + 1, MaxDps.spellHistory[1])
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

    classtable.InstantPoison = 315584
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ShadowDanceBuff = 185422
    classtable.StealthBuff = 115191
    classtable.VanishBuff = 11327
    classtable.DarkestNightBuff = 457280
    classtable.SliceandDiceBuff = 315496
    classtable.ShadowBladesBuff = 121471
    classtable.SymbolsofDeathBuff = 212283
    classtable.FlagellationBuffBuff = 384631
    classtable.LingeringDarknessBuff = 457273
    classtable.CleartheWitnessesBuff = 457178
    classtable.PremeditationBuff = 343173
    classtable.FlawlessFormBuff = 0
    classtable.TheRottenBuff = 394203
    classtable.FlagellationPersistBuff = 394758
    classtable.BloodlustBuff = 2825
    classtable.ThistleTeaBuff = 381623
    classtable.SubterfugeBuff = 115192
    classtable.RuptureDeBuff = 1943
    classtable.FindWeaknessDeBuff = 0
    classtable.DeathstalkersMarkDeBuff = 457129
    classtable.FazedDeBuff = 441224
    classtable.ArcanePulse = 260369
    classtable.Shadowmeld = 58984

    local function debugg()
        talents[classtable.LingeringDarkness] = 1
        talents[classtable.UnseenBlade] = 1
        talents[classtable.Premeditation] = 1
        talents[classtable.DeathstalkersMark] = 1
        talents[classtable.TheRotten] = 1
        talents[classtable.Flagellation] = 1
        talents[classtable.DeathPerception] = 1
        talents[classtable.TheFirstDance] = 1
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
