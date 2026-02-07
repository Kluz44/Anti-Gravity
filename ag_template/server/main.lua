-- Server Logic Entry Point

-- Server Logic Entry Point

RegisterCommand('ag_test', function(source, args)
    if source == 0 then return end -- Player only
    
    local Player = AG.GetPlayer(source)
    if not Player then return end
    
    print('^4[AG-Test] ^7Starting Module Tests for ID: ' .. source)

    -- 1. Test Notify
    AG.Notify.Show(source, 'Testing Notification System', 'success', 5000)
    print('^2[AG-Test] ^7Notify Sent.')

    -- 2. Test Inventory (Give Bread if possible)
    local hasItem = AG.Inventory.HasItem(source, 'bread', 1) -- HasItem needs implementation or use GetItemCount
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

end, true) -- true = restricted (requires ace perms usually, or change to false for dev)
