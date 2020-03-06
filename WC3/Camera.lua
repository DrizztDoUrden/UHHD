local Class = require "Class"
local Player = require "WC3.Player"

local Camera = Class()

function Camera.PanTo(x, y, player, time)
    if player == nil or player == Player.Local then
        PanCameraToTimed(x, y, time or 0)
    end
end

return Camera