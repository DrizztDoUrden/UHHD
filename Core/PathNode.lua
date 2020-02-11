local Class = Require("Class")
local Log = Require("Log")
local WCRect = Require("WC3.Rect")
local Region = Require("WC3.Region")
local Trigger = Require("WC3.Trigger")
local Unit = Require("WC3.Unit")

local PathNode = Class()

function PathNode:ctor(x, y, prev)
    self.sizex = 200
    self.sizey = 200
    self.x = x
    self.y = y
    self.prev = prev
    self.region = Region()
    local rect = WCRect(x - self.sizex, y - self.sizey, x + self.sizex, y + self.sizey)
    self.region:AddRect(rect)
    if prev ~= nil then
        self:SetEvent()
    end
end

function PathNode:GetCenter()
    return self.x, self.y
end

function PathNode:IsUnitInNode(whichUnit)
    return self.region:IsUnitIn(whichUnit)
end

function PathNode:SetEvent(formation)
    Log(" Add trigger to path Node in"..self.x.." "..self.y)
    local trigger = Trigger()
    trigger:RegisterEnterRegion(self.region)
    trigger:AddAction(function()
        local whichunit = Unit.GetEntering()
        if self.prev then
            local x, y = self.prev:GetCenter()
            whichunit:IssueAttackPoint(x, y)
        end
        Log(" Mobs in node: "..self.x.." "..self.y)
    end)
end

return PathNode