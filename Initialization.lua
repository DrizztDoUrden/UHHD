do
    local result, err = pcall(function()
        local handlers = {
            initGlobals = {},
            initBlizzard = {},
            initCustomTriggers = {},
            initialization = {},
            gameStart = {},
        }

        local function FunctionRegistar(table)
            return setmetatable({}, {
                __index = {
                    Add = function(_, func)
                        table[func] = true
                    end
                },
            })
        end

        GlobalInit = FunctionRegistar(handlers.initGlobals)
        CustomTriggerInit = FunctionRegistar(handlers.initCustomTriggers)
        Initializtion = FunctionRegistar(handlers.initialization)
        BlizzardInit = FunctionRegistar(handlers.initBlizzard)
        GameStart = FunctionRegistar(handlers.gameStart)

        local function RunHandlers(table)
            for handler in pairs(handlers[table]) do
                local result, err = pcall(function()
                    handler()
                end)
                if not result then Log(err) end
            end
            handlers[table] = nil
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
    end)

    if not result then
        print(err)
    end
end
