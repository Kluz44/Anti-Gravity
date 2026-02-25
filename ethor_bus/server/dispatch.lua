-- =============================================
-- Leitstelle / Dispatch Center (Phase 3)
-- =============================================

-- Live Tracking Broadcast
CreateThread(function()
    while true do
        Wait(3000) -- Update map every 3 seconds

        local liveBuses = {}

        -- Gather Virtual Buses that are NOT materialized
        for vId, bus in pairs(AGVirtualBuses) do
            local pushData = {
                id = bus.id,
                routeId = bus.routeId,
                coords = bus.coords,
                state = bus.state,
                isMaterialized = false
            }
            table.insert(liveBuses, pushData)
        end
        
        -- In a fully featured version we'd also gather human players doing active trips from AGActiveTrips.
        -- We will mock that logic by appending AGActiveTrips that have a valid netid.
        for tripId, trip in pairs(AGActiveTrips) do
            if trip.busNetId then
                local veh = NetworkGetEntityFromNetworkId(trip.busNetId)
                if DoesEntityExist(veh) then
                    local coords = GetEntityCoords(veh)
                    table.insert(liveBuses, {
                        id = "HUMAN_" .. tripId,
                        routeId = trip.routeId,
                        coords = {x = coords.x, y = coords.y, z = coords.z},
                        state = "DRIVING",
                        isMaterialized = true,
                        driver = trip.driverIdentifier
                    })
                end
            end
        end

        -- Send to all open Dispatch UIs (for simplicity we broadcast to everyone, in reality filter by job/open UI)
        TriggerClientEvent('ethor_bus:client:SyncLiveTracking', -1, liveBuses)
    end
end)

-- Intercom / Funk
RegisterCommand('busfunk', function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, 'command.buscreate') then return end -- Boss only
    
    local msg = table.concat(args, " ")
    if msg == "" then
        AG.Notify.Show(src, 'Nutzung: /busfunk [Nachricht]', 'error')
        return
    end
    
    -- Send to all clients. The client will check if they are currently in a driver seat to show it.
    TriggerClientEvent('ethor_bus:client:ReceiveIntercom', -1, msg)
    AG.Notify.Show(src, 'Funk an alle Fahrer gesendet!', 'success')
end, false)
