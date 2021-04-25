local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local MaxDps = MaxDps;
local Rogue = addonTable.Rogue;

local OL = {
	Stealth              = 1784,
	MarkedForDeath       = 137619,
	LoadedDice           = 256170,
	SnakeEyes            = 275863,
	GhostlyStrike        = 196937,
	DeeperStratagem      = 193531,

	SkullAndCrossbones   = 199603,
	TrueBearing          = 193359,
	RuthlessPrecision    = 193357,
	GrandMelee           = 193358,
	BuriedTreasure       = 199600,
	Broadside            = 193356,

	BladeFlurry          = 13877,
	Opportunity          = 195627,
	QuickDraw            = 196938,
	PistolShot           = 185763,
	KeepYourWitsAboutYou = 288988,
	Deadshot             = 272940,
	SinisterStrike       = 193315,
	KillingSpree         = 51690,
	BladeRush            = 271877,
	Vanish               = 1856,
	Ambush               = 8676,
	AdrenalineRush       = 13750,
	RollTheBones         = 315508,
	SliceAndDice         = 315496,
	BetweenTheEyes       = 315341,
	Dispatch             = 2098,
	DirtyTricks			 = 108216,
	Gouge				 = 1776,

	-- Covenant Abilities
	Sepsis               = 328305,
	SepsisAura           = 347037,

	Flagellation		 = 323654,

	SerratedBoneSpear	 = 328547,
	SerratedBoneSpearAura = 324073,

	EchoingReprimand = 323547,

	StealthAura          = 1784,
	VanishAura           = 11327,
	InstantPoison        = 315584
};

local RTB = {
	Broadside			=	193356,
	BuriedTreasure		=	199600,
	GrandMelee			=	193358,
	RuthlessPrecision	=	193357,
	SkullAndCrossbones	=	199603,
	TrueBearing			=	193359
};

local A = {
	Deadshot        = 272935,
	AceUpYourSleeve = 278676,
	SnakeEyes       = 275846,

};

setmetatable(OL, Rogue.spellMeta);
setmetatable(A, Rogue.spellMeta);

local Rtb = { 'Broadside', 'GrandMelee', 'RuthlessPrecision', 'TrueBearing', 'SkullAndCrossbones', 'BuriedTreasure' };

function Rogue:Outlaw()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local targets = MaxDps:SmartAoe();
	local covenantId = fd.covenant.covenantId;
	local comboPoints = UnitPower('player', 4);
	local comboPointsMax = UnitPowerMax('player', 4);
	local energy = UnitPower('player', 3);
	local energyMax = UnitPowerMax('player', 3);
	local inCombat = UnitAffectingCombat("player");

	if not inCombat and not buff[OL.StealthAura].up then
		return OL.Stealth;
	end

	if covenantId == NightFae then
		MaxDps:GlowCooldown(FR.AncientAftershock, cooldown[FR.AncientAftershock].ready);
	elseif covenantId == Necrolord then
		MaxDps:GlowCooldown(FR.ConquerorsBanner, cooldown[FR.ConquerorsBanner].ready);
	elseif covenantId == Kyrian then
		MaxDps:GlowCooldown(FR.SpearOfBastion, cooldown[FR.SpearOfBastion].ready);
	end

	if cooldown[OL.RollTheBones].ready and ((buff[OL.Broadside].remains <= 1.5 or buff[OL.TrueBearing].remains <= 1.5) or
	not ((buff[RTB.Broadside].up and (buff[RTB.BuriedTreasure].up or buff[RTB.GrandMelee].up or buff[RTB.RuthlessPrecision].up or buff[RTB.SkullAndCrossbones].up or buff[RTB.TrueBearing].up)) or
	(buff[RTB.TrueBearing].up and (buff[RTB.BuriedTreasure].up or buff[RTB.GrandMelee].up or buff[RTB.RuthlessPrecision].up or buff[RTB.SkullAndCrossbones].up or buff[RTB.Broadside].up))))
	then
		return OL.RollTheBones;
	end

	if cooldown[OL.MarkedForDeath].ready and talents[OL.MarkedForDeath] and comboPoints <= 1 then
		return OL.MarkedForDeath;
	end

	--actions+=/run_action_list,name=stealth,if=stealthed.all
	if buff[OL.StealthAura].up then
		return Rogue:OutlawStealth();
	end

	--actions+=/call_action_list,name=cds
	local result = Rogue:OutlawCooldown();
	if result then
		return result;
	end
	--actions+=/run_action_list,name=finish,if=variable.finish_condition
	if comboPoints == comboPointsMax or (buff[OL.Broadside].up and comboPoints == comboPointsMax - 1) then
		return Rogue:OutlawFinisher();
	end
	--actions+=/call_action_list,name=build
	return Rogue:OutlawBuilder();
end

function Rogue:OutlawStealth()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local comboPoints = UnitPower('player', 4);
	local comboPointsMax = UnitPowerMax('player', 4);

	if cooldown[OL.SliceAndDice].ready and buff[OL.SliceAndDice].remains < 6 and comboPoints == comboPointsMax then
		return OL.SliceAndDice;
	end

	if comboPoints == comboPointsMax or (buff[OL.Broadside].up and comboPoints == comboPointsMax - 1) then
		return OL.Dispatch;
	end

	return OL.Ambush;
end

function Rogue:OutlawCooldown()
	local fd = MaxDps.FrameData;
	local timeToDie = fd.timeToDie;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local comboPoints = UnitPower('player', 4);
	local comboPointsMax = UnitPowerMax('player', 4);
	local targets = MaxDps:SmartAoe();
	local energy = UnitPower('player', 3);
	local energyMax = UnitPowerMax('player', 3);
	local energyRegen = GetPowerRegen();
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	local RTB_Buffs = (buff[RTB.Broadside].up and (buff[RTB.BuriedTreasure].up or buff[RTB.GrandMelee].up or buff[RTB.RuthlessPrecision].up or buff[RTB.SkullAndCrossbones].up or buff[RTB.TrueBearing].up))

	if cooldown[OL.BladeFlurry].ready and targets >= 2 and not buff[OL.BladeFlurry].up then
		return OL.BladeFlurry;
	end

	if cooldown[OL.AdrenalineRush].ready and MaxDps.db.global.enableCooldowns and not buff[OL.AdrenalineRush].up then
		return OL.AdrenalineRush;
	end

	if talents[OL.BladeRush] and cooldown[OL.BladeRush].ready and (targets > 2 or energyTimeToMax > 2 or energy <= 30) then
		return OL.BladeRush;
	end
end

function Rogue:OutlawFinisher()
	local fd = MaxDps.FrameData;
	local targets = MaxDps:SmartAoe();
	local timeToDie = fd.timeToDie;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local covenantId = fd.covenant.covenantId;

	if covenantId == Venthyr and cooldown[OL.Flagellation].ready then
		return OL.Flagellation;
	end

	if cooldown[OL.BetweenTheEyes].ready and timeToDie > 3 then
		return OL.BetweenTheEyes;
	end

	if cooldown[OL.SliceAndDice].ready and buff[OL.SliceAndDice].remains < 6 and (buff[OL.SliceAndDice].remains < timeToDie or targets > 1) then
		return OL.SliceAndDice;
	end

	return OL.Dispatch;
end

function Rogue:OutlawBuilder()
	local fd = MaxDps.FrameData;
	local timeToDie = fd.timeToDie;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local covenantId = fd.covenant.covenantId;
	local energy = UnitPower('player', 3);
	local energyMax = UnitPowerMax('player', 3);
	local energyRegen = GetPowerRegen();
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	if talents[OL.GhostlyStrike] and cooldown[OL.GhostlyStrike].ready and energy >= 30 then
		return OL.GhostlyStrike;
	end

	if covenantId == Necrolord and (cooldown[OL.SerratedBoneSpear].charges >= 1 and (buff[OL.SliceAndDice].up and not debuff[OL.SerratedBoneSpearAura].up) or cooldown[OL.SerratedBoneSpear].charges > 2.75 )then
		return OL.SerratedBoneSpear;
	end

	if buff[OL.Opportunity].up and energy <= (energyMax - (10 + energyRegen)) then
		return OL.PistolShot;
	end

	if covenantId == NightFae and cooldown[OL.Sepsis].ready then
		return OL.Sepsis;
	end

	if covenantId == Kyrian and cooldown[OL.EchoingReprimand].ready then
		return OL.EchoingReprimand;
	end

	if energy >= 45 then
		return OL.SinisterStrike;
	end

	if cooldown[OL.Gouge].ready and talents[OL.DirtyTricks] then
		return OL.Gouge;
	end
end
