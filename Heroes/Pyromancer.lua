local Class = require("Class")
local HeroPreset = require("Core.HeroPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Log = require "Log"
local CreepStatsDebuff = require "Core.Effects.CreepStatsDebuff"
local HeroSStatsBuff = require "Core.Effects.HeroSStatsBuff"

local logPyromancer = Log.Category("Heroes\\Pyromancer")

local Pyromancer = Class(HeroPreset)

local BoilingBlood = Class(Spell)
local FiresOfNaalXul = Class(Spell)
local RagingFlames = Class(Spell)
local FireAndIce = Class(Spell)

Pyromancer.unitid = FourCC('H_PM')

Pyromancer.abilities = {}

Pyromancer.talentBooks = {
    FourCC("PMT0"),
    FourCC("PMT1"),
    FourCC("PMT2"),
    FourCC("PMT3"),
}

function Pyromancer:ctor()
    HeroPreset.ctor(self)

    self:AddTalent("2", "00")
    self:AddTalent("2", "01")
    self:AddTalent("2", "02")

    self:AddTalent("2", "10")
    self:AddTalent("2", "11")
    self:AddTalent("2", "12")

    self:AddTalent("2", "20")
    self:AddTalent("2", "21")
    self:AddTalent("2", "22")

    self:AddTalent("2", "30")
    self:AddTalent("2", "31")
    self:AddTalent("2", "32")

    self.basicStats.strength = 6
    self.basicStats.agility = 6
    self.basicStats.intellect = 16
    self.basicStats.constitution = 7
    self.basicStats.endurance = 14
    self.basicStats.willpower = 11
end

function BoilingBlood:Cast()
    self.target = self:GetTargetUnit()

    local existing = self.target.effects["Pyromancer.BoilingBlood"]
    if existing then
        if self.damagePartOnRefresh > 0 then
            self.caster:DealDamage(self.target, { value = existing.damage * existing.durationLeft / existing.duration * self.damagePartOnRefresh, })
        end
        existing:Destroy()
    end

    if self.spellpowerBonus > 0 then
        self.spellBuff = self.caster.effects["Pyromancer.BoilingBlood.SpellBuff"]

        if not self.spellBuff then
            self.spellBuff = HeroSStatsBuff({ spellDamage = self.spellpowerBonus, }, self.caster)
            self.caster.effects["Pyromancer.BoilingBlood.SpellBuff"] = self.spellBuff
        else
            self.spellBuff:UpdateStats({ spellDamage = self.spellBuff.stats.spellDamage + self.spellpowerBonus, })
        end
    end

    WC3.SpecialEffect({ path = "Abilities\\Spells\\Orc\\Disenchant\\DisenchantSpecialArt.mdl", target = self.target, attachPoint = "origin", lifeSpan = 15, })
    self.smoke = WC3.SpecialEffect({ path = "Doodads\\LordaeronSummer\\Props\\SmokeSmudge\\SmokeSmudge", target = self.target, attachPoint = "origin", })

    self.target.effects["Pyromancer.BoilingBlood"] = self
    self.deathHandler = function() self:Explode() end
    self.target.onDeath[self.deathHandler] = true
    self.durationLeft = self.duration
    self.timer = WC3.Timer()
    self.timer:Start(self.period, true, function() self:Tick() end)
end

local function SortByHealthDescending(array, limit)
    for i = 1,math.min(limit,#array) do
        for j = i+1,#array do
            if array[i]:GetHP() < array[j]:GetHP() then
                local tmp = array[i]
                array[i] = array[j]
                array[j] = tmp
            end
        end
    end
end

Pyromancer.abilities.boilingBlood = {
    id = FourCC('PM_0'),
    handler = BoilingBlood,
    availableFromStart = true,
    params = {
        damage = function(self, caster) return 3 * caster.secondaryStats.spellDamage * self.params.duration(self, caster) end,
        duration = function(_) return 5 end,
        period = function(_) return 0.5 end,
        explosionDamage = function(_, caster) return 10 * caster.secondaryStats.spellDamage end,
        explosionRadius = function(_) return 250 end,
        spreadLimit = function(_) return 2 end,
        healPerExplosion = function(_, caster)
            if caster:HasTalent("T200") then return 0.02 end
            return 0
        end,
        spellpowerBonus = function(_, caster)
            if caster:HasTalent("T201") then return 0.05 end
            return 0
        end,
        damagePartOnRefresh = function(_, caster)
            if caster:HasTalent("T202") then return 1 end
            return 0
        end,
    },
}

function BoilingBlood:Explode()
    if self.healPerExplosion > 0 then
        self.caster:Heal(self.caster, self.healPerExplosion * self.caster.secondaryStats.health)
    end
    local x, y = self.target:GetX(), self.target:GetY()
    WC3.SpecialEffect({ path = "Units\\Undead\\Abomination\\AbominationExplosion.mdl", x = x, y = y, })
    local targets = {}
    WC3.Unit.EnumInRange(x, y, self.explosionRadius, function(unit)
        if unit:GetHP() > 0 and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            self.caster:DealDamage(unit, { value = self.explosionDamage, })
            if unit:GetHP() > 0 then
                table.insert(targets, unit)
            end
        end
    end)
    SortByHealthDescending(targets, self.spreadLimit)
    for i = 1,math.min(self.spreadLimit,#targets) do
        BoilingBlood(Pyromancer.abilities.boilingBlood, self.caster, { unit = targets[i], })
    end
    self:Destroy()
end

function BoilingBlood:Tick()
    local ticks = self.duration // self.period
    local damage = self.damage / ticks
    self.caster:DealDamage(self.target, { value = damage, })
    self.durationLeft = self.durationLeft - self.period
    if self.durationLeft <= 0 then
        self:Destroy()
    end
end

function BoilingBlood:Destroy()
    self.timer:Destroy()
    self.target.effects["Pyromancer.BoilingBlood"] = nil
    self.target.onDeath[self.deathHandler] = nil
    self.smoke:Destroy()
    if self.spellBuff then
        local newStats = { spellDamage = self.spellBuff.stats.spellDamage - self.spellpowerBonus, }
        if newStats.spellDamage <= 1 then
            self.spellBuff:Destroy()
        else
            self.spellBuff:UpdateStats(newStats)
        end
    end
end

Pyromancer.abilities.firesOfNaalXul = {
    id = FourCC('PM_1'),
    handler = FiresOfNaalXul,
    availableFromStart = true,
    params = {
        damage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
        radius = function(_) return 200 end,
        spellResistanceDebuff = function(_) return 0.20 end,
        debuffDuration = function(_) return 3 end,
        dotDuration = function(_) return 3 end,
        dotPeriod = function(_) return 0.25 end,
        dotDamage = function(_, caster)
            if caster:HasTalent("T210") then return 9 end
            return 0
        end,
        cdrPerHit = function(_, caster)
            if caster:HasTalent("T211") then return 1 end
            return 0
        end,
        damageReduction = function(_, caster)
            if caster:HasTalent("T212") then return 0.15 end
            return 0
        end,
    },
}

function FiresOfNaalXul:Cast()
    local x, y = self:GetTargetX(), self:GetTargetY()
    local timer = WC3.Timer()
    timer:Start(0.2, false, function()
        WC3.SpecialEffect({ path = "Abilities\\Spells\\Human\\FlameStrike\\FlameStrike1.mdl", x = x, y = y, })
        local hits = 0
        WC3.Unit.EnumInRange(x, y, self.radius, function(unit)
            if unit:GetHP() > 0 and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                self.caster:DealDamage(unit, { value = self.damage, })
                if unit:GetHP() > 0 then
                    local debuff = {
                        spellResist = -self.spellResistanceDebuff,
                        physicalDamage = -self.damageReduction,
                        spellDamage = -self.damageReduction,
                    }
                    CreepStatsDebuf(debuff, unit, self.debuffDuration)
                end
            end
        end)
        if self.cdrPerHit > 0 and hits > 0 then
            self.caster:SetCooldownRemaining(Pyromancer.abilities.firesOfNaalXul, math.max(0, self.caster:GetCooldownRemaining(Pyromancer.abilities.firesOfNaalXul) - self.cdrPerHit * hits))
        end
        if self.dotDamage > 0 then
            local dot = WC3.Timer()
            local timeLeft = self.dotDuration
            local ticks = self.dotDuration // self.dotPeriod
            local damagePerTick = self.dotDamage / ticks
            dot:Start(self.dotPeriod, true, function()
                timeLeft = timeLeft - self.dotPeriod
                WC3.Unit.EnumInRange(x, y, self.radius, function(unit)
                    if unit:GetHP() > 0 and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                        self.caster:DealDamage(unit, { value = damagePerTick, })
                    end
                end)
                if timeLeft <= 0 then
                    dot:Destroy()
                end
            end)
        end
    end)
end

Pyromancer.abilities.ragingFlames = {
    id = FourCC('PM_2'),
    handler = RagingFlames,
    availableFromStart = true,
    params = {
        radius = function(_) return 250 end,
        damage = function(_, caster) return 10 * caster.secondaryStats.spellDamage end,
        implosionPeriod = function(_) return 0.05 end,
        implosionPower = function(_) return 300 end,
        channelTime = function(_, caster)
            if caster:HasTalent("T220") then return 1 end
            return 2
        end,
        implosionDuration = function(_, caster)
            if caster:HasTalent("T221") then return 1 end
            return 0
        end,
        bbSpreadLimit = function(_, caster)
            if caster:HasTalent("T222") then return 2 end
            return 0
        end,
    },
}

function RagingFlames:Cast()
    self.explosionId = 0
    self:Explode(self.caster:GetPos())
    local timer = WC3.Timer()
    local x, y = self:GetTargetX(), self:GetTargetY()
    timer:Start(self.channelTime, false, function()
        self.caster:SetPos(x, y)
        timer:Destroy()
        self.explosionId = 1
        self:Explode(x, y)
    end)
end

function RagingFlames:Explode(x, y)
    WC3.SpecialEffect({ path = "Abilities\\Spells\\Human\\FlameStrike\\FlameStrike1.mdl", x = x, y = y, })
    local targets = {}
    WC3.Unit.EnumInRange(x, y, self.radius, function(unit)
        if unit:GetHP() > 0 and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            table.insert(targets, unit)
        end
    end)
    if self.bbSpreadLimit > 0 then
        SortByHealthDescending(targets, self.bbSpreadLimit)
        for i = 1,math.min(self.bbSpreadLimit,#targets) do
            BoilingBlood(Pyromancer.abilities.boilingBlood, self.caster, { unit = targets[i], })
        end
    end
    for i = math.min(self.bbSpreadLimit,#targets),#targets do
        self.caster:DealDamage(targets[i], { value = self.damage, })
    end
    if self.implosionDuration > 0 then
        local implosion = WC3.Timer()
        local implosionTimeLeft = self.implosionDuration
        local ticks = math.floor(self.implosionDuration / self.implosionPeriod)
        local powerPerTick = self.implosionPower / ticks
        implosion:Start(self.implosionPeriod, true, function()
            WC3.Unit.EnumInRange(x, y, self.radius, function(unit)
                if unit:GetHP() > 0 and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                    local unitX, unitY = unit:GetPos()
                    local deltaX, deltaY = x - unitX, y - unitY
                    local length = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
                    if length > powerPerTick then
                        deltaX, deltaY = deltaX * powerPerTick / length, deltaY * powerPerTick / length
                    end
                    unit:SetX(unitX + deltaX, unitY + deltaY)
                end
            end)
            implosionTimeLeft = implosionTimeLeft - self.implosionPeriod
            if implosionTimeLeft <= 0 then
                implosion:Destroy()
            end
        end)
    end
end

Pyromancer.abilities.fireAndIce = {
    id = FourCC('PM_3'),
    handler = FireAndIce,
    availableFromStart = true,
    params = {
        duration = function(_) return 4 end,
        period = function(_) return 0.25 end,
        damage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
        shieldRate = function(_) return 1 end,
        shieldDuration = function(_) return 6 end,
    },
}

local FireAndIceShield = Class()

function FireAndIceShield:ctor(target)
    self.target = target
    self.amount = 0
    self.handler = function(args) self:Handler(args) end
end

function FireAndIceShield:Handler(args)
    local reduction = math.min(self.amount, args.GetDamage())
    self.amount = self.amount - reduction
    args:SetDamage(args:GetDamage() - reduction)
    if self.amount <= 0 then
        self.target.onDamageReceived[self.handler] = nil
        if self.se then
            self.se:Destroy()
            self.se = nil
        end
    end
end

function FireAndIce:Cast()
    local x, y = self.caster:GetPos()
    self.target = self:GetTargetUnit()
    local xEnd, yEnd = self.target:GetPos()
    self.lighting = WC3.LightningEffect("DRAM", false, x, y, xEnd, yEnd)
    local ticks = self.duration // self.period
    self.damagePerTick = self.damage / ticks
    self.shield = FireAndIceShield(self.caster)

    self.timer = WC3.Timer()
    local timeLeft = self.duration
    self.timer:Start(self.period, true, function()
        timeLeft = timeLeft - self.period
        if self.caster:GetHP() <= 0 or self.target:GetHP() <= 0 then
            self:Destroy()
        end
        self:Tick()
        if timeLeft <= 0 or self.target:GetHP() <= 0 then
            self:Destroy()
        end
    end)
end

function FireAndIce:Tick()
    local damage = self.caster:DealDamage(self.target, { value = self.damagePerTick, })
    local toShield = damage * self.shieldRate
    self.shield.amount = self.shield.amount + toShield
    self.caster.onDamageReceived[self.shield.handler] = true
    if not self.shield.se then
        self.shield.se = WC3.SpecialEffect({ path = "Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl", target = self.caster, attachPoint = "origin", lifeSpan = 0, })
    end
end

function FireAndIce:Destroy()
    self.lighting:Destroy()
    self.timer:Destroy()
    local shieldEnd = WC3.Timer()
    shieldEnd:Start(self.shieldDuration, false, function()
        shieldEnd:Destroy()
        self.caster.onDamageReceived[self.shield.handler] = nil
        if self.shield.se then
            self.shield.se:Destroy()
        end
    end)
end

return Pyromancer