local Class = Require("Class")
local Log = Require("Log")
local Unit = Require("WC3.Unit")

local Trigger = Class()

function Trigger:ctor()
    self.handle = CreateTrigger()
end

function Trigger:Destroy()
    DestroyTrigger(self.handle)
end

function Trigger:RegisterPlayerUnitEvent(player, event, filter)
    if filter then
        filter = function()
            local result, errOrRet = pcall(filter, Unit.Get(GetFilterUnit()))
            if not result then
                Log("Error filtering player units for and event: " .. errOrRet)
                return false
            end
            return errOrRet
        end
    end
    return TriggerRegisterPlayerUnitEvent(self.handle, player.handle, event, Filter(filter))
end

function Trigger:RegisterUnitEvent(unit, event)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, event)
end

    function Trigger:TriggerRegisterEnterRegion(region, filter)
        if filter then
            filter = function ()
                local result, errOrRet
                if not result then
                    Log("Error filtering Region for and event: "..errOrRet)
                    return false
                end
                return errOrRet
            end
        end
        return TriggerRegisterEnterRegion(self.handle, region.handle, filter)
    end

    function Trigger:AddAction(action)
        return TriggerAddAction(self.handle, function()
            local result, err = pcall(action)
            if not result then
                Log("Error running trigger action: " .. err)
            end
        end)
    end
end

return Trigger