
Stats = require("Core.Stats")
Class = require("Class")
All = require("WC3.All")


local UHDItem = Class()


function UHDItem:ctor(itemid)
    All.Item.ctor(self, FourCC(itemid))
    self.itemid = FourCC(itemid)
    self.type = "general"
    self.modules = {}


    self.bonusSecondaryStats = Stats()

    self.bonusSecondaryStats.health = 0
    self.bonusSecondaryStats.mana = 0
    self.bonusSecondaryStats.healthRegen = 0
    self.bonusSecondaryStats.manaRegen = 0

    self.bonusSecondaryStats.weaponDamage = 0
    self.bonusSecondaryStats.attackSpeed = 1
    self.bonusSecondaryStats.physicalDamage = 1
    self.bonusSecondaryStats.spellDamage = 1

    self.bonusSecondaryStats.armor = 0
    self.bonusSecondaryStats.evasion = 0
    self.bonusSecondaryStats.ccResist = 0
    self.bonusSecondaryStats.spellResist = 0

    self.bonusSecondaryStats.movementSpeed = 0
end

function  UHDItem:AddStats(unit)
    local bonusSecondaryStats = unit.bonusSecondaryStats
    unit.bonusSecondaryStats.health = bonusSecondaryStats.health + self.bonusSecondaryStats.health
    unit.bonusSecondaryStats.mana = bonusSecondaryStats.mana + self.bonusSecondaryStats.mana
    unit.bonusSecondaryStats.healthRegen = bonusSecondaryStats.healthRegen + self.bonusSecondaryStats.healthRegen
    unit.bonusSecondaryStats.manaRegen = bonusSecondaryStats.manaRegen + self.bonusSecondaryStats.manaRegen

    self.bonusSecondaryStats.weaponDamage = bonusSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage
    self.bonusSecondaryStats.attackSpeed = bonusSecondaryStats.attackSpeed + self.bonusSecondaryStats.attackSpeed
    self.bonusSecondaryStats.physicalDamage = bonusSecondaryStats.physicalDamage + self.bonusSecondaryStats.physicalDamage
    self.bonusSecondaryStats.spellDamage = bonusSecondaryStats.spellDamage + self.bonusSecondaryStats.spellDamage

    self.bonusSecondaryStats.armor = bonusSecondaryStats.armor + self.bonusSecondaryStats.armor
    self.bonusSecondaryStats.evasion = bonusSecondaryStats.evasion + self.bonusSecondaryStats.evasion
    self.bonusSecondaryStats.ccResist = bonusSecondaryStats.ccResist + self.bonusSecondaryStats.ccResist
    self.bonusSecondaryStats.spellResist = bonusSecondaryStats.spellResist + self.bonusSecondaryStats.spellResist

    self.bonusSecondaryStats.movementSpeed = bonusSecondaryStats.movementSpeed + self.bonusSecondaryStats.movementSpeed
    unit:ApplyStats()
end

function  UHDItem:RemoveStats(unit)
    local bonusSecondaryStats = unit.bonusSecondaryStats
    unit.bonusSecondaryStats.health = bonusSecondaryStats.health - self.bonusSecondaryStats.health
    unit.bonusSecondaryStats.mana = bonusSecondaryStats.mana - self.bonusSecondaryStats.mana
    unit.bonusSecondaryStats.healthRegen = bonusSecondaryStats.healthRegen - self.bonusSecondaryStats.healthRegen
    unit.bonusSecondaryStats.manaRegen = bonusSecondaryStats.manaRegen - self.bonusSecondaryStats.manaRegen

    self.bonusSecondaryStats.weaponDamage = bonusSecondaryStats.weaponDamage - self.bonusSecondaryStats.weaponDamage
    self.bonusSecondaryStats.attackSpeed = bonusSecondaryStats.attackSpeed - self.bonusSecondaryStats.attackSpeed
    self.bonusSecondaryStats.physicalDamage = bonusSecondaryStats.physicalDamage - self.bonusSecondaryStats.physicalDamage
    self.bonusSecondaryStats.spellDamage = bonusSecondaryStats.spellDamage - self.bonusSecondaryStats.spellDamage

    self.bonusSecondaryStats.armor = bonusSecondaryStats.armor - self.bonusSecondaryStats.armor
    self.bonusSecondaryStats.evasion = bonusSecondaryStats.evasion - self.bonusSecondaryStats.evasion
    self.bonusSecondaryStats.ccResist = bonusSecondaryStats.ccResist - self.bonusSecondaryStats.ccResist
    self.bonusSecondaryStats.spellResist = bonusSecondaryStats.spellResist - self.bonusSecondaryStats.spellResist

    self.bonusSecondaryStats.movementSpeed = bonusSecondaryStats.movementSpeed - self.bonusSecondaryStats.movementSpeed
    unit:ApplyStats()
end

return UHDItem
