-- Client Logic Entry Point
local isUiOpen = false

-- Command to open the UI
RegisterCommand('ag_menu', function()
    SetUiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            title = "AG Template Menu",
            message = "Welcome to the framework agnostic system."
        }
    })
    isUiOpen = true
end)

-- Close UI Callback
RegisterNUICallback('close', function(data, cb)
    SetUiFocus(false, false)
    isUiOpen = false
    cb('ok')
end)

-- Example Action Callback
RegisterNUICallback('action', function(data, cb)
    print('UI Action Triggered:', data.type)
    TriggerServerEvent('ag_template:server:exampleEvent', data)
    cb('ok')
end)
