local Log = require("Log")
local WCPlayer = require("WC3.Player")
local DuskKnight = require("Heroes.DuskKnight")
local Mutant = require("Heroes.Mutant")
local Unit = require("WC3.Unit")
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
for i = 0, 7, 1 do
    local shiftx = 1300 + i * 100
    local unit = Unit(WCPlayer.Get(i), FourCC("e001"), shiftx, -3600, 0)
    unit:SetMoveSpeed(0)
end
Core(WCPlayer.Get(8), -2300, -3800, 0)
Tavern(WCPlayer.Get(0), 1600, -3800, 0, heroPresets)


WaveObserver(WCPlayer.Get(9))

Log("Game initialized successfully")