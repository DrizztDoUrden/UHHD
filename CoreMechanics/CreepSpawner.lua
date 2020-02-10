Module("CreepSpawner", function()

    local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("WaveSpecification")
    local CreepClasses = {MagicDragon = Require("Creeps.MagicDragon")}


    local CreepSpawner = Class()
    local PathNode = Require("PathNode")

    function  CreepSpawner:ctor(positions)
        Log("Construct CreepSpawner")
        self.level = 0
        self.levelCreepsComopsion = levelCreepsComopsion
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
        self.x , self.y = self.nodes[#self.nodes]:GetCenterPos()
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