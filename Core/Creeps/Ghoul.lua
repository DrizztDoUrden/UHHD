local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 35
    self.secondaryStats.mana = 0
    self.secondaryStats.weaponDamage = 1

    self.unitid = FourCC('e002')
end
Log("MagicDragon load successfull")

return MagicDragon