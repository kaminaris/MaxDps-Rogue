--- @type MaxDps
if not MaxDps then
	return ;
end

local MaxDps = MaxDps;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetPowerRegen = GetPowerRegen;
local EnumPowerType = Enum.PowerType;

local Rogue = MaxDps:NewModule('Rogue');

-- Outlaw
local SO = {
	Vanish             = 1856,
	VanishAura         = 11327,
	Ambush             = 8676,
	CheapShot          = 1833,
	PreyOnTheWeak      = 131511,
	KillingSpree       = 51690,
	BladeRush          = 271877,
	BladeFlurry        = 13877,
	RollTheBones       = 193316,
	GhostlyStrike      = 196937,
	AdrenalineRush     = 13750,
	MarkedForDeath     = 137619,
	BetweenTheEyes     = 199804,
	RuthlessPrecision  = 193357,
	AceUpYourSleeve    = 278676,
	Deadshot           = 272935,
	Dispatch           = 2098,
	PistolShot         = 185763,
	Opportunity        = 195627,
	SinisterStrike     = 193315,
	SnakeEyes          = 275846,
	MasteryMainGauche  = 76806,
	SliceAndDice       = 5171,
	DeeperStratagem    = 193531,
	TrueBearing        = 193359,
	SkullAndCrossbones = 199603,
	GrandMelee         = 193358,
	Broadside          = 193356,
	BuriedTreasure     = 199600,
	LoadedDice         = 256170,
	Vigor              = 14983,
	CombatPotency      = 61329,
	RestlessBlades     = 79096,
	Ruthlessness       = 14161,
	GrapplingHook      = 195457,
	Elusiveness        = 79008,
	CloakOfShadows     = 31224,
	Riposte            = 199754,
	QuickDraw          = 196938,

	-- Auras
	StealthAura        = 1784
};

-- Assassination
local AS = {
	Stealth          = 1784,
	StealthAlt       = 115191,
	MarkedForDeath   = 137619,
	Vendetta         = 79140,
	Subterfuge       = 108208,
	Garrote          = 703,
	Rupture          = 1943,
	Nightstalker     = 14062,
	Exsanguinate     = 200806,
	DeeperStratagem  = 193531,
	Vanish           = 1856,
	VanishAura       = 11327,
	MasterAssassin   = 255989,
	ToxicBlade       = 245388,
	PoisonedKnife    = 185565,
	FanOfKnives      = 51723,
	HiddenBlades     = 270061,
	Blindside        = 111240,
	BlindsideAura    = 121153,
	VenomRush        = 152152,
	CrimsonTempest   = 121411,
	DeadlyPoison     = 2823,
	DeadlyPoisonAura = 2818,
	Mutilate         = 1329,
	Envenom          = 32645,

	SharpenedBlades  = 272916,
	InternalBleeding = 154904,

	-- Auras
	StealthAura        = 1784
};

local SB = {
	Stealth         = 1784,
	MarkedForDeath  = 137619,
	ShadowBlades    = 121471,
	Nightblade      = 195452,
	Vigor           = 14983,
	MasterOfShadows = 196976,
	ShadowFocus     = 108209,
	Alacrity        = 193539,
	DarkShadow      = 245687,
	SecretTechnique = 280719,
	ShurikenTornado = 277925,
	ShurikenToss    = 114014,
	Nightstalker    = 14062,
	SymbolsOfDeath  = 212283,
	ShurikenStorm   = 197835,
	Gloomblade      = 200758,
	Backstab        = 53,
	ShadowDance     = 185313,
	ShadowDanceAura = 185422,
	Subterfuge      = 108208,
	Eviscerate      = 196819,
	Vanish          = 1856,
	VanishAura      = 11327,
	FindWeakness    = 91023,
	Shadowstrike    = 185438,
	DeeperStratagem = 193531,
};

local A = {
	DoubleDose = 273007,
	ShroudedSuffocation = 278666,
	NightsVengeance = 273418,
	SharpenedBlades = 272911,
	BladeInTheShadows = 275896
}

local spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

setmetatable(SO, spellMeta);
setmetatable(AS, spellMeta);
setmetatable(SB, spellMeta);
setmetatable(A, spellMeta);

function Rogue:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Rogue [Outlaw]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Rogue.Assassination;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Rogue.Outlaw;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Rogue.Subtlety;
	end

	return true;
end

local auraMetaTable = {
	__index = function()
		return {
			up          = false,
			count       = 0,
			remains     = 0,
			refreshable = true,
		};
	end
};

function Rogue:PoisonedBleeds(timeShift)
	local poisoned = 0;
	for i, frame in pairs(C_NamePlate.GetNamePlates()) do
		local unit = frame.UnitFrame.unit;

		if frame:IsVisible() then
			local debuff = setmetatable({}, auraMetaTable);

			MaxDps:CollectAura(unit, timeShift, debuff, 'PLAYER|HARMFUL');

			if debuff[AS.DeadlyPoisonAura].up then
				poisoned = poisoned +
					debuff[AS.Rupture].count +
					debuff[AS.Garrote].count +
					debuff[AS.InternalBleeding].count;
			end

		end
	end

	return poisoned;
end

function Rogue:Assassination()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, timeShift =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.timeShift;

	local energy = UnitPower('player', EnumPowerType.Energy);
	local energyMax = UnitPowerMax('player', EnumPowerType.Energy);
	local energyRegen = GetPowerRegen();
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	local combo = UnitPower('player', EnumPowerType.ComboPoints);
	local comboMax = UnitPowerMax('player', EnumPowerType.ComboPoints);
	local comboDeficit = comboMax - combo;
	local spellHaste = MaxDps:AttackHaste();
	local targets = MaxDps:SmartAoe();
	local cpMaxSpend = 5 + (talents[AS.DeeperStratagem] and 1 or 0);

	local stealthed = buff[AS.StealthAura].up or buff[AS.StealthAlt].up or buff[AS.VanishAura].up;
	local poisonedBleeds = Rogue:PoisonedBleeds(timeShift);
	local energyRegenCombined = energyRegen + poisonedBleeds * 7 % (2 * spellHaste);

	fd.energy, fd.energyMax, fd.energyRegen, fd.energyTimeToMax, fd.combo, fd.comboMax, fd.comboDeficit, fd.stealthed, fd.targets, fd.energyRegenCombined, fd.cpMaxSpend =
	energy, energyMax, energyRegen, energyTimeToMax, combo, comboMax, comboDeficit, stealthed, targets, energyRegenCombined, cpMaxSpend;
	local effectiveEnergy = energy + energyRegen * timeShift;

	-- vendetta,if=!stealthed.rogue&dot.rupture.ticking&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1)&(!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled);
	MaxDps:GlowCooldown(
		AS.Vendetta,
		cooldown[AS.Vendetta].ready and not stealthed and
		debuff[AS.Rupture].up and energy < 80
	);

	MaxDps:GlowCooldown(AS.Vanish, cooldown[AS.Vanish].ready and not stealthed);

	if not buff[AS.DeadlyPoison].up then
		return AS.DeadlyPoison;
	end

	if not InCombatLockdown() and buff[AS.DeadlyPoison].remains < 5 * 60 then
		return AS.DeadlyPoison;
	end

	-- stealth;
	if not InCombatLockdown() and not stealthed then
		return MaxDps:FindSpell(AS.Stealth) and AS.Stealth or AS.StealthAlt;
	end

	if stealthed then
		return Rogue:AssassinationStealthed();
	end

	-- marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend);
	if talents[AS.MarkedForDeath] and cooldown[AS.MarkedForDeath].ready and (comboDeficit >= cpMaxSpend) then
		return AS.MarkedForDeath;
	end

	-- rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)));
	if talents[AS.Exsanguinate] and
		(
			(combo >= cpMaxSpend and cooldown[AS.Exsanguinate].remains < 1) or
			(not debuff[AS.Rupture].up and (combo >= 2))
		)
	then
		return AS.Rupture;
	end

	--actions.dot+=/garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
	if cooldown[AS.Garrote].ready and
		(not talents[AS.Subterfuge] or not (cooldown[AS.Vanish].ready and cooldown[AS.Vendetta].remains <= 4)) and
		comboDeficit >= 1 and
		debuff[AS.Garrote].refreshable
	then
		return AS.Garrote;
	end

	-- crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4;
	if talents[AS.CrimsonTempest] and effectiveEnergy >= 35 and
		targets >= 2 and
		debuff[AS.CrimsonTempest].remains < 2 + (targets >= 5 and 1 or 0) and
		combo >= 4
	then
		return AS.CrimsonTempest;
	end

	--actions.dot+=/rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
	if combo >= 4 and debuff[AS.Rupture].refreshable then
		return AS.Rupture;
	end

	-- exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable;
	if talents[AS.Exsanguinate] and
		cooldown[AS.Exsanguinate].ready and
		energy >= 35 and
		debuff[AS.Rupture].remains > 4 + 4 * cpMaxSpend and
		not debuff[AS.Garrote].refreshable
	then
		return AS.Exsanguinate;
	end

	-- toxic_blade,if=dot.rupture.ticking;
	if talents[AS.ToxicBlade] and cooldown[AS.ToxicBlade].ready and debuff[AS.Rupture].up then
		return AS.ToxicBlade;
	end

	return Rogue:AssassinationDirect();
end

function Rogue:AssassinationCds()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell = fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	local energy, energyMax, energyTimeToMax, combo, comboMax, comboDeficit, stealthed, targets, cpMaxSpend =
	fd.energy, fd.energyMax, fd.energyTimeToMax, fd.combo, fd.comboMax, fd.comboDeficit, fd.stealthed, fd.targets, fd.cpMaxSpend;

	if cooldown[AS.Vanish].ready then
		-- vanish,if=talent.subterfuge.enabled&!dot.garrote.ticking&variable.single_target;
		if talents[AS.Subterfuge] and not debuff[AS.Garrote].up and targets < 2 then
			return AS.Vanish;
		end

		-- vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1);
		if talents[AS.Exsanguinate] and
			(talents[AS.Nightstalker] or talents[AS.Subterfuge] and targets < 2) and
			combo >= cpMaxSpend and
			cooldown[AS.Exsanguinate].remains < 1 and
			(not talents[AS.Subterfuge] or azerite[A.ShroudedSuffocation] == 0)
		then
			return AS.Vanish;
		end

		-- vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up;
		if talents[AS.Nightstalker] and
			not talents[AS.Exsanguinate] and
			combo >= cpMaxSpend and
			debuff[AS.Vendetta].up
		then
			return AS.Vanish;
		end

		-- vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|!variable.single_target)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4);
		if talents[AS.Subterfuge] and
			(not talents[AS.Exsanguinate] or not targets < 2) and
			not stealthed and
			cooldown[AS.Garrote].up and
			debuff[AS.Garrote].refreshable and
			(targets <= 3 and comboDeficit >= 1 + targets or targets >= 4 and comboDeficit >= 4)
		then
			return AS.Vanish;
		end

		-- vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable;
		if talents[AS.MasterAssassin] and
			not stealthed and
			buff[AS.MasterAssassin].remains <= 0 and
			not debuff[AS.Rupture].refreshable
		then
			return AS.Vanish;
		end
	end


end

function Rogue:AssassinationDirect()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	local energy, energyMax, energyRegen, energyTimeToMax, combo, comboMax, comboDeficit, stealthed, targets, energyRegenCombined, timeShift =
		fd.energy, fd.energyMax, fd.energyRegen, fd.energyTimeToMax, fd.combo, fd.comboMax, fd.comboDeficit, fd.stealthed, fd.targets, fd.energyRegenCombined, fd.timeShift;
	
	local energyDeficit = energyMax - energy;
	local effectiveEnergy = energy + energyRegen * timeShift;

	-- envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2);
	if combo >= 4 + (talents[AS.DeeperStratagem] and 1 or 0) and
		(debuff[AS.Vendetta].up or debuff[AS.ToxicBlade].up or energyDeficit <= 25 + energyRegenCombined or targets >= 2) and
		(not talents[AS.Exsanguinate] or cooldown[AS.Exsanguinate].remains > 2)
	then
		return AS.Envenom;
	end

	-- variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target;
	local useFiller = comboDeficit > 1 or energyDeficit <= 25 + energyRegenCombined or targets >= 2;

	-- poisoned_knife,if=variable.use_filler&buff.sharpened_blades.stack>=29;
	if effectiveEnergy >= 40 and useFiller and buff[AS.SharpenedBlades].count >= 29 then
		return AS.PoisonedKnife;
	end

	-- fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue);
	if useFiller and (
		buff[AS.HiddenBlades].count >= 19 or
		targets >= 4 + (azerite[A.DoubleDose] > 2 and 1 or 0) + (stealthed and 1 or 0)
	) then
		return AS.FanOfKnives;
	end

	-- fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3;
	if useFiller and targets >= 3 then
		return AS.FanOfKnives;
	end

	-- blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled);
	local thp = MaxDps:TargetPercentHealth();
	if talents[AS.Blindside] and
		useFiller and
		(buff[AS.BlindsideAura].up or (not talents[AS.VenomRush] and thp <= 0.3))
	then
		return AS.Blindside;
	end

	-- mutilate,if=variable.use_filler;
	if useFiller then
		return AS.Mutilate;
	end
end

function Rogue:AssassinationStealthed()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite;

	local energy, energyRegen, combo, targets, timeShift, cpMaxSpend, spellHistory =
	fd.energy, fd.energyRegen, fd.combo, fd.targets, fd.timeShift, fd.cpMaxSpend, fd.spellHistory;

	local effectiveEnergy = energy + energyRegen * timeShift;

	-- rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6;
	if effectiveEnergy >= 25 and combo >= 4 and (
		talents[AS.Nightstalker] or talents[AS.Subterfuge] and
		(talents[AS.Exsanguinate] and cooldown[AS.Exsanguinate].remains <= 2 or not debuff[AS.Rupture].up) and
		targets < 2
	) then
		return AS.Rupture;
	end

	-- rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking;
	if effectiveEnergy >= 25 and combo >= 1 and
		talents[AS.Subterfuge] and
		azerite[A.ShroudedSuffocation] > 0 and
		not debuff[AS.Rupture].up
	then
		return AS.Rupture;
	end

	-- garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend;
	if cooldown[AS.Garrote].ready and talents[AS.Subterfuge] and
		talents[AS.Exsanguinate] and
		cooldown[AS.Exsanguinate].remains < 1 and
		spellHistory[1] == AS.Rupture and
		debuff[AS.Rupture].remains > 5 + 4 * cpMaxSpend
	then
		return AS.Garrote;
	end

	if combo >= 1 and not debuff[AS.Rupture].up then
		return AS.Rupture;
	end

	if cooldown[AS.Garrote].ready then
		return AS.Garrote;
	end
end

function Rogue:Outlaw(timeShift, currentSpell, gcd, talents, azerite)

	local energy = UnitPower('player', EnumPowerType.Energy);
	local energyMax = UnitPowerMax('player', EnumPowerType.Energy);
	local energyTimeToMax = (energyMax - energy) / GetPowerRegen();

	local combo = UnitPower('player', EnumPowerType.ComboPoints);
	local comboMax = UnitPowerMax('player', EnumPowerType.ComboPoints);
	local comboDeficit = comboMax - combo;

	local stealthed = MaxDps:Aura(SO.StealthAura, timeShift) or MaxDps:Aura(SO.VanishAura, timeShift);

	local buffBladeFlurryUp = MaxDps:Aura(SO.BladeFlurry, timeShift);
	local buffOpportunityUp = MaxDps:Aura(SO.Opportunity, timeShift);
	local buffAdrenalineRushUp = MaxDps:Aura(SO.AdrenalineRush, timeShift);
	local _, _, buffSliceAndDiceRemains = MaxDps:Aura(SO.SliceAndDice, timeShift);

	local cooldownBetweenTheEyesReady, cooldownBetweenTheEyesRemains = MaxDps:SpellAvailable(SO.BetweenTheEyes, timeShift);
	local cooldownGhostlyStrikeReady, cooldownGhostlyStrikeRemains = MaxDps:SpellAvailable(SO.GhostlyStrike, timeShift);
	local cooldownMarkedForDeathReady, cooldownMarkedForDeathRemains = MaxDps:SpellAvailable(SO.MarkedForDeath, timeShift);

	local buffLoadedDiceUp = MaxDps:Aura(SO.LoadedDice, timeShift);
	local _, buffSnakeEyesStack = MaxDps:Aura(SO.SnakeEyes, timeShift);

	local Rtb = {
		Up      = {
			GrandMelee         = false,
			RuthlessPrecision  = false,
			Broadside          = false,
			BuriedTreasure     = false,
			TrueBearing        = false,
			SkullAndCrossbones = false,
		},
		Remains = {
			GrandMelee         = 0,
			RuthlessPrecision  = 0,
			Broadside          = 0,
			BuriedTreasure     = 0,
			TrueBearing        = 0,
			SkullAndCrossbones = 0,
		},
	};
	local BuffRollTheBonesUp, BuffRollTheBonesRemains = false, 0;
	local RtbBuffs = 0;
	local RtbReroll = false;

	if not talents[SO.SliceAndDice] then
		Rtb.Up.GrandMelee, _, Rtb.Remains.GrandMelee = MaxDps:Aura(SO.GrandMelee, timeShift);
		Rtb.Up.RuthlessPrecision, _, Rtb.Remains.RuthlessPrecision = MaxDps:Aura(SO.RuthlessPrecision, timeShift);
		Rtb.Up.Broadside, _, Rtb.Remains.Broadside = MaxDps:Aura(SO.Broadside, timeShift);
		Rtb.Up.BuriedTreasure, _, Rtb.Remains.BuriedTreasure = MaxDps:Aura(SO.BuriedTreasure, timeShift);
		Rtb.Up.TrueBearing, _, Rtb.Remains.TrueBearing = MaxDps:Aura(SO.TrueBearing, timeShift);
		Rtb.Up.SkullAndCrossbones, _, Rtb.Remains.SkullAndCrossbones = MaxDps:Aura(SO.SkullAndCrossbones, timeShift);

		for k, v in pairs(Rtb.Remains) do
			if v > 0 then
				RtbBuffs = RtbBuffs + 1;
				BuffRollTheBonesUp = true;
				BuffRollTheBonesRemains = v;
			end
		end

		RtbReroll = RtbBuffs < 2 and
			(buffLoadedDiceUp or not Rtb.Up.GrandMelee and not Rtb.Up.RuthlessPrecision);

		if azerite[SO.Deadshot] > 0 or azerite[SO.AceUpYourSleeve] > 0 then
			RtbReroll = RtbBuffs < 2 and
				(buffLoadedDiceUp or Rtb.Remains.RuthlessPrecision <= cooldownBetweenTheEyesRemains);
		end

		if azerite[SO.SnakeEyes] > 0 then
			RtbReroll = RtbBuffs < 2 or (azerite[SO.SnakeEyes] == 3 and RtbBuffs < 5);
		end

		if azerite[SO.SnakeEyes] >= 2 and buffSnakeEyesStack >= 2 - (Rtb.Up.Broadside and 1 or 0) then
			RtbReroll = false;
		end

	end

	local varAmbushCondition = comboDeficit >= 2 + 2 *
		((talents[SO.GhostlyStrike] and cooldownGhostlyStrikeRemains < 1) and 1 or 0) +
		((Rtb.Up.Broadside and energy > 60 and not Rtb.Up.SkullAndCrossbones) and 1 or 0);
	local cpMaxSpend = 5 + (talents[SO.DeeperStratagem] and 1 or 0);

	-- !buff.adrenaline_rush.up&energy.time_to_max>1
	--if not buffAdrenalineRushUp and energyTimeToMax > 1 then
	--	return _AdrenalineRush;
	--end

	-- !stealthed.all&variable.ambush_condition
	--if not stealthed and varAmbushCondition then
	--	return _Vanish;
	--end

	MaxDps:GlowCooldown(
		SO.AdrenalineRush,
		MaxDps:SpellAvailable(SO.AdrenalineRush, timeShift) and not buffAdrenalineRushUp and energyTimeToMax > 1
	);
	MaxDps:GlowCooldown(
		SO.Vanish,
		MaxDps:SpellAvailable(SO.Vanish, timeShift) and not stealthed and varAmbushCondition
	);
	if talents[SO.KillingSpree] then
		MaxDps:GlowCooldown(
			SO.KillingSpree,
			MaxDps:SpellAvailable(SO.KillingSpree, timeShift) and (energyTimeToMax > 5 or energy < 15)
		);
	end

	local targets = MaxDps:TargetsInRange(SO.SinisterStrike);

	-- stealthed.all
	if stealthed then
		if energy >= 50 then
			return SO.Ambush;
		end
	end

	-- raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
	if talents[SO.MarkedForDeath] and MaxDps:SpellAvailable(SO.MarkedForDeath) and not stealthed and
		comboDeficit >= cpMaxSpend - 1
	then
		return SO.MarkedForDeath;
	end

	-- spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
	if MaxDps:SpellAvailable(SO.BladeFlurry, timeShift) and targets >= 2 and not buffBladeFlurryUp then
		return SO.BladeFlurry;
	end

	-- variable.blade_flurry_sync&comboDeficit>=1+buff.broadside.up
	if talents[SO.GhostlyStrike] and MaxDps:SpellAvailable(SO.GhostlyStrike, timeShift) and energy >= 25 and
		comboDeficit >= 1 + (Rtb.Up.Broadside and 1 or 0)
	then
		return SO.GhostlyStrike;
	end

	-- variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
	--if talents[SO.KillingSpree] and (energyTimeToMax > 5 or energy < 15) then
	--	return SO.KillingSpree;
	--end

	-- nope, on cooldown
	-- variable.blade_flurry_sync&energy.time_to_max>1
	if talents[SO.BladeRush] and MaxDps:SpellAvailable(SO.BladeRush, timeShift) and energyTimeToMax > 1
	then
		return SO.BladeRush;
	end


	-- combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
	if combo >= cpMaxSpend -
		((Rtb.Up.Broadside and 1 or 0) + (buffOpportunityUp and 1 or 0)) *
			((talents[SO.QuickDraw] and (not talents[SO.MarkedForDeath] or cooldownMarkedForDeathRemains > 1)) and 1 or 0)
	then

		-- buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
		if cooldownBetweenTheEyesReady and
			(Rtb.Up.RuthlessPrecision or (azerite[SO.Deadshot] > 0 or azerite[SO.AceUpYourSleeve] > 0) and BuffRollTheBonesUp)
		then
			return SO.BetweenTheEyes;
		end

		-- buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
		if talents[SO.SliceAndDice] and buffSliceAndDiceRemains < (1 + combo) * 1.8 then
			return SO.SliceAndDice;
		end

		-- (buff.roll_the_bones.remains<=3|variable.rtb_reroll)&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)
		if not talents[SO.SliceAndDice] and (BuffRollTheBonesRemains <= 3 or RtbReroll) then
			return SO.RollTheBones;
		end

		-- azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
		if cooldownBetweenTheEyesReady and (azerite[SO.AceUpYourSleeve] > 0 or azerite[SO.Deadshot] > 0) then
			return SO.BetweenTheEyes;
		end

		--if energy >= 30 and combo >= 1 then
		return SO.Dispatch;
		--end
	end

	--
	-- comboDeficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
	if buffOpportunityUp and
		comboDeficit >= 1 + (Rtb.Up.Broadside and 1 or 0) + (talents[SO.QuickDraw] and 1 or 0)
	then
		return SO.PistolShot;
	end

	--if energy >= 30 then
	return SO.SinisterStrike;
	--end

	--return nil;
end

function Rogue:Subtlety()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, gcd =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.gcd;

	local energy = UnitPower('player', EnumPowerType.Energy);
	local energyMax = UnitPowerMax('player', EnumPowerType.Energy);
	local energyDeficit = energyMax - energy;
	local energyRegen = GetPowerRegen();
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	local combo = UnitPower('player', EnumPowerType.ComboPoints);
	local comboMax = UnitPowerMax('player', EnumPowerType.ComboPoints);
	local comboDeficit = comboMax - combo;
	local targets = MaxDps:SmartAoe();
	local cpMaxSpend = 5 + (talents[SB.DeeperStratagem] and 1 or 0);
	local priorityRotation = false;

	local stealthed = buff[SB.Stealth].up or buff[SB.ShadowDanceAura].up or buff[SB.VanishAura].up;

	fd.energy, fd.targets, fd.combo, fd.comboDeficit, fd.cpMaxSpend, fd.stealthed =
	energy, targets, combo, comboDeficit, cpMaxSpend, stealthed;

	MaxDps:GlowCooldown(SB.ShadowBlades, cooldown[SB.ShadowBlades].ready);

	-- stealth;
	if not InCombatLockdown() and not stealthed then
		return AS.Stealth;
	end

	local cd = Rogue:SubtletyCds();
	if cd then return cd; end

	if stealthed then
		return Rogue:SubtletyStealthed();
	end

	-- nightblade,if=target.time_to_die>6&remains<gcd.max&combo_points>=4-(time<10)*2;
	if debuff[SB.Nightblade].remains < gcd and combo >= 4 then
		return SB.Nightblade;
	end
	-- variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2;
	local usePriorityRotation = priorityRotation and targets >= 2;

	local r;
	if usePriorityRotation then
		r = Rogue:SubtletyStealthCds();
		if r then return r; end
	end

	-- variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3);
	local stealthThreshold = 25 + (talents[SB.Vigor] and 35 or 0) +
		(talents[SB.MasterOfShadows] and 25 or 0) +
		(talents[SB.ShadowFocus] and 20 or 0) +
		(talents[SB.Alacrity] and 10 or 0) +
		(targets >= 3 and 15 or 0);

	if energyDeficit <= stealthThreshold and comboDeficit >= 4 then
		r = Rogue:SubtletyStealthCds();
		if r then return r; end
	end

	if energyDeficit <= stealthThreshold and talents[SB.DarkShadow] and talents[SB.SecretTechnique] and cooldown[SB.SecretTechnique].ready then
		r = Rogue:SubtletyStealthCds();
		if r then return r; end
	end

	if energyDeficit <= stealthThreshold and talents[SB.DarkShadow] and targets >= 2 and (
		not talents[SB.ShurikenTornado] or not cooldown[SB.ShurikenTornado].ready
	) then
		r = Rogue:SubtletyStealthCds();
		if r then return r; end
	end

	if comboDeficit <= 1 and combo >= 3 then
		return Rogue:SubtletyFinish();
	end

	if targets == 4 and combo >= 4 then
		return Rogue:SubtletyFinish();
	end

	if energyDeficit <= stealthThreshold then
		return Rogue:SubtletyBuild();
	end
end

function Rogue:SubtletyBuild()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, energy, targets =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.energy, fd.targets;

	-- shuriken_toss,if=!talent.nightstalker.enabled&(!talent.dark_shadow.enabled|cooldown.symbols_of_death.remains>10)&buff.sharpened_blades.stack>=29&spell_targets.shuriken_storm<=(3*azerite.sharpened_blades.rank);
	if energy >= 40 and (
		not talents[SB.Nightstalker] and
		(not talents[SB.DarkShadow] or cooldown[SB.SymbolsOfDeath].remains > 10) and
		buff[A.SharpenedBlades].count >= 29 and
		targets <= (3 * azerite[A.SharpenedBlades])
	) then
		return SB.ShurikenToss;
	end

	-- shuriken_storm,if=spell_targets>=2;
	if energy >= 35 and (targets >= 2) then
		return SB.ShurikenStorm;
	end

	-- gloomblade;
	if talents[SB.Gloomblade] and energy >= 35 then
		return SB.Gloomblade;
	end

	-- backstab;
	return SB.Backstab;
end

function Rogue:SubtletyCds()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, stealthed, comboDeficit, cpMaxSpend, energy =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.stealthed, fd.comboDeficit, fd.cpMaxSpend, fd.energy;

	-- shadow_dance,use_off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5;
	if cooldown[SB.ShadowDance].ready and (not buff[SB.ShadowDanceAura].up and buff[SB.ShurikenTornado].up and buff[SB.ShurikenTornado].remains <= 3.5) then
		return SB.ShadowDance;
	end

	-- symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5;
	if cooldown[SB.SymbolsOfDeath].ready and
		buff[SB.ShurikenTornado].up and
		buff[SB.ShurikenTornado].remains <= 3.5
	then
		return SB.SymbolsOfDeath;
	end

	-- symbols_of_death,if=dot.nightblade.ticking&(!talent.shuriken_tornado.enabled|talent.shadow_focus.enabled|spell_targets.shuriken_storm<3|!cooldown.shuriken_tornado.up);
	if cooldown[SB.SymbolsOfDeath].ready and debuff[SB.Nightblade].up and (
		not talents[SB.ShurikenTornado] or talents[SB.ShadowFocus] or targets < 3 or not cooldown[SB.ShurikenTornado].ready
	) then
		return SB.SymbolsOfDeath;
	end

	-- marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.all&combo_points.deficit>=cp_max_spend);
	if talents[SB.MarkedForDeath] and cooldown[SB.MarkedForDeath].ready and (
		(not stealthed and comboDeficit >= cpMaxSpend)
	) then
		return SB.MarkedForDeath;
	end

	-- shadow_blades,if=combo_points.deficit>=2+stealthed.all;

	-- shuriken_tornado,if=spell_targets>=3&!talent.shadow_focus.enabled&dot.nightblade.ticking&!stealthed.all&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1;
	if talents[SB.ShurikenTornado] and cooldown[SB.ShurikenTornado].ready and energy >= 60 and (
		targets >= 3 and
		not talents[SB.ShadowFocus] and
		debuff[SB.Nightblade].up and
		not stealthed and
		cooldown[SB.SymbolsOfDeath].ready and
		cooldown[SB.ShadowDance].charges >= 1
	) then
		return SB.ShurikenTornado;
	end

	-- shuriken_tornado,if=spell_targets>=3&talent.shadow_focus.enabled&dot.nightblade.ticking&buff.symbols_of_death.up;
	if talents[SB.ShurikenTornado] and cooldown[SB.ShurikenTornado].ready and
		(targets >= 3 and talents[SB.ShadowFocus] and debuff[SB.Nightblade].up and buff[SB.SymbolsOfDeath].up)
	then
		return SB.ShurikenTornado;
	end

	-- shadow_dance,if=!buff.shadow_dance.up&target.time_to_die<=5+talent.subterfuge.enabled&!raid_event.adds.up;
	--if cooldown[SB.ShadowDance].ready and (not buff[SB.ShadowDanceAura].up) then
	--	return SB.ShadowDance;
	--end
end

function Rogue:SubtletyFinish()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, combo, energy, targets =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.combo, fd.energy, fd.targets;

	local usePriorityRotation = false;

	-- eviscerate,if=talent.shadow_focus.enabled&buff.nights_vengeance.up&spell_targets.shuriken_storm>=2+3*talent.secret_technique.enabled;
	if combo >= 1 and energy >= 35 and (
		talents[SB.ShadowFocus] and
		buff[A.NightsVengeance].up and
		targets >= 2 + (talents[SB.SecretTechnique] and 3 or 0)
	) then
		return SB.Eviscerate;
	end

	local tickTime = 2;
	-- nightblade,if=(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>6&remains<tick_time*2&(spell_targets.shuriken_storm<4|!buff.symbols_of_death.up);
	if combo >= 1 and (
		(not talents[SB.DarkShadow] or not buff[SB.ShadowDanceAura].up) and
		debuff[SB.Nightblade].remains < tickTime * 2 and
		(targets < 4 or not buff[SB.SymbolsOfDeath].up)
	) then
		return SB.Nightblade;
	end

	-- nightblade,cycle_targets=1,if=!variable.use_priority_rotation&spell_targets.shuriken_storm>=2&(talent.secret_technique.enabled|azerite.nights_vengeance.enabled|spell_targets.shuriken_storm<=5)&!buff.shadow_dance.up&target.time_to_die>=(5+(2*combo_points))&refreshable;
	if combo >= 1 and (
		not usePriorityRotation and
		targets >= 2 and
		(talents[SB.SecretTechnique] or azerite[A.NightsVengeance] > 0 or targets <= 5) and
		not buff[SB.ShadowDanceAura].up and
		debuff[SB.Nightblade].refreshable)
	then
		return SB.Nightblade;
	end

	-- nightblade,if=remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5;
	if combo >= 1 and (
		debuff[SB.Nightblade].remains < cooldown[SB.SymbolsOfDeath].remains + 10 and
		cooldown[SB.SymbolsOfDeath].remains <= 5
	) then
		return SB.Nightblade;
	end

	-- secret_technique,if=buff.symbols_of_death.up&(!talent.dark_shadow.enabled|buff.shadow_dance.up);
	if talents[SB.SecretTechnique] and cooldown[SB.SecretTechnique].ready and combo >= 1 and (
		buff[SB.SymbolsOfDeath].up and
		(not talents[SB.DarkShadow] or buff[SB.ShadowDanceAura].up)
	) then
		return SB.SecretTechnique;
	end

	-- secret_technique,if=spell_targets.shuriken_storm>=2+talent.dark_shadow.enabled+talent.nightstalker.enabled;
	if talents[SB.SecretTechnique] and cooldown[SB.SecretTechnique].ready and combo >= 1 and (
		targets >= 2 + (talents[SB.DarkShadow] and 1 or 0) + (talents[SB.Nightstalker] and 1 or 0))
	then
		return SB.SecretTechnique;
	end

	-- eviscerate;
	return SB.Eviscerate;
end

function Rogue:SubtletyStealthCds()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, comboDeficit =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.comboDeficit;
	-- variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=1.75;

	local shdThreshold = cooldown[SB.ShadowDance].charges >= 1.75;
	local usePriorityRotation = false;

	-- vanish,if=!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1;
	--if cooldown[SB.Vanish].ready and (not shdThreshold and debuff[SB.FindWeakness].remains < 1 and comboDeficit > 1) then
	--	return SB.Vanish;
	--end

	-- shadow_dance,if=(!talent.dark_shadow.enabled|dot.nightblade.remains>=5+talent.subterfuge.enabled)&(!talent.nightstalker.enabled&!talent.dark_shadow.enabled|!variable.use_priority_rotation|combo_points.deficit<=1)&(variable.shd_threshold|buff.symbols_of_death.remains>=1.2|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10);
	if cooldown[SB.ShadowDance].ready and (
		(not talents[SB.DarkShadow] or debuff[SB.Nightblade].remains >= 5 + (talents[SB.Subterfuge] and 1 or 0)) and
		(not talents[SB.Nightstalker] and not talents[SB.DarkShadow] or not usePriorityRotation or comboDeficit <= 1) and
		(shdThreshold or buff[SB.SymbolsOfDeath].remains >= 1.2 or targets >= 4 and cooldown[SB.SymbolsOfDeath].remains > 10)
	) then
		return SB.ShadowDance;
	end

	-- shadow_dance,if=target.time_to_die<cooldown.symbols_of_death.remains&!raid_event.adds.up;
	if cooldown[SB.ShadowDance].ready then
		return SB.ShadowDance;
	end
end

function Rogue:SubtletyStealthed()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, energy, comboDeficit, targets =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.energy, fd.comboDeficit, fd.targets;

	local shadowStrike = MaxDps:FindSpell(SB.Shadowstrike) and SB.Shadowstrike or SB.Backstab;
	-- shadowstrike,if=buff.stealth.up;
	if energy >= 40 and (buff[SB.Stealth].up) then
		return shadowStrike;
	end

	if comboDeficit <= 1 - (talents[SB.DeeperStratagem] and buff[SB.Vanish].up and 1 or 0) then
		return Rogue:SubtletyFinish();
	end

	-- shuriken_toss,if=buff.sharpened_blades.stack>=29&(!talent.find_weakness.enabled|debuff.find_weakness.up);
	if energy >= 40 and (
		buff[A.SharpenedBlades].count >= 29 and
		(not talents[SB.FindWeakness] or debuff[SB.FindWeakness].up)
	) then
		return SB.ShurikenToss;
	end

	-- shadowstrike,cycle_targets=1,if=talent.secret_technique.enabled&talent.find_weakness.enabled&debuff.find_weakness.remains<1&spell_targets.shuriken_storm=2&target.time_to_die-remains>6;
	if energy >= 40 and (
		talents[SB.SecretTechnique] and
		talents[SB.FindWeakness] and
		debuff[SB.FindWeakness].remains < 1 and
		targets == 2
	) then
		return shadowStrike;
	end

	-- shadowstrike,if=!talent.deeper_stratagem.enabled&azerite.blade_in_the_shadows.rank=3&spell_targets.shuriken_storm=3;
	if energy >= 40 and (
		not talents[SB.DeeperStratagem] and
		azerite[A.BladeInTheShadows] == 3 and
		targets == 3
	) then
		return shadowStrike;
	end

	-- shuriken_storm,if=spell_targets>=3;
	if targets >= 3 then
		return SB.ShurikenStorm;
	end

	-- shadowstrike;
	return shadowStrike;
end

