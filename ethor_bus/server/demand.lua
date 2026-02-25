-- =============================================
-- Hybrid Demand System (Phase 1)
-- =============================================

local stopDemandBuffer = {}

-- Function to calculate demand based on time and profile
local function calculateDemand(stopData)
    local base = stopData.base_demand or 5
    local profileName = stopData.rush_profile or 'default'
    local profile = Config.Demand.Profiles[profileName] or Config.Demand.Profiles['default']
    
    local mult = profile.multiplier or 1.0
    
    -- Time check for rush hour
    local hour = tonumber(os.date("%H"))
    if profile.timeStart and profile.timeEnd then
        if hour >= profile.timeStart and hour <= profile.timeEnd then
            mult = profile.multiplier
        else
            mult = 1.0 -- Outside rush
        end
    end

    -- Add some randomness
    local rand = math.random(80, 120) / 100.0
    local finalDemand = math.floor(base * mult * rand)

    -- Cap it
    local spawnCap = stopData.spawn_cap or 15
    if finalDemand > spawnCap then finalDemand = spawnCap end

    return finalDemand
end

RegisterNetEvent('ethor_bus:server:RequestStopDemand', function(stopId)
    local src = source

    -- Check if we have a valid buffered demand for this stop-slot
    local currentTime = os.time()
    
    if not stopDemandBuffer[stopId] or (currentTime - stopDemandBuffer[stopId].lastEval) > (Config.Demand.EvaluationTick / 1000) then
        -- Fetch stop data
        local stopData = MySQL.query.await('SELECT base_demand, rush_profile, spawn_cap FROM bus_stops WHERE id = ?', {stopId})
        if stopData and stopData[1] then
            local newDemand = calculateDemand(stopData[1])
            stopDemandBuffer[stopId] = {
                demand = newDemand,
                lastEval = currentTime
            }
        else
            stopDemandBuffer[stopId] = { demand = 0, lastEval = currentTime }
        end
    end

    TriggerClientEvent('ethor_bus:client:ReceiveStopDemand', src, stopId, stopDemandBuffer[stopId].demand)
end)

-- Boss can adjust base_demand via Admin tool, so we provide an export or event to flush the buffer
RegisterNetEvent('ethor_bus:server:FlushDemandBuffer', function(stopId)
    if stopId then
        stopDemandBuffer[stopId] = nil
    else
        stopDemandBuffer = {}
    end
end)
