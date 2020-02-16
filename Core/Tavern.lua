local Class = require("Class")
local WC3 = require("WC3.All")
local Log = require("Log")

local logTavern = Log.Category("Core\\Tavern")

local heroSpawnX = -2300
local heroSpawnY = -3400

local Tavern = Class(WC3.Unit)


function Tavern:ctor(owner, x, y, facing, heroPresets)
    WC3.Unit.ctor(self, owner, FourCC("n000"), x, y, facing)

    heroPresets[1]:Spawn(WC3.Player.Get(8), heroSpawnX, heroSpawnY, 0)

    self.owner = owner
    self.heroPresets = heroPresets
    self:AddTrigger()
end

function Tavern:AddTrigger()
    local trigger = WC3.Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
        local buying = WC3.Unit.GetBying()
        local sold = WC3.Unit.GetSold()
        local whichOwner = sold:GetOwner()
        local id = sold:GetTypeId()
        logTavern:Trace("Unit bought with id "..id)
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
