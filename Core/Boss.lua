local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local WC3 = require("WC3.All")
local Timer = require("WC3.Timer")
local Unit = require("WC3.Unit")
local Creep = require("Core.Creep")
local Log = require("Log")


local BossLog = Log.Category("Boss\\Boss", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

    local Boss = Class(Creep)

    function Boss:ctor(...)
        UHDUnit.ctor(self, ...)
        self.aggresive = false
        self.spellBook = {}
        self.nextNode = nil

        self.abilities = WC3.Trigger() 
        self.abilities:RegisterUnitSpellEffect(self)
        self.toDestroy[self.abilities] = true
    end



    function Boss:Destroy()
        local timer = WC3.Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

    function Boss:OrderToAttack(x, y)
        self.nextNode = {x, y}
        self:IssueAttackPoint(x, y)
    end

    function Boss:GotoNodeAgain()
        if self.nextNode ~= nil then
            self:IssueAttackPoint(self.nextNode[1], self.nextNode[2])
        end
    end

    function Boss:SelectbyMinHP(list)
        local minHP = list[1]:GetHP()
        local unitWithMinHP = list[1]
        for _, unit in pairs(list) do
            local hp = unit:GetHP()
            if minHP > hp then
                unitWithMinHP = unit
                minHP = hp
            end
        end
        -- BossLog:Info("unit"..unitWithMinHP:GetX())
        return unitWithMinHP
    end

    function Boss:SelectbyMinMana(list)
        local minMana = list[1]:GetMana()
        local unitWithMinMana = list[1]
        for _, unit in pairs(list) do
            local mana = unit:GetMana()
            if minMana > mana then
                unitWithMinMana = unit
                minMana = mana
            end
        end
        return unitWithMinMana
    end

return Boss