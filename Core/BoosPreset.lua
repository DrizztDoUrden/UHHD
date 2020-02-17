local Class = require("Class")
local Log = require("Log")
local Stats = require("Core.Stats")
local Boos = require("Core.Boos")

local boosPresetLog = Log.Category("Boos\\BoosPreset", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

local BoosPreset = Class()

function BoosPreset:ctor()
    self.secondaryStats = Stats.Secondary()

    self.abilities = {}

    self.secondaryStats.health = 50
    self.secondaryStats.mana = 2
    self.secondaryStats.healthRegen = 1
    self.secondaryStats.manaRegen = 1

    self.secondaryStats.weaponDamage = 15
    self.secondaryStats.attackSpeed = 0.5
    self.secondaryStats.physicalDamage = 1
    self.secondaryStats.spellDamage = 1

    self.secondaryStats.armor = 5
    self.secondaryStats.evasion = 0.3
    self.secondaryStats.block = 0
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0.3

    self.secondaryStats.movementSpeed = 1
end

function BoosPreset:Spawn(owner, x, y, facing)
    local boos = Boos(owner, self.unitid, x, y, facing);

    boos.secondaryStats = self.secondaryStats
    boos:ApplyStats()
    boos.abilities:AddAction(function() self:Cast(boos) end)

    for i, ability in pairs(self.abilities) do
        boosPresetLog:Info("Number "..i)
        if ability.availableFromStart then
            boosPresetLog:Info("Try to add ability")
            boos:AddAbility(ability.id)
        end
    end
    return boos
end

function BoosPreset:Cast(boos)
    local abilityId = GetSpellAbilityId()
    for _, ability in pairs(self.abilities) do
        if type(ability.id) == "table" then
            for _, id in pairs(ability.id) do
                if id == abilityId then
                    ability:handler(boos)
                    break
                end
            end
        else
            if ability.id == abilityId then
                ability:handler(boos)
                break
            end
        end
    end
end



Log("Creep load succsesfull")
return BoosPreset