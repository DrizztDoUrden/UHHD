Module("Creaps.MagicDragon", function()
    local CreapPreset = Require("CreapPreset")

    local MagicDragon = Class(CreapPreset)

    function MagicDragon:ctor()
        Log("Construct Magic Dragon")
        CreapPreset.ctor(self)
        self.secondaryStats.health = 50
        self.secondaryStats.mana = 15

        self.unitid = FourCC('efdr')
        
    end
    Log("MagicDragon load succsesfull")
    return MagicDragon
end)