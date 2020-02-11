local Log = Require("Log")
local Class = Require("Class")
local PathNode = Require("Core.Node.PathNode")
local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("Core.WaveSpecification")
local CreepClasses = { MagicDragon = Require("Core.Creeps.MagicDragon") }

local CreepSpawner = Class(PathNode)

function CreepSpawner:ctor(x, y, prevnode)
    PathNode.ctor(self, x, y, prevnode)
    Log("Construct CreepSpawner")
    self.level = 0
    self.levelCreepsComopsion = levelCreepsComopsion
    self.nComposion = nComposion
    self.maxlevel = maxlevel
    self.aComposition = aComposition
end

function CreepSpawner:GetNextWaveSpecification()
    local nextlevel = self.level + 1

    local result_CreepsComposition = self.levelCreepsComopsion[nextlevel]
    local result_nComposion = self.nComposion[nextlevel]
    local result_aComposion = self.aComposition[nextlevel]
    self.level = nextlevel
    return result_CreepsComposition, result_nComposion, result_aComposion
end

function CreepSpawner:IsANextWave()
    if self.level + 1 > self.maxlevel then
        return false
    end
    return true
end

function CreepSpawner:SpawnNewWave(owner, facing)
    Log("WAVE"..self.level + 1)
    local CreepsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
    for i, CreepName in pairs(CreepsComposition) do
        Log(CreepName)
        for j = 1, nComposion[i] do
            local creepPresetClass = CreepClasses[CreepName]
            local creepPreset = creepPresetClass()
            local creep = creepPreset:Spawn(owner, self.x, self.y, facing)
        end
    end
end

Log("CreepSpawner load succsesfull")
return CreepSpawner