do
    local modules = {}
    local readyModules = {}

    BlizzardInit:Add(function()
        local resume = {}

        local oldRequire = Require
        function Require(...)
            return table.unpack(coroutine.yield(resume, ...))
        end

        while #modules > 0 do
            local anyFound = false
            for moduleId, module in pairs(modules) do
                if not module.hasErrors and #module.requirements == module.resolvedRequirements.n then
                    local ret
                    local coocked = false

                    repeat
                        ret = table.pack(coroutine.resume(module.definition, module.resolvedRequirements))
                        local correct = table.remove(ret, 1)

                        if not correct then
                            module.hasErrors = true
                            Log(module.id .. " has errors:", table.unpack(ret))
                        end

                        module.resolvedRequirements = { n = 0, }
                        if #ret == 0 or ret[1] ~= resume then
                            coocked = true
                            break
                        end

                        table.remove(ret, 1)
                        module.requirements = ret
                        for reqId, id in pairs(module.requirements) do
                            local ready = readyModules[id]
                            if ready then
                                module.resolvedRequirements[reqId] = ready
                                module.resolvedRequirements.n = module.resolvedRequirements.n + 1
                            end
                        end
                    until module.resolvedRequirements.n ~= #module.requirements
                    
                    if coocked then
                        Log("Successfully loaded " .. module.id)
                        if #ret == 1 then ret = ret[1] end
                        anyFound = true
                        readyModules[module.id] = ret
                        table.remove(modules, moduleId)
                        for _, other in pairs(modules) do
                            for reqId, id in ipairs(other.requirements) do
                                if id == module.id and not other.resolvedRequirements[reqId] then
                                    other.resolvedRequirements[reqId] = ret
                                    other.resolvedRequirements.n = other.resolvedRequirements.n + 1
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
            if not anyFound then
                Log("Some modules not resolved:")
                for _, module in pairs(modules) do
                    Log(module.id)
                    for _, id in pairs(module.requirements) do
                        Log(">   has unresolved " .. id)
                    end
                end
                break
            end
        end
        modules = nil
        readyModules = nil
        Require = oldRequire
        Module = function (id, definition)
            Log("Module loading has already finished. Can't load " .. id)
        end
    end)

    function Module(id, definition)
        if type(id) ~= "string" then
            Log("Module id must be string")
            return
        end
        if type(definition) == "table" then
            local t = definition
            definition = function() return t end
        elseif type(definition) ~= "function" then
            Log("Module definition must be function or table")
            return
        end
        table.insert(modules, {
            id = id,
            requirements = {},
            definition = coroutine.create(definition),
            resolvedRequirements = { n = 0, },
        })
    end
end
