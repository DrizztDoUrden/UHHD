Module("PathNode", function (arg1, arg2, arg3)
    
    PathNode = Class()

    function PathNode:ctor(x, y, prevNode)
        self.sizex = 200
        self.sizey = 200
        self.x = x
        self.y = y
        self.prevNode = prevNode
        self.region = Region()
        local rect = CRect(x - self.sizex, y - self.sizey, x + self.sizex, y + self.sizey)
        self.region:RegionAddRect(rect)
        if prevNode ~= nil then
            self:SetEvent()
        end
    end

    function PathNode:addNode(node)
        self.prevNode = node
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

    function PathNode:SetEvent(formation)
        Log(" Add trigger to path Node in"..self.x.." "..self.y)
        local trigger = Trigger()
        trigger:TriggerRegisterEnterRegion(self.region, nil)
        trigger:AddAction(function()
            local whichunit = Unit.Get(GetEnteringUnit())
            local x, y = self:GetPrevCenterPos()
            whichunit:IssueAttackPoint(x, y)
            Log(" Mobs in node: "..self.x.." "..self.y)
        end)
    end
    return PathNode
end)