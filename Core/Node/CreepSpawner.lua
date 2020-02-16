local Log = require("Log")
local Class = require("Class")
local Node = require("Core.Node.Node")
local waveComopsion = require("Core.WaveSpecification")
local CreepClasses = { MagicDragon = require("Core.Creeps.MagicDragon") }

local CreepSpawner = Class(Node)

local logCreepSpawner = Log.Category("CreepSpawner\\CreepSpawnerr", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

function CreepSpawner:ctor(owner,  x, y, prevnode, facing)
    Node.ctor(self, x, y, prevnode)
    self.owner = owner
    self.facing = facing
    self.maxlevel = #waveComopsion
    logCreepSpawner:Info("Max level: "..self.maxlevel)
    self.waveComopsion = waveComopsion
end

function CreepSpawner:GetWaveSpecification(level)
    local wave = self.waveComopsion[level]
    return wave
end

function CreepSpawner:HasNextWave(level)
    return level < self.maxlevel
end

function CreepSpawner:SpawnNewWave(level)
    -- logCreepSpawner:Info("WAVE "..self.level + 1)
    local wave = self:GetWaveSpecification(level)
    local acc = 0
    for i, unit in pairs(wave) do
        for j = 1, unit["count"] do
            local creepPresetClass = CreepClasses[unit["unit"]]
            local creepPreset = creepPresetClass()
            local creep = creepPreset:Spawn(self.owner, self.x, self.y, self.facing, level)
            local x, y = self.prev:GetCenter()
            creep:IssueAttackPoint(x, y)
            acc = acc + 1
        end
    end
    return acc
end

Log("CreepSpawner load succsesfull")
return CreepSpawner