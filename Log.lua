local Class = require("Class")

local Verbosity = {
    Fatal = 1,
    Critical = 2,
    Error = 3,
    Warning = 4,
    Message = 5,
    Info = 6,
    Trace = 7,
}

local verbosityNames = {
    "Fatal",
    "Critical",
    "Error",
    "Warning",
    "Message",
    "Info",
    "Trace",
}

local verbosityColors = {
    [Verbosity.Fatal] = { start = "|cffff0000", end_ = "|r", },
    [Verbosity.Critical] = { start = "|cffff0000", end_ = "|r", },
    [Verbosity.Error] = { start = "|cffff0000", end_ = "|r", },
    [Verbosity.Warning] = { start = "|cffffff33", end_ = "|r", },
    [Verbosity.Message] = { start = "", end_ = "", },
    [Verbosity.Info] = { start = "", end_ = "", },
    [Verbosity.Trace] = { start = "", end_ = "", },
}

local function LogInternal(category, verbosity, ...)
    if verbosity <= math.max(category.printVerbosity, category.fileVerbosity) then
        if verbosity <= category.printVerbosity then
            local params = {...}
            table.insert(params, verbosityColors[verbosity].end_)
            print(verbosityColors[verbosity].start .. "[" .. verbosityNames[verbosity] .. "] " .. category.name .. ": ", ...)
        end
        if verbosity <= category.fileVerbosity then
            category.buffer = category.buffer .. "\n[" .. verbosityNames[verbosity] .. "]"
            for _, line in pairs({...}) do
                category.buffer = category.buffer .. "\t" .. tostring(line)
            end
            PreloadGenClear()
            PreloadStart()
            Preload("\")" .. category.buffer .. "\n")
            PreloadGenEnd("Logs\\" .. category.name .. ".txt")
        end
    end
end

local Category = Class()

function Category:ctor(name, options)
    options = options or {}
    self.name = name
    if TestBuild then
        self.printVerbosity = options.printVerbosity or Verbosity.Info
    else
        self.printVerbosity = options.printVerbosity or Verbosity.Warning
    end
    if TestBuild then
        self.fileVerbosity = options.fileVerbosity or Verbosity.Trace
    else
        self.fileVerbosity = options.fileVerbosity or Verbosity.Message
    end
    self.buffer = ""
end

function Category:Log(verbosity, ...)
    LogInternal(self, verbosity, ...)
end

function Category:Fatal(...)
    LogInternal(self, Verbosity.Fatal, ...)
end

function Category:Critical(...)
    LogInternal(self, Verbosity.Critical, ...)
end

function Category:Error(...)
    LogInternal(self, Verbosity.Error, ...)
end

function Category:Warning(...)
    LogInternal(self, Verbosity.Warning, ...)
end

function Category:Message(...)
    LogInternal(self, Verbosity.Message, ...)
end

function Category:Info(...)
    LogInternal(self, Verbosity.Info, ...)
end

function Category:Trace(...)
    LogInternal(self, Verbosity.Trace, ...)
end

Category.Default = Category("Default")

local mt = {
    __call = function(_, ...) LogInternal(Category.Default, Verbosity.Message, ...) end,
    __index = {
        Verbosity = Verbosity,
        Category = Category,
    },
}

local Log = setmetatable({}, mt)

return Log