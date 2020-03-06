local Class = require "Class"
local Log = require "Log"
local WC3 = require "WC3.All"

local Spell = Class()

function Spell:ctor(definition, caster)
    self.caster = caster
    for k, v in pairs(definition.params or {}) do
        self[k] = v(definition, caster)
    end
    self:Cast()
end

function Spell:GetTargetUnit()
    return WC3.Unit.GetSpellTarget()
end

function Spell:GetTargetX()
    return GetSpellTargetX()
end

function Spell:GetTargetY()
    return GetSpellTargetY()
end

return Spell