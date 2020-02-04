do
    SecondaryStats = Class(function(self)
        self.names = {
            "health",
            "mana",

            "healthRegen",
            "manaRegen",

            "weaponDamage",
            "attackSpeed",
            "physicalDamage",
            "spellDamage",

            "armor",
            "evasion",
            "block",
            "ccResist",
            "spellResist",

            "movementSpeed",
        }

        for _, stat in self:EnumerateNames() do self[stat] = 0 end
    end)

    function SecondaryStats:EnumerateNames()
        return pairs(self.names)
    end

    function SecondaryStats:Enumerate()
        local ret = {}
        for _, name in self:EnumerateNames() do
            ret[name] = self[name]
        end
        return pairs(ret);
    end

    function SecondaryStats:__add(other)
        if not other or not other.IsA or not other:IsA(SecondaryStats) then
            error("Invalid SecondaryStats operation (+): second operand is not SecondaryStats")
        end
        local ret = SecondaryStats()
        for name, value in self:Enumerate() do
            ret[name] = value + other[name]
        end
    end

    function SecondaryStats:__sub(other)
        if not other or not other.IsA or not other:IsA(SecondaryStats) then
            error("Invalid SecondaryStats operation (-): second operand is not SecondaryStats")
        end
        local ret = SecondaryStats()
        for name, value in self:Enumerate() do
            ret[name] = value - other[name]
        end
    end
end
