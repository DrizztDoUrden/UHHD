local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local WC3 = require("WC3.All")
local Timer = require("WC3.Timer")
local Unit = require("Core.Unit")

local Log = require("Log")


local BosLog = Log.Category("Bos\\Bos", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

    local Bos= Class(UHDUnit)

    function Bos:ctor(...)
        UHDUnit.ctor(self, ...)
        self.aggresive = false
        self.abilitiesCastOnEnemy = {true}
        self.abilities = WC3.Trigger() 
        self.abilities:RegisterUnitSpellEffect(self)
        self.toDestroy[self.abilities] = true
    end

    function Bos:Destroy()
        local timer = WC3.Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

    function Bos:SelectbyMinHP(range)
        local x, y = Bos:GetX(), Bos:GetY()
        local bosOwner = Bos:GetOwner()
        local targets = {}
        Unit.EnumInRange(x, y, range, function(unit)
            if bosOwner:IsAEnemy(unit:GetOwner()) then
                table.insert(targets, {unit = unit})
            end
        end)
        local minHP = targets[1].unit:GetHP()
        local unitWithMinHP = targets[1].unit
        for _, unit in pairs(self.targets) do
            local hp = unit.unit:GetHP()
            if minHP < hp then
                unitWithMinHP = unit.unit
                minHP = hp
            end
        end
        return unitWithMinHP
    end

    function Bos:CheckEnemyInRange(range)
        local x, y = self:GetX(), self:GetY()
        local bosOwner = self:GetOwner()
        self.aggresive = false
        Unit.EnumInRange(x, y, range, function(unit)
            if bosOwner:IsAEnemy(unit:GetOwner()) then
                self.aggresive = true
            end
        end)
    end

    function Bos:SelectbyMinMana(range)
        local x, y = self:GetX(), self:GetY()
        local bosOwner = self:GetOwner()
        local targets = {}
        Unit.EnumInRange(x, y, range, function(unit)
            if bosOwner:IsAEnemy(unit:GetOwner()) then
                table.insert(targets, {unit = unit})
            end
        end)
        local minMana = targets[1].unit:GetMana()
        local unitWithMinMana = targets[1].unit
        for _, unit in pairs(self.targets) do
            local mana = unit.unit:GetMana()
            if minMana < mana then
                unitWithMinMana = unit.unit
                minMana = mana
            end
        end
        return unitWithMinMana
    end

return Bos