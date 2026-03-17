local QBCore = exports['qb-core']:GetCoreObject()

local creatorOpen = false

RegisterNetEvent('ethorium_banking:client:OpenCreatorUI', function()
    -- This event is triggered from /bankcreator command on the server
    if not creatorOpen then
        creatorOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openCreator"
        })
    end
end)

RegisterNUICallback('closeCreator', function(data, cb)
    SetNuiFocus(false, false)
    creatorOpen = false
    cb('ok')
end)

-- Callback from UI when admin creates a bank
RegisterNUICallback('createBank', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    data.coords = {x = coords.x, y = coords.y, z = coords.z}
    
    QBCore.Functions.TriggerCallback('ethorium_banking:server:CreateBank', function(success, msg)
        if success then
            QBCore.Functions.Notify('Bank Created Successfully!', 'success')
        else
            QBCore.Functions.Notify('Error: ' .. tostring(msg), 'error')
        end
        cb('ok')
    end, data.name, data.type, data.vaultBalance, data)
end)
