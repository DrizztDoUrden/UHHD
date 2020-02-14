local Class = Require("Class")
local Unit = Require("WC3.Unit")
local Trigger = Require("WC3.Trigger")
local HeroPreset = Require("Core.HeroPreset")
local HeroClasses = { DuskKnight = Require("Core.Creeps.DuskKnight")()}
local HeroPresets = { HeroClasses[1].unit}
local Log = Require("Log")

local statsX = 0
local statsY = -1000

local Tawern = Class(Unit)

function Tawern:ctor(...)
    local params = { ... }
    self.owner = params[1]
    Unit.ctor(self, ...)

    for _, hero in HeroClasses do
        self:AddUnitToStock(hero.unitid, 1, 1)
    end
    self:AddTrigger()
end

function Tawern:AddTrigger()
    local trigger = Trigger()
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
    local whicUnit = Unit.GetSold()
    local whichOwner = whicUnit:GetOwner()
    for _, hero in HeroClasses do
        hero:Spawn(whichOwner, 100, -1600, 0)
    end
    whicUnit:Destroy()
    end)
end


return Tawern
