local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local WaveObserver = Require("Core.WaveObserver")

local testHeroPreset = DuskKnight()
local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 0, 0)

local testWaveObserver = WaveObserver(WCPlayer.Get(12))

Log("Game initialized successfully")