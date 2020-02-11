local Class = Require("Class")
local UHDUnit = Require("Core.UHDUnit")
local Timer = Require("WC3.Timer")
local Creep = Class(UHDUnit)

    function Creep:Destroy()
        local timer = Timer()
        timer:Start(5, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

return Creep