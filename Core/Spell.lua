local Class = require "Class"
local Log = require "Log"
local WC3 = require "WC3.All"

local Spell = Class()

function Spell:ctor(definition, caster, target)
    self.caster = caster
    for k, v in pairs(definition.params or {}) do
        self[k] = v(definition, caster)
    end
    self.target = target or {}
    self:Cast()
end

function Spell:GetTargetUnit()
    if self.target.unit == nil then
        self.target.unit = WC3.Unit.GetSpellTarget()
    end
    return self.target.unit
end

function Spell:GetTargetX()
    if self.target.x == nil then
        self.target.x = GetSpellTargetX()
    end
    return self.target.x
end

function Spell:GetTargetY()
    if self.target.y == nil then
        self.target.y = GetSpellTargetY()
    end
    return self.target.y
end

return Spell