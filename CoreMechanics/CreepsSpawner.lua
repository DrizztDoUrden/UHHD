Module("CreepsSpawner", function()

    local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("WaveSpecification")
    local CreepClasses = {MagicDragon = Require("Creeps.MagicDragon")}

    local CreepSpawner = Class()
    local PathNodes = Require("PathNode")

    function  CreepSpawner:ctor()
        Log("Construct CreepSpawner")
        self.level = 0
        self.x = 0
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
        node1:SetEvent()
        node:SetEvent(function()
            Log("excute event got next node")
            for i, creep in pairs(self.creeps) do
                if node1:IsUnitInRegion(creep) then
                    if node1:IsPrevNode() then
                        local x, y = node1:GetPrevCenterPos()
                        creep:IssueAttackPoint(x, y)
                    end
                end
            end
        end)
        table.insert(self.nodes, node)
        table.insert(self.nodes, node1)
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
        Log("   posx"..self.x)
        Log("   poxy"..self.y)
        Log("   facing"..facing)
        local CreepsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
        for i, CreepName in pairs(CreepsComposition) do
            Log(CreepName)
            for j =1, nComposion[i], 1
             do
                Log("Read Class Preset")
                local CreepPresetClass = CreepClasses[CreepName]
                Log("initialize CreepPreset")
                local creepPreset = CreepPresetClass()
                Log("Spawn new unit")
                local Creep = creepPreset:Spawn(owner, self.x, self.y, facing)
                table.insert(self.creeps, Creep)
            end
        end
        Log("Wave was Spawn")
    end

    Log("CreepsSpawner load succsesfull")
    return CreepSpawner

end)