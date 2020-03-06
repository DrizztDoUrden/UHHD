local Class = require("Class")
local Stats = require("Core.Stats")
local UHDUnit = require("Core.UHDUnit")
local WC3 = require("WC3.All")
local Log = require("Log")

local logHero = Log.Category("Core\\Hero")
local Invetory = require("Core.Inventory")
local talentsHelperId = FourCC("__TU")
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
Hero.LevelsForTalent = 5

function Hero:ctor(...)
    UHDUnit.ctor(self, ...)
    self.basicStats = Stats.Basic()
    self.baseSecondaryStats = Stats.Secondary()
    self.bonusSecondaryStats = Stats.Secondary()

    self.leveling = WC3.Trigger()
    self.leveling:RegisterHeroLevel(self)
    self.leveling:AddAction(function() self:OnLevel() end)
    self.toDestroy[self.leveling] = true

    self.abilities = WC3.Trigger()
    self.abilities:RegisterUnitSpellEffect(self)
    self.toDestroy[self.abilities] = true

    self.invetory = Invetory(self)
    self.invetory.customItemAvailability["BodyArmor"] = 1
    self.invetory.customItemAvailability["Helmet"] = 1
    self.invetory.customItemAvailability["Arms"] = 1
    self.invetory.customItemAvailability["Legs"] = 1
    self.invetory.customItemAvailability["Weapon"] = 1
    self.invetory.customItemAvailability["Misc"] = 2
    
    self.statUpgrades = {}
    self.skillUpgrades = {}
    self.talentBooks = {}
    self.talents = {}


    self.baseSecondaryStats.health = 100
    self.baseSecondaryStats.mana = 100
    self.baseSecondaryStats.healthRegen = .5
    self.baseSecondaryStats.manaRegen = 1

    self.baseSecondaryStats.weaponDamage = 10
    self.baseSecondaryStats.attackSpeed = .5
    self.baseSecondaryStats.physicalDamage = 1
    self.baseSecondaryStats.spellDamage = 1

    self.baseSecondaryStats.armor = 0
    self.baseSecondaryStats.evasion = 0.05
    self.baseSecondaryStats.ccResist = 0
    self.baseSecondaryStats.spellResist = 0

    self.baseSecondaryStats.movementSpeed = 1


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

function Hero:Destroy()
    UHDUnit.Destroy(self)
    for u in pairs(self.statUpgrades) do u:Destroy() end
    for u in pairs(self.skillUpgrades) do u:Destroy() end
end


function Hero:OnLevel()
    for _ = 1,Hero.StatsPerLevel do
        self:AddStatPoint()
    end
    local div = self:GetLevel() / Hero.LevelsForTalent
    if math.floor(div) == div then
        self:AddTalentPoint()
    end
end

function Hero:SetItem(item)
    self.invetory:SetItem(item)
end

function Hero:AddStatPoint()
    local statHelper = WC3.Unit(self:GetOwner(), statsHelperId, statsX, statsY, 0)
    self.statUpgrades[statHelper] = true

    for _, id in pairs(statUpgrades) do
        statHelper:AddAbility(id)
    end

    local trigger = WC3.Trigger()
    statHelper.toDestroy[trigger] = true

    trigger:RegisterUnitSpellEffect(statHelper)
    trigger:AddAction(function()
        self.statUpgrades[statHelper] = nil
        statHelper:Destroy()
        self:SelectNextHelper(true)
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

function Hero:AddTalentPoint()
    local talentHelper = WC3.Unit(self:GetOwner(), talentsHelperId, statsX, statsY, 0)
    self.skillUpgrades[talentHelper] = true

    for _, id in pairs(self.talentBooks) do
        talentHelper:AddAbility(id)
    end

    local trigger = WC3.Trigger()
    talentHelper.toDestroy[trigger] = true

    trigger:RegisterUnitSpellEffect(talentHelper)
    trigger:AddAction(function()
        self.skillUpgrades[talentHelper] = nil
        talentHelper:Destroy()
        local spellId = GetSpellAbilityId()
        self:SelectNextHelper(false)
        local talent = self.talents[spellId]
        talent.learned = true
        if talent.onTaken then talent:onTaken(self) end
        self:GetOwner():SetTechLevel(talent.tech, 0)
    end)
end

function Hero:SelectNextHelper(prefferStats)
    if self:GetOwner() == WC3.Player.Local then
        ClearSelection()
        if prefferStats then
            for helper in pairs(self.statUpgrades) do helper:Select() return end
            for helper in pairs(self.skillUpgrades) do helper:Select() return end
        else
            for helper in pairs(self.skillUpgrades) do helper:Select() return end
            for helper in pairs(self.statUpgrades) do helper:Select() return end
        end
        -- todo: fix selection
        -- self:Select()
    end
end

local function BonusBeforePow(base, pow, stat, bonus)
    return (base + bonus) * pow^stat
end

local function BonusMul(base, pow, stat, bonus)
    return base * pow^stat * bonus
end

local function ProbabilityBased(base, pow, stat, bonus)
    return base + bonus + (1 - base - bonus) * (1 - pow^stat)
end

function Hero:UpdateSecondaryStats()
    local gtoBase = 1.05
    local ltoBase = 0.95

    self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, gtoBase, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
    self.secondaryStats.weaponDamage = self.baseSecondaryStats.weaponDamage * self.bonusSecondaryStats.weaponDamage

    self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, math.sqrt(ltoBase), self.basicStats.agility, self.bonusSecondaryStats.evasion)
    self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, math.sqrt(gtoBase), self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

    self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, gtoBase, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

    self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.health)
    self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

    self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.health)
    self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

    self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
    self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)

    self.secondaryStats.movementSpeed = self.baseSecondaryStats.movementSpeed + self.bonusSecondaryStats.movementSpeed
    self.secondaryStats.armor = self.baseSecondaryStats.armor + self.bonusSecondaryStats.armor
end


function Hero:ApplyStats()
    self:UpdateSecondaryStats()
    self:SetStr(self.basicStats.strength, true)
    self:SetAgi(self.basicStats.agility, true)
    self:SetInt(self.basicStats.intellect, true)
    UHDUnit.ApplyStats(self)
end

function Hero:HasTalent(id)
    return self.talents[FourCC(id)].learned
end

return Hero
