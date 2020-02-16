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

local function FunctionRegistar(table)
    return setmetatable({}, {
        __index = {
            Add = function(_, func)
                if table.executed then
                    local result, err = pcall(func)
                    if not result then Log(err) end
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
        if not result then Log(err) end
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

local function LogInternal(category, verbosity, ...)
    if verbosity <= math.max(category.printVerbosity, category.fileVerbosity) then
        if verbosity <= category.printVerbosity then
            print("[" .. verbosityNames[verbosity] .. "] " .. category.name .. ": ", ...)
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

    function Creep:Destroy()
        local timer = Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
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
    self.secondaryStats.evasion = 30
    self.secondaryStats.block = 0
    self.secondaryStats.ccResist = 0
    self.secondaryStats.spellResist = 30

    self.secondaryStats.movementSpeed = 1
end

function CreepPreset:Spawn(owner, x, y, facing)
    local creep = Creep(owner, self.unitid, x, y, facing);
    creep.secondaryStats = self.secondaryStats
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
local Trigger = require("WC3.Trigger")
local Unit = require("WC3.Unit")
local Log = require("Log")
local WCPlayer = require("WC3.Player")

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

    self.leveling = Trigger()
    self.leveling:RegisterHeroLevel(self)
    self.leveling:AddAction(function() self:OnLevel() end)
    self.toDestroy[self.leveling] = true

    self.abilities = Trigger()
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
    local statHelper = Unit(self:GetOwner(), statsHelperId, statsX, statsY, 0)
    self.statUpgrades[statHelper] = true

    for _, id in pairs(statUpgrades) do
        statHelper:AddAbility(id)
    end

    local trigger = Trigger()
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
    local talentHelper = Unit(self:GetOwner(), talentsHelperId, statsX, statsY, 0)
    self.skillUpgrades[talentHelper] = true

    for _, id in pairs(self.talentBooks) do
        talentHelper:AddAbility(id)
    end

    local trigger = Trigger()
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
    if self:GetOwner() == WCPlayer.Local then
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
    self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

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
            hero:AddAbility(ability.id)
            hero:SetAbilityLevel(ability.id, 1)
        end
    end

    if TestBuild then
        hero:AddTalentPoint()
        hero:AddTalentPoint()
    end

    return hero
end

function HeroPreset:AddTalent(id)
    local talent = { tech = FourCC("U" .. id), }
    self.talents[FourCC("T" .. id)] = talent
    return talent
end

function HeroPreset:Cast(hero)
    local abilityId = GetSpellAbilityId()

    for _, ability in pairs(self.abilities) do
        if ability.id == abilityId then
            ability:handler(hero)
            break
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
local Unit = require("WC3.Unit")
local Trigger = require("WC3.Trigger")
local Log = require("Log")

local logTavern = Log.Category("Core\\Tavern")

local heroSpawnX = 100
local heroSpawnY = -1600

local Tavern = Class(Unit)

function Tavern:ctor(owner, x, y, facing, heroPresets)
    Unit.ctor(self, owner, FourCC("n000"), x, y, facing)

    self.owner = owner
    self.heroPresets = heroPresets

    for _, hero in pairs(heroPresets) do
        logTavern:Info(hero.unitid, "==", FourCC("H_DK"), " is ", hero.unitid == FourCC("H_DK"))
        logTavern:Info(self:GetTypeId(), "==", FourCC("n000"), " is ", self:GetTypeId() == FourCC("n000"))
        self:AddUnitToStock(hero.unitid)
    end
    self:AddTrigger()
end

function Tavern:AddTrigger()
    local trigger = Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
        local whicUnit = Unit.GetSold()
        local whichOwner = whicUnit:GetOwner()
        local id = whicUnit:GetTypeId()
        whicUnit:Destroy()
        for _, hero in pairs(self.heroPresets) do
            if hero.unitid == id then
                hero:Spawn(whichOwner, heroSpawnX, heroSpawnY, 0)
                return
            end
        end
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

local UHDUnit = Class(WC3.Unit)

local hpRegenAbility = FourCC('_HPR')
local mpRegenAbility = FourCC('_MPR')

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

    self:AddAbility(hpRegenAbility)
    self:AddAbility(mpRegenAbility)
end

function UHDUnit:ApplyStats()
    local oldMaxHp = self:GetMaxHP()
    local oldMaxMana = self:GetMaxMana()
    local oldHp = self:GetHP()
    local oldMana = self:GetMana()

    self:SetMaxHealth(self.secondaryStats.health)
    self:SetMaxMana(self.secondaryStats.mana)
    self:SetBaseDamage(self.secondaryStats.weaponDamage)
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

function UHDUnit:DamageDealt()
    local args = {
        source = self
    }
    for handler in pairs(self.onDamageDealt) do
        handler(args)
    end
end

function UHDUnit:DealDamage(target, damage)
    local dmg = damage.value
    if damage.isAttack then
        dmg = damage.value * (1 - math.pow(UHDUnit.armorValue, target.secondaryStats.armor))
    else
        dmg = damage.value * (1 - target.secondaryStats.spellResist)
    end
    local hpAfterDamage = target:GetHP() - dmg
    if hpAfterDamage < 0 then
        hpAfterDamage = 0
        dmg = dmg + hpAfterDamage
    end
    target:SetHP(hpAfterDamage)
    self:DamageDealt()
    return dmg
end

local unitDamaging = WC3.Trigger()
for i=0,23 do unitDamaging:RegisterPlayerUnitDamaging(WC3.Player.Get(i)) end
unitDamaging:AddAction(function()
    local source = WC3.Unit.GetEventDamageSource()
    if source.IsA(UHDUnit) then source:DamageDealt() end
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
    local node = PathNode(0, -1800, nil)
    local node1 = PathNode(0, 0, node)
    local creepSpawner1 = CreepSpawner(owner, 1600, 0, node1, 0)
    local creepSpawner2 = CreepSpawner(owner, -1600, 0, node1, 0)
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
        wcplayer.PlayersEndGame(true)
    end
    end)

    Log(" Create Timer")
    
    wavetimer:Start(15, true, function()
        if creepSpawner1:IsANextWave(level) then
            logWaveObserver:Info("WAVE"..level)
            creepcount = creepcount + creepSpawner1:SpawnNewWave(level)
            creepcount = creepcount + creepSpawner2:SpawnNewWave(level)
            level = level + 1
            if not creepSpawner1:IsANextWave(level) then
                Log("level "..level)
                self.needtokillallcreep = true
                logWaveObserver:Info("No waves")
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

local levelCreepCompositon = {
    {"MagicDragon"},
    {"MagicDragon"},
    {"MagicDragon"},
    {"MagicDragon"},
    {"MagicDragon"},}
    local nComposition = {
        {5},
        {5},
        {5},
        {5},
        {5},
    }
    local aComposition = {
        {nil},
        {nil},
        {nil},
        {nil},
        {nil}
    }

Log("WaveSpecification is load")
return levelCreepCompositon, nComposition, aComposition, 5
end)
-- End of file Core\WaveSpecification.lua
-- Start of file Core\Creeps\MagicDragon.lua
Module("Core.Creeps.MagicDragon", function()
local Class = require("Class")
local CreepPreset = require("Core.CreepPreset")
local Log = require("Log")

local MagicDragon = Class(CreepPreset)

function MagicDragon:ctor()
    CreepPreset.ctor(self)
    self.secondaryStats.health = 15
    self.secondaryStats.mana = 5
    self.secondaryStats.weaponDamage = 3

    self.unitid = FourCC('e000')
end
Log("MagicDragon load successfull")

return MagicDragon
end)
-- End of file Core\Creeps\MagicDragon.lua
-- Start of file Core\Node\CreepSpawner.lua
Module("Core.Node.CreepSpawner", function()
local Log = require("Log")
local Class = require("Class")
local Node = require("Core.Node.Node")
local levelCreepsComopsion, nComposion, aComposition, maxlevel = require("Core.WaveSpecification")
local CreepClasses = { MagicDragon = require("Core.Creeps.MagicDragon") }

local CreepSpawner = Class(Node)

local logCreepSpawner = Log.Category("CreepSpawner\\CreepSpawnerr", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

function CreepSpawner:ctor(owner,  x, y, prevnode, facing)
    Node.ctor(self, x, y, prevnode)
    self.owner = owner
    self.facing = facing
    Log("Max level: "..maxlevel)
    self.levelCreepsComopsion = levelCreepsComopsion
    self.nComposion = nComposion
    self.maxlevel = maxlevel
    self.aComposition = aComposition
end

function CreepSpawner:GetWaveSpecification(level)
    local result_CreepsComposition = self.levelCreepsComopsion[level]
    local result_nComposion = self.nComposion[level]
    local result_aComposion = self.aComposition[level]
    return result_CreepsComposition, result_nComposion, result_aComposion
end

function CreepSpawner:IsANextWave(level)
    if level < self.maxlevel then
        return true
    end
    return false
end

function CreepSpawner:SpawnNewWave(level)
    -- logCreepSpawner:Info("WAVE "..self.level + 1)
    local CreepsComposition, nComposion, aComposition = self:GetWaveSpecification(level)
    local acc = 0
    for i, CreepName in pairs(CreepsComposition) do
        for j = 1, nComposion[i] do
            local creepPresetClass = CreepClasses[CreepName]
            local creepPreset = creepPresetClass()
            local creep = creepPreset:Spawn(self.owner, self.x, self.y, self.facing)
            local x, y = self.prev:GetCenter()
            creep:IssueAttackPoint(x, y)
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
            whichunit:IssueAttackPoint(x, y)
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

    self:AddTalent("000")
    self:AddTalent("001")
    self:AddTalent("002")

    self:AddTalent("010")
    self:AddTalent("011")
    self:AddTalent("012")

    self:AddTalent("020")
    self:AddTalent("021")
    self:AddTalent("022")

    self:AddTalent("030")
    self:AddTalent("031").onTaken = function(_, hero) hero:SetManaCost(self.abilities.darkMend.id, 1, 0) hero:SetCooldown(self.abilities.darkMend.id, 1, hero:GetCooldown(self.abilities.darkMend.id, 1) - 3) end
    self:AddTalent("032")

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
        if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
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
        local damage = self.caster:DealDamage(target.unit, { value = damagePerTick, isAttack = false, })
        if self.healed < self.healLimit * self.period then
            local toHeal = math.min(self.healLimit * self.period - self.healed, self.stealPercentage * damage)
            self.healed = self.healed + toHeal
            self.caster:SetHP(math.min(self.caster:GetMaxHP(), self.caster:GetHP() + toHeal))
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
            if self.vampirism > 0 then self.caster:SetHP(math.min(self.caster:GetMaxHP(), self.vampirism * damage)) end

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
        self.caster:SetHP(curHp + (curHp * self.percentHeal + self.baseHeal) * part * self.healOverTime)
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

local Mutant = Class(HeroPreset)

local BashingStrikes = Class(Spell)
local TakeCover = Class(Spell)
local Rage = Class(Spell)
local Meditation = Class(Spell)

function Mutant:ctor()
    HeroPreset.ctor(self)

    self.unitid = FourCC('H_MT')

    self.abilities = {
        bashingStrikes = {
            id = FourCC('MT_0'),
            handler = BashingStrikes,
            params = {
                attacks = function(_) return 3 end,
                attackSpeedBonus = function(_) return 0.5 end,
                healPerHit = function(_) return 0.05 end,
            },
        },
        takeCover = {
            id = FourCC('MT_1'),
            handler = TakeCover,
            availableFromStart = true,
            params = {
                baseRedirect = function(_) return 0.3 end,
                redirectPerRage = function(_) return 0.02 end,
            },
        },
        rage = {
            id = FourCC('MT_2'),
            handler = Rage,
            availableFromStart = true,
            params = {
                ragePerAttack = function(_) return 1 end,
                damagePerRage = function(_) return 1 end,
                armorPerRage = function(_) return -1 end,
                startingStacks = function(_) return 3 end,
            },
        },
        meditation = {
            id = FourCC('MT_3'),
            handler = Meditation,
            availableFromStart = true,
            params = {
                healPerRage = function(_) return 0.06 end,
            },
        },
    }

    self.talentBooks = {
        -- FourCC("MTT0"),
        -- FourCC("MTT1"),
        -- FourCC("MTT2"),
        -- FourCC("MTT3"),
    }

    -- self:AddTalent("100")
    -- self:AddTalent("101")
    -- self:AddTalent("102")

    -- self:AddTalent("110")
    -- self:AddTalent("111")
    -- self:AddTalent("112")

    -- self:AddTalent("120")
    -- self:AddTalent("121")
    -- self:AddTalent("122")

    -- self:AddTalent("130")
    -- self:AddTalent("131").onTaken = function(_, hero) hero:SetManaCost(self.abilities.darkMend.id, 1, 0) hero:SetCooldown(self.abilities.darkMend.id, 1, hero:GetCooldown(self.abilities.darkMend.id, 1) - 3) end
    -- self:AddTalent("132")

    self.basicStats.strength = 16
    self.basicStats.agility = 6
    self.basicStats.intellect = 7
    self.basicStats.constitution = 13
    self.basicStats.endurance = 8
    self.basicStats.willpower = 10
end

function BashingStrikes:Cast()
    self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed + self.attackSpeedBonus

    local function handler()
        self:SetHP(math.min(self.caster.secondaryStats.health, self:GetHP() + self.healPerHit * self.caster.secondaryStats.health))
        self.hitsLeft = self.hitsLeft - 1
        if self.hitsLeft < 0 then
            self.caster.onDamageDealt[handler] = nil
            self.caster.bonusSecondaryStats.attackSpeed = self.caster.bonusSecondaryStats.attackSpeed - self.attackSpeedBonus
        end
    end

    self.caster.onDamageDealt[handler] = true
end

return Mutant
end)
-- End of file Heroes\Mutant.lua
-- Start of file Tests\Initialization.lua
Module("Tests.Initialization", function()
local Log = require("Log")
local Init = require("Initialization")

if ExtensiveLog and TestBuild then
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
        Log("GameStart: true")
        Log("InitGlobals: " .. globalInit)
        Log("InitCustomTriggers: " .. customTriggerInit)
        Log("RunInitializationTriggers: " .. initializtion)
        Log("InitBlizzard: " .. blizz)
    end)
end

end)
-- End of file Tests\Initialization.lua
-- Start of file Tests\Main.lua
Module("Tests.Main", function()
local Log = require("Log")
local WCPlayer = require("WC3.Player")
local DuskKnight = require("Heroes.DuskKnight")
local Mutant = require("Heroes.Mutant")
local WaveObserver = require("Core.WaveObserver")
local Core = require("Core.Core")
local Tavern = require("Core.Tavern")

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

Core(WCPlayer.Get(8), 0, -1800, 0)
Tavern(WCPlayer.Get(0), 0, -2000, 0, heroPresets)

for i = 0,1 do
    heroPresets[2]:Spawn(WCPlayer.Get(i), 0, -1600, 0)
end

WaveObserver(WCPlayer.Get(9))

Log("Game initialized successfully")
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
            Log("Error running timer handler: " .. err)
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
                Log("Error filtering player units for and event: " .. errOrRet)
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
                Log("Error filtering player units for and event: " .. errOrRet)
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
                Log("Error filtering Region for and event: "..errOrRet)
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
            Log("Error running trigger action: " .. err)
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

function Unit.GetSold()
    return Get(GetBuyingUnit())
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

function Unit.EnumInRange(x, y, radius, handler)
    local group = CreateGroup()
    GroupEnumUnitsInRange(group, x, y, radius, Filter(function()
        local result, err = pcall(handler, Unit.GetFiltered())
        if not result then
            Log("Error enumerating units in range: " .. err)
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
        error("Attempt to reregister a unit")
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

return Unit
end)
-- End of file WC3\Unit.lua
function CreateUnitsForPlayer0()
    local p = Player(0)
    local u
    local unitID
    local t
    local life
    u = BlzCreateUnitWithSkin(p, FourCC("ushd"), 98.3, 49.5, 77.006, FourCC("ushd"))
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
    SetCameraBounds(-3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), -3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
    NewSoundEnvironment("Default")
    SetAmbientDaySound("LordaeronSummerDay")
    SetAmbientNightSound("LordaeronSummerNight")
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

