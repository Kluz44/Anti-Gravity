API = API or {}

-- This function is called when a robbery has been started for each player that should receive the alert.
-- You can customize it to your liking
-- @params playerSource source An online player who has his job listed in Config.NotificationJobs
-- @params coords vector3 The coordinates of the robbery
function API:SendAlertToPoliceOfficer(playerSource, coords)
    TriggerClientEvent('s1n_atmrobbery:policeAlert', playerSource, coords)
end

-- This function is called once when a robbery has been started.
-- @params coords vector3 The coordinates of the robbery
function API:SendAlert(coords)
    -- You can do whatever you want here, for example call an export or trigger an event from another script
end

-- Send a log to the discord webhook
-- @param message string The message to be sent to the discord webhook
function API:SendDiscordLog(message)
    if not Config.DiscordWebhook.enable then return end

    exports[Config.ExportNames.s1nLib]:sendDiscordLog("s1n_atmrobbery", message)
end