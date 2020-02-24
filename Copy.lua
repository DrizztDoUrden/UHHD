local function CopyImplementation(object)
    if type(object) == "table" then
        local copy = {}
        for k, v in pairs(object) do
            copy[k] = CopyImplementation(v)
        end
        return copy
    end
    return object
end

local function Copy(object)
    if type(object) == "function" then
        error("Attempt to copy a function", 2)
    end
    if type(object) == "userdata" then
        error("Attempt to copy a userdata", 2)
    end
end

return Copy