local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end

local MaxDps = MaxDps;
local Rogue = addonTable.Rogue;

local OL = {
	AdrenalineRush = 13750,
	Ambush = 8676,
	Audacity = 381845,
	BetweenTheEyes = 315341,
	BladeFlurry = 13877,
	BladeRush = 271877,
	Broadside = 193356,
	BuriedTreasure = 199600,
	ColdBlood = 382245,
	CountTheOdds = 381982,
	Dispatch = 2098,
	Dreadblades = 343142,
	EchoingReprimand = 385616,
	FanTheHammer = 381846,
	GhostlyStrike = 196937,
	GrandMelee = 193358,
	GreenskinsWickers = 386823,
	ImprovedAdrenalineRush = 395422,
	KeepItRolling = 381989,
	KillingSpree = 51690,
	MarkedForDeath = 137619,
	MasterAssassinBuff = 256735,
	Opportunity = 195627,
	PistolShot = 185763,
	QuickDraw = 196938,
	RollTheBones = 315508,
	RuthlessPrecision = 193357,
	Sepsis = 385408,
	SepsisBuff = 347037,
	SerratedBoneSpike = 385424,
	SerratedBoneSpikeDot = 394036,
	ShadowBlades = 121471,
	ShadowDance = 185313,
	Shiv = 5938,
	SinisterStrike = 193315,
	SkullAndCrossbones = 199603,
	SliceAndDice = 315496,
	Stealth = 1784,
	SwiftSlasher = 381988,
	TakeEmBySurprise = 382742,
	ThistleTea = 381623,
	TinyToxicBlade = 381800,
	TrueBearing = 193359,
	Vanish = 1856,
	ViciousWound = 115774,
	Weaponmaster = 200733
};

setmetatable(OL, Rogue.spellMeta);

local echoingReprimand = {
	auras = {
		{
			id = 323558,
			cp = 2
		},
		{
			id = 323559,
			cp = 3
		},
		{
			id = 323560,
			cp = 4
		},
		{
			id = 354835,
			cp = 5
		}
	}
};

echoingReprimand.up = function(comboPoints)
	local buff = MaxDps.FrameData.buff

	for i in pairs(echoingReprimand.auras) do
		local aura = echoingReprimand.auras[i];
		if buff[aura.id].up and aura.cp == comboPoints then
			return aura
		end
	end

	return false
end

local function calculateEffectiveComboPoints(comboPoints)
	if comboPoints > 1 and comboPoints < 6 then
		local aura = echoingReprimand.up(comboPoints)
		if aura then
			return MaxDps.FrameData.cpMaxSpend
		end
	end

	return comboPoints
end

local function calculateRtbBuffCount()
	local buff = MaxDps.FrameData.buff

	local rollTheBonesBuffCount = 0;
	if buff[OL.SkullAndCrossbones].up then rollTheBonesBuffCount = rollTheBonesBuffCount + 1; end
	if buff[OL.TrueBearing].up        then rollTheBonesBuffCount = rollTheBonesBuffCount + 1; end
	if buff[OL.RuthlessPrecision].up  then rollTheBonesBuffCount = rollTheBonesBuffCount + 1; end
	if buff[OL.GrandMelee].up         then rollTheBonesBuffCount = rollTheBonesBuffCount + 1; end
	if buff[OL.BuriedTreasure].up     then rollTheBonesBuffCount = rollTheBonesBuffCount + 1; end
	if buff[OL.Broadside].up          then rollTheBonesBuffCount = rollTheBonesBuffCount + 1; end

	return rollTheBonesBuffCount
end

function Rogue:Outlaw()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local talents = fd.talents
	local targets = MaxDps:SmartAoe()
	fd.targets = targets
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints)
	fd.comboPoints = comboPoints
	local cpMaxSpend = UnitPowerMax('player', Enum.PowerType.ComboPoints)
	fd.cpMaxSpend = cpMaxSpend
	local comboPointsDeficit = cpMaxSpend - comboPoints
	fd.comboPointsDeficit = comboPointsDeficit
	local energy = UnitPower('player', Enum.PowerType.Energy)
	fd.energy = energy
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyRegen = GetPowerRegen();
	fd.energyDeficit = energyMax - energy
	fd.energyRegen = energyRegen
	fd.energyTimeToMax = (energyMax - energy) / energyRegen
	local effectiveComboPoints = calculateEffectiveComboPoints(comboPoints);
	local rtbBuffCount = calculateRtbBuffCount()
	local stealthed = IsStealthed()

	-- variable,name=rtb_reroll,value=rtb_buffs<2&(!buff.broadside.up&(!runeforge.concealed_blunderbuss&!talent.fan_the_hammer|!buff.skull_and_crossbones.up)&(!runeforge.invigorating_shadowdust|!buff.true_bearing.up))|rtb_buffs=2&buff.buried_treasure.up&buff.grand_melee.up
	local rtbReroll = rtbBuffCount < 2 and ( not buff[OL.Broadside].up and ( not talents[OL.FanTheHammer] or not buff[OL.SkullAndCrossbones].up ) and not buff[OL.TrueBearing].up ) or rtbBuffCount == 2 and buff[OL.BuriedTreasure].up and buff[OL.GrandMelee].up
	fd.rtbReroll = rtbReroll

	-- variable,name=ambush_condition,value=combo_points.deficit>=2+buff.broadside.up&energy>=50&(!conduit.count_the_odds&!talent.count_the_odds|buff.roll_the_bones.remains>=10)
	local ambushCondition = comboPointsDeficit >= 2 and buff[OL.Broadside].up and energy >= 50 and ( not talents[OL.CountTheOdds] or (not talents[OL.RollTheBones] or cooldown[OL.RollTheBones].remains >= 10) )
	fd.ambushCondition = ambushCondition

	-- variable,name=finish_condition,value=combo_points>=cp_max_spend-buff.broadside.up-(buff.opportunity.up*(talent.quick_draw|talent.fan_the_hammer)|buff.concealed_blunderbuss.up)|effective_combo_points>=cp_max_spend
	local finishCondition = (
			(comboPoints >= cpMaxSpend and 1 or 0)
			- (buff[OL.Broadside].up and 1 or 0)
			- ((( buff[OL.Opportunity].up and ( talents[OL.QuickDraw] or talents[OL.FanTheHammer] ) )) and 1 or 0)
			) > 0
			or effectiveComboPoints >= cpMaxSpend
	fd.finishCondition = finishCondition

	-- variable,name=finish_condition,op=reset,if=cooldown.between_the_eyes.ready&effective_combo_points<5
	if cooldown[OL.BetweenTheEyes].ready and effectiveComboPoints < 5 then
		finishCondition = false
	end

	-- variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.remains>1+talent.killing_spree.enabled
	local bladeFlurrySync = targets < 2 and buff[OL.BladeFlurry].remains > (1 + (talents[OL.KillingSpree] and 1 or 0))
	fd.bladeFlurrySync = bladeFlurrySync

	-- run_action_list,name=stealth,if=stealthed.all
	if stealthed then
		return Rogue:OutlawStealth()
	end

	-- call_action_list,name=cds
	local result = Rogue:OutlawCds()
	if result then
		return result
	end

	-- run_action_list,name=finish,if=variable.finish_condition
	if finishCondition then
		return Rogue:OutlawFinish()
	end

	-- call_action_list,name=build
	result = Rogue:OutlawBuild()
	if result then
		return result
	end

	return OL.SinisterStrike
end

local function calccCpGain(baseCp)
	local buff = MaxDps.FrameData.buff
	local debuff = MaxDps.FrameData.debuff
	return debuff[OL.Dreadblades].up and MaxDps.FrameData.cpMaxSpend or ( baseCp + ( buff[OL.ShadowBlades].up and 1 or 0 ) + ( buff[OL.Broadside].up and 2 or 1 ) + ( buff[OL.Opportunity].up and 1 or 0 ) )
end

function Rogue:OutlawBuild()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local timeToDie = fd.timeToDie
	local energy = fd.energy
	local comboPointsDeficit = fd.comboPointsDeficit
	local bladeFlurrySync = fd.bladeFlurrySync
	local energyTimeToMax = fd.energyTimeToMax
	local energyDeficit = fd.energyDeficit
	local energyRegen = fd.energyRegen
	local stealthed = fd.stealthed

	-- sepsis,target_if=max:target.time_to_die*debuff.between_the_eyes.up,if=target.time_to_die>11&debuff.between_the_eyes.up|fight_remains<11
	if talents[OL.Sepsis] and cooldown[OL.Sepsis].ready and energy >= 25 and (timeToDie > 11 and debuff[OL.BetweenTheEyes].up or timeToDie < 11) then
		return OL.Sepsis
	end

	-- ghostly_strike,if=debuff.ghostly_strike.remains<=3
	if talents[OL.GhostlyStrike] and cooldown[OL.GhostlyStrike].ready and energy >= 30 and (debuff[OL.GhostlyStrike].remains <= 3) then
		return OL.GhostlyStrike
	end

	-- shiv,if=runeforge.tiny_toxic_blade
	if cooldown[OL.Shiv].ready and energy >= 20 and talents[OL.TinyToxicBlade] then
		return OL.Shiv
	end

	-- echoing_reprimand,if=!soulbind.effusive_anima_accelerator|variable.blade_flurry_sync
	if talents[OL.EchoingReprimand] and cooldown[OL.EchoingReprimand].ready and energy >= 10 and not bladeFlurrySync then
		return OL.EchoingReprimand
	end

	-- ambush
	if energy >= 50 and buff[OL.SepsisBuff].up then
		return OL.Ambush
	end

	-- cold_blood,if=buff.opportunity.up&buff.greenskins_wickers.up|buff.greenskins_wickers.up&buff.greenskins_wickers.remains<1.5
	if talents[OL.ColdBlood] and cooldown[OL.ColdBlood].ready and (buff[OL.Opportunity].up and buff[OL.GreenskinsWickers].up or buff[OL.GreenskinsWickers].up and buff[OL.GreenskinsWickers].remains < 1.5) then
		return OL.ColdBlood
	end

	-- pistol_shot,if=buff.opportunity.up&(buff.greenskins_wickers.up&!talent.fan_the_hammer|buff.concealed_blunderbuss.up)|buff.greenskins_wickers.up&buff.greenskins_wickers.remains<1.5
	if energy >= 40 and (buff[OL.Opportunity].up and ( buff[OL.GreenskinsWickers].up and not talents[OL.FanTheHammer] ) or buff[OL.GreenskinsWickers].up and buff[OL.GreenskinsWickers].remains < 1.5) then
		return OL.PistolShot
	end

	local opportunityMaxCharges = 1 + (talents[OL.FanTheHammer] and 5 or 0)

	-- pistol_shot,if=talent.fan_the_hammer&buff.opportunity.up&(buff.opportunity.stack>=buff.opportunity.max_stack|buff.opportunity.remains<2)
	if energy >= 40 and (talents[OL.FanTheHammer] and buff[OL.Opportunity].up and ( buff[OL.Opportunity].count >= opportunityMaxCharges or buff[OL.Opportunity].remains < 2 )) then
		return OL.PistolShot
	end

	-- pistol_shot,if=talent.fan_the_hammer&buff.opportunity.up&combo_points.deficit>4&!buff.dreadblades.up
	if energy >= 40 and (talents[OL.FanTheHammer] and buff[OL.Opportunity].up and comboPointsDeficit > 4 and not buff[OL.Dreadblades].up) then
		return OL.PistolShot
	end

	-- serrated_bone_spike,if=!dot.serrated_bone_spike_dot.ticking
	if talents[OL.SerratedBoneSpike] and cooldown[OL.SerratedBoneSpike].ready and energy >= 15 and (not debuff[OL.SerratedBoneSpikeDot].up) then
		return OL.SerratedBoneSpike
	end

	-- serrated_bone_spike,if=fight_remains<=5|cooldown.serrated_bone_spike.max_charges-charges_fractional<=0.25|combo_points.deficit=cp_gain&!buff.skull_and_crossbones.up&energy.base_time_to_max>1
	if talents[OL.SerratedBoneSpike] and cooldown[OL.SerratedBoneSpike].ready and energy >= 15 and (timeToDie <= 5 or cooldown[OL.SerratedBoneSpike].maxCharges - cooldown[OL.SerratedBoneSpike].charges <= 0.25 or comboPointsDeficit == calccCpGain(1) and not buff[OL.SkullAndCrossbones].up and energyTimeToMax > 1) then
		return OL.SerratedBoneSpike
	end

	-- pistol_shot,if=!talent.fan_the_hammer&buff.opportunity.up&(energy.base_deficit>energy.regen*1.5|!talent.weaponmaster&combo_points.deficit<=1+buff.broadside.up|talent.quick_draw.enabled|talent.audacity.enabled&!buff.audacity.up)
	if energy >= 40 and (
			not talents[OL.FanTheHammer] 
					and buff[OL.Opportunity].up 
					and ( 
						energyDeficit > energyRegen * 1.5 
								or not talents[OL.Weaponmaster] 
								and comboPointsDeficit <= 1 + (buff[OL.Broadside].up 
								or talents[OL.QuickDraw] 
								or talents[OL.Audacity] 
								and not buff[OL.Audacity].up) and 1 or 0
					)
	)
	then
		return OL.PistolShot
	end

	-- sinister_strike
	if energy >= 45 then
		return OL.SinisterStrike
	end
end

function Rogue:OutlawCds()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local timeToDie = fd.timeToDie
	local energy = fd.energy
	local comboPoints = fd.comboPoints
	local comboPointsDeficit = fd.comboPointsDeficit
	local finishCondition = fd.finishCondition
	local rtbReroll = fd.rtbReroll
	local stealthed = fd.stealthed
	local ambushCondition = fd.ambushCondition
	local cpMaxSpend = fd.cpMaxSpend
	local bladeFlurrySync = fd.bladeFlurrySync
	local energyDeficit = fd.energyDeficit
	local energyRegen = fd.energyRegen
	local energyTimeToMax = fd.energyTimeToMax

	-- blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up
	if talents[OL.BladeFlurry] and cooldown[OL.BladeFlurry].ready and energy >= 15 and (targets >= 2 and not buff[OL.BladeFlurry].up) then
		return OL.BladeFlurry
	end
	local masterAssassinRemains = buff[OL.MasterAssassinBuff].remains

	-- roll_the_bones,if=master_assassin_remains=0&buff.dreadblades.down&(!buff.roll_the_bones.up|variable.rtb_reroll)
	if talents[OL.RollTheBones] and cooldown[OL.RollTheBones].ready and energy >= 25 and (masterAssassinRemains == 0 and not buff[OL.Dreadblades].up and rtbReroll ) then
		return OL.RollTheBones
	end

	-- keep_it_rolling,if=!variable.rtb_reroll&(buff.broadside.up+buff.true_bearing.up+buff.skull_and_crossbones.up+buff.ruthless_precision.up)>2
	if talents[OL.KeepItRolling] and cooldown[OL.KeepItRolling].ready and (not rtbReroll and ( (buff[OL.Broadside].up and 1 or 0) + (buff[OL.TrueBearing].up and 1 or 0) + (buff[OL.SkullAndCrossbones].up and 1 or 0) + (buff[OL.RuthlessPrecision].up and 1 or 0) ) > 2) then
		return OL.KeepItRolling
	end

	-- shadow_dance,if=!runeforge.mark_of_the_master_assassin&!runeforge.invigorating_shadowdust&!runeforge.deathly_shadows&!stealthed.all&!buff.take_em_by_surprise.up&(variable.finish_condition&buff.slice_and_dice.up|variable.ambush_condition&!buff.slice_and_dice.up)
	if talents[OL.ShadowDance] and cooldown[OL.ShadowDance].ready and (not stealthed and not buff[OL.TakeEmBySurprise].up and ( finishCondition and buff[OL.SliceAndDice].up or ambushCondition and not buff[OL.SliceAndDice].up )) then
		return OL.ShadowDance
	end

	-- vanish,if=!runeforge.mark_of_the_master_assassin&!runeforge.invigorating_shadowdust&!runeforge.deathly_shadows&!stealthed.all&!buff.take_em_by_surprise.up&(variable.finish_condition&buff.slice_and_dice.up|variable.ambush_condition&!buff.slice_and_dice.up)
	if cooldown[OL.Vanish].ready and (not stealthed and not buff[OL.TakeEmBySurprise].up and ( finishCondition and buff[OL.SliceAndDice].up or ambushCondition and not buff[OL.SliceAndDice].up )) then
		return OL.Vanish
	end
	
	-- adrenaline_rush,if=!buff.adrenaline_rush.up&(!talent.improved_adrenaline_rush|combo_points<=2)
	if talents[OL.AdrenalineRush] and cooldown[OL.AdrenalineRush].ready and (not buff[OL.AdrenalineRush].up and ( not talents[OL.ImprovedAdrenalineRush] or comboPoints <= 2 )) then
		return OL.AdrenalineRush
	end

	-- dreadblades,if=!stealthed.all&combo_points<=2&(!covenant.venthyr|buff.flagellation_buff.up)&(!talent.marked_for_death|!cooldown.marked_for_death.ready)
	if talents[OL.Dreadblades] and cooldown[OL.Dreadblades].ready and energy >= 50 and (not stealthed and comboPoints <= 2 and ( not talents[OL.MarkedForDeath] or not cooldown[OL.MarkedForDeath].ready )) then
		return OL.Dreadblades
	end

	-- marked_for_death,line_cd=1.5,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
	if talents[OL.MarkedForDeath] and cooldown[OL.MarkedForDeath].ready and (( timeToDie < comboPointsDeficit or not stealthed and comboPointsDeficit >= cpMaxSpend - 1 )) then
		return OL.MarkedForDeath
	end

	-- marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1&(!covenant.venthyr|cooldown.flagellation.remains>10|buff.flagellation_buff.up)
	if talents[OL.MarkedForDeath] and cooldown[OL.MarkedForDeath].ready and (not stealthed and comboPointsDeficit >= cpMaxSpend - 1) then
		return OL.MarkedForDeath
	end

	if talents[OL.KillingSpree] then
		-- variable,name=killing_spree_vanish_sync,value=!runeforge.mark_of_the_master_assassin|cooldown.vanish.remains>10|master_assassin_remains>2
		local killingSpreeVanishSync = cooldown[OL.Vanish].remains > 10 or masterAssassinRemains > 2

		-- killing_spree,if=variable.blade_flurry_sync&variable.killing_spree_vanish_sync&!stealthed.rogue&(debuff.between_the_eyes.up&buff.dreadblades.down&energy.base_deficit>(energy.regen*2+15)|spell_targets.blade_flurry>(2-buff.deathly_shadows.up)|master_assassin_remains>0)
		if cooldown[OL.KillingSpree].ready and (bladeFlurrySync and killingSpreeVanishSync and not stealthed and ( debuff[OL.BetweenTheEyes].up and not buff[OL.Dreadblades].up and energyDeficit > ( energyRegen * 2 + 15 ) or targets > 2 or masterAssassinRemains > 0 )) then
			return OL.KillingSpree
		end
	end

	-- blade_rush,if=variable.blade_flurry_sync&(energy.base_time_to_max>2&!buff.dreadblades.up&!buff.flagellation_buff.up|energy<=30|spell_targets>2)
	if talents[OL.BladeRush] and cooldown[OL.BladeRush].ready and (bladeFlurrySync and ( energyTimeToMax > 2 and not buff[OL.Dreadblades].up and energy <= 30 or targets > 2 )) then
		return OL.BladeRush
	end

	-- thistle_tea,if=energy.deficit>=100&!buff.thistle_tea.up&(charges=3|buff.adrenaline_rush.up|fight_remains<charges*6)
	if talents[OL.ThistleTea] and cooldown[OL.ThistleTea].ready and (energyDeficit >= 100 and not buff[OL.ThistleTea].up and ( cooldown[OL.ThistleTea].charges == 3 or buff[OL.AdrenalineRush].up or timeToDie < cooldown[OL.ThistleTea].charges * 6 )) then
		return OL.ThistleTea
	end
end

function Rogue:OutlawFinish()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local timeToDie = fd.timeToDie
	local energy = fd.energy
	local comboPoints = fd.comboPoints
	local cpMaxSpend = fd.cpMaxSpend

	-- between_the_eyes,if=target.time_to_die>3&(debuff.between_the_eyes.remains<4|(runeforge.greenskins_wickers|talent.greenskins_wickers)&!buff.greenskins_wickers.up|!runeforge.greenskins_wickers&!talent.greenskins_wickers&buff.ruthless_precision.up)
	if cooldown[OL.BetweenTheEyes].ready and energy >= 25 and comboPoints >= 1 and (timeToDie > 3 and ( debuff[OL.BetweenTheEyes].remains < 4 or ( talents[OL.GreenskinsWickers] ) and not buff[OL.GreenskinsWickers].up or not talents[OL.GreenskinsWickers] and buff[OL.RuthlessPrecision].up )) then
		return OL.BetweenTheEyes
	end

	-- slice_and_dice,if=buff.slice_and_dice.remains<fight_remains&refreshable&(!talent.swift_slasher|combo_points>=cp_max_spend)
	if energy >= 25 and comboPoints >= 1 and (buff[OL.SliceAndDice].remains < timeToDie and buff[OL.SliceAndDice].refreshable and ( not talents[OL.SwiftSlasher] or comboPoints >= cpMaxSpend )) then
		return OL.SliceAndDice
	end

	-- cold_blood,if=!(runeforge.greenskins_wickers|talent.greenskins_wickers)
	if talents[OL.ColdBlood] and cooldown[OL.ColdBlood].ready and not talents[OL.GreenskinsWickers] then
		return OL.ColdBlood
	end

	-- dispatch
	if energy >= 35 and comboPoints >= 1 then
		return OL.Dispatch
	end
end

function Rogue:OutlawStealth()
	local fd = MaxDps.FrameData
	local energy = fd.energy
	local comboPoints = fd.comboPoints
	local finishCondition = fd.finishCondition

	-- dispatch,if=variable.finish_condition
	if energy >= 35 and comboPoints >= 1 and (finishCondition) then
		return OL.Dispatch
	end

	-- ambush
	if energy >= 50 then
		return OL.Ambush
	end
end