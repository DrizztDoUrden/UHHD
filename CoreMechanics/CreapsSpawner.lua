Module("CreapsSpawner", function()
    local Stats = Require("Stats")
    local Creaps = Require("Creap")
    local levelCreapsComopsion, nComposion, aComposition = Require("WaveSpecification")

    local CreapsSpawner = Class()

    function  CreapsSpawner:ctor()
        self.level = 0
        self.levelCreapsComopsion = levelCreapsComopsion
        self.nComposion = nComposion
        self.aComposition = aComposition
    end

    function CreapsSpawner:GetNextWaveSpecification()
        for i, value in ipairs(self.levelCreapsComopsion) do
            if i + 1 == self.level then
                result_CreapsComposition = value
                break
            else
                result_CreapsComposition = nil
            end
        end
        for i, value in ipairs(self.nComposion) do 
            if i + 1 == self.level then
                result_nComposion = value
                break
            else
                result_nComposion = nil
            end
        end
        for i, value in ipairs(self.aComposition) do 
            if i + 1 == self.aComposition then
                result_aComposion = value
                break
            else
                result_aComposion = nil
            end
        end
        self.level = self.level + 1
        return result_CreapsComposition, result_nComposion, result_aComposion
    end

    function CreapsSpawner:ReadStats(...)
        self.secondaryStats.health = Stats[0]
        self.secondaryStats.mana = Stats[1]
        self.secondaryStats.healthRegen = Stats[2]
        self.secondaryStats.manaRegen = Stats[3]

        self.secondaryStats.weaponDamage = Stats[4]
        self.secondaryStats.attackSpeed = Stats[5]
        self.secondaryStats.physicalDamage = Stats[6]
        self.secondaryStats.spellDamage = Stats[7]

        self.secondaryStats.armor = Stats[8]
        self.secondaryStats.evasion = Stats[9]
        self.secondaryStats.block = Stats[10]
        self.secondaryStats.ccResist = Stats[11]
        self.secondaryStats.spellResist = Stats[12]

        self.secondaryStats.movementSpeed = 1
    end

    function CreapsSpawner:SpawnNewWave(owner, x, y, facing)
        local CreapsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
        for i, creapName in ipairs(CreapsComposition) do 
            for j  in nComposion[i] do
                creap = Require(creapName)
                creap:Spawn(owner, x, y, facing)
            end
        end

        Log("Wave was Spawn")
    end

    Log("CreapsSpawner load succsesfull")
    return CreapsSpawner

end)