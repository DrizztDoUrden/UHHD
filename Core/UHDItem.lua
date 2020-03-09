
local Stats = require("Core.Stats")
local Class = require("Class")
local WC3 = require("WC3.All")

local UHDItem = Class(WC3.Item)


function UHDItem:ctor(...)
    WC3.Item.ctor(self, ...)
    
    self.type = "general"
    self.modules = {}


    self.bonusSecondaryStats = Stats.Secondary()

    self.bonusSecondaryStats.health = 0
    self.bonusSecondaryStats.mana = 0
    self.bonusSecondaryStats.healthRegen = 0
    self.bonusSecondaryStats.manaRegen = 0

    self.bonusSecondaryStats.weaponDamage = 0
    self.bonusSecondaryStats.attackSpeed = 0
    self.bonusSecondaryStats.physicalDamage = 0
    self.bonusSecondaryStats.spellDamage = 0

    self.bonusSecondaryStats.armor = 0
    self.bonusSecondaryStats.evasion = 0
    self.bonusSecondaryStats.ccResist = 0
    self.bonusSecondaryStats.spellResist = 0

    self.bonusSecondaryStats.movementSpeed = 0
end

function  UHDItem:AddStats(unit)
    if UHDItem.type == "Weapon" then
        unit.baseSecondaryStats.weaponDamage = self.baseSecondaryStats.weaponDamage
    end
    for k, v in pairs(self.bonusSecondaryStats) do
        unit.bonusSecondaryStats[k] = Stats.Secondary.AddBonus[k](unit.bonusSecondaryStats[k], v)
    end
    unit:ApplyStats()
end

function  UHDItem:RemoveStats(unit)
    if UHDItem.type == "Weapon" then
        unit.baseSecondaryStats.weaponDamage = 0
    end
    for k, v in pairs(self.bonusSecondaryStats) do
        unit.bonusSecondaryStats[k] = Stats.Secondary.SubBonus[k](unit.bonusSecondaryStats[k], v)
    end
    unit:ApplyStats()
end

return UHDItem