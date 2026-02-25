-- =============================================
-- Rating & Feedback System
-- =============================================

function ApplyMoodModifier(tripId, amount, reason)
    if AGActiveTrips[tripId] then
        AGActiveTrips[tripId].moodScore = AGActiveTrips[tripId].moodScore + amount
        
        -- Clamp 0-100
        if AGActiveTrips[tripId].moodScore > 100 then AGActiveTrips[tripId].moodScore = 100 end
        if AGActiveTrips[tripId].moodScore < 0 then AGActiveTrips[tripId].moodScore = 0 end
        
        if Config.Debug then 
            print(('^3[ethor_bus] ^7Trip %s Mood changed by %d -> %d (%s)'):format(tripId, amount, AGActiveTrips[tripId].moodScore, reason))
        end
    end
end

-- Route Rating Deductions
RegisterNetEvent('ethor_bus:server:ReportDelay', function(tripId, minutesLate)
    -- Deduct 2% per minute late
    ApplyMoodModifier(tripId, -(minutesLate * 2), "Delay")
end)

RegisterNetEvent('ethor_bus:server:ReportSkipStop', function(tripId, missedPax)
    -- Deduct 5% per missed waiting ped
    ApplyMoodModifier(tripId, -(missedPax * 5), "Skipped Stop")
end)

-- Analytics Aggregation (Called by Boss Dispatch UI)
RegisterNetEvent('ethor_bus:server:RequestAnalytics', function(companyId)
    local src = source
    
    -- The Boss Dispatch UI requests this to show live stats.
    -- We aggregate currently active trips to calculate the active system average.
    local activeQuery = MySQL.query.await('SELECT route_id, mood_score, passengers_total FROM bus_active_trips')
    
    local totalPax = 0
    local avgMood = 0
    local count = 0
    
    for _, row in ipairs(activeQuery) do
        totalPax = totalPax + (row.passengers_total or 0)
        avgMood = avgMood + (row.mood_score or 100)
        count = count + 1
    end
    
    if count > 0 then avgMood = avgMood / count end
    
    TriggerClientEvent('ethor_bus:client:ReceiveAnalytics', src, {
        activeBuses = count,
        totalPax = totalPax,
        avgMood = avgMood
    })
end)

-- Deep Analytics: Heatmap (Phase 3)
RegisterNetEvent('ethor_bus:server:RequestHeatmap', function()
    local src = source
    
    -- Fetch stops with their demand profiles to calculate layout
    -- To calculate advanced 'hot routes', we base the heatmap on the `base_demand` config per stop
    local stopsQuery = MySQL.query.await('SELECT id, coords, base_demand FROM bus_stops')
    
    local heatmapData = {}
    for _, stop in ipairs(stopsQuery) do
        local coords = json.decode(stop.coords)
        if coords then
            -- Heat weight based on demand (0.0 to 1.0 roughly)
            local weight = math.min(1.0, (stop.base_demand or 5) / 20.0)
            table.insert(heatmapData, {
                x = coords.x,
                y = coords.y,
                weight = weight
            })
        end
    end
    
    TriggerClientEvent('ethor_bus:client:ReceiveHeatmap', src, heatmapData)
end)
