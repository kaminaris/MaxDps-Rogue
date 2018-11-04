--- @type MaxDps
if not MaxDps then
	return ;
end

local MaxDps = MaxDps;
local UnitPower = UnitPower;

local Druid = MaxDps:NewModule('Druid');

-- Spells
local BL = {
	Moonfire                 = 8921,
	Sunfire                  = 93402,
	Starsurge                = 78674,
	LunarEmpowerment         = 164547,
	SolarEmpowerment         = 164545,
	LunarStrike              = 194153,
	SolarWrath               = 190984,
	NewMoon                  = 202767,
	CelestialAlignment       = 194223,
	IncarnationChosenOfElune = 102560,
	HalfMoon                 = 202768,
	FullMoon                 = 202771,
	StellarFlare             = 202347,
	Starfall                 = 191034,
	MasteryStarlight         = 77492,
	StellarEmpowerment       = 197637,
	Heroism                  = 32182,
	Bloodlust                = 2825,
	Berserking               = 26297,
	ForceOfNature            = 205636,
	WarriorOfElune           = 202425,
	AstralCommunion          = 202359,
	BlessingoftheAncients    = 202360,
	BlessingofElune          = 202737,
	FuryofElune              = 202770,
	MoonfireAura             = 164812,
	SunfireAura              = 164815,
	WarriorOfEluneAura       = 202425,
};


-- Feral
local FR = {
	SavageRoar                 = 52610,
	Rake                       = 1822,
	RakeDot                    = 155722,
	Rip                        = 1079,
	Sabertooth                 = 202031,
	FerociousBite              = 22568,
	LunarInspiration           = 155580,
	TigersFury                 = 5217,
	AshamanesFrenzy            = 210722,
	Shred                      = 5221,
	Bloodtalons                = 155672,
	Regrowth                   = 8936,
	PredatorySwiftness         = 69369,
	IncarnationKingOfTheJungle = 102543,
	Prowl                      = 5215,
	Berserk                    = 106951,
	Thrash                     = 106830,
	Swipe                      = 213764,
	MasteryRazorClaws          = 77493,
	PrimalFury                 = 159286,
	JaggedWounds               = 202032,
	OmenofClarity              = 16864,
	Predator                   = 202021,
	ElunesGuidance             = 202060,
	BrutalSlash                = 202028,
	ClearCasting               = 135700,
	FeralFrenzy                = 274837,
	FeralMoonfire              = 155625,
	CatForm                    = 768,
	MassEntanglement           = 102359,
};

-- Guardian
local GR = {
	Mangle               = 33917,
	MangleProc           = 93622,
	ThrashGuard          = 77758,
	Ironfur              = 192081,
	FrenziedRegeneration = 22842,
	MarkOfUrsol          = 192083,
	RageOfTheSleeper     = 200851,
	GalacticGuardian     = 203964,
	GalacticGuardianBuff = 213708,
};

local spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

setmetatable(GR, spellMeta);
setmetatable(BL, spellMeta);
setmetatable(FR, spellMeta);

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

function Druid:Balance()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local lunar = UnitPower('player', Enum.PowerType.LunarPower);

	local solarCharges = buff[BL.SolarEmpowerment].count;
	local lunarCharges = buff[BL.LunarEmpowerment].count;

	if currentSpell == BL.SolarWrath then
		lunar = lunar + 8;
		solarCharges = solarCharges - 1;
	elseif currentSpell == BL.LunarStrike then
		lunar = lunar + 12;
		lunarCharges = lunarCharges - 1;
	end

	if talents[BL.IncarnationChosenOfElune] then
		MaxDps:GlowCooldown(BL.IncarnationChosenOfElune, cooldown[BL.IncarnationChosenOfElune].ready);
	else
		MaxDps:GlowCooldown(BL.CelestialAlignment, cooldown[BL.CelestialAlignment].ready);
	end

	if talents[BL.WarriorOfElune] then
		MaxDps:GlowCooldown(BL.WarriorOfElune, cooldown[BL.WarriorOfElune].ready and not buff[BL.WarriorOfEluneAura].up);
	end

	if talents[BL.ForceOfNature] then
		MaxDps:GlowCooldown(BL.ForceOfNature, cooldown[BL.ForceOfNature].ready);
	end

	if debuff[BL.MoonfireAura].refreshable then
		return BL.Moonfire;
	end

	if debuff[BL.SunfireAura].refreshable then
		return BL.Sunfire;
	end

	if talents[BL.StellarFlare] and debuff[BL.StellarFlare].refreshable and currentSpell ~= BL.StellarFlare
	then
		return BL.StellarFlare;
	end

	if lunar > 70 then
		return BL.Starsurge;
	end

	if solarCharges >= 2 then
		return BL.SolarWrath;
	end

	if lunarCharges >= 2 then
		return BL.LunarStrike;
	end

	if solarCharges == 1 then
		return BL.SolarWrath;
	end

	if lunarCharges == 1 then
		return BL.LunarStrike;
	end

	return BL.SolarWrath;
end

function Druid:Feral()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local energy = UnitPower('player', Enum.PowerType.Energy);
	local combo = UnitPower('player', Enum.PowerType.ComboPoints);

	--Cooldowns
	local berserk = talents[FR.IncarnationKingOfTheJungle] and FR.IncarnationKingOfTheJungle or FR.Berserk;
	MaxDps:GlowCooldown(berserk, cooldown[berserk].ready);

	--Dot Aura
	local ph = MaxDps:TargetPercentHealth();

	-- Rotation
	if talents[FR.Bloodtalons] and buff[FR.PredatorySwiftness].up and combo >= 4 then --and MaxDps:Aura(FR.SavageRoar, timeShift + 5)
		return FR.Regrowth;
	end

	if cooldown[FR.TigersFury].ready and (energy < 30 or buff[berserk].up) then
		return FR.TigersFury;
	end

	if talents[FR.FeralFrenzy] and combo == 0 then
		return FR.FeralFrenzy;
	end

	local ripPandemic = debuff[FR.Rip].remains < 5;

	if (not debuff[FR.Rip].up and combo >= 5) or
		(combo >= 5 and not ripPandemic and ph > 0.25 and not talents[FR.Sabertooth])
	then
		return FR.Rip;
	end

	if not ripPandemic and (talents[FR.Sabertooth] or ph < 0.25) and combo >= 5 then
		return FR.FerociousBite;
	end

	if talents[FR.SavageRoar] and buff[FR.SavageRoar].remains < 5 and combo >= 5 then
		return FR.SavageRoar;
	end

	if combo >= 5 then
		return FR.FerociousBite;
	end

	if debuff[FR.RakeDot].remains < 3 then
		return FR.Rake;
	end

	if talents[FR.LunarInspiration] and debuff[FR.FeralMoonfire].refreshable then
		return FR.FeralMoonfire;
	end

	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and combo < 5 then
		return FR.BrutalSlash;
	end

	return FR.Shred;
end

function Druid:Guardian(timeShift, currentSpell, gcd, talents)
	local rage = UnitPower('player', Enum.PowerType.Rage);
	return nil;
end

function Druid:Restoration(timeShift, currentSpell, gcd, talents)
	return nil;
end