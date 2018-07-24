--- @type MaxDps
if not MaxDps then
	return ;
end

local Druid = MaxDps:NewModule('Druid');

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
local _MoonkinMoonfire = 164812;
local _MoonkinSunfire = 164815;
local _WarriorofEluneAura = 202425;

-- Feral
local _SavageRoar = 52610;
local _Rake = 1822;
local _RakeDot = 155722;
local _Rip = 1079;
local _Sabertooth = 202031;
local _FerociousBite = 22568;
local _LunarInspiration = 155580;
local _TigersFury = 5217;
local _AshamanesFrenzy = 210722;
local _Shred = 5221;
local _Bloodtalons = 155672;
local _Regrowth = 8936;
local _PredatorySwiftness = 69369;
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
local _FeralFrenzy = 274837;
local _FeralMoonfire = 155625;
local _CatForm = 768;
local _MassEntanglement = 102359;

-- Guardian
local _Mangle = 33917;
local _MangleProc = 93622;
local _ThrashGuard = 77758;
local _Ironfur = 192081;
local _FrenziedRegeneration = 22842;
local _MarkOfUrsol = 192083;
local _RageOfTheSleeper = 200851;
local _GalacticGuardian = 203964;
local _GalacticGuardianBuff = 213708;

function Druid:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Druid [Balance, Feral, Guardian, Restoration]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Druid.Balance;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Druid.Feral;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Druid.Guardian;
	elseif MaxDps.Spec == 4 then
		MaxDps.NextSpell = Druid.Restoration;
	end ;

	return true;
end

function Druid:Balance(timeShift, currentSpell, gcd, talents)
	local lunar = UnitPower('player', Enum.PowerType.LunarPower);

	local moon = MaxDps:TargetAura(_MoonkinMoonfire, timeShift + 5);
	local sun = MaxDps:TargetAura(_MoonkinSunfire, timeShift + 4);
	local sf = MaxDps:TargetAura(_StellarFlare, timeShift + 5);

	local solarE, solarCharges = MaxDps:Aura(_SolarEmpowerment, timeShift);
	local lunarE, lunarCharges = MaxDps:Aura(_LunarEmpowerment, timeShift);

	if currentSpell == _SolarWrath then
		lunar = lunar + 8;
		solarCharges = solarCharges - 1;
	elseif currentSpell == _LunarStrike then
		lunar = lunar + 12;
		lunarCharges = lunarCharges - 1;
	end

	if talents[_IncarnationChosenofElune] then
		MaxDps:GlowCooldown(_IncarnationChosenofElune, MaxDps:SpellAvailable(_IncarnationChosenofElune, timeShift));
	else
		MaxDps:GlowCooldown(_CelestialAlignment, MaxDps:SpellAvailable(_CelestialAlignment, timeShift));
	end


	if talents[_WarriorofElune] then
		MaxDps:GlowCooldown(_WarriorofElune, MaxDps:SpellAvailable(_WarriorofElune, timeShift)
			and not MaxDps:Aura(_WarriorofEluneAura));
	end

	if not moon then
		return _Moonfire;
	end

	if not sun then
		return _Sunfire;
	end

	if talents[_StellarFlare] and not sf and currentSpell ~= _StellarFlare then
		return _StellarFlare;
	end

	if lunar > 70 then
		return _Starsurge;
	end

	if solarCharges >= 2 then
		return _SolarWrath;
	end

	if lunarCharges >= 2 then
		return _LunarStrike;
	end

	if solarCharges == 1 then
		return _SolarWrath;
	end

	if lunarCharges == 1 then
		return _LunarStrike;
	end

	return _SolarWrath;
end

local testflag = true;
function Druid:Feral(timeShift, currentSpell, gcd, talents)
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local combo = UnitPower('player', Enum.PowerType.ComboPoints);

	--Cooldowns
	local berserk = talents[_IncarnationKingoftheJungle] and _IncarnationKingoftheJungle or _Berserk;
	MaxDps:GlowCooldown(berserk, MaxDps:SpellAvailable(berserk, timeShift));

	-- Player Aura
	local pred = MaxDps:Aura(_PredatorySwiftness, timeShift);
	local bers = MaxDps:Aura(berserk, timeShift);
	local bt, btCount = MaxDps:Aura(_Bloodtalons, timeShift);

	--Dot Aura
	local rip = MaxDps:TargetAura(_Rip, timeShift);
	local ph = MaxDps:TargetPercentHealth();

	-- Rotation
	if talents[_Bloodtalons] and MaxDps:Aura(_PredatorySwiftness, timeShift) and combo >= 4 then --and MaxDps:Aura(_SavageRoar, timeShift + 5)
		return _Regrowth;
	end

	if MaxDps:SpellAvailable(_TigersFury, timeShift) and (energy < 30 or bers) then
		return _TigersFury;
	end

	if talents[_FeralFrenzy] and combo == 0 then
		return _FeralFrenzy;
	end

	local ripPandemic = MaxDps:TargetAura(_Rip, timeShift + 5);

	if (not MaxDps:TargetAura(_Rip, timeShift) and combo >= 5) or
		(combo >= 5 and not ripPandemic and ph > 0.25 and not talents[_Sabertooth])
	then
		return _Rip;
	end

	if not ripPandemic and (talents[_Sabertooth] or ph < 0.25) and combo >= 5 then
		return _FerociousBite;
	end

	if talents[_SavageRoar] and not MaxDps:Aura(_SavageRoar, timeShift + 5) and combo >= 5 then
		return _SavageRoar;
	end

	if combo >= 5 then
		return _FerociousBite;
	end

	if not MaxDps:TargetAura(_RakeDot, timeShift + 3) then
		return _Rake;
	end

	if talents[_LunarInspiration] and not MaxDps:TargetAura(_FeralMoonfire, timeShift + 4) then
		return _FeralMoonfire;
	end

	if talents[_BrutalSlash] and MaxDps:SpellAvailable(_BrutalSlash, timeShift) and combo < 5 then
		return _BrutalSlash;
	end

	return _Shred;
end

function Druid:Guardian(timeShift, currentSpell, gcd, talents)
	local rage = UnitPower('player', Enum.PowerType.Rage);
	return nil;
end

function Druid:Restoration(timeShift, currentSpell, gcd, talents)
	return nil;
end