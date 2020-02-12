local Class = Require("Class")
local Stats = Require("Core.Stats")
local UHDUnit = Require("Core.UHDUnit")
local Trigger = Require("WC3.Trigger")
local Unit = Require("WC3.Unit")
local Log = Require("Log")
local WCPlayer = Require("WC3.Player")

local logHero = Log.Category("Core\\Hero")

local statsHelperId = FourCC("__SU")
local statUpgrades = {
    strength = FourCC("SU_0"),
    agility = FourCC("SU_1"),
    intellect = FourCC("SU_2"),
    constitution = FourCC("SU_3"),
    endurance = FourCC("SU_4"),
    willpower = FourCC("SU_5"),
}

local Hero = Class(UHDUnit)

local statsX = 0
local statsY = -1000
Hero.StatsPerLevel = 5

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
    for _ = 1,Hero.StatsPerLevel do
        self:AddStatPoint()
    end
end

function Hero:AddStatPoint()
    local statHelper = Unit(self:GetOwner(), statsHelperId, statsX, statsY, 0)
    self.statUpgrades[statHelper] = true

    for _, id in pairs(statUpgrades) do
        statHelper:AddAbility(id)
    end

    local trigger = Trigger()
    statHelper.toDestroy[trigger] = true

    trigger:RegisterUnitSpellEffect(statHelper)
    trigger:AddAction(function()
        self.statUpgrades[statHelper] = nil
        statHelper:Destroy()
        self:SelectNextStatHelper()
        local spellId = GetSpellAbilityId()
        for stat, id in pairs(statUpgrades) do
            if id == spellId then
                self.basicStats[stat] = self.basicStats[stat] + 1
                self:UpdateSecondaryStats()
                self:ApplyStats()
                return
            end
        end
        logHero:Error("Invalid spell in stat upgrades: " .. spellId)
    end)
end

function Hero:SelectNextStatHelper()
    if self:GetOwner() == WCPlayer.Local then
        for helper in pairs(self.statUpgrades) do
            helper:Select()
            return
        end
        self:Select()
    end
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
    local gtoBase = 1.05
    local ltoBase = 0.95

    self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, gtoBase, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
    self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

    self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, math.sqrt(ltoBase), self.basicStats.agility, self.bonusSecondaryStats.evasion)
    self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, math.sqrt(gtoBase), self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

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
