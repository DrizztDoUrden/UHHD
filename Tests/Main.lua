local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local WaveObserver = Require("Core.WaveObserver")
local Core = Require("Core.Core")
local Tavern = Require("Core.Tavern")

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