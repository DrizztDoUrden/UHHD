local Class = require("Class")
local Stats = require("Core.Stats")
local WC3 = require("WC3.All")

local UHDUnit = Class(WC3.Unit)

local hpRegenAbility = FourCC('_HPR')
local mpRegenAbility = FourCC('_MPR')

UHDUnit.armorValue = 0.06

function UHDUnit:ctor(...)
    WC3.Unit.ctor(self, ...)
    self.secondaryStats = Stats.Secondary()
    self.effects = {}

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
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0

    self.secondaryStats.movementSpeed = 1

    self.onDamageDealt = {}

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
    self:SetMoveSpeed(self.secondaryStats.movementSpeed)

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

function UHDUnit:DamageDealt()
    local args = {
        source = self
    }
    for handler in pairs(self.onDamageDealt) do
        handler(args)
    end
end

function UHDUnit:DealDamage(target, damage)
    local dmg = damage.value
    if damage.isAttack then
        dmg = damage.value * (1 - math.pow(UHDUnit.armorValue, target.secondaryStats.armor))
    else
        dmg = damage.value * (1 - target.secondaryStats.spellResist)
    end
    local hpAfterDamage = target:GetHP() - dmg
    if hpAfterDamage < 0 then
        hpAfterDamage = 0
        dmg = dmg + hpAfterDamage
    end
    target:SetHP(hpAfterDamage)
    self:DamageDealt()
    return dmg
end

local unitDamaging = WC3.Trigger()
for i=0,23 do unitDamaging:RegisterPlayerUnitDamaging(WC3.Player.Get(i)) end
unitDamaging:AddAction(function()
    local source = WC3.Unit.GetEventDamageSource()
    if source.IsA(UHDUnit) then source:DamageDealt() end
end)

return UHDUnit