do
    Unit = Class()

    local units = {}

    function Unit.Get(handle)
        local existing = units[handle]
        if existing then
            return existing
        end
        existing = Unit(handle)
        return existing
    end

    function Unit:ctor(...)
        local params = { ... }
        if #params == 1 then
            self.handle = params[0]
        else
            local player, unitid, x, y, facing = ...
            self.handle = CreateUnit(player, unitid, x, y, facing)
        end
        self:Register()
    end

    function Unit:Register()
        if units[self.handle] then
            error("Attempt to reregister a unit")
        end
        units[self.handle] = self
    end

    function Unit:SetMaxHealth(value)
        if math.type(value) then
            BlzSetUnitMaxHP(self.handle, math.floor(value))
        else
            Log("Unit max health should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetMaxMana(value)
        if math.type(value) then
            BlzSetUnitMaxMana(self.handle, math.floor(value))
        else
            Log("Unit max mana should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetArmor(value)
        if math.type(value) then
            BlzSetUnitArmor(self.handle, value)
        else
            Log("Unit armor should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetBaseDamage(value, weaponId)
        weaponId = weaponId or 0
        if math.type(weaponId) ~= "integer" then
            Log("Unit weapon id should be an integer (" .. type(weaponId) .. ")")
            return
        end
        if type(value) == "integer" then
            BlzSetUnitBaseDamage(self.handle, value, weaponId)
        elseif type(value) == "number" then
            BlzSetUnitBaseDamage(self.handle, math.floor(value), math.tointeger(weaponId))
        else
            Log("Unit base damage should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetAttackCooldown(value, weaponId)
        weaponId = weaponId or 0
        if math.type(weaponId) ~= "integer" then
            Log("Unit weapon id should be an integer (" .. type(weaponId) .. ")")
            return
        end
        if type(value) == "integer" or type(value) == "number" then
            BlzSetUnitAttackCooldown(self.handle, value, math.tointeger(weaponId))
        else
            Log("Unit attack cooldown should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetStr(value, permanent)
        if math.type(value) then
            SetHeroStr(self.handle, math.floor(value), permanent)
        else
            Log("Unit strength should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetAgi(value, permanent)
        if math.type(value) then
            SetHeroAgi(self.handle, math.floor(value), permanent)
        else
            Log("Unit agility should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetInt(value, permanent)
        if math.type(value) then
            SetHeroInt(self.handle, math.floor(value), permanent)
        else
            Log("Unit intellect should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:AddAbility(id)
        if math.type(id) then
            return UnitAddAbility(self.handle, math.tointeger(id))
        else
            Log("Abilityid should be an integer (" .. type(id) .. ")")
            return false
        end
    end

    function Unit:SetAbilityLevel(abilityId, level)
        return SetUnitAbilityLevel(self.handle, abilityId, level)
    end

    function Unit:GetName() return GetUnitName(self.handle) end
    function Unit:IsInRange(other, range) return IsUnitInRange(self.handle, other.handle, range) end
    function Unit:GetX() return GetUnitX(self.handle) end
    function Unit:GetY() return GetUnitY(self.handle) end
end
