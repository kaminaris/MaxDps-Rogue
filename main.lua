
-- Outlaw
local _BladeFlurry = 13877;
local _RolltheBones = 193316;
local _TrueBearing = 193359;
local _SharkInfestedWaters = 193357;
local _GhostlyStrike = 196937;
local _CurseoftheDreadblades = 202665;
local _AdrenalineRush = 13750;
local _MarkedforDeath = 137619;
local _RunThrough = 2098;
local _Broadsides = 193356;
local _PistolShot = 185763;
local _Opportunity = 195627;
local _SaberSlash = 193315;
local _Vanish = 1856;
local _Ambush = 8676;
local _CheapShot = 1833;
local _PreyontheWeak = 131511;
local _DeeperStratagem = 193531;
local _JollyRoger = 199603;
local _GrandMelee = 193358;
local _BuriedTreasure = 199600;
local _SliceandDice = 5171;
local _DeathfromAbove = 152150;
local _Vigor = 14983;
local _CombatPotency = 35551;
local _Bloodlust = 2825;
local _Heroism = 32182;
local _TimeWarp = 80353;
local _Ruthlessness = 14161;
local _Sprint = 2983;
local _BetweentheEyes = 199804;
local _Blind = 2094;
local _CloakofShadows = 31224;
local _Riposte = 199754;
local _GrapplingHook = 195457;
local _CannonballBarrage = 185767;
local _KillingSpree = 51690;
local _Feint = 1966;
local _Elusiveness = 79008;
local _CheatDeath = 31230;
local _CrimsonVial = 185311;
local _Stealth = 1784;
local _HiddenBlade = 202753;

-- Auras
local _Stealth = 1784;

-- Talents
local _isGhostlyStrike = false;
local _isMarkedforDeath = false;
MaxDps.Rogue = {};

function MaxDps.Rogue.CheckTalents()
    MaxDps:CheckTalents();
    _isGhostlyStrike = MaxDps:HasTalent(_GhostlyStrike);
    _isMarkedforDeath = MaxDps:HasTalent(_MarkedforDeath);
end

function MaxDps:EnableRotationModule(mode)
    mode = mode or 1;
    MaxDps.Description = 'Rogue [Outlaw]';
    MaxDps.ModuleOnEnable = MaxDps.Rogue.CheckTalents;
    if mode == 1 then
        MaxDps.NextSpell = MaxDps.Rogue.Assassination;
    end;
    if mode == 2 then
        MaxDps.NextSpell = MaxDps.Rogue.Outlaw;
    end;
    if mode == 3 then
        MaxDps.NextSpell = MaxDps.Rogue.Subtlety;
    end;
end

function MaxDps.Rogue.Assassination()
    local timeShift, currentSpell, gcd = MaxDps:EndCast();

    return nil;
end

function MaxDps.Rogue.Outlaw()
    local timeShift, currentSpell, gcd = MaxDps:EndCast();

    local energy = UnitPower('player', SPELL_POWER_ENERGY);
    local combo = GetComboPoints('player', 'target');

    MaxDps:GlowCooldown(_AdrenalineRush, MaxDps:SpellAvailable(_AdrenalineRush, timeShift));
    MaxDps:GlowCooldown(_CurseoftheDreadblades, MaxDps:SpellAvailable(_CurseoftheDreadblades, timeShift));
    MaxDps:GlowCooldown(_KillingSpree, MaxDps:SpellAvailable(_KillingSpree, timeShift));

    if MaxDps:PersistentAura(_Stealth, timeShift) then
        return _Ambush;
    end

    local curse = MaxDps:Aura(_CurseoftheDreadblades, timeShift, 'HARMFUL');

    -- roll the bones auras
    local rb = {
        TB = MaxDps:Aura(_TrueBearing, timeShift + 3),
        SIW = MaxDps:Aura(_SharkInfestedWaters, timeShift + 3),
        JR = MaxDps:Aura(_JollyRoger, timeShift + 3),
        GM = MaxDps:Aura(_GrandMelee, timeShift + 3),
        BS = MaxDps:Aura(_Broadsides, timeShift + 3),
        BT = MaxDps:Aura(_BuriedTreasure, timeShift + 3),
    }
    -- buty, sprint co CD
    local rbCount = 0;
    for k, v in pairs(rb) do
        if v then
            rbCount = rbCount + 1;
        end
    end

    local shouldRoll = not rb.TB and rbCount < 2;

    if shouldRoll and combo >=4 and energy >= 20 then
        return _RolltheBones;
    end

    if _isGhostlyStrike and not MaxDps:TargetAura(_GhostlyStrike, timeShift + 3) and energy > 27 then
        return _GhostlyStrike;
    end

    if _isMarkedforDeath and combo < 2 and MaxDps:SpellAvailable(_MarkedforDeath, timeShift) then
        return _MarkedforDeath;
    end

    if (combo >= 6 or (combo >= 5 and rb.BS)) then
        return _RunThrough;
    end

    if MaxDps:Aura(_Opportunity, timeShift) and combo <= 4 then
        return _PistolShot;
    end

    return _SaberSlash;
end

function MaxDps.Rogue.Subtlety()
    local timeShift, currentSpell, gcd = MaxDps:EndCast();

    return nil;
end