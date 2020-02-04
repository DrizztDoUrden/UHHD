if TestBuild then
    Module("Tests.Initialization", function()
        local globalInit = "false";
        local customTriggerInit = "false";
        local initializtion = "false";
        local blizz = "false";

        GlobalInit:Add(function ()
            globalInit = "true"
        end)
        CustomTriggerInit:Add(function ()
            customTriggerInit = "true"
        end)
        Initializtion:Add(function ()
            initializtion = "true"
        end)
        BlizzardInit:Add(function ()
            blizz = "true"
        end)
        GameStart:Add(function()
            for pid = 0, 23 do
                DisplayTextToPlayer(Player(pid), 0, 0, "GameStart: true")
                DisplayTextToPlayer(Player(pid), 0, 0, "InitGlobals: " .. globalInit)
                DisplayTextToPlayer(Player(pid), 0, 0, "InitCustomTriggers: " .. customTriggerInit)
                DisplayTextToPlayer(Player(pid), 0, 0, "RunInitializationTriggers: " .. initializtion)
                DisplayTextToPlayer(Player(pid), 0, 0, "InitBlizzard: " .. blizz)
            end
        end)
    end)
end
