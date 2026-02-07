AG.Notify = {}

-- [[ SHOW NOTIFICATION ]]
-- Types: 'success', 'error', 'info', 'warning'
-- Length: ms (default 5000)
function AG.Notify.Show(source, msg, type, length)
    local notifySystem = AG.System.Notify
    type = type or 'info'
    length = length or 5000
    
    -- Server-side call (Triggers client event usually)
    if IsDuplicityVersion() then
        -- Some systems have server exports, others need client events.
        -- We'll trigger a client event to handle the actual display to be safe and consistent.
        TriggerClientEvent('ag_template:client:notify', source, msg, type, length)
        return
    end

    -- CLIENT-SIDE LOGIC
    
    -- 1. OX LIB
    if notifySystem == 'ox_lib' then
        lib.notify({
            title = 'Notification',
            description = msg,
            type = type,
            duration = length
        })

    -- 2. OKOK NOTIFY
    elseif notifySystem == 'okokNotify' then
        exports['okokNotify']:Alert('Notification', msg, length, type)

    -- 3. MYTHIC NOTIFY
    elseif notifySystem == 'mythic_notify' then
        exports['mythic_notify']:DoHudText(type, msg)

    -- 4. P-NOTIFY
    elseif notifySystem == 'pNotify' then
        exports.pNotify:SendNotification({
            text = msg,
            type = type,
            timeout = length,
            layout = "centerRight",
            queue = "right"
        })

    -- 5. T-NOTIFY
    elseif notifySystem == 't-notify' then
        exports['t-notify']:Alert({
            style = type,
            message = msg,
            duration = length
        })
        
    -- 6. RCORE NOTIFY
    elseif notifySystem == 'rcore_notify' then
        -- rcore often mimics other styles or has its own
         exports['rcore_notify']:SendNotification(type, msg, length)

    -- 7. FRAMEWORK DEFAULTS
    elseif AG.Framework == 'qbox' or AG.Framework == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
        if type == 'info' then type = 'primary' end -- Fix for QBCore missing 'info' style
        QBCore.Functions.Notify(msg, type, length)

    elseif AG.Framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        ESX.ShowNotification(msg) -- ESX default doesn't always support type/length cleanly without plugins
    else
        -- Fallback
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, false)
    end
end

-- Client Event Handler to receive server notifications
if not IsDuplicityVersion() then
    RegisterNetEvent('ag_template:client:notify', function(msg, type, length)
        AG.Notify.Show(GetPlayerServerId(PlayerId()), msg, type, length)
    end)
end
