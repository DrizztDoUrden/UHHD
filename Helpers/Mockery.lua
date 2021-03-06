TestBuild = true
ExtensiveLog = false

---@class timer
---@class player
---@class id
---@class unit
---@class trigger
---@class playerunitevent
---@class event
---@class triggeraction
---@class group
---@class widget
---@class unitstate
---@class conditionfunc
---@class filterfunc
---@class unitevent
---@class attackType
---@class damageType
---@class weaponType
---@class ability
---@class abilityreallevelfield
---@class unitrealfield
---@class region
---@class rect
---@class location

PLAYER_GAME_RESULT_VICTORY = {}
PLAYER_GAME_RESULT_DEFEAT = {}

EVENT_UNIT_SPELL_EFFECT = {}
EVENT_UNIT_SPELL_FINISH = {}
EVENT_UNIT_DEATH = {}
EVENT_UNIT_HERO_LEVEL = {}
EVENT_UNIT_SELL = {}
EVENT_UNIT_DROP_ITEM = {}
EVENT_UNIT_PICKUP_ITEM = {}
EVENT_UNIT_SELL_ITEM = {}

EVENT_PLAYER_UNIT_SELL_ITEM = {}
EVENT_PLAYER_UNIT_DEATH = {}
EVENT_PLAYER_UNIT_DAMAGING = {}
EVENT_PLAYER_UNIT_SPELL_FINISH = {}

EVENT_GAME_ENTER_REGION = {}

UNIT_STATE_LIFE = {}
UNIT_STATE_MANA = {}
UNIT_STATE_MAX_LIFE = {}
UNIT_STATE_MAX_MANA = {}

WEAPON_TYPE_METAL_MEDIUM_SLICE = {}
WEAPON_TYPE_WHOKNOWS = {}

ATTACK_TYPE_HERO = {}
ATTACK_TYPE_NORMAL = {}

DAMAGE_TYPE_NORMAL = {}
DAMAGE_TYPE_MAGIC = {}
DAMAGE_TYPE_UNKNOWN = {}

ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND = {}
UNIT_RF_MANA_REGENERATION = {}

UNIT_RF_HIT_POINTS_REGENERATION_RATE = {}
UNIT_RF_MANA_REGENERATION = {}

function OrderId(order) end

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
---@return player
function GetLocalPlayer() end

---@param player player
---@param id id
---@param x number
---@param y number
---@param face number
---@return unit
function CreateUnit(player, id, x, y, face) end
---@param whichUnit unit
---@return string
function GetUnitName(whichUnit) end
---@param unit unit
---@return integer
function BlzGetUnitMaxHP(unit) end
---@param unit unit
---@return integer
function BlzGetUnitMaxMana(unit) end
---@param unit unit
---@param value integer
function BlzSetUnitMaxHP(unit, value) end
---@param unit unit
---@param value integer
function BlzSetUnitMaxMana(unit, value) end
---@param unit unit
---@return number
function BlzGetUnitArmor(unit) end
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
---@param whichUnit unit
---@param abilityId integer
---@return boolean
function UnitRemoveAbility(whichUnit, abilityId) end
---@param whichUnit unit
---@param abilcode integer
---@param level integer
---@return integer
function SetUnitAbilityLevel(whichUnit, abilcode, level) end
---@param whichWidget widget
---@param newLife number
function SetWidgetLife(whichWidget, newLife) end
---@param whichWidget widget
---@return number
function GetWidgetLife(whichWidget) end
---@param whichWidget widget
---@param newLife number
function SetWidgetLife(whichWidget, newLife) end
---@param whichWidget widget
---@return number
function GetWidgetLife(whichWidget) end
---@param whichUnit unit
---@param whichUnitState unitstate
---@return number
function GetUnitState(whichUnit, whichUnitState) end
---@param whichUnit unit
---@param whichUnitState unitstate
---@param newVal number
function SetUnitState(whichUnit, whichUnitState, newVal) end
---@param whichUnit unit
---@return player
function GetOwningPlayer(whichUnit) end
---@param whichUnit unit
---@param target widget
---@param amount number
---@param attack boolean
---@param ranged boolean
---@param attackType attackType
---@param damageType damageType
---@param weaponType weaponType
---@return boolean
function UnitDamageTarget(whichUnit, target, amount, attack, ranged, attackType, damageType, weaponType) end
---@param whichUnit unit
---@return number
function GetUnitFacing(whichUnit) end
---@param whichUnit unit
---@param abilId id
---@return ability
function BlzGetUnitAbility(whichUnit, abilId) end
---@param whichUnit unit
---@param whichField unitrealfield
---@param value number
---@return boolean
function BlzSetUnitRealField(whichUnit, whichField, value) end
---@param whichUnit unit
---@param newSpeed number
function SetUnitMoveSpeed(whichUnit, newSpeed) end
---@param unit unit
---@param value number
function SetUnitX(unit, value) end
---@param unit unit
---@param value number
function SetUnitY(unit, value) end
---@param unit unit
---@param value boolean
function SelectUnit(unit, value) end
---@param unit unit
---@return integer
function GetHeroLevel(unit) end
---@param whichUnit unit
function RemoveUnit(whichUnit) end
---@param unit unit
---@return id
function GetUnitTypeId(unit) end
---@param id id
---@return boolean
function IsHeroUnitId(id) end

function IssueTargetOrderById(whichUnit, order, targetWidget) end

function IssuePointOrderById(whichUnit, order, x, y) end
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

---@param whichAbility ability
---@param whichField abilityreallevelfield
---@param level integer
---@return number
function BlzGetAbilityRealLevelField(whichAbility, whichField, level) end
---@param whichAbility ability
---@param whichField abilityreallevelfield
---@param level integer
---@param value number
function BlzSetAbilityRealLevelField(whichAbility, whichField, level, value) end
---@param whichUnit unit
---@param abilId id
---@param level integer
---@param manaCost integer
function BlzSetUnitAbilityManaCost(whichUnit, abilId, level, manaCost) end
---@param whichUnit unit
---@param abilId id
---@param level integer
---@return integer
function BlzGetUnitAbilityManaCost(whichUnit, abilId, level) end
---@param whichUnit unit
---@param abilId id
---@param level integer
---@param cooldown number
function BlzSetUnitAbilityCooldown(whichUnit, abilId, level, cooldown) end
---@param whichUnit unit
---@param abilId id
---@param level integer
---@return number
function BlzGetUnitAbilityCooldown(whichUnit, abilId, level) end
---@param whichUnit unit
---@param abilCode id
---@param cooldown number
function BlzStartUnitAbilityCooldown(whichUnit, abilCode, cooldown) end

---@param from player
---@param to player
---@return boolean
function IsPlayerEnemy(from, to) end
---@param whichPlayer player
---@param techid integer
---@param setToLevel integer
function SetPlayerTechResearched(whichPlayer, techid, setToLevel) end

---@param str string
---@return id
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

function GetBuyingUnit() end

function GetSoldUnit() end

function GetDyingUnit() end
---@param whichTrigger trigger
---@param actionFunc function
---@return triggeraction
function TriggerAddAction(whichTrigger, actionFunc) end
---@param whichTrigger trigger
---@param whichUnit unit
---@param whichEvent unitevent
---@return event
function TriggerRegisterUnitEvent(whichTrigger, whichUnit, whichEvent) end

function AddUnitToAllStock(unitId, currentStock, stockMax) end

function AddUnitToStock(whichUnit, unitId, currentStock, stockMax) end

function TriggerRegisterEnterRegion(trigger, whichTrigger, whichRegion, filter) end
---@param func function
---@return filterfunc
function Filter(func) end
---@param func function
---@return conditionfunc
function Condition(func) end

---@return integer
function GetSpellAbilityId() end
---@param abilId integer
---@param level integer
---@return integer
function BlzGetAbilityManaCost(abilId, level) end

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
---@return unit
function GetEnteringUnit() end
---@return unit
function GetLevelingUnit() end
---@return unit
function GetEventDamageSource() end
---@return region
function GetTriggeringRegion() end
---@return unit
function BlzGetEventDamageTarget() end
---@return number
function GetEventDamage() end
---@param value number
function BlzSetEventDamage(value) end

---@param minx number
---@param miny number
---@param maxx number
---@param maxy number
---@return rect
function Rect(minx, miny, maxx, maxy) end
---@param rect rect
function RemoveRect(rect) end

---@return region
function CreateRegion() end
---@param region region
function RemoveRegion(region) end
---@param region region
---@param rect rect
function RegionAddRect(region, rect) end
---@param region region
---@param whichUnit unit
---@return boolean
function IsUnitInRegion(region, whichUnit) end

function SelectUnit(whichUnit, value) end
---@return number
function GetSpellTargetX() end
---@return number
function GetSpellTargetY() end
---@return number
function GetSpellTargetUnit() end
---@return location
function GetSpellTargetLoc() end
---@return damageType
function BlzGetEventDamageType() end

---@param loc location
function GetLocationX(loc) end
---@param loc location
function GetLocationY(loc) end
---@param loc location
function GetLocationZ(loc) end
---@param loc location
function RemoveLocation(loc) end


function RemovePlayer(whichPlayer, PLAYER_GAME_RESULT) end

function CreateItem(itemid, x, y) end

function RemoveItem(whichItem) end

function GetItemPlayer(whichItem) end

function GetItemX(whichItem) end

function GetItemY(whichItem) end

function GetItemY(whichItem) end

function GetItemName(whichItem) end

function GetSoldItem() end

function GetItemTypeId(whichItem) end

function SetItemPosition(whichItem, x, y) end

function BlzItemAddAbility(wwhichUnit, abilId) end

function BlzItemRemoveAbility (whichUnit, abilId) end

function UnitItemInSlot(whichUnit, slot) end

function UnitRemoveItemFromSlot(whichUnit, slot) end

function UnitAddItem(whichUnit, whichItem) end

function UnitHasItem(whichUnit, whichItem) end

function UnitAddItemById( whichUnit, itemId) end

function UnitDropItemTarget(whicUnit, whichItem, widget) end

function UnitInventorySize(whichUnit) end

function GetManipulatedItem() end

function EndGame(isShowScore) end

function ClearSelection() end
