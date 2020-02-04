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
                if not module.hasErrors and #module.requirements == #module.resolvedRequirements then
                    local ret = table.pack(coroutine.resume(module.definition, table.unpack(module.resolvedRequirements)))
                    local correct = table.remove(ret, 1)

                    if not correct then
                        module.hasErrors = true
                        Log(">   has errors:", table.unpack(ret))
                    end

                    module.resolvedRequirements = {}
                    if #ret > 0 and ret[1] == resume then
                        module.requirements = ret
                        for reqId, id in pairs(module.requirements) do
                            local ready = readyModules[id]
                            if ready then
                                module.resolvedRequirements[reqId] = ready
                                module.resolvedRequirements.n = (module.resolvedRequirements.n or 0) + 1
                            end
                        end
                    else
                        if #ret == 1 then ret = ret[1] end
                        anyFound = true
                        readyModules[module.id] = ret
                        table.remove(modules, moduleId)
                        for _, other in pairs(modules) do
                            for reqId, id in pairs(other.requirements) do
                                if id == module.id and not other.resolvedRequirements[reqId] then
                                    other.resolvedRequirements[reqId] = ret
                                    other.resolvedRequirements.n = (other.resolvedRequirements.n or 0) + 1
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
        table.insert(modules, {
            id = id,
            requirements = {},
            definition = coroutine.create(definition),
            resolvedRequirements = {},
        })
    end
end
