Module("PathNode", function (arg1, arg2, arg3)
    
    PathNode = Class()

    function PathNode:ctor(x, y, prevNode)
        self.sizex = 300
        self.sizey = 300
        self.x = x
        self.y = y
        self.prevNode = prevNode or nil
        self.region = Region()
        local rect = CRect(x - self.sizex, y - self.sizey, x + self.sizex, y + self.sizey)
        self.region:RegionAddRect(rect)
        
    end

    function PathNode:GetCenterPos()
        return self.x, self.y
    end

    function PathNode:IsUnitInNode(whichUnit)
        return self.region:IsUnitInRegion(whichUnit)
    end

    function PathNode:GetPrevCenterPos()
        if self.prevNode then
            return self.prevNode:GetCenterPos()
        end
    end

    function PathNode:IsPrevNode()
        if not self.prevNode then
            return true
        end
        return false
    end

    function PathNode:SetEvent(action)
        if not self.prevNode then
            local trigger = Trigger()
            trigger:TriggerRegisterEnterRegion(self.region, nil)
            trigger:AddAction(function() Log(" Mobs in node: "..self.x.." "..self.y) end)
        end
    end

    return PathNode
end)