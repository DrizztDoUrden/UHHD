local Class = Require("Class")
local Log = Require("Log")
local Timer = Require("WC3.Timer")
local Trigger = Require("WC3.Trigger")
local Creep = Require("Core.Creep")
local PathNode = Require("Core.Node.PathNode")
local CreepSpawner = Require("Core.Node.CreepSpawner")

local logWaveObserver = Log.Category("WaveObserver\\WaveObserver", {
    -- printVerbosity = Log.Verbosity.Trace,
    -- fileVerbosity = Log.Verbosity.Trace,
    })


local WaveObserver = Class()

function WaveObserver:ctor(owner)
    local node = PathNode(0, 0, nil)
    local node1 = PathNode(0, 700, node)
    local creepSpawner1 = CreepSpawner(700, 700, node1)
    local creepSpawner2 = CreepSpawner(-700, 700, node1)
    local trigger = Trigger()
    self.needtokillallcreep = false
    local creepcount = 0
    trigger:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    trigger:AddAction(function()
        local whichcreep = Creep.GetDying()
        whichcreep:Destroy()
        creepcount = creepcount - 1
    end)
    local wavetimer  = Timer()
    
    local triggercheckalldead = Trigger()
    triggercheckalldead:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    triggercheckalldead:AddAction(function ()
    if creepcount == 0 and self.needtokillallcreep then
        logWaveObserver:Info("Players Win")
    end
    end)

    Log(" Create Timer")
    
    wavetimer:Start(25, true, function()
        if creepSpawner1:IsANextWave() then
            creepcount = creepcount + creepSpawner1:SpawnNewWave(owner, 0)
            creepcount = creepcount + creepSpawner2:SpawnNewWave(owner, 0)
        else
            self.needtokillallcreep = true
            wavetimer:Destroy()
        end
    end)
end
return WaveObserver
