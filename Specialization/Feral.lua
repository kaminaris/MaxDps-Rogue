local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local Druid = addonTable.Druid;
local UnitPower = UnitPower;

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