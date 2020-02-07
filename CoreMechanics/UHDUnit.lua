Module("UHDUnit", function()
    local Stats = Require("Stats")

    local UHDUnit = Class(Unit)

    local hpRegenAbility = FourCC('_HPR')
    local mpRegenAbility = FourCC('_MPR')

    function UHDUnit:ctor(...)
        Unit.ctor(self, ...)
        self.secondaryStats = Stats.Secondary()

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

        self:AddAbility(hpRegenAbility)
        self:AddAbility(mpRegenAbility)
    end

    function UHDUnit:ApplyStats()
        local oldMaxHp = self:GetMaxHP()
        local oldMaxMana = self:GetMaxMana()
        local oldHp = self:GetHP()
        local oldMana = self:GetMana()

        self:SetMaxHealth(self.secondaryStats.health)
        self:SetMaxMana(self.secondaryStats.mana)
        self:SetBaseDamage(self.secondaryStats.weaponDamage)
        self:SetAttackCooldown(1 / self.secondaryStats.attackSpeed)
        self:SetArmor(self.secondaryStats.armor)
        self:SetHpRegen(self.secondaryStats.healthRegen)
        self:SetManaRegen(self.secondaryStats.manaRegen)

        if oldMaxHp > 0 then
            self:SetHP(oldHp * self.secondaryStats.health / oldMaxHp)
        else
            self:SetHP(self.secondaryStats.health)
        end
        if oldMaxMana > 0 then
            self:SetMana(oldMana * self.secondaryStats.mana / oldMaxMana)
        else
            self:SetMana(self.secondaryStats.mana)
        end
    end

    return UHDUnit
end)
