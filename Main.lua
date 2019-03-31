local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Rogue = MaxDps:NewModule('Rogue');
addonTable.Rogue = Rogue;

Rogue.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

setmetatable(SB, Rogue.spellMeta);
setmetatable(A, Rogue.spellMeta);

function Rogue:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Rogue.Assassination;
		MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Assassination');
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Rogue.Outlaw;
		MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Outlaw');
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Rogue.Subtlety;
		MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Subtlety');
	end

	return true;
end