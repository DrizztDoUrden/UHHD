Class = require("Class")

UHDItem = require("Core.UHDItem")

local LeatherArmor = Class(UHDItem)

function LeatherArmor:ctor()
    UHDItem.ctor(self, "i001")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = 5
    self.bonusSecondaryStats.evasion = 0.85
    self.bonusSecondaryStats.spellDamage = 0.85
end