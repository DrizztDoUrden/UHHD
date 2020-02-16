local Class = require("Class")
local Unit = require("WC3.Unit")
local Trigger = require("WC3.Trigger")
local Log = require("Log")

local logTavern = Log.Category("Core\\Tavern")

local heroSpawnX = 100
local heroSpawnY = -1600

local Tavern = Class(Unit)

function Tavern:ctor(owner, x, y, facing, heroPresets)
    Unit.ctor(self, owner, FourCC("n000"), x, y, facing)

    self.owner = owner
    self.heroPresets = heroPresets

    for _, hero in pairs(heroPresets) do
        logTavern:Info(hero.unitid, "==", FourCC("H_DK"), " is ", hero.unitid == FourCC("H_DK"))
        logTavern:Info(self:GetTypeId(), "==", FourCC("n000"), " is ", self:GetTypeId() == FourCC("n000"))
        self:AddUnitToStock(hero.unitid)
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
        local id = whicUnit:GetTypeId()
        whicUnit:Destroy()
        for _, hero in pairs(self.heroPresets) do
            if hero.unitid == id then
                hero:Spawn(whichOwner, heroSpawnX, heroSpawnY, 0)
                return
            end
        end
    end)
end


return Tavern
