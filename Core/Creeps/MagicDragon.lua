local Class = Require("Class")
local CreepPreset = Require("Core.CreepPreset")
local Log = Require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 15
    self.secondaryStats.mana = 5
    self.secondaryStats.weaponDamage = 3

    self.unitid = FourCC('C_MD')
end
Log("MagicDragon load successfull")

return MagicDragon