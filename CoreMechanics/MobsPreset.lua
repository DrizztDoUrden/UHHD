Module("MobsPreset", function()
    local Stats = Require("Stats")
    mob = Require("Mobs")

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

    function MobsPreset:Spawn(owner, x, y, facing)

        local unit Unit(owner, self.unitid, x, y, facing);

        mob.baseSecondaryStats = self.secondaryStats
        mob:SetBasicStats(self.basicStats)

        mob.abilities = Trigger()
        mob.abilities:RegisterPlayerUnitEvent(owner, nil)    
        return mob
    end


    return MobsPreset

end)