local Class = require("Class")
local HeroPreset = require("Core.HeroPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Log = require "Log"
local CreepStatsDebuf = require "Core.Effects.CreepStatsDebuff"

local logPyromancer = Log.Category("Heroes\\Pyromancer")

local Pyromancer = Class(HeroPreset)

local BoilingBlood = Class(Spell)
local FiresOfNaalXul = Class(Spell)
local RagingFlames = Class(Spell)
local FireAndIce = Class(Spell)

Pyromancer.unitid = FourCC('H_PM')

Pyromancer.abilities = {
    boilingBlood = {
        id = FourCC('PM_0'),
        handler = BoilingBlood,
        availableFromStart = true,
        params = {
            damage = function(self, caster) return 5 * caster.secondaryStats.spellDamage * self.params.duration(self, caster) end,
            duration = function(_) return 5 end,
            period = function(_) return 0.5 end,
            explosionDamage = function(_, caster) return 10 * caster.secondaryStats.spellDamage end,
            explosionRadius = function(_) return 250 end,
        },
    },
    firesOfNaalXul = {
        id = { FourCC('PM_1'), },
        handler = FiresOfNaalXul,
        availableFromStart = true,
        params = {
            damage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
            radius = function(_) return 200 end,
            spellResistanceDebuff = function(_) return 0.20 end,
        },
    },
    ragingFlames = {
        id = FourCC('PM_2'),
        handler = RagingFlames,
        availableFromStart = true,
        params = {
            radius = function(_) return 150 end,
            damage = function(_, caster) return 15 * caster.secondaryStats.spellDamage end,
            channelTime = function(_) return 2 end,
        },
    },
    fireAndIce = {
        id = FourCC('PM_3'),
        handler = FireAndIce,
        availableFromStart = true,
        params = {
            duration = function(_) return 4 end,
            period = function(_) return 0.25 end,
            channelTime = function(_) return 2 end,
            damage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
            shieldRate = function(_) return 1 end,
            shieldDuration = function(_) return 6 end,
        },
    },
}

Pyromancer.talentBooks = {
    --[[FourCC("PMT0"),
    FourCC("PMT1"),
    FourCC("PMT2"),
    FourCC("PMT3"),]]
}

function Pyromancer:ctor()
    HeroPreset.ctor(self)

    self:AddTalent("2", "00")
    self:AddTalent("2", "01")
    self:AddTalent("2", "02")

    self:AddTalent("2", "10")
    self:AddTalent("2", "11")
    self:AddTalent("2", "12")

    self:AddTalent("2", "20")
    self:AddTalent("2", "21")
    self:AddTalent("2", "22")

    self:AddTalent("2", "30")
    self:AddTalent("2", "31")
    self:AddTalent("2", "32")

    self.basicStats.strength = 6
    self.basicStats.agility = 6
    self.basicStats.intellect = 16
    self.basicStats.constitution = 7
    self.basicStats.endurance = 14
    self.basicStats.willpower = 11
end

function BoilingBlood:Cast()
    self.target = self:GetTargetUnit()

    local existing = self.target.effects["Pyromancer.BoilingBlood"]

    if existing then
        existing:Destroy()
    end

    self.target.effects["Pyromancer.BoilingBlood"] = self
    self.deathHandler = function() self:Explode() end
    self.target.onDeath[self.deathHandler] = true
    self.durationLeft = self.duration
    self.timer = WC3.Timer()
    self.timer:Start(self.period, true, function() self:Tick() end)
end

function BoilingBlood:Explode()
    WC3.Unit.EnumInRange(self.target.GetX(), self.target.GetY(), self.explosionRadius, function(unit)
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            self.caster:DealDamage(self.target, { value = self.explosionDamage, })
            BoilingBlood(Pyromancer.abilities.boilingBlood, self.caster)
        end
    end)
end

function BoilingBlood:Tick()
    local ticks = self.duration // self.period
    local damage = self.damage / ticks
    self.caster:DealDamage(self.target, { value = damage, })
    self.durationLeft = self.durationLeft - self.period
    if self.durationLeft <= 0 then
        self:Destroy()
    end
end

function BoilingBlood:Destroy()
    self.timer:Destroy()
    self.target.effects["Pyromancer.BoilingBlood"] = nil
    self.target.onDeath[self.deathHandler] = nil
end

function FiresOfNaalXul:Cast()
    WC3.Unit.EnumInRange(self.GetTargetX(), self.GetTargetY(), self.radius, function(unit)
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            self.caster:DealDamage(unit, { value = self.damage, })
            CreepStatsDebuf({ spellResist = (1 - self.spellResistanceDebuff), }, unit, self.duration)
        end
    end)
end

function RagingFlames:Cast()
end

function FireAndIce:Cast()
end

return Pyromancer