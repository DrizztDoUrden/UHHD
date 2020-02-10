do
    local modules = {}
    local readyModules = {}

    BlizzardInit:Add(function()
        local resume = {}

        local oldRequire = Require
        function Require(id)
            return table.unpack(coroutine.yield(resume, id))
        end

        while #modules > 0 do
            local anyFound = false
            for moduleId, module in pairs(modules) do
                if not module.hasErrors and not module.requirement or module.resolvedRequirement then
                    local ret
                    local coocked = false

                    repeat
                        ret = table.pack(coroutine.resume(module.definition, module.resolvedRequirement))
                        local correct = table.remove(ret, 1)

                        if not correct then
                            module.hasErrors = true
                            Log(module.id .. " has errors:", table.unpack(ret))
                        end

                        module.resolvedRequirement = nil
                        if #ret == 0 or ret[1] ~= resume then
                            coocked = true
                            break
                        end

                        module.requirement = ret[2]
                        local ready = readyModules[module.requirement]
                        if ready then
                            module.resolvedRequirement = ready
                        end
                    until not module.resolvedRequirement
                    
                    if coocked then
                        if ExtensiveLog or true then
                            Log("Successfully loaded " .. module.id)
                        end
                        anyFound = true
                        readyModules[module.id] = ret
                        table.remove(modules, moduleId)
                        for _, other in pairs(modules) do
                            if other.requirement == module.id and not other.resolvedRequirement then
                                other.resolvedRequirement = ret
                            end
                        end
                        break
                    end
                end
            end
            if not anyFound then
                Log("Some modules not resolved:")
                for _, module in pairs(modules) do
                    Log(module.id .. " has unresolved requirement: " .. module.requirement)
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
            definition = coroutine.create(definition),
        })
    end
end
