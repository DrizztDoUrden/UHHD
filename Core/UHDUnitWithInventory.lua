UHDUnit = require("Core.UHDUnit")
WC3 = require("WC3.All")
Class = require("Class")


local UHDUnitWInventory = Class(UHDUnit)


    function UHDUnitWInventory:ctor(...)
        self.customItemAvailability = {
            General = nil,
            Helmet = nil,
            BodyArmor = nil,
            Weapon = nil,
            Arms = nil,
            legs = nil}
        UHDUnit.ctor(...)
        self.invetory = {}
    end

    function UHDUnitWInventory:CheckAvaileItemToAdd(item)
        local amount = -1 
        local ltype = item.type
        self.EnumItems(function (locItem) 
            if locItem.type == ltype then
                amount = amount + 1
            end
        end)
        if ~self.customItemAvailability[type] then
            return true
        else
            if self.customItemAvailability[type] < amount then
                return false
            else
                return true
            end
        end
        error("Something going wrong when checking should be this item to add to the unit")
        return false
    end

    function UHDUnitWInventory:GetItem(item)
        local maxInventory = self:GetInventorySize()
        if #self.invetory <= maxInventory then
            self.invetory[item]  = true
        else
            self:LeaveItem(item)
        end
    end

    function UHDUnitWInventory:LeaveItem(item)
        local x, y = self:GetX(), self:GetY()
        item:SetPos(x, y)
    end

    function UHDUnitWInventory:EnumItems(handler)
        local i = 0
        for item in pairs(self.invetory) do
            local res, err = pcall(handler, item, i)
            i = i + 1
        end
    end

    function UHDUnitWInventory:DropItem(item)
        local itemSlot = self:GetItemSlot(item)
        self:RemoveItemFromSlot(itemSlot)
    end

    function UHDUnitWInventory:AddItemStats(item)
        local bonusSecondaryStats = item.bonusSecondaryStats
        for key, value in pairs(bonusSecondaryStats) do
            self.bonusSecondaryStats =self.bonusSecondaryStats[key]  + bonusSecondaryStats[key]
        end
        self:ApplyStats()
    end

    function UHDUnitWInventory:RemoveItemStats(item)
        local bonusSecondaryStats = item.bonusSecondaryStats
        for key, value in pairs(bonusSecondaryStats) do
            self.bonusSecondaryStats = self.bonusSecondaryStats[key] - bonusSecondaryStats[key]
        end
        self:ApplyStats()
    end

    function UHDUnitWInventory:UpdateItems()
        local resultList = {}
        UHDUnit.EnumItems(self, function (item) resultList[item] = true end)
        self.invetory = resultList
    end

    function UHDUnitWInventory:GetItemSlot(item)
        local resslot = nil
        UHDUnit.EnumItems(self, 
        function (itemInSlot, slot)
            if itemInSlot == item then
                    resslot = slot
                    return
                end
            end)
        return resslot
    end

    function UHDUnitWInventory:DressItem(item)
        self:AddItem(item)
        self:AddItemStats(item)
    end

return UHDUnitWInventory