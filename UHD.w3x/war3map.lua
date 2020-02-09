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
    AbilityInstance = Class()

    function AbilityInstance:ctor(handle)
        self.handle = handle
    end

    function AbilityInstance:SetHpRegen(level, value)
        return BlzSetAbilityRealLevelField(self.handle, ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND, level, value)
    end

    function AbilityInstance:SetMpRegen(level, value)
        return BlzSetAbilityRealLevelField(self.handle, ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND, level, value)
    end
end

do
    WCPlayer = Class()
    local players = {}

    function WCPlayer.Get(player)
        if math.type(player) == "integer" then
            player = Player(player)
        end
        if not players[player] then
            players[player] = WCPlayer(player)
        end
        return players[player]
    end

    function WCPlayer:ctor(player)
        self.handle = player
    end

    function WCPlayer:IsEnemy(other)
        if not other:IsA(WCPlayer) then
            error("Expected player as an argument")
        end
        return IsPlayerEnemy(self.handle, other.handle)
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
        TimerStart(self.handle, period, periodic, function()
            local result, err = pcall(onEnd)
            if not result then
                Log("Error running timer handler: " .. err)
            end
        end)
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

    function Trigger:RegisterUnitEvent(unit, event)
        return TriggerRegisterUnitEvent(self.handle, unit.handle, event)
    end

    function Trigger:TriggerRegisterEnterRegion(region, event, action, filter)
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
        return TriggerRegisterEnterRegion(self.handle, region.handle, event, filter(filter))
    end

    function Trigger:AddAction(action)
        return TriggerAddAction(self.handle, function()
            local result, err = pcall(action)
            if not result then
                Log("Error running trigger action: " .. err)
            end
        end)
    end
end
do
    Unit = Class()

    local units = {}

    function Unit.Get(handle)
        local existing = units[handle]
        if existing then
            return existing
        end
        existing = Unit(handle)
        return existing
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



    function Unit.EnumInRange(x, y, radius, handler)
        local group = CreateGroup()
        GroupEnumUnitsInRange(group, x, y, radius, Filter(function()
            local result, err = pcall(handler, Unit.Get(GetFilterUnit()))
            if not result then
                Log("Error enumerating units in range: " .. err)
            end
        end))
        DestroyGroup(group)
    end

    function Unit:ctor(...)
        local params = { ... }
        if #params == 1 then
            self.handle = params[0]
        else
            local player, unitid, x, y, facing = ...
            self.handle = CreateUnit(player.handle, unitid, x, y, facing)
        end
        self:Register()
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
            Log("Unit max health should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetMaxMana(value)
        if math.type(value) then
            BlzSetUnitMaxMana(self.handle, math.floor(value))
        else
            Log("Unit max mana should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetArmor(value)
        if math.type(value) then
            BlzSetUnitArmor(self.handle, value)
        else
            Log("Unit armor should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetBaseDamage(value, weaponId)
        weaponId = weaponId or 0
        if math.type(weaponId) ~= "integer" then
            Log("Unit weapon id should be an integer (" .. type(weaponId) .. ")")
            return
        end
        if type(value) == "integer" then
            BlzSetUnitBaseDamage(self.handle, value, weaponId)
        elseif type(value) == "number" then
            BlzSetUnitBaseDamage(self.handle, math.floor(value), math.tointeger(weaponId))
        else
            Log("Unit base damage should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetAttackCooldown(value, weaponId)
        weaponId = weaponId or 0
        if math.type(weaponId) ~= "integer" then
            Log("Unit weapon id should be an integer (" .. type(weaponId) .. ")")
            return
        end
        if type(value) == "integer" or type(value) == "number" then
            BlzSetUnitAttackCooldown(self.handle, value, math.tointeger(weaponId))
        else
            Log("Unit attack cooldown should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetStr(value, permanent)
        if math.type(value) then
            SetHeroStr(self.handle, math.floor(value), permanent)
        else
            Log("Unit strength should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetAgi(value, permanent)
        if math.type(value) then
            SetHeroAgi(self.handle, math.floor(value), permanent)
        else
            Log("Unit agility should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:SetInt(value, permanent)
        if math.type(value) then
            SetHeroInt(self.handle, math.floor(value), permanent)
        else
            Log("Unit intellect should be a number (" .. type(value) .. ")")
        end
    end

    function Unit:AddAbility(id)
        if math.type(id) then
            return UnitAddAbility(self.handle, math.tointeger(id))
        else
            Log("Abilityid should be an integer (" .. type(id) .. ")")
            return false
        end
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

    

    function Unit:GetName() return GetUnitName(self.handle) end
    function Unit:IsInRange(other, range) return IsUnitInRange(self.handle, other.handle, range) end
    function Unit:GetX() return GetUnitX(self.handle) end
    function Unit:GetY() return GetUnitY(self.handle) end
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
end
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
        function Require(id)
            return table.unpack(coroutine.yield(resume, id))
        end

        while #modules > 0 do
            local anyFound = false
            for moduleId, module in pairs(modules) do
                if not module.hasErrors and not module.requirement or module.resolvedRequirement then
                    local ret
                    local coocked = false

                    repeat
                        ret = table.pack(coroutine.resume(module.definition, module.resolvedRequirement))
                        local correct = table.remove(ret, 1)

                        if not correct then
                            module.hasErrors = true
                            Log(module.id .. " has errors:", table.unpack(ret))
                        end

                        module.resolvedRequirement = nil
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
                        if ExtensiveLog or true then
                            Log("Successfully loaded " .. module.id)
                        end
                        anyFound = true
                        readyModules[module.id] = ret
                        table.remove(modules, moduleId)
                        for _, other in pairs(modules) do
                            if other.requirement == module.id and not other.resolvedRequirement then
                                other.resolvedRequirement = ret
                                break
                            end
                        end
                        break
                    end
                end
            end
            if not anyFound then
                Log("Some modules not resolved:")
                for _, module in pairs(modules) do
                    Log(module.id .. " has unresolved requirement: " .. module.requirement)
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
            definition = coroutine.create(definition),
        })
    end
end

Module("Creeps.MagicDragon", function()
    local CreepPreset = Require("CreepPreset")

    local MagicDragon = Class(CreepPreset)

    function MagicDragon:ctor()
        Log("Construct Magic Dragon")
        CreepPreset.ctor(self)
        self.secondaryStats.health = 50
        self.secondaryStats.mana = 15

        self.unitid = FourCC('C_MD')
        
    end
    Log("MagicDragon load successfull")
    return MagicDragon
end)
Module("WaveSpecification", function ()
    
    local levelCreepCompositon = {{"MagicDragon"}}
    local nComposition = {
        {1}
    }
    local aComposition = {
        {nil}
    }
    Log("WaveSpecification is load")

    return levelCreepCompositon, nComposition, aComposition, 1
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

Module("CreepsSpawner", function()

    local levelCreepsComopsion, nComposion, aComposition, maxlevel = Require("WaveSpecification")
    local CreepClasses = {MagicDragon = Require("Creeps.MagicDragon")}

    local CreepSpawner = Class()


    function  CreepSpawner:ctor()
        Log("Construct CreepSpawner")
        self.level = 0
        self.x = 0
        self.y = 0
        self.levelCreepsComopsion = levelCreepsComopsion
        Log("in zero wave first creater is ",self.levelCreepsComopsion[1][1])
        self.nComposion = nComposion
        self.maxlevel = maxlevel
        self.aComposition = aComposition
    end

    function CreepSpawner:GetNextWaveSpecification()        
        local nextlevel = self.level + 1

        Log("   get next wave specification"..nextlevel)
        local result_CreepsComposition = self.levelCreepsComopsion[nextlevel]
        Log("   first wave Creep is "..result_CreepsComposition[1])
        local result_nComposion = self.nComposion[nextlevel]
        Log("   count first wave Creep is "..result_nComposion[1])
        local result_aComposion = self.aComposition[nextlevel]
 
        self.level = nextlevel
        return result_CreepsComposition, result_nComposion, result_aComposion
    end

    function CreepSpawner:isNextLevel()
        if self.level > self.maxlevel then
            return true
        end
        return false
    end


    function CreepSpawner:SpawnNewWave(owner, facing)
        Log("Spawn new wave")
        Log("   posx"..self.x)
        Log("   poxy"..self.y)
        Log("   facing"..facing)
        local CreepsComposition, nComposion, aComposition = self:GetNextWaveSpecification()
        for i, CreepName in pairs(CreepsComposition) do
            Log(CreepName)
            for j =1, nComposion[i], 1
             do
                Log("Read Class Preset")
                local CreepPresetClass = CreepClasses[CreepName]
                Log("initialize CreepPreset")
                local creepPreset = CreepPresetClass()
                Log("Spawn new unit")
                local Creep = creepPreset:Spawn(owner, self.x, self.y, facing)
                local res = Creep:IssueAttackPoint(0, 700)
                if res then
                    Log(" Is attack true")
                else
                    if res == nil then
                        Log(" order was not sended")
                    else
                        Log(" Is attack false")
                    end
                end
            end
        end
        Log("Wave was Spawn")
    end

    Log("CreepsSpawner load succsesfull")
    return CreepSpawner

end)
Module("CreepPreset", function()

    local Stats = Require("Stats")
    local UHDUnit = Require("UHDUnit")

    local Creep = Class(UHDUnit)
    local CreepPreset = Class()

    function CreepPreset:ctor()
        self.secondaryStats = Stats.Secondary()

        self.secondaryStats.health = 50
        self.secondaryStats.mana = 2
        self.secondaryStats.healthRegen = 1
        self.secondaryStats.manaRegen = 1

        self.secondaryStats.weaponDamage = 15
        self.secondaryStats.attackSpeed = 2
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
        Log(" CreepPreset:Spawn")
        Log(" id=", self.unitid)
        local Creep = Creep(owner, self.unitid, x, y, facing);
        Creep.secondaryStats = self.secondaryStats
        Creep:ApplyStats()
        return Creep
    end

    Log("Creep load succsesfull")
    return CreepPreset
end)
Module("UHDUnit", function()
    local Stats = Require("Stats")

    local UHDUnit = Class(Unit)

    local hpRegenAbility = FourCC('_HPR')
    local mpRegenAbility = FourCC('_MPR')

    function UHDUnit:ctor(...)
        Unit.ctor(self, ...)
        self.secondaryStats = Stats.Secondary()

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

    return UHDUnit
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
        local gtoBase = 1.02
        local ltoBase = 0.98

        self.secondaryStats.physicalDamage = BonusMul(self.baseSecondaryStats.physicalDamage, gtoBase, self.basicStats.strength, self.bonusSecondaryStats.physicalDamage)
        self.secondaryStats.weaponDamage = (self.baseSecondaryStats.weaponDamage + self.bonusSecondaryStats.weaponDamage) * self.secondaryStats.physicalDamage

        self.secondaryStats.evasion = ProbabilityBased(self.baseSecondaryStats.evasion, ltoBase, self.basicStats.agility, self.bonusSecondaryStats.evasion)
        self.secondaryStats.attackSpeed = BonusMul(self.baseSecondaryStats.attackSpeed, gtoBase, self.basicStats.agility, self.bonusSecondaryStats.attackSpeed)

        self.secondaryStats.spellDamage = BonusMul(self.baseSecondaryStats.spellDamage, gtoBase, self.basicStats.intellect, self.bonusSecondaryStats.spellDamage)

        self.secondaryStats.health = BonusBeforePow(self.baseSecondaryStats.health, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.health)
        self.secondaryStats.healthRegen = BonusBeforePow(self.baseSecondaryStats.healthRegen, gtoBase, self.basicStats.constitution, self.bonusSecondaryStats.healthRegen)

        self.secondaryStats.mana = BonusBeforePow(self.baseSecondaryStats.mana, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.health)
        self.secondaryStats.manaRegen = BonusBeforePow(self.baseSecondaryStats.manaRegen, gtoBase, self.basicStats.endurance, self.bonusSecondaryStats.manaRegen)

        self.secondaryStats.ccResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
        self.secondaryStats.spellResist = ProbabilityBased(self.baseSecondaryStats.ccResist, ltoBase, self.basicStats.willpower, self.bonusSecondaryStats.ccResist)
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

    local DrainLight = Class()
    local HeavySlash = Class()
    local ShadowLeap = Class()
    local DarkMend = Class()

    function DuskKnight:ctor()
        HeroPreset.ctor(self)

        self.unitid = FourCC('H_DK')

        self.abilities = {
            drainLight = {
                id = FourCC('DK_0'),
                handler = DrainLight,
                availableFromStart = true,
                radius = function(_) return 300 end,
                duration = function(_) return 2 end,
                period = function(_) return 0.1 end,
                effectDuration = function(_) return 10 end,
                armorRemoved = function(_) return 10 end,
                stealPercentage = function(_) return 0.25 end,
            },
            heavySlash = {
                id = FourCC('DK_1'),
                handler = HeavySlash,
                availableFromStart = true,
                radius = function(_) return 75 end,
                distance = function(_) return 75 end,
                baseDamage = function(_) return 30 end,
            },
            shadowLeap = {
                id = FourCC('DK_2'),
                handler = ShadowLeap,
                availableFromStart = true,
                -- radius = function(_) return 75 end,
                -- distance = function(_) return 75 end,
                -- baseDamage = function(_) return 30 end,
            },
            darkMend = {
                id = FourCC('DK_3'),
                handler = DarkMend,
                availableFromStart = true,
                baseHeal = function(_) return 20 end,
                duration = function(_) return 4 end,
                percentHeal = function(_) return 0.1 end,
                period = function(_) return 0.1 end,
            },
        }

        self.basicStats.strength = 12
        self.basicStats.agility = 6
        self.basicStats.intellect = 12
        self.basicStats.constitution = 11
        self.basicStats.endurance = 8
        self.basicStats.willpower = 11
    end

    function DrainLight:ctor(definition, caster)
        self.caster = caster
        self.affected = {}
        self.bonus = 0
        self.bonusLimit = 30
        self.duration = definition:effectDuration(caster)
        self.toSteal = definition:armorRemoved(caster)
        self.radius = definition:radius(caster)
        self.stealTimeLeft = definition:duration(caster)
        self.period = definition:period(caster)
        self.toBonus = definition:stealPercentage(caster)

        self:Cast()
    end

    function DrainLight:Cast()
        local timer = Timer()

        Unit.EnumInRange(self.caster:GetX(), self.caster:GetY(), self.radius, function(unit)
            if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                table.insert(self.affected, {
                    unit = unit,
                    stolen = 0,
                    toSteal = self.toSteal,
                    toReturn = self.toSteal,
                    toBonus = 0.25,
                })
            end
        end)

        timer:Start(self.period, true, function()
            if self.caster:GetHP() <= 0 then
                timer:Destroy()
                self:End()
                return
            end

            self.stealTimeLeft = self.stealTimeLeft - self.period

            for _, target in pairs(self.affected) do
                self:Drain(target)
            end

            if self.stealTimeLeft <= 0 then
                timer:Destroy()
                self:Effect()
            end
        end)
    end

    function DrainLight:Effect()
        local timer = Timer()
        local trigger = Trigger()

        trigger:RegisterUnitEvent(self.caster, EVENT_UNIT_DEATH)

        trigger:AddAction(function()
            timer:Destroy()
            trigger:Destroy()
            self:End()
        end)

        timer:Start(self.duration, false, function()
            timer:Destroy()
            trigger:Destroy()
            self:End()
        end)
    end

    function DrainLight:End()
        for _, target in pairs(self.affected) do
            target.unit:SetArmor(target.unit:GetArmor() + target.toReturn)
        end
        self.caster:SetArmor(self.caster:GetArmor() - self.bonus)
    end

    function DrainLight:Drain(target)
        local toStealNow = (target.toSteal - target.stolen) * self.period / self.stealTimeLeft
        target.unit:SetArmor(target.unit:GetArmor() + target.stolen)
        target.stolen = target.stolen + toStealNow
        target.unit:SetArmor(target.unit:GetArmor() - target.stolen)
        if self.bonus < self.bonusLimit then
            local toBonus = math.min(self.bonusLimit - self.bonus, toStealNow * target.toBonus)
            self.caster:SetArmor(self.caster:GetArmor() - self.bonus)
            self.bonus = self.bonus + toBonus
            self.caster:SetArmor(self.caster:GetArmor() + self.bonus)
        end
    end

    function HeavySlash:ctor(definition, caster)
        self.caster = caster
        self.radius = definition:radius(caster)
        self.distance = definition:distance(caster)
        self.baseDamage = definition:baseDamage(caster)
        self:Cast()
    end

    function HeavySlash:Cast()
        local facing = self.caster:GetFacing() * math.pi / 180
        local x = self.caster:GetX() + math.cos(facing) * self.distance
        local y = self.caster:GetY() + math.sin(facing) * self.distance

        Unit.EnumInRange(x, y, self.radius, function(unit)
            if self.caster:GetOwner():IsEnemy(unit:GetOwner()) then
                self.caster:DamageTarget(unit, self.baseDamage, true, false, ATTACK_TYPE_HERO, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_METAL_MEDIUM_SLICE)
            end
        end)
    end

    function ShadowLeap:ctor(definition, caster)
    end

    function DarkMend:ctor(definition, caster)
        self.caster = caster
        self.baseHeal = definition:baseHeal(caster)
        self.duration = definition:duration(caster)
        self.percentHeal = definition:percentHeal(caster)
        self.period = definition:period(caster)
        self.spellDamage = caster.secondaryStats.spellDamage
        self:Cast()
    end

    function DarkMend:Cast()
        local timer = Timer()
        local timeLeft = self.duration
        timer:Start(self.period, true, function()
            timeLeft = timeLeft - self.period
            local part = self.period / self.duration
            self.caster:SetHP(self.caster:GetHP() + (self.caster:GetHP() * self.percentHeal + self.baseHeal) * self.spellDamage * part)
            if timeLeft <= 0 then
                timer:Destroy()
            end
        end)
    end

    return DuskKnight
end)

if ExtensiveLog and TestBuild then
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
            Log("GameStart: true")
            Log("InitGlobals: " .. globalInit)
            Log("InitCustomTriggers: " .. customTriggerInit)
            Log("RunInitializationTriggers: " .. initializtion)
            Log("InitBlizzard: " .. blizz)
        end)
    end)
end

Module("Tests.Main", function()
    local DuskKnight = Require("Heroes.DuskKnight")

    local UHDUnit = Require("UHDUnit")
    local CreepsSpawner = Require("CreepsSpawner")
    testCreepsSpawner = CreepsSpawner()
    testCreepsSpawner:SpawnNewWave(WCPlayer.Get(1), 0)
    local testHeroPreset = DuskKnight()
    local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 700, 0)

    Log("Game initialized successfully")
end)
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
    CreateAllUnits()
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

