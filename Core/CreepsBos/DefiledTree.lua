local Class = require("Class")
local BosPreset = require("Core.BosPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Unit = require("WC3.Unit")
local Timer = require("WC3.Timer")
local Log = require("Log")
local treeLog = Log.Category("Bos\\DefiledTree", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

local DrainMana = Class(Spell)

local DefiledTree = Class(BosPreset)


function DefiledTree:ctor()
    BosPreset.ctor(self)
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
                radius = function (_) return 150 end,
                duration = function (_) return 10 end,
                period = function (_) return 0.5 end,
                leachMana = function (_) return 3 * self.secondaryStats.spellDamage end,
                leachHP = function (_) return 6 * self.secondaryStats.spellDamage end,
                dummySpeed = function (_) return 0.6 end,
                range = function (_) return 599 end
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

function DefiledTree:Spawn()
    local Bos = BosPreset.Spawn(self)
    local timerDM = Timer()
    Bos.timerDM:Start(1, true, function()
        treeLog:Info("Choose aim")
        local target = Bos:SelectbyMinHP()
        treeLog:Info("target in : "..target:PosX().." "..target:PosY())
        Bos:IssueTargetOrderById(851983, target)
        end)
    Bos:AddTimer("DrainMana")
end

function DrainMana:Cast()
    self.target =  Unit.GetSpellTarget()
    local x, y = self.target:GetX(), self.target:GetY()
    treeLog:Info("Pos "..x.." "..y)
    --treeLog:Info("Caster Owner "..self.caster:GetOwner().handle)
    self.dummy = WC3.Unit(self.caster:GetOwner(), FourCC("bs00") , x, y, 0)
    self.dummy:SetMoveSpeed(self.dummySpeed)
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
    WC3.Unit.EnumInRange(self.dummy:GetX(), self.dummy:GetY(), self.radius, function(unit)
        if self.caster ~= unit and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
        table.insert(self.affected,{unit = unit})
        end
    end)
    local x, y = self.target:GetX(), self.target:GetY()
    self.dummy:IssuePointOrderById(851986, x, y)
end

function DrainMana:AutoCast()
    
end

function DrainMana:Drain()
    local sumHP = 0
    for _, target in pairs(self.affected) do
        local currentMana = target.unit:GetMana()
        local residualMana = math.max(currentMana - self.leachMana * self.period, 0)
        sumHP =  sumHP + self.leachHP * self.period * ((currentMana - residualMana)/ self.leachMana)
        target.unit:SetMana(residualMana)
    end
    self.caster:SetHP(self.caster:GetHP() + sumHP)
end


function DrainMana:End()
    self.dummy:Destroy()
end

return DefiledTree