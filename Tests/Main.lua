local Log = require("Log")
local WCPlayer = require("WC3.Player")
local DuskKnight = require("Heroes.DuskKnight")
local WaveObserver = require("Core.WaveObserver")
local Core = require("Core.Core")
local Tavern = require("Core.Tavern")

local heroPresets = {
    DuskKnight()
}

local testHeroPreset = DuskKnight()

Core(WCPlayer.Get(8), 0, -1800, 0)
Tavern(WCPlayer.Get(8), 0, -2000, 0, heroPresets)

for i = 0,1 do
    testHeroPreset:Spawn(WCPlayer.Get(i), 0, -1600, 0)
end

WaveObserver(WCPlayer.Get(9))

Log("Game initialized successfully")