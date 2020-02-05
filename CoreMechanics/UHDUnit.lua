Module("UHDUnit", function()
    local Stats = Require("Stats")

    local UHDUnit = Class(Unit)

    function UHDUnit:ctor(...)
        Unit.ctor(self, ...)
        self.secondaryStats = Stats.Secondary()
    end

    function UHDUnit:ApplyStats()
        self:SetMaxHealth(self.secondaryStats.health)
        self:SetMaxMana(self.secondaryStats.mana)
        self:SetBaseDamage(self.secondaryStats.weaponDamage)
        self:SetAttackCooldown(1 / self.secondaryStats.attackSpeed)
        self:SetArmor(0)
    end

    return UHDUnit
end)
