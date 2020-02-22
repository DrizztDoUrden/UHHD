local Class = require("Class")
local Log = require("Log")

local Trigger = require("WC3.Trigger")
local Unit = require("WC3.Unit")
local Creep = require("Core.Creep")
local RectNode = require("Core.Node.RectNode")
local PathNode = Class(RectNode)
function PathNode:ctor(x, y, prev)
    RectNode.ctor(self, 100, 100, x, y, prev)
    if prev ~= nil then
        self:SetEvent()
    end
end


function PathNode:SetEvent(formation)
    local trigger = Trigger()
    trigger:RegisterEnterRegion(self.region)
    trigger:AddAction(function()
        local whichunit = Unit.GetEntering()
        if self.prev and (whichunit:IsA(Creep) or whichunit:IsA(Creep))  then
            local x, y = self.prev:GetCenter()
            whichunit:OrderToAttack(x, y)
        end
    end)
end

return PathNode