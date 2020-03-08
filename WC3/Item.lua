local Class = require("Class")
local Log = require("Log")

local Item = Class()

local items = {}

local logItem = Log.Category("WC3\\Item")


local function Get(handle)
    local existing = items[handle]
    if existing then
        return existing
    end
    if handle == nil then
        print(" Where getter give nil expect class from table")
    end
    return Item(handle)
end

function Item.GetInSlot(unithandle, slot)
    return Get(UnitItemInSlot(unithandle, slot))
end

function Item.GetSold()

    return Get(GetSoldItem())
end

function Item.GetManipulated()
    local result = GetManipulatedItem()
    if result ~= nil then
        return Get(result)
    end
    return nil
end

function Item:ctor(...)
    local params = { ... }
    if #params == 1 then
        self.handle = params[1]
    else
        local itemid, x, y = ...
        self.handle = CreateItem(itemid, x, y)
    end
    self:Register()
    self.toDestroy = {}
end

function Item:Register()
    if items[self.handle] then
        error("Attempt to reregister a unit", 3)
    end
    items[self.handle] = self
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

function Item.GetInSlot(unit, slot)
    local result = UnitItemInSlot(unit.handle, slot)
    if result ~= nil then
        return Get(result)
    end
    return nil
end

return Item