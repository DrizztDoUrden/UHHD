local Class = require("Class")

local UHDItem = require("Core.UHDItem")

local ChainArmor = Class(UHDItem)

function ChainArmor:ctor(...)
    UHDItem.ctor(self, FourCC("I003"), ...)
    self.itemid = FourCC("I003")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = 10
    self.bonusSecondaryStats.evasion = -0.3
    self.bonusSecondaryStats.spellDamage = -0.2
end

return ChainArmor