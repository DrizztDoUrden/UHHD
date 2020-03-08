
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

    self.bonusSecondaryStats.weaponDamage = 1
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

    if UHDItem.type == "Weapon" then
        unit.baseSecondaryStats.weaponDamage = self.baseSecondaryStats.weaponDamage
    else
        unit.bonusSecondaryStats.weaponDamage = bonusSecondaryStats.weaponDamage * self.bonusSecondaryStats.weaponDamage
        -- print("WPD "..unit.bonusSecondaryStats.weaponDamage.." " ..bonusSecondaryStats.weaponDamage.." " ..self.bonusSecondaryStats.weaponDamage)
    end

    unit.bonusSecondaryStats.attackSpeed = bonusSecondaryStats.attackSpeed * self.bonusSecondaryStats.attackSpeed
    unit.bonusSecondaryStats.physicalDamage = bonusSecondaryStats.physicalDamage * self.bonusSecondaryStats.physicalDamage
    unit.bonusSecondaryStats.spellDamage = bonusSecondaryStats.spellDamage * self.bonusSecondaryStats.spellDamage

    unit.bonusSecondaryStats.armor = bonusSecondaryStats.armor + self.bonusSecondaryStats.armor
    unit.bonusSecondaryStats.evasion = 1 - (1 - bonusSecondaryStats.evasion) * (1 - self.bonusSecondaryStats.evasion)
    unit.bonusSecondaryStats.ccResist = 1 - (1 - bonusSecondaryStats.ccResist) * (1 - self.bonusSecondaryStats.ccResist)
    unit.bonusSecondaryStats.spellResist = 1 - (1 - bonusSecondaryStats.spellResist) * (1 - self.bonusSecondaryStats.spellResist)

    unit.bonusSecondaryStats.movementSpeed = bonusSecondaryStats.movementSpeed * self.bonusSecondaryStats.movementSpeed
    unit:ApplyStats()
end

function  UHDItem:RemoveStats(unit)
    local bonusSecondaryStats = unit.bonusSecondaryStats
    unit.bonusSecondaryStats.health = bonusSecondaryStats.health - self.bonusSecondaryStats.health
    unit.bonusSecondaryStats.mana = bonusSecondaryStats.mana - self.bonusSecondaryStats.mana
    unit.bonusSecondaryStats.healthRegen = bonusSecondaryStats.healthRegen - self.bonusSecondaryStats.healthRegen
    unit.bonusSecondaryStats.manaRegen = bonusSecondaryStats.manaRegen - self.bonusSecondaryStats.manaRegen

    if UHDItem.type == "Weapon" then
        unit.baseSecondaryStats.weaponDamage = 0
    else
        unit.bonusSecondaryStats.weaponDamage = bonusSecondaryStats.weaponDamage / self.bonusSecondaryStats.weaponDamage
    end

    unit.bonusSecondaryStats.attackSpeed = bonusSecondaryStats.attackSpeed / self.bonusSecondaryStats.attackSpeed
    unit.bonusSecondaryStats.physicalDamage = bonusSecondaryStats.physicalDamage / self.bonusSecondaryStats.physicalDamage
    unit.bonusSecondaryStats.spellDamage = bonusSecondaryStats.spellDamage / self.bonusSecondaryStats.spellDamage

    unit.bonusSecondaryStats.armor = bonusSecondaryStats.armor - self.bonusSecondaryStats.armor
    unit.bonusSecondaryStats.evasion = 1 - (1 - bonusSecondaryStats.evasion) / (1 - self.bonusSecondaryStats.evasion)
    unit.bonusSecondaryStats.ccResist = 1 - (1 - bonusSecondaryStats.ccResist) / (1 - self.bonusSecondaryStats.ccResist)
    unit.bonusSecondaryStats.spellResist = 1 - (1 - bonusSecondaryStats.spellResist) / (1 - self.bonusSecondaryStats.spellResist)

    unit.bonusSecondaryStats.movementSpeed = bonusSecondaryStats.movementSpeed / self.bonusSecondaryStats.movementSpeed
    unit:ApplyStats()
end

return UHDItem