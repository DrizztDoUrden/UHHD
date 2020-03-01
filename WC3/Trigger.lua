local Class = require("Class")
local Log = require("Log")
local Unit = require("WC3.Unit")

local logTrigger = Log.Category("WC3\\Trigger")

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
                logTrigger:Error("Error filtering player units for and event: " .. errOrRet)
                return false
            end
            return errOrRet
        end
    end
    return TriggerRegisterPlayerUnitEvent(self.handle, player.handle, event, Filter(filter))
end

function Trigger:RegisterUnitSold(unit)
    TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_SELL)
end

function Trigger:RegisterSoldItem(unit)
    TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_PLAYER_UNIT_SELL_ITEM)
end

function Trigger:RegisterUnitDeath(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_DEATH)
end

function Trigger:RegisterUnitPickUpItem(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_PICKUP_ITEM)
end

function Trigger:RegisterUnitDropItem(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_DROP_ITEM)
end

function Trigger:RegisterUnitSpellEffect(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_SPELL_EFFECT)
end

function Trigger:RegisterHeroLevel(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_HERO_LEVEL)
end

function Trigger:RegisterPlayerUnitDamaging(player, filter)
    return self.RegisterPlayerUnitEvent(player.handle, EVENT_PLAYER_UNIT_DAMAGING, filter)
end

function Trigger:RegisterEnterRegion(region, filter)
    return self.RegisterEnterRegion(region.handle, filter)
end

function Trigger:AddAction(action)
    return TriggerAddAction(self.handle, function()
        local result, err = pcall(action)
        if not result then
            logTrigger:Error("Error running trigger action: " .. err)
        end
    end)
end

return Trigger