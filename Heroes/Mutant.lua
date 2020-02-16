local Class = require("Class")
local HeroPreset = require("Core.HeroPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"

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
                attacks = function(_) return 3 end,
                attackSpeedBonus = function(_) return 0.5 end,
                healPerHit = function(_) return 0.05 end,
            },
        },
        takeCover = {
            id = { FourCC('MT_1'), FourCC('MTD1'), },
            handler = TakeCover,
            availableFromStart = true,
            params = {
                baseRedirect = function(_) return 0.3 end,
                redirectPerRage = function(_) return 0.02 end,
            },
        },
        meditate = {
            id = FourCC('MT_2'),
            handler = Meditate,
            availableFromStart = true,
            params = {
                healPerRage = function(_) return 0.06 end,
            },
        },
        rage = {
            id = FourCC('MT_3'),
            handler = Rage,
            availableFromStart = true,
            params = {
                ragePerAttack = function(_) return 1 end,
                damagePerRage = function(_) return 1 end,
                armorPerRage = function(_) return -1 end,
                startingStacks = function(_) return 3 end,
            },
        },
    }

    self.initialTechs = {
        [FourCC("MTU0")] = 0,
        [FourCC("R001")] = 1,
    }

    self.talentBooks = {
        -- FourCC("MTT0"),
        -- FourCC("MTT1"),
        -- FourCC("MTT2"),
        -- FourCC("MTT3"),
    }

    -- self:AddTalent("100")
    -- self:AddTalent("101")
    -- self:AddTalent("102")

    -- self:AddTalent("110")
    -- self:AddTalent("111")
    -- self:AddTalent("112")

    -- self:AddTalent("120")
    -- self:AddTalent("121")
    -- self:AddTalent("122")

    -- self:AddTalent("130")
    -- self:AddTalent("131").onTaken = function(_, hero) hero:SetManaCost(self.abilities.darkMend.id, 1, 0) hero:SetCooldown(self.abilities.darkMend.id, 1, hero:GetCooldown(self.abilities.darkMend.id, 1) - 3) end
    -- self:AddTalent("132")

    self.basicStats.strength = 16
    self.basicStats.agility = 6
    self.basicStats.intellect = 7
    self.basicStats.constitution = 13
    self.basicStats.endurance = 8
    self.basicStats.willpower = 10
end

function BashingStrikes:Cast()
    self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed + self.attackSpeedBonus

    local function handler()
        self:SetHP(math.min(self.caster.secondaryStats.health, self:GetHP() + self.healPerHit * self.caster.secondaryStats.health))
        self.hitsLeft = self.hitsLeft - 1
        if self.hitsLeft < 0 then
            self.caster.onDamageDealt[handler] = nil
            self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed - self.attackSpeedBonus
        end
    end

    self.caster.onDamageDealt[handler] = true
end

function TakeCover:Cast()
    if not self.caster.effects["mt.cover"] then
        self.caster:RemoveAbility(FourCC('MT_1'))
        self.caster:AddAbility(FourCC('MTD1'))
        self.caster:SetCooldownRemaining(FourCC('MTD1'), 5)
        self.caster.effects["mt.cover"] = true
    else
        self.caster:RemoveAbility(FourCC('MTD1'))
        self.caster:AddAbility(FourCC('MT_1'))
        self.caster:SetCooldownRemaining(FourCC('MT_1'), 5)
        self.caster.effects["mt.cover"] = nil
    end
end

function Meditate:Cast()
end

function Rage:Cast()
end

return Mutant