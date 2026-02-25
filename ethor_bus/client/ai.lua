-- =============================================
-- Client-Side AI Materialization & Spawning
-- =============================================

local materializedBuses = {} -- Local reference of active vehicles

local function RequestModelSync(modelStr)
    local hash = GetHashKey(modelStr)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return hash
end

RegisterNetEvent('ethor_bus:client:MaterializeAI', function(busData)
    if materializedBuses[busData.id] then return end -- Already spawned

    local bModel = Config.BusModels[1]
    local bHash = RequestModelSync(bModel)
    local pHash = RequestModelSync('a_m_m_business_01') -- Standard driver
    
    if bHash and pHash then
        -- We place the bus on the closest road node to the virtual coordinate
        local targetPos = vec3(busData.coords.x, busData.coords.y, busData.coords.z)
        local found, nodeX, nodeY, nodeZ = GetClosestVehicleNode(targetPos.x, targetPos.y, targetPos.z, 0, 3.0, 0)
        
        if not found then
            nodeX, nodeY, nodeZ = targetPos.x, targetPos.y, targetPos.z
        end

        local veh = CreateVehicle(bHash, nodeX, nodeY, nodeZ, 0.0, true, false)
        local ped = CreatePedInsideVehicle(veh, 4, pHash, -1, true, false)

        SetEntityAsMissionEntity(veh, true, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetVehicleEngineOn(veh, true, true, false)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Store the network IDs so the server can track them
        local netId = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(netId, true)

        materializedBuses[busData.id] = {
            id = busData.id,
            veh = veh,
            ped = ped,
            netId = netId,
            stops = busData.stops,
            state = "IN_SERVICE_DRIVING",
            currentStopIdx = busData.currentStopIdx or 1
        }
        
        SetModelAsNoLongerNeeded(bHash)
        SetModelAsNoLongerNeeded(pHash)

        if Config.Debug then print('^2[ethor_bus] ^7Materialized AI Bus: ' .. busData.id) end
    end
end)

RegisterNetEvent('ethor_bus:client:DematerializeAI', function(vId)
    if materializedBuses[vId] then
        local myBus = materializedBuses[vId]
        if DoesEntityExist(myBus.ped) then DeleteEntity(myBus.ped) end
        if DoesEntityExist(myBus.veh) then DeleteEntity(myBus.veh) end
        materializedBuses[vId] = nil
        if Config.Debug then print('^1[ethor_bus] ^7Dematerialized AI Bus: ' .. vId) end
    end
end)

-- Emergency Vehicle Checking Logic
local function checkEmergencyVehicleBehind(busVeh)
    if not Config.AI.EnableEmergencyReaction then return false end
    
    local busPos = GetEntityCoords(busVeh)
    local busForward = GetEntityForwardVector(busVeh)
    
    -- Check nearby vehicles
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if veh ~= busVeh and IsVehicleSirenOn(veh) then
            local class = GetVehicleClass(veh)
            local isEmergency = false
            for _, c in ipairs(Config.AI.EmergencyClasses) do
                if class == c then isEmergency = true break end
            end
            
            if isEmergency then
                local ePos = GetEntityCoords(veh)
                local dist = #(busPos - ePos)
                if dist < Config.AI.EmergencySirenDistance then
                    -- Check if it's roughly behind the bus using dot product
                    local dirToEmergency = (ePos - busPos)
                    local dot = (busForward.x * dirToEmergency.x) + (busForward.y * dirToEmergency.y) + (busForward.z * dirToEmergency.z)
                    
                    if dot < 0 then -- It is behind
                        return true, veh
                    end
                end
            end
        end
    end
    return false, nil
end

-- Main Driving Logic Loop for Host
CreateThread(function()
    while true do
        Wait(Config.AI.CheckInterval or 1000)
        
        for vId, myBus in pairs(materializedBuses) do
            if DoesEntityExist(myBus.veh) and DoesEntityExist(myBus.ped) then
                local vehCoords = GetEntityCoords(myBus.veh)
                local fwd = GetEntityForwardVector(myBus.veh)
                local right = vector3(fwd.y, -fwd.x, 0.0) -- Simple 2D right vector
                
                -- EMERGENCY REACTION CHECK
                local isEmergencyBehind, emVeh = checkEmergencyVehicleBehind(myBus.veh)
                
                if isEmergencyBehind and myBus.state == "IN_SERVICE_DRIVING" then
                    myBus.state = "PULLING_OVER"
                    SetVehicleIndicatorLights(myBus.veh, 1, true) -- Right blinker
                    
                    -- Calculate a safe right-hand offset
                    local pullOverPos = vehCoords + (right * 4.0) + (fwd * 10.0)
                    local found, pnX, pnY, pnZ = GetClosestVehicleNode(pullOverPos.x, pullOverPos.y, pullOverPos.z, 0, 3.0, 0)
                    if not found then pnX, pnY, pnZ = pullOverPos.x, pullOverPos.y, vehCoords.z end
                    
                    TaskVehicleDriveToCoord(myBus.ped, myBus.veh, pnX, pnY, pnZ, 5.0, 0, GetEntityModel(myBus.veh), 786603, 1.0, true)
                    
                    if Config.Debug then print('^1[ethor_bus] ^7AI Bus ' .. vId .. ' Pulling Over for Emergency!') end
                
                elseif myBus.state == "PULLING_OVER" then
                    -- Check if we stopped (speed approaches 0)
                    if GetEntitySpeed(myBus.veh) < 0.5 then
                        myBus.state = "PULLED_OVER_WAITING"
                        ClearPedTasks(myBus.ped)
                        SetVehicleHandbrake(myBus.veh, true)
                    end
                
                elseif myBus.state == "PULLED_OVER_WAITING" then
                    -- Check if emergency passed
                    if not isEmergencyBehind then
                        myBus.state = "MERGING_BACK"
                        SetVehicleHandbrake(myBus.veh, false)
                        SetVehicleIndicatorLights(myBus.veh, 1, false)
                        SetVehicleIndicatorLights(myBus.veh, 0, true) -- Left blinker to merge
                        Wait(1500)
                        SetVehicleIndicatorLights(myBus.veh, 0, false)
                        myBus.state = "IN_SERVICE_DRIVING"
                        if Config.Debug then print('^2[ethor_bus] ^7AI Bus ' .. vId .. ' Merging back into traffic.') end
                    end
                
                elseif myBus.state == "IN_SERVICE_DRIVING" then
                    local targetStop = myBus.stops[myBus.currentStopIdx]
                    if targetStop then
                        local tCoords = vec3(targetStop.coords.x, targetStop.coords.y, targetStop.coords.z)
                        local dist = #(vehCoords - tCoords)
                        
                        if dist < 10.0 then
                            -- Reached Stop
                            myBus.state = "WAITING"
                            SetVehicleIndicatorLights(myBus.veh, 1, true) -- Right indicator
                            TaskVehicleDriveToCoord(myBus.ped, myBus.veh, tCoords.x, tCoords.y, tCoords.z, 2.0, 0, GetEntityModel(myBus.veh), 786603, 1.0, true)
                            
                            -- Tell server we are waiting
                            TriggerServerEvent('ethor_bus:server:SyncMaterializedState', vId, myBus.netId, myBus.state, myBus.currentStopIdx, {x=vehCoords.x, y=vehCoords.y, z=vehCoords.z})
                            
                            -- Simple wait coroutine for stop
                            Citizen.SetTimeout(Config.AI.WaitAtStop, function()
                                if materializedBuses[vId] then -- Ensure it wasn't dematerialized
                                    SetVehicleIndicatorLights(myBus.veh, 1, false)
                                    SetVehicleIndicatorLights(myBus.veh, 0, true) -- Left indicator out
                                    Wait(2000)
                                    SetVehicleIndicatorLights(myBus.veh, 0, false)
                                    
                                    myBus.currentStopIdx = myBus.currentStopIdx + 1
                                    if myBus.currentStopIdx > #myBus.stops then myBus.currentStopIdx = 1 end
                                    myBus.state = "IN_SERVICE_DRIVING"
                                end
                            end)
                        else
                            -- Keep Driving
                            TaskVehicleDriveToCoord(myBus.ped, myBus.veh, tCoords.x, tCoords.y, tCoords.z, Config.AI.Speed, 0, GetEntityModel(myBus.veh), 786603, 1.0, true)
                        end
                        
                        -- Update server periodically on position
                        TriggerServerEvent('ethor_bus:server:SyncMaterializedState', vId, myBus.netId, myBus.state, myBus.currentStopIdx, {x=vehCoords.x, y=vehCoords.y, z=vehCoords.z})
                    end
                end
            else
                -- Entity despawned externally
                materializedBuses[vId] = nil
            end
        end
    end
end)
