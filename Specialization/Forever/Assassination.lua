local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Assassination = {}

function Rogue:Assassination()
    if (IsStealthed()) and not MaxDps.IsSpellOnCooldown(1833, true) then return 1833 end --  Cheap Shot
    if (IsStealthed() and not MaxDps.IsTrackedAuraActive(703)) and not MaxDps.IsSpellOnCooldown(703, true) then return 703 end --  Garrote
    if (MaxDps.Power("combo_points", false) >= 1 and not MaxDps.IsTrackedAuraActive(5171)) and not MaxDps.IsSpellOnCooldown(5171, true) then return 5171 end --  Slice and Dice
    if (MaxDps.IsTrackedAuraActive(5171)) and not MaxDps.IsSpellOnCooldown(14177, true) then return 14177 end --  Cold Blood
    if (MaxDps.Power("combo_points", false) >= 4 and (MaxDps.IsTrackedAuraActive(5171) or MaxDps.Power("energy", false) >= 79)) and not MaxDps.IsSpellOnCooldown(2098, true) then return 2098 end -- Eviscerate
    if not MaxDps.IsSpellOnCooldown(1310707, true) then return 1310707 end --  Mutilate
end
