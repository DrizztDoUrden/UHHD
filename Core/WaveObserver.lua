local Class = Require("Class")
local Log = Require("Log")
local Timer = Require("WC3.Timer")
local Trigger = Require("WC3.Trigger")
local Creep = Require("Core.Creep")
local PathNode = Require("Core.Node.PathNode")
local CreepSpawner = Require("Core.Node.CreepSpawner")



local WaveObserver = Class()

function WaveObserver:ctor(owner)
    local node = PathNode(0, 0, nil)
    local node1 = PathNode(0, 700, node)
    local creepSpawner1 = CreepSpawner(700, 700, node1)
    local creepSpawner2 = CreepSpawner(-700, 700, node1)
    local trigger = Trigger()
    trigger:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    trigger:AddAction(function()
        local whichcreep = Creep.GetDying()
        whichcreep:Destroy()
    end)
    local wavetimer  = Timer()
    Log(" Create Timer")
    wavetimer:Start(25, true, function()
        Log(" Try strart new wave")
        if creepSpawner1:IsANextWave() then
            Log("Spaw from crSp1")
            creepSpawner1:SpawnNewWave(owner, 0)
            Log("Spaw from crSp2")
            creepSpawner2:SpawnNewWave(owner, 0)
        else
            Log("No waves")
            wavetimer:Destroy()
        end
    end)
end
return WaveObserver
