local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local CreepsSpawner = Require("Core.CreepsSpawner")

local testHeroPreset = DuskKnight()
local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 700, 0)

    local UHDUnit = Require("UHDUnit")
    local WaveObserver = Require("WaveObserver")
    testWaveObserver = WaveObserver(WCPlayer.Get(1))
    local testHeroPreset = DuskKnight()
    local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 700, 0)

Log("Game initialized successfully")
