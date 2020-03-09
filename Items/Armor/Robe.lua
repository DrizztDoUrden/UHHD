local Class = require("Class")

local UHDItem = require("Core.UHDItem")

local Robe = Class(UHDItem)

function Robe:ctor(...)
    UHDItem.ctor(self, FourCC("I004"), ...)
    self.itemid = FourCC("I004")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = -2
    self.bonusSecondaryStats.evasion = -0.1
    self.bonusSecondaryStats.spellDamage = 0.2
end

return Robe