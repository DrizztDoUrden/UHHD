
local WC3 = require("WC3.All")
local Class = require("Class")
local UHDItem = require("Core.UHDItem")


local Inventory = Class()

    function Inventory:ctor(owner)
        self.owner = owner
        self.customItemAvailability = {
            General = nil,
            Helmet = nil,
            BodyArmor = nil,
            Weapon = nil,
            Arms = nil,
            Legs = nil,
            Misc = nil}
        self.invetory = {}
        local triggerUnitPickUPItem = WC3.Trigger()
        triggerUnitPickUPItem:RegisterUnitPickUpItem(self.owner)
        triggerUnitPickUPItem:AddAction(function() self:SetItem(UHDItem.GetManipulatedItem()) end)
        local triggerUnitDropItem = WC3.Trigger()
        triggerUnitDropItem:RegisterUnitDropItem(self.owner)
        triggerUnitDropItem:AddAction(function() self:LeaveItem(UHDItem.GetManipulatedItem()) end)
        self.owner.toDestroy[triggerUnitDropItem] = true
        self.owner.toDestroy[triggerUnitDropItem] = true
    end

    function Inventory:SearchNewItem()
        local resultList = {}
        self.owner:EnumItems(function (item) resultList[item] = true end)
        for item in pairs(resultList) do
            if ~self:HasItem(item) then
                self.invetory = resultList
                return item
            end
        end
    end

    function Inventory:HasItem(item)
        for litem in pairs(self.invetory) do
            if item == litem then
                return true
            end
        end
        return false
    end

    function Inventory:CheckAvaileItemToAdd(item)
        local amount = 0
        local ltype = item.type
        self:EnumItems(function (locItem)
            if locItem.type == ltype then
                amount = amount + 1
            end
        end)
        if not self.customItemAvailability[ltype] then
            return true
        else
            
            if self.customItemAvailability[ltype] < amount + 1 then
                return false
            else
                return true
            end
        end
        error("Something going wrong when checking should be this item to add to the unit")
        return false
    end

    function Inventory:SetItem(item)
        -- print("New item")
        -- print(item)
        if item ~= nil then
            local maxInventory = self.owner:GetInventorySize()
            if #self.invetory <= maxInventory then
                if self:CheckAvaileItemToAdd(item) then
                    self:DressItem(item)
                else
                    self:DropItem(item)
                end
            end
        end
    end

    function Inventory:LeaveItem(item)
        if  item ~= nil then
            if self:HasItem(item) then
                item:RemoveStats(self.owner)
                self.invetory[item] = nil
            end
        end
    end

    function Inventory:EnumItems(handler)
        local i = 0
        for item in pairs(self.invetory) do
            local res, err = pcall(handler, item, i)
            i = i + 1
        end
    end

    function Inventory:DropItem(item)
        local itemSlot = self:GetItemSlot(item)
        if itemSlot == nil then
        else
            self.owner:RemoveItemFromSlot(itemSlot)
        end
    end

    function Inventory:UpdateItems()
        local resultList = {}
        self.owner:EnumItems(function (item) resultList[item] = true end)
        self.invetory = resultList
    end

    function Inventory:GetItemSlot(item)
        local resslot = nil
        self.owner:EnumItems(
        function (itemInSlot, slot)
            if itemInSlot == item then
                resslot = slot
            end
        end)
        return resslot
    end

    function Inventory:DressItem(item)
        self.invetory[item] = true
        item:AddStats(self.owner)
    end

return Inventory