local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local Timer = require("WC3.Timer")
local Creep = Class(UHDUnit)
local Log = require("Log")
local creepLog = Log.Category("CreepSpawner\\CreepSpawnerr", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

    function Creep:Destroy()
        local timer = Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

    function Creep:OrderToAttack(x, y)
        self:IssueAttackPoint(x, y)
    end

    function Creep:Scale(level, heroesCount)
        local mult = (1 + 0.05 * (0.7 * heroesCount +  0) * (level - 1))
        --creepLog:Info("multiplier "..mult)
        self.secondaryStats.health = mult * self.secondaryStats.health
        self.secondaryStats.physicalDamage = mult * self.secondaryStats.physicalDamage
        self.secondaryStats.armor = mult * self.secondaryStats.armor
    end


return Creep