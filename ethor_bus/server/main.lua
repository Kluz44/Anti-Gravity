-- =============================================
-- Server Main Logic (ethor_bus)
-- =============================================



RegisterNetEvent('ethor_bus:server:RequestDispatchData', function()
    local src = source
    local playerJob = AG.GetJob(src) -- Assuming bridge has this
    
    -- Check for specific job/boss based on Config.Society
    if IsPlayerAceAllowed(src, 'command.buscreate') or (playerJob and playerJob.name == Config.Society) then
        -- Fetch Stops
        local stops = MySQL.query.await('SELECT id, name, coords, base_demand, rush_profile FROM bus_stops')
        print('^3[DB] Loaded ' .. #stops .. ' stops from bus_stops table^7')
        
        -- Fetch Routes (Assuming checking company later, fetching all for now)
        local routes = MySQL.query.await('SELECT id, name, color, stops_json FROM bus_routes')
        
        -- Parse JSON strings
        for k, v in ipairs(stops) do
            if type(v.coords) == 'string' then v.coords = json.decode(v.coords) end
        end
        for k, v in ipairs(routes) do
            if type(v.stops_json) == 'string' then v.stops = json.decode(v.stops_json) end
        end

        local payloadString = json.encode({
            stops = stops,
            routes = routes
        })
        
        TriggerClientEvent('ethor_bus:client:OpenDispatchUI', src, payloadString)
        
        if Config.Debug then print('^4[ethor_bus] ^7Sent Dispatch Data to ' .. src) end
    else
        AG.Notify.Show(src, 'Keine Berechtigung (Job: ' .. (playerJob and playerJob.name or 'None') .. ')', 'error')
    end
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

-- Passenger Stop Board Data Request
RegisterNetEvent('ethor_bus:server:RequestStopBoard', function(stopId)
    local src = source
    
    -- Calculate real ETAs based on active/virtual buses approaching this stop
    local upcomingBuses = {}
    
    local function processBusList(busList, isVirtual)
        for id, bus in pairs(busList) do
            -- Find if this bus's route includes our stopId
            local routeData = MySQL.query.await('SELECT stops_json, color, name FROM bus_routes WHERE id = ?', {bus.routeId or bus.route_id})
            if routeData and routeData[1] then
                local stopsList = json.decode(routeData[1].stops_json)
                if stopsList then
                    local targetIndex = -1
                    for i, sid in ipairs(stopsList) do
                        if sid == stopId then
                            targetIndex = i
                            break
                        end
                    end
                    
                    if targetIndex ~= -1 then
                        local currentIndex = bus.currentStopIdx or bus.current_stop_index or 1
                        -- Only show if it's heading towards us (very simple heuristic for now)
                        if currentIndex <= targetIndex then
                            local stopsAway = targetIndex - currentIndex
                            
                            -- Approximate ETA (e.g., 2 mins per stop distance + wait times)
                            -- In a perfect world we'd trace the path nodes.
                            local etaMins = stopsAway * 2
                            if stopsAway == 0 then etaMins = 0 end -- At stop
                            
                            table.insert(upcomingBuses, {
                                line = routeData[1].name or "L?",
                                color = routeData[1].color or "#3b82f6",
                                destination = "Richtung Endstation", -- Could fetch last stop name
                                isFull = (bus.passengersTotal or 0) >= 40,
                                eta = etaMins,
                                delay = 0 -- Could calculate based on expected vs actual Time
                            })
                        end
                    end
                end
            end
        end
    end
    
    processBusList(AGActiveTrips, false)
    processBusList(AGVirtualBuses, true)
    
    -- Sort by ETA
    table.sort(upcomingBuses, function(a, b) return a.eta < b.eta end)
    
    -- Return top 5
    local topBuses = {}
    for i=1, math.min(5, #upcomingBuses) do
        table.insert(topBuses, upcomingBuses[i])
    end

    TriggerClientEvent('ethor_bus:client:ReceiveStopBoard', src, stopId, {
        buses = topBuses
    })
end)
