local Class = require("Class")
local Log = require("Log")

local Node = Class()

function Node:ctor(x, y, prev)
    self.x = x
    self.y = y
    self.prev = prev
end

function Node:GetCenter()
    return self.x, self.y
end

return Node
