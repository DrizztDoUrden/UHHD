local Class = require "Class"
local TimedEffect = require "Core.Effects.TimedEffect"

local CCEffect = Class(TimedEffect)

function CCEffect:ctor(target, duration)
    TimedEffect.ctor(self, target, duration * (1 - target.secondaryStats.ccResist))
end

return CCEffect