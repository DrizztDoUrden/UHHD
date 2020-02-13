local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local WaveObserver = Require("Core.WaveObserver")
local Core = Require("Core.Core")

local testHeroPreset = DuskKnight()
local core = Core(WCPlayer.Get(8), 0, -1800, 0)
local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, -1600, 0)

local testWaveObserver = WaveObserver(WCPlayer.Get(9))
local testHero2 = testHeroPreset:Spawn(WCPlayer.Get(1), 100, -1600, 0)
Log("Game initialized successfully")