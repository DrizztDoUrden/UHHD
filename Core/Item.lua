
Stats = require("Core.Stats")
Class = require("Class")
All = require("WC3.All")


Item = Class()

local customItemAvailability = {
    General = "inf",
    Helmet = 1,
    BodyArmor = 1,
    Weapon = 1,
    Arms = 2,
    legs = 1}

function Item:ctor(itemid)
    All.Item.ctor(itemid)
    self.itemid = FourCC(itemid)
    self.type = "general"
    self.additionalSecondaryStats = Stats()
    self.additionalBasicStats = Stats()
    self.modules = {}
end

function Item.checkAvailabilityToAdd(unit, itemType)
    if customItemAvailability[itemType] == "inf" then
        return true
    end
end


function Item:pass()

end