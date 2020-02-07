Module("Mobs", function()

    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Mobs = Class(UHDUnit)

    function Mobs:ctor(level, ...)
        local args = {...}
        local levelwave = level
        UHDUnit.ctor(self, ...)
        self.basicStats = Stats.Basic()
        self.baseSecondaryStats = Stats.Secondary()
        self.bonusSecondaryStats = Stats.Secondary()
    end

    

    return Mobs
end)