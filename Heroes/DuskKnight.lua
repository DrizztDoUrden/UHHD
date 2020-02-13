local Class = Require("Class")
local Timer = Require("WC3.Timer")
local Trigger = Require("WC3.Trigger")
local Unit = Require("WC3.Unit")
local HeroPreset = Require("Core.HeroPreset")
local UHDUnit = Require("Core.UHDUnit")
local Log = Require("Log")

local logDuskKnight = Log.Category("Heroes\\Dusk Knight", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
})

local DuskKnight = Class(HeroPreset)

local DrainLight = Class()
local HeavySlash = Class()
local ShadowLeap = Class()
local DarkMend = Class()

function DuskKnight:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_DK')

    self.abilities = {
        drainLight = {
            id = FourCC('DK_0'),
            handler = DrainLight,
            availableFromStart = true,
            radius = function(_) return 300 end,
            duration = function(_) return 2 end,
            period = function(_) return 0.1 end,
            effectDuration = function(_) return 10 end,
            armorRemoved = function(_) return 10 end,
            gainLimit = function(_) return 30 end,
            stealPercentage = function(_) return 0.25 end,
            damage = function(_, caster)
                if caster:HasTalent("T001") then return 5 * caster.secondaryStats.spellDamage end
                return 0
            end,
            healLimit = function(_, caster) return 10 * caster.secondaryStats.spellDamage end
        },
        heavySlash = {
            id = FourCC('DK_1'),
            handler = HeavySlash,
            availableFromStart = true,
            radius = function(_, caster)
                local value = 125
                if caster:HasTalent("T010") then value = value + 50 end
                return value
            end,
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
        shadowLeap = {
            id = FourCC('DK_2'),
            handler = ShadowLeap,
            availableFromStart = true,
            period = function(_) return 0.05 end,
            duration = function(_) return 0.5 end,
            distance = function(_) return 300 end,
            baseDamage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
            push = function(_) return 100 end,
            pushDuration = function(_) return 0.5 end,
        },
        darkMend = {
            id = FourCC('DK_3'),
            handler = DarkMend,
            availableFromStart = true,
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
    }

    self.talentBooks = {
        FourCC("DKT0"),
        FourCC("DKT1"),
        -- FourCC("DKT2"),
        FourCC("DKT3"),
    }

    self:AddTalent("000")
    self:AddTalent("001")
    self:AddTalent("002")

    self:AddTalent("010")
    self:AddTalent("011")
    self:AddTalent("012")

    self:AddTalent("020")
    self:AddTalent("021")
    self:AddTalent("022")

    self:AddTalent("030")
    self:AddTalent("031").onTaken = function(_, hero) hero:SetManaCost(self.abilities.darkMend.id, 1, 0) hero:SetCooldown(self.abilities.darkMend.id, 1, hero:GetCooldown(self.abilities.darkMend.id) - 3) end
    self:AddTalent("032")

    self.basicStats.strength = 12
    self.basicStats.agility = 6
    self.basicStats.intellect = 12
    self.basicStats.constitution = 11
    self.basicStats.endurance = 8
    self.basicStats.willpower = 11
end

function DrainLight:ctor(definition, caster)
    self.caster = caster
    self.affected = {}
    self.bonus = 0
    self.bonusLimit = definition:gainLimit(caster)
    self.duration = definition:effectDuration(caster)
    self.toSteal = definition:armorRemoved(caster)
    self.radius = definition:radius(caster)
    self.stealTimeLeft = definition:duration(caster)
    self.period = definition:period(caster)
    self.toBonus = definition:stealPercentage(caster)
    self.damage = definition:damage(caster)
    self.healLimit = definition:healLimit(caster)

    self:Cast()
end

function DrainLight:Cast()
    local timer = Timer()

    Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), self.radius, function(unit)
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            table.insert(self.affected, {
                unit = unit,
                stolen = 0,
                toSteal = self.toSteal,
                toReturn = self.toSteal,
                toBonus = 0.25,
            })
        end
    end)

    timer:Start(self.period, true, function()
        if self.caster:GetHP() <= 0 then
            timer:Destroy()
            self:End()
            return
        end

        self.stealTimeLeft = self.stealTimeLeft - self.period
        self.healed = 0

        for _, target in pairs(self.affected) do
            self:Drain(target)
        end

        if self.stealTimeLeft <= 0 then
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

    timer:Start(self.duration, false, function()
        timer:Destroy()
        trigger:Destroy()
        self:End()
    end)
end

function DrainLight:End()
    for _, target in pairs(self.affected) do
        target.unit:SetArmor(target.unit:GetArmor() + target.toReturn)
    end
    self.caster:SetArmor(self.caster:GetArmor() - self.bonus)
end

function DrainLight:Drain(target)
    local parts = math.floor(self.stealTimeLeft / self.period)
    local toStealNow = (target.toSteal - target.stolen) / parts
    target.unit:SetArmor(target.unit:GetArmor() + target.stolen)
    target.stolen = target.stolen + toStealNow
    target.unit:SetArmor(target.unit:GetArmor() - target.stolen)
    if self.bonus < self.bonusLimit then
        local toBonus = math.min(self.bonusLimit - self.bonus, toStealNow * target.toBonus)
        self.caster:SetArmor(self.caster:GetArmor() - self.bonus)
        self.bonus = self.bonus + toBonus
        self.caster:SetArmor(self.caster:GetArmor() + self.bonus)
    end
    if self.damage > 0 then
        local damagePerTick = self.period * self.damage
        self.caster:DamageTarget(target.unit, damagePerTick, false, true, ATTACK_TYPE_HERO, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
        if self.healed < self.healLimit * self.period then
            local toHeal = math.min(self.healLimit * self.period - self.healed, self.toSteal * damagePerTick)
            self.healed = self.healed + toHeal
            self.caster:SetHP(math.min(self.caster:GetMaxHP(), self.caster:GetHP() + toHeal))
        end
    end
end

function HeavySlash:ctor(definition, caster)
    self.caster = caster
    self.radius = definition:radius(caster)
    self.distance = definition:distance(caster)
    self.baseDamage = definition:baseDamage(caster)
    self.baseSlow = definition:baseSlow(caster)
    self.slowDuration = definition:slowDuration(caster)
    self.manaBurn = definition:manaBurn(caster)
    self.vampirism = definition:vampirism(caster)
    self:Cast()
end

function HeavySlash:Cast()
    local facing = self.caster:GetFacing() * math.pi / 180
    local x = self.caster:GetX() + math.cos(facing) * self.distance
    local y = self.caster:GetY() + math.sin(facing) * self.distance
    local affected = {}

    Unit.EnumInRange(x, y, self.radius, function(unit)
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            self.caster:DamageTarget(unit, self.baseDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_METAL_MEDIUM_SLICE)
            if self.manaBurn > 0 then unit:SetMana(math.max(0, unit:GetMana() - self.manaBurn)) end
            if self.vampirism > 0 then self.caster:SetHP(math.min(self.caster.GetMaxHP(), self.vampirism * self.baseDamage)) end

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

function ShadowLeap:ctor(definition, caster)
    self.caster = caster
    self.period = definition:period(caster)
    self.duration = definition:duration(caster)
    self.distance = definition:distance(caster)
    self.baseDamage = definition:baseDamage(caster)
    self.push = definition:push(caster)
    self.pushDuration = definition:pushDuration(caster)
    self:Cast()
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
                    self.caster:DamageTarget(unit, self.baseDamage, false, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_METAL_MEDIUM_SLICE)
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

function DarkMend:ctor(definition, caster)
    self.caster = caster
    self.baseHeal = definition:baseHeal(caster)
    self.duration = definition:duration(caster)
    self.percentHeal = definition:percentHeal(caster)
    self.period = definition:period(caster)
    self.instantHeal = definition:instantHeal(caster)
    self.healOverTime = definition:healOverTime(caster)
    self:Cast()
end

function DarkMend:Cast()
    local timer = Timer()
    local timeLeft = self.duration
    local curHp = self.caster:GetHP();
    local part = 1 / math.floor(self.period / self.duration)
    self.caster:SetHP(math.min(self.caster:GetMaxHP(), curHp + (curHp * self.percentHeal + self.baseHeal) * self.instantHeal))
    timer:Start(self.period, true, function()
        local curHp = self.caster:GetHP();
        if curHp <= 0 then
            timer:Destroy()
            return
        end
        timeLeft = timeLeft - self.period
        self.caster:SetHP(math.min(self.caster:GetMaxHP(), curHp + (curHp * self.percentHeal + self.baseHeal) * part * self.healOverTime))
        if timeLeft <= 0 then
            timer:Destroy()
        end
    end)
end

return DuskKnight