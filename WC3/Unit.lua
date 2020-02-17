local Class = require("Class")
local WCPlayer = require("WC3.Player")
local Log = require("Log")

local Unit = Class()

local units = {}

local logUnit = Log.Category("WC3\\Unit")

local function Get(handle)
    local existing = units[handle]
    if existing then
        return existing
    end
    return Unit(handle)
end

function Unit.GetFiltered()
    return Get(GetFilterUnit())
end

function Unit.GetDying()
    return Get(GetDyingUnit())
end

function Unit.GetSpellTarget()
    return Get(GetSpellTargetUnit())
end

function Unit.GetBying()
    return Get(GetBuyingUnit())
end

function Unit.GetSold()
    return Get(GetSoldUnit())
end

function Unit.GetEntering()
    return Get(GetEnteringUnit())
end

function Unit.GetLeveling()
    return Get(GetLevelingUnit())
end

function Unit.GetEventDamageSource()
    return Get(GetEventDamageSource())
end

function Unit.GetEventDamageTarget()
    return Get(BlzGetEventDamageTarget())
end

function Unit.EnumInRange(x, y, radius, handler)
    local group = CreateGroup()
    GroupEnumUnitsInRange(group, x, y, radius, Filter(function()
        local result, err = pcall(handler, Unit.GetFiltered())
        if not result then
            logUnit:Error("Error enumerating units in range: " .. err)
        end
    end))
    DestroyGroup(group)
end

function Unit:ctor(...)
    local params = { ... }
    if #params == 1 then
        self.handle = params[1]
    else
        local player, unitid, x, y, facing = ...
        self.handle = CreateUnit(player.handle, unitid, x, y, facing)
    end
    self:Register()
    self.toDestroy = {}
end

function Unit:Register()
    if units[self.handle] then
        error("Attempt to reregister a unit", 3)
    end
    units[self.handle] = self
end

function Unit:SetMaxHealth(value)
    if math.type(value) then
        BlzSetUnitMaxHP(self.handle, math.floor(value))
    else
        error("Unit max health should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:SetMaxMana(value)
    if math.type(value) then
        BlzSetUnitMaxMana(self.handle, math.floor(value))
    else
        error("Unit max mana should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:SetArmor(value)
    if math.type(value) then
        BlzSetUnitArmor(self.handle, value)
    else
        error("Unit armor should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:SetBaseDamage(value, weaponId)
    weaponId = weaponId or 0
    if math.type(weaponId) ~= "integer" then
        error("Unit weapon id should be an integer (" .. type(weaponId) .. ")", 2)
        return
    end
    if type(value) == "integer" then
        BlzSetUnitBaseDamage(self.handle, value, weaponId)
    elseif type(value) == "number" then
        BlzSetUnitBaseDamage(self.handle, math.floor(value), math.tointeger(weaponId))
    else
        error("Unit base damage should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:SetAttackCooldown(value, weaponId)
    weaponId = weaponId or 0
    if math.type(weaponId) ~= "integer" then
        error("Unit weapon id should be an integer (" .. type(weaponId) .. ")", 2)
        return
    end
    if type(value) == "integer" or type(value) == "number" then
        BlzSetUnitAttackCooldown(self.handle, value, math.tointeger(weaponId))
    else
        error("Unit attack cooldown should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:SetStr(value, permanent)
    if math.type(value) then
        SetHeroStr(self.handle, math.floor(value), permanent)
    else
        error("Unit strength should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:SetAgi(value, permanent)
    if math.type(value) then
        SetHeroAgi(self.handle, math.floor(value), permanent)
    else
        error("Unit agility should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:Destroy()
    units[self.handle] = nil
    RemoveUnit(self.handle)
    for item in pairs(self.toDestroy) do
        item:Destroy()
    end
end

function Unit:ChangeSelection(value)
    SelectUnit(self.handle, value)
end

function Unit:Select()
    self:ChangeSelection(true)
end

function Unit:Deselect()
    self:ChangeSelection(false)
end

function Unit:SetInt(value, permanent)
    if math.type(value) then
        SetHeroInt(self.handle, math.floor(value), permanent)
    else
        error("Unit intellect should be a number (" .. type(value) .. ")", 2)
    end
end

function Unit:AddAbility(id)
    if math.type(id) then
        return UnitAddAbility(self.handle, math.tointeger(id))
    else
        error("Abilityid should be an integer (" .. type(id) .. ")", 2)
        return false
    end
end

function Unit:RemoveAbility(id)
    if math.type(id) then
        return UnitRemoveAbility(self.handle, math.tointeger(id))
    else
        error("Abilityid should be an integer (" .. type(id) .. ")", 2)
        return false
    end
end

function Unit.AddToAllStock(unitId, currentStock, stockMax)
    if math.type(unitId) ~= "integer" then
        error("unitId should be an integer", 2)
    end
    if currentStock == nil then
        currentStock = 1
    else
        if math.type(currentStock) ~= "integer" then
            error("currentStock should be an integer", 2)
        end
    end
    if stockMax == nil then
        stockMax = 1
    else
        if math.type(stockMax) ~= "integer" then
            error("stockMax should be an integer", 2)
        end
    end
    AddUnitToAllStock(unitId, currentStock, stockMax)
end

function Unit:AddUnitToStock(unitId, currentStock, stockMax)
    if math.type(unitId) ~= "integer" then
        error("unitId should be an integer", 2)
    end
    if currentStock == nil then
        currentStock = 1
    else
        if math.type(currentStock) ~= "integer" then
            error("currentStock should be an integer", 2)
        end
    end
    if stockMax == nil then
        stockMax = 1
    else
        if math.type(stockMax) ~= "integer" then
            error("stockMax should be an integer", 2)
        end
    end
    AddUnitToStock(self.handle, unitId, currentStock, stockMax)
end

function Unit:SetAbilityLevel(abilityId, level)
    return SetUnitAbilityLevel(self.handle, abilityId, level)
end

function Unit:DamageTarget(target, damage, isAttack, isRanged, attackType, damageType, weaponType)
    return UnitDamageTarget(self.handle, target.handle, damage, isAttack, isRanged, attackType, damageType, weaponType)
end

function Unit:SetHpRegen(value)
    return BlzSetUnitRealField(self.handle, UNIT_RF_HIT_POINTS_REGENERATION_RATE, value)
end

function Unit:SetManaRegen(value)
    return BlzSetUnitRealField(self.handle, UNIT_RF_MANA_REGENERATION, value)
end

function Unit:IssuePointOrderById(order, x, y)
    if math.type(x) and math.type(y) then
        if math.type(order) == "integer" then
            local result = IssuePointOrderById(self.handle, order, x, y)
            return result
        else
            error("order should be integer", 2)
        end
    else
        error("coorditane should be a number", 2)
    end
end

function Unit:IssueAttackPoint(x, y)
    return self:IssuePointOrderById(851983, x, y)
end

function Unit:IssueMovePoint(x, y)
    return self:IssuePointOrderById(851986, x, y)
end

function Unit:SetMoveSpeed(value)
    SetUnitMoveSpeed(self.handle, 300 * value)
end

function Unit:SetX(value)
    SetUnitX(self.handle, value)
end

function Unit:SetY(value)
    SetUnitY(self.handle, value)
end

function Unit:GetManaCost(abilityId, level)
    return BlzGetUnitAbilityManaCost(self.handle, abilityId, level)
end

function Unit:SetManaCost(abilityId, level, value)
    return BlzSetUnitAbilityManaCost(self.handle, abilityId, level, value)
end

function Unit:GetCooldown(abilityId, level)
    return BlzGetUnitAbilityCooldown(self.handle, abilityId, level)
end

function Unit:SetCooldown(abilityId, level, value)
    return BlzSetUnitAbilityCooldown(self.handle, abilityId, level, value)
end

function Unit:SetCooldownRemaining(abilityId, value)
    return BlzStartUnitAbilityCooldown(self.handle, abilityId, value)
end

function Unit:GetName() return GetUnitName(self.handle) end
function Unit:IsInRange(other, range) return IsUnitInRange(self.handle, other.handle, range) end
function Unit:GetX() return GetUnitX(self.handle) end
function Unit:GetY() return GetUnitY(self.handle) end
function Unit:GetPos() return self:GetX(), self:GetY() end
function Unit:GetHP() return GetWidgetLife(self.handle) end
function Unit:SetHP(value) return SetWidgetLife(self.handle, value) end
function Unit:GetMana() return GetUnitState(self.handle, UNIT_STATE_MANA) end
function Unit:SetMana(value) return SetUnitState(self.handle, UNIT_STATE_MANA, value) end
function Unit:GetMaxHP() return BlzGetUnitMaxHP(self.handle) end
function Unit:GetMaxMana() return BlzGetUnitMaxMana(self.handle) end
function Unit:GetOwner() return WCPlayer.Get(GetOwningPlayer(self.handle)) end
function Unit:GetArmor() return BlzGetUnitArmor(self.handle) end
function Unit:GetFacing() return GetUnitFacing(self.handle) end
function Unit:GetAbility(id) return BlzGetUnitAbility(self.handle, id) end
function Unit:GetLevel() return GetHeroLevel(self.handle) end
function Unit:GetTypeId() return GetUnitTypeId(self.handle) end
function Unit:IsHero() return IsHeroUnitId(self:GetTypeId()) end

return Unit