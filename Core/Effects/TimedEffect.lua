local Class = require "Class"
local WC3 = require "WC3.All"

local TimedEffect = Class()

function TimedEffect:ctor(target, duration)
    self.timer = WC3.Timer()
    self.timer:Start(duration, false, function() self:Destroy() end)
    self.target = target
    target.effects[self] = true
    self:OnStart()
end

function TimedEffect:OnStart()
    error("TimedEffect:OnStart not implemented. target: " .. self.target:GetName(), 2)
end

function TimedEffect:OnEnd()
    error("TimedEffect:OnEnd not implemented: " .. self.target:GetName(), 2)
end

function TimedEffect:Destroy()
    self:OnEnd()
    self.timer:Destroy()
    self.target.effects[self] = nil
end

return TimedEffect