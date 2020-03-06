local Class = require "Class"
local CCEffect = require "Core.Effects.CCEffect"
local Stats = require "Core.Stats"

local CreepStatsDebuff = Class(CCEffect)

function CreepStatsDebuff:ctor(stats, target, duration)
    self.stats = stats
    CCEffect.ctor(self, target, duration)
end

function CreepStatsDebuff:OnStart()
    for k, v in pairs(self.stats) do
        if Stats.Secondary.adding[k] then
            self.target.secondaryStats[k] = self.target.secondaryStats[k] + v
        else
            self.target.secondaryStats[k] = self.target.secondaryStats[k] * v
        end
    end
end

function CreepStatsDebuff:OnEnd()
    for k, v in pairs(self.stats) do
        if Stats.Secondary.adding[k] then
            self.target.secondaryStats[k] = self.target.secondaryStats[k] - v
        else
            self.target.secondaryStats[k] = self.target.secondaryStats[k] / v
        end
    end
end

return CreepStatsDebuff