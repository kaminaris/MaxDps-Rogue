local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local Druid = addonTable.Druid;

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


function Druid:Guardian()
	return nil;
end