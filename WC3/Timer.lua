local Class = require("Class")
local Log = require("Log")

local Timer = Class()

local logTimer = Log.Category("WC3\\Timer")

function Timer:ctor()
    self.handle = CreateTimer()
end

function Timer:Destroy()
    DestroyTimer(self.handle)
end

function Timer:Start(period, periodic, onEnd)
    TimerStart(self.handle, period, periodic, function()
        local result, err = pcall(onEnd)
        if not result then
            logTimer:Error("Error running timer handler: " .. err)
        end
    end)
end

return Timer