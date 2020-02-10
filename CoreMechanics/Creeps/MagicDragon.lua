Module("Creeps.MagicDragon", function()
    local CreepPreset = Require("CreepPreset")

    local MagicDragon = Class(CreepPreset)

    function MagicDragon:ctor()
        Log("Construct Magic Dragon")
        CreepPreset.ctor(self)
        self.secondaryStats.health = 15
        self.secondaryStats.mana = 15

        self.unitid = FourCC('C_MD')
        
    end
    Log("MagicDragon load successfull")
    return MagicDragon
end)