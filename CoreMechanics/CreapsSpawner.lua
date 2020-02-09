Module("CreepsSpawner", function()

    local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("WaveSpecification")
    local CreepClasses = {{"Creeps.MagicDragon", Require("Creeps.MagicDragon")}}

    local CreepSpawner = Class()


    function  CreepSpawner:ctor()
        Log("Construct CreepSpawner")
        self.level = 0
        self.levelCreepsComopsion = levelCreepsComopsion
        Log("in zero wave first creater is ",self.levelCreepsComopsion[1][1])
        self.nComposion = nComposion
        self.maxlevel = maxlevel
        self.aComposition = aComposition
    end

    function CreepSpawner:GetNextWaveSpecification()        
        local nextlevel = self.level + 1

        Log(" get next wave specification"..nextlevel)
        local result_CreepsComposition = self.levelCreepsComopsion[nextlevel]
        Log(" first wave Creep is "..result_CreepsComposition[1])
        local result_nComposion = self.nComposion[nextlevel]
        Log(" count first wave Creep is "..result_nComposion[1])
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

    function CreepSpawner:loadCreeps(nameofCreeps)
        for i, value in pairs(CreepsClasses) do
            if nameofCreeps == value[1] then
                return value[2]
            end
        end
    end

    function CreepSpawner:SpawnNewWave(owner, x, y, facing)
        Log("Spawn new wave")
        Log("   posx"..x)
        Log("   poxy"..y)
        Log("   facing"..facing)
        local CreepsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
        for i, CreepName in pairs(CreepsComposition) do
            Log(CreepName)
            for j =1, nComposion[i], 1
             do
                Log("Read Class Preset")
                local CreepPreset = self:loadCreeps(CreepName)
                Log("initialize CreepPreset")
                local CreepPreset = CreepPreset()
                Log("Spawn new unit")
                local Creep = CreepPreset:Spawn(owner, x, y, facing)
            end
        end
        Log("Wave was Spawn")
    end

    Log("CreepsSpawner load succsesfull")
    return CreepSpawner

end)