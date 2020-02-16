local Class = require("Class")

local WCRect = Class()

function WCRect:ctor(...)
    local minx, miny, maxx, maxy = ...
    self.handle = Rect(minx, miny, maxx, maxy)
end

function WCRect:Destroy()
    RemoveRect(self.handle)
end

return WCRect