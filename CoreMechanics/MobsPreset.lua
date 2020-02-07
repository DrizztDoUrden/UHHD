Module("MobsPreset", function()
    local Stats = Require("Stats")
    local Mobs = Require("Mobs")

    local MobsPreset = Class()

    function  MobsPreset:ctor()
        self.basicStats = Stats.Basic()
        self.secondaryStats = Stats.Secondary()
        self.unitid = FourCC('0000')

        self.abilities = {}

        self.secondaryStats.health = 100
        self.secondaryStats.mana = 100
        self.secondaryStats.healthRegen = .5
        self.secondaryStats.manaRegen = 1

        self.secondaryStats.weaponDamage = 10
        self.secondaryStats.attackSpeed = .5
        self.secondaryStats.physicalDamage = 1
        self.secondaryStats.spellDamage = 1

        self.secondaryStats.armor = 0
        self.secondaryStats.evasion = 0.05
        self.secondaryStats.block = 0
        self.secondaryStats.ccResist = 0
        self.secondaryStats.spellResist = 0

        self.secondaryStats.movementSpeed = 1
    end

    function MobsPreset:Spawn(level, owner, x, y, facing)

        local mobs = Mobs(level, owner, self.unitid, x, y, facing);

        mobs.baseSecondaryStats = self.secondaryStats

        return mobs
    end

    Log("MobsPreset load succsesfull")
    return MobsPreset

end)