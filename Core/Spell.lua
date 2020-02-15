local Class = require "Class"
local Log = require "Log"

local Spell = Class()

function Spell:ctor(definition, caster)
    self.caster = caster
    for k, v in pairs(definition.params or {}) do
        self[k] = v(definition, caster)
    end
    self:Cast()
end

return Spell