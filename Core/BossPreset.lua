local Class = require("Class")
local Log = require("Log")
local Stats = require("Core.Stats")
local Boss = require("Core.Boss")
local Unit = require("WC3.Unit")
local CreepPreset = require("Core.CreepPreset")
local Timer = require("WC3.Timer")

local BossPresetLog = Log.Category("Boss\\BossPreset", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

local BossPreset = Class(CreepPreset)

function BossPreset:ctor()
    self.secondaryStats = Stats.Secondary()

    self.abilities = {}

    self.secondaryStats.health = 50
    self.secondaryStats.mana = 2
    self.secondaryStats.healthRegen = 1
    self.secondaryStats.manaRegen = 1

    self.secondaryStats.weaponDamage = 15
    self.secondaryStats.attackSpeed = 0.5
    self.secondaryStats.physicalDamage = 1
    self.secondaryStats.spellDamage = 1

    self.secondaryStats.armor = 5
    self.secondaryStats.evasion = 0.3
    self.secondaryStats.block = 0
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0.3

    self.secondaryStats.movementSpeed = 1

    self.class = Boss
end

function BossPreset:Spawn(owner, x, y, facing,  level, herocount)
    local boss = CreepPreset.Spawn(self, owner, x, y, facing,  level, herocount);
    -- BossPresetLog:Info("Spawn Boss")
    boss.abilities:AddAction(function() self:Cast(boss) end)
    -- print("BossPreset")
    -- print(boss)
    

    for i, ability in pairs(self.abilities) do
        -- BossPresetLog:Info("Number "..i)
        if ability.availableFromStart then
            boss:AddAbility(ability.id)
        end
    end
    -- print("BossPreset after spell adding")
    -- print(boss)
    boss.AggroTimer:Start(1, true, function()
        self:SelectTarget(boss)
    end)
    return boss
end

function BossPreset:SelectTarget(boss)
    local x, y = boss:GetX(), boss:GetY()
    local bosOwner = boss:GetOwner()
    local targets = {}
    boss.aggresive = false
    Unit.EnumInRange(x, y, 700, function(unit)
        if bosOwner:IsEnemy(unit:GetOwner()) then
            table.insert(targets, unit)
            boss.aggresive = true
        end
    end)
    if boss.aggresive then
        local target = self:SelectbyMinHP(targets)
        boss:IssueTargetOrderById(851983, target)
        for spellName, spell in pairs(self.abilities) do
            -- BossPresetLog:Info("Spell ="..spellName)
            if boss:GetCooldown(spell.id, 1) == 0 then
                local target = self:GetTargetWithMaxPriority(boss, spell)
                if target ~= nil then
                    boss:IssueTargetOrderById(OrderId(spell.idforCast), target)
                end
            end
        end
    else
        boss:GotoNodeAgain()
    end
end

function BossPreset:GetTargetWithMaxPriority(boss, spellDefinition)
    local x, y = boss:GetX(), boss:GetY()
    local bosOwner = boss:GetOwner()
    local target = nil
    local maxPriority = -1
    Unit.EnumInRange(x,y, spellDefinition.params.range(), function(unit) 
        if bosOwner:IsEnemy(unit:GetOwner()) then
            local currPriority = spellDefinition.GetPriority(spellDefinition, self)(unit)
            if maxPriority <= currPriority then
                target = unit
                maxPriority = currPriority
            end
        end
    end)
    return target
end

function BossPreset:SelectbyMinHP(list)
    local minHP = list[1]:GetHP()
    local unitWithMinHP = list[1]
    for _, unit in pairs(list) do
        local hp = unit:GetHP()
        if minHP > hp then
            unitWithMinHP = unit
            minHP = hp
        end
    end
    return unitWithMinHP
end

function BossPreset:Cast(Boss)
    local abilityId = GetSpellAbilityId()
    for _, ability in pairs(self.abilities) do
        if type(ability.id) == "table" then
            for _, id in pairs(ability.id) do
                if id == abilityId then
                    ability:handler(Boss)
                    break
                end
            end
        else
            if ability.id == abilityId then
                ability:handler(Boss)
                break
            end
        end
    end
end

Log("Creep load succsesfull")
return BossPreset