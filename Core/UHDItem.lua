
Stats = require("Core.Stats")
Class = require("Class")
All = require("WC3.All")


local UHDItem = Class()


function UHDItem:ctor(itemid)
    All.Item.ctor(self, FourCC(itemid))
    self.itemid = FourCC(itemid)
    self.type = "general"
    self.additionalSecondaryStats = Stats()
    self.additionalBasicStats = Stats()
    self.modules = {}
end


return UHDItem
