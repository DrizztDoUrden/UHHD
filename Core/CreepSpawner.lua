local Log = Require("Log")
local Class = Require("Class")
local PathNode = Require("Core.PathNode")

local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("Core.WaveSpecification")
local CreepClasses = { MagicDragon = Require("Core.Creeps.MagicDragon") }

local CreepSpawner = Class()

function CreepSpawner:ctor(positions)
    Log("Construct CreepSpawner")
    self.level = 0
    self.x = 700
    self.y = 0
    self.levelCreepsComopsion = levelCreepsComopsion
    Log("in zero wave first creater is ",self.levelCreepsComopsion[1][1])
    self.nComposion = nComposion
    self.maxlevel = maxlevel
    self.aComposition = aComposition
    self.nodes = {}
    self.creeps = {}
    local prevnode = {}
    local node = {}
    for i, pos in pairs(positions) do
        if i == 1 then
            node = PathNode(pos[1], pos[2], nil)
        else
            node = PathNode(pos[1], pos[2], prevnode)
        end
        table.insert(self.nodes, node)
        prevnode = node
    end
    self.x , self.y = self.nodes[#self.nodes]:GetCenter()
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
            Log("Spawn new unit")
            local Creep = creepPreset:Spawn(owner, self.x, self.y, facing)
            table.insert(self.creeps, Creep)
        end
    end
end

Log("CreepSpawner load succsesfull")
return CreepSpawner