Utils = Utils or {}

-- Send a debug message to the console if the debug mode is enabled.
-- @param ... The message to send to the console.
function Utils:Debug(...)
    if not Config.debugMode then return end

    exports[Config.ExportNames.s1nLib]:debug(("%s: %s"):format(GetCurrentResourceName(), ...))
end