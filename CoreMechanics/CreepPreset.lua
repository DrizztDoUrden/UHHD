Module("CreepPreset", function()

    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Creep = Class(UHDUnit)
    local CreepPreset = Class()

    function CreepPreset:ctor()
        self.secondaryStats = Stats.Secondary()

        self.secondaryStats.health = 50
        self.secondaryStats.mana = 2
        self.secondaryStats.healthRegen = 1
        self.secondaryStats.manaRegen = 1

        self.secondaryStats.weaponDamage = 15
        self.secondaryStats.attackSpeed = 2
        self.secondaryStats.physicalDamage = 1
        self.secondaryStats.spellDamage = 1

        self.secondaryStats.armor = 5
        self.secondaryStats.evasion = 30
        self.secondaryStats.block = 0
        self.secondaryStats.ccResist = 0
        self.secondaryStats.spellResist = 30

        self.secondaryStats.movementSpeed = 1
    end

    function CreepPreset:Spawn(owner, x, y, facing)
        Log(" CreepPreset:Spawn")
        Log(" id=", self.unitid)
        local Creep = Creep(owner, self.unitid, x, y, facing);
        Creep.secondaryStats = self.secondaryStats
        Creep:ApplyStats()
        return Creep
    end

    Log("Creep load succsesfull")
    return CreepPreset
end)