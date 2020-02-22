local Class = require("Class")
local Log = require("Log")
local Stats = require("Core.Stats")
local Boss = require("Core.Boss")
local Unit = require("WC3.Unit")
local CreepPreset = require("Core.CreepPreset")
local Timer = require("WC3.Timer")

local BossPresetLog = Log.Category("Boss\\BossPreset", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

local BossPreset = Class(CreepPreset)

function BossPreset:ctor()
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

    self.class = Boss
end

function BossPreset:Spawn(owner, x, y, facing,  level, herocount)
    local Boss = CreepPreset.Spawn(self, owner, x, y, facing,  level, herocount);
    BossPresetLog:Info("Spawn Boss")
    Boss.abilities:AddAction(function() self:Cast(Boss) end)
    print("BossPreset")
    print(Boss)

    for i, ability in pairs(self.abilities) do
        BossPresetLog:Info("Number "..i)
        if ability.availableFromStart then
            Boss:AddAbility(ability.id)
        end
    end
    print("BossPreset after spell adding")
    print(Boss)
    return Boss
end


function BossPreset:Cast(Boss)
    local abilityId = GetSpellAbilityId()
    for _, ability in pairs(self.abilities) do
        if type(ability.id) == "table" then
            for _, id in pairs(ability.id) do
                if id == abilityId then
                    ability:handler(Boss)
                    break
                end
            end
        else
            if ability.id == abilityId then
                ability:handler(Boss)
                break
            end
        end
    end
end

Log("Creep load succsesfull")
return BossPreset