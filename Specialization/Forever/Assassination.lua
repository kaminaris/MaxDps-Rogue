local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Assassination = {}

-- Forever flavor fixes:
-- 1) Spell ids are rank-specific and differ from the historical hardcodes
--    (observed on a live Forever client: Eviscerate 6760, Backstab 2589), so
--    resolve by name at call time - this also picks up higher ranks the
--    moment they are learned. Falls back to the historical id when the spell
--    is not known yet. (Also fixes Mutilate: the previous hardcode 1310707
--    is not a valid spell id.)
-- 2) IsTrackedAuraActive reads the HUD cooldown viewers and returns nil on
--    setups where they are hidden, which made Slice and Dice re-recommended
--    forever while it was already up. Remember the last successful cast as a
--    minimum-duration fallback (9s = rank 1); the aura check still wins when
--    it answers.
local function S(name, fallback)
    local get = C_Spell and C_Spell.GetSpellInfo
    if get then
        local ok, info = pcall(get, name)
        if ok and info and info.spellID then return info.spellID end
    end
    return fallback
end

local sndExpire = 0
local sndWatcher = CreateFrame("Frame")
sndWatcher:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
sndWatcher:SetScript("OnEvent", function(_, _, unit, _, spellId)
    if unit == "player" and spellId == S("Slice and Dice", 5171) then
        sndExpire = GetTime() + 9
    end
end)
local function SnDUp()
    return MaxDps.IsTrackedAuraActive(S("Slice and Dice", 5171)) or GetTime() < sndExpire
end

function Rogue:Assassination()
    if (IsStealthed()) and not MaxDps.IsSpellOnCooldown(S("Cheap Shot", 1833), true) then return S("Cheap Shot", 1833) end --  Cheap Shot
    if (IsStealthed() and not MaxDps.IsTrackedAuraActive(S("Garrote", 703))) and not MaxDps.IsSpellOnCooldown(S("Garrote", 703), true) then return S("Garrote", 703) end --  Garrote
    if (MaxDps.Power("combo_points", false) >= 1 and not SnDUp()) and not MaxDps.IsSpellOnCooldown(S("Slice and Dice", 5171), true) then return S("Slice and Dice", 5171) end --  Slice and Dice
    if (SnDUp()) and not MaxDps.IsSpellOnCooldown(S("Cold Blood", 14177), true) then return S("Cold Blood", 14177) end --  Cold Blood
    if (MaxDps.Power("combo_points", false) >= 4 and (SnDUp() or MaxDps.Power("energy", false) >= 79)) and not MaxDps.IsSpellOnCooldown(S("Eviscerate", 2098), true) then return S("Eviscerate", 2098) end -- Eviscerate
    if not MaxDps.IsSpellOnCooldown(S("Mutilate", 1329), true) then return S("Mutilate", 1329) end --  Mutilate
end
