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
            for handler in pairs(handlers[table]) do handler() end
            handlers[table] = nil
        end

        local gst = Timer()
        gst:Start(0.00, false, function()
            gst:Destroy()
            local result, err = pcall(function()
                RunHandlers("gameStart")
            end)
            if not result then Log(err) end
        end)

        local oldInitBliz = InitBlizzard
        local oldInitGlobals = InitGlobals
        local oldInitTrigs = InitCustomTriggers
        local oldInit = RunInitializationTriggers

        function InitBlizzard()
            local result, err = pcall(function()
                oldInitBliz()
                RunHandlers("initBlizzard")
            end)
            if not result then Log(err) end
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
            local result, err = pcall(function()
                if oldInitGlobals then oldInitGlobals() end
                RunHandlers("initGlobals")
            end)
            if not result then Log(err) end
        end

        function InitCustomTriggers()
            local result, err = pcall(function()
                if oldInitTrigs then oldInitTrigs() end
                RunHandlers("initCustomTriggers")
            end)
            if not result then Log(err) end
        end

        function RunInitializationTriggers()
            local result, err = pcall(function()
                if oldInit then oldInit() end
                RunHandlers("initialization")
            end)
            if not result then Log(err) end
        end
    end)

    if not result then
        print(err)
    end
end
