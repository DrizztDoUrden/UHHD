local Class = require("Class")
local Log = require("Log")
local Timer = require("WC3.Timer")
local Trigger = require("WC3.Trigger")
local Creep = require("Core.Creep")
local PathNode = require("Core.Node.PathNode")
local CreepSpawner = require("Core.Node.CreepSpawner")
local wcplayer = require("WC3.Player")

local logWaveObserver = Log.Category("WaveObserver\\WaveObserver", {
     printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })


local WaveObserver = Class()

function WaveObserver:ctor(owner)
    local node = PathNode(-2300, -3800, nil)
    local node1 = PathNode(-2300, 5000, node)
    local creepSpawner1 = CreepSpawner(owner, 1600, 5000, node1, 0)
    local creepSpawner2 = CreepSpawner(owner, -5800, 5000, node1, 0)
    local trigger = Trigger()
    self.needtokillallcreep = false
    local creepcount = 0
    local level = 1
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
        if creepSpawner1:HasNextWave(level) then
            logWaveObserver:Info("Bos spawn")
            creepSpawner1:SpawnNewWave(level, 2)
            creepSpawner2:SpawnNewWave(level, 2)
            level = level + 1
        else
            wcplayer.PlayersEndGame(true)
        end
    end
    end)

    Log(" Create Timer")
    
    wavetimer:Start(5, true, function()
        if creepSpawner1:HasNextWave(level) then
            logWaveObserver:Info("WAVE"..level)
            creepcount = creepcount + creepSpawner1:SpawnNewWave(level, 4)
            creepcount = creepcount + creepSpawner2:SpawnNewWave(level, 4)
            level = level + 1
            if math.floor(level/10) == level/10 then
                self.needtokillallcreep = true
                logWaveObserver:Info("Next Boss")
                wavetimer:Destroy()
            end
        end
    end)


end
return WaveObserver
