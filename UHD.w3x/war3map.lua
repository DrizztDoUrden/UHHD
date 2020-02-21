function InitGlobals()
end

do

TestBuild = true
ExtensiveLog = false

end

do
    local function LogFile(...)
        local text = table.concat({...}, "\n")
        Preload("\")\n" .. text .. "\n\\")
        PreloadGenEnd("log.txt")
    end

    local function Log(...)
        if TestBuild then
            local text = table.concat({...}, "\n")
            print(text)
        end
        LogFile(...)
    end

    local modules = {}
    local readyModules = {}

    local oldInitBliz = InitBlizzard

    function InitBlizzard()
        oldInitBliz()
        local resume = {}

        local oldRequire = Require
        function Require(id)
            return table.unpack(coroutine.yield(resume, id))
        end

        local oldClassicReqire = require
        require = Require

        while #modules > 0 do
            local anyFound = false
            for moduleId, module in pairs(modules) do
                if not module.hasErrors and ((not module.requirement) or module.resolvedRequirement) then
                    anyFound = true
                    local ret
                    local coocked = false

                    repeat
                        ret = table.pack(coroutine.resume(module.definition, module.resolvedRequirement))
                        module.resolvedRequirement = nil
                        local correct = table.remove(ret, 1)

                        if not correct then
                            module.hasErrors = true
                            Log(module.id .. " has errors:", table.unpack(ret))
                            break
                        end

                        if #ret == 0 or ret[1] ~= resume then
                            coocked = true
                            break
                        end

                        module.requirement = ret[2]
                        local ready = readyModules[module.requirement]
                        if ready then
                            module.resolvedRequirement = ready
                        end
                    until not module.resolvedRequirement

                    if coocked then
                        LogFile("Successfully loaded " .. module.id)
                        readyModules[module.id] = ret
                        table.remove(modules, moduleId)
                        for _, other in pairs(modules) do
                            if other.requirement == module.id and not other.resolvedRequirement then
                                other.resolvedRequirement = ret
                            end
                        end
                        break
                    else
                        LogFile("Failed to load " .. module.id .. ", missing: " .. module.requirement)
                    end
                end
            end
            if not anyFound then
                local text = "Some modules not resolved:"
                for _, module in pairs(modules) do
                    text = text .. "\n>   " .. module.id .. " has unresolved requirement: " .. module.requirement
                end
                Log(text)
                break
            end
        end

        modules = nil
        readyModules = nil
        Require = oldRequire
        require = oldClassicReqire
        Module = function (id, definition)
            Log("Module loading has already finished. Can't load " .. id)
        end
    end

    function Module(id, definition)
        if type(id) ~= "string" then
            Log("Module id must be string")
            return
        end
        if type(definition) == "table" then
            local t = definition
            definition = function() return t end
        elseif type(definition) ~= "function" then
            Log("Module definition must be function or table")
            return
        end
        table.insert(modules, {
            id = id,
            definition = coroutine.create(definition),
        })
    end
end


-- Start of file Class.lua
Module("Class", function()
local function Class(base, ctor)
    local class = {}

    if not ctor and type(base) == 'function' then
        ctor = base
        base = nil
    elseif type(base) == 'table' then
        for i,v in pairs(base) do
            class[i] = v
        end
        class._base = base
    end

    class.__index = class

    if base and base.ctor and not ctor then
        ctor = base.ctor
    elseif not ctor then
        ctor = function() end
    end

    local mt = {}
    function mt:__call(...)
        local instance = {}
        setmetatable(instance, class)
        instance:ctor(...)
        return instance
    end

    class.ctor = ctor
    function class:GetType()
        return getmetatable(self)
    end
    function class:IsA(other)
        local curClass = self:GetType()
        while curClass do 
            if curClass == other then return true end
            curClass = curClass._base
        end
        return false
    end
    setmetatable(class, mt)
    return class
end

return Class
end)
-- End of file Class.lua
-- Start of file Initialization.lua
Module("Initialization", function()
local Log = require("Log")
local Timer = require("WC3.Timer")

local handlers = {
    initGlobals = { funcs = {}, executed = false, },
    initBlizzard = { funcs = {}, executed = false, },
    initCustomTriggers = { funcs = {}, executed = false, },
    initialization = { funcs = {}, executed = false, },
    gameStart = { funcs = {}, executed = false, },
}

local logInitialization = Log.Category("Initialization")

local function FunctionRegistar(table)
    return setmetatable({}, {
        __index = {
            Add = function(_, func)
                if table.executed then
                    local result, err = pcall(func)
                    if not result then logInitialization:Error(err) end
                else
                    table.funcs[func] = true
                end
            end
        },
    })
end

local Init = {
    Global = FunctionRegistar(handlers.initGlobals),
    CustomTrigger = FunctionRegistar(handlers.initCustomTriggers),
    Initializtion = FunctionRegistar(handlers.initialization),
    Blizzard = FunctionRegistar(handlers.initBlizzard),
    GameStart = FunctionRegistar(handlers.gameStart),
}

local function RunHandlers(table)
    for handler in pairs(handlers[table].funcs) do
        local result, err = pcall(handler)
        if not result then logInitialization:Error(err) end
    end
    handlers[table].funcs = nil
    handlers[table].executed = true
end

local gst = Timer()
gst:Start(0.00, false, function()
    gst:Destroy()
    RunHandlers("gameStart")
end)

local oldInitBliz = InitBlizzard
local oldInitGlobals = InitGlobals
local oldInitTrigs = InitCustomTriggers
local oldInit = RunInitializationTriggers

function InitBlizzard()
    oldInitBliz()
    RunHandlers("initBlizzard")
    if not oldInitGlobals then
        InitGlobals()
    end
    if not oldInitTrigs then
        InitCustomTriggers()
    end
    if not oldInit then
        RunInitializationTriggers()
    end
end

function InitGlobals()
    if oldInitGlobals then oldInitGlobals() end
    RunHandlers("initGlobals")
end

function InitCustomTriggers()
    if oldInitTrigs then oldInitTrigs() end
    RunHandlers("initCustomTriggers")
end

function RunInitializationTriggers()
    if oldInit then oldInit() end
    RunHandlers("initialization")
end

return Init
end)
-- End of file Initialization.lua
-- Start of file Log.lua
Module("Log", function()
local Class = require("Class")

local Verbosity = {
    Fatal = 1,
    Critical = 2,
    Error = 3,
    Warning = 4,
    Message = 5,
    Info = 6,
    Trace = 7,
}

local verbosityNames = {
    "Fatal",
    "Critical",
    "Error",
    "Warning",
    "Message",
    "Info",
    "Trace",
}

local verbosityColors = {
    [Verbosity.Fatal] = { start = "|cffff0000", end_ = "|r", },
    [Verbosity.Critical] = { start = "|cffff0000", end_ = "|r", },
    [Verbosity.Error] = { start = "|cffff0000", end_ = "|r", },
    [Verbosity.Warning] = { start = "|cffffff33", end_ = "|r", },
    [Verbosity.Message] = { start = "", end_ = "", },
    [Verbosity.Info] = { start = "", end_ = "", },
    [Verbosity.Trace] = { start = "", end_ = "", },
}

local function LogInternal(category, verbosity, ...)
    if verbosity <= math.max(category.printVerbosity, category.fileVerbosity) then
        if verbosity <= category.printVerbosity then
            local params = {...}
            table.insert(params, verbosityColors[verbosity].end_)
            print(verbosityColors[verbosity].start .. "[" .. verbosityNames[verbosity] .. "] " .. category.name .. ": ", ...)
        end
        if verbosity <= category.fileVerbosity then
            category.buffer = category.buffer .. "\n[" .. verbosityNames[verbosity] .. "]"
            for _, line in pairs({...}) do
                category.buffer = category.buffer .. "\t" .. tostring(line)
            end
            PreloadGenClear()
            PreloadStart()
            Preload("\")" .. category.buffer .. "\n")
            PreloadGenEnd("Logs\\" .. category.name .. ".txt")
        end
    end
end

local Category = Class()

function Category:ctor(name, options)
    options = options or {}
    self.name = name
    if TestBuild then
        self.printVerbosity = options.printVerbosity or Verbosity.Info
    else
        self.printVerbosity = options.printVerbosity or Verbosity.Warning
    end
    if TestBuild then
        self.fileVerbosity = options.fileVerbosity or Verbosity.Trace
    else
        self.fileVerbosity = options.fileVerbosity or Verbosity.Message
    end
    self.buffer = ""
    PreloadGenClear()
    PreloadStart()
    Preload("")
    PreloadGenEnd("Logs\\" .. self.name .. ".txt")
end

function Category:Log(verbosity, ...)
    LogInternal(self, verbosity, ...)
end

function Category:Fatal(...)
    LogInternal(self, Verbosity.Fatal, ...)
end

function Category:Critical(...)
    LogInternal(self, Verbosity.Critical, ...)
end

function Category:Error(...)
    LogInternal(self, Verbosity.Error, ...)
end

function Category:Warning(...)
    LogInternal(self, Verbosity.Warning, ...)
end

function Category:Message(...)
    LogInternal(self, Verbosity.Message, ...)
end

function Category:Info(...)
    LogInternal(self, Verbosity.Info, ...)
end

function Category:Trace(...)
    LogInternal(self, Verbosity.Trace, ...)
end

Category.Default = Category("Default")

local mt = {
    __call = function(_, ...) LogInternal(Category.Default, Verbosity.Message, ...) end,
    __index = {
        Verbosity = Verbosity,
        Category = Category,
    },
}

local Log = setmetatable({}, mt)

return Log
end)
-- End of file Log.lua
-- Start of file Core\Bos.lua
Module("Core.Bos", function()
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

    local Bos = Class(UHDUnit)

    function Bos:ctor(...)
        UHDUnit.ctor(self, ...)
        self.aggresive = false
        self.spellBook = {}
        self.nextNode = nil

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

    function Bos:OrderToAttack(x, y)
        self.nextNode = {x, y}
        self:IssueAttackPoint(x, y)
    end

    function Bos:GotoNodeAgain()
        if self.nextNode ~= nil then
            self:IssueAttackPoint(self.nextNode[1], self.nextNode[2])
        end
    end

    function Bos:SelectbyMinHP(range)
        local x, y = self:GetX(), self:GetY()
        local bosOwner = self:GetOwner()
        -- BosLog:Info("Choose target")
        local targets = {}
        Unit.EnumInRange(x, y, range, function(unit)
            if bosOwner:IsEnemy(unit:GetOwner()) then
                table.insert(targets, unit)
                self.aggresive = true
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
end)
-- End of file Core\Bos.lua
-- Start of file Core\BosPreset.lua
Module("Core.BosPreset", function()
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
    BosPresetLog:Info("Spawn Bos")
    Bos.secondaryStats = self.secondaryStats
    Bos:ApplyStats()
    Bos.abilities:AddAction(function() self:Cast(Bos) end)

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
end)
-- End of file Core\BosPreset.lua
-- Start of file Core\Core.lua
Module("Core.Core", function()
local Class = require("Class")
local Unit = require("WC3.Unit")
local Trigger = require("WC3.Trigger")
local Player = require("WC3.Player")

local wcplayer = Class(Player)
local Core = Class(Unit)

function Core:ctor(...)
    local owner, x, y, facing = ... 
    self.unitid = FourCC('__HC')

    Unit.ctor(self, owner, self.unitid, x, y, facing)

    self:SetMaxHealth(200)
    self:SetArmor(0)

    local trigger = Trigger()
    trigger:RegisterUnitDeath(self)
    trigger:AddAction(function() wcplayer.PlayersEndGame(false) end)
end

return Core
end)
-- End of file Core\Core.lua
-- Start of file Core\Creep.lua
Module("Core.Creep", function()
local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local Timer = require("WC3.Timer")
local Creep = Class(UHDUnit)
local Log = require("Log")
local creepLog = Log.Category("CreepSpawner\\CreepSpawnerr", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

    function Creep:Destroy()
        local timer = Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end

    function Creep:OrderToAttack(x, y)
        self:IssueAttackPoint(x, y)
    end

    function Creep:Scale(level, heroesCount)
        local mult = (1 + 0.05 * (0.7 * heroesCount +  0)) ^ (level - 1)
        --creepLog:Info("multiplier "..mult)
        self.secondaryStats.health = mult * self.secondaryStats.health
        self.secondaryStats.physicalDamage = mult * self.secondaryStats.physicalDamage
        self.secondaryStats.armor = mult * self.secondaryStats.armor
    end


return Creep
end)
-- End of file Core\Creep.lua
-- Start of file Core\CreepPreset.lua
Module("Core.CreepPreset", function()
local Class = require("Class")
local Log = require("Log")
local Stats = require("Core.Stats")
local Creep = require("Core.Creep")


local CreepPreset = Class()

function CreepPreset:ctor()
    self.secondaryStats = Stats.Secondary()

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

function CreepPreset:Spawn(owner, x, y, facing, level, herocount)
    local creep = Creep(owner, self.unitid, x, y, facing);
    creep.secondaryStats = self.secondaryStats
    creep:Scale(level, herocount)
    creep:ApplyStats()
    return creep
end



Log("Creep load succsesfull")
return CreepPreset
end)
-- End of file Core\CreepPreset.lua
-- Start of file Core\Hero.lua
Module("Core.Hero", function()
local Class = require("Class")
local Stats = require("Core.Stats")
local UHDUnit = require("Core.UHDUnit")
local WC3 = require("WC3.All")
local Log = require("Log")

local logHero = Log.Category("Core\\Hero")

local talentsHelperId = FourCC("__TU")
local statsHelperId = FourCC("__SU")
local statUpgrades = {
    strength = FourCC("SU_0"),
    agility = FourCC("SU_1"),
    intellect = FourCC("SU_2"),
    constitution = FourCC("SU_3"),
    endurance = FourCC("SU_4"),
    willpower = FourCC("SU_5"),
}

local Hero = Class(UHDUnit)

local statsX = 0
local statsY = -1000
Hero.StatsPerLevel = 5
Hero.LevelsForTalent = 5

function Hero:ctor(...)
    UHDUnit.ctor(self, ...)
    self.basicStats = Stats.Basic()
    self.baseSecondaryStats = Stats.Secondary()
    self.bonusSecondaryStats = Stats.Secondary()

    self.leveling = WC3.Trigger()
    self.leveling:RegisterHeroLevel(self)
    self.leveling:AddAction(function() self:OnLevel() end)
    self.toDestroy[self.leveling] = true

    self.abilities = WC3.Trigger()
    self.abilities:RegisterUnitSpellEffect(self)
    self.toDestroy[self.abilities] = true

    self.statUpgrades = {}
    self.skillUpgrades = {}
    self.talentBooks = {}
    self.talents = {}


    self.baseSecondaryStats.health = 100
    self.baseSecondaryStats.mana = 100
    self.baseSecondaryStats.healthRegen = .5
    self.baseSecondaryStats.manaRegen = 1

    self.baseSecondaryStats.weaponDamage = 10
    self.baseSecondaryStats.attackSpeed = .5
    self.baseSecondaryStats.physicalDamage = 1
    self.baseSecondaryStats.spellDamage = 1

    self.baseSecondaryStats.armor = 0
    self.baseSecondaryStats.evasion = 0.05
    self.baseSecondaryStats.ccResist = 0
    self.baseSecondaryStats.spellResist = 0

    self.baseSecondaryStats.movementSpeed = 1


    self.bonusSecondaryStats.health = 0
    self.bonusSecondaryStats.mana = 0
    self.bonusSecondaryStats.healthRegen = 0
    self.bonusSecondaryStats.manaRegen = 0

    self.bonusSecondaryStats.weaponDamage = 0
    self.bonusSecondaryStats.attackSpeed = 1
    self.bonusSecondaryStats.physicalDamage = 1
    self.bonusSecondaryStats.spellDamage = 1

    self.bonusSecondaryStats.armor = 0
    self.bonusSecondaryStats.evasion = 0
    self.bonusSecondaryStats.ccResist = 0
    self.bonusSecondaryStats.spellResist = 0

    self.bonusSecondaryStats.movementSpeed = 0
end

function Hero:Destroy()
    UHDUnit.Destroy(self)
    for u in pairs(self.statUpgrades) do u:Destroy() end
    for u in pairs(self.skillUpgrades) do u:Destroy() end
end

function Hero:OnLevel()
    for _ = 1,Hero.StatsPerLevel do
        self:AddStatPoint()
    end
    local div = self:GetLevel() / Hero.LevelsForTalent
    if math.floor(div) == div then
        self:AddTalentPoint()
    end
end

function Hero:AddStatPoint()
    local statHelper = WC3.Unit(self:GetOwner(), statsHelperId, statsX, statsY, 0)
    self.statUpgrades[statHelper] = true

    for _, id in pairs(statUpgrades) do
        statHelper:AddAbility(id)
    end

    local trigger = WC3.Trigger()
    statHelper.toDestroy[trigger] = true

    trigger:RegisterUnitSpellEffect(statHelper)
    trigger:AddAction(function()
        self.statUpgrades[statHelper] = nil
        statHelper:Destroy()
        self:SelectNextHelper(true)
        local spellId = GetSpellAbilityId()
        for stat, id in pairs(statUpgrades) do
            if id == spellId then
                self.basicStats[stat] = self.basicStats[stat] + 1
                self:UpdateSecondaryStats()
                self:ApplyStats()
                return
            end
        end
        logHero:Error("Invalid spell in stat upgrades: " .. spellId)
    end)
end

function Hero:AddTalentPoint()
    local talentHelper = WC3.Unit(self:GetOwner(), talentsHelperId, statsX, statsY, 0)
    self.skillUpgrades[talentHelper] = true

    for _, id in pairs(self.talentBooks) do
        talentHelper:AddAbility(id)
    end

    local trigger = WC3.Trigger()
    talentHelper.toDestroy[trigger] = true

    trigger:RegisterUnitSpellEffect(talentHelper)
    trigger:AddAction(function()
        self.skillUpgrades[talentHelper] = nil
        talentHelper:Destroy()
        local spellId = GetSpellAbilityId()
        self:SelectNextHelper(false)
        local talent = self.talents[spellId]
        talent.learned = true
        if talent.onTaken then talent:onTaken(self) end
        self:GetOwner():SetTechLevel(talent.tech, 0)
    end)
end

function Hero:SelectNextHelper(prefferStats)
    if self:GetOwner() == WC3.Player.Local then
        ClearSelection()
        if prefferStats then
            for helper in pairs(self.statUpgrades) do helper:Select() return end
            for helper in pairs(self.skillUpgrades) do helper:Select() return end
        else
            for helper in pairs(self.skillUpgrades) do helper:Select() return end
            for helper in pairs(self.statUpgrades) do helper:Select() return end
        end
        -- todo: fix selection
        -- self:Select()
    end
end

local function BonusBeforePow(base, pow, stat, bonus)
    return (base + bonus) * pow^stat
end

local function BonusMul(base, pow, stat, bonus)
    return base * pow^stat * bonus
end

local function ProbabilityBased(base, pow, stat, bonus)
    return base + bonus + (1 - base - bonus) * (1 - pow^stat)
end

function Hero:UpdateSecondaryStats()
    local gtoBase = 1.05
    local ltoBase = 0.95

    self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, gtoBase, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
    self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage)

    self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, math.sqrt(ltoBase), self.basicStats.agility, self.bonusSecondaryStats.evasion)
    self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, math.sqrt(gtoBase), self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

    self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, gtoBase, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

    self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.health)
    self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

    self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.health)
    self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

    self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
    self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)

    self.secondaryStats.movementSpeed = self.baseSecondaryStats.movementSpeed + self.bonusSecondaryStats.movementSpeed
    self.secondaryStats.armor = self.baseSecondaryStats.armor + self.bonusSecondaryStats.armor
end

function Hero:ApplyStats()
    self:UpdateSecondaryStats()
    self:SetStr(self.basicStats.strength, true)
    self:SetAgi(self.basicStats.agility, true)
    self:SetInt(self.basicStats.intellect, true)
    UHDUnit.ApplyStats(self)
end

function Hero:HasTalent(id)
    return self.talents[FourCC(id)].learned
end

return Hero

end)
-- End of file Core\Hero.lua
-- Start of file Core\HeroPreset.lua
Module("Core.HeroPreset", function()
local Class = require("Class")
local Trigger = require("WC3.Trigger")
local Stats = require("Core.Stats")
local Hero = require("Core.Hero")
local Log = require("Log")

local HeroPreset = Class()

local logHeroPreset = Log.Category("Core\\HeroPreset")

function HeroPreset:ctor()
    self.basicStats = Stats.Basic()
    self.secondaryStats = Stats.Secondary()

    self.abilities = {}

    self.secondaryStats.health = 100
    self.secondaryStats.mana = 100
    self.secondaryStats.healthRegen = .5
    self.secondaryStats.manaRegen = 1

    self.secondaryStats.weaponDamage = 10
    self.secondaryStats.attackSpeed = .5
    self.secondaryStats.physicalDamage = 1
    self.secondaryStats.spellDamage = 1

    self.secondaryStats.armor = 0
    self.secondaryStats.evasion = 0.05
    self.secondaryStats.block = 0
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0

    self.secondaryStats.movementSpeed = 1

    self.talents = {}
end

function HeroPreset:Spawn(owner, x, y, facing)
    local hero = Hero(owner, self.unitid, x, y, facing);

    hero.baseSecondaryStats = self.secondaryStats
    hero.basicStats = self.basicStats
    hero:ApplyStats()
    hero.talents = {}
    hero.talentBooks = {}

    for k, v in pairs(self.talentBooks) do hero.talentBooks[k] = v end

    for id, talent in pairs(self.talents) do
        hero.talents[id] = talent
        owner:SetTechLevel(talent.tech, 1)
    end

    hero.abilities:AddAction(function() self:Cast(hero) end)

    for _, ability in pairs(self.abilities) do
        if ability.availableFromStart then
            if type(ability.id) == "table" then
                hero:AddAbility(ability.id[1])
            else
                hero:AddAbility(ability.id)
            end
        end
    end

    if TestBuild then
        hero:AddTalentPoint()
        hero:AddTalentPoint()
    end

    for tech, level in pairs(self.initialTechs or {}) do
        owner:SetTechLevel(tech, level)
    end

    return hero
end

function HeroPreset:AddTalent(heroId, id)
    local talent = { tech = FourCC("U0" .. id), }
    self.talents[FourCC("T" .. heroId .. id)] = talent
    return talent
end

function HeroPreset:Cast(hero)
    local abilityId = GetSpellAbilityId()

    for _, ability in pairs(self.abilities) do
        if type(ability.id) == "table" then
            for _, id in pairs(ability.id) do
                if id == abilityId then
                    ability:handler(hero)
                    break
                end
            end
        else
            if ability.id == abilityId then
                ability:handler(hero)
                break
            end
        end
    end
end

return HeroPreset

end)
-- End of file Core\HeroPreset.lua
-- Start of file Core\Spell.lua
Module("Core.Spell", function()
local Class = require "Class"
local Log = require "Log"

local Spell = Class()

function Spell:ctor(definition, caster)
    self.caster = caster
    for k, v in pairs(definition.params or {}) do
        self[k] = v(definition, caster)
    end
    self:Cast()
end

return Spell
end)
-- End of file Core\Spell.lua
-- Start of file Core\Stats.lua
Module("Core.Stats", function()
local Class = require("Class")
local StatsBase = Class()

function StatsBase:EnumerateNames()
    return pairs(self.names)
end

function StatsBase:Enumerate()
    local ret = {}
    for _, name in self:EnumerateNames() do
        ret[name] = self[name]
    end
    return pairs(ret);
end

function StatsBase:__add(other)
    if not other or not other.IsA or not other:IsA(self) then
        error("Invalid stats operation (+): second operand is not same stats")
    end
    local ret = self()
    for name, value in self:Enumerate() do
        ret[name] = value + other[name]
    end
end

function StatsBase:__sub(other)
    if not other or not other.IsA or not other:IsA(self) then
        error("Invalid stats operation (-): second operand is not same stats")
    end
    local ret = self()
    for name, value in self:Enumerate() do
        ret[name] = value - other[name]
    end
end

local Stats = {}

Stats.Basic = Class(StatsBase)

function Stats.Basic:ctor()
    self.names = {
        "strength",
        "agility",
        "intellect",
        "constitution",
        "endurance",
        "willpower",
    }

    for _, stat in self:EnumerateNames() do self[stat] = 0 end
end

Stats.Secondary = Class(StatsBase)

function Stats.Secondary:ctor()
    self.names = {
        "health",
        "mana",

        "healthRegen",
        "manaRegen",

        "weaponDamage",
        "attackSpeed",
        "physicalDamage",
        "spellDamage",

        "armor",
        "evasion",
        "block",
        "ccResist",
        "spellResist",

        "movementSpeed",
    }

    for _, stat in self:EnumerateNames() do self[stat] = 0 end
end

return Stats
end)
-- End of file Core\Stats.lua
-- Start of file Core\Tavern.lua
Module("Core.Tavern", function()
local Class = require("Class")
local WC3 = require("WC3.All")
local Log = require("Log")

local logTavern = Log.Category("Core\\Tavern")

local heroSpawnX = -2300
local heroSpawnY = -3400

local Tavern = Class(WC3.Unit)


function Tavern:ctor(owner, x, y, facing, heroPresets)
    WC3.Unit.ctor(self, owner, FourCC("n000"), x, y, facing)

    heroPresets[1]:Spawn(WC3.Player.Get(8), heroSpawnX, heroSpawnY, 0)

    self.owner = owner
    self.heroPresets = heroPresets
    self:AddTrigger()
end

function Tavern:AddTrigger()
    local trigger = WC3.Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
        local buying = WC3.Unit.GetBying()
        local sold = WC3.Unit.GetSold()
        local whichOwner = sold:GetOwner()
        local id = sold:GetTypeId()
        logTavern:Trace("Unit bought with id "..id)
        for _, hero in pairs(self.heroPresets) do
            if hero.unitid == id then
                hero:Spawn(whichOwner, heroSpawnX, heroSpawnY, 0)
                break
            end
        end
        buying:Destroy()
        sold:Destroy()
    end)
end


return Tavern

end)
-- End of file Core\Tavern.lua
-- Start of file Core\UHDUnit.lua
Module("Core.UHDUnit", function()
local Class = require("Class")
local Stats = require("Core.Stats")
local WC3 = require("WC3.All")
local Log = require("Log")

local logUnit = Log.Category("Core\\Unit")

local UHDUnit = Class(WC3.Unit)

UHDUnit.armorValue = 0.06

function UHDUnit:ctor(...)
    WC3.Unit.ctor(self, ...)
    self.secondaryStats = Stats.Secondary()
    self.effects = {}

    self.secondaryStats.health = 100
    self.secondaryStats.mana = 100
    self.secondaryStats.healthRegen = .5
    self.secondaryStats.manaRegen = 1

    self.secondaryStats.weaponDamage = 10
    self.secondaryStats.attackSpeed = .5
    self.secondaryStats.physicalDamage = 1
    self.secondaryStats.spellDamage = 1

    self.secondaryStats.armor = 0
    self.secondaryStats.evasion = 0.05
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 0

    self.secondaryStats.movementSpeed = 1

    self.onDamageDealt = {}
    self.onDamageReceived = {}
end

function UHDUnit:CheckSecondaryStat0_1(name)
    if self.secondaryStats[name] < 0 or self.secondaryStats[name] > 1 then
        logUnit:Error("Value of " .. name .. " of " .. self:GetName() .. " can't be outside of [0;1]")
        self.secondaryStats[name] = math.min(1, math.max(0, self.secondaryStats[name]))
    end
end

function UHDUnit:ApplyStats()
    local oldMaxHp = self:GetMaxHP()
    local oldMaxMana = self:GetMaxMana()
    local oldHp = self:GetHP()
    local oldMana = self:GetMana()

    self:CheckSecondaryStat0_1("evasion")
    self:CheckSecondaryStat0_1("ccResist")
    self:CheckSecondaryStat0_1("spellResist")

    self:SetMaxHealth(self.secondaryStats.health)
    self:SetMaxMana(self.secondaryStats.mana)
    self:SetBaseDamage(self.secondaryStats.weaponDamag * self.secondaryStats.physicalDamage)
    self:SetAttackCooldown(1 / self.secondaryStats.attackSpeed)
    self:SetArmor(self.secondaryStats.armor)
    self:SetHpRegen(self.secondaryStats.healthRegen)
    self:SetManaRegen(self.secondaryStats.manaRegen)
    self:SetMoveSpeed(self.secondaryStats.movementSpeed)

    if oldMaxHp > 0 then
        self:SetHP(oldHp * self.secondaryStats.health / oldMaxHp)
    else
        self:SetHP(self.secondaryStats.health)
    end
    if oldMaxMana > 0 then
        self:SetMana(oldMana * self.secondaryStats.mana / oldMaxMana)
    else
        self:SetMana(self.secondaryStats.mana)
    end
end

function UHDUnit:DamageDealt(args)
    for handler in pairs(self.onDamageDealt) do
        handler(args)
    end
end

function UHDUnit:DamageReceived(args)
    for handler in pairs(self.onDamageReceived) do
        handler(args)
    end
end

function UHDUnit:DealDamage(target, damage)
    local dmg = damage.value
    if damage.isAttack then
        dmg = damage.value * (1 - UHDUnit.armorValue^target.secondaryStats.armor)
    else
        dmg = damage.value * (1 - target.secondaryStats.spellResist)
    end
    local hpAfterDamage = target:GetHP() - dmg
    if hpAfterDamage < 0 then
        hpAfterDamage = 0
        dmg = dmg + hpAfterDamage
    end
    local args = {
        source = self,
        target = target,
        recursion = damage.recursion or {},
        isAttack = damage.isAttack,
        GetDamage = function() return dmg end,
        SetDamage = function(_, value) dmg = value end,
    }
    self:DamageDealt(args)
    if target:IsA(UHDUnit) then target:DamageDealt(args) end
    self:DamageTarget(target, dmg, false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_UNKNOWN, WEAPON_TYPE_WHOKNOWS)
    return dmg
end

function UHDUnit:Heal(target, value)
    target:SetHP(math.min(self.secondaryStats.health, target:GetHP() + value))
end

local unitDamaging = WC3.Trigger()
for i=0,23 do unitDamaging:RegisterPlayerUnitDamaging(WC3.Player.Get(i)) end
unitDamaging:AddAction(function()
    local damageType = BlzGetEventDamageType()
    if damageType == DAMAGE_TYPE_UNKNOWN then
        return
    end
    local source = WC3.Unit.GetEventDamageSource()
    local target = WC3.Unit.GetEventDamageTarget()
    local args = {
        source = source,
        target = target,
        recursion = {},
        isAttack = true, --todo
        GetDamage = function() return GetEventDamage() end,
        SetDamage = function(_, value) BlzSetEventDamage(value) end
    }
    if source:IsA(UHDUnit) then source:DamageDealt(args) end
    if target:IsA(UHDUnit) then target:DamageReceived(args) end
end)

return UHDUnit
end)
-- End of file Core\UHDUnit.lua
-- Start of file Core\WaveObserver.lua
Module("Core.WaveObserver", function()
local Class = require("Class")
local Log = require("Log")
local Timer = require("WC3.Timer")
local Trigger = require("WC3.Trigger")
local Creep = require("Core.Creep")
local PathNode = require("Core.Node.PathNode")
local CreepSpawner = require("Core.Node.CreepSpawner")
local wcplayer = require("WC3.Player")

local logWaveObserver = Log.Category("WaveObserver\\WaveObserver", {
     printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })


local WaveObserver = Class()

function WaveObserver:ctor(owner)
    local node = PathNode(-2300, -3800, nil)
    local node1 = PathNode(-2300, 5000, node)
    local creepSpawner1 = CreepSpawner(owner, 1600, 5000, node1, 0)
    local creepSpawner2 = CreepSpawner(owner, -5800, 5000, node1, 0)
    local trigger = Trigger()
    self.needtokillallcreep = false
    local creepcount = 0
    local level = 1
    trigger:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    trigger:AddAction(function()
        local whichcreep = Creep.GetDying()
        whichcreep:Destroy()
        creepcount = creepcount - 1
    end)
    local wavetimer  = Timer()
    
    local triggercheckalldead = Trigger()
    triggercheckalldead:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_DEATH, nil)
    triggercheckalldead:AddAction(function ()
    if creepcount == 0 and self.needtokillallcreep then
        if creepSpawner1:HasNextWave(level) then
            logWaveObserver:Info("Bos spawn")
            creepSpawner1:SpawnNewWave(level, 2)
            creepSpawner2:SpawnNewWave(level, 2)
            level = level + 1
        else
            wcplayer.PlayersEndGame(true)
        end
    end
    end)

    Log(" Create Timer")
    
    wavetimer:Start(25, true, function()
        if creepSpawner1:HasNextWave(level) then
            logWaveObserver:Info("WAVE"..level)
            creepcount = creepcount + creepSpawner1:SpawnNewWave(level, 2)
            creepcount = creepcount + creepSpawner2:SpawnNewWave(level, 2)
            level = level + 1
            if math.floor(level/10) == level/10 then
                self.needtokillallcreep = true
                logWaveObserver:Info("Next Boss")
                wavetimer:Destroy()
            end
        end
    end)


end
return WaveObserver

end)
-- End of file Core\WaveObserver.lua
-- Start of file Core\WaveSpecification.lua
Module("Core.WaveSpecification", function()
local Log = require("Log")

    local waveComposition = { 
        [1] = {{
            count = 4,
            unit = "Ghoul",
            ability = nil
        }},
        [2] = {{
            count = 5,
            unit = "Ghoul",
            ability = nil
        }},
        [3] = {{
            count = 5,
            unit = "MagicDragon",
            ability = nil
        }},
        [4] = {{
            count = 2,
            unit = "Ghoul",
            ability = nil
        },
        {
            count = 3,
            unit = "MagicDragon",
            ability = nil
        }},
        [5] = {{
            count = 5,
            unit = "Necromant",
            ability = nil
        }},
        [6] = {{
            count = 5,
            unit = "Necromant",
            ability = nil
        }},
        [7] = {{
            count = 5,
            unit = "Faceless",
            ability = nil
        }},
        [8] = {{
            count = 3,
            unit = "Faceless",
            ability = nil
        },{
            count = 3,
            unit = "Necromant",
            ability = nil
        }},
        [9] = {{
            count = 2,
            unit = "Faceless",
            ability = nil
        },
        {
            count = 2,
            unit = "Ghoul",
            ability = nil
        },{
            count = 2,
            unit = "Necromant",
            ability = nil
        },{
            count = 3,
            unit = "MagicDragon",
            ability = nil
        }},
        [10] = {{
            count = 1,
            unit = "DefiledTree",
            ability = nil
        }},
    }
Log("WaveSpecification is load")
return waveComposition
end)
-- End of file Core\WaveSpecification.lua
-- Start of file Core\Creeps\Faceless.lua
Module("Core.Creeps.Faceless", function()
local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 20
    self.secondaryStats.mana = 10
    self.secondaryStats.weaponDamage = 3
    self.secondaryStats.evasion = 0.15
    
    self.unitid = FourCC('e004')
end
Log("MagicDragon load successfull")

return MagicDragon
end)
-- End of file Core\Creeps\Faceless.lua
-- Start of file Core\Creeps\Ghoul.lua
Module("Core.Creeps.Ghoul", function()
local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 35
    self.secondaryStats.mana = 0
    self.secondaryStats.weaponDamage = 1

    self.unitid = FourCC('e002')
end
Log("MagicDragon load successfull")

return MagicDragon
end)
-- End of file Core\Creeps\Ghoul.lua
-- Start of file Core\Creeps\MagicDragon.lua
Module("Core.Creeps.MagicDragon", function()
local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 10
    self.secondaryStats.mana = 5
    self.secondaryStats.weaponDamage = 3
    self.secondaryStats.evasion = 0.1
    self.unitid = FourCC('e000')
end
Log("MagicDragon load successfull")

return MagicDragon
end)
-- End of file Core\Creeps\MagicDragon.lua
-- Start of file Core\Creeps\Necromant.lua
Module("Core.Creeps.Necromant", function()
local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 20
    self.secondaryStats.mana = 5
    self.secondaryStats.weaponDamage = 4
    self.secondaryStats.evasion = 0
    self.unitid = FourCC('e003')
end
Log("MagicDragon load successfull")

return MagicDragon
end)
-- End of file Core\Creeps\Necromant.lua
-- Start of file Core\CreepsBos\DefiledTree.lua
Module("Core.CreepsBos.DefiledTree", function()
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
    self.secondaryStats.weaponDamage = 4
    self.secondaryStats.physicalDamage = 35
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
        local target = Bos:SelectbyMinHP(700)
        Bos:IssueTargetOrderById(851983, target)
        for i, value in pairs(self.abilities) do
            if Bos:GetCooldown(value.id, 0) == 0 then
                -- treeLog:Info("range "..value.params.duration())
                local target = Bos:SelectbyMinMana(600)
                Bos:IssueTargetOrderById(OrderId('absorb'), target)
                break
            end
        end
        if not Bos.aggresive then
            Bos:GotoNodeAgain()
        end
        end)
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
end)
-- End of file Core\CreepsBos\DefiledTree.lua
-- Start of file Core\Node\CreepSpawner.lua
Module("Core.Node.CreepSpawner", function()
local Log = require("Log")
local Class = require("Class")
local Node = require("Core.Node.Node")
local waveComopsion = require("Core.WaveSpecification")
local CreepClasses = {
    MagicDragon = require("Core.Creeps.MagicDragon"), 
    Faceless = require("Core.Creeps.Faceless"),
    Ghoul = require("Core.Creeps.Ghoul"),
    Necromant = require("Core.Creeps.Necromant"),
    DefiledTree = require("Core.CreepsBos.DefiledTree") }

local CreepSpawner = Class(Node)

local logCreepSpawner = Log.Category("CreepSpawner\\CreepSpawnerr", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

function CreepSpawner:ctor(owner,  x, y, prevnode, facing)
    Node.ctor(self, x, y, prevnode)
    self.owner = owner
    self.facing = facing
    self.maxlevel = #waveComopsion
    logCreepSpawner:Info("Max level: "..self.maxlevel)
    self.waveComopsion = waveComopsion
end

function CreepSpawner:GetWaveSpecification(level)
    local wave = self.waveComopsion[level]
    return wave
end

function CreepSpawner:HasNextWave(level)
    return level <= self.maxlevel
end

function CreepSpawner:SpawnNewWave(level, herocount)
    -- logCreepSpawner:Info("WAVE "..self.level + 1)
    local wave = self:GetWaveSpecification(level)
    local acc = 0
    for i, unit in pairs(wave) do
        for j = 1, unit["count"] do
            local creepPresetClass = CreepClasses[unit["unit"]]
            local creepPreset = creepPresetClass()
            local creep = creepPreset:Spawn(self.owner, self.x, self.y, self.facing, level, herocount)
            local x, y = self.prev:GetCenter()
            creep:OrderToAttack(x, y)
            acc = acc + 1
        end
    end
    return acc
end

Log("CreepSpawner load succsesfull")
return CreepSpawner
end)
-- End of file Core\Node\CreepSpawner.lua
-- Start of file Core\Node\Node.lua
Module("Core.Node.Node", function()
local Class = require("Class")
local Log = require("Log")

local Node = Class()

function Node:ctor(x, y, prev)
    self.x = x
    self.y = y
    self.prev = prev
end

function Node:GetCenter()
    return self.x, self.y
end

return Node

end)
-- End of file Core\Node\Node.lua
-- Start of file Core\Node\PathNode.lua
Module("Core.Node.PathNode", function()
local Class = require("Class")
local Log = require("Log")

local Trigger = require("WC3.Trigger")
local Unit = require("WC3.Unit")
local Creep = require("Core.Creep")
local RectNode = require("Core.Node.RectNode")
local PathNode = Class(RectNode)
function PathNode:ctor(x, y, prev)
    RectNode.ctor(self, 100, 100, x, y, prev)
    if prev ~= nil then
        self:SetEvent()
    end
end


function PathNode:SetEvent(formation)
    Log(" Add trigger to path Node in"..self.x.." "..self.y)
    local trigger = Trigger()
    trigger:RegisterEnterRegion(self.region)
    trigger:AddAction(function()
        local whichunit = Unit.GetEntering()
        if self.prev and whichunit:IsA(Creep) then
            local x, y = self.prev:GetCenter()
            whichunit:OrderToAttack(x, y)
        end
    end)
end

return PathNode
end)
-- End of file Core\Node\PathNode.lua
-- Start of file Core\Node\RectNode.lua
Module("Core.Node.RectNode", function()
local Class = require("Class")
local Log = require("Log")
local WCRect = require("WC3.Rect")
local Region = require("WC3.Region")
local Node = require("Core.Node.Node")

local RectNode = Class(Node)

function RectNode:ctor(sizex, sizey, x, y, prevnode)
    Node.ctor(self, x, y, prevnode)
    self.region = Region()
    self.sizex = sizex
    self.sizey = sizey
    local rect = WCRect(x - self.sizex, y - self.sizey, x + self.sizex, y + self.sizey)
    self.region:AddRect(rect)
end

function RectNode:IsUnitInNode(whichUnit)
    return self.region:IsUnitIn(whichUnit)
end

return RectNode
end)
-- End of file Core\Node\RectNode.lua
-- Start of file Heroes\DuskKnight.lua
Module("Heroes.DuskKnight", function()
local Class = require("Class")
local Timer = require("WC3.Timer")
local Trigger = require("WC3.Trigger")
local Unit = require("WC3.Unit")
local HeroPreset = require("Core.HeroPreset")
local UHDUnit = require("Core.UHDUnit")
local Log = require("Log")
local Spell = require "Core.Spell"

local logDuskKnight = Log.Category("Heroes\\Dusk Knight", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
})

local DuskKnight = Class(HeroPreset)

local DrainLight = Class(Spell)
local HeavySlash = Class(Spell)
local ShadowLeap = Class(Spell)
local DarkMend = Class(Spell)

function DuskKnight:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_DK')

    self.abilities = {
        drainLight = {
            id = FourCC('DK_0'),
            handler = DrainLight,
            availableFromStart = true,
            params = {
                radius = function(_) return 300 end,
                duration = function(_) return 2 end,
                period = function(_) return 0.1 end,
                effectDuration = function(_) return 10 end,
                armorRemoved = function(_) return 10 end,
                gainLimit = function(_) return 30 end,
                stealPercentage = function(_) return 0.25 end,
                damage = function(_, caster)
                    if caster:HasTalent("T001") then return 5 * caster.secondaryStats.spellDamage end
                    return 0
                end,
                healLimit = function(_, caster) return 10 * caster.secondaryStats.spellDamage end,
            },
        },
        heavySlash = {
            id = FourCC('DK_1'),
            handler = HeavySlash,
            availableFromStart = true,
            params = {
                radius = function(_) return 125 end,
                distance = function(_) return 100 end,
                baseDamage = function(_, caster)
                    local value = 20
                    if caster:HasTalent("T011") then value = value + 15 end
                    return value * caster.secondaryStats.physicalDamage
                end,
                baseSlow = function(_) return 0.3 end,
                slowDuration = function(_) return 3 end,
                manaBurn = function(_, caster)
                    if caster:HasTalent("T010") then return 20 end
                    return 0
                end,
                vampirism = function(_, caster)
                    if caster:HasTalent("T012") then return 0.15 end
                    return 0
                end,
            },
        },
        shadowLeap = {
            id = FourCC('DK_2'),
            handler = ShadowLeap,
            availableFromStart = true,
            params = {
                period = function(_) return 0.05 end,
                duration = function(_) return 0.5 end,
                distance = function(_) return 300 end,
                baseDamage = function(_, caster) return 20 * caster.secondaryStats.spellDamage end,
                push = function(_) return 100 end,
                pushDuration = function(_) return 0.5 end,
            },
        },
        darkMend = {
            id = FourCC('DK_3'),
            handler = DarkMend,
            availableFromStart = true,
            params = {
                baseHeal = function(_, caster)
                    local value = 20
                    if caster:HasTalent("T030") then value = value * 0.75 end
                    return value * caster.secondaryStats.spellDamage
                end,
                duration = function(_) return 4 end,
                percentHeal = function(_, caster)
                    local value = 0.1
                    if caster:HasTalent("T030") then value = value * 0.75 end
                    return value
                end,
                period = function(_) return 0.1 end,
                instantHeal = function(_, caster)
                    if caster:HasTalent("T030") then return 0.5 end
                    return 0
                end,
                healOverTime = function(_, caster)
                    if caster:HasTalent("T030") then return 0.75 end
                    return 1
                end,
            },
        },
    }

    self.talentBooks = {
        FourCC("DKT0"),
        FourCC("DKT1"),
        FourCC("DKT2"),
        FourCC("DKT3"),
    }

    self:AddTalent("0", "00")
    self:AddTalent("0", "01")
    self:AddTalent("0", "02")

    self:AddTalent("0", "10")
    self:AddTalent("0", "11")
    self:AddTalent("0", "12")

    self:AddTalent("0", "20")
    self:AddTalent("0", "21")
    self:AddTalent("0", "22")

    self:AddTalent("0", "30")
    self:AddTalent("0", "31").onTaken = function(_, hero)
        hero:SetManaCost(self.abilities.darkMend.id, 0, 0)
        hero:SetCooldown(self.abilities.darkMend.id, 0, hero:GetCooldown(self.abilities.darkMend.id, 0) - 3)
    end
    self:AddTalent("0", "32")

    self.basicStats.strength = 12
    self.basicStats.agility = 6
    self.basicStats.intellect = 12
    self.basicStats.constitution = 11
    self.basicStats.endurance = 8
    self.basicStats.willpower = 11
end

function DrainLight:ctor(definition, caster)
    self.affected = {}
    self.bonus = 0
    Spell.ctor(self, definition, caster)
end

function DrainLight:Cast()
    local timer = Timer()

    Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), self.radius, function(unit)
        if self.caster ~= unit and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            table.insert(self.affected, {
                unit = unit,
                stolen = 0,
                toSteal = self.armorRemoved,
                toReturn = self.armorRemoved,
                toBonus = self.stealPercentage,
            })
        end
    end)

    timer:Start(self.period, true, function()
        if self.caster:GetHP() <= 0 then
            timer:Destroy()
            self:End()
            return
        end

        self.duration = self.duration - self.period
        self.healed = 0

        for _, target in pairs(self.affected) do
            if target.unit:GetHP() > 0 then
                self:Drain(target)
            end
        end

        if self.duration <= 0 then
            timer:Destroy()
            self:Effect()
        end
    end)
end

function DrainLight:Effect()
    local timer = Timer()
    local trigger = Trigger()

    trigger:RegisterUnitDeath(self.caster)

    trigger:AddAction(function()
        timer:Destroy()
        trigger:Destroy()
        self:End()
    end)

    timer:Start(self.effectDuration, false, function()
        timer:Destroy()
        trigger:Destroy()
        self:End()
    end)
end

function DrainLight:End()
    for _, target in pairs(self.affected) do
        target.unit:SetArmor(target.unit:GetArmor() + target.toReturn)
    end
    self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor - self.bonus
    self.caster:ApplyStats()
end

function DrainLight:Drain(target)
    local toStealNow = (target.toSteal - target.stolen) * self.period / self.duration
    target.unit:SetArmor(target.unit:GetArmor() + target.stolen)
    target.stolen = target.stolen + toStealNow
    target.unit:SetArmor(target.unit:GetArmor() - target.stolen)
    if self.bonus < self.gainLimit then
        local toBonus = math.min(self.gainLimit - self.bonus, toStealNow * target.toBonus)
        self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor + toBonus
        self.caster:ApplyStats()
        self.bonus = self.bonus + toBonus
    end
    if self.damage > 0 then
        local damagePerTick = self.period * self.damage
        local damage = self.caster:DealDamage(target.unit, { value = damagePerTick, })
        if self.healed < self.healLimit * self.period then
            local toHeal = math.min(self.healLimit * self.period - self.healed, self.stealPercentage * damage)
            self.healed = self.healed + toHeal
            self.caster:Heal(self.caster, toHeal)
        end
    end
end

function HeavySlash:Cast()
    local facing = self.caster:GetFacing() * math.pi / 180
    local x = self.caster:GetX() + math.cos(facing) * self.distance
    local y = self.caster:GetY() + math.sin(facing) * self.distance
    local affected = {}

    Unit.EnumInRange(x, y, self.radius, function(unit)
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
            local damage = self.caster:DealDamage(unit, { value = self.baseDamage, isAttack = true, })
            if self.manaBurn > 0 then unit:SetMana(math.max(0, unit:GetMana() - self.manaBurn)) end
            if self.vampirism > 0 then self.caster:Heal(self.caster, self.vampirism * damage) end

            if unit:IsA(UHDUnit) then
                affected[unit] = true
                unit.secondaryStats.movementSpeed = unit.secondaryStats.movementSpeed * (1 - self.baseSlow)
                unit.secondaryStats.attackSpeed = unit.secondaryStats.attackSpeed * (1 - self.baseSlow)
                unit:ApplyStats()
            end
        end
    end)

    local timer = Timer()
    timer:Start(self.slowDuration, false, function()
        timer:Destroy()
        for unit in pairs(affected) do
            unit.secondaryStats.movementSpeed = unit.secondaryStats.movementSpeed / (1 - self.baseSlow)
            unit.secondaryStats.attackSpeed = unit.secondaryStats.attackSpeed / (1 - self.baseSlow)
            unit:ApplyStats()
        end
    end)
end

function ShadowLeap:Cast()
    local timer = Timer()
    local timeLeft = self.duration
    local affected = {}
    local pushTicks = math.floor(self.pushDuration / self.period);
    local targetX = GetSpellTargetX()
    local targetY = GetSpellTargetY()
    local targetDistance = math.sqrt((targetX - self.caster:GetX())^2 + (targetY - self.caster:GetY())^2)
    local selfPush = math.min(targetDistance, self.distance) / math.floor(self.duration / self.period)
    local castAngle = math.atan(targetY - self.caster:GetY(), targetX - self.caster:GetX())

    local selfPushX = selfPush * math.cos(castAngle)
    local selfPushY = selfPush * math.sin(castAngle)
    timer:Start(self.period, true, function()
        if timeLeft <= -self.pushDuration then
            timer:Destroy()
        end
        if timeLeft > 0 then
            self.caster:SetX(self.caster:GetX() + selfPushX)
            self.caster:SetY(self.caster:GetY() + selfPushY)
            Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), 75, function (unit)
                if not affected[unit] and self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                    local angle = math.atan(self.caster:GetY() - unit:GetY(), self.caster:GetX() - unit:GetX())
                    affected[unit] = {
                        x = self.push * math.cos(angle) / pushTicks,
                        y = self.push * math.sin(angle) / pushTicks,
                        ticksLeft = pushTicks,
                    }
                    self.caster:DealDamage(unit, { value = self.baseDamage, isAttack = true, })
                end
            end)
        end
        timeLeft = timeLeft - self.period
        for unit, push in pairs(affected) do
            unit:SetX(unit:GetX() + push.x)
            unit:SetY(unit:GetY() + push.y)
            push.ticksLeft = push.ticksLeft - 1
            if push.ticksLeft == 0 then
                affected[unit] = nil
            end
        end
    end)
end

function DarkMend:Cast()
    local timer = Timer()
    local timeLeft = self.duration
    local curHp = self.caster:GetHP();
    local part = 1 / math.floor(self.period / self.duration)
    self.caster:SetHP(curHp + (curHp * self.percentHeal + self.baseHeal) * self.instantHeal)
    timer:Start(self.period, true, function()
        local curHp = self.caster:GetHP();
        if curHp <= 0 then
            timer:Destroy()
            return
        end
        timeLeft = timeLeft - self.period
        self.caster:Heal(self.caster, (curHp * self.percentHeal + self.baseHeal) * part * self.healOverTime)
        if timeLeft <= 0 then
            timer:Destroy()
        end
    end)
end

return DuskKnight
end)
-- End of file Heroes\DuskKnight.lua
-- Start of file Heroes\Mutant.lua
Module("Heroes.Mutant", function()
local Class = require("Class")
local HeroPreset = require("Core.HeroPreset")
local WC3 = require("WC3.All")
local Spell = require "Core.Spell"
local Log = require "Log"

local logMutant = Log.Category("Heroes\\Mutant")

local Mutant = Class(HeroPreset)

local BashingStrikes = Class(Spell)
local TakeCover = Class(Spell)
local Meditate = Class(Spell)
local Rage = Class(Spell)

function Mutant:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_MT')

    self.abilities = {
        bashingStrikes = {
            id = FourCC('MT_0'),
            handler = BashingStrikes,
            availableFromStart = true,
            params = {
                attacks = function(_, caster)
                    local value = 3
                    if caster:HasTalent("T100") then value = value + 1 end
                    return value
                end,
                attackSpeedBonus = function(_, caster)
                    local value = 0.5
                    if caster:HasTalent("T101") then value = value + 0.2 end
                    return value
                end,
                healPerHit = function(_) return 0.05 end,
                endlessRageLimit = function(_, caster)
                    if caster:HasTalent("T102") then return 8 end
                    return 0
                end
            },
        },
        takeCover = {
            id = { FourCC('MT_1'), FourCC('MTD1'), },
            handler = TakeCover,
            availableFromStart = true,
            params = {
                radius = function(_) return 500 end,
                baseRedirect = function(_) return 0.3 end,
                redirectPerRage = function(_) return 0.02 end,
                manaPerHealth = function(_, caster)
                    local value = 1
                    if caster:HasTalent("T110") then value = value * 0.75 end
                    return value
                end,
                damageReduction = function(_, caster)
                    local value = 0
                    if caster:HasTalent("T111") then value = 0.15 end
                    return value
                end,
                damageReflection = function(_, caster)
                    local value = 0
                    if caster:HasTalent("T112") then value = 0.15 end
                    return value
                end,
            },
        },
        meditate = {
            id = FourCC('MT_2'),
            handler = Meditate,
            availableFromStart = true,
            params = {
                castTime = function(_) return 2 end,
                castSlow = function(_, caster)
                    local value = -0.7
                    if caster:HasTalent("T121") then value = 0 end
                    return value
                end,
                healPerRage = function(_) return 0.05 end,
                manaHealPerRage = function(_, caster)
                    local value = 0
                    if caster:HasTalent("T120") then value = value + 0.025 end
                    return value
                end,
            },
        },
        rage = {
            id = FourCC('MT_3'),
            handler = Rage,
            availableFromStart = true,
            params = {
                ragePerAttack = function(_) return 1 end,
                damagePerRage = function(_) return 1 end,
                armorPerRage = function(_, caster)
                    local value = -1
                    if caster:HasTalent("T130") then value = value + 0.2 end
                    return value
                end,
                startingStacks = function(_) return 3 end,
                maxStacks = function(_, caster)
                    local value = 10
                    if caster:HasTalent("T131") then value = value + 5 end
                    return value
                end,
                stackDecayTime = function(_, caster)
                    local value = 3
                    if caster:HasTalent("T132") then value = value + 1.5 end
                    return value
                end,
                meditationCooldown = function(_, caster)
                    local value = 20
                    if caster:HasTalent("T122") then value = value - 10 end
                    return value
                end,
            },
        },
    }

    self.initialTechs = {
        [FourCC("MTU0")] = 0,
        [FourCC("R001")] = 1,
        [FourCC("R002")] = 1,
    }

    self.talentBooks = {
        FourCC("MTT0"),
        FourCC("MTT1"),
        FourCC("MTT2"),
        FourCC("MTT3"),
    }

    self:AddTalent("1", "00")
    self:AddTalent("1", "01")
    self:AddTalent("1", "02")

    self:AddTalent("1", "10")
    self:AddTalent("1", "11")
    self:AddTalent("1", "12")

    self:AddTalent("1", "20")
    self:AddTalent("1", "21")
    self:AddTalent("1", "22")

    self:AddTalent("1", "30")
    self:AddTalent("1", "31")
    self:AddTalent("1", "32")

    self.basicStats.strength = 16
    self.basicStats.agility = 6
    self.basicStats.intellect = 7
    self.basicStats.constitution = 13
    self.basicStats.endurance = 8
    self.basicStats.willpower = 10
end

function BashingStrikes:Cast()
    self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed * (1 + self.attackSpeedBonus)
    self.caster:ApplyStats()
    self.caster:GetOwner():SetTechLevel(FourCC("R002"), 0)
    self.caster:SetCooldownRemaining(FourCC("MT_0"), 0)

    local function handler()
        self.caster:SetHP(math.min(self.caster.secondaryStats.health, self.caster:GetHP() + self.healPerHit * self.caster.secondaryStats.health))
        local rage = self.caster.effects["Mutant.Rage"]
        if not rage or rage.stacks > self.endlessRageLimit then
            self.attacks = self.attacks - 1
        end
        if self.attacks <= 0 then
            self.caster:GetOwner():SetTechLevel(FourCC("R002"), 1)
            self.caster:SetCooldownRemaining(FourCC("MT_0"), 10)
            self.caster.onDamageDealt[handler] = nil
            self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed / (1 + self.attackSpeedBonus)
            self.caster:ApplyStats()
        end
    end

    self.caster.onDamageDealt[handler] = true
end

function TakeCover:Cast()
    if not self.caster.effects["Mutant.TakeCover"] then
        self:Enable()
    else
        self:Disable()
    end
end

function TakeCover:Enable()
    self.caster:RemoveAbility(FourCC('MT_1'))
    self.caster:AddAbility(FourCC('MTD1'))
    self.caster:SetCooldownRemaining(FourCC('MTD1'), 5)
    self.caster.effects["Mutant.TakeCover"] = true

    self.handler = function(args)
        if args.recursion["Mutant.TakeCover"] then
            return
        end
        local nearest
        local nearestRange = math.huge
        WC3.Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), self.radius, function(unit)
            if unit ~= self.caster and unit:IsHero() and not self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                local range = math.sqrt((self.caster:GetX() - unit:GetX())^2 + (self.caster:GetY() - unit:GetY())^2)
                if range < nearestRange then
                    nearest = unit
                    nearestRange = range
                end
            end
        end)

        if not nearest then
            return
        end

        local damage = args.GetDamage()
        local rage = self.caster.effects["Mutant.Rage"] or {}
        local rageStacks = rage.stacks or 0
        local redirected = (self.baseRedirect + self.redirectPerRage * rageStacks) * damage

        local mpBurned = redirected / self.caster:GetMaxHP() * self.caster:GetMaxMana() * self.manaPerHealth
        local curMp = self.caster:GetMana()

        if curMp < mpBurned then
            redirected = redirected * curMp / mpBurned
            mpBurned = curMp
        end

        self.caster:SetMana(curMp - mpBurned)
        args:SetDamage((damage - redirected) * (1 - self.damageReduction))

        do
            local recursion = { ["Mutant.TakeCover"] = true, }
            for k, v in pairs(args.recursion) do recursion[k] = v end

            local toAlly = {
                value = redirected * (1 - self.damageReduction),
                isAttack = false,
                recursion = recursion,
            }
            args.source:DealDamage(nearest, toAlly)
        end

        if self.damageReflection > 0 then
            local recursion = { ["Mutant.TakeCover.Reflect"] = true, }
            for k, v in pairs(args.recursion) do recursion[k] = v end

            local toReflect = {
                value = damage.value * self.damageReflection,
                isAttack = false,
                recursion = recursion,
            }
            self.caster.source:DealDamage(nearest, toReflect)
        end
    end

    self.caster.onDamageReceived[self.handler] = true
end

function TakeCover:Disable()
    self.caster:RemoveAbility(FourCC('MTD1'))
    self.caster:AddAbility(FourCC('MT_1'))
    self.caster:SetCooldownRemaining(FourCC('MT_1'), 5)
    self.caster.effects["Mutant.TakeCover"] = nil
    self.caster.onDamageReceived[self.handler] = nil
end

function Meditate:Cast()
    local timer = WC3.Timer()
    self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed * (1 + self.castSlow)
    self.caster:ApplyStats()

    timer:Start(self.castTime, false, function()
        timer:Destroy()
        self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed * (1 - self.castSlow)
        self.caster:ApplyStats()
        local rage = self.caster.effects["Mutant.Rage"]
        if rage then
            local curHp = self.caster:GetHP()
            local percentHealed = rage.stacks * self.healPerRage
            local heal = (self.caster.secondaryStats.health - curHp) * percentHealed
            self.caster:SetHP(curHp + heal)
            if self.manaHealPerRage then
                local manaHealPart = self.manaHealPerRage * rage.stacks
                local curMp = self.caster:GetMana()
                self.caster:SetMana(curMp + manaHealPart * (self.caster:GetMaxMana() - curMp))
            end
            rage:SetStacks(0)
        end
    end)
end

function Rage:Cast()
    self.caster:GetOwner():SetTechLevel(FourCC("R001"), 0)
    self.caster:GetOwner():SetTechLevel(FourCC("MTU0"), 1)
    self.caster:SetCooldownRemaining(FourCC('MT_3'), 0)
    self.caster:SetCooldownRemaining(FourCC('MT_2'), self.meditationCooldown)
    self.caster.effects["Mutant.Rage"] = self
    self:SetStacks(self.startingStacks)

    self.handler = function()
        self:SetStacks(self.stacks + self.ragePerAttack)
    end

    self.timer = WC3.Timer()

    self.timer:Start(self.stackDecayTime, true, function()
        self:SetStacks(self.stacks - 1)
    end)

    self.caster.onDamageDealt[self.handler] = true
end

function Rage:SetStacks(value)
    value = math.min(self.maxStacks, value)
    if self.stacks == value then return end
    if self.stacks then
        self.caster.bonusSecondaryStats.weaponDamage = self.caster.bonusSecondaryStats.weaponDamage - self.damagePerRage * self.stacks
        self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor - self.armorPerRage * self.stacks
    end
    self.stacks = value
    self.caster.bonusSecondaryStats.weaponDamage = self.caster.bonusSecondaryStats.weaponDamage + self.damagePerRage * self.stacks
    self.caster.bonusSecondaryStats.armor = self.caster.bonusSecondaryStats.armor + self.armorPerRage * self.stacks
    self.caster:ApplyStats()
    if self.stacks <= 0 then
        self:Destroy()
    end
end

function Rage:Destroy()
    self.timer:Destroy()
    self.caster.onDamageDealt[self.handler] = nil
    self.caster:GetOwner():SetTechLevel(FourCC("R001"), 1)
    self.caster:GetOwner():SetTechLevel(FourCC("MTU0"), 0)
    self.caster:SetCooldownRemaining(FourCC('MT_3'), 20)
    self.caster.effects["Mutant.Rage"] = nil
end

return Mutant
end)
-- End of file Heroes\Mutant.lua
-- Start of file Tests\Initialization.lua
Module("Tests.Initialization", function()
local Log = require("Log")
local Init = require("Initialization")

local logTimer = Log.Category("Tests\\Initialization")

if TestBuild then
    local globalInit = "false";
    local customTriggerInit = "false";
    local initializtion = "false";
    local blizz = "false";

    Init.Global:Add(function ()
        globalInit = "true"
    end)
    Init.CustomTrigger:Add(function ()
        customTriggerInit = "true"
    end)
    Init.Initializtion:Add(function ()
        initializtion = "true"
    end)
    Init.Blizzard:Add(function ()
        blizz = "true"
    end)
    Init.GameStart:Add(function()
        logTimer:Trace("GameStart: true")
        logTimer:Trace("InitGlobals: " .. globalInit)
        logTimer:Trace("InitCustomTriggers: " .. customTriggerInit)
        logTimer:Trace("RunInitializationTriggers: " .. initializtion)
        logTimer:Trace("InitBlizzard: " .. blizz)
    end)
end

end)
-- End of file Tests\Initialization.lua
-- Start of file Tests\Main.lua
Module("Tests.Main", function()
local Log = require("Log")
local WC3 = require("WC3.All")
local DuskKnight = require("Heroes.DuskKnight")
local Mutant = require("Heroes.Mutant")
local WaveObserver = require("Core.WaveObserver")
local Core = require("Core.Core")
local Tavern = require("Core.Tavern")
local Timer = require("WC3.Timer")
local DefiledTree = require("Core.CreepsBos.DefiledTree")
local logMain = Log.Category("Main")

local heroPresets = {
    DuskKnight(),
    Mutant(),
}

-- preloading heroes to reduce lags
-- before doing that it's needed to finish the cleanup in Hero:Destroy. e.g. stat/talent helpers should be deleted as well
-- also it would be cool to add a mode of hero spawning which also spawns stat/talent helpers to make sure they get preloaded too
--[[
for _, preset in pairs(heroPresets) do
    preset::Spawn(WCPlayer.Get(0), 0, -1600, 0):Destroy()
end
]]
for i = 0, 7, 1 do
    local shiftx = 1300 + i * 100
    local unit = WC3.Unit(WC3.Player.Get(i), FourCC("e001"), shiftx, -3600, 0)
end
logMain = Log.Category("AddSpell")
logMain:Info("Start Map")
--local unit = WC3.Unit(WC3.Player.Get(0), FourCC("bs00"), -2100, -3800, 0)
-- heroPresets[1]:Spawn(WC3.Player.Get(9), -2300, -3400, 0)
-- heroPresets[1]:Spawn(WC3.Player.Get(9), -2300, -3400, 0)
Core(WC3.Player.Get(8), -2300, -3800, 0)
Tavern(WC3.Player.Get(0), 1600, -3800, 0, heroPresets)
-- local Bos = DefiledTree():Spawn(WC3.Player.Get(0), -2300, -3500, 0)
local timerwaveObserver = Timer()
timerwaveObserver:Start(25, false,
    function() WaveObserver(WC3.Player.Get(9))
end)


logMain:Message("Game initialized successfully")
end)
-- End of file Tests\Main.lua
-- Start of file WC3\AbilityInstance.lua
Module("WC3.AbilityInstance", function()
local Class = require("Class")

local AbilityInstance = Class()

function AbilityInstance:ctor(handle)
    self.handle = handle
end

function AbilityInstance:SetHpRegen(level, value)
    return BlzSetAbilityRealLevelField(self.handle, ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND, level, value)
end

function AbilityInstance:SetMpRegen(level, value)
    return BlzSetAbilityRealLevelField(self.handle, ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND, level, value)
end

return AbilityInstance
end)
-- End of file WC3\AbilityInstance.lua
-- Start of file WC3\All.lua
Module("WC3.All", function()
local WC3 = {
    AbilityInstance = require("WC3.AbilityInstance"),
    Location = require("WC3.Location"),
    Player = require("WC3.Player"),
    Rect = require("WC3.Rect"),
    Region = require("WC3.Region"),
    Timer = require("WC3.Timer"),
    Trigger = require("WC3.Trigger"),
    Unit = require("WC3.Unit"),
}

return WC3
end)
-- End of file WC3\All.lua
-- Start of file WC3\Location.lua
Module("WC3.Location", function()
local Class = require("Class")

local Location = Class()

function Location.SpellTarget()
    return Location(GetSpellTargetLoc())
end

function Location:ctor(...)
    if #{...} > 1 then
        self.x, self.y, self.z = ...
        self.z = self.z or 0
    else
        local loc = ...
        self.x = GetLocationX(loc)
        self.y = GetLocationY(loc)
        self.z = GetLocationZ(loc)
        RemoveLocation(loc)
    end
end

return Location
end)
-- End of file WC3\Location.lua
-- Start of file WC3\Player.lua
Module("WC3.Player", function()
local Class = require("Class")
local Timer = require("WC3.Timer")

local WCPlayer = Class()
local players = {}
local playersCount = 12
local isEnd = false

function WCPlayer.Get(player)
    if math.type(player) == "integer" then
        player = Player(player)
    end
    if not players[player] then
        players[player] = WCPlayer(player)
    end
    return players[player]
end


function WCPlayer.PlayersRemoweWithResult(isAVictory)
    local result = nil
    if isAVictory then
        result = PLAYER_GAME_RESULT_VICTORY
    else
        result = PLAYER_GAME_RESULT_DEFEAT
    end
    local tplayer = {}
    for id = 0, playersCount, 1  do
        local player = WCPlayer.Get(id)
        tplayer[id] = player
    end
    for id = 0, playersCount, 1  do
        tplayer[id]:RemovePlayer(result)
    end
    EndGame(true)
end

function WCPlayer.PlayersEndGame(isAVictory)
    local timer = Timer()
    if not isEnd then
        isEnd = true
        if isAVictory then
            WCPlayer.DisplayTextToAll("VICTORY")
        else
            WCPlayer.DisplayTextToAll("DEFEAT")
        end
        timer:Start(10, false, function()
            EndGame()
        end)
    end
end

function  WCPlayer.DisplayTextToAll(text)
    for id = 0, 23, 1 do
        DisplayTextToPlayer(WCPlayer.Get(id).handle, 0, 0, text)
    end
end

function WCPlayer:DisplayText(text)
    DisplayTextToPlayer(self.handle, 0, 0, text)
end



function  WCPlayer:RemovePlayer(playerGameResult)
    RemovePlayer(self.handle, playerGameResult)
    players[self.handle] = nil
end

function WCPlayer:ctor(player)
    self.handle = player
end

function WCPlayer:IsEnemy(other)
    if not other:IsA(WCPlayer) then
        error("Expected player as an argument", 2)
    end
    return IsPlayerEnemy(self.handle, other.handle)
end

function WCPlayer:SetTechLevel(tech, value)
    SetPlayerTechResearched(self.handle, tech, value)
end

WCPlayer.Local = WCPlayer.Get(GetLocalPlayer())

return WCPlayer
end)
-- End of file WC3\Player.lua
-- Start of file WC3\Rect.lua
Module("WC3.Rect", function()
local Class = require("Class")

local WCRect = Class()

function WCRect:ctor(...)
    local minx, miny, maxx, maxy = ...
    self.handle = Rect(minx, miny, maxx, maxy)
end

function WCRect:Destroy()
    RemoveRect(self.handle)
end

return WCRect
end)
-- End of file WC3\Rect.lua
-- Start of file WC3\Region.lua
Module("WC3.Region", function()
local Class = require("Class")

local Region = Class()
local regions = {}

function Region.GetTriggering()
    local handle = GetTriggeringRegion()
    if handle == nil then
        return nil
    end
    local existing = regions[handle]
    if existing then
        return existing
    end
    return Region(handle)
end

local function Register(region)
    if regions[region.handle] then
        error("Attempt to reregister a region", 3)
    end
    regions[region.handle] = region
end

function Region:ctor(handle)
    self.handle = handle or CreateRegion()
    Register(self)
end

function Region:Destroy()
    RemoveRegion(self.handle)
end

function Region:IsUnitIn(whichUnit)
    return IsUnitInRegion(self.handle, whichUnit.handle)
end

function Region:AddRect(rect)
    RegionAddRect(self.handle, rect.handle)
end

return Region
end)
-- End of file WC3\Region.lua
-- Start of file WC3\Timer.lua
Module("WC3.Timer", function()
local Class = require("Class")
local Log = require("Log")

local Timer = Class()

local logTimer = Log.Category("WC3\\Timer")

function Timer:ctor()
    self.handle = CreateTimer()
end

function Timer:Destroy()
    DestroyTimer(self.handle)
end

function Timer:Start(period, periodic, onEnd)
    TimerStart(self.handle, period, periodic, function()
        local result, err = pcall(onEnd)
        if not result then
            logTimer:Error("Error running timer handler: " .. err)
        end
    end)
end

return Timer
end)
-- End of file WC3\Timer.lua
-- Start of file WC3\Trigger.lua
Module("WC3.Trigger", function()
local Class = require("Class")
local Log = require("Log")
local Unit = require("WC3.Unit")

local logTrigger = Log.Category("WC3\\Trigger")

local Trigger = Class()

function Trigger:ctor()
    self.handle = CreateTrigger()
end

function Trigger:Destroy()
    DestroyTrigger(self.handle)
end

function Trigger:RegisterPlayerUnitEvent(player, event, filter)
    if filter then
        filter = function()
            local result, errOrRet = pcall(filter, Unit.Get(GetFilterUnit()))
            if not result then
                logTrigger:Error("Error filtering player units for and event: " .. errOrRet)
                return false
            end
            return errOrRet
        end
    end
    return TriggerRegisterPlayerUnitEvent(self.handle, player.handle, event, Filter(filter))
end

function Trigger:RegisterUnitSold(unit)
    TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_SELL)
end

function Trigger:RegisterUnitDeath(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_DEATH)
end

function Trigger:RegisterUnitSpellEffect(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_SPELL_EFFECT)
end

function Trigger:RegisterHeroLevel(unit)
    return TriggerRegisterUnitEvent(self.handle, unit.handle, EVENT_UNIT_HERO_LEVEL)
end

function Trigger:RegisterPlayerUnitDamaging(player, filter)
    if filter then
        filter = function()
            local result, errOrRet = pcall(filter, Unit.Get(GetFilterUnit()))
            if not result then
                logTrigger:Error("Error filtering player units for and event: " .. errOrRet)
                return false
            end
            return errOrRet
        end
    end
    return TriggerRegisterPlayerUnitEvent(self.handle, player.handle, EVENT_PLAYER_UNIT_DAMAGING, Filter(filter))
end

function Trigger:RegisterEnterRegion(region, filter)
    if filter then
        filter = function ()
            local result, errOrRet
            if not result then
                logTrigger:Error("Error filtering Region for and event: "..errOrRet)
                return false
            end
            return errOrRet
        end
    end
    return TriggerRegisterEnterRegion(self.handle, region.handle, filter)
end

function Trigger:AddAction(action)
    return TriggerAddAction(self.handle, function()
        local result, err = pcall(action)
        if not result then
            logTrigger:Error("Error running trigger action: " .. err)
        end
    end)
end

return Trigger
end)
-- End of file WC3\Trigger.lua
-- Start of file WC3\Unit.lua
Module("WC3.Unit", function()
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

function Unit:IssueTargetOrderById(order, target)
    if math.type(order) == "integer" then
        local result = IssueTargetOrderById(self.handle, order, target.handle)
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
end)
-- End of file WC3\Unit.lua
function CreateUnitsForPlayer0()
    local p = Player(0)
    local u
    local unitID
    local t
    local life
    u = BlzCreateUnitWithSkin(p, FourCC("ushd"), -2332.8, -3133.0, 77.006, FourCC("ushd"))
end

function CreatePlayerBuildings()
end

function CreatePlayerUnits()
    CreateUnitsForPlayer0()
end

function CreateAllUnits()
    CreatePlayerBuildings()
    CreatePlayerUnits()
end

function InitCustomPlayerSlots()
    SetPlayerStartLocation(Player(0), 0)
    SetPlayerColor(Player(0), ConvertPlayerColor(0))
    SetPlayerRacePreference(Player(0), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(0), true)
    SetPlayerController(Player(0), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(1), 1)
    SetPlayerColor(Player(1), ConvertPlayerColor(1))
    SetPlayerRacePreference(Player(1), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(1), true)
    SetPlayerController(Player(1), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(2), 2)
    SetPlayerColor(Player(2), ConvertPlayerColor(2))
    SetPlayerRacePreference(Player(2), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(2), true)
    SetPlayerController(Player(2), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(3), 3)
    SetPlayerColor(Player(3), ConvertPlayerColor(3))
    SetPlayerRacePreference(Player(3), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(3), true)
    SetPlayerController(Player(3), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(4), 4)
    SetPlayerColor(Player(4), ConvertPlayerColor(4))
    SetPlayerRacePreference(Player(4), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(4), true)
    SetPlayerController(Player(4), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(5), 5)
    SetPlayerColor(Player(5), ConvertPlayerColor(5))
    SetPlayerRacePreference(Player(5), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(5), true)
    SetPlayerController(Player(5), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(6), 6)
    SetPlayerColor(Player(6), ConvertPlayerColor(6))
    SetPlayerRacePreference(Player(6), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(6), true)
    SetPlayerController(Player(6), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(7), 7)
    SetPlayerColor(Player(7), ConvertPlayerColor(7))
    SetPlayerRacePreference(Player(7), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(7), true)
    SetPlayerController(Player(7), MAP_CONTROL_USER)
    SetPlayerStartLocation(Player(8), 8)
    SetPlayerColor(Player(8), ConvertPlayerColor(8))
    SetPlayerRacePreference(Player(8), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(8), true)
    SetPlayerController(Player(8), MAP_CONTROL_COMPUTER)
    SetPlayerStartLocation(Player(9), 9)
    SetPlayerColor(Player(9), ConvertPlayerColor(9))
    SetPlayerRacePreference(Player(9), RACE_PREF_RANDOM)
    SetPlayerRaceSelectable(Player(9), true)
    SetPlayerController(Player(9), MAP_CONTROL_COMPUTER)
end

function InitCustomTeams()
    SetPlayerTeam(Player(0), 0)
    SetPlayerState(Player(0), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(1), 0)
    SetPlayerState(Player(1), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(2), 0)
    SetPlayerState(Player(2), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(3), 0)
    SetPlayerState(Player(3), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(4), 0)
    SetPlayerState(Player(4), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(5), 0)
    SetPlayerState(Player(5), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(6), 0)
    SetPlayerState(Player(6), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(7), 0)
    SetPlayerState(Player(7), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerTeam(Player(8), 0)
    SetPlayerState(Player(8), PLAYER_STATE_ALLIED_VICTORY, 1)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(0), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(1), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(2), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(3), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(4), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(5), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(7), true)
    SetPlayerAllianceStateAllyBJ(Player(6), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(7), Player(8), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(0), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(1), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(2), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(3), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(4), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(5), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(6), true)
    SetPlayerAllianceStateAllyBJ(Player(8), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(0), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(1), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(2), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(3), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(4), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(5), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(7), true)
    SetPlayerAllianceStateVisionBJ(Player(6), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(7), Player(8), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(0), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(1), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(2), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(3), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(4), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(5), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(6), true)
    SetPlayerAllianceStateVisionBJ(Player(8), Player(7), true)
    SetPlayerTeam(Player(9), 1)
end

function InitAllyPriorities()
    SetStartLocPrioCount(0, 7)
    SetStartLocPrio(0, 0, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(0, 1, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(0, 2, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(0, 3, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(0, 4, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(0, 5, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(0, 6, 7, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(1, 7)
    SetStartLocPrio(1, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 1, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 2, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 3, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 4, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 5, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(1, 6, 7, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(2, 7)
    SetStartLocPrio(2, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(2, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(2, 2, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(2, 3, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(2, 4, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(2, 5, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(2, 6, 7, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(3, 6)
    SetStartLocPrio(3, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(3, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(3, 2, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(3, 3, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(3, 4, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(3, 5, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(4, 7)
    SetStartLocPrio(4, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 2, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 3, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 4, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 5, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(4, 6, 7, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(5, 7)
    SetStartLocPrio(5, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(5, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(5, 2, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(5, 3, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(5, 4, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(5, 5, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(5, 6, 7, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(6, 7)
    SetStartLocPrio(6, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(6, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(6, 2, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(6, 3, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(6, 4, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(6, 5, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(6, 6, 7, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(7, 7)
    SetStartLocPrio(7, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(7, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(7, 2, 2, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(7, 3, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(7, 4, 4, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(7, 5, 5, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(7, 6, 6, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(8, 3)
    SetStartLocPrio(8, 0, 0, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(8, 1, 1, MAP_LOC_PRIO_HIGH)
    SetStartLocPrio(8, 2, 2, MAP_LOC_PRIO_HIGH)
    SetEnemyStartLocPrioCount(8, 4)
    SetEnemyStartLocPrio(8, 0, 0, MAP_LOC_PRIO_HIGH)
    SetEnemyStartLocPrio(8, 1, 1, MAP_LOC_PRIO_HIGH)
    SetEnemyStartLocPrio(8, 2, 2, MAP_LOC_PRIO_HIGH)
    SetEnemyStartLocPrio(8, 3, 3, MAP_LOC_PRIO_HIGH)
    SetStartLocPrioCount(9, 2)
    SetStartLocPrio(9, 0, 8, MAP_LOC_PRIO_HIGH)
end

function main()
    SetCameraBounds(-7424.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -6656.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 8192.0 - GetCameraMargin(CAMERA_MARGIN_TOP), -7424.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 8192.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -6656.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    SetDayNightModels("Environment\\DNC\\DNCDalaran\\DNCDalaranTerrain\\DNCDalaranTerrain.mdl", "Environment\\DNC\\DNCDalaran\\DNCDalaranUnit\\DNCDalaranUnit.mdl")
    NewSoundEnvironment("Default")
    SetAmbientDaySound("DalaranRuinsDay")
    SetAmbientNightSound("DalaranRuinsNight")
    SetMapMusic("Music", true, 0)
    CreateAllUnits()
    InitBlizzard()
    InitGlobals()
end

function config()
    SetMapName("TRIGSTR_001")
    SetMapDescription("TRIGSTR_003")
    SetPlayers(10)
    SetTeams(10)
    SetGamePlacement(MAP_PLACEMENT_TEAMS_TOGETHER)
    DefineStartLocation(0, 0.0, -1984.0)
    DefineStartLocation(1, 0.0, -1984.0)
    DefineStartLocation(2, 0.0, -1984.0)
    DefineStartLocation(3, 0.0, -1984.0)
    DefineStartLocation(4, 0.0, -1984.0)
    DefineStartLocation(5, 0.0, -1984.0)
    DefineStartLocation(6, 0.0, -1984.0)
    DefineStartLocation(7, 0.0, -1984.0)
    DefineStartLocation(8, 0.0, -1984.0)
    DefineStartLocation(9, 0.0, -1984.0)
    InitCustomPlayerSlots()
    InitCustomTeams()
    InitAllyPriorities()
end

