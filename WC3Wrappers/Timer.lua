do
    Timer = Class()
    
    function Timer:ctor(handle)
        self.handle = CreateTimer()
    end

    function Timer:Destroy()
        DestroyTimer(self.handle)
    end

    function Timer:Start(period, periodic, onEnd)
        TimerStart(self.handle, period, periodic, onEnd)
    end
end
