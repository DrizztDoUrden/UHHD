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
        self.target.secondaryStats[k] = Stats.Secondary.AddBonus[k](self.target.secondaryStats[k], v)
    end
    self.target:ApplyStats()
end

function CreepStatsDebuff:OnEnd()
    for k, v in pairs(self.stats) do
        self.target.secondaryStats[k] = Stats.Secondary.SubBonus[k](self.target.secondaryStats[k], v)
    end
    self.target:ApplyStats()
end

return CreepStatsDebuff