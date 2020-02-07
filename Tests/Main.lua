Module("Tests.Main", function()
    local DuskKnight = Require("Heroes.DuskKnight")
    local UHDUnit = Require("UHDUnit")

    local testHeroPreset = DuskKnight()
    local testHero = testHeroPreset:Spawn(WCPlayer.Get(0), 0, 0, 0)

    local dummy = UHDUnit(WCPlayer.Get(1), FourCC('hfoo'), 500, 0, 0)

    dummy.secondaryStats.health = 150
    dummy.secondaryStats.weaponDamage = 15
    dummy.secondaryStats.armor = 5

    dummy:ApplyStats()

    Log("Game initialized successfully")
end)
