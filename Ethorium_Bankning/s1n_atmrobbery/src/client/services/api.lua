API = API or {}

-- This function is called by all jobs listed in Config.NotificationJobs when a robbery has been started.
-- You can customize it to your liking.
-- @params coords vector3 The coordinates of the robbery
function NotifyPolice(coords)
    if not coords then return Utils:Debug("policeAlert: Coordinates not received") end

    -- Show the blip on the map
    Helpers:CreateRobberyBlip(coords)

    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    if not streetHash then return Utils:Debug("policeAlert: Street hash not found") end

    local streetName = GetStreetNameFromHashKey(streetHash)
    if not streetName then return Utils:Debug("policeAlert: Street name not found") end

    -- Send the notification to the police
    Helpers:Notification(Config.Translation.RobberyInProgressInStreet:format(streetName))
end

-- Notify the player with a message
-- @param message string The message to be sent to the player
function API:NotifyPlayer(message)
    Utils:Debug(("Notifying the player with the message: %s"):format(message))

    exports[Config.ExportNames.s1nLib]:showNotification({
        message = message
    })
end