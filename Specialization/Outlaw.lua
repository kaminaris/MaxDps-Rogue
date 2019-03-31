local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local MaxDps = MaxDps;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetPowerRegen = GetPowerRegen;
local ComboPoints = Enum.PowerType.ComboPoints;
local Energy = Enum.PowerType.Energy;
local Rogue = addonTable.Rogue;

local OL = {
	Stealth              = 1784,
	MarkedForDeath       = 137619,
	RollTheBones         = 193316,
	SliceAndDice         = 5171,
	AdrenalineRush       = 13750,
	LoadedDice           = 256170,
	BetweenTheEyes       = 199804,
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
	Dispatch             = 2098,
	Ambush               = 8676,

	StealthAura          = 1784,
	VanishAura           = 11327,
};

local A = {
	Deadshot        = 272935,
	AceUpYourSleeve = 278676,
	SnakeEyes       = 275846,
};

setmetatable(OL, Rogue.spellMeta);
setmetatable(A, Rogue.spellMeta);

function Rogue:Outlaw()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local targets = MaxDps:SmartAoe();
	local comboPoints = UnitPower('player', ComboPoints);
	local comboPointsMax = UnitPowerMax('player', ComboPoints);
	local comboPointsDeficit = comboPointsMax - comboPoints;

	local energy = UnitPower('player', Energy);
	local energyMax = UnitPowerMax('player', Energy);
	local energyTimeToMax = (energyMax - energy) / GetPowerRegen();

	local cpMaxSpend = 5 + (talents[OL.DeeperStratagem] and 1 or 0);

	local stealthed = buff[OL.StealthAura].up or buff[OL.VanishAura].up;

	local Rtb = {'Broadside','GrandMelee','RuthlessPrecision','TrueBearing','SkullAndCrossbones','BuriedTreasure'};
	local rtbBuffs = 0;
	local rtbRemains = 0;
	for _, i in pairs(Rtb) do
		if buff[OL[i]].up then
			rtbBuffs = rtbBuffs + 1;
			rtbRemains = buff[OL[i]].remains;
		end
	end
print(rtbBuffs)
	-- variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up);
	local rtbReroll = rtbBuffs < 2 and (buff[OL.LoadedDice].up or not buff[OL.GrandMelee].up and not buff[OL.RuthlessPrecision].up);

	-- variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains);
	if azerite[A.Deadshot] > 0 or azerite[A.AceUpYourSleeve] > 0 then
		rtbReroll = rtbBuffs < 2 and (buff[OL.LoadedDice].up or buff[OL.RuthlessPrecision].remains <= cooldown[OL.BetweenTheEyes].remains);
	end

	-- variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2;
	if azerite[A.SnakeEyes] >= 2 then
		rtbReroll = rtbBuffs < 2;
	end

	-- variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up;
	if azerite[A.SnakeEyes] >= 2 and buff[OL.SnakeEyes].count >= 2 - buff[OL.Broadside].upMath then
		rtbReroll = false;
	end

	-- variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up;
	local ambushCondition = comboPointsDeficit >=
		2 + 2 * (talents[OL.GhostlyStrike] and cooldown[OL.GhostlyStrike].remains < 1 and 1 or 0) + (buff[OL.Broadside].up and 1 or 0) and
		energy > 60 and
		not buff[OL.SkullAndCrossbones].up;

	-- variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up;
	local bladeFlurrySync = targets < 2 and 20 or buff[OL.BladeFlurry].up;

	fd.targets = targets;
	fd.energy = energy;
	fd.energyTimeToMax = energyTimeToMax;
	fd.comboPoints = comboPoints;
	fd.cpMaxSpend = cpMaxSpend;
	fd.ambushCondition = ambushCondition;
	fd.bladeFlurrySync = bladeFlurrySync;
	fd.stealthed = stealthed;
	fd.comboPointsDeficit = comboPointsDeficit;
	fd.rtbReroll = rtbReroll;
	fd.rtbRemains = rtbRemains;

	-- adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1;
	MaxDps:GlowCooldown(
		OL.AdrenalineRush, cooldown[OL.AdrenalineRush].ready and not buff[OL.AdrenalineRush].up and energyTimeToMax > 1
	);

	-- vanish,if=!stealthed.all&variable.ambush_condition;
	MaxDps:GlowCooldown(
		OL.Vanish,
		cooldown[OL.Vanish].ready and (not stealthed and ambushCondition)
	);

	-- killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15);
	if talents[OL.KillingSpree] then
		MaxDps:GlowCooldown(
			OL.KillingSpree,
			cooldown[OL.KillingSpree].ready and bladeFlurrySync and (energyTimeToMax > 5 or energy < 15)
		);
	end

	if self.db.outlawMarkedAsCooldown then
		-- marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1);
		-- marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1;
		MaxDps:GlowCooldown(
			OL.MarkedForDeath,
			cooldown[OL.MarkedForDeath].ready and (
				(timeToDie < comboPointsDeficit or not stealthed and comboPointsDeficit >= cpMaxSpend - 1) or
				(not stealthed and comboPointsDeficit >= cpMaxSpend - 1)
			)
		);
	end

	-- call_action_list,name=stealth,if=stealthed.all;
	if stealthed then
		local result = Rogue:OutlawStealth();
		if result then return result; end
	end

	-- call_action_list,name=cds;
	local result = Rogue:OutlawCds();
	if result then return result; end

	-- run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1));
	if comboPoints >= cpMaxSpend -
		(buff[OL.Broadside].upMath + buff[OL.Opportunity].upMath) *
		(talents[OL.QuickDraw] and (not talents[OL.MarkedForDeath] or cooldown[OL.MarkedForDeath].remains > 1) and 1 or 0)
	then
		return Rogue:OutlawFinish();
	end

	-- call_action_list,name=build;
	return Rogue:OutlawBuild();
end

function Rogue:OutlawBuild()
	local fd = MaxDps.FrameData;
	local buff = fd.buff;
	local energy = fd.energy;

	-- pistol_shot,if=buff.opportunity.up&(buff.keep_your_wits_about_you.stack<25|buff.deadshot.up);
	if buff[OL.Opportunity].up and energy >= 20 and (buff[OL.KeepYourWitsAboutYou].count < 25 or buff[OL.Deadshot].up)
	then
		return OL.PistolShot;
	end

	-- sinister_strike;
	return OL.SinisterStrike;
end

function Rogue:OutlawCds()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local timeToDie = fd.timeToDie;
	local energy = fd.energy;
	local energyTimeToMax = fd.energyTimeToMax;
	local comboPoints = fd.comboPoints;
	local cpMaxSpend = fd.cpMaxSpend;
	local stealthed = fd.stealthed;
	local comboPointsDeficit = fd.comboPointsDeficit;
	local bladeFlurrySync = fd.bladeFlurrySync;

	if not self.db.outlawMarkedAsCooldown then
		-- marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1);
		if cooldown[OL.MarkedForDeath].ready and (
			timeToDie < comboPointsDeficit or not stealthed and comboPointsDeficit >= cpMaxSpend - 1
		) then
			return OL.MarkedForDeath;
		end

		-- marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1;
		if cooldown[OL.MarkedForDeath].ready and not stealthed and comboPointsDeficit >= cpMaxSpend - 1 then
			return OL.MarkedForDeath;
		end
	end

	-- blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25);
	if cooldown[OL.BladeFlurry].ready and (
		targets >= 2 and not buff[OL.BladeFlurry].up and ((2 - cooldown[OL.BladeFlurry].charges) * 25)
	) then
		return OL.BladeFlurry;
	end

	-- ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up;
	if talents[OL.GhostlyStrike] and cooldown[OL.GhostlyStrike].ready and energy >= 30 and bladeFlurrySync and
		comboPointsDeficit >= 1 + buff[OL.Broadside].upMath
	then
		return OL.GhostlyStrike;
	end

	-- blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1;
	if talents[OL.BladeRush] and cooldown[OL.BladeRush].ready and bladeFlurrySync and energyTimeToMax > 1 then
		return OL.BladeRush;
	end
end

function Rogue:OutlawFinish()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local energy = fd.energy;
	local comboPoints = fd.comboPoints;
	local rtbReroll = fd.rtbReroll;
	local rtbBuffs = fd.rtbBuffs;
	local rtbRemains = fd.rtbRemains;

	-- between_the_eyes,if=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up;
	if cooldown[OL.BetweenTheEyes].ready and energy >= 25 and comboPoints >= 1 and (
		buff[OL.RuthlessPrecision].up or
		(azerite[A.Deadshot] > 0 or azerite[A.AceUpYourSleeve] > 0) and rtbBuffs >= 2
	) then
		return OL.BetweenTheEyes;
	end

	-- slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8;
	if talents[OL.SliceAndDice] and energy >= 25 and comboPoints >= 1 and
		buff[OL.SliceAndDice].remains < timeToDie and buff[OL.SliceAndDice].remains < (1 + comboPoints) * 1.8
	then
		return OL.SliceAndDice;
	end

	-- roll_the_bones,if=buff.roll_the_bones.remains<=3|variable.rtb_reroll;
	if energy >= 25 and comboPoints >= 1 and (rtbRemains <= 3 or rtbReroll) then
		return OL.RollTheBones;
	end

	-- between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled;
	if cooldown[OL.BetweenTheEyes].ready and energy >= 25 and comboPoints >= 1 and (azerite[A.AceUpYourSleeve] > 0 or azerite[A.Deadshot] > 0) then
		return OL.BetweenTheEyes;
	end

	-- dispatch;
	if energy >= 35 and comboPoints >= 1 then
		return OL.Dispatch;
	end
end

function Rogue:OutlawStealth()
	-- ambush;
	return OL.Ambush;
end



--[[
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
]]--