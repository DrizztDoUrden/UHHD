local Class = require("Class")

local ItemPreset = require("Core.ItemPreset")

local Robe = Class(ItemPreset)

function Robe:ctor()
    ItemPreset.ctor(self)
    self.itemid = FourCC("I004")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = -2
    self.bonusSecondaryStats.evasion = 0.9
    self.bonusSecondaryStats.spellDamage = 1.2
end

return Robe