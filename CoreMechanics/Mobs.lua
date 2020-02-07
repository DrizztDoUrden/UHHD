Module("Mobs", function()

    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Mobs = Class(UHDUnit)

    function Mobs:ctor(level, ...)
        UHDUnit.ctor(self, ...)
        self.levelwave = level
        self.basicStats = Stats.Basic()
        self.baseSecondaryStats = Stats.Secondary()
        self.bonusSecondaryStats = Stats.Secondary()
    end
    
    Log("Mobs load succsesfull")
    return Mobs
end)