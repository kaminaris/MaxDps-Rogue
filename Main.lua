local addonName, addonTable = ...
_G[addonName] = addonTable

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps
local Rogue = MaxDps:NewModule('Rogue')
addonTable.Rogue = Rogue

Rogue.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!')
	end
}

function Rogue:Enable()
	if MaxDps:IsRetailWow() then
	    Rogue:InitializeDatabase()
	    Rogue:CreateConfig()
	end

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Rogue.Assassination
		MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Assassination', "info")
	elseif MaxDps.Spec == 2 then
		if MaxDps:IsRetailWow() then
		    MaxDps.NextSpell = Rogue.Outlaw
		    MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Outlaw', "info")
		else
			MaxDps.NextSpell = Rogue.Combat
		    MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Combat', "info")
		end
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Rogue.Subtlety
		MaxDps:Print(MaxDps.Colors.Info .. 'Rogue Subtlety', "info")
	end

	return true
end

function Rogue:EnergyCost(spellId)
	local spellTable = GetSpellPowerCost(spellId)
	if spellTable ~= nil then
		if spellTable[2] ~= nil then
			return spellTable[2].cost
		else
			return spellTable[1].cost
		end
	end
end