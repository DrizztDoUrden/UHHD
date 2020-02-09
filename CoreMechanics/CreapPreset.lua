Module("CreapPeset", function()

    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Creap = Class(UHDUnit)
    local CreapPreset = Class()

    function CreapPreset:ctor()
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

    function CreapPreset:Spawn(owner, x, y, facing)
        Log(" CreapPreset:Spawn")
        Log(" id=", self.unitid)
        local creap = Creap(owner, self.unitid, x, y, facing);
        creap.ApplyStats(self)
        return creap
    end

    Log("Creap load succsesfull")
    return CreapPreset
end)