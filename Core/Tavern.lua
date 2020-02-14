local Class = require("Class")
local Unit = require("WC3.Unit")
local Trigger = require("WC3.Trigger")
local Log = require("Log")

local logTavern = Log.Category("Core\\Tavern")

local statsX = 0
local statsY = -1000

local Tavern = Class(Unit)

function Tavern:ctor(owner, x, y, facing, heroPresets)
    Unit.ctor(self, owner, FourCC("n000"), x, y, facing)

    self.owner = owner
    self.heroPresets = heroPresets
    for _, hero in pairs(heroPresets) do
        logTavern:Info(hero.unitid)
        self:AddUnitToStock(hero.unitid, 1, 1)
    end
    self:AddTrigger()
end

function Tavern:AddTrigger()
    local trigger = Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
        local whicUnit = Unit.GetSold()
        local whichOwner = whicUnit:GetOwner()
        for _, hero in pairs(self.heroPresets) do
            if hero.unitid == whicUnit:GetTypeId() then
                hero:Spawn(whichOwner, 100, -1600, 0)
            end
        end
        whicUnit:Destroy()
    end)
end


return Tavern
