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
        if Stats.Secondary.adding[k] then
            self.target.bonusSecondaryStats[k] = self.target.bonusSecondaryStats[k] + v
        else
            self.target.bonusSecondaryStats[k] = self.target.bonusSecondaryStats[k] * v
        end
    end
end

function HeroSStatsBuff:RemoveStats()
    for k, v in pairs(self.stats) do
        if Stats.Secondary.adding[k] then
            self.target.bonusSecondaryStats[k] = self.target.bonusSecondaryStats[k] - v
        else
            self.target.bonusSecondaryStats[k] = self.target.bonusSecondaryStats[k] / v
        end
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