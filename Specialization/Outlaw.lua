local _, addonTable = ...
local Rogue = addonTable.Rogue
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Outlaw = {}

function Rogue:Outlaw()
    local _, class = UnitClass("player")
    local specIndex = GetSpecialization()
    local specName = specIndex and select(2, GetSpecializationInfo(specIndex))

    if class and specName and MaxDps.classCooldowns[class] and MaxDps.classCooldowns[class][specName] then
        for _, spellID in pairs(MaxDps.classCooldowns[class][specName].defensive) do
            --print("Defensive:", spellName, spellID)
            if MaxDps:CheckSpellUsable(spellID) then
                MaxDps:GlowDefensiveHPMidnight(spellID, true)
            end
        end
    end
    if class and specName
        and MaxDps.classInterrupts[class]
        and MaxDps.classInterrupts[class][specName]
    then
        for _, spellID in pairs(MaxDps.classInterrupts[class][specName]) do
            --print("Defensive:", spellName, spellID)
            if MaxDps:CheckSpellUsable(spellID) then
                MaxDps:GlowInteruptMidnight(spellID)
            end
        end
    end
    if class and specName and MaxDps.classCooldowns[class] and MaxDps.classCooldowns[class][specName] then
        for _, spellID in pairs(MaxDps.classCooldowns[class][specName].offensive) do
            --print("Defensive:", spellName, spellID)
            if not MaxDps.FrameData.ACSpells or not MaxDps.FrameData.ACSpells[spellID] then
                if MaxDps:CheckSpellUsable(spellID) then
                    MaxDps:GlowCooldownMidnight(spellID, true)
                end
            end
        end
    end
end
