Utils = Utils or {}

-- Send a debug message to the console if the debug mode is enabled.
-- @param ... The message to send to the console.
function Utils:Debug(...)
    if not Config.DebugMode then return end

    -- Get the calling function info to get the name of the function calling Utils:Debug()
    local info = debug.getinfo(2, "n")
    local callerName = info and info.name or "Unknown"

    local args = {...}
    local formatStr = table.remove(args, 1)

    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            args[i] = json.encode(arg)
        elseif arg == nil then
            args[i] = "nil"
        else
            args[i] = tostring(arg)
        end
    end

    local message = formatStr:format(table.unpack(args))

    exports[Config.ExportNames.s1nLib]:debug(("%s: (%s) %s"):format(GetCurrentResourceName(), callerName, message))
end