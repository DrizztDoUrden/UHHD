local Class = require("Class")
local Log = require("Log")

local Item = Class()

local items = {}

local logItem = Log.Category("WC3\\Item")


local function Get(handle)
    print(#items)
    local existing = items[handle]
    if existing then
        return existing
    end
    return Item(handle)
end


function Item.GetItemInSlot(unithandle, slot)
    Get(UnitItemInSlot(unithandle, slot))
end

function Item.GetSold()
    Get(GetSoldUnit())
end

function Item.GetManipulatedItem()
    local item = GetManipulatedItem()
    print(" Choose item")
    print(item)
    Get(GetManipulatedItem())
end

function Item:ctor(...)
    local params = { ... }
    if #params == 1 then
        self.handle = params[1]
    else
        local itemid, x, y = ...
        self.handle = CreateItem(itemid, x, y)
        print(itemid)
    end
    print(self)
    self:Register()
    self.toDestroy = {}
end


function Item:Register()
    print("Register Item")
    print(self)
    print(self.handle)
    
    if items[self.handle] then
        error("Attempt to reregister a unit", 3)
    end
    print("State of items")
    print(items)
    -- items[1] = {self, self.handle}
    -- print("Amount of Items "..#items)
    -- print(items[1][1])
    -- print(items[1][2])
    items[self.handle] = self
    print("Amount of Items "..#items)
end

function Item:GetTypeId()
    return GetItemTypeId(self.handle)
end

function Item:Destroy()
    items[self.handle] = nil
    RemoveItem(self.handle)
    for item in pairs(self.toDestroy) do 
        item:Destroy()
    end
end

function Item:GetX()
    return GetItemX(self.handle)
end

function Item:GetY()
    return GetItemY(self.handle)
end

function Item:SetPos(x, y)
    return SetItemPosition(self.handle, x, y)
end

function Item:GetName()
    return GetItemName(self.handle)
end

function Item:AddAbility(id)
        if math.type(id) then
            return BlzItemAddAbility(self.handle, math.tointeger(id))
        else
            error("Abilityid should be an integer (" .. type(id) .. ")", 2)
            return false
        end
end

function Item:RemoveAbility(id)
    if math.type(id) then
        return BlzItemRemoveAbility(self.handle, math.tointeger(id))
    else
        error("Abilityid should be an integer (" .. type(id) .. ")", 2)
        return false
    end
end

function Item:GetPlayer()
    return GetItemPlayer(self.handle)
end


function Item.GetInSlot(handle, slot)
    return Get(UnitItemInSlot(handle, slot))
end

return Item