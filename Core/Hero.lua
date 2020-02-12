local Class = Require("Class")
local Stats = Require("Core.Stats")
local UHDUnit = Require("Core.UHDUnit")
local Trigger = Require("WC3.Trigger")
local Unit = Require("WC3.Unit")

local Hero = Class(UHDUnit)

local statsHelperId = FourCC("__SU")

function Hero:ctor(...)
    UHDUnit.ctor(self, ...)
    self.basicStats = Stats.Basic()
    self.baseSecondaryStats = Stats.Secondary()
    self.bonusSecondaryStats = Stats.Secondary()

    self.leveling = Trigger()
    self.leveling:RegisterHeroLevel(self)
    self.leveling:AddAction(function() self:OnLevel() end)

    self.abilities = Trigger()
    self.abilities:RegisterUnitSpellEffect(self)

    self.statUpgrades = {}
    self.skillUpgrades = {}
end

function Hero:Destroy()
    UHDUnit.Destroy(self)
    self.leveling:Destroy()
    self.abilities:Destroy()
    for u in pairs(self.statUpgrades) do u:Destroy() end
    for u in pairs(self.skillUpgrades) do u:Destroy() end
end

function Hero:OnLevel()
    local statHelper = Unit(self:GetOwner(), statsHelperId, 0, 0, 0)
    self.statUpgrades[statHelper] = true
end

local function BonusBeforePow(base, pow, stat, bonus)
    return (base + bonus) * pow^stat
end

local function BonusMul(base, pow, stat, bonus)
    return base * pow^stat * (1 + bonus)
end

local function ProbabilityBased(base, pow, stat, bonus)
    return base + bonus + (1 - base - bonus) * (1 - pow^stat)
end

function Hero:UpdateSecondaryStats()
    local gtoBase = 1.02
    local ltoBase = 0.98

    self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, gtoBase, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
    self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

    self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, ltoBase, self.basicStats.agility, self.bonusSecondaryStats.evasion)
    self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, gtoBase, self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

    self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, gtoBase, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

    self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.health)
    self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

    self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.health)
    self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

    self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
    self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
end

function Hero:SetBasicStats(value)
    self.basicStats = value
    self:UpdateSecondaryStats()
    self:ApplyStats()
end

function Hero:ApplyStats()
    self:SetStr(self.basicStats.strength, true)
    self:SetAgi(self.basicStats.agility, true)
    self:SetInt(self.basicStats.intellect, true)
    UHDUnit.ApplyStats(self)
end

return Hero
