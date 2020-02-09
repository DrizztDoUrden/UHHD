do
    Region = Class()
    local regions = {}

    function Region.Get(handle)
        local existing = regions[handle]
        if existing then
            return existing
        end
        existing = Unit(handle)
        return existing
    end


    function Region:ctor()
        self.handle = CreateRegion()
    end

    function Region:RemoveRegion()
        RemoveRegion(self.handle)
    end

    function Region:IsUnitInRegion(whichUnit)
        return IsUnitInRegion(self.handle, whichUnit.handle)
    end

    function Region:RegionAddRect(rect)
        RegionAddRect(self.handle, rect.handle)
    end

    CRect = Class()
    local crects = {}
    
    function CRect.Get(handle)
        local existing = crects[handle]
        if existing then
            return existing
        end
        existing = Unit(handle)
        return existing
    end

    function CRect:ctor(...)
        local minx, miny, maxx, maxy = ...
        self.handle = Rect(minx, miny, maxx, maxy)
    end

    function CRect:RemoveRect()
        RemoveRect(self.handle)
    end

end