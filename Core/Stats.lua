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

--[[
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
]]

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

local function SimpleAdd(l, r) return l + r end
local function SimpleMul(l, r) return l * (1 + r) end
local function ReversedMul(l, r) return 1 - (1 - l) * (1 - r) end

local function SimpleSub(l, r) return l - r end
local function SimpleDiv(l, r) return l / (1 + r) end
local function ReversedDiv(l, r) return 1 - (1 - l) / (1 - r) end

Stats.Secondary.AddBonus = {
    health = SimpleAdd,
    mana = SimpleAdd,
    healthRegen = SimpleAdd,
    manaRegen = SimpleAdd,
    armor = SimpleAdd,

    weaponDamage = SimpleMul,
    attackSpeed = SimpleMul,
    physicalDamage = SimpleMul,
    spellDamage = SimpleMul,
    movementSpeed = SimpleMul,

    evasion = ReversedMul,
    ccResist = ReversedMul,
    spellResist = ReversedMul,
}

Stats.Secondary.SubBonus = {
    health = SimpleSub,
    mana = SimpleSub,
    healthRegen = SimpleSub,
    manaRegen = SimpleSub,
    armor = SimpleSub,

    weaponDamage = SimpleDiv,
    attackSpeed = SimpleDiv,
    physicalDamage = SimpleDiv,
    spellDamage = SimpleDiv,
    movementSpeed = SimpleDiv,

    evasion = ReversedDiv,
    ccResist = ReversedDiv,
    spellResist = ReversedDiv,
}

function Stats.Secondary:ctor()
    for _, stat in self:EnumerateNames() do self[stat] = 0 end
end

return Stats