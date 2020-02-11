local Class = Require("Class")

local Region = Class()
local regions = {}

function Region.GetTriggering()
    local handle = GetTriggeringRegion()
    if handle == nil then
        return nil
    end
    local existing = regions[handle]
    if existing then
        return existing
    end
    return Region(handle)
end

local function Register(region)
    if regions[region.handle] then
        error("Attempt to reregister a region", 3)
    end
    regions[region.handle] = region
end

function Region:ctor(handle)
    self.handle = handle or CreateRegion()
    Register(self)
end

function Region:Destroy()
    RemoveRegion(self.handle)
end

function Region:IsUnitIn(whichUnit)
    return IsUnitInRegion(self.handle, whichUnit.handle)
end

function Region:AddRect(rect)
    RegionAddRect(self.handle, rect.handle)
end

return Region