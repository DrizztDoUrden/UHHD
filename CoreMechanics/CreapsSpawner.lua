Module("CreapsSpawner", function()
    local Stats = Require("Stats")
    local Creaps = Require("Creap")
    local levelCreapsComopsion, nComposion, aComposition, maxlevel = Require("WaveSpecification")

    local CreapsSpawner = Class()

    function  CreapsSpawner:ctor()
        Log("Construct CreapSpawner")
        self.level = 0
        self.levelCreapsComopsion = levelCreapsComopsion
        Log("in zero wave first creater is ",self.levelCreapsComopsion[1][1])
        self.nComposion = nComposion
        self.maxlevel = maxlevel
        self.aComposition = aComposition
    end

    function CreapsSpawner:GetNextWaveSpecification()        
        local nextlevel = self.level + 1

        Log(" get next wave specification", nextlevel)
        local result_CreapsComposition = self.levelCreapsComopsion[nextlevel]
        Log(" first wave creap is ", result_CreapsComposition[1])
        local result_nComposion = self.nComposion[nextlevel]
        Log(" number first wave creap is ", result_nComposion[1])
        local result_aComposion = self.aComposition[nextlevel]
 
        self.level = nextlevel
        return result_CreapsComposition, result_nComposion, result_aComposion
    end

    function CreapsSpawner:isNextLevel()
        if self.level > self.maxlevel then
            return true
        end
        return false
    end

    function CreapsSpawner:SpawnNewWave(owner, x, y, facing)
        Log("Spawn new wave")
        Log("   owner ", owner)
        Log("   posx", x)
        Log("   poxy", y)
        Log("   facing", facing)
        local CreapsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
        for i, creapName in pairs(CreapsComposition) do
            Log(creapName)
            for j =1, nComposion[i], 1
             do
                Log("intilize new creap")
                Creap = Require(creapName)
                creap = Creap()
                Log("Spawn new unit")
                creap:Spawn(owner, x, y, facing)
            end
        end

        Log("Wave was Spawn")
    end

    Log("CreapsSpawner load succsesfull")
    return CreapsSpawner

end)