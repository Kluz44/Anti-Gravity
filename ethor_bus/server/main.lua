-- =============================================
-- Server Main Logic (ethor_bus)
-- =============================================

RegisterNetEvent('ethor_bus:server:RequestDispatchData', function()
    local src = source
    local playerAuth = AG.GetPlayer(src)
    -- TODO: Add specific job/boss check here based on Config.Society
    
    -- Fetch Stops
    local stops = MySQL.query.await('SELECT id, name, coords, base_demand, rush_profile FROM bus_stops')
    
    -- Fetch Routes (Assuming checking company later, fetching all for now)
    local routes = MySQL.query.await('SELECT id, name, color, stops_json FROM bus_routes')
    
    -- Parse JSON strings
    for k, v in ipairs(stops) do
        if type(v.coords) == 'string' then v.coords = json.decode(v.coords) end
    end
    for k, v in ipairs(routes) do
        if type(v.stops_json) == 'string' then v.stops = json.decode(v.stops_json) end
    end

    TriggerClientEvent('ethor_bus:client:OpenDispatchUI', src, {
        stops = stops,
        routes = routes
    })
    
    if Config.Debug then print('^4[ethor_bus] ^7Sent Dispatch Data to ' .. src) end
end)

-- =============================================
-- Passenger / Target Sync Logic
-- =============================================

-- Sync stops to clients for ox_target when they join
AddEventHandler('ag_template:playerLoaded', function(source) -- or QBCore:Server:PlayerLoaded depending on your specific bridge trigger
    local stops = MySQL.query.await('SELECT id, name, coords, base_demand, queue_coords FROM bus_stops')
    TriggerClientEvent('ethor_bus:client:InitStopTargets', source, stops)
end)

-- Because some players might already be online, also provide a command to force sync for dev/testing
RegisterCommand('bussync', function(source)
    local stops = MySQL.query.await('SELECT id, name, coords, base_demand, queue_coords FROM bus_stops')
    TriggerClientEvent('ethor_bus:client:InitStopTargets', source, stops)
end, true)

-- Send Dummy Data for the Passenger Departure Board for now
RegisterNetEvent('ethor_bus:server:RequestStopBoard', function(stopId, stopName)
    local src = source
    local timeStr = os.date("%H:%M")
    
    -- In Phase 2, this will actively pull from bus_active_trips
    local mockBuses = {
        { line = "54", destination = "Paleto Bay", color = "#e74c3c", isFull = false, eta = 3, delay = 0 },
        { line = "12", destination = "Legion Square", color = "#3b82f6", isFull = true, eta = 12, delay = 2 },
    }

    TriggerClientEvent('ethor_bus:client:OpenStopBoard', src, {
        stopName = stopName,
        time = timeStr,
        buses = mockBuses
    })
end)
