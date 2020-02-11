local Log = Require("Log")
local Init = Require("Initialization")

if ExtensiveLog and TestBuild then
    local globalInit = "false";
    local customTriggerInit = "false";
    local initializtion = "false";
    local blizz = "false";

    Init.Global:Add(function ()
        globalInit = "true"
    end)
    Init.CustomTrigger:Add(function ()
        customTriggerInit = "true"
    end)
    Init.Initializtion:Add(function ()
        initializtion = "true"
    end)
    Init.Blizzard:Add(function ()
        blizz = "true"
    end)
    Init.GameStart:Add(function()
        Log("GameStart: true")
        Log("InitGlobals: " .. globalInit)
        Log("InitCustomTriggers: " .. customTriggerInit)
        Log("RunInitializationTriggers: " .. initializtion)
        Log("InitBlizzard: " .. blizz)
    end)
end
