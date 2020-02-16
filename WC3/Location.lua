local Class = require("Class")

local Location = Class()

function Location.SpellTarget()
    return Location(GetSpellTargetLoc())
end

function Location:ctor(...)
    if #{...} > 1 then
        self.x, self.y, self.z = ...
        self.z = self.z or 0
    else
        local loc = ...
        self.x = GetLocationX(loc)
        self.y = GetLocationY(loc)
        self.z = GetLocationZ(loc)
        RemoveLocation(loc)
    end
end

return Location