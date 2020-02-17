local Class = require("Class")
local BoosPreset = require("Core.BoosPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Unit = require("WC3.Unit")
local Log = require("Log")
local treeLog = Log.Category("Boos\\DefiledTree", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

local DrainMana = Class(Spell)

local DefiledTree = Class(BoosPreset)


function DefiledTree:ctor()
    BoosPreset.ctor(self)
    self.secondaryStats.health = 375
    self.secondaryStats.mana = 110
    self.secondaryStats.weaponDamage = 4
    self.secondaryStats.physicalDamage = 35
    self.abilities = {
        drainMana = {
            id = FourCC('BS00'),
            handler = DrainMana,
            availableFromStart = true,
            params = {
                radius = function (_) return 400 end,
                duration = function (_) return 10 end,
                period = function (_) return 0.5 end,
                stealMana = function (_) return 3 end,
                wampireHp = function (_) return 6 end
            }
        }
    }
    self.unitid = FourCC('bu01')
end


function DrainMana:ctor(definition, caster)
    self.affected = {}
    self.bonus = 0
    Spell.ctor(self, definition, caster)
end

function DrainMana:Cast()
    self.target =  Unit.GetSpellTarget()
    local x, y = self.target:GetX(), self.target:GetY()
    treeLog:Info("Pos "..x.." "..y)
    --treeLog:Info("Caster Owner "..self.caster:GetOwner().handle)
    self.spellunit = WC3.Unit(self.caster:GetOwner(), FourCC("bs00") , x, y, 0)
    local timer = WC3.Timer()
    timer:Start(self.period, true, function()
        if self.caster:GetHP() <= 0 then
            timer:Destroy()
            self:End()
            return
        end
        self.duration = self.duration - self.period
        -- treeLog:Info("Duration "..self.duration)

        self:Effect()
        self:Drain()

        if self.duration <= 0 then
            timer:Destroy()
            self:End()
        end
    end)
end

function DrainMana:Effect()
    WC3.Unit.EnumInRange(self.spellunit:GetX(), self.spellunit:GetY(), self.radius, function(unit)
        if self.caster ~= unit and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
        table.insert(self.affected,{unit = unit})
        end
    end)
    local x, y = self.target:GetX(), self.target:GetY()
    self.spellunit:IssuePointOrderById(851986, x, y)
end

function DrainMana:Drain()
    local towampire = self.caster:GetHP()
    for _, target in pairs(self.affected) do
        local residualMana = target.unit:GetMana() - self.stealMana
        local stolenMana = self.stealMana
        if residualMana <= 0 then
            stolenMana = stolenMana + residualMana
            residualMana = 0
        end
        towampire = self.wampireHp + towampire * (stolenMana / self.stealMana)
        target.unit:SetMana(residualMana)
    end
    self.caster:SetHP(towampire)
end

function DrainMana:End()
    self.spellunit:Destroy()
end

return DefiledTree