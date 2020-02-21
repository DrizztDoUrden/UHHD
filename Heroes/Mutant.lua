local Class = require("Class")
local HeroPreset = require("Core.HeroPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Log = require "Log"

local logMutant = Log.Category("Heroes\\Mutant")

local Mutant = Class(HeroPreset)

local BashingStrikes = Class(Spell)
local TakeCover = Class(Spell)
local Meditate = Class(Spell)
local Rage = Class(Spell)

function Mutant:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_MT')

    self.abilities = {
        bashingStrikes = {
            id = FourCC('MT_0'),
            handler = BashingStrikes,
            availableFromStart = true,
            params = {
                attacks = function(_, caster)
                    local value = 3
                    if caster:HasTalent("T100") then value = value + 1 end
                    return value
                end,
                attackSpeedBonus = function(_, caster)
                    local value = 0.5
                    if caster:HasTalent("T101") then value = value + 0.2 end
                    return value
                end,
                healPerHit = function(_) return 0.05 end,
                endlessRageLimit = function(_, caster)
                    if caster:HasTalent("T102") then return 7 end
                    return 0
                end,
                endlessRageHeal = function(_) return 0.02 end
            },
        },
        takeCover = {
            id = { FourCC('MT_1'), FourCC('MTD1'), },
            handler = TakeCover,
            availableFromStart = true,
            params = {
                radius = function(_) return 500 end,
                baseRedirect = function(_) return 0.3 end,
                redirectPerRage = function(_) return 0.02 end,
                manaPerHealth = function(_, caster)
                    local value = 1
                    if caster:HasTalent("T110") then value = value * 0.75 end
                    return value
                end,
                damageReduction = function(_, caster)
                    local value = 0
                    if caster:HasTalent("T111") then value = 0.15 end
                    return value
                end,
                damageReflection = function(_, caster)
                    local value = 0
                    if caster:HasTalent("T112") then value = 0.15 end
                    return value
                end,
            },
        },
        meditate = {
            id = FourCC('MT_2'),
            handler = Meditate,
            availableFromStart = true,
            params = {
                castTime = function(_) return 2 end,
                castSlow = function(_, caster)
                    local value = -0.7
                    if caster:HasTalent("T121") then value = 0 end
                    return value
                end,
                healPerRage = function(_) return 0.05 end,
                manaHealPerRage = function(_, caster)
                    local value = 0
                    if caster:HasTalent("T120") then value = value + 0.025 end
                    return value
                end,
            },
        },
        rage = {
            id = FourCC('MT_3'),
            handler = Rage,
            availableFromStart = true,
            params = {
                ragePerAttack = function(_) return 1 end,
                damagePerRage = function(_) return 1 end,
                armorPerRage = function(_, caster)
                    local value = -1
                    if caster:HasTalent("T130") then value = value + 0.2 end
                    return value
                end,
                startingStacks = function(_) return 3 end,
                maxStacks = function(_, caster)
                    local value = 10
                    if caster:HasTalent("T131") then value = value + 5 end
                    return value
                end,
                stackDecayTime = function(_, caster)
                    local value = 3
                    if caster:HasTalent("T132") then value = value + 1.5 end
                    return value
                end,
                meditationCooldown = function(_, caster)
                    local value = 20
                    if caster:HasTalent("T122") then value = value - 10 end
                    return value
                end,
            },
        },
    }

    self.initialTechs = {
        [FourCC("MTU0")] = 0,
        [FourCC("R001")] = 1,
        [FourCC("R002")] = 1,
    }

    self.talentBooks = {
        FourCC("MTT0"),
        FourCC("MTT1"),
        FourCC("MTT2"),
        FourCC("MTT3"),
    }

    self:AddTalent("1", "00")
    self:AddTalent("1", "01")
    self:AddTalent("1", "02")

    self:AddTalent("1", "10")
    self:AddTalent("1", "11")
    self:AddTalent("1", "12")

    self:AddTalent("1", "20")
    self:AddTalent("1", "21")
    self:AddTalent("1", "22")

    self:AddTalent("1", "30")
    self:AddTalent("1", "31")
    self:AddTalent("1", "32")

    self.basicStats.strength = 16
    self.basicStats.agility = 6
    self.basicStats.intellect = 7
    self.basicStats.constitution = 13
    self.basicStats.endurance = 8
    self.basicStats.willpower = 10
end

function BashingStrikes:Cast()
    self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed * (1 + self.attackSpeedBonus)
    self.caster:ApplyStats()
    self.caster:GetOwner():SetTechLevel(FourCC("R002"), 0)
    self.caster:SetCooldownRemaining(FourCC("MT_0"), 0)

    local function handler()
        local rage = self.caster.effects["Mutant.Rage"]
        local heal
        if not rage or rage.stacks > self.endlessRageLimit then
            self.attacks = self.attacks - 1
            heal = self.healPerHit
        else
            heal = self.endlessRageHeal
        end
        self.caster:SetHP(math.min(self.caster.secondaryStats.health, self.caster:GetHP() + heal * self.caster.secondaryStats.health))
        if self.attacks <= 0 then
            self.caster:GetOwner():SetTechLevel(FourCC("R002"), 1)
            self.caster:SetCooldownRemaining(FourCC("MT_0"), 10)
            self.caster.onDamageDealt[handler] = nil
            self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed / (1 + self.attackSpeedBonus)
            self.caster:ApplyStats()
        end
    end

    self.caster.onDamageDealt[handler] = true
end

function TakeCover:Cast()
    if not self.caster.effects["Mutant.TakeCover"] then
        self:Enable()
    else
        self:Disable()
    end
end

function TakeCover:Enable()
    self.caster:RemoveAbility(FourCC('MT_1'))
    self.caster:AddAbility(FourCC('MTD1'))
    self.caster:SetCooldownRemaining(FourCC('MTD1'), 5)
    self.caster.effects["Mutant.TakeCover"] = true

    self.handler = function(args)
        if args.recursion["Mutant.TakeCover"] then
            return
        end
        local nearest
        local nearestRange = math.huge
        WC3.Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), self.radius, function(unit)
            if unit ~= self.caster and unit:IsHero() and not self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                local range = math.sqrt((self.caster:GetX() - unit:GetX())^2 + (self.caster:GetY() - unit:GetY())^2)
                if range < nearestRange then
                    nearest = unit
                    nearestRange = range
                end
            end
        end)

        if not nearest then
            return
        end

        local damage = args.GetDamage()
        local rage = self.caster.effects["Mutant.Rage"] or {}
        local rageStacks = rage.stacks or 0
        local redirected = (self.baseRedirect + self.redirectPerRage * rageStacks) * damage

        local mpBurned = redirected / self.caster:GetMaxHP() * self.caster:GetMaxMana() * self.manaPerHealth
        local curMp = self.caster:GetMana()

        if curMp < mpBurned then
            redirected = redirected * curMp / mpBurned
            mpBurned = curMp
        end

        self.caster:SetMana(curMp - mpBurned)
        args:SetDamage((damage - redirected) * (1 - self.damageReduction))

        do
            local recursion = { ["Mutant.TakeCover"] = true, }
            for k, v in pairs(args.recursion) do recursion[k] = v end

            local toAlly = {
                value = redirected * (1 - self.damageReduction),
                isAttack = false,
                recursion = recursion,
            }
            args.source:DealDamage(nearest, toAlly)
        end

        if self.damageReflection > 0 then
            local recursion = { ["Mutant.TakeCover.Reflect"] = true, }
            for k, v in pairs(args.recursion) do recursion[k] = v end

            local toReflect = {
                value = damage.value * self.damageReflection,
                isAttack = false,
                recursion = recursion,
            }
            self.caster.source:DealDamage(nearest, toReflect)
        end
    end

    self.caster.onDamageReceived[self.handler] = true
end

function TakeCover:Disable()
    self.caster:RemoveAbility(FourCC('MTD1'))
    self.caster:AddAbility(FourCC('MT_1'))
    self.caster:SetCooldownRemaining(FourCC('MT_1'), 5)
    self.caster.effects["Mutant.TakeCover"] = nil
    self.caster.onDamageReceived[self.handler] = nil
end

function Meditate:Cast()
    local timer = WC3.Timer()
    self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed * (1 + self.castSlow)
    self.caster:ApplyStats()

    timer:Start(self.castTime, false, function()
        timer:Destroy()
        self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed * (1 - self.castSlow)
        self.caster:ApplyStats()
        local rage = self.caster.effects["Mutant.Rage"]
        if rage then
            local curHp = self.caster:GetHP()
            local percentHealed = rage.stacks * self.healPerRage
            local heal = (self.caster.secondaryStats.health - curHp) * percentHealed
            self.caster:SetHP(curHp + heal)
            if self.manaHealPerRage then
                local manaHealPart = self.manaHealPerRage * rage.stacks
                local curMp = self.caster:GetMana()
                self.caster:SetMana(curMp + manaHealPart * (self.caster:GetMaxMana() - curMp))
            end
            rage:SetStacks(0)
        end
    end)
end

function Rage:Cast()
    self.caster:GetOwner():SetTechLevel(FourCC("R001"), 0)
    self.caster:GetOwner():SetTechLevel(FourCC("MTU0"), 1)
    self.caster:SetCooldownRemaining(FourCC('MT_3'), 0)
    self.caster:SetCooldownRemaining(FourCC('MT_2'), self.meditationCooldown)
    self.caster.effects["Mutant.Rage"] = self
    self:SetStacks(self.startingStacks)

    self.handler = function()
        self:SetStacks(self.stacks + self.ragePerAttack)
    end

    self.timer = WC3.Timer()

    self.timer:Start(self.stackDecayTime, true, function()
        self:SetStacks(self.stacks - 1)
    end)

    self.caster.onDamageDealt[self.handler] = true
end

function Rage:SetStacks(value)
    value = math.min(self.maxStacks, value)
    if self.stacks == value then return end
    if self.stacks then
        self.caster.bonusSecondaryStats.weaponDamage = self.caster.bonusSecondaryStats.weaponDamage - self.damagePerRage * self.stacks
        self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor - self.armorPerRage * self.stacks
    end
    self.stacks = value
    self.caster.bonusSecondaryStats.weaponDamage = self.caster.bonusSecondaryStats.weaponDamage + self.damagePerRage * self.stacks
    self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor + self.armorPerRage * self.stacks
    self.caster:ApplyStats()
    if self.stacks <= 0 then
        self:Destroy()
    end
end

function Rage:Destroy()
    self.timer:Destroy()
    self.caster.onDamageDealt[self.handler] = nil
    self.caster:GetOwner():SetTechLevel(FourCC("R001"), 1)
    self.caster:GetOwner():SetTechLevel(FourCC("MTU0"), 0)
    self.caster:SetCooldownRemaining(FourCC('MT_3'), 20)
    self.caster.effects["Mutant.Rage"] = nil
end

return Mutant