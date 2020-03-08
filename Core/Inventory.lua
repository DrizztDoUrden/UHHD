
local WC3 = require("WC3.All")
local Class = require("Class")
local UHDItem = require("Core.UHDItem")
local Log = require("Log")
local InvetoryLog = Log.Category("Core\\Items\\Inventory", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
})

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
        self.inventory = {}
        local triggerUnitPickUPItem = WC3.Trigger()
        triggerUnitPickUPItem:RegisterUnitPickUpItem(self.owner)
        triggerUnitPickUPItem:AddAction(function() InvetoryLog:Info(" Inventory catch that unit pick up item") self:SetItem(UHDItem.GetManipulated()) end)
        local triggerUnitDropItem = WC3.Trigger()
        triggerUnitDropItem:RegisterUnitDropItem(self.owner)
        triggerUnitDropItem:AddAction(function() InvetoryLog:Info(" Inventory catch that unit drop item") self:LeaveItem(UHDItem.GetManipulated()) end)
        self.owner.toDestroy[triggerUnitDropItem] = true
        self.owner.toDestroy[triggerUnitDropItem] = true
    end

    function Inventory:SearchNewItem()
        local resultList = {}
        self.owner:EnumItems(function (item) resultList[item] = true end)
        for item in pairs(resultList) do
            if ~self:HasItem(item) then
                self.inventory = resultList
                return item
            end
        end
    end

    function Inventory:HasItem(item)
        for litem in pairs(self.inventory) do
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
        if item ~= nil then
            if item:IsA(UHDItem) then
                local maxInventory = self.owner:GetInventorySize()
                if #self.inventory <= maxInventory then
                    if self:CheckAvaileItemToAdd(item) then
                        self:DressItem(item)
                    else
                        self:DropItem(item)
                    end
                end
            end
        end
    end

    function Inventory:LeaveItem(item)
        if  item ~= nil then
            if item:IsA(UHDItem) then
                if self:HasItem(item) then
                    item:RemoveStats(self.owner)
                    self.inventory[item] = nil
                end
            end
        end
    end

    function Inventory:EnumItems(handler)
        local i = 0
        for item in pairs(self.inventory) do
            local res, err = pcall(handler, item, i)
            i = i + 1
        end
    end

    function Inventory:DropItem(item)
        local itemSlot = self:GetSlot(item)
        if itemSlot == nil then
        else
            self.owner:RemoveItemFromSlot(itemSlot)
        end
    end

    function Inventory:UpdateItems()
        local resultList = {}
        print("UpdateItems ")
        self.owner:EnumOnlyExistentItems(function(item)
            resultList[item] = true
            end)
        self.inventory = resultList
    end

    function Inventory:GetSlot(item)
        local resslot = nil
        self.owner:EnumOnlyExistentItems(
        function (itemInSlot, slot)
            if itemInSlot == item then
                resslot = slot
            end
        end)
        return resslot
    end

    function Inventory:DressItem(item)
        self.inventory[item] = true
        item:AddStats(self.owner)
    end

return Inventory