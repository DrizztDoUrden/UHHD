Module("Mobs.MagicDragon", function()
    local MobsPreset = Require("MobsPreset")

    local MagicDragon = Class(MobsPreset)

    function MagicDragon:ctor()
        MobsPreset.ctor(self)

        self.unitid = FourCC('efdr')   
    end

    return MagicDragon
end)