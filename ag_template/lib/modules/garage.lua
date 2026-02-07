AG.Garage = {}

-- [[ GET PLAYER VEHICLES ]]
-- Returns asynchronous list of vehicles: { { plate = 'ABC', vehicle = 'adder', state = 1 }, ... }
function AG.Garage.GetPlayerVehicles(source)
    local pPromise = promise.new()

    -- QBCore / QBox
    if AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        local Player = AG.GetPlayer(source)
        if not Player then return {} end
        
        MySQL.query('SELECT * FROM player_vehicles WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(result)
            pPromise:resolve(result)
        end)

    -- ESX
    elseif AG.Framework == 'esx' then
        local xPlayer = AG.GetPlayer(source)
        if not xPlayer then return {} end

        MySQL.query('SELECT * FROM owned_vehicles WHERE owner = ?', { xPlayer.identifier }, function(result)
            -- Normalize result structure if needed, or return raw
            pPromise:resolve(result)
        end)
    else
        pPromise:resolve({})
    end

    return Citizen.Await(pPromise)
end

-- [[ STORE VEHICLE ]]
-- Mark a vehicle as stored in the database.
-- Note: This doesn't delete the entity, it just updates the state so the Garage script knows it's parked.
function AG.Garage.SetVehicleState(plate, stored, garageName)
    local state = stored and 1 or 0
    local boolState = stored and true or false
    garageName = garageName or 'Legion' -- Default garage if none provided

    -- QBCore / QBox
    if AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        MySQL.update('UPDATE player_vehicles SET state = ?, garage = ? WHERE plate = ?', { state, garageName, plate })

    -- ESX
    elseif AG.Framework == 'esx' then
        -- ESX Standard uses 'stored' (boolean or tinyint)
        MySQL.update('UPDATE owned_vehicles SET stored = ?, parking = ? WHERE plate = ?', { boolState, garageName, plate })
        
        -- Some ESX versions use `state` instead of `stored`.
        -- We try both usually, or rely on the specific garage script if possible.
    end
    
    -- SUPPORT FOR SPECIFIC SCRIPTS (If they have exports)
    local garageSystem = AG.System.Garage
    
    if garageSystem == 'qs-advancedgarages' then
        -- QS often relies on DB, but if there's an export to refresh cache, call it here.
    elseif garageSystem == 'cd_garage' then
        -- CD Garage specific logic
    end
end
