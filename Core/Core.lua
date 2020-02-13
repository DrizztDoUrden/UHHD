local Class = Require("Class")
local Unit = Require("WC3.Unit")
local Trigger = Require("WC3.Trigger")
local Player = Require("WC3.Player")

local wcplayer = Class(Player)
local Core = Class(Unit)

function Core:ctor(...)
    local owner, x, y, facing = ... 
    self.unitid = FourCC('__HC')

    Unit.ctor(self, owner, self.unitid, x, y, facing)

    self:SetMaxHealth(200)
    self:SetArmor(0)

    local trigger = Trigger()
    trigger:RegisterUnitDeath(self)
    trigger:AddAction(function() wcplayer.PlayersEndGame(false) end)
end


return Core