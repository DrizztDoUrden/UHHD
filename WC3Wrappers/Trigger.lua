do
    Trigger = Class()

    function Trigger:ctor()
        self.handle = CreateTrigger()
    end

    function Trigger:Destroy()
        DestroyTrigger(self.handle)
    end

    function Trigger:RegisterPlayerUnitEvent(player, event, filter)
        return TriggerRegisterPlayerUnitEvent(self.handle, player, event, filter)
    end

    function Trigger:AddAction(action)
        return TriggerAddAction(self.handle, action)
    end
end
