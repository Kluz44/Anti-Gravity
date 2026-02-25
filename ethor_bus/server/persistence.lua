-- =============================================
-- Active Trips Persistence Snapshot (Phase 1)
-- =============================================

-- Global table to hold active trips
AGActiveTrips = {}

-- Snapshot Loop
CreateThread(function()
    while true do
        Wait(Config.Persistence.SnapshotInterval)
        
        local activeCount = 0
        for id, trip in pairs(AGActiveTrips) do
            -- Batch save to DB
            MySQL.update([[
                INSERT INTO bus_active_trips 
                (id, route_id, bus_netid, bus_plate, driver_type, driver_identifier, current_stop_index, mood_score, passengers_total, last_update) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON DUPLICATE KEY UPDATE 
                current_stop_index = VALUES(current_stop_index), mood_score = VALUES(mood_score), 
                passengers_total = VALUES(passengers_total), last_update = CURRENT_TIMESTAMP
            ]], {
                id,
                trip.routeId,
                trip.busNetId,
                trip.busPlate,
                trip.driverType,
                trip.driverIdentifier,
                trip.currentStopIndex,
                trip.moodScore,
                trip.passengersTotal
            })
            activeCount = activeCount + 1
        end

        if Config.Debug and activeCount > 0 then
            print('^3[ethor_bus] ^7[Persistence] Snapshotted ' .. activeCount .. ' active trips to database.')
        end
    end
end)

-- Recover Logic on Script Start
CreateThread(function()
    Wait(2000) -- give DB time

    local rows = MySQL.query.await('SELECT * FROM bus_active_trips WHERE last_update > DATE_SUB(NOW(), INTERVAL 30 MINUTE)')
    if rows and #rows > 0 then
        for _, trip in ipairs(rows) do
            AGActiveTrips[trip.id] = {
                routeId = trip.route_id,
                busNetId = trip.bus_netid,
                busPlate = trip.bus_plate,
                driverType = trip.driver_type,
                driverIdentifier = trip.driver_identifier,
                currentStopIndex = trip.current_stop_index,
                moodScore = trip.mood_score,
                passengersTotal = trip.passengers_total
            }
        end
        print('^2[ethor_bus] ^7[Persistence] Recovered ' .. #rows .. ' trips from previous session.')
    end
end)

-- Clean old trips
CreateThread(function()
    while true do
        Wait(600000) -- Every 10 min
        MySQL.query('DELETE FROM bus_active_trips WHERE last_update < DATE_SUB(NOW(), INTERVAL 2 HOUR)')
    end
end)
