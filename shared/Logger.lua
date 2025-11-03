local Logger = {}
Logger.__index = Logger

local function getEnv()
    return IsDuplicityVersion() and "Server" or "Client"
end

local function serialize(value, indent)
    indent = indent or 0
    local t = type(value)
    if t ~= "table" then return tostring(value) end

    if next(value) == nil then return "{EMPTY TABLE}" end

    local lines = { "{" }
    for k, v in pairs(value) do
        local key = tostring(k)
        local val = serialize(v, indent + 2)
        table.insert(lines, string.rep(" ", indent + 2) .. key .. " = " .. val .. ",")
    end
    table.insert(lines, string.rep(" ", indent) .. "}")
    return table.concat(lines, "\n")
end

local function printLog(level, msg, ...)
    local prefix = ("[^2Factions^0] [^3%s^0]: "):format(level)

    local parts = {}

    if type(msg) == "table" then
        table.insert(parts, serialize(msg))
    else
        table.insert(parts, tostring(msg))
    end

    local nargs = select("#", ...)
    for i = 1, nargs do
        local arg = select(i, ...)
        if type(arg) == "table" then
            table.insert(parts, serialize(arg))
        else
            table.insert(parts, tostring(arg))
        end
    end

    local finalMsg = table.concat(parts, " ")

    print(prefix .. finalMsg)
end

-- Public functions
function Logger:Info(msg, ...)
    printLog("Info", msg, ...)
end

function Logger:Error(msg, ...)
    printLog("Err", msg, ...)
end

function Logger:Warning(msg, ...)
    printLog("Warning", msg, ...)
end

function Logger:Debug(msg, ...)
    if mCore.isDebug then
        printLog("Debug", msg, ...)
    end
end

return Logger
