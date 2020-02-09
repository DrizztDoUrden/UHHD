
Module("Tests.Main", function()
    local DuskKnight = Require("Heroes.DuskKnight")

    local UHDUnit = Require("UHDUnit")
    local CreepsSpawner = Require("CreepsSpawner")
    testCreepsSpawner = CreepsSpawner()
    testCreepsSpawner:SpawnNewWave(WCPlayer.Get(1), 0)
    local testHeroPreset = DuskKnight()
    local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 700, 0)

    Log("Game initialized successfully")
end)
