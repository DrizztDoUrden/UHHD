local Class = Require("Class")
local Log = Require("Log")
local Timer = Require("WC3.Timer")
local Trigger = Require("WC3.Trigger")
local Creep = Require("Core.Creep")
local CreepSpawner = Require("Core.CreepSpawner")



local WaveObserver = Class()

function WaveObserver:ctor(owner)
    self.creepsSpawner1 = CreepSpawner({{0,700},{0,0},{700,0}})
    self.creepsSpawner2 = CreepSpawner({{0,700},{0,1400},{700,1400}})
    local trigger = Trigger()
    trigger:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    trigger:AddAction(function()
        local whichcreep = Creep.Get(GetDyingUnit())
        whichcreep:Destroy()
    end)
    local wavetimer  = Timer()
    Log(" Create Timer")
    wavetimer:Start(5, true, function()
        Log(" Try strart new wave")
        if self.creepsSpawner1:IsANextWave() then
            self.creepsSpawner1:SpawnNewWave(owner, 0)
            self.creepsSpawner2:SpawnNewWave(owner, 0)
        else
            Log("No waves")
            wavetimer:Destroy()
        end
    end)
end
return WaveObserver
