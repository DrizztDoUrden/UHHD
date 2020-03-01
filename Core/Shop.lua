local Class = require("Class")
local WC3 = require("WC3.All")
local Log = require("Log")

local logShop = Log.Category("Core\\Shop")


local Shop = Class(WC3.Unit)


function Shop:ctor(owner, x, y, facing)
    WC3.Unit.ctor(self, owner, FourCC("n001"), x, y, facing)
    self.owner = owner
    self:AddTrigger()
end

function Shop:AddTrigger()
    local trigger = WC3.Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterSoldItem(self)
    trigger:AddAction(function()
        local buying = WC3.Unit.GetBying()
        local sold = WC3.Item.GetSold()
        local whichOwner = buying:GetOwner()
        local id = sold:GetTypeId()
        logShop:Trace("Item bought with id "..id)
    end)
end


return Shop