local Log = require("Log")
local Init = require("Initialization")

local logTimer = Log.Category("Tests\\Initialization")

if TestBuild then
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
        logTimer:Trace("GameStart: true")
        logTimer:Trace("InitGlobals: " .. globalInit)
        logTimer:Trace("InitCustomTriggers: " .. customTriggerInit)
        logTimer:Trace("RunInitializationTriggers: " .. initializtion)
        logTimer:Trace("InitBlizzard: " .. blizz)
    end)
end
