local Class = require("Class")
local WC3 = require("WC3.All")
local Log = require("Log")

local logShop = Log.Category("Core\\Shop")


local Shop = Class(WC3.Unit)


function Shop:ctor(owner, x, y, facing, itemPresets)
    WC3.Unit.ctor(self, owner, FourCC("n002"), x, y, facing)
    self.owner = owner
    self.itemPresets = itemPresets
    self:AddTrigger()
end

function Shop:AddTrigger()
    local trigger = WC3.Trigger()
    local x, y = self:GetX(), self:GetY() - 100
    self.toDestroy[trigger] = true
    trigger:RegisterPlayerSoldItem(self.owner, self)
    trigger:AddAction(function()
        local buying = WC3.Unit.GetBying()
        local sold = WC3.Item.GetSold()
        local id = sold:GetTypeId()

        sold:Destroy()
        logShop:Info("buying item id"..id)
        for _, itemPreset in pairs(self.itemPresets) do
            logShop:Info(" itemPreset itemid"..itemPreset.itemid)
            if itemPreset.itemid == id then
                local newItem = itemPreset:Create(x, y)
                buying:AddItem(newItem)
                break
            end
        end
        
        -- logShop:Trace("Item bought with id "..id)
    end)
end


return Shop