local Class = Require("Class")

local Verbosity = {
    Fatal = 0,
    Critical = 1,
    Error = 2,
    Warning = 3,
    Message = 4,
    Info = 5,
    Trace = 6,
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

local function LogInternal(category, verbosity, ...)
    if verbosity <= math.max(category.printVerbosity, category.fileVerbosity) then
        if verbosity <= category.printVerbosity then
            print("[" .. verbosityNames[verbosity] .. "]" .. category.name .. ": ", ...)
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
    self.fileVerbosity = options.fileVerbosity or Verbosity.Message
    self.printVerbosity = options.printVerbosity or Verbosity.Warning
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