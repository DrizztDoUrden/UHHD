local Class = require("Class")
local Trigger = require("WC3.Trigger")
local Stats = require("Core.Stats")
local Hero = require("Core.Hero")
local Log = require("Log")

local HeroPreset = Class()

local logHeroPreset = Log.Category("Core\\HeroPreset")

function HeroPreset:ctor()
    self.basicStats = Stats.Basic()
    self.secondaryStats = Stats.Secondary()

    self.abilities = {}

    self.secondaryStats.health = 100
    self.secondaryStats.mana = 100
    self.secondaryStats.healthRegen = .5
    self.secondaryStats.manaRegen = 1

    self.secondaryStats.weaponDamage = 10
    self.secondaryStats.attackSpeed = .5
    self.secondaryStats.physicalDamage = 1
    self.secondaryStats.spellDamage = 1

    self.secondaryStats.armor = 0
    self.secondaryStats.evasion = 0.05
    self.secondaryStats.block = 0
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0

    self.secondaryStats.movementSpeed = 1

    self.talents = {}
end

function HeroPreset:Spawn(owner, x, y, facing)
    local hero = Hero(owner, self.unitid, x, y, facing);

    hero.baseSecondaryStats = self.secondaryStats
    hero.basicStats = self.basicStats
    hero:ApplyStats()
    hero.talents = {}
    hero.talentBooks = {}

    for k, v in pairs(self.talentBooks) do hero.talentBooks[k] = v end

    for id, talent in pairs(self.talents) do
        hero.talents[id] = talent
        owner:SetTechLevel(talent.tech, 1)
    end

    hero.abilities:AddAction(function() self:Cast(hero) end)

    for _, ability in pairs(self.abilities) do
        if ability.availableFromStart then
            hero:AddAbility(ability.id)
            hero:SetAbilityLevel(ability.id, 1)
        end
    end

    if TestBuild then
        hero:AddTalentPoint()
        hero:AddTalentPoint()
    end

    return hero
end

function HeroPreset:AddTalent(id)
    local talent = { tech = FourCC("U" .. id), }
    self.talents[FourCC("T" .. id)] = talent
    return talent
end

function HeroPreset:Cast(hero)
    local abilityId = GetSpellAbilityId()

    for _, ability in pairs(self.abilities) do
        if ability.id == abilityId then
            ability:handler(hero)
            break
        end
    end
end

return HeroPreset
