local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local UHDUnit = Require("Core.UHDUnit")
local CreepsSpawner = Require("CreepsSpawner")

local testHeroPreset = DuskKnight()
local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 700, 0)

local testCreepsSpawner = CreepsSpawner()
testCreepsSpawner:SpawnNewWave(WCPlayer.Get(1), 0)

Log("Game initialized successfully")
