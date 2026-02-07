-- Server Logic Entry Point
print('^2[AG-PowerWater] ^7Resource Started. Name: ^3' .. GetCurrentResourceName() .. '^7')

-- [[ ADMIN COMMAND HELPER ]]
_G.RegisterAdminCommand = function(name, help, handler)
    if AG.Framework == 'esx' then
        -- Supports 'admin', 'god', 'owner', 'superadmin'
        ESX.RegisterCommand(name, {'admin', 'superadmin', 'god', 'owner'}, function(xPlayer, args, showError)
             handler(xPlayer.source, args)
        end, true, {help = help or 'Admin Command'})
    elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        -- QBCore usually inherits (god > admin). 'admin' should suffice for all.
        QBCore.Commands.Add(name, help or 'Admin Command', {}, false, function(source, args)
             handler(source, args)
        end, 'admin')
    else
        -- Standalone / Fallback
        RegisterCommand(name, function(source, args)
             if source == 0 or IsPlayerAceAllowed(source, 'command.'..name) then
                 handler(source, args)
             end
        end, true)
    end
end

-- [[ USABLE ITEMS ]]
CreateThread(function()
    while not AG.Framework do 
        Wait(500) 
        print('^3[AG-Debug] Waiting for Framework...^7')
    end
    print('^2[AG-Debug] Framework Detected: ' .. AG.Framework .. '^7')

    -- Item Registration Logic
    local itemRegistered = false
    local tabletItem = Config.Items and Config.Items.tablet -- lowercase key

    if tabletItem then
        -- 1. Try QS-Inventory (if started)
        if GetResourceState('qs-inventory') == 'started' then
            local status, err = pcall(function()
                exports['qs-inventory']:CreateUsableItem(tabletItem, function(source, item)
                    TriggerClientEvent('ag_powerwater:client:openTablet', source)
                end)
            end)
            if status then
                print('^2[AG-PowerWater] ^7Tablet Item Registered (QS-Inventory): ' .. tabletItem)
                itemRegistered = true
            else
                print('^1[AG-PowerWater] ^7QS-Inventory Export Failed: ' .. tostring(err))
            end
        end

        -- 2. Fallback to Framework Default if not registered yet
        if not itemRegistered then
            if AG.Framework == 'esx' then
                ESX.RegisterUsableItem(tabletItem, function(source)
                     TriggerClientEvent('ag_powerwater:client:openTablet', source)
                end)
                print('^2[AG-PowerWater] ^7Tablet Item Registered (ESX): ' .. tabletItem)
                itemRegistered = true
            elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
                QBCore.Functions.CreateUseableItem(tabletItem, function(source, item)
                     TriggerClientEvent('ag_powerwater:client:openTablet', source)
                end)
                print('^2[AG-PowerWater] ^7Tablet Item Registered (QBCore): ' .. tabletItem)
                itemRegistered = true
            end
        end
        
        if not itemRegistered then
            print('^1[AG-PowerWater] ^7Failed to register Tablet Item! (No compatible system found)')
        end
    else
        print('^3[AG-PowerWater] ^7Config.Items.tablet is missing. Item registration skipped.^7')
    end
end)

-- [[ ADMIN COMMANDS ]]
RegisterAdminCommand('ag_test', 'Run Module Tests', function(source, args)
    if source == 0 then return end -- Player only
    
    local Player = AG.GetPlayer(source)
    if not Player then return end
    
    print('^4[AG-Test] ^7Starting Module Tests for ID: ' .. source)

    -- 1. Test Notify
    AG.Notify.Show(source, 'Testing Notification System', 'success', 5000)
    print('^2[AG-Test] ^7Notify Sent.')

    -- 2. Test Inventory (Give Bread if possible)
    local hasItem = AG.Inventory.HasItem(source, 'bread', 1) 
    local count = AG.Inventory.GetItemCount(source, 'bread')
    print('^2[AG-Test] ^7Bread Count: ' .. count)
    
    if AG.Inventory.AddItem(source, 'bread', 1) then
        print('^2[AG-Test] ^7Added 1 Bread.')
    else
        print('^1[AG-Test] ^7Failed to add Bread (Full or Invalid Item).')
    end

    -- 3. Test Garage (Read only to be safe)
    local vehicles = AG.Garage.GetPlayerVehicles(source)
    print('^2[AG-Test] ^7Vehicle Count: ' .. #vehicles)

    -- 4. Test Phone
    AG.Phone.SendMail(source, {
        sender = 'AG System',
        subject = 'Test Mail',
        message = 'This is a test email from the AG Template.'
    })
    print('^2[AG-Test] ^7Mail Sent.')
end)

RegisterAdminCommand('fixcables', 'Debug: Fix Cables Minigame', function(source, args)
    TriggerClientEvent('ag_powerwater:client:fixCables', source)
end)

RegisterAdminCommand('housecall', 'Debug: Trigger House Call', function(source, args)
    TriggerEvent('ag_powerwater:server:requestHouseCall', source) 
end)
