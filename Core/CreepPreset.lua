local Class = require("Class")
local Log = require("Log")
local Stats = require("Core.Stats")
local Creep = require("Core.Creep")
local Copy = require "Copy"

local CreepPreset = Class()

function CreepPreset:ctor()
    self.secondaryStats = Stats.Secondary()

    self.secondaryStats.health = 50
    self.secondaryStats.mana = 10
    self.secondaryStats.healthRegen = 1
    self.secondaryStats.manaRegen = 1

    self.secondaryStats.weaponDamage = 15
    self.secondaryStats.attackSpeed = 0.5
    self.secondaryStats.physicalDamage = 1
    self.secondaryStats.spellDamage = 1

    self.secondaryStats.armor = 0
    self.secondaryStats.evasion = 0
    self.secondaryStats.block = 0
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0

    self.secondaryStats.movementSpeed = 1
    self.class = Creep
end

function CreepPreset:Spawn(owner, x, y, facing, level, herocount)
    local creep = self.class(owner, self.unitid, x, y, facing);
    creep.secondaryStats = Copy(self.secondaryStats)
    creep:Scale(level, herocount)
    creep:ApplyStats()
    -- print(" CreepPreset")
    -- print(creep)
    return creep
end



Log("Creep load succsesfull")
return CreepPreset