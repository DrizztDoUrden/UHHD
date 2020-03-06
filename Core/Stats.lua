local Class = require("Class")
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

Stats.Basic.names = {
    "strength",
    "agility",
    "intellect",
    "constitution",
    "endurance",
    "willpower",
}

function Stats.Basic:ctor()
    for _, stat in self:EnumerateNames() do self[stat] = 0 end
end

Stats.Secondary = Class(StatsBase)

Stats.Secondary.names = {
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

Stats.Secondary.adding = {
    health = true,
    mana = true,
    healthRegen = true,
    manaRegen = true,
    armor = true,
}

function Stats.Secondary:ctor()
    for _, stat in self:EnumerateNames() do self[stat] = 0 end
end

return Stats