local Class = Require("Class")
local Trigger = Require("WC3.Trigger")
local Stats = Require("Core.Stats")
local Hero = Require("Core.Hero")

local HeroPreset = Class()

function HeroPreset:ctor()
    self.basicStats = Stats.Basic()
    self.secondaryStats = Stats.Secondary()
    self.unitid = FourCC('0000')

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
end

function HeroPreset:Spawn(owner, x, y, facing)
    local hero = Hero(owner, self.unitid, x, y, facing);

    hero.baseSecondaryStats = self.secondaryStats
    hero:SetBasicStats(self.basicStats)

    hero.abilities = Trigger()
    hero.abilities:RegisterUnitSpellFinish(hero)
    hero.abilities:AddAction(function() self:Cast(hero) end)

    for _, ability in pairs(self.abilities) do
        if ability.availableFromStart then
            hero:AddAbility(ability.id)
            hero:SetAbilityLevel(ability.id, 1)
        end
    end

    return hero
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