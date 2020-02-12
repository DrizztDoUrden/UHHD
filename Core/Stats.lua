local Class = Require("Class")
local StatsBase = Class()

function StatsBase:EnumerateNames()
    return pairs(self.names)
end

function StatsBase:Enumerate()
    local ret = {}
    for _, name in self:EnumerateNames() do
        ret[name] = self[name]
    end
    return pairs(ret);
end

function StatsBase:__add(other)
    if not other or not other.IsA or not other:IsA(self) then
        error("Invalid stats operation (+): second operand is not same stats")
    end
    local ret = self()
    for name, value in self:Enumerate() do
        ret[name] = value + other[name]
    end
end

function StatsBase:__sub(other)
    if not other or not other.IsA or not other:IsA(self) then
        error("Invalid stats operation (-): second operand is not same stats")
    end
    local ret = self()
    for name, value in self:Enumerate() do
        ret[name] = value - other[name]
    end
end

local Stats = {}

Stats.Basic = Class(StatsBase)

function Stats.Basic:ctor()
    self.names = {
        "strength",
        "agility",
        "intellect",
        "constitution",
        "endurance",
        "willpower",
    }

    for _, stat in self:EnumerateNames() do self[stat] = 0 end
end

Stats.Secondary = Class(StatsBase)

function Stats.Secondary:ctor()
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
end

return Stats