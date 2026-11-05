local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Outlaw = {}

function Rogue:Outlaw()
    if (IsStealthed()) and not MaxDps.IsSpellOnCooldown(1833, true) then return 1833 end --  Cheap Shot
    if (IsStealthed() and not MaxDps.IsTrackedAuraActive(703)) and not MaxDps.IsSpellOnCooldown(703, true) then return 703 end --  Garrote
    if (MaxDps.Power("combo_points", false) >= 1 and not MaxDps.IsTrackedAuraActive(5171)) and not MaxDps.IsSpellOnCooldown(5171, true) then return 5171 end --  Slice and Dice
    if ((MaxDps.Power("energy", false) < 59)) and not MaxDps.IsSpellOnCooldown(13750, true) then return 13750 end --  Adrenaline Rush
    if (MaxDps.Power("combo_points", false) >= 5 and (MaxDps.IsTrackedAuraActive(5171) or MaxDps.Power("energy", false) >= 79)) and not MaxDps.IsSpellOnCooldown(2098, true) then return 2098 end -- Eviscerate
    if not MaxDps.IsSpellOnCooldown(1752, true) then return 1752 end --  Sinister Strike
end
