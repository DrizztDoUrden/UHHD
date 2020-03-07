local Class = require "Class"

local LightningEffect = Class()

function LightningEffect:ctor(code, checkVisibility, x, y, x2, y2)
    self.handle = AddLightning(code, checkVisibility, x, y, x2, y2)
end

function LightningEffect:Destroy()
    DestroyLightning(self.handle)
end

return LightningEffect