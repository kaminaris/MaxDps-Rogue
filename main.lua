-- Spells
local _Moonfire = 8921;
local _Sunfire = 93402;
local _Starsurge = 78674;
local _LunarEmpowerment = 164547;
local _SolarEmpowerment = 164545;
local _LunarStrike = 194153;
local _SolarWrath = 190984;
local _NewMoon = 202767;
local _CelestialAlignment = 194223;
local _IncarnationChosenofElune = 102560;
local _HalfMoon = 202768;
local _FullMoon = 202771;
local _StellarFlare = 202347;
local _Starfall = 191034;
local _MasteryStarlight = 77492;
local _StellarEmpowerment = 197637;
local _Heroism = 32182;
local _Bloodlust = 2825;
local _Berserking = 26297;
local _ForceofNature = 205636;
local _WarriorofElune = 202425;
local _AstralCommunion = 202359;
local _BlessingoftheAncients = 202360;
local _BlessingofElune = 202737;
local _FuryofElune = 202770;

-- Feral
local _SavageRoar = 52610;
local _Rake = 1822;
local _Rip = 1079;
local _Sabertooth = 202031;
local _FerociousBite = 22568;
local _LunarInspiration = 155580;
local _TigersFury = 5217;
local _AshamanesFrenzy = 210722;
local _Shred = 5221;
local _Bloodtalons = 155672;
local _Regrowth = 8936;
local _PredatorySwiftness = 16974;
local _IncarnationKingoftheJungle = 102543;
local _Prowl = 5215;
local _Berserk = 106951;
local _Thrash = 106830;
local _Swipe = 213764;
local _MasteryRazorClaws = 77493;
local _PrimalFury = 159286;
local _JaggedWounds = 202032;
local _OmenofClarity = 16864;
local _Predator = 202021;
local _ElunesGuidance = 202060;
local _BrutalSlash = 202028;
local _ClearCasting = 135700;

-- Guardian
local _Mangle = 33917;
local _MangleProc = 93622;
local _ThrashGuard = 77758;
local _Swipe = 213764;
local _Ironfur = 192081;
local _FrenziedRegeneration = 22842;
local _MarkOfUrsol = 192083;
local _RageOfTheSleeper = 200851;
local _GalacticGuardian = 203964;
local _GalacticGuardianBuff = 213708;

local newMoonPhase = false;

local _isSabertooth = false;
local _isLunarInspiration = false;
local _isSavageRoar = false;
local _isBloodtalons = false;

MaxDps.Druid = {};

function MaxDps.Druid.CheckTalents()
	MaxDps:CheckTalents();
	_isSabertooth = MaxDps:HasTalent(_Sabertooth);
	_isLunarInspiration = MaxDps:HasTalent(_LunarInspiration);
	_isSavageRoar = MaxDps:HasTalent(_SavageRoar);
	_isBloodtalons = MaxDps:HasTalent(_Bloodtalons);
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = "Druid Module [Balance]";
	MaxDps.ModuleOnEnable = MaxDps.Druid.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Druid.Balance;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Druid.Feral;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Druid.Guardian;
	end;
end

function MaxDps.Druid.Balance()
	local timeShift, currentSpell = MaxDps:EndCast();

	local lunar = UnitPower('player', SPELL_POWER_LUNAR_POWER);

	-- detect which phase we are staring
	if MaxDps:FindSpell(_NewMoon) then
		newMoonPhase = _NewMoon;
	elseif MaxDps:FindSpell(_HalfMoon) then
		newMoonPhase = _HalfMoon;
	else
		newMoonPhase = _FullMoon;
	end

	local moon = MaxDps:TargetAura(_Moonfire, timeShift + 5);
	local sun = MaxDps:TargetAura(_Sunfire, timeShift + 3);

	local newmoon, newCharges = MaxDps:SpellCharges(_NewMoon, timeShift);

	local solarE, solarCharges = MaxDps:Aura(_SolarEmpowerment, timeShift);
	local lunarE, lunarCharges = MaxDps:Aura(_LunarEmpowerment, timeShift);

	MaxDps:GlowCooldown(_CelestialAlignment, MaxDps:SpellAvailable(_CelestialAlignment, timeShift));

	if MaxDps:SameSpell(currentSpell, _FullMoon) then
		lunar = lunar + 40;
	elseif MaxDps:SameSpell(currentSpell, _NewMoon) then
		lunar = lunar + 10;
	elseif MaxDps:SameSpell(currentSpell, _HalfMoon) then
		lunar = lunar + 20;
	elseif MaxDps:SameSpell(currentSpell, _SolarWrath) then
		lunar = lunar + 8;
	elseif MaxDps:SameSpell(currentSpell, _LunarStrike) then
		lunar = lunar + 12;
	end

	if not moon then
		return _Moonfire;
	end

	if not sun then
		return _Sunfire;
	end

	if lunar > 70 then
		return _Starsurge;
	end

	if newCharges > 1 then
		return newMoonPhase;
	end

	if newCharges == 1 and (
		not MaxDps:SameSpell(currentSpell, _NewMoon) and
		not MaxDps:SameSpell(currentSpell, _HalfMoon) and
		not MaxDps:SameSpell(currentSpell, _FullMoon)
	)
	then
		return newMoonPhase;
	end

	if lunarCharges >= 3 and not MaxDps:SameSpell(currentSpell, _LunarStrike) then
		return _LunarStrike;
	end

	return _SolarWrath;
end

function MaxDps.Druid.Feral()
	local timeShift, currentSpell = MaxDps:EndCast();

	local energy = UnitPower('player', SPELL_POWER_ENERGY);
	local combo = GetComboPoints('player', 'target');

	local clear = MaxDps:Aura(_ClearCasting, timeShift);
	local bt, btCount = MaxDps:Aura(_Bloodtalons, timeShift);
	local berserk = MaxDps:Aura(_Berserk, timeShift);

	local rip, ripCd = MaxDps:TargetAura(_Rip, timeShift);

	local ph = MaxDps:TargetPercentHealth();

	MaxDps:GlowCooldown(_AshamanesFrenzy, MaxDps:SpellAvailable(_AshamanesFrenzy, timeShift));
	MaxDps:GlowCooldown(_Berserk, MaxDps:SpellAvailable(_Berserk, timeShift));

	if MaxDps:SpellAvailable(_TigersFury, timeShift) and (energy < 20 or berserk) then
		return _TigersFury;
	end

	if _isSavageRoar and not MaxDps:Aura(_SavageRoar, timeShift + 3) and combo >= 5 then
		return _SavageRoar;
	end

	if not MaxDps:TargetAura(_Rake, timeShift + 3) then
		return _Rake;
	end

	if rip and ripCd < 4 and combo >= 5 and (_isSabertooth or ph < 0.25) then
		return _FerociousBite;
	end

	if (not rip or ripCd < 4) and combo >= 5 then
		return _Rip;
	end

	if _isLunarInspiration and not MaxDps:TargetAura(_Moonfire, timeShift + 4) then
		return _Moonfire;
	end

	if _isBloodtalons and MaxDps:Aura(_PredatorySwiftness, timeShift) and combo >= 4 and not bt then
		return _Regrowth;
	end

	if rip and ripCd > 5 and combo >= 5 then
		return _FerociousBite;
	end

	return _Shred;
end

-- Guardian rotation by Ryzux
function MaxDps.Druid.Guardian()
	local timeShift, currentSpell = MaxDps:EndCast();
	local rage = UnitPower('player', SPELL_POWER_RAGE);

	-- Spells
	local mangle = MaxDps:SpellAvailable(_Mangle, timeShift);
	local mangleProc = MaxDps:Aura(_MangleProc, timeShift);
	local thrash = MaxDps:SpellAvailable(_ThrashGuard, timeShift);
	local moonfire = MaxDps:TargetAura(_Moonfire, timeShift + 5);
	local gg = MaxDps:Aura(_GalacticGuardianBuff, timeShift);
	local swipe = MaxDps:SpellAvailable(_Swipe, timeShift);

	-- Defensives
	MaxDps:GlowCooldown(_Ironfur, timeShift);
	MaxDps:GlowCooldown(_RageOfTheSleeper, timeShift);

	-- #1. Mangle on cooldown.
	if mangle or mangleProc then
		return _Mangle;
	end

	-- #2. Thrash on cooldown.
	if thrash then
		return _ThrashGuard;
	end

	-- #3. Moonfire if target doesn't have debuff or with Galactic Guardian proc.
	if not moonfire or gg then
		return _Moonfire;
	end

	-- #4. Swipe if anything else is available.
	return _Swipe;
end