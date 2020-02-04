TestBuild = true

---@class timer
---@class player
---@class unitid
---@class unit
---@class trigger
---@class playerunitevent
---@class event
---@class triggeraction
---@class group

EVENT_PLAYER_UNIT_SPELL_FINISH = {}

---@return timer
function CreateTimer() end
---@param timer timer
function DestroyTimer(timer) end
---@param timer timer
---@param period number
---@param periodic boolean
---@param onEnd function
function TimerStart(timer, period, periodic, onEnd) end

---@param id integer
---@return player
function Player(id) end
---@param player player
---@param x number
---@param y number
---@param message string
function DisplayTextToPlayer(player, x, y, message) end
---@param player player
---@param x number
---@param y number
---@param time number
---@param message string
function DisplayTimedTextToPlayer(player, x, y, time, message) end

---@param player player
---@param unitid unitid
---@param x number
---@param y number
---@param face number
---@return unit
function CreateUnit(player, unitid, x, y, face) end
---@param whichUnit unit
---@return string
function GetUnitName(whichUnit) end
---@param unit unit
---@param value integer
function BlzSetUnitMaxHP(unit, value) end
---@param unit unit
---@param value integer
function BlzSetUnitMaxMana(unit, value) end
---@param unit unit
---@param value number
function BlzSetUnitArmor(unit, value) end
---@param unit unit
---@param value integer
---@param weaponId integer
function BlzSetUnitBaseDamage(unit, value, weaponId) end
---@param whichUnit unit
---@param cooldown number
---@param weaponIndex integer
function BlzSetUnitAttackCooldown(whichUnit, cooldown, weaponIndex) end
---@param whichUnit unit
---@return number
function GetUnitX(whichUnit) end
---@param whichUnit unit
---@return number
function GetUnitY(whichUnit) end
---@param whichUnit unit
---@param otherUnit unit
---@param distance number
---@return boolean
function IsUnitInRange(whichUnit, otherUnit, distance) end
---@param whichUnit unit
---@param abilityId integer
---@return boolean
function UnitAddAbility(whichUnit, abilityId) end

---@param whichHero unit
---@param value integer
---@param permanent boolean
function SetHeroStr(whichHero, value, permanent) end
---@param whichHero unit
---@param value integer
---@param permanent boolean
function SetHeroAgi(whichHero, value, permanent) end
---@param whichHero unit
---@param value integer
---@param permanent boolean
function SetHeroInt(whichHero, value, permanent) end
---@param whichHero unit
---@param includeBonuses boolean
---@return integer
function GetHeroStr(whichHero, includeBonuses) end
---@param whichHero unit
---@param includeBonuses boolean
---@return integer
function GetHeroAgi(whichHero, includeBonuses) end
---@param whichHero unit
---@param includeBonuses boolean
---@return integer
function GetHeroInt(whichHero, includeBonuses) end

---@param str string
---@return unitid
function FourCC(str) end

---@param filename string
function Preload(filename) end
---@param timeout number
function PreloadEnd(timeout) end
function PreloadStart() end
function PreloadRefresh() end
function PreloadEndEx() end
function PreloadGenClear() end
function PreloadGenStart() end
---@param filename string
function PreloadGenEnd(filename) end
---@param filename string
function Preloader(filename) end

---@return trigger
function CreateTrigger() end
---@param trigger trigger
function DestroyTrigger(trigger) end
---@param trigger trigger
---@paran player player
---@param event playerunitevent
---@param filter function
---@return event
function TriggerRegisterPlayerUnitEvent(trigger, player, event, filter) end
---@param whichTrigger trigger
---@param actionFunc function
---@return triggeraction
function TriggerAddAction(whichTrigger, actionFunc) end

---@return integer
function GetSpellAbilityId() end

---@return group
function CreateGroup() end
---@param group group
function DestroyGroup(group) end
---@param whichGroup group
---@param x number
---@param y number
---@param radius number
---@param filter function
function GroupEnumUnitsInRange(whichGroup, x, y, radius, filter) end

---@return unit
function GetFilterUnit() end
