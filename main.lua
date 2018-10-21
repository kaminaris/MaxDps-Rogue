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

function Rogue:Assassination(timeShift, currentSpell, gcd, talents, azerite)
	return nil;
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
		Rtb.Up.GrandMelee,         _, Rtb.Remains.GrandMelee         = MaxDps:Aura(SO.GrandMelee, timeShift);
		Rtb.Up.RuthlessPrecision,  _, Rtb.Remains.RuthlessPrecision  = MaxDps:Aura(SO.RuthlessPrecision, timeShift);
		Rtb.Up.Broadside,          _, Rtb.Remains.Broadside          = MaxDps:Aura(SO.Broadside, timeShift);
		Rtb.Up.BuriedTreasure,     _, Rtb.Remains.BuriedTreasure     = MaxDps:Aura(SO.BuriedTreasure, timeShift);
		Rtb.Up.TrueBearing,        _, Rtb.Remains.TrueBearing        = MaxDps:Aura(SO.TrueBearing, timeShift);
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

function Rogue:Subtlety(timeShift, currentSpell, gcd, talents, azerite)
	return nil;
end