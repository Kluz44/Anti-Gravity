-- Admin Server Callbacks

RegisterNetEvent('ethor_bus:server:SaveStop', function(data)
    local src = source
    -- Quick permission check
    if not IsPlayerAceAllowed(src, 'command.buscreate') then return end

    MySQL.insert([[
        INSERT INTO bus_stops (id, name, coords, approach_coords, exit_coords, queue_coords, base_demand, rush_profile) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        name = VALUES(name), coords = VALUES(coords), approach_coords = VALUES(approach_coords), 
        exit_coords = VALUES(exit_coords), queue_coords = VALUES(queue_coords), 
        base_demand = VALUES(base_demand), rush_profile = VALUES(rush_profile)
    ]], {
        data.id,
        data.name,
        json.encode(data.coords),
        json.encode(data.approach_coords),
        json.encode(data.exit_coords),
        json.encode(data.queue_coords),
        data.base_demand,
        data.rush_profile
    }, function(stored)
        if stored then
            print('^2[ethor_bus] ^7Admin ' .. GetPlayerName(src) .. ' saved/updated Stop: ' .. data.id)
        end
    end)
end)
