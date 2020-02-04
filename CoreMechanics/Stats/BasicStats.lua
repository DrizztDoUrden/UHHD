do
    BasicStats = Class(function(self)
        self.names = {
            "strength",
            "agility",
            "intellect",
            "constintution",
            "endurance",
            "willpower",
        }

        for _, stat in self:EnumerateNames() do self[stat] = 0 end
    end)

    function BasicStats:EnumerateNames()
        return pairs(self.names)
    end

    function BasicStats:Enumerate()
        local ret = {}
        for _, name in self:EnumerateNames() do
            ret[name] = self[name]
        end
        return pairs(ret);
    end

    function BasicStats:__add(other)
        if not other or not other.IsA or not other:IsA(BasicStats) then
            error("Invalid BasicStats operation (+): second operand is not BasicStats")
        end
        local ret = BasicStats()
        for name, value in self:Enumerate() do
            ret[name] = value + other[name]
        end
    end

    function BasicStats:__sub(other)
        if not other or not other.IsA or not other:IsA(BasicStats) then
            error("Invalid BasicStats operation (-): second operand is not BasicStats")
        end
        local ret = BasicStats()
        for name, value in self:Enumerate() do
            ret[name] = value - other[name]
        end
    end
end
