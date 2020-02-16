local Class = require("Class")
local Log = require("Log")
local WCRect = require("WC3.Rect")
local Region = require("WC3.Region")
local Node = require("Core.Node.Node")

local RectNode = Class(Node)

function RectNode:ctor(sizex, sizey, x, y, prevnode)
    Node.ctor(self, x, y, prevnode)
    self.region = Region()
    self.sizex = sizex
    self.sizey = sizey
    local rect = WCRect(x - self.sizex, y - self.sizey, x + self.sizex, y + self.sizey)
    self.region:AddRect(rect)
end

function RectNode:IsUnitInNode(whichUnit)
    return self.region:IsUnitIn(whichUnit)
end

return RectNode