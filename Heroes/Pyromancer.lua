local Class = require("Class")
local HeroPreset = require("Core.HeroPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Log = require "Log"

local logPyromancer = Log.Category("Heroes\\Mutant")

local Pyromancer = Class(HeroPreset)

local BoilingBlood = Class(Spell)
local FiresOfNaalXul = Class(Spell)
local RagingFlames = Class(Spell)
local FireAndIce = Class(Spell)

function Pyromancer:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_PM')

    self.abilities = {
        boilingBlood = {
            id = FourCC('PM_0'),
            handler = BoilingBlood,
            availableFromStart = true,
            params = {
                damagePerSecond = function(_, caster) return 5 * caster.secondaryStats.spellDamage end,
                duration = function(_) return 5 end,
                period = function(_) return 0.5 end,
                explosionDamage = function(_, caster) return 10 * caster.secondaryStats.spellDamage end,
            },
        },
        firesOfNaalXul = {
            id = { FourCC('PM_1'), },
            handler = FiresOfNaalXul,
            availableFromStart = true,
            params = {
            },
        },
        ragingFlames = {
            id = FourCC('PM_2'),
            handler = RagingFlames,
            availableFromStart = true,
            params = {
            },
        },
        fireAndIce = {
            id = FourCC('PM_3'),
            handler = FireAndIce,
            availableFromStart = true,
            params = {
            },
        },
    }

    self.talentBooks = {
        FourCC("PMT0"),
        FourCC("PMT1"),
        FourCC("PMT2"),
        FourCC("PMT3"),
    }

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
    self.basicStats.agility = 8
    self.basicStats.intellect = 15
    self.basicStats.constitution = 9
    self.basicStats.endurance = 13
    self.basicStats.willpower = 9
end

function BoilingBlood:Cast()
    self.target = self:GetTargetUnit()

    local existing = self.target.effects["Pyromancer.BoilingBlood"]

    if existing then
        existing:End()
    end

    self.target.effects["Pyromancer.BoilingBlood"] = self
    self.deathHandler = function() self:Explode() end
    self.target.onDeath[self.deathHandler] = true
    self.durationLeft = self.duration
    self.timer = WC3.Timer()
    self.timer:Start(self.period, true, function() self:Tick() end)
end

function BoilingBlood:Explode()
end

function BoilingBlood:Tick()
    self.durationLeft = self.durationLeft - self.period
    if self.durationLeft <= 0 then
        self:End()
    end
end

function BoilingBlood:End()
    self.timer:Destroy()
    self.target.effects["Pyromancer.BoilingBlood"] = nil
    self.target.onDeath[self.deathHandler] = nil
end

function FiresOfNaalXul:Cast()
end

function RagingFlames:Cast()
end

function FireAndIce:Cast()
end

return Pyromancer