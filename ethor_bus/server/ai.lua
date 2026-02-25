-- =============================================
-- Server-Side Virtual AI Router
-- =============================================

-- Virtual AI State
AGVirtualBuses = {}
local busCounter = 0

-- For Phase 2, we simulate one AI bus on the first route we find for testing
CreateThread(function()
    Wait(5000) -- Wait for DB
    if not Config.AutoImportInitialData then return end -- Using this as a quick toggle for now
    
    local routes = MySQL.query.await('SELECT id, stops_json FROM bus_routes LIMIT 1')
    if not routes or #routes == 0 then return end
    
    local routeId = routes[1].id
    local stopsIds = json.decode(routes[1].stops_json)
    if not stopsIds or #stopsIds < 2 then return end
    
    -- Load actual coordinates for these stops
    local routeStops = {}
    for i, sid in ipairs(stopsIds) do
        local res = MySQL.query.await('SELECT coords, approach_coords FROM bus_stops WHERE id = ?', {sid})
        if res and res[1] then
            local mainCoords = json.decode(res[1].coords)
            local appCoordsStr = res[1].approach_coords
            local targetCoords = mainCoords
            if appCoordsStr and appCoordsStr ~= "null" then
                targetCoords = json.decode(appCoordsStr)
            end
            table.insert(routeStops, { id = sid, coords = targetCoords })
        end
    end
    
    if #routeStops < 2 then return end
    
    -- Create Virtual Bus
    busCounter = busCounter + 1
    local vBusId = "VAI_" .. busCounter
    
    AGVirtualBuses[vBusId] = {
        id = vBusId,
        routeId = routeId,
        stops = routeStops,
        currentStopIdx = 1,
        coords = { x = routeStops[1].coords.x, y = routeStops[1].coords.y, z = routeStops[1].coords.z },
        state = "DRIVING", -- DRIVING, WAITING
        waitTimer = 0,
        materializedBy = nil, -- Source ID of the player currently acting as the host for this bus
        netId = nil
    }
    
    if Config.Debug then print('^5[ethor_bus] ^7Created Virtual AI Bus ' .. vBusId .. ' on Route ' .. routeId) end
end)

-- Main Virtual Movement Loop
-- Math-based movement when not materialized
CreateThread(function()
    while true do
        Wait(1000) -- Math tick every second
        
        for id, bus in pairs(AGVirtualBuses) do
            if bus.materializedBy == nil then
                -- Move it virtually
                if bus.state == "DRIVING" then
                    local targetStop = bus.stops[bus.currentStopIdx]
                    local tx, ty, tz = targetStop.coords.x, targetStop.coords.y, targetStop.coords.z
                    local bx, by, bz = bus.coords.x, bus.coords.y, bus.coords.z
                    
                    local dx, dy = tx - bx, ty - by
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < 5.0 then
                        -- Reached stop
                        bus.coords.x, bus.coords.y, bus.coords.z = tx, ty, tz
                        bus.state = "WAITING"
                        bus.waitTimer = Config.AI.WaitAtStop / 1000 -- Config is ms, timer ticks are 1s
                    else
                        -- Move towards target (Straight line virtual movement for now)
                        -- Real pathfinding requires client natives. When materialized, the client handles true roads.
                        local moveRatio = Config.AI.Speed / dist
                        bus.coords.x = bx + (dx * moveRatio)
                        bus.coords.y = by + (dy * moveRatio)
                    end
                elseif bus.state == "WAITING" then
                    bus.waitTimer = bus.waitTimer - 1
                    if bus.waitTimer <= 0 then
                        bus.currentStopIdx = bus.currentStopIdx + 1
                        if bus.currentStopIdx > #bus.stops then
                            bus.currentStopIdx = 1 -- Loop route
                        end
                        bus.state = "DRIVING"
                    end
                end
            end
        end
    end
end)

-- Materialization Check Loop
CreateThread(function()
    while true do
        Wait(2000)
        
        local players = GetPlayers()
        for vId, bus in pairs(AGVirtualBuses) do
            if not bus.materializedBy then
                for _, srcStr in ipairs(players) do
                    local src = tonumber(srcStr)
                    local ped = GetPlayerPed(src)
                    if DoesEntityExist(ped) then
                        local pCoords = GetEntityCoords(ped)
                        local dist = #(pCoords - vec3(bus.coords.x, bus.coords.y, bus.coords.z))
                        
                        if dist < Config.AI.SyncDistance then
                            -- Materialize this bus!
                            bus.materializedBy = src
                            -- Ask client to spawn it and take over logic
                            TriggerClientEvent('ethor_bus:client:MaterializeAI', src, bus)
                            if Config.Debug then print('^5[ethor_bus] ^7Instructed Player '..src..' to materialize '..vId) end
                            break -- Found a host
                        end
                    end
                end
            else
                -- Check if host is still nearby / valid
                local hostPed = GetPlayerPed(bus.materializedBy)
                if not DoesEntityExist(hostPed) then
                    bus.materializedBy = nil
                    bus.netId = nil
                else
                    local pCoords = GetEntityCoords(hostPed)
                    -- If we have the netid, get the real vehicle coords instead of player coords
                    local realCoords = pCoords
                    if bus.netId then
                        local veh = NetworkGetEntityFromNetworkId(bus.netId)
                        if DoesEntityExist(veh) then
                            realCoords = GetEntityCoords(veh)
                            bus.coords = {x = realCoords.x, y = realCoords.y, z = realCoords.z}
                        end
                    end
                    
                    local dist = #(pCoords - vec3(bus.coords.x, bus.coords.y, bus.coords.z))
                    if dist > (Config.AI.SyncDistance + 50.0) then -- Buffer to despawn
                        TriggerClientEvent('ethor_bus:client:DematerializeAI', bus.materializedBy, vId)
                        bus.materializedBy = nil
                        bus.netId = nil
                        if Config.Debug then print('^5[ethor_bus] ^7Dematerialized '..vId) end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('ethor_bus:server:SyncMaterializedState', function(vId, netId, currentState, currentStopIdx, coords)
    if AGVirtualBuses[vId] then
        local bus = AGVirtualBuses[vId]
        if bus.materializedBy == source then
            bus.netId = netId
            bus.state = currentState
            bus.currentStopIdx = currentStopIdx
            if coords then
                bus.coords = coords
            end
        end
    end
end)
