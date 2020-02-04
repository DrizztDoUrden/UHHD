Module("Heroes.DuskKnight", function()
    local HeroPreset = Require("HeroPreset")

    local DuskKnight = Class(HeroPreset)

    function DuskKnight:ctor()
        HeroPreset.ctor(self)

        self.unitid = FourCC('H_DK')

        self.abilities = {
            drainLight = {
                id = FourCC('Z_DK'),
                handler = function(hero) self:CastDrainLight(hero) end,
                availableFromStart = true,
                duration = function() return 3 end,
                period = function() return 0.1 end,
            }
        }

        self.basicStats.strength = 12
        self.basicStats.agility = 6
        self.basicStats.intellect = 12
        self.basicStats.constitution = 11
        self.basicStats.endurance = 8
        self.basicStats.willpower = 11
    end

    function DuskKnight:CastDrainLight(hero)
        local timer = Timer()
        local affected = {}

        local group = CreateGroup()
        GroupEnumUnitsInRange(group, hero.unit.GetX(), hero.unit.GetY(), hero.unit.GetY(), function()
            local unit = Unit.Get(GetFilterUnit())
            if unit == hero.unit then return end
            table.insert(affected, unit)
        end)
        DestroyGroup(group)

        local timeLeft = self.abilities.drainLight:duration()
        local period = self.abilities.drainLight:period();
        timer.Start(period, true, function()
            timeLeft = timeLeft - period
            if timeLeft <= 0 then
                timer:Destroy()
            end

            local i = 1
            while i <= #affected do
                if affected[i].IsInRange(hero.unit) then
                    self:ApplyDrainLight(hero, affected[i], period)
                    i = i + 1
                else
                    table.remove(affected, i)
                end
            end
        end)
    end

    function DuskKnight:ApplyDrainLight(hero, target, period)
        Log("Draining light from " .. hero.unit.GetName() .. " to " .. target:GetName() .. " for " .. period)
        -- apply effect
    end

    return DuskKnight
end)
