local Class = Require("Class")
local Log = Require("Log")
local Timer = Require("WC3.Timer")
local Trigger = Require("WC3.Trigger")
local Creep = Require("Core.Creep")
local PathNode = Require("Core.Node.PathNode")
local CreepSpawner = Require("Core.Node.CreepSpawner")
local WCPlayer = Require("WC3.Player")

local logWaveObserver = Log.Category("WaveObserver\\WaveObserver", {
     printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })


local WaveObserver = Class()

function WaveObserver:ctor(owner, main_player)
    local node = PathNode(0, 0, nil)
    local node1 = PathNode(0, 700, node)
    local creepSpawner1 = CreepSpawner(owner, 700, 700, node1, 0)
    local creepSpawner2 = CreepSpawner(owner, -700, 700, node1, 0)
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
        logWaveObserver:Info("You should win")
        WCPlayer.SetPlayerVictorybyId(0)
    end
    end)

    Log(" Create Timer")
    
    wavetimer:Start(5, true, function()
        if creepSpawner1:IsANextWave(level) then
            logWaveObserver:Info("WAVE"..level)
            creepcount = creepcount + creepSpawner1:SpawnNewWave(level)
            creepcount = creepcount + creepSpawner2:SpawnNewWave(level)
            level = level + 1
            if not creepSpawner1:IsANextWave(level) then
                Log("level "..level)
                self.needtokillallcreep = true
                logWaveObserver:Info("No waves")
                wavetimer:Destroy()
            end
        end
    end)
end
return WaveObserver
