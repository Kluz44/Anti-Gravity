API = {}

-- Send a notification to the player
-- @param message string The message to be shown to the player
function API:NotifyPlayer(message)
    -- Want to use another export ? Change it here or inside s1n_lib/src/modules/framework/client/notify.lua !
    exports[Config.ExportNames.s1nLib]:showNotification(message)
end