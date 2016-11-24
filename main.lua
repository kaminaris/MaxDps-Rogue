-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

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


----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Druid_CheckTalents = function()
	--_isTalent = TD_TalentEnabled('Talent Name');
	-- other checking functions

end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Druid_EnableAddon(mode)
	mode = mode or 1;
	TDDps.Description = "TD Druid DPS supports: Balance";
	TDDps.ModuleOnEnable = TDDps_Druid_CheckTalents;
	if mode == 1 then
		TDDps.NextSpell = TDDps_Druid_Balance;
	end;
	if mode == 2 then
		TDDps.NextSpell = TDDps_Druid_Feral;
	end;
	if mode == 3 then
		TDDps.NextSpell = TDDps_Druid_Guardian;
	end;
end

----------------------------------------------
-- Main rotation: Balance
----------------------------------------------
TDDps_Druid_Balance = function()
	local timeShift, currentSpell = TD_EndCast();

	local lunar = UnitPower('player', SPELL_POWER_LUNAR_POWER);

	-- detect which phase we are staring
	if TDButton.FindSpell(_NewMoon) then
		newMoonPhase = _NewMoon;
	elseif TDButton.FindSpell(_HalfMoon) then
		newMoonPhase = _HalfMoon;
	else
		newMoonPhase = _FullMoon;
	end

	local moon = TD_TargetAura(_Moonfire, timeShift + 5);
	local sun = TD_TargetAura(_Sunfire, timeShift + 3);

	local newmoon, newCharges = TD_SpellCharges(_NewMoon, timeShift);
	local ca = TD_SpellAvailable(_CelestialAlignment, timeShift);

	local solarE, solarCharges = TD_Aura(_SolarEmpowerment, timeShift);
	local lunarE, lunarCharges = TD_Aura(_LunarEmpowerment, timeShift);

	TDButton.GlowCooldown(_CelestialAlignment, ca);

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

	if lunar > 80 then
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

----------------------------------------------
-- Main rotation: Feral
----------------------------------------------
TDDps_Druid_Feral = function()
	local timeShift, currentSpell = TD_EndCast();

	return nil;
end

----------------------------------------------
-- Main rotation: Guardian
----------------------------------------------
TDDps_Druid_Guardian = function()
	local timeShift, currentSpell = TD_EndCast();

	return nil;
end