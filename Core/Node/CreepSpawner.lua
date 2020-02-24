local Log = require("Log")
local Class = require("Class")
local Node = require("Core.Node.Node")
local waveComopsion = require("Core.WaveSpecification")
local CreepClasses = {
    MagicDragon = require("Creeps.MagicDragon")(), 
    Faceless = require("Creeps.Faceless")(),
    Ghoul = require("Creeps.Ghoul")(),
    Necromant = require("Creeps.Necromant")(),
    DefiledTree = require("Bosses.DefiledTree")()}

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
    return level <= self.maxlevel
end

function CreepSpawner:SpawnNewWave(level, herocount)
    local wave = self:GetWaveSpecification(level)
    local acc = 0
    for i, unit in pairs(wave) do
        for j = 1, unit["count"] do
            local creepPresetClass = CreepClasses[unit["unit"]]
            local creepPreset = creepPresetClass
            -- print(creepPreset)
            local creep = creepPreset:Spawn(self.owner, self.x, self.y, self.facing, level, herocount)
            -- print(creepPreset.unitid == CreepClasses.DefiledTree.unitid)
            local x, y = self.prev:GetCenter()
            -- print(creep)
            creep:OrderToAttack(x, y)
            acc = acc + 1
        end
    end
    return acc
end

Log("CreepSpawner load succsesfull")
return CreepSpawner