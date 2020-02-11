local Class = Require("Class")
local UHDUnit = Require("Core.UHDUnit")

local Creep = Class(UHDUnit)

    function Creep:Destroy()
        UHDUnit.Destroy(self)
    end

return Creep