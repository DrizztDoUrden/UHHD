Module("Creep", function()

    local UHDUnit = Require("UHDUnit")
    local Creep = Class(UHDUnit)

    function Creep:ctor(...)
        UHDUnit.ctor(self, ...)
    end

    return Creep
end)