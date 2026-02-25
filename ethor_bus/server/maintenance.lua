-- =============================================
-- Maintenance / Workshop (Phase 3)
-- =============================================

Config.Maintenance = {
    DegradePerStop = 2, -- % health lost per stop
    ServiceThreshold = 20, -- Drops below this? Needs service
}

-- Method called when a bus arrives at a stop (from main or demand scripts)
function ApplyBusDegradation(tripId)
    if not AGActiveTrips[tripId] then return end
    
    local trip = AGActiveTrips[tripId]
    trip.busHealth = (trip.busHealth or 100) - Config.Maintenance.DegradePerStop
    
    if trip.busHealth <= 0 then trip.busHealth = 0 end
    
    -- Check Service Mode
    if trip.busHealth <= Config.Maintenance.ServiceThreshold then
        trip.inServiceMode = true
        
        -- Notify Driver
        if trip.driverType == 'human' and trip.driverSource then
            AG.Notify.Show(trip.driverSource, 'Dein Bus ist in einem schlechten Zustand und muss in die Werkstatt (Service Mode aktiv).', 'error')
            
            TriggerClientEvent('ethor_bus:client:ForceServiceMode', trip.driverSource)
        end
        if Config.Debug then print('^1[ethor_bus] ^7Trip '..tripId..' is now in Service Mode due to degradation.') end
    end
end

-- Export for Mechanics
exports('RepairBus', function(netId, amount)
    local repairAmount = amount or 100
    local repaired = false
    
    for tripId, trip in pairs(AGActiveTrips) do
        if trip.busNetId == netId then
            trip.busHealth = math.min(100, (trip.busHealth or 0) + repairAmount)
            if trip.busHealth > Config.Maintenance.ServiceThreshold then
                trip.inServiceMode = false -- Reset
                if trip.driverSource then
                    AG.Notify.Show(trip.driverSource, 'Bus repariert. Service Mode deaktiviert.', 'success')
                end
            end
            repaired = true
            break
        end
    end
    return repaired
end)

-- Allow Boss/Admin to manually toggle Service Mode
RegisterNetEvent('ethor_bus:server:ToggleServiceMode', function(tripId)
    local src = source
    if AGActiveTrips[tripId] then
        AGActiveTrips[tripId].inServiceMode = not AGActiveTrips[tripId].inServiceMode
        AG.Notify.Show(src, 'Service Mode für Trip '..tripId..': ' .. tostring(AGActiveTrips[tripId].inServiceMode), 'info')
    end
end)
