local Class = require("Class")
local Stats = require("Core.Stats")
local WC3 = require("WC3.All")
local Log = require("Log")

local logUnit = Log.Category("Core\\Unit")

local UHDUnit = Class(WC3.Unit)

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
    self.onDamageReceived = {}
end

function UHDUnit:CheckSecondaryStat0_1(name)
    if self.secondaryStats[name] < 0 or self.secondaryStats[name] > 1 then
        logUnit:Error("Value of " .. name .. " of " .. self:GetName() .. " can't be outside of [0;1]")
        self.secondaryStats[name] = math.min(1, math.max(0, self.secondaryStats[name]))
    end
end

function UHDUnit:ApplyStats()
    local oldMaxHp = self:GetMaxHP()
    local oldMaxMana = self:GetMaxMana()
    local oldHp = self:GetHP()
    local oldMana = self:GetMana()

    self:CheckSecondaryStat0_1("evasion")
    self:CheckSecondaryStat0_1("ccResist")
    self:CheckSecondaryStat0_1("spellResist")

    self:SetMaxHealth(self.secondaryStats.health)
    self:SetMaxMana(self.secondaryStats.mana)
    self:SetBaseDamage(self.secondaryStats.weaponDamage * self.secondaryStats.physicalDamage)
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

function UHDUnit:DamageDealt(args)
    for handler in pairs(self.onDamageDealt) do
        handler(args)
    end
end

function UHDUnit:DamageReceived(args)
    for handler in pairs(self.onDamageReceived) do
        handler(args)
    end
end

function UHDUnit:DealDamage(target, damage)
    local dmg = damage.value
    if damage.isAttack then
        dmg = damage.value * (1 - UHDUnit.armorValue^target.secondaryStats.armor)
    else
        dmg = damage.value * (1 - target.secondaryStats.spellResist)
    end
    local args = {
        source = self,
        target = target,
        recursion = damage.recursion or {},
        isAttack = damage.isAttack,
        GetDamage = function() return dmg end,
        SetDamage = function(_, value) dmg = value end,
    }
    self:DamageDealt(args)
    if target:IsA(UHDUnit) then target:DamageDealt(args) end
    self:DamageTarget(target, dmg, false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_UNKNOWN, WEAPON_TYPE_WHOKNOWS)
    return dmg
end

function UHDUnit:Heal(target, value)
    target:SetHP(math.min(self.secondaryStats.health, target:GetHP() + value))
end

local unitDamaging = WC3.Trigger()
for i=0,23 do unitDamaging:RegisterPlayerUnitDamaging(WC3.Player.Get(i)) end
unitDamaging:AddAction(function()
    local damageType = BlzGetEventDamageType()
    if damageType == DAMAGE_TYPE_UNKNOWN then
        return
    end
    local source = WC3.Unit.GetEventDamageSource()
    local target = WC3.Unit.GetEventDamageTarget()
    local args = {
        source = source,
        target = target,
        recursion = {},
        isAttack = true, --todo
        GetDamage = function() return GetEventDamage() end,
        SetDamage = function(_, value) BlzSetEventDamage(value) end
    }
    if source:IsA(UHDUnit) then source:DamageDealt(args) end
    if target:IsA(UHDUnit) then target:DamageReceived(args) end
end)

return UHDUnit