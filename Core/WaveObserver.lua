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
    self.creepSpawner1 = CreepSpawner(owner, 1600, 5000, node1, 0)
    self.creepSpawner2 = CreepSpawner(owner, -5800, 5000, node1, 0)
    local trigger = Trigger()
    self.needtokillallcreep = false
    self.creepcount = 0
    self.level = 1
    trigger:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    trigger:AddAction(function()
        local whichcreep = Creep.GetDying()
        whichcreep:Destroy()
        self.creepcount = self.creepcount - 1
    end)
    local wavetimer  = Timer()
    
    local triggercheckalldead = Trigger()
    triggercheckalldead:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    triggercheckalldead:AddAction(function ()
    if self.creepcount == 0 and self.needtokillallcreep then
        if self.creepSpawner1:HasNextWave(self.level) then
            self.level = self.level + 1
            logWaveObserver:Info("Bos spawn")
            -- self.creepSpawner1:SpawnNewWave(self.level - 1, 2)
            -- self.creepSpawner2:SpawnNewWave(self.level - 1, 2)
            if self.creepSpawner1:HasNextWave(self.level) then
                wavetimer:Start(5, true, function()
                    self:StartGeneralWave()
                end)
            end
        else
            wcplayer.PlayersEndGame(true)
        end
    end
    end)

    Log(" Create Timer")
    wavetimer:Start(5, true, function()
        self:StartGeneralWave(wavetimer)
    end)

end

    function WaveObserver:StartGeneralWave(timer)
        if self.creepSpawner1:HasNextWave(self.level) then
            self.level = self.level + 1
            logWaveObserver:Info("WAVE"..self.level)
            self.creepcount = self.creepcount + self.creepSpawner1:SpawnNewWave(self.level - 1, 2)
            self.creepcount = self.creepcount + self.creepSpawner2:SpawnNewWave(self.level - 1, 2)
            if math.floor(self.level/10) == self.level/10 then
                self.needtokillallcreep = true
                -- logWaveObserver:Info("Next Boss")
                self:Destroy()
            end
        end
    end



return WaveObserver
