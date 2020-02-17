local Class = require("Class")
local UHDUnit = require("Core.UHDUnit")
local WC3 = require("WC3.All")

local Log = require("Log")


local boosLog = Log.Category("Boos\\Boos", {
    printVerbosity = Log.Verbosity.Trace,
    fileVerbosity = Log.Verbosity.Trace,
    })

    local Boos= Class(UHDUnit)

    function Boos:ctor(...)
        UHDUnit.ctor(self, ...)
        self.abilities = WC3.Trigger()
        self.abilities:RegisterUnitSpellEffect(self)
        self.toDestroy[self.abilities] = true
        self.aggroBehavier = WC3.Trigger()
        self.toDestroy[self.aggroBehavier] = true
    end


    function Boos:Destroy()
        local timer = WC3.Timer()
        timer:Start(15, false, function()
            UHDUnit.Destroy(self)
            timer:Destroy()
        end)
    end


return Boos