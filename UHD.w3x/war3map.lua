function InitGlobals()
end

do

TestBuild = true
ExtensiveLog = false

end

do
    function Log(...)
        local text = table.concat({...}, "\n")
        if TestBuild then
            print(text)
        end
        Preload("\")\n" .. text .. "\n\\")
        PreloadGenEnd("log.txt")
    end
end

do
    function Class(base, ctor)
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
end

do
    Timer = Class()
    
    function Timer:ctor(handle)
        self.handle = CreateTimer()
    end

    function Timer:Destroy()
        DestroyTimer(self.handle)
    end

    function Timer:Start(period, periodic, onEnd)
        TimerStart(self.handle, period, periodic, onEnd)
    end
end

do
    Trigger = Class()

    function Trigger:ctor()
        self.handle = CreateTrigger()
    end

    function Trigger:Destroy()
        DestroyTrigger(self.handle)
    end

    function Trigger:RegisterPlayerUnitEvent(player, event, filter)
        return TriggerRegisterPlayerUnitEvent(self.handle, player, event, filter)
    end

    function Trigger:AddAction(action)
        return TriggerAddAction(self.handle, action)
    end
end

Module("Hero", function()
    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Hero = Class(UHDUnit)

    function Hero:ctor(...)
        UHDUnit.ctor(self, ...)
        self.basicStats = Stats.Basic()
        self.baseSecondaryStats = Stats.Secondary()
        self.bonusSecondaryStats = Stats.Secondary()
    end

    local function BonusBeforePow(base, pow, stat, bonus)
        return (base + bonus) * pow^stat
    end

    local function BonusMul(base, pow, stat, bonus)
        return base * pow^stat * (1 + bonus)
    end

    local function ProbabilityBased(base, pow, stat, bonus)
        return base + bonus + (1 - base - bonus) * (1 - pow^stat)
    end

    function Hero:UpdateSecondaryStats()
        self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, 1.05, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
        self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

        self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, 0.95, self.basicStats.agility, self.bonusSecondaryStats.evasion)
        self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, 1.05, self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

        self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, 1.05, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

        self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, 1.05, self.basicStats.constitution, self.bonusSecondaryStats.health)
        self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, 1.05, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

        self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, 1.05, self.basicStats.endurance, self.bonusSecondaryStats.health)
        self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, 1.05, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

        self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, 0.99, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
        self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, 0.99, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
    end

    function Hero:SetBasicStats(value)
        self.basicStats = value
        self:UpdateSecondaryStats()
        self:ApplyStats()
    end

    function Hero:ApplyStats()
        self:SetStr(self.basicStats.strength, true)
        self:SetAgi(self.basicStats.agility, true)
        self:SetInt(self.basicStats.intellect, true)
        UHDUnit.ApplyStats(self)
    end

    return Hero
end)

do
    local result, err = pcall(function()
        local handlers = {
            initGlobals = {},
            initBlizzard = {},
            initCustomTriggers = {},
            initialization = {},
            gameStart = {},
        }

        local function FunctionRegistar(table)
            return setmetatable({}, {
                __index = {
                    Add = function(_, func)
                        table[func] = true
                    end
                },
            })
        end

        GlobalInit = FunctionRegistar(handlers.initGlobals)
        CustomTriggerInit = FunctionRegistar(handlers.initCustomTriggers)
        Initializtion = FunctionRegistar(handlers.initialization)
        BlizzardInit = FunctionRegistar(handlers.initBlizzard)
        GameStart = FunctionRegistar(handlers.gameStart)

        local function RunHandlers(table)
            for handler in pairs(handlers[table]) do
                local result, err = pcall(function()
                    handler()
                end)
                if not result then Log(err) end
            end
            handlers[table] = nil
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
    end)

    if not result then
        print(err)
    end
end

do
    local modules = {}
    local readyModules = {}

    BlizzardInit:Add(function()
        local resume = {}

        local oldRequire = Require
        function Require(...)
            return table.unpack(coroutine.yield(resume, ...))
        end

        while #modules > 0 do
            local anyFound = false
            for moduleId, module in pairs(modules) do
                if not module.hasErrors and #module.requirements == module.resolvedRequirements.n then
                    local ret
                    local coocked = false

                    repeat
                        ret = table.pack(coroutine.resume(module.definition, module.resolvedRequirements))
                        local correct = table.remove(ret, 1)

                        if not correct then
                            module.hasErrors = true
                            Log(module.id .. " has errors:", table.unpack(ret))
                        end

                        module.resolvedRequirements = { n = 0, }
                        if #ret == 0 or ret[1] ~= resume then
                            coocked = true
                            break
                        end

                        table.remove(ret, 1)
                        module.requirements = ret
                        for reqId, id in pairs(module.requirements) do
                            local ready = readyModules[id]
                            if ready then
                                module.resolvedRequirements[reqId] = ready
                                module.resolvedRequirements.n = module.resolvedRequirements.n + 1
                            end
                        end
                    until module.resolvedRequirements.n ~= #module.requirements
                    
                    if coocked then
                        if ExtensiveLog then
                            Log("Successfully loaded " .. module.id)
                        end
                        if #ret == 1 then ret = ret[1] end
                        anyFound = true
                        readyModules[module.id] = ret
                        table.remove(modules, moduleId)
                        for _, other in pairs(modules) do
                            for reqId, id in ipairs(other.requirements) do
                                if id == module.id and not other.resolvedRequirements[reqId] then
                                    other.resolvedRequirements[reqId] = ret
                                    other.resolvedRequirements.n = other.resolvedRequirements.n + 1
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
            if not anyFound then
                Log("Some modules not resolved:")
                for _, module in pairs(modules) do
                    Log(module.id)
                    for _, id in pairs(module.requirements) do
                        Log(">   has unresolved " .. id)
                    end
                end
                break
            end
        end
        modules = nil
        readyModules = nil
        Require = oldRequire
        Module = function (id, definition)
            Log("Module loading has already finished. Can't load " .. id)
        end
    end)

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
            requirements = {},
            definition = coroutine.create(definition),
            resolvedRequirements = { n = 0, },
        })
    end
end

Module("UHDUnit", function()
    local Stats = Require("Stats")

    local UHDUnit = Class(Unit)

    function UHDUnit:ctor(...)
        Unit.ctor(self, ...)
        self.secondaryStats = Stats.Secondary()
    end

    function UHDUnit:ApplyStats()
        self:SetMaxHealth(self.secondaryStats.health)
        self:SetMaxMana(self.secondaryStats.mana)
        self:SetBaseDamage(self.secondaryStats.weaponDamage)
        self:SetAttackCooldown(1 / self.secondaryStats.attackSpeed)
        self:SetArmor(0)
    end

    return UHDUnit
end)

Module("Stats", function()
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
            "constintution",
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

Module("Hero", function()
    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Hero = Class(UHDUnit)

    function Hero:ctor(...)
        UHDUnit.ctor(self, ...)
        self.basicStats = Stats.Basic()
        self.baseSecondaryStats = Stats.Secondary()
        self.bonusSecondaryStats = Stats.Secondary()
    end

    local function BonusBeforePow(base, pow, stat, bonus)
        return (base + bonus) * pow^stat
    end

    local function BonusMul(base, pow, stat, bonus)
        return base * pow^stat * (1 + bonus)
    end

    local function ProbabilityBased(base, pow, stat, bonus)
        return base + bonus + (1 - base - bonus) * (1 - pow^stat)
    end

    function Hero:UpdateSecondaryStats()
        self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, 1.05, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
        self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

        self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, 0.95, self.basicStats.agility, self.bonusSecondaryStats.evasion)
        self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, 1.05, self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

        self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, 1.05, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

        self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, 1.05, self.basicStats.constitution, self.bonusSecondaryStats.health)
        self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, 1.05, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

        self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, 1.05, self.basicStats.endurance, self.bonusSecondaryStats.health)
        self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, 1.05, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

        self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, 0.99, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
        self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, 0.99, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
    end

    function Hero:SetBasicStats(value)
        self.basicStats = value
        self:UpdateSecondaryStats()
        self:ApplyStats()
    end

    function Hero:ApplyStats()
        self:SetStr(self.basicStats.strength, true)
        self:SetAgi(self.basicStats.agility, true)
        self:SetInt(self.basicStats.intellect, true)
        UHDUnit.ApplyStats(self)
    end

    return Hero
end)

Module("HeroPreset", function()
    local Stats = Require("Stats")
    local Hero = Require("Hero")

    local HeroPreset = Class()

    function HeroPreset:ctor()
        self.basicStats = Stats.Basic()
        self.secondaryStats = Stats.Secondary()
        self.unitid = FourCC('0000')

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
    end

    function HeroPreset:Spawn(owner, x, y, facing)
        local hero = Hero(owner, self.unitid, x, y, facing);

        hero.baseSecondaryStats = self.secondaryStats
        hero:SetBasicStats(self.basicStats)

        hero.abilities = Trigger()
        hero.abilities:RegisterPlayerUnitEvent(owner, EVENT_PLAYER_UNIT_SPELL_FINISH)
        hero.abilities:AddAction(function() self:Cast(hero) end)

        for _, ability in pairs(self.abilities) do
            if ability.availableFromStart then
                hero:AddAbility(ability.id)
                hero:SetAbilityLevel(ability.id, 1)
            end
        end

        return hero
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

Module("Heroes.DuskKnight", function()
    local HeroPreset = Require("HeroPreset")

    local DuskKnight = Class(HeroPreset)

    function DuskKnight:ctor()
        HeroPreset.ctor(self)

        self.unitid = FourCC('H_DK')

        self.abilities = {
            drainLight = {
                id = FourCC('Z_DK'),
                handler = function(hero) self:CastDrainLight(hero) end,
                availableFromStart = true,
                duration = function() return 3 end,
                period = function() return 0.1 end,
            }
        }

        self.basicStats.strength = 12
        self.basicStats.agility = 6
        self.basicStats.intellect = 12
        self.basicStats.constitution = 11
        self.basicStats.endurance = 8
        self.basicStats.willpower = 11
    end

    function DuskKnight:CastDrainLight(hero)
        local timer = Timer()
        local affected = {}

        local group = CreateGroup()
        GroupEnumUnitsInRange(group, hero.unit.GetX(), hero.unit.GetY(), hero.unit.GetY(), function()
            local unit = Unit.Get(GetFilterUnit())
            if unit == hero.unit then return end
            table.insert(affected, unit)
        end)
        DestroyGroup(group)

        local timeLeft = self.abilities.drainLight:duration()
        local period = self.abilities.drainLight:period();
        timer.Start(period, true, function()
            timeLeft = timeLeft - period
            if timeLeft <= 0 then
                timer:Destroy()
            end

            local i = 1
            while i <= #affected do
                if affected[i].IsInRange(hero.unit) then
                    self:ApplyDrainLight(hero, affected[i], period)
                    i = i + 1
                else
                    table.remove(affected, i)
                end
            end
        end)
    end

    function DuskKnight:ApplyDrainLight(hero, target, period)
        Log("Draining light from " .. hero.unit.GetName() .. " to " .. target:GetName() .. " for " .. period)
        -- apply effect
    end

    return DuskKnight
end)

if TestBuild and ExtensiveLog then
    Module("Tests.Initialization", function()
        local globalInit = "false";
        local customTriggerInit = "false";
        local initializtion = "false";
        local blizz = "false";

        GlobalInit:Add(function ()
            globalInit = "true"
        end)
        CustomTriggerInit:Add(function ()
            customTriggerInit = "true"
        end)
        Initializtion:Add(function ()
            initializtion = "true"
        end)
        BlizzardInit:Add(function ()
            blizz = "true"
        end)
        GameStart:Add(function()
            for pid = 0, 23 do
                DisplayTextToPlayer(Player(pid), 0, 0, "GameStart: true")
                DisplayTextToPlayer(Player(pid), 0, 0, "InitGlobals: " .. globalInit)
                DisplayTextToPlayer(Player(pid), 0, 0, "InitCustomTriggers: " .. customTriggerInit)
                DisplayTextToPlayer(Player(pid), 0, 0, "RunInitializationTriggers: " .. initializtion)
                DisplayTextToPlayer(Player(pid), 0, 0, "InitBlizzard: " .. blizz)
            end
        end)
    end)
end

Module("Tests.Main", function()
    local DuskKnight = Require("Heroes.DuskKnight")

    local testHeroPreset = DuskKnight()
    local testHero = testHeroPreset:Spawn(Player(0), 0, 0, 0)
    Log("Game initialized successfully")
end)

function InitCustomPlayerSlots()
    SetPlayerStartLocation(Player(0), 0)
    SetPlayerColor(Player(0), ConvertPlayerColor(0))
    SetPlayerRacePreference(Player(0), RACE_PREF_HUMAN)
    SetPlayerRaceSelectable(Player(0), true)
    SetPlayerController(Player(0), MAP_CONTROL_USER)
end

function InitCustomTeams()
    SetPlayerTeam(Player(0), 0)
end

function main()
    SetCameraBounds(-3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), -3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
    NewSoundEnvironment("Default")
    SetAmbientDaySound("LordaeronSummerDay")
    SetAmbientNightSound("LordaeronSummerNight")
    SetMapMusic("Music", true, 0)
    InitBlizzard()
    InitGlobals()
end

function config()
    SetMapName("TRIGSTR_001")
    SetMapDescription("TRIGSTR_003")
    SetPlayers(1)
    SetTeams(1)
    SetGamePlacement(MAP_PLACEMENT_USE_MAP_SETTINGS)
    DefineStartLocation(0, -512.0, -1664.0)
    InitCustomPlayerSlots()
    SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
    InitGenericPlayerSlots()
end

