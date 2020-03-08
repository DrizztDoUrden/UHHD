local Class = require("Class")

local ItemPreset = require("Core.ItemPreset")

local LeatherArmor = Class(ItemPreset)

function LeatherArmor:ctor()
    ItemPreset.ctor(self)
    self.itemid = FourCC("I002")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.evasion = 1.1
    self.bonusSecondaryStats.spellDamage = 0.9
end

return LeatherArmor