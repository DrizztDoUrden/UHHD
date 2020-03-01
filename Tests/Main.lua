local Log = require("Log")
local WC3 = require("WC3.All")
local DuskKnight = require("Heroes.DuskKnight")
local Mutant = require("Heroes.Mutant")
local WaveObserver = require("Core.WaveObserver")
local Core = require("Core.Core")
local Tavern = require("Core.Tavern")
local Timer = require("WC3.Timer")
local DefiledTree = require("Bosses.DefiledTree")
local ChainArmor = require("Items.Armor.ChainArmor")
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
ChainArmor(-2300, -3400)
-- local Bos = DefiledTree():Spawn(WC3.Player.Get(0), -2300, -3500, 0, 1, 2)
-- local timerwaveObserver = Timer()
-- timerwaveObserver:Start(15, false,
--     function() WaveObserver(WC3.Player.Get(9))
-- end)


logMain:Message("Game initialized successfully")