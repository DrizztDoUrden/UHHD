local Class = require("Class")

local ItemPreset = require("Core.ItemPreset")

local ChainArmor = Class(ItemPreset)

function ChainArmor:ctor(...)
    ItemPreset.ctor(self)
    self.itemid = FourCC("I003")
    self.type = "BodyArmor"
    self.bonusSecondaryStats.armor = 10
    self.bonusSecondaryStats.evasion = 0.7
    self.bonusSecondaryStats.spellDamage = 0.8
end

return ChainArmor