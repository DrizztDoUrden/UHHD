local Class = require("Class")
local Trigger = require("WC3.Trigger")
local Stats = require("Core.Stats")
local Hero = require("Core.Hero")
local Log = require("Log")
local Copy = require "Copy"

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

    hero.baseSecondaryStats = Copy(self.secondaryStats)
    hero.basicStats = Copy(self.basicStats)
    hero:ApplyStats()
    hero.talentBooks = Copy(self.talentBooks)
    hero.talents = Copy(self.talents)

    for _, talent in pairs(self.talents) do
        owner:SetTechLevel(talent.tech, 1)
    end

    hero.abilities:AddAction(function() self:Cast(hero) end)

    for _, ability in pairs(self.abilities) do
        if ability.availableFromStart then
            if type(ability.id) == "table" then
                hero:AddAbility(ability.id[1])
            else
                hero:AddAbility(ability.id)
            end
        end
    end

    if TestBuild then
        hero:AddTalentPoint()
        hero:AddTalentPoint()
    end

    for tech, level in pairs(self.initialTechs or {}) do
        owner:SetTechLevel(tech, level)
    end

    return hero
end

function HeroPreset:AddTalent(heroId, id)
    local talent = { tech = FourCC("U0" .. id), }
    self.talents[FourCC("T" .. heroId .. id)] = talent
    return talent
end

function HeroPreset:Cast(hero)
    local abilityId = GetSpellAbilityId()

    for _, ability in pairs(self.abilities) do
        if type(ability.id) == "table" then
            for _, id in pairs(ability.id) do
                if id == abilityId then
                    ability:handler(hero)
                    break
                end
            end
        else
            if ability.id == abilityId then
                ability:handler(hero)
                break
            end
        end
    end
end

return HeroPreset
