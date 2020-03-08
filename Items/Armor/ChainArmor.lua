local Class = require("Class")

local ItemPreset = require("Core.ItemPreset")

local ChainArmor = Class(ItemPreset)

function ChainArmor:ctor()
    ItemPreset.ctor(self)
    self.itemid = FourCC("I001")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = 5
    self.bonusSecondaryStats.evasion = 0.85
    self.bonusSecondaryStats.spellDamage = 0.85
end

return ChainArmor