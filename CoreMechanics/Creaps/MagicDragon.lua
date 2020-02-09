Module("Creaps.MagicDragon", function()
    local Creap = Require("Creap")

    local MagicDragon = Class(Creap)

    function MagicDragon:ctor()
        Log("Construct Magic Dragon")
        Creap.ctor(self)
        self.secondaryStats.health = 50
        self.secondaryStats.mana = 15

        self.unitid = FourCC('efdr')
        self:ApplyStats()
    end
    Log("MagicDragon load succsesfull")
    return MagicDragon
end)