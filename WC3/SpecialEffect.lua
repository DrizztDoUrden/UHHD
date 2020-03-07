local Class = require "Class"
local Timer = require "WC3.Timer"

local SpecialEffect = Class()

function SpecialEffect:ctor(options)
    if options.path and options.x and options.y then
        self.handle = AddSpecialEffect(options.path, options.x, options.y)
    elseif options.abilityId and options.type and options.target then
        self.handle = AddSpellEffectTargetById(options.abilityId, options.type, options.target.handle, options.attachPoint or "")
    elseif options.path and options.target then
        self.handle = AddSpecialEffectTarget (options.path, options.target.handle, options.attachPoint or "")
    else
        error("Invalid parameters configuration for WC3.SpecialEffect()", 2)
    end
    self.timer = Timer()
    if options.lifeSpan and options.lifeSpan > 0 then
        self.timer:Start(options.lifeSpan or 60, false, function() self:Destroy() end)
    end
end

function SpecialEffect:Destroy()
    if self.timer then
        self.timer:Destroy()
    end
    DestroyEffect(self.handle)
end

return SpecialEffect