local Class = require "Class"
local TimedEffect = require "Core.Effects.TimedEffect"
local Stats = require "Core.Stats"
local Log = require "Log"

local HeroSStatsBuff = Class(TimedEffect)

local logHeroSStatsBuff = Log.Category("Core\\Effects\\HeroSStatsBuff")

function HeroSStatsBuff:ctor(stats, target, duration)
    self.stats = stats
    TimedEffect.ctor(self, target, duration)
end

--[[HeroSStatsBuff private]]
local function AddStats(self)
    for k, v in pairs(self.stats) do
        logHeroSStatsBuff:Info(k .. " + " .. v .. ": " .. self.target.bonusSecondaryStats[k] .. " -> " .. Stats.Secondary.AddBonus[k](self.target.bonusSecondaryStats[k], v))
        self.target.bonusSecondaryStats[k] = Stats.Secondary.AddBonus[k](self.target.bonusSecondaryStats[k], v)
    end
end

--[[HeroSStatsBuff private]]
local function RemoveStats(self)
    for k, v in pairs(self.stats) do
        logHeroSStatsBuff:Info(k .. " - " .. v .. ": " .. self.target.bonusSecondaryStats[k] .. " -> " .. Stats.Secondary.SubBonus[k](self.target.bonusSecondaryStats[k], v))
        self.target.bonusSecondaryStats[k] = Stats.Secondary.SubBonus[k](self.target.bonusSecondaryStats[k], v)
    end
end

function HeroSStatsBuff:OnStart()
    if self.stats == nil then
        error("Attempt use a destroyed buff", 3)
    end
    AddStats(self)
    self.target:ApplyStats()
end

function HeroSStatsBuff:OnEnd()
    if self.stats == nil then
        error("Attempt use a destroyed buff", 3)
    end
    RemoveStats(self)
    self.target:ApplyStats()
end

function HeroSStatsBuff:UpdateStats(value)
    if self.stats == nil then
        error("Attempt use a destroyed buff", 2)
    end
    RemoveStats(self)
    self.stats = value
    AddStats(self)
    self.target:ApplyStats()
end

function HeroSStatsBuff:Destroy()
    logHeroSStatsBuff:Trace("Destroying buff")
    if self.stats == nil then
        error("Attempt to destroy buff twice", 2)
    end
    TimedEffect.Destroy(self)
    self.stats = nil
end

return HeroSStatsBuff