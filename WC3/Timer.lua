local Class = Require("Class")
local Log = Require("Log")

local Timer = Class()

function Timer:ctor(handle)
    self.handle = CreateTimer()
end

function Timer:Destroy()
    DestroyTimer(self.handle)
end

function Timer:Start(period, periodic, onEnd)
    TimerStart(self.handle, period, periodic, function()
        local result, err = pcall(onEnd)
        if not result then
            Log("Error running timer handler: " .. err)
        end
    end)
end

return Timer