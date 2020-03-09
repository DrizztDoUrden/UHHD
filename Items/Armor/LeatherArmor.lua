local Class = require("Class")

local UHDItem = require("Core.UHDItem")

local LeatherArmor = Class(UHDItem)

function LeatherArmor:ctor(...)
    UHDItem.ctor(self, FourCC("I002"), ...)
    self.itemid = FourCC("I002")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.evasion = 0.1
    self.bonusSecondaryStats.spellDamage = 0.9
end

return LeatherArmor