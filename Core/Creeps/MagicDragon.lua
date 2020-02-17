local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 10
    self.secondaryStats.mana = 5
    self.secondaryStats.weaponDamage = 3
    self.secondaryStats.evasion = 0.1
    self.unitid = FourCC('e000')
end
Log("MagicDragon load successfull")

return MagicDragon