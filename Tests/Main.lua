Module("Tests.Main", function()
    local DuskKnight = Require("Heroes.DuskKnight")

    local testHeroPreset = DuskKnight()
    local testHero = testHeroPreset:Spawn(Player(0), 0, 0, 0)
    Log("Game initialized successfully")
end)
