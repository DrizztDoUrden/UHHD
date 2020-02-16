local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local Timer = require("WC3.Timer")
local Creep = Class(UHDUnit)

    function Creep:Destroy()
        local timer = Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

    function Creep:Scale(level, heroesCount)
        local mult = (1 + 0.05 * (0.7 * heroesCount +  0) * (level - 1))
        self.secondaryStats.health = mult * self.secondaryStats.health
        self.secondaryStats.physicalDamage = mult * self.secondaryStats.physicalDamage
        self.secondaryStats.armor = mult * self.secondaryStats.armor
    end


return Creep