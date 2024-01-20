local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local GetPowerRegen = GetPowerRegen
local ComboPoints = Enum.PowerType.ComboPoints
local Energy = Enum.PowerType.Energy
local Rogue = addonTable.Rogue

local AS = {
	Ambush = 8676,
	AmplifyingPoison = 381664,
	BlindsideBuff = 121153,
	CrimsonTempest = 121411,
	DashingScoundrel = 381797,
	DeadlyPoison = 2823,
	DeadlyPoisonDot = 2818,
	Deathmark = 360194,
	DeeperStratagem = 193531,
	Doomblade = 381673,
	DragontemperedBlades = 381801,
	EchoingReprimand = 385616,
	Envenom = 32645,
	Exsanguinate = 200806,
	FanOfKnives = 51723,
	Garrote = 703,
	ImprovedGarrote = 381632,
	ImprovedGarroteBuff = 392401,
	IndiscriminateCarnage = 381802,
	InternalBleeding	= 154904,
	Kingsbane = 385627,
	MarkedForDeath = 137619,
	MasterAssassin = 255989,
	MasterAssassinBuff = 256735,
	Mutilate = 1329,
	MutilatedFlesh = 340431,
	Rupture = 1943,
	Sepsis = 385408,
	SerratedBoneSpike = 385424,
	SerratedBoneSpikeDot = 394036,
	ShadowDance = 185313,
	Shiv = 5938,
	SliceAndDice = 315496,
	Stealth = 1784,
	ThistleTea = 381623,
	Vanish = 1856,
}

setmetatable(AS, Rogue.spellMeta)

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
}

echoingReprimand.up = function(comboPoints)
	local buff = MaxDps.FrameData.buff

	for i in pairs(echoingReprimand.auras) do
		local aura = echoingReprimand.auras[i]
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


function Rogue:Assassination()
	local fd = MaxDps.FrameData
	local buff, timeShift = fd.buff, fd.timeShift

	local energy = UnitPower('player', Energy)
	fd.energy = energy
	local energyMax = UnitPowerMax('player', Energy)
	fd.energyMax = energyMax
	fd.energyDeficit = energyMax - energy
	local energyRegen = GetPowerRegen()
	fd.energyRegen = energyRegen
	fd.energyTimeToMax = (energyMax - energy) / energyRegen

	local comboPoints = UnitPower('player', ComboPoints)
	fd.comboPoints = comboPoints
	fd.effectiveComboPoints = calculateEffectiveComboPoints(comboPoints)

	fd.cpMaxSpend = UnitPowerMax('player', ComboPoints)
	fd.comboPointsDeficit = fd.cpMaxSpend - comboPoints

	fd.targets = MaxDps:SmartAoe()

	--local stealthed = buff[AS.Stealth].up or buff[AS.StealthSub].up or buff[AS.VanishAura].up
	local poisonedBleeds = Rogue:PoisonedBleeds(timeShift)

	local spellHaste = MaxDps:AttackHaste()
	fd.spellHaste = spellHaste
	local energyRegenCombined = energyRegen + poisonedBleeds * 7 % (2 * spellHaste)
	fd.energyRegenCombined = energyRegenCombined
	fd.regenSaturated = energyRegenCombined > 35

	local stealthed = IsStealthed()
	fd.stealthed = stealthed
	fd.effectiveEnergy = energy + energyRegen * timeShift
	local inCombat = UnitAffectingCombat("player")
	fd.inCombat = inCombat

	if not buff[AS.DeadlyPoison].up then
		return AS.DeadlyPoison
	end

	if not inCombat and buff[AS.DeadlyPoison].remains < 300 then
		return AS.DeadlyPoison
	end

	-- call_action_list,name=stealthed,if=stealthed.rogue|stealthed.improved_garrote
	if stealthed or buff[AS.ImprovedGarroteBuff].up then
		local result = Rogue:AssassinationStealthed()
		if result then
			return result
		end
	end

	-- call_action_list,name=cds
	local result = Rogue:AssassinationCds()
	if result then
		return result
	end

	-- slice_and_dice,if=!buff.slice_and_dice.up&combo_points>=2
	if energy >= 25 and comboPoints >= 1 and (not buff[AS.SliceAndDice].up and comboPoints >= 2) then
		return AS.SliceAndDice
	end

	-- envenom,if=buff.slice_and_dice.up&buff.slice_and_dice.remains<5&combo_points>=4
	if energy >= 35 and comboPoints >= 1 and (buff[AS.SliceAndDice].up and buff[AS.SliceAndDice].remains < 5 and comboPoints >= 4) then
		return AS.Envenom
	end

	-- call_action_list,name=dot
	result = Rogue:AssassinationDot()
	if result then
		return result
	end

	-- call_action_list,name=direct
	result = Rogue:AssassinationDirect()
	if result then
		return result
	end
end

function Rogue:AssassinationCds()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local stealthed = fd.stealthed
	local timeToDie = fd.timeToDie
	local cpMaxSpend = fd.cpMaxSpend
	local comboPointsDeficit = fd.comboPointsDeficit
    local energyDeficit = fd.energyDeficit

	local energy = fd.energy

	-- marked_for_death,line_cd=1.5,target_if=min:target.time_to_die,if=raid_event.adds.up&(!variable.single_target|target.time_to_die<30)&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
	if talents[AS.MarkedForDeath] and cooldown[AS.MarkedForDeath].ready and (( targets > 1 or timeToDie < 30 ) and ( timeToDie < comboPointsDeficit * 1.5 or comboPointsDeficit >= cpMaxSpend )) then
		return AS.MarkedForDeath
	end

	-- sepsis,if=!stealthed.rogue&dot.garrote.ticking&(target.time_to_die>10|fight_remains<10)
	if talents[AS.Sepsis] and cooldown[AS.Sepsis].ready and energy >= 25 and (not stealthed and debuff[AS.Garrote].up and timeToDie > 10) then
		return AS.Sepsis
	end

	-- variable,name=deathmark_exsanguinate_condition,value=!talent.exsanguinate|cooldown.exsanguinate.remains>15|exsanguinated.rupture|exsanguinated.garrote
	local deathmarkExsanguinateCondition = not talents[AS.Exsanguinate] or cooldown[AS.Exsanguinate].remains > 15
	-- variable,name=deathmark_ma_condition,value=!talent.master_assassin.enabled|dot.garrote.ticking|covenant.venthyr&combo_points.deficit=0
	local deathmarkMaCondition = (not talents[AS.MasterAssassin] or debuff[AS.Garrote].up) and comboPointsDeficit == 0
	-- variable,name=deathmark_condition,value=!stealthed.rogue&dot.rupture.ticking&!debuff.deathmark.up&variable.deathmark_exsanguinate_condition&variable.deathmark_ma_condition&variable.deathmark_covenant_condition
	local deathmarkCondition = not stealthed and debuff[AS.Rupture].up and not debuff[AS.Deathmark].up and deathmarkExsanguinateCondition and deathmarkMaCondition

	-- deathmark,if=variable.deathmark_condition
	if talents[AS.Deathmark] and cooldown[AS.Deathmark].ready and deathmarkCondition then
		return AS.Deathmark
	end

	-- kingsbane,if=(debuff.shiv.up|cooldown.shiv.remains<6)&buff.envenom.up&(cooldown.deathmark.remains>=50|dot.deathmark.ticking)
	if talents[AS.Kingsbane] and cooldown[AS.Kingsbane].ready and energy >= 35 and (( debuff[AS.Shiv].up or cooldown[AS.Shiv].remains < 6 ) and buff[AS.Envenom].up and ( cooldown[AS.Deathmark].remains >= 50 or debuff[AS.Deathmark].up )) then
	    return AS.Kingsbane
	end

	-- exsanguinate,if=!stealthed.rogue&!stealthed.improved_garrote&!dot.deathmark.ticking&(!dot.garrote.refreshable&dot.rupture.remains>4+4*cp_max_spend|dot.rupture.remains*0.5>target.time_to_die)&target.time_to_die>4
	if talents[AS.Exsanguinate] and cooldown[AS.Exsanguinate].ready and energy >= 25 and (not stealthed and not buff[AS.ImprovedGarroteBuff].up and not debuff[AS.Deathmark].up and ( not debuff[AS.Garrote].refreshable and debuff[AS.Rupture].remains > 4 + 4 * cpMaxSpend or debuff[AS.Rupture].remains * 0.5 > timeToDie ) and timeToDie > 4) then
	    return AS.Exsanguinate
	end

	-- shiv,if=talent.kingsbane&!debuff.shiv.up&dot.kingsbane.ticking&dot.garrote.ticking&dot.rupture.ticking&(!talent.crimson_tempest.enabled|variable.single_target|dot.crimson_tempest.ticking)
	if cooldown[AS.Shiv].ready and energy >= 20 and (talents[AS.Kingsbane] and not debuff[AS.Shiv].up and debuff[AS.Kingsbane].up and debuff[AS.Garrote].up and debuff[AS.Rupture].up and ( not talents[AS.CrimsonTempest] or targets < 2 or debuff[AS.CrimsonTempest].up )) then
	    return AS.Shiv
	end

	-- shiv,if=!talent.kingsbane&!covenant.night_fae&!debuff.shiv.up&dot.garrote.ticking&dot.rupture.ticking&(!talent.crimson_tempest.enabled|variable.single_target|dot.crimson_tempest.ticking)
	if cooldown[AS.Shiv].ready and energy >= 20 and (not talents[AS.Kingsbane] and not debuff[AS.Shiv].up and debuff[AS.Garrote].up and debuff[AS.Rupture].up and ( not talents[AS.CrimsonTempest] or targets < 2 or debuff[AS.CrimsonTempest].up )) then
	    return AS.Shiv
	end

	-- thistle_tea,if=energy.deficit>=100&!buff.thistle_tea.up&(charges=3|debuff.deathmark.up|fight_remains<cooldown.deathmark.remains)
	if talents[AS.ThistleTea] and cooldown[AS.ThistleTea].ready and (energyDeficit >= 100 and not buff[AS.ThistleTea].up and ( cooldown[AS.ThistleTea].charges == 3 or debuff[AS.Deathmark].up or timeToDie < cooldown[AS.Deathmark].remains )) then
	    return AS.ThistleTea
	end

	-- indiscriminate_carnage,if=(spell_targets.fan_of_knives>desired_targets|spell_targets.fan_of_knives>1&raid_event.adds.in>60)&(!talent.improved_garrote|cooldown.vanish.remains>45)
	if talents[AS.IndiscriminateCarnage] and cooldown[AS.IndiscriminateCarnage].ready and (targets > 1 and ( not talents[AS.ImprovedGarrote] or cooldown[AS.Vanish].remains > 45 )) then
	    return AS.IndiscriminateCarnage
	end

	-- call_action_list,name=vanish,if=!stealthed.all&master_assassin_remains=0
	if not stealthed and not buff[AS.MasterAssassinBuff].up then
        local result = Rogue:AssassinationVanish()
        if result then
            return result
        end
	end
end

function Rogue:AssassinationDirect()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local timeToDie = fd.timeToDie
	local effectiveComboPoints = fd.effectiveComboPoints
	local energy = fd.energy
    local energyDeficit = fd.energyDeficit
    local energyRegenCombined = fd.energyRegenCombined
	local comboPoints = fd.comboPoints
	local comboPointsDeficit = fd.comboPointsDeficit
	local cpMaxSpend = fd.cpMaxSpend
	local stealthed = fd.stealthed

	-- envenom,if=effective_combo_points>=4+talent.deeper_stratagem.enabled&(debuff.deathmark.up|debuff.shiv.up|debuff.amplifying_poison.stack>=10|buff.flagellation_buff.up|energy.deficit<=25+energy.regen_combined|!variable.single_target|effective_combo_points>cp_max_spend)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
	if energy >= 35
			and comboPoints >= 1
			and (
				effectiveComboPoints >= (4 + (talents[AS.DeeperStratagem] and 1 or 0))
						and (
							debuff[AS.Deathmark].up
									or debuff[AS.Shiv].up
									or debuff[AS.AmplifyingPoison].count >= 10
									or (energyDeficit <= 25 + energyRegenCombined)
									or targets > 1
									or effectiveComboPoints > cpMaxSpend
						) and ( not talents[AS.Exsanguinate] or cooldown[AS.Exsanguinate].remains > 2 )
			)
	then
		return AS.Envenom
	end

    local masterAssassinRemains = buff[AS.MasterAssassinBuff].remains

	-- variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+energy.regen_combined|!variable.single_target
	local useFiller = comboPointsDeficit > 1 or energyDeficit <= 25 + energyRegenCombined or targets > 1

	-- serrated_bone_spike,if=variable.use_filler&!dot.serrated_bone_spike_dot.ticking
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and not debuff[AS.SerratedBoneSpikeDot].up) then
		return AS.SerratedBoneSpike
	end

	-- serrated_bone_spike,target_if=min:target.time_to_die+(dot.serrated_bone_spike_dot.ticking*600),if=variable.use_filler&!dot.serrated_bone_spike_dot.ticking
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and not debuff[AS.SerratedBoneSpikeDot].up) then
		return AS.SerratedBoneSpike
	end

	-- serrated_bone_spike,if=variable.use_filler&master_assassin_remains<0.8&(fight_remains<=5|cooldown.serrated_bone_spike.max_charges-charges_fractional<=0.25)
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and masterAssassinRemains < 0.8 and ( timeToDie <= 5 or cooldown[AS.SerratedBoneSpike].maxCharges - cooldown[AS.SerratedBoneSpike].charges <= 0.25 )) then
	return AS.SerratedBoneSpike
	end

	-- fan_of_knives,target_if=!dot.deadly_poison_dot.ticking&(!priority_rotation|dot.garrote.ticking|dot.rupture.ticking),if=variable.use_filler&spell_targets.fan_of_knives>=3
	if energy >= 35 and (useFiller and targets >= 3) then
	    return AS.FanOfKnives
	end

	-- echoing_reprimand,if=variable.use_filler&variable.deathmark_cooldown_remains>10
	if talents[AS.EchoingReprimand] and cooldown[AS.EchoingReprimand].ready and energy >= 10 and (useFiller and cooldown[AS.Deathmark].remains > 10) then
	    return AS.EchoingReprimand
	end

	-- ambush,if=variable.use_filler&(master_assassin_remains=0&!runeforge.doomblade|buff.blindside.up)
	if energy >= 50 and (useFiller and ( masterAssassinRemains == 0 and buff[AS.BlindsideBuff].up )) then
	    return AS.Ambush
	end

	-- mutilate,if=variable.use_filler
	if energy >= 50 and (useFiller) then
	    return AS.Mutilate
	end
end

function Rogue:AssassinationDot()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local timeToDie = fd.timeToDie
	local energy = fd.energy
	local effectiveComboPoints = fd.effectiveComboPoints
	local comboPoints = fd.comboPoints
	local comboPointsDeficit = fd.comboPointsDeficit
	local cpMaxSpend = fd.cpMaxSpend
	local spellHaste = fd.spellHaste
	local tickTime = 2 * spellHaste
	local energyRegenCombined = fd.energyRegenCombined
	local regenSaturated = fd.regenSaturated

    local masterAssassinRemains = buff[AS.MasterAssassinBuff].remains

	-- variable,name=skip_rupture,value=debuff.deathmark.up&(debuff.shiv.up|master_assassin_remains>0)&dot.rupture.remains>2
	local skipRupture = debuff[AS.Deathmark].up and ( debuff[AS.Shiv].up or masterAssassinRemains > 0 ) and debuff[AS.Rupture].remains > 2

	-- garrote,if=talent.exsanguinate.enabled&!will_lose_exsanguinate&dot.garrote.pmultiplier<=1&cooldown.exsanguinate.remains<2&spell_targets.fan_of_knives=1&raid_event.adds.in>6&dot.garrote.remains*0.5<target.time_to_die
	if cooldown[AS.Garrote].ready and energy >= 45 and (talents[AS.Exsanguinate] and cooldown[AS.Exsanguinate].remains < 2 and debuff[AS.Garrote].remains * 0.5 < timeToDie) then
	    return AS.Garrote
	end

	-- rupture,if=talent.exsanguinate.enabled&!will_lose_exsanguinate&dot.rupture.pmultiplier<=1&(effective_combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&dot.rupture.remains*0.5<target.time_to_die)
	if energy >= 25 and comboPoints >= 1 and (talents[AS.Exsanguinate] and ( effectiveComboPoints >= cpMaxSpend and cooldown[AS.Exsanguinate].remains < 1 and debuff[AS.Rupture].remains * 0.5 < timeToDie )) then
	    return AS.Rupture
	end

	-- garrote,if=refreshable&combo_points.deficit>=1&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3)&(!will_lose_exsanguinate|remains<=tick_time*2&spell_targets.fan_of_knives>=3)&(target.time_to_die-remains)>4&master_assassin_remains=0
	if cooldown[AS.Garrote].ready and energy >= 45 and (debuff[AS.Garrote].refreshable and comboPointsDeficit >= 1 and ( debuff[AS.Garrote].remains <= tickTime ) and ( debuff[AS.Garrote].remains <= tickTime * 2 ) and ( timeToDie - debuff[AS.Garrote].remains ) > 4 and masterAssassinRemains == 0) then
	    return AS.Garrote
	end

	-- crimson_tempest,target_if=min:remains,if=spell_targets>=2&effective_combo_points>=4&energy.regen_combined>20&(!cooldown.deathmark.ready|dot.rupture.ticking)&remains<(2+3*(spell_targets>=4))
	if talents[AS.CrimsonTempest] and comboPoints >= 1 and energy >= 35 and (effectiveComboPoints >= 4 and energyRegenCombined > 20 and ( not cooldown[AS.Deathmark].ready or debuff[AS.Rupture].up ) and debuff[AS.CrimsonTempest].remains < ( 2 + 3 * ( targets >= 4 and 1 or 0 ) )) then
		return AS.CrimsonTempest
	end

	-- rupture,if=!variable.skip_rupture&effective_combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3)&(!will_lose_exsanguinate|remains<=tick_time*2&spell_targets.fan_of_knives>=3)&target.time_to_die-remains>(4+(runeforge.dashing_scoundrel*5)+(runeforge.doomblade*5)+(variable.regen_saturated*6))
	if energy >= 25 and comboPoints >= 1 and (not skipRupture and effectiveComboPoints >= 4 and debuff[AS.Rupture].refreshable and ( debuff[AS.Rupture].remains <= tickTime ) and ( debuff[AS.Rupture].remains <= tickTime * 2 ) and timeToDie - debuff[AS.Rupture].remains > ( 4 + ( (regenSaturated and 1 or 0) * 6 ) )) then
		return AS.Rupture
	end

	-- crimson_tempest,if=spell_targets>=2&effective_combo_points>=4&remains<2+3*(spell_targets>=4)
	if talents[AS.CrimsonTempest] and comboPoints >= 1 and energy >= 35 and (effectiveComboPoints >= 4 and debuff[AS.CrimsonTempest].remains < 2 + 3 * ( targets >= 4 and 1 or 0 )) then
		return AS.CrimsonTempest
	end

	-- crimson_tempest,if=spell_targets=1&(!runeforge.dashing_scoundrel|rune_word.frost.enabled)&effective_combo_points>=(cp_max_spend-1)&refreshable&!will_lose_exsanguinate&!debuff.shiv.up&debuff.amplifying_poison.stack<15&target.time_to_die-remains>4
	if talents[AS.CrimsonTempest] and comboPoints >= 1 and energy >= 35 and (effectiveComboPoints >= ( cpMaxSpend - 1 ) and debuff[AS.CrimsonTempest].refreshable and not debuff[AS.Shiv].up and debuff[AS.AmplifyingPoison].count < 15 and timeToDie - debuff[AS.CrimsonTempest].remains > 4) then
		return AS.CrimsonTempest
	end
end

function Rogue:AssassinationStealthed()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local timeToDie = fd.timeToDie
	local energy = fd.energy

	-- indiscriminate_carnage,if=spell_targets.fan_of_knives>desired_targets|spell_targets.fan_of_knives>1&raid_event.adds.in>60
	if talents[AS.IndiscriminateCarnage] and cooldown[AS.IndiscriminateCarnage].ready and (targets > 1) then
		return AS.IndiscriminateCarnage
	end

	-- garrote,target_if=min:remains,if=stealthed.improved_garrote&!will_lose_exsanguinate&(remains<12%exsanguinated_rate|pmultiplier<=1)&target.time_to_die-remains>2
	if cooldown[AS.Garrote].ready and energy >= 45 and (buff[AS.ImprovedGarroteBuff].up and ( debuff[AS.Garrote].refreshable ) and timeToDie - debuff[AS.Garrote].remains > 2) then
		return AS.Garrote
	end

	-- garrote,if=talent.exsanguinate.enabled&stealthed.improved_garrote&active_enemies=1&!will_lose_exsanguinate&improved_garrote_remains<1.3
	if cooldown[AS.Garrote].ready and energy >= 45 and (talents[AS.Exsanguinate] and buff[AS.ImprovedGarroteBuff].up and targets <= 1 and buff[AS.ImprovedGarroteBuff].remains < 1.3) then
		return AS.Garrote
	end
end

function Rogue:AssassinationVanish()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local comboPoints = fd.comboPoints
	local comboPointsDeficit = fd.comboPointsDeficit

	-- vanish,if=talent.improved_garrote&cooldown.garrote.up&!exsanguinated.garrote&dot.garrote.pmultiplier<=1&(debuff.deathmark.up|cooldown.deathmark.remains<4)&combo_points.deficit>=(spell_targets.fan_of_knives>?4)
	if cooldown[AS.Vanish].ready and (talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up and ( debuff[AS.Deathmark].up or cooldown[AS.Deathmark].remains < 4 ) ) then
		return AS.Vanish
	end

	-- vanish,if=talent.improved_garrote&cooldown.garrote.up&!exsanguinated.garrote&dot.garrote.pmultiplier<=1&spell_targets.fan_of_knives>(3-talent.indiscriminate_carnage)&(!talent.indiscriminate_carnage|cooldown.indiscriminate_carnage.ready)
	if cooldown[AS.Vanish].ready and (talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up and ( not talents[AS.IndiscriminateCarnage] or cooldown[AS.IndiscriminateCarnage].ready )) then
		return AS.Vanish
	end

	-- vanish,if=!talent.improved_garrote&(talent.master_assassin.enabled|runeforge.mark_of_the_master_assassin)&!dot.rupture.refreshable&dot.garrote.remains>3&debuff.deathmark.up&(debuff.shiv.up|debuff.deathmark.remains<4|dot.sepsis.ticking)&dot.sepsis.remains<3
	if cooldown[AS.Vanish].ready and (not talents[AS.ImprovedGarrote] and talents[AS.MasterAssassin] and not debuff[AS.Rupture].refreshable and debuff[AS.Garrote].remains > 3 and debuff[AS.Deathmark].up and ( debuff[AS.Shiv].up or debuff[AS.Deathmark].remains < 4 or debuff[AS.Sepsis].up ) and debuff[AS.Sepsis].remains < 3) then
		return AS.Vanish
	end

	-- shadow_dance,if=talent.improved_garrote&cooldown.garrote.up&!exsanguinated.garrote&dot.garrote.pmultiplier<=1&(debuff.deathmark.up|cooldown.deathmark.remains<4|cooldown.deathmark.remains>60)&combo_points.deficit>=(spell_targets.fan_of_knives>?4)
	if cooldown[AS.ShadowDance].ready and (talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up and ( debuff[AS.Deathmark].up or cooldown[AS.Deathmark].remains < 4 or cooldown[AS.Deathmark].remains > 60 ) ) then
		return AS.ShadowDance
	end

	-- shadow_dance,if=!talent.improved_garrote&(talent.master_assassin.enabled|runeforge.mark_of_the_master_assassin)&!dot.rupture.refreshable&dot.garrote.remains>3&(debuff.deathmark.up|cooldown.deathmark.remains>60)&(debuff.shiv.up|debuff.deathmark.remains<4|dot.sepsis.ticking)&dot.sepsis.remains<3
	if cooldown[AS.ShadowDance].ready and (not talents[AS.ImprovedGarrote] and talents[AS.MasterAssassin] and not debuff[AS.Rupture].refreshable and debuff[AS.Garrote].remains > 3 and ( debuff[AS.Deathmark].up or cooldown[AS.Deathmark].remains > 60 ) and ( debuff[AS.Shiv].up or debuff[AS.Deathmark].remains < 4 or debuff[AS.Sepsis].up ) and debuff[AS.Sepsis].remains < 3) then
		return AS.ShadowDance
	end
end


function Rogue:PoisonedBleeds(timeShift)
	local poisoned = 0
	local debuff = MaxDps.FrameData.debuff

	local usedNamePlates = false

	for i, frame in pairs(C_NamePlate.GetNamePlates()) do
		usedNamePlates = true
		local unit = frame.UnitFrame.unit

		if frame:IsVisible() then
			MaxDps:CollectAura(unit, timeShift, debuff, 'PLAYER|HARMFUL')

			if debuff[AS.DeadlyPoisonDot].up then
				poisoned = poisoned +
						debuff[AS.Rupture].count +
						debuff[AS.MutilatedFlesh].count +
						debuff[AS.SerratedBoneSpike].count +
						debuff[AS.Garrote].count +
						debuff[AS.InternalBleeding].count
			end
		end
	end

	if not usedNamePlates then
		poisoned = debuff[AS.Rupture].count +
				debuff[AS.MutilatedFlesh].count +
				debuff[AS.SerratedBoneSpike].count +
				debuff[AS.Garrote].count +
				debuff[AS.InternalBleeding].count
	end

	return poisoned
end