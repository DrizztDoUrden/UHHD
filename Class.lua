do
    function Class(base, ctor)
        local class = {}

        if not ctor and type(base) == 'function' then
            ctor = base
            base = nil
            elseif type(base) == 'table' then
            for i,v in pairs(base) do
                class[i] = v
            end
            class._base = base
        end

        class.__index = class

        if base and base.ctor and not ctor then
            ctor = base.ctor
        elseif not ctor then
            ctor = function() end
        end

        local mt = {}
        function mt:__call(...)
            local instance = {}
            setmetatable(instance, class)
            instance:ctor(...)
            return instance
        end

        class.ctor = ctor
        function class:GetType()
            return getmetatable(self)
        end
        function class:IsA(other)
            local curClass = self:GetType()
            while curClass do 
                if curClass == other then return true end
                curClass = curClass._base
            end
            return false
        end
        setmetatable(class, mt)
        return class
    end
end
