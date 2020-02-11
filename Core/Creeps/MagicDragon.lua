local Class = Require("Class")
local CreepPreset = Require("Core.CreepPreset")
local Log = Require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    Log("Construct Magic Dragon")
    CreepPreset.ctor(self)
    self.secondaryStats.health = 50
    self.secondaryStats.mana = 15

    self.unitid = FourCC('C_MD')
end
Log("MagicDragon load successfull")

return MagicDragon