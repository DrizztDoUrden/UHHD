local Class = require("Class")

local UHDItem = require("Core.UHDItem")

local ChainArmor = Class(UHDItem)

function ChainArmor:ctor(...)
    UHDItem.ctor(self, FourCC("I001"), ...)
    self.itemid = FourCC("I001")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = 5
    self.bonusSecondaryStats.evasion = -0.15
    self.bonusSecondaryStats.spellDamage = -0.15
end

return ChainArmor