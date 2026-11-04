local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Assassination = {}

function Rogue:Assassination()
    if IsStealthed() then return 1833 end --  Cheap Shot
    if IsStealthed() and not MaxDps.IsTrackedAuraActive(703) then return 703 end --  Garrote
    if MaxDps.Power("combo_points", false) >= 1 and not MaxDps.IsTrackedAuraActive(5171) then return 5171 end --  Slice and Dice
    if MaxDps.IsTrackedAuraActive(5171) then return 14177 end --  Cold Blood
    if MaxDps.Power("combo_points", false) >= 4 and (MaxDps.IsTrackedAuraActive(5171) or MaxDps.Power("energy", false) >= 79) then return 2098 end -- Eviscerate
    if not MaxDps.IsSpellOnCooldown(1310707, true) then return 1310707 end --  Mutilate
end
