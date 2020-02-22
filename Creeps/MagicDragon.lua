local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 10
    self.secondaryStats.mana = 5
    self.secondaryStats.weaponDamage = 6
    self.secondaryStats.evasion = 0.1
    self.unitid = FourCC('e000')
end


return MagicDragon