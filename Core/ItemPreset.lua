local Class = require("Class")
local Stats = require("Core.Stats")
local UHDItem = require("Core.UHDItem")
local Copy = require "Copy"

local ItemPreset = Class()


function ItemPreset:ctor(...)
    self.type = "general"
    self.modules = {}

    self.bonusSecondaryStats = Stats.Secondary()

    self.bonusSecondaryStats.health = 0
    self.bonusSecondaryStats.mana = 0
    self.bonusSecondaryStats.healthRegen = 0
    self.bonusSecondaryStats.manaRegen = 0

    self.bonusSecondaryStats.weaponDamage = 1
    self.bonusSecondaryStats.attackSpeed = 1
    self.bonusSecondaryStats.physicalDamage = 1
    self.bonusSecondaryStats.spellDamage = 1

    self.bonusSecondaryStats.armor = 0
    self.bonusSecondaryStats.evasion = 1
    self.bonusSecondaryStats.ccResist = 0
    self.bonusSecondaryStats.spellResist = 0

    self.bonusSecondaryStats.movementSpeed = 1
end

function ItemPreset:Create(x, y)
    local item = UHDItem(self.itemid, x, y)
    item.bonusSecondaryStats = Copy(self.bonusSecondaryStats)
    item.type = self.type
    item.modules = self.modules
    return item
end

return ItemPreset