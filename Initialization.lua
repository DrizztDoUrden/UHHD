local Log = require("Log")
local Timer = require("WC3.Timer")

local handlers = {
    initGlobals = { funcs = {}, executed = false, },
    initBlizzard = { funcs = {}, executed = false, },
    initCustomTriggers = { funcs = {}, executed = false, },
    initialization = { funcs = {}, executed = false, },
    gameStart = { funcs = {}, executed = false, },
}

local function FunctionRegistar(table)
    return setmetatable({}, {
        __index = {
            Add = function(_, func)
                if table.executed then
                    local result, err = pcall(func)
                    if not result then Log(err) end
                else
                    table.funcs[func] = true
                end
            end
        },
    })
end

local Init = {
    Global = FunctionRegistar(handlers.initGlobals),
    CustomTrigger = FunctionRegistar(handlers.initCustomTriggers),
    Initializtion = FunctionRegistar(handlers.initialization),
    Blizzard = FunctionRegistar(handlers.initBlizzard),
    GameStart = FunctionRegistar(handlers.gameStart),
}

local function RunHandlers(table)
    for handler in pairs(handlers[table].funcs) do
        local result, err = pcall(handler)
        if not result then Log(err) end
    end
    handlers[table].funcs = nil
    handlers[table].executed = true
end

local gst = Timer()
gst:Start(0.00, false, function()
    gst:Destroy()
    RunHandlers("gameStart")
end)

local oldInitBliz = InitBlizzard
local oldInitGlobals = InitGlobals
local oldInitTrigs = InitCustomTriggers
local oldInit = RunInitializationTriggers

function InitBlizzard()
    oldInitBliz()
    RunHandlers("initBlizzard")
    if not oldInitGlobals then
        InitGlobals()
    end
    if not oldInitTrigs then
        InitCustomTriggers()
    end
    if not oldInit then
        RunInitializationTriggers()
    end
end

function InitGlobals()
    if oldInitGlobals then oldInitGlobals() end
    RunHandlers("initGlobals")
end

function InitCustomTriggers()
    if oldInitTrigs then oldInitTrigs() end
    RunHandlers("initCustomTriggers")
end

function RunInitializationTriggers()
    if oldInit then oldInit() end
    RunHandlers("initialization")
end

return Init