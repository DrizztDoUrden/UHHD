local Class = require("Class")
local BosPreset = require("Core.BosPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"

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
    self.secondaryStats.weaponDamage = 35
    self.secondaryStats.physicalDamage = 1
    self.spellBook = {{
        spellName = "DrainMana",
        isAllTimeAcctivate = false}}
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

function DefiledTree:Spawn(...)
    Bos = BosPreset.Spawn(self, ...)
    local timerAttack = WC3.Timer()
    Bos.toDestroy[timerAttack] = true
    timerAttack:Start(1, true, function()
        self:SelectAims()
    end)
end

function DefiledTree:SelectAims()
    local x, y = Bos:GetX(), Bos:GetY()
    local bosOwner = Bos:GetOwner()
    local targets = {}
    WC3.Unit.EnumInRange(x, y, 700, function(unit)
        if bosOwner:IsEnemy(unit:GetOwner()) then
            table.insert(targets, unit)
            Bos.aggresive = true
        end
    end)
    if Bos.aggresive then
        local target = Bos:SelectbyMinHP(targets)
        Bos:IssueTargetOrderById(851983, target)
        -- print(self.unitid)
        for i, value in pairs(self.abilities) do
            -- treeLog:Info(" spell"..i)
            if Bos:GetCooldown(value.id, 0) == 0 then
                -- treeLog:Info("range "..value.params.duration())
                local target = Bos:SelectbyMinMana(targets)
                Bos:IssueTargetOrderById(OrderId('absorb'), target)
                break
            end
        end
    else
        Bos:GotoNodeAgain()
    end
end

function DrainMana:ctor(definition, caster)
    self.affected = {}
    self.bonus = 0
    Spell.ctor(self, definition, caster)
end

function DrainMana:Cast()
    self.target =  WC3.Unit.GetSpellTarget()
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
    if self.aggresive then
        local Bos = self.caster
        treeLog:Info("Choose aim")
        local target = Bos:SelectbyMinHP()
        treeLog:Info("target in : "..target:PosX().." "..target:PosY())
        return true
    end
    return false
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