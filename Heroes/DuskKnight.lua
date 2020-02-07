Module("Heroes.DuskKnight", function()
    local HeroPreset = Require("HeroPreset")

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
                stealPercentage = function(_) return 0.25 end,
            },
            heavySlash = {
                id = FourCC('DK_1'),
                handler = HeavySlash,
                availableFromStart = true,
                radius = function(_) return 75 end,
                distance = function(_) return 75 end,
                baseDamage = function(_) return 30 end,
            },
            shadowLeap = {
                id = FourCC('DK_2'),
                handler = ShadowLeap,
                availableFromStart = true,
                -- radius = function(_) return 75 end,
                -- distance = function(_) return 75 end,
                -- baseDamage = function(_) return 30 end,
            },
            darkMend = {
                id = FourCC('DK_3'),
                handler = DarkMend,
                availableFromStart = true,
                baseHeal = function(_) return 20 end,
                duration = function(_) return 4 end,
                percentHeal = function(_) return 0.1 end,
            },
        }

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
        self.bonusLimit = 30
        self.duration = definition:effectDuration(caster)
        self.toSteal = definition:armorRemoved(caster)
        self.radius = definition:radius(caster)
        self.stealTimeLeft = definition:duration(caster)
        self.period = definition:period(caster)
        self.toBonus = definition:stealPercentage(caster)

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

        trigger:RegisterUnitEvent(self.caster, EVENT_UNIT_DEATH)

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
        local toStealNow = (target.toSteal - target.stolen) * self.period / self.stealTimeLeft
        target.unit:SetArmor(target.unit:GetArmor() + target.stolen)
        target.stolen = target.stolen + toStealNow
        target.unit:SetArmor(target.unit:GetArmor() - target.stolen)
        if self.bonus < self.bonusLimit then
            local toBonus = math.min(self.bonusLimit - self.bonus, toStealNow * target.toBonus)
            self.caster:SetArmor(self.caster:GetArmor() - self.bonus)
            self.bonus = self.bonus + toBonus
            self.caster:SetArmor(self.caster:GetArmor() + self.bonus)
        end
    end

    function HeavySlash:ctor(definition, caster)
        self.caster = caster
        self.radius = definition:radius(caster)
        self.distance = definition:distance(caster)
        self.baseDamage = definition:baseDamage(caster)
        self:Cast()
    end

    function HeavySlash:Cast()
        local facing = self.caster:GetFacing() * math.pi / 180
        local x = self.caster:GetX() + math.cos(facing) * self.distance
        local y = self.caster:GetY() + math.sin(facing) * self.distance

        Unit.EnumInRange(x, y, self.radius, function(unit)
            if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                self.caster:DamageTarget(unit, self.baseDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_METAL_MEDIUM_SLICE)
            end
        end)
    end

    function ShadowLeap:ctor(definition, caster)
    end

    function DarkMend:ctor(definition, caster)
        self.caster = caster
    end

    return DuskKnight
end)
