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

local Combat = {}

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.BladeFlurry, false)
    MaxDps:GlowCooldown(classtable.AdrenalineRush, false)
end

-- TBC Classic Combat Rogue Rotation based on Icy Veins guide
-- Priorities:
-- 1. Keep Slice and Dice up at 100% uptime
-- 2. Maintain Expose Armor if spec'd into Improved Expose Armor
-- 3. Apply/maintain Rupture for filler damage
-- 4. Use cooldowns (Blade Flurry, Adrenaline Rush) with Haste Potions
-- 5. Build combo points with Sinister Strike/Backstab
-- 6. Use Eviscerate when target is dying or extra combo points available

function Combat:callaction()
    -- Cooldown usage with Blade Flurry and Adrenaline Rush
    if (MaxDps:CheckSpellUsable(classtable.BladeFlurry, 'Blade Flurry')) and cooldown[classtable.BladeFlurry].ready and
        buff[classtable.SliceandDice].up and ttd > 10 then
        --if not setSpell then setSpell = classtable.BladeFlurry end
        MaxDps:GlowCooldown(classtable.BladeFlurry, true)
    end

    if (MaxDps:CheckSpellUsable(classtable.AdrenalineRush, 'Adrenaline Rush')) and cooldown[classtable.AdrenalineRush].ready and
        buff[classtable.SliceandDice].up and ttd > 10 then
        --if not setSpell then setSpell = classtable.AdrenalineRush end
        MaxDps:GlowCooldown(classtable.AdrenalineRush, true)
    end

    -- Refresh Slice and Dice - maintains 100% uptime (priority)
    if (MaxDps:CheckSpellUsable(classtable.SliceandDice, 'Slice and Dice')) and
        (ComboPoints >= 2 and (not buff[classtable.SliceandDice].up or buff[classtable.SliceandDice].remains <= 3)) and
        cooldown[classtable.SliceandDice].ready then
        if not setSpell then setSpell = classtable.SliceandDice end
    end

    -- Maintain Expose Armor at full uptime if spec'd into Improved Expose Armor
    if (MaxDps:CheckSpellUsable(classtable.ExposeArmor, 'Expose Armor')) and talents[classtable.ImprovedExposeArmor] and
        (ComboPoints >= 5 and (not debuff[classtable.ExposeArmor].up or debuff[classtable.ExposeArmor].remains <= 2)) and
        cooldown[classtable.ExposeArmor].ready then
        if not setSpell then setSpell = classtable.ExposeArmor end
    end

    -- Apply/maintain Rupture for filler damage (especially with extra combo points)
    if (MaxDps:CheckSpellUsable(classtable.Rupture, 'Rupture')) and
        (ComboPoints >= 3 and (not debuff[classtable.Rupture].up or debuff[classtable.Rupture].remains <= 2)) and
        cooldown[classtable.Rupture].ready and ttd > 10 then
        if not setSpell then setSpell = classtable.Rupture end
    end

    -- Use Eviscerate if target is close to death or extra combo points
    if (MaxDps:CheckSpellUsable(classtable.Eviscerate, 'Eviscerate')) and
        (ComboPoints >= 5 and (targethealthPerc < 25 or buff[classtable.BladeFlurry].up)) and
        cooldown[classtable.Eviscerate].ready then
        if not setSpell then setSpell = classtable.Eviscerate end
    end

    -- Build combo points with Sinister Strike (primary builder for Combat spec)
    if (MaxDps:CheckSpellUsable(classtable.SinisterStrike, 'Sinister Strike')) and
        (ComboPoints < 5 and Energy >= 45) and
        cooldown[classtable.SinisterStrike].ready then
        if not setSpell then setSpell = classtable.SinisterStrike end
    end

    -- Backstab only in stealth or if behind target
    if (MaxDps:CheckSpellUsable(classtable.Backstab, 'Backstab')) and
        ((UnitThreatSituation("player") == 0 or buff[classtable.Stealth].up) and ComboPoints < 5 and Energy >= 60) and
        cooldown[classtable.Backstab].ready then
        if not setSpell then setSpell = classtable.Backstab end
    end
end
function Rogue:Combat()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
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

    -- Spell IDs for TBC Combat Rogue
    classtable.SinisterStrike = 26861
    classtable.Backstab = 26863
    classtable.SliceandDice = 6774
    classtable.Rupture = 26867
    classtable.ExposeArmor = 26866
    classtable.Eviscerate = 31016
    classtable.BladeFlurry = 13877
    classtable.AdrenalineRush = 13750
    classtable.Stealth = 1787
    classtable.ImprovedExposeArmor = 14072

    setSpell = nil
    ClearCDs()

    Combat:callaction()
    if setSpell then return setSpell end
end
