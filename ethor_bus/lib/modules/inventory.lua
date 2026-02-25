AG.Inventory = {}

-- [[ ADD ITEM ]]
-- Returns true/false
function AG.Inventory.AddItem(source, item, count, metadata, slot)
    local invResource = AG.System.Inventory
    count = count or 1

    -- OX INVENTORY
    if invResource == 'ox_inventory' then
        if IsDuplicityVersion() then -- Server
            return exports.ox_inventory:AddItem(source, item, count, metadata, slot)
        end
    
    -- QS INVENTORY
    elseif invResource == 'qs-inventory' then
        if IsDuplicityVersion() then
            return exports['qs-inventory']:AddItem(source, item, count, slot, metadata)
        end

    -- QB / PS / ORIGEN / CODEM (Usually QBCore Standard)
    elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        if IsDuplicityVersion() then
            local Player = AG.GetPlayer(source)
            if Player then
                return Player.Functions.AddItem(item, count, slot, metadata)
            end
        end

    -- ESX DEFAULT
    elseif AG.Framework == 'esx' then
        if IsDuplicityVersion() then
            local xPlayer = AG.GetPlayer(source)
            if xPlayer then
                if xPlayer.canCarryItem and not xPlayer.canCarryItem(item, count) then
                    return false
                end
                xPlayer.addInventoryItem(item, count, metadata, slot)
                return true
            end
        end
    end

    print('^1[AG-Template] ^7AddItem Not Implemented for: ' .. (invResource or 'Unknown'))
    return false
end

-- [[ REMOVE ITEM ]]
-- Returns true/false
function AG.Inventory.RemoveItem(source, item, count, metadata, slot)
    local invResource = AG.System.Inventory
    count = count or 1

    -- OX INVENTORY
    if invResource == 'ox_inventory' then
        if IsDuplicityVersion() then
            return exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
        end

    -- QS INVENTORY
    elseif invResource == 'qs-inventory' then
        if IsDuplicityVersion() then
            return exports['qs-inventory']:RemoveItem(source, item, count, slot, metadata)
        end

    -- QB / PS / ORIGEN / CODEM
    elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        if IsDuplicityVersion() then
            local Player = AG.GetPlayer(source)
            if Player then
                return Player.Functions.RemoveItem(item, count, slot)
            end
        end

    -- ESX DEFAULT
    elseif AG.Framework == 'esx' then
        if IsDuplicityVersion() then
            local xPlayer = AG.GetPlayer(source)
            if xPlayer then
                xPlayer.removeInventoryItem(item, count, metadata, slot)
                return true
            end
        end
    end

    return false
end

-- [[ GET ITEM COUNT ]]
-- Returns count (number)
function AG.Inventory.GetItemCount(source, item, metadata)
    local invResource = AG.System.Inventory

    -- OX INVENTORY
    if invResource == 'ox_inventory' then
        local data = exports.ox_inventory:GetItem(source, item, metadata, false)
        return data and data.count or 0

    -- QS INVENTORY
    elseif invResource == 'qs-inventory' then
        local data = exports['qs-inventory']:GetItemTotalAmount(source, item)
        return data or 0

    -- QB / PS / ORIGEN
    elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        if IsDuplicityVersion() then
            local Player = AG.GetPlayer(source)
            if Player then
                -- QBCore usually returns table or nil
                local itemData = Player.Functions.GetItemByName(item)
                return itemData and itemData.amount or 0
            end
        end

    -- ESX DEFAULT
    elseif AG.Framework == 'esx' then
        if IsDuplicityVersion() then
            local xPlayer = AG.GetPlayer(source)
            if xPlayer then
                local itemData = xPlayer.getInventoryItem(item)
                return itemData and itemData.count or 0
            end
        end
    end

    return 0
end

-- [[ CAN CARRY ITEM ]] 
-- Returns true/false
function AG.Inventory.CanCarryItem(source, item, count)
    local invResource = AG.System.Inventory
    count = count or 1

    -- OX INVENTORY
    if invResource == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(source, item, count)
        
    -- QS INVENTORY
    elseif invResource == 'qs-inventory' then
         return exports['qs-inventory']:CanCarryItem(source, item, count)
         
    -- QB / PS (Default check often built into AddItem, but we can check weight if exposed)
    -- Fallback to assuming yes if framework standard check isn't exposed easily
    -- QBCore doesn't have a direct 'CanCarry' export widely used, logic is internal.
    elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        -- Simple weight check logic could be implemented if needed, 
        -- but default to true as AddItem handles failure.
        return true 

    -- ESX
    elseif AG.Framework == 'esx' then
        if IsDuplicityVersion() then
            local xPlayer = AG.GetPlayer(source)
            if xPlayer and xPlayer.canCarryItem then
                return xPlayer.canCarryItem(item, count)
            end
        end
    end
    
    return true
end
