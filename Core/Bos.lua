local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local WC3 = require("WC3.All")
local Timer = require("WC3.Timer")
local Unit = require("WC3.Unit")

local Log = require("Log")


local BosLog = Log.Category("Bos\\Bos", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

    local Bos= Class(UHDUnit)

    function Bos:ctor(...)
        UHDUnit.ctor(self, ...)
        self.aggresive = false
        self.spellBook = {}

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
        local x, y = self:GetX(), self:GetY()
        local bosOwner = self:GetOwner()
        -- BosLog:Info("Choose target")
        local targets = {}
        Unit.EnumInRange(x, y, range, function(unit)
            if bosOwner:IsEnemy(unit:GetOwner()) then
                table.insert(targets, unit)
            end
        end)
        local minHP = targets[1]:GetHP()
        local unitWithMinHP = targets[1]
        for _, unit in pairs(targets) do
            local hp = unit:GetHP()
            if minHP > hp then
                unitWithMinHP = unit
                minHP = hp
            end
        end
        -- BosLog:Info("unit"..unitWithMinHP:GetX())
        return unitWithMinHP
    end


    function Bos:SelectbyMinMana(range)
        self.aggresive = false
        local x, y = self:GetX(), self:GetY()
        local bosOwner = self:GetOwner()
        local targets = {}
        Unit.EnumInRange(x, y, range, function(unit)
            if bosOwner:IsEnemy(unit:GetOwner()) then
                table.insert(targets, unit)
                self.aggresive = true
            end
        end)
        local minMana = targets[1]:GetMana()
        local unitWithMinMana = targets[1]
        for _, unit in pairs(targets) do
            local mana = unit:GetMana()
            if minMana > mana then
                unitWithMinMana = unit
                minMana = mana
            end
        end
        return unitWithMinMana
    end

return Bos