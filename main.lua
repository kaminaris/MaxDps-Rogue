-- Outlaw
local _BladeFlurry = 13877;
local _RolltheBones = 193316;
local _TrueBearing = 193359;
local _SharkInfestedWaters = 193357;
local _GhostlyStrike = 196937;
local _CurseoftheDreadblades = 202665;
local _AdrenalineRush = 13750;
local _MarkedforDeath = 137619;
local _RunThrough = 2098;
local _Broadsides = 193356;
local _PistolShot = 185763;
local _Opportunity = 195627;
local _SaberSlash = 193315;
local _Vanish = 1856;
local _Ambush = 8676;
local _CheapShot = 1833;
local _PreyontheWeak = 131511;
local _DeeperStratagem = 193531;
local _JollyRoger = 199603;
local _GrandMelee = 193358;
local _BuriedTreasure = 199600;
local _SliceandDice = 5171;
local _DeathfromAbove = 152150;
local _Vigor = 14983;
local _CombatPotency = 35551;
local _Bloodlust = 2825;
local _Heroism = 32182;
local _TimeWarp = 80353;
local _Ruthlessness = 14161;
local _Sprint = 2983;
local _BetweentheEyes = 199804;
local _Blind = 2094;
local _CloakofShadows = 31224;
local _Riposte = 199754;
local _GrapplingHook = 195457;
local _CannonballBarrage = 185767;
local _KillingSpree = 51690;
local _Feint = 1966;
local _Elusiveness = 79008;
local _CheatDeath = 31230;
local _CrimsonVial = 185311;
local _Stealth = 1784;
local _HiddenBlade = 202753;

--Assasination
local _Rupture = 1943;
local _Vendetta = 79140;
local _Vanish = 1856;
local _Nightstalker = 14062;
local _Mutilate = 1329;
local _Garrote = 703;
local _Envenom = 32645;
local _Kingsbane = 192759;
local _FanofKnives = 51723;
local _AgonizingPoison = 200802;
local _DeadlyPoison = 2823;
local _CripplingPoison = 3408;
local _Vigor = 14983;
local _VenomousWounds = 79134;
local _UrgetoKill = 192384;
local _VenomRush = 152152;
local _SurgeofToxins = 192424;
local _SealFate = 14190;
local _PoisonedKnife = 185565;
local _DeeperStratagem = 193531;
local _Exsanguinate = 200806;
local _MasterAssassin = 192349;
local _Feint = 1966;
local _Elusiveness = 79008;
local _CloakofShadows = 31224;
local _Evasion = 5277;
local _CheatDeath = 31230;
local _CrimsonVial = 185311;
local _Stealth = 1784;
local _Berserking = 26297;


-- Sub
local _Nightblade = 195452;
local _ShadowBlades = 121471;
local _ShadowDance = 185313;
local _EnvelopingShadows = 206237;
local _MasterofShadows = 196976;
local _Shadowstrike = 185438;
local _Anticipation = 114015;
local _SymbolsofDeath = 212283;
local _DeathfromAbove = 152150;
local _Vanish = 1856;
local _GoremawsBite = 209783;
local _Stealth = 1784;
local _Eviscerate = 196819;
local _Backstab = 53;
local _DarkShadow = 245687;
local _FinalityEviscerate = 197393;
local _ShurikenStorm = 197835;
local _Vigor = 14983;
local _RelentlessStrikes = 58423;
local _EnergeticStabbing = 197239;
local _CheapShot = 1833;
local _ShadowsWhisper = 242707;
local _ShadowTechniques = 196912;
local _Subterfuge = 108208;
local _ShadowFocus = 108209;
local _DeepeningShadows = 185314;
local _MasteryExecutioner = 76808;
local _Feint = 1966;
local _Elusiveness = 79008;
local _CloakofShadows = 31224;
local _SeekerSwarm = 213238;
local _FelNova = 206517;
local _CheatDeath = 31230;
local _CrimsonVial = 185311;
local _FinalityNightblade = 197395;
local _DeeperStratagem = 193531;

-- Auras
local _Stealth = 1784;

MaxDps.Rogue = {};
function MaxDps.Rogue.CheckTalents()
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Rogue [Outlaw]';
	MaxDps.ModuleOnEnable = MaxDps.Rogue.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Rogue.Assassination;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Rogue.Outlaw;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Rogue.Subtlety;
	end;
end

function MaxDps.Rogue.Assassination(_, timeShift, currentSpell, gcd, talents)
	local energy = UnitPower('player', SPELL_POWER_ENERGY);
	local combo = GetComboPoints('player', 'target');

	local poison = talents[_AgonizingPoison] and _AgonizingPoison or _DeadlyPoison;

	MaxDps:GlowCooldown(_Vendetta, energy < 30 and MaxDps:SpellAvailable(_Vendetta, timeShift));

	if not MaxDps:Aura(poison, timeShift + 60) then
		return poison;
	end

	local isStealth = MaxDps:PersistentAura(_Stealth) or MaxDps:Aura(_Vanish, timeShift);

	if MaxDps:SpellAvailable(_Vanish, timeShift) and combo >= 5 then
		return _Vanish;
	end

	if (combo >= 3 and not MaxDps:TargetAura(_Rupture, timeShift)) or
			(combo >= 5 and not MaxDps:TargetAura(_Rupture, timeShift + 6) and isStealth) then
		return _Rupture;
	end

	--kingsbane
	if MaxDps:SpellAvailable(_Kingsbane, timeShift) and MaxDps:Aura(_Envenom, timeShift) and energy > 35 then
		return _Kingsbane;
	end

	if not MaxDps:TargetAura(_Garrote, timeShift + 5) and energy >= 45 then
		return _Garrote;
	end

	if not MaxDps:Aura(_Envenom, timeShift + 1) and combo >= 4 then
		return _Envenom;
	end

	if energy > 95 then
		return _Mutilate;
	else
		return nil;
	end
end

function MaxDps.Rogue.Outlaw(_, timeShift, currentSpell, gcd, talents)

	local energy = UnitPower('player', SPELL_POWER_ENERGY);
	local combo = GetComboPoints('player', 'target');

	MaxDps:GlowCooldown(_AdrenalineRush, MaxDps:SpellAvailable(_AdrenalineRush, timeShift));
	MaxDps:GlowCooldown(_CurseoftheDreadblades, MaxDps:SpellAvailable(_CurseoftheDreadblades, timeShift));
	MaxDps:GlowCooldown(_KillingSpree, MaxDps:SpellAvailable(_KillingSpree, timeShift));

	if MaxDps:PersistentAura(_Stealth, timeShift) then
		return _Ambush;
	end

	local curse = MaxDps:Aura(_CurseoftheDreadblades, timeShift, 'HARMFUL');

	-- roll the bones auras
	local rb = {
		TB = MaxDps:Aura(_TrueBearing, timeShift + 3),
		SIW = MaxDps:Aura(_SharkInfestedWaters, timeShift + 3),
		JR = MaxDps:Aura(_JollyRoger, timeShift + 3),
		GM = MaxDps:Aura(_GrandMelee, timeShift + 3),
		BS = MaxDps:Aura(_Broadsides, timeShift + 3),
		BT = MaxDps:Aura(_BuriedTreasure, timeShift + 3),
	}
	-- buty, sprint co CD
	local rbCount = 0;
	for k, v in pairs(rb) do
		if v then
			rbCount = rbCount + 1;
		end
	end

	local shouldRoll = not rb.TB and rbCount < 2;

	if shouldRoll and combo >= 4 and energy >= 20 then
		return _RolltheBones;
	end

	if talents[_GhostlyStrike] and not MaxDps:TargetAura(_GhostlyStrike, timeShift + 3) and energy > 27 then
		return _GhostlyStrike;
	end

	if talents[_MarkedforDeath] and combo < 2 and MaxDps:SpellAvailable(_MarkedforDeath, timeShift) then
		return _MarkedforDeath;
	end

	if (combo >= 6 or (combo >= 5 and rb.BS)) then
		return _RunThrough;
	end

	if MaxDps:Aura(_Opportunity, timeShift) and combo <= 4 then
		return _PistolShot;
	end

	return _SaberSlash;
end

function MaxDps.Rogue.Subtlety(_, timeShift, currentSpell, gcd, talents)
	MaxDps:GlowCooldown(_ShadowBlades, MaxDps:SpellAvailable(_ShadowBlades, timeShift));
	MaxDps:GlowCooldown(_SymbolsofDeath, MaxDps:SpellAvailable(_SymbolsofDeath, timeShift));

	local energy = UnitPower('player', Enum.PowerType.Energy);
	local combo = UnitPower('player', Enum.PowerType.ComboPoints);

	local nightb, nightbCd = MaxDps:TargetAura(_Nightblade, timeShift);
	local sd, sdCharges = MaxDps:SpellCharges(_ShadowDance, timeShift);

	local isStealth = MaxDps:PersistentAura(_Stealth) or MaxDps:Aura(_Vanish, timeShift) or MaxDps:Aura(_ShadowDance, timeShift);

	-- EDIT HERE IF YOU HAVE DIFFERENT SPELLS
	local shadowStrike = _Shadowstrike;
	if not MaxDps:FindSpell(_Shadowstrike) then
		shadowStrike = _Backstab; -- EDIT SPELL THAT YOU HAVE SHADOWSTRIKE UNDER
	end

	-- DON'T EDIT BELOW THIS LINE

	if isStealth then
		if combo < 5 then
			return shadowStrike;
		end

	end

	if nightbCd < 2 then
		if combo < 5 then
			return _Backstab;
		else
			return _Nightblade;
		end
	end

	if combo >= 5 and nightbCd < 5 then
		return _Nightblade;
	end

	if sdCharges >= 1.8 and energy > 75 then
		return _ShadowDance;
	end

	local dfa = MaxDps:SpellAvailable(_DeathfromAbove, timeShift);
	if energy < 60 and talents[_DeathfromAbove] and dfa then
		return _DeathfromAbove;
	end

	if combo <= 3 and MaxDps:SpellAvailable(_Vanish, timeShift) then
		return _Vanish;
	end

	if not isStealth and combo < 3 and energy < 50 then
		return _GoremawsBite;
	end

	if combo >= 5 and dfa then
		return _DeathfromAbove;
	end

	if combo >= 5 then
		return _Eviscerate;
	end

	if combo < 5 then
		return _Backstab;
	else
		return nil;
	end
end