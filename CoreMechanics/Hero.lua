Module("Hero", function()
    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Hero = Class(UHDUnit)

    function Hero:ctor(...)
        UHDUnit.ctor(self, ...)
        self.basicStats = Stats.Basic()
        self.baseSecondaryStats = Stats.Secondary()
        self.bonusSecondaryStats = Stats.Secondary()
    end

    local function BonusBeforePow(base, pow, stat, bonus)
        return (base + bonus) * pow^stat
    end

    local function BonusMul(base, pow, stat, bonus)
        return base * pow^stat * (1 + bonus)
    end

    local function ProbabilityBased(base, pow, stat, bonus)
        return base + bonus + (1 - base - bonus) * (1 - pow^stat)
    end

    function Hero:UpdateSecondaryStats()
        self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, 1.05, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
        self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

        self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, 0.95, self.basicStats.agility, self.bonusSecondaryStats.evasion)
        self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, 1.05, self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

        self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, 1.05, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

        self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, 1.05, self.basicStats.constitution, self.bonusSecondaryStats.health)
        self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, 1.05, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

        self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, 1.05, self.basicStats.endurance, self.bonusSecondaryStats.health)
        self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, 1.05, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

        self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, 0.99, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
        self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, 0.99, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
    end

    function Hero:SetBasicStats(value)
        self.basicStats = value
        self:UpdateSecondaryStats()
        self:ApplyStats()
    end

    function Hero:ApplyStats()
        self:SetStr(self.basicStats.strength, true)
        self:SetAgi(self.basicStats.agility, true)
        self:SetInt(self.basicStats.intellect, true)
        UHDUnit.ApplyStats(self)
    end

    return Hero
end)
