local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local WaveObserver = Require("Core.WaveObserver")
local Core = Require("Core.Core")

local testHeroPreset = DuskKnight()
local core = Core(WCPlayer.Get(8), 0, 0, 0)
local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 200, 0, 0)

local testWaveObserver = WaveObserver(WCPlayer.Get(9))

Log("Game initialized successfully")