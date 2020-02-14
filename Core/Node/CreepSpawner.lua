local Log = require("Log")
local Class = require("Class")
local Node = require("Core.Node.Node")
local levelCreepsComopsion, nComposion, aComposition, maxlevel = require("Core.WaveSpecification")
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
    Log("Max level: "..maxlevel)
    self.levelCreepsComopsion = levelCreepsComopsion
    self.nComposion = nComposion
    self.maxlevel = maxlevel
    self.aComposition = aComposition
end

function CreepSpawner:GetWaveSpecification(level)
    local result_CreepsComposition = self.levelCreepsComopsion[level]
    local result_nComposion = self.nComposion[level]
    local result_aComposion = self.aComposition[level]
    return result_CreepsComposition, result_nComposion, result_aComposion
end

function CreepSpawner:IsANextWave(level)
    if level < self.maxlevel then
        return true
    end
    return false
end

function CreepSpawner:SpawnNewWave(level)
    -- logCreepSpawner:Info("WAVE "..self.level + 1)
    local CreepsComposition, nComposion, aComposition = self:GetWaveSpecification(level)
    local acc = 0
    for i, CreepName in pairs(CreepsComposition) do
        for j = 1, nComposion[i] do
            local creepPresetClass = CreepClasses[CreepName]
            local creepPreset = creepPresetClass()
            local creep = creepPreset:Spawn(self.owner, self.x, self.y, self.facing)
            local x, y = self.prev:GetCenter()
            creep:IssueAttackPoint(x, y)
            acc = acc + 1
        end
    end
    return acc
end

Log("CreepSpawner load succsesfull")
return CreepSpawner