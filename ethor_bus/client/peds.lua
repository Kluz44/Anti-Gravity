-- =============================================
-- Passenger Ped System (Real Peds)
-- =============================================

local activeStops = {}
local spawnedPeds = {}
local globalPedCount = 0

local pedModels = {
    'a_m_m_business_01', 'a_m_m_tourist_01', 'a_f_m_tourist_01', 'a_f_m_business_02',
    'a_m_y_hipster_01', 'a_f_y_hipster_01'
}

local function RequestModelSync(modelStr)
    local hash = GetHashKey(modelStr)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return hash
end

local function cleanupPedsForStop(stopId)
    if spawnedPeds[stopId] then
        for _, ped in ipairs(spawnedPeds[stopId]) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
                globalPedCount = globalPedCount - 1
            end
        end
        spawnedPeds[stopId] = nil
    end
end

RegisterNetEvent('ethor_bus:client:ReceiveStopDemand', function(stopId, demand)
    if not activeStops[stopId] or not activeStops[stopId].inRange then return end
    if demand <= 0 then return end
    
    -- Avoid double spawning
    if spawnedPeds[stopId] and #spawnedPeds[stopId] > 0 then return end

    spawnedPeds[stopId] = {}
    
    local stopInfo = activeStops[stopId]
    local queuePoints = stopInfo.queue_coords or {}
    if #queuePoints == 0 then return end

    -- Limit spawn by queue points / global cap
    local spawnCount = math.min(demand, #queuePoints)
    if (globalPedCount + spawnCount) > Config.Peds.GlobalCap then
        spawnCount = Config.Peds.GlobalCap - globalPedCount
    end
    if spawnCount <= 0 then return end

    for i = 1, spawnCount do
        local q = queuePoints[i]
        local model = pedModels[math.random(#pedModels)]
        local hash = RequestModelSync(model)
        
        if hash then
            local ped = CreatePed(4, hash, q.x, q.y, q.z - 1.0, q.h or 0.0, false, false)
            SetEntityAsMissionEntity(ped, true, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            
            -- Phone or Idle Animation
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)

            table.insert(spawnedPeds[stopId], ped)
            globalPedCount = globalPedCount + 1
        end
    end
end)

-- Proximity Loop for Stops
CreateThread(function()
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        
        -- We get the list of stops from the ox_target sync or we need a local grid cache.
        -- For phase 1, we request all stops from DB on load and store them locally.
        -- Let's assume `activeStops` is populated when `InitStopTargets` is called.
        
        for stopId, stopData in pairs(activeStops) do
            local dist = #(pCoords - vec3(stopData.coords.x, stopData.coords.y, stopData.coords.z))
            
            if dist <= Config.Peds.SpawnDistance then
                if not stopData.inRange then
                    stopData.inRange = true
                    TriggerServerEvent('ethor_bus:server:RequestStopDemand', stopId)
                end
            elseif dist > Config.Peds.DespawnDistance then
                if stopData.inRange then
                    stopData.inRange = false
                    cleanupPedsForStop(stopId)
                end
            end
        end
    end
end)

-- Hook into the Target Init to build our activeStops list
local originalInitEvent = 'ethor_bus:client:InitStopTargets'
RegisterNetEvent(originalInitEvent, function(stops)
    for _, stop in ipairs(stops) do
        local coords
        if type(stop.coords) == 'string' then coords = json.decode(stop.coords) else coords = stop.coords end

        -- Fetch queue coords (We actually need queue coords here, so let's update the server event to include them)
        -- We will assume the server provides queue_coords now. Add a fix in the next tick if needed.
        local queues = stop.queue_coords
        if type(queues) == 'string' then queues = json.decode(queues) end

        activeStops[stop.id] = {
            id = stop.id,
            coords = coords,
            queue_coords = queues or {},
            inRange = false
        }
    end
end)
