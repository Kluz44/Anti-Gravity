API = API or {}

-- Send a log to the discord webhook
-- @param message string The message to be sent to the discord webhook
function API:SendDiscordLog(message)
    if not Config.DiscordWebhook.enable then return end

    exports[Config.ExportNames.s1nLib]:sendDiscordLog("s1n_billing", message)
end

-- Send a notification to the player
-- @param playerSource number The player source to send the notification to
-- @param message string The message to be shown to the player
function API:NotifyPlayer(playerSource, message)
    -- Want to use another export ? Change it here or inside s1n_lib/src/modules/framework/server/notify.lua !
    exports[Config.ExportNames.s1nLib]:notifyPlayer(playerSource, message)
end