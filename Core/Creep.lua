local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local Timer = require("WC3.Timer")
local Creep = Class(UHDUnit)

    function Creep:Destroy()
        local timer = Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

return Creep