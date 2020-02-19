local Class = require("Class")
local Log = require("Log")
local Stats = require("Core.Stats")
local Bos = require("Core.Bos")
local Unit = require("WC3.Unit")
local Timer = require("WC3.Timer")

local BosPresetLog = Log.Category("Bos\\BosPreset", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

local BosPreset = Class()

function BosPreset:ctor()
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
end

function BosPreset:Spawn(owner, x, y, facing)
    local Bos = Bos(owner, self.unitid, x, y, facing);

    Bos.secondaryStats = self.secondaryStats
    Bos:ApplyStats()
    Bos.abilities:AddAction(function() self:Cast(Bos) end)
    local timerAttack = Timer()
    Bos.toDestroy[timerAttack] = true
    Bos.timerAttack:Start(1, true, function()
        BosPresetLog:Info("Choose aim")
        local target = Bos:SelectbyMinHP(700)
        BosPresetLog:Info("target in : "..target:PosX().." "..target:PosY())
        Bos:IssueTargetOrderById(851983, target)
        for i, value in pairs(Bos.spellBook) do
            if value:AutoCast() then
                local timer = Timer()
                timer:Start(value.cooldown + 0.2, true, function()
                    if not value:AddAction() then
                        timer:Destroy()
                    end
                end)
                Bos.toDestroy[timer] = true
            end
        end
        end)

    for i, ability in pairs(self.abilities) do
        BosPresetLog:Info("Number "..i)
        if ability.availableFromStart then
            BosPresetLog:Info("Try to add ability")
            Bos:AddAbility(ability.id)
        end
    end
    return Bos
end

function BosPreset:Cast(Bos)
    local abilityId = GetSpellAbilityId()
    for _, ability in pairs(self.abilities) do
        if type(ability.id) == "table" then
            for _, id in pairs(ability.id) do
                if id == abilityId then
                    ability:handler(Bos)
                    break
                end
            end
        else
            if ability.id == abilityId then
                ability:handler(Bos)
                break
            end
        end
    end
end




Log("Creep load succsesfull")
return BosPreset