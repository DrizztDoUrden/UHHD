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
    logTavern:Info("add unit")
    self:AddTrigger()
end

function Tavern:AddTrigger()
    local trigger = Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
        local buying = Unit.GetBying()
        local sold = Unit.GetSold()
        local whichOwner = sold:GetOwner()
        local id = sold:GetTypeId()
        logTavern:Info("Unit bought with id "..id)
        for _, hero in pairs(self.heroPresets) do
            if hero.unitid == id then
                hero:Spawn(whichOwner, heroSpawnX, heroSpawnY, 0)
                break
            end
        end
        buying:Destroy()
        sold:Destroy()
    end)
end


return Tavern
