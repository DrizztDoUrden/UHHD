Module("CreepsSpawner", function()

    local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("WaveSpecification")
    local CreepClasses = {MagicDragon = Require("Creeps.MagicDragon")}


    local CreepSpawner = Class()
    local PathNode = Require("PathNode")

    function  CreepSpawner:ctor()
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
        local node = PathNode(0, 700, nil)
        local node1 = PathNode(0, 0, node)
        local node2 = PathNode(700, 0, node1)


        table.insert(self.nodes, node)
        table.insert(self.nodes, node1)
        table.insert(self.nodes, node2)
    end

    function CreepSpawner:GetNextWaveSpecification()        
        local nextlevel = self.level + 1

        Log("   get next wave specification"..nextlevel)
        local result_CreepsComposition = self.levelCreepsComopsion[nextlevel]
        Log("   first wave Creep is "..result_CreepsComposition[1])
        local result_nComposion = self.nComposion[nextlevel]
        Log("   count first wave Creep is "..result_nComposion[1])
        local result_aComposion = self.aComposition[nextlevel]
 
        self.level = nextlevel
        return result_CreepsComposition, result_nComposion, result_aComposion
    end

    function CreepSpawner:isNextLevel()
        if self.level > self.maxlevel then
            return true
        end
        return false
    end


    function CreepSpawner:SpawnNewWave(owner, facing)
        Log("Spawn new wave")
        local CreepsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
        for i, CreepName in pairs(CreepsComposition) do
            Log(CreepName)
            for j =1, nComposion[i], 1
             do
                local CreepPresetClass = CreepClasses[CreepName]
                local creepPreset = CreepPresetClass()
                Log("Spawn new unit")
                local Creep = creepPreset:Spawn(owner, self.x, self.y, facing)
                table.insert(self.creeps, Creep)
            end
        end
    end

    Log("CreepsSpawner load succsesfull")
    return CreepSpawner

end)