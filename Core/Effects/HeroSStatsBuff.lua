local Class = require "Class"
local TimedEffect = require "Core.Effects.TimedEffect"
local Stats = require "Core.Stats"

local HeroSStatsBuff = Class(TimedEffect)

function HeroSStatsBuff:ctor(stats, target, duration)
    self.stats = stats
    TimedEffect.ctor(self, target, duration)
end

function HeroSStatsBuff:AddStats()
    for k, v in pairs(self.stats) do
        self.target.secondaryStats[k] = Stats.Secondary.AddBonus[k](self.target.secondaryStats[k], v)
    end
end

function HeroSStatsBuff:RemoveStats()
    for k, v in pairs(self.stats) do
        self.target.secondaryStats[k] = Stats.Secondary.SubBonus[k](self.target.secondaryStats[k], v)
    end
end

function HeroSStatsBuff:OnStart()
    self:AddStats()
    self.target:ApplyStats()
end

function HeroSStatsBuff:OnEnd()
    self:RemoveStats()
    self.target:ApplyStats()
end

function HeroSStatsBuff:UpdateStats(value)
    self:RemoveStats()
    self.stats = value
    self:AddStats()
    self.target:ApplyStats()
end

return HeroSStatsBuff