if false and TestBuild then
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
            print("GameStart: true")
            print("InitGlobals: " .. globalInit)
            print("InitCustomTriggers: " .. customTriggerInit)
            print("RunInitializationTriggers: " .. initializtion)
            print("InitBlizzard: " .. blizz)
        end)
    end)
end
