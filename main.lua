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

local newMoonPhase = false;

MaxDps.Druid = {};

function MaxDps.Druid.CheckTalents()
	--_isTalent = TD_TalentEnabled('Talent Name');
	-- other checking functions
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
	local ca = MaxDps:SpellAvailable(_CelestialAlignment, timeShift);

	local solarE, solarCharges = MaxDps:Aura(_SolarEmpowerment, timeShift);
	local lunarE, lunarCharges = MaxDps:Aura(_LunarEmpowerment, timeShift);

	MaxDps:GlowCooldown(_CelestialAlignment, ca);

	if currentSpell == 'Full Moon' then
		lunar = lunar + 40;
	elseif currentSpell == 'New Moon' then
		lunar = lunar + 10;
	elseif currentSpell == 'Half Moon' then
		lunar = lunar + 20;
	elseif currentSpell == 'Solar Wrath' then
		lunar = lunar + 8;
	elseif currentSpell == 'Lunar Strike' then
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

	if newCharges == 1 and (currentSpell ~= 'New Moon' and currentSpell ~= 'Half Moon' and currentSpell ~= 'Full Moon')
	then
		return newMoonPhase;
	end

	if lunarCharges >= 3 and currentSpell ~= 'Lunar Strike' then
		return _LunarStrike;
	end

	return _SolarWrath;
end

function MaxDps.Druid.Feral()
	local timeShift, currentSpell = MaxDps:EndCast();

	return nil;
end

function MaxDps.Druid.Guardian()
	local timeShift, currentSpell = MaxDps:EndCast();

	return nil;
end