local Class = require("Class")
local Timer = require("WC3.Timer")
local Trigger = require("WC3.Trigger")
local Unit = require("WC3.Unit")
local HeroPreset = require("Core.HeroPreset")
local UHDUnit = require("Core.UHDUnit")
local Log = require("Log")
local Spell = require "Core.Spell"

local logDuskKnight = Log.Category("Heroes\\Dusk Knight", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
})

local DuskKnight = Class(HeroPreset)

local DrainLight = Class(Spell)
local HeavySlash = Class(Spell)
local ShadowLeap = Class(Spell)
local DarkMend = Class(Spell)

function DuskKnight:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_DK')

    self.abilities = {
        drainLight = {
            id = FourCC('DK_0'),
            handler = DrainLight,
            availableFromStart = true,
            params = {
                radius = function(_) return 300 end,
                duration = function(_) return 2 end,
                period = function(_) return 0.1 end,
                effectDuration = function(_) return 10 end,
                armorRemoved = function(_) return 10 end,
                gainLimit = function(_) return 30 end,
                stealPercentage = function(_) return 0.25 end,
                damage = function(self, caster)
                    if caster:HasTalent("T001") then return 5 * caster.secondaryStats.spellDamage * self.params.duration(self, caster) end
                    return 0
                end,
                healLimit = function(self, caster) return 10 * caster.secondaryStats.spellDamage * self.params.duration(self, caster) end,
                damageReduction = function(_, caster)
                    if caster:HasTalent("T002") then return 0.15 end
                    return 0
                end,
                damageBuffLimit = function(_, caster)
                    if caster:HasTalent("T002") then return 0.15 end
                    return 0
                end,
            },
        },
        heavySlash = {
            id = FourCC('DK_1'),
            handler = HeavySlash,
            availableFromStart = true,
            params = {
                radius = function(_) return 125 end,
                distance = function(_) return 100 end,
                baseDamage = function(_, caster)
                    local value = 20
                    if caster:HasTalent("T011") then value = value + 15 end
                    return value * caster.secondaryStats.physicalDamage
                end,
                baseSlow = function(_) return 0.3 end,
                slowDuration = function(_) return 3 end,
                manaBurn = function(_, caster)
                    if caster:HasTalent("T010") then return 20 end
                    return 0
                end,
                vampirism = function(_, caster)
                    if caster:HasTalent("T012") then return 0.15 end
                    return 0
                end,
            },
        },
        shadowLeap = {
            id = FourCC('DK_2'),
            handler = ShadowLeap,
            availableFromStart = true,
            params = {
                period = function(_) return 0.05 end,
                duration = function(_) return 0.5 end,
                distance = function(_) return 300 end,
                baseDamage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
                push = function(_) return 100 end,
                pushDuration = function(_) return 0.5 end,
            },
        },
        darkMend = {
            id = FourCC('DK_3'),
            handler = DarkMend,
            availableFromStart = true,
            params = {
                baseHeal = function(_, caster)
                    local value = 20
                    if caster:HasTalent("T030") then value = value * 0.75 end
                    return value * caster.secondaryStats.spellDamage
                end,
                duration = function(_) return 4 end,
                percentHeal = function(_, caster)
                    local value = 0.1
                    if caster:HasTalent("T030") then value = value * 0.75 end
                    return value
                end,
                period = function(_) return 0.1 end,
                instantHeal = function(_, caster)
                    if caster:HasTalent("T030") then return 0.5 end
                    return 0
                end,
                healOverTime = function(_, caster)
                    if caster:HasTalent("T030") then return 0.75 end
                    return 1
                end,
            },
        },
    }

    self.talentBooks = {
        FourCC("DKT0"),
        FourCC("DKT1"),
        FourCC("DKT2"),
        FourCC("DKT3"),
    }

    self:AddTalent("0", "00")
    self:AddTalent("0", "01")
    self:AddTalent("0", "02")

    self:AddTalent("0", "10")
    self:AddTalent("0", "11")
    self:AddTalent("0", "12")

    self:AddTalent("0", "20")
    self:AddTalent("0", "21")
    self:AddTalent("0", "22")

    self:AddTalent("0", "30")
    self:AddTalent("0", "31").onTaken = function(_, hero)
        hero:SetManaCost(self.abilities.darkMend.id, 0, 0)
        hero:SetCooldown(self.abilities.darkMend.id, 0, hero:GetCooldown(self.abilities.darkMend.id, 0) - 3)
    end
    self:AddTalent("0", "32")

    self.basicStats.strength = 12
    self.basicStats.agility = 6
    self.basicStats.intellect = 12
    self.basicStats.constitution = 11
    self.basicStats.endurance = 8
    self.basicStats.willpower = 11
end

function DrainLight:ctor(definition, caster)
    self.affected = {}
    self.bonus = 0
    self.damageBonus = 0
    Spell.ctor(self, definition, caster)
end

function DrainLight:Cast()
    local timer = Timer()

    Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), self.radius, function(unit)
        if self.caster ~= unit and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            table.insert(self.affected, {
                unit = unit,
                stolen = 0,
                toSteal = self.armorRemoved,
                toReturn = 0,
                toBonus = self.stealPercentage,
                toStealDamage = self.damageReduction,
            })
        end
    end)

    self.durationLeft = self.duration

    timer:Start(self.period, true, function()
        if self.caster:GetHP() <= 0 then
            timer:Destroy()
            self:End()
            return
        end

        self.durationLeft = self.durationLeft - self.period
        self.healed = 0

        for _, target in pairs(self.affected) do
            if target.unit:GetHP() > 0 then
                self:Drain(target)
            end
        end

        if self.durationLeft <= 0 then
            for _, target in pairs(self.affected) do
                if target.unit:GetHP() > 0 then
                    target.unit.secondaryStats.physicalDamage = target.unit.secondaryStats.physicalDamage * (1 - target.toStealDamage)
                    target.unit:ApplyStats()
                    if self.damageBonus < self.damageBuffLimit then
                        self.caster.bonusSecondaryStats.physicalDamage = self.caster.bonusSecondaryStats.physicalDamage / (1 + self.damageBonus)
                        self.damageBonus = math.min(self.damageBuffLimit, self.damageBonus + target.toStealDamage * target.toBonus)
                        self.caster.bonusSecondaryStats.physicalDamage = self.caster.bonusSecondaryStats.physicalDamage * (1 + self.damageBonus)
                        self.caster:ApplyStats()
                    end
                end
            end

            timer:Destroy()
            self:Effect()
        end
    end)
end

function DrainLight:Effect()
    local timer = Timer()
    local trigger = Trigger()

    trigger:RegisterUnitDeath(self.caster)

    trigger:AddAction(function()
        timer:Destroy()
        trigger:Destroy()
        self:End()
    end)

    timer:Start(self.effectDuration, false, function()
        timer:Destroy()
        trigger:Destroy()
        self:End()
    end)
end

function DrainLight:End()
    for _, target in pairs(self.affected) do
        target.unit.secondaryStats.armor = target.unit.secondaryStats.armor + target.toReturn
        target.unit.secondaryStats.physicalDamage = target.unit.secondaryStats.physicalDamage / (1 - target.toStealDamage)
        target.unit:ApplyStats()
    end
    self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor - self.bonus
    self.caster.bonusSecondaryStats.physicalDamage = self.caster.bonusSecondaryStats.physicalDamage / (1 + self.damageBonus)
    self.caster:ApplyStats()
end

function DrainLight:Drain(target)
    local ticks = (self.duration // self.period)
    local toStealNow = (target.toSteal - target.stolen) / ticks
    target.unit.secondaryStats.armor = target.unit.secondaryStats.armor - toStealNow
    target.toReturn = target.toReturn + toStealNow
    target.unit:ApplyStats()
    if self.bonus < self.gainLimit then
        local toBonus = math.min(self.gainLimit - self.bonus, toStealNow * target.toBonus)
        self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor + toBonus
        self.caster:ApplyStats()
        self.bonus = self.bonus + toBonus
    end
    if self.damage > 0 then
        local damagePerTick = self.damage / ticks
        local damage = self.caster:DealDamage(target.unit, { value = damagePerTick, })
        if self.healed < self.healLimit / ticks then
            local toHeal = math.min(self.healLimit / ticks - self.healed, self.stealPercentage * damage)
            self.healed = self.healed + toHeal
            self.caster:Heal(self.caster, toHeal)
        end
    end
end

function HeavySlash:Cast()
    local facing = self.caster:GetFacing() * math.pi / 180
    local x = self.caster:GetX() + math.cos(facing) * self.distance
    local y = self.caster:GetY() + math.sin(facing) * self.distance
    local affected = {}

    Unit.EnumInRange(x, y, self.radius, function(unit)
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            local damage = self.caster:DealDamage(unit, { value = self.baseDamage, isAttack = true, })
            if self.manaBurn > 0 then unit:SetMana(math.max(0, unit:GetMana() - self.manaBurn)) end
            if self.vampirism > 0 then self.caster:Heal(self.caster, self.vampirism * damage) end

            if unit:IsA(UHDUnit) then
                affected[unit] = true
                unit.secondaryStats.movementSpeed = unit.secondaryStats.movementSpeed * (1 - self.baseSlow)
                unit.secondaryStats.attackSpeed = unit.secondaryStats.attackSpeed * (1 - self.baseSlow)
                unit:ApplyStats()
            end
        end
    end)

    local timer = Timer()
    timer:Start(self.slowDuration, false, function()
        timer:Destroy()
        for unit in pairs(affected) do
            unit.secondaryStats.movementSpeed = unit.secondaryStats.movementSpeed / (1 - self.baseSlow)
            unit.secondaryStats.attackSpeed = unit.secondaryStats.attackSpeed / (1 - self.baseSlow)
            unit:ApplyStats()
        end
    end)
end

function ShadowLeap:Cast()
    local timer = Timer()
    local timeLeft = self.duration
    local affected = {}
    local pushTicks = math.floor(self.pushDuration / self.period);
    local targetX = GetSpellTargetX()
    local targetY = GetSpellTargetY()
    local targetDistance = math.sqrt((targetX - self.caster:GetX())^2 + (targetY - self.caster:GetY())^2)
    local selfPush = math.min(targetDistance, self.distance) / math.floor(self.duration / self.period)
    local castAngle = math.atan(targetY - self.caster:GetY(), targetX - self.caster:GetX())

    local selfPushX = selfPush * math.cos(castAngle)
    local selfPushY = selfPush * math.sin(castAngle)
    timer:Start(self.period, true, function()
        if timeLeft <= -self.pushDuration then
            timer:Destroy()
        end
        if timeLeft > 0 then
            self.caster:SetX(self.caster:GetX() + selfPushX)
            self.caster:SetY(self.caster:GetY() + selfPushY)
            Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), 75, function (unit)
                if not affected[unit] and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                    local angle = math.atan(self.caster:GetY() - unit:GetY(), self.caster:GetX() - unit:GetX())
                    affected[unit] = {
                        x = self.push * math.cos(angle) / pushTicks,
                        y = self.push * math.sin(angle) / pushTicks,
                        ticksLeft = pushTicks,
                    }
                    self.caster:DealDamage(unit, { value = self.baseDamage, isAttack = true, })
                end
            end)
        end
        timeLeft = timeLeft - self.period
        for unit, push in pairs(affected) do
            unit:SetX(unit:GetX() + push.x)
            unit:SetY(unit:GetY() + push.y)
            push.ticksLeft = push.ticksLeft - 1
            if push.ticksLeft == 0 then
                affected[unit] = nil
            end
        end
    end)
end

function DarkMend:Cast()
    local timer = Timer()
    local timeLeft = self.duration
    local ticks = self.duration // self.period
    self.caster:Heal(self.caster, (self.caster:GetHP() * self.percentHeal + self.baseHeal) * self.instantHeal)
    timer:Start(self.period, true, function()
        local curHp = self.caster:GetHP();
        if curHp <= 0 then
            timer:Destroy()
            return
        end
        self.caster:Heal(self.caster, ((curHp * self.percentHeal + self.baseHeal) / ticks) * self.healOverTime)
        timeLeft = timeLeft - self.period
        if timeLeft <= 0 then
            timer:Destroy()
        end
    end)
end

return DuskKnight