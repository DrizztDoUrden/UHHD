local Log = Require("Log")
local WCPlayer = Require("WC3.Player")
local DuskKnight = Require("Heroes.DuskKnight")
local WaveObserver = Require("Core.WaveObserver")
local Core = Require("Core.Core")

local testHeroPreset = DuskKnight()
local core = Core(WCPlayer.Get(8), 0, -1800, 0)
local tavern = tawern(WCPlayer.Get(8), 0, -1800, 0)

for i = 0,1 do
    testHeroPreset:Spawn(WCPlayer.Get(i), 0, -1600, 0)
end

local testWaveObserver = WaveObserver(WCPlayer.Get(9))

Log("Game initialized successfully")