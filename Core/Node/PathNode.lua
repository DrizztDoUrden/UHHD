local Class = Require("Class")
local Log = Require("Log")

local Trigger = Require("WC3.Trigger")
local Unit = Require("WC3.Unit")
local Creep = Require("Core.Creep")
local RectNode = Require("Core.Node.RectNode")
local PathNode = Class(RectNode)
function PathNode:ctor(x, y, prev)
    RectNode.ctor(self, 100, 100, x, y, prev)
    if prev ~= nil then
        self:SetEvent()
    end
end


function PathNode:SetEvent(formation)
    Log(" Add trigger to path Node in"..self.x.." "..self.y)
    local trigger = Trigger()
    trigger:RegisterEnterRegion(self.region)
    trigger:AddAction(function()
        local whichunit = Unit.GetEntering()
        if self.prev and whichunit:IsA(Creep) then
            local x, y = self.prev:GetCenter()
            whichunit:IssueAttackPoint(x, y)
        end
    end)
end

return PathNode