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

local function Dot100(v)
    return string.format("%.2f", v)
end

local function Percent(v)
    return math.floor(100 * v) .. "%"
end

Stats.Secondary.meta = {
    health = {
        display = "health",
        formatter = math.floor,
    },
    mana = {
        display = "mana",
        formatter = math.floor,
    },
    healthRegen = {
        display = "health regen",
        formatter = Dot100,
    },
    manaRegen = {
        display = "mana regen",
        formatter = Dot100,
    },

    weaponDamage = {
        display = "weapon damage",
        formatter = math.floor,
    },
    attackSpeed = {
        display = "attack speed",
        formatter = Dot100,
    },
    physicalDamage = {
        display = "physical damage",
        formatter = Percent,
    },
    spellDamage = {
        display = "spell damage",
        formatter = Percent,
    },

    armor = {
        display = "armor",
        formatter = math.floor,
    },
    evasion = {
        display = "evasion",
        formatter = Percent,
    },
    block = {
        display = "block",
        formatter = Percent,
    },
    ccResist = {
        display = "CC resist",
        formatter = Percent,
    },
    spellResist = {
        display = "spell resist",
        formatter = Percent,
    },

    movementSpeed = {
        display = "movement speed",
        formatter = Percent,
    },
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