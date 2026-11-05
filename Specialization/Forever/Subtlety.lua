local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Subtlety = {}

function Rogue:Subtlety()
    if (IsStealthed()) and not MaxDps.IsSpellOnCooldown(1833, true) then return 1833 end --  Cheap Shot
    if (IsStealthed() and not MaxDps.IsTrackedAuraActive(703)) and not MaxDps.IsSpellOnCooldown(703, true) then return 703 end --  Garrote
    if (MaxDps.Power("combo_points", false) >= 1 and not MaxDps.IsTrackedAuraActive(5171)) and not MaxDps.IsSpellOnCooldown(5171, true) then return 5171 end --  Slice and Dice
    if ((MaxDps.Power("energy", false) >= 60) and (MaxDps.Power("combo_points", false) <= 1) and MaxDps.IsTrackedAuraActive(5171)) and not MaxDps.IsSpellOnCooldown(1856, true) then return 1856 end --  Vanish
    if not MaxDps.IsSpellOnCooldown(14183, true) then return 14183 end --  Premeditation
    if not MaxDps.IsSpellOnCooldown(8676, true) then return 8676 end --  Ambush
    if ((MaxDps.Power("combo_points", false) >= 3) and not MaxDps.IsTrackedAuraActive(1943)) and not MaxDps.IsSpellOnCooldown(1943, true) then return 1943 end --  Rupture
    if (MaxDps.Power("combo_points", false) >= 4 and (MaxDps.IsTrackedAuraActive(5171) or MaxDps.Power("energy", false) >= 79)) and not MaxDps.IsSpellOnCooldown(2098, true) then return 2098 end -- Eviscerate
    if not MaxDps.IsSpellOnCooldown(16511, true) then return 16511 end --  Hemorrhage
end
