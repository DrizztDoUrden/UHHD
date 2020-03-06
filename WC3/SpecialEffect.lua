local Class = require "Class"
local Timer = require "WC3.Timer"

local SpecialEffect = Class()

function SpecialEffect:ctor(options)
    self.handle = AddSpecialEffect(options.path, options.x, options.y)
    self.timer = Timer()
    self.timer:Start(options.lifeSpan or 60, false, function() self:Destroy() end)
end

function SpecialEffect:Destroy()
    self.timer:Destroy()
    DestroyEffect(self.handle)
end

return SpecialEffect