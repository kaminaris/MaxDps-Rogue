local _, addonTable = ...

--- @type MaxDps
if not MaxDps then
    return
end

local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local GetPowerRegen = GetPowerRegen
local Rogue = addonTable.Rogue
local cooldown, buff, debuff, talents, currentSpell, gcd
local energy
local energyMax
local energyDeficit
local energyRegen
local energyTimeToMax
local combo
local comboMax
local comboDeficit
local targets

local SB = {
    BlackPowder = 319175,
    Backstab = 53,
    DeeperStratagem = 193531,
    EchoingReprimand = 385616,
    Eviscerate = 196819,
    Flagellation = 323654,
    Gloomblade = 200758,
    MarkedForDeath = 137619,
    Rupture = 1943,
    SecretStrategem = 394320,
    SecretTechnique = 280719,
    Sepsis = 328305,
    SepsisAura = 347037,
    SerratedBoneSpear = 328547,
    SerratedBoneSpearAura = 324073,
    --spell id same as buff id
    ShadowBlades = 121471,
    ShadowDance = 185313,
    ShadowDanceBuff = 185422,
    Shadowstrike = 185438,
    ShurikenStorm = 197835,
    ShurikenTornado = 277925,
    SliceAndDice = 315496,
    Stealth = 1784,
    --spell id same as buff id
    SymbolsOfDeath = 212283,
    ThistleTea = 381623,
}

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

echoingReprimand.up = function(comboPoints)
    local buff = MaxDps.FrameData.buff

    for i in pairs(echoingReprimand.auras) do
        local aura = echoingReprimand.auras[i]
        if buff[aura.id].up and aura.cp == comboPoints then
            return true
        end
    end

    return false
end

setmetatable(SB, Rogue.spellMeta)

function Rogue:Subtlety()
    local fd = MaxDps.FrameData
    cooldown, buff, debuff, talents, azerite, currentSpell, gcd = fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.gcd

    energy = UnitPower('player', 3)
    energyMax = UnitPowerMax('player', 3)
    energyDeficit = energyMax - energy
    energyRegen = GetPowerRegen()
    energyTimeToMax = (energyMax - energy) / energyRegen
    combo = UnitPower('player', 4)
    comboMax = UnitPowerMax('player', 4)
    comboDeficit = comboMax - combo
    targets = MaxDps:SmartAoe()

    MaxDps:GlowEssences()
    MaxDps:GlowCooldown(SB.ShadowBlades, cooldown[SB.ShadowBlades].ready and not buff[SB.ShadowBlades].up)
    MaxDps:GlowCooldown(SB.Flagellation, cooldown[SB.Flagellation].ready and not buff[SB.Flagellation].up)

    if targets > 2 then
        return Rogue:SubtletyMultiTarget()
    end
    return Rogue:SubtletySingleTarget()
end
function Rogue:HasEnoughComboPoints()
    return combo >= comboMax or (combo >= (comboMax - 1) and buff[SB.ShadowDanceBuff].up) or echoingReprimand.up(combo)
end

function Rogue:SubtletySingleTarget()
    local enoughComboPoints = Rogue:HasEnoughComboPoints()

    if enoughComboPoints and talents[SB.Flagellation] and cooldown[SB.Flagellation].ready then
        return SB.Flagellation
    end

    if enoughComboPoints then
        if buff[SB.SliceAndDice].refreshable and energy >= Rogue:EnergyCost(SB.SliceAndDice) then
            return SB.SliceAndDice
        end
        if buff[SB.Rupture].refreshable and energy >= Rogue:EnergyCost(SB.Rupture) then
            return SB.Rupture
        end
        if energy >= Rogue:EnergyCost(SB.Eviscerate) then
            return SB.Eviscerate
        end
    end

    if cooldown[SB.SymbolsOfDeath].ready then
        return SB.SymbolsOfDeath
    end

    if talents[SB.ShadowBlades] and buff[SB.SymbolsOfDeath].up and cooldown[SB.ShadowBlades].ready then
        return SB.ShadowBlades
    end

    if talents[SB.Sepsis] and buff[SB.SymbolsOfDeath].up then
        return SB.Sepsis
    end

    if talents[SB.ShurikenTornado] and buff[SB.SymbolsOfDeath].up and cooldown[SB.ShurikenTornado].ready then
        return SB.ShurikenTornado
    end

    if cooldown[SB.ShadowDance].charges >= 1 and not buff[SB.ShadowDanceBuff].up then
        return SB.ShadowDance
    end

    if energy < 30 then
        return SB.ThistleTea
    end

    if talents[SB.EchoingReprimand] and cooldown[SB.EchoingReprimand].ready and not buff[SB.ShadowDanceBuff].up then
        return SB.EchoingReprimand
    end

    if buff[SB.ShadowDanceBuff].up and energy >= Rogue:EnergyCost(SB.Shadowstrike) then
        return SB.Shadowstrike
    else
        if talents[SB.Gloomblade] and energy >= Rogue:EnergyCost(SB.Gloomblade) then
            return SB.Gloomblade
        end
        if not talents[SB.Gloomblade] and energy >= Rogue:EnergyCost(SB.Backstab) then
            return SB.Backstab
        end
    end

end

function Rogue:SubtletyMultiTarget()
    local enoughComboPoints = Rogue:HasEnoughComboPoints()
    if talents[SB.EchoingReprimand] and cooldown[SB.EchoingReprimand].ready and not buff[SB.ShadowDanceBuff].up then
        return SB.EchoingReprimand
    end

    if enoughComboPoints and targets < 5 then
        if buff[SB.SliceAndDice].refreshable and energy >= Rogue:EnergyCost(SB.SliceAndDice) then
            return SB.SliceAndDice
        end
        if buff[SB.Rupture].refreshable and energy >= Rogue:EnergyCost(SB.Rupture) then
            return SB.Rupture
        end
    end

    if cooldown[SB.SymbolsOfDeath].ready then
        return SB.SymbolsOfDeath
    end

    if talents[SB.ShadowBlades] and buff[SB.SymbolsOfDeath].up and cooldown[SB.ShadowBlades].ready then
        return SB.ShadowBlades
    end

    if talents[SB.Sepsis] and buff[SB.SymbolsOfDeath].up then
        return SB.Sepsis
    end

    if talents[SB.ShurikenTornado] and buff[SB.SymbolsOfDeath].up and cooldown[SB.ShurikenTornado].ready then
        return SB.ShurikenTornado
    end

    if cooldown[SB.ShadowDance].charges >= 1 and not buff[SB.ShadowDanceBuff].up then
        return SB.ShadowDance
    end

    if enoughComboPoints and talents[SB.Flagellation] and cooldown[SB.Flagellation].ready then
        return SB.Flagellation
    end

    if enoughComboPoints then
        if talents[SB.SecretTechnique] and cooldown[SB.SecretTechnique].ready and energy >= Rogue:EnergyCost(SB.SecretTechnique) then
            return SB.SecretTechnique
        end
        if talents[SB.BlackPowder] and energy >= Rogue:EnergyCost(SB.BlackPowder) then
            return SB.BlackPowder
        end
    end

    if energy < 30 then
        return SB.ThistleTea
    end

    if energy >= Rogue:EnergyCost(SB.ShurikenStorm) then
        return SB.ShurikenStorm
    end

end

