-- Mission / Event Logic

-- [[ EXPLOSION & FIRE HANDLER ]]
RegisterNetEvent('ag_powerwater:server:transformerExplosion', function(coords)
    local src = source
    -- Verify distance (Anti-Cheat basic)
    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - coords) > 10.0 then return end

    -- 1. Create Explosion
    -- Type 1: VISUAL (Safe), Type 2: DAMAGING. Using Type 2 for consequences.
    TriggerClientEvent('ag_powerwater:client:explosion', -1, coords)

    -- 2. Trigger Fire based on Config
    if Config.Grid.FireSystem == 'SmartFires' then
        -- Integration for LondonStudios SmartFires
        -- Arguments: coords, radius, explosionType (optional)
        -- Adjust export name if different version is used
        local fireCreated = false
        if GetResourceState('SmartFires') == 'started' then
            -- Common export patterns:
            if exports['SmartFires']['CreateFire'] then
                exports['SmartFires']:CreateFire(coords.x, coords.y, coords.z, 25, 40) -- 25 flames, 40 radius?? (Check docs)
                fireCreated = true
                print('^2[AG-PowerWater] ^7SmartFire triggered at ' .. coords)
            end
        end
        
        if not fireCreated then
            print('^1[AG-PowerWater] ^7SmartFires designated but resource not found/export invalid.')
        end

    elseif Config.Grid.FireSystem == 'default' then
        -- Standard FiveM Fire
        TriggerClientEvent('ag_powerwater:client:startScriptFire', -1, coords)
    end
    
    -- 3. Damage Grid
    -- Massive damage because of explosion
    exports['ag_powerwater']:RestoreGrid('Power', -15.0)
end)

-- [[ HOUSE CALL ASSIGNMENT ]]
RegisterNetEvent('ag_powerwater:server:requestHouseCall', function(_targetSrc)
    local src = _targetSrc or source
    -- Cooldown check could go here
    
    local loc = Config.HouseLocations[math.random(#Config.HouseLocations)]
    TriggerClientEvent('ag_powerwater:client:startHouseCall', src, loc)
    AG.Notify.Show(src, 'New House Call Assigned! Check GPS.', 'info')
end)

-- [[ HOUSE CALL PAYMENT ]]
RegisterNetEvent('ag_powerwater:server:finishHouseCall', function()
    local src = source
    local Player = AG.GetPlayer(src)
    if not Player then return end

    if Config.HouseCallPayout then
        -- Payout to Society IF configured
        local society = Config.Society
        local amount = Config.HouseCallPrice
        
        if society and society ~= 'none' then
             print('^3[AG-PowerWater] ^7Society Payout Logic Placeholder for ' .. amount)
        end
    end
    
    -- If PayPerMission is true, give cash to player
    if Config.PayPerMission then
        if AG.Framework == 'esx' then
            Player.addMoney(Config.HouseCallPrice)
        elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
            Player.Functions.AddMoney('cash', Config.HouseCallPrice)
        end
    end
end)

-- [[ WATER MISSIONS ]]
RegisterNetEvent('ag_powerwater:server:requestWaterMission', function()
    local src = source
    local loc = Config.PipeLocations[math.random(#Config.PipeLocations)]
    TriggerClientEvent('ag_powerwater:client:startPipeBurst', -1, loc) -- Global Sync
    AG.Notify.Show(src, 'Water Main Burst Assigned! Check GPS.', 'info')
end)

RegisterNetEvent('ag_powerwater:server:finishWaterMission', function(isBigMission)
    local src = source
    -- Sync Stop Effects to all clients
    TriggerClientEvent('ag_powerwater:client:stopWaterEffects', -1)

    -- Optional: Give money reward if Config.PayPerMission is true
    if Config.PayPerMission then
        local Player = AG.GetPlayer(src)
        if Player then
             local reward = isBigMission and 1500 or 300
             if AG.Framework == 'esx' then
                Player.addMoney(reward)
            elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
                Player.Functions.AddMoney('cash', reward)
            end
        end
    end
end)

RegisterNetEvent('ag_powerwater:server:requestHydrantMission', function()
    local src = source
    if #Config.HydrantLocations > 0 then
        local loc = Config.HydrantLocations[math.random(#Config.HydrantLocations)]
        TriggerClientEvent('ag_powerwater:client:startHydrantMission', -1, loc) -- Global Sync
    else
        AG.Notify.Show(src, 'No Hydrant Locations Configured', 'error')
    end
end)

RegisterNetEvent('ag_powerwater:server:requestWaterHouseCall', function()
    local src = source
    local loc = Config.HouseLocations[math.random(#Config.HouseLocations)]
    TriggerClientEvent('ag_powerwater:client:startWaterHouseCall', src, loc) -- Private
end)

-- Legacy Dam Stub Removed

-- [[ WIND ENERGY MISSIONS ]]
local function CountFirefighters()
    local count = 0
    local players = GetPlayers()
    
    for _, src in ipairs(players) do
        local Player = AG.GetPlayer(tonumber(src))
        if Player then
            local jobName = ""
            if AG.Framework == 'esx' then
                jobName = Player.job.name
            elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
                jobName = Player.PlayerData.job.name
            end
            
            for _, job in ipairs(Config.FireJobs) do
                if job == jobName then
                    count = count + 1
                    break
                end
            end
        end
    end
    return count
end

RegisterNetEvent('ag_powerwater:server:requestTurbineMission', function()
    local src = source
    local index = math.random(#Config.Turbines)
    local isFire = math.random() > 0.7 -- 30% chance of fire
    
    -- SmartFires Integration
    if isFire then
        local data = Config.Turbines[index]
        local top = vector3(data.base.x, data.base.y, data.base.z + data.topOffset)
        
        -- Create Fire via Server Export
        pcall(function()
            exports["SmartFires"]:CreateFire(top, 15, true, false) -- isGas=true (Oil Fire)
        end)
        
        -- Create Dispatch Entry
        local mId = CreateDispatchMission('power', 'turbine_fire', data.base, 'emergency', 'Turbine #'..index..' Fire', { index = index })
        
        -- Store mission ID globally or in a way we can retrieve? 
        -- For simplicity, we assume client passes back context or similar.
        -- But for Turbine, we only have one active turbine mission per index usually.
        -- We won't store it here excessively, as the Dispatch System is the source of truth.
    end
    
    TriggerClientEvent('ag_powerwater:client:startTurbineMission', -1, index, isFire)
    AG.Notify.Show(src, 'Turbine Alert Generated. Check Dispatch.', 'info')
end)

-- Called by Electrician when doing Emergency Shutdown
RegisterNetEvent('ag_powerwater:server:attemptTurbineFix', function(isFire)
    local src = source
    local fdCount = CountFirefighters()
    
    -- Pay the Electrician
    if Config.PayPerMission then
        local Player = AG.GetPlayer(src)
        if Player then
             local reward = isFire and 1000 or 500
             if AG.Framework == 'esx' then
                Player.addMoney(reward)
            elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
                Player.Functions.AddMoney('cash', reward)
            end
        end
    end

    if isFire and fdCount > 0 then
        -- Firefighters are online -> Fire stays
        AG.Notify.Show(src, 'Shutdown Complete. Turbine halted. Fire Persists -> FD REQUIRED.', 'error')
    else
        -- No FD or Routine Maintenance -> Clean up
        if isFire then
            pcall(function()
                exports["SmartFires"]:StopFire(vector3(0,0,0), 0) 
            end)
            TriggerClientEvent('ag_powerwater:client:runStopFireCommand', -1) 
        end
        TriggerClientEvent('ag_powerwater:client:stopTurbineMission', -1)
        AG.Notify.Show(src, 'Turbine Verified. Systems Nominal.', 'success')
        
        -- Find and Complete Dispatch Mission?
        -- We need to find the open mission for this turbine.
        -- Ideally we'd loop Missions.
        -- Since we made Missions global...
        if Missions then
            for id, m in pairs(Missions) do
                if m.subType == 'turbine_fire' and m.status ~= 'completed' then
                    -- Approximate check or check data index
                    -- Just closing matches for now
                    CompleteDispatchMission(id)
                end
            end
        end
    end
end)

-- Called by Firefighters manually AFTER they extinguished the fire
RegisterNetEvent('ag_powerwater:server:firefighterExtinguish', function()
    local src = source
    TriggerClientEvent('ag_powerwater:client:stopTurbineMission', -1)
    AG.Notify.Show(src, 'Area Secure. Grid Safe.', 'success')
    
    -- Complete Dispatch
    if Missions then
        for id, m in pairs(Missions) do
            if m.subType == 'turbine_fire' and m.status ~= 'completed' then
                CompleteDispatchMission(id)
            end
        end
    end
end)

-- [[ TRANSFORMER FIRES ]]
-- Tracking active fires by coordinate key string
local activeTransformerFires = {}

local function GetCoordKey(coords)
    return math.floor(coords.x) .. "_" .. math.floor(coords.y)
end

RegisterNetEvent('ag_powerwater:server:electricalFailure', function(coords, isExplosion, fireType)
    local key = GetCoordKey(coords)
    if activeTransformerFires[key] then return end -- Already burning
    
    -- Create Dispatch Mission
    local mId = CreateDispatchMission('power', 'transformer_fire', coords, 'emergency', 'Grid Component Failure')

    activeTransformerFires[key] = { coords = coords, missionId = mId }
    
    -- Sync to all clients (for interaction availability)
    -- We map values to coords for client compatibility
    local clientData = {} 
    for k, v in pairs(activeTransformerFires) do clientData[k] = v.coords end
    TriggerClientEvent('ag_powerwater:client:syncTransformerFires', -1, clientData)
    
    -- Create SmartFire
    pcall(function()
        exports["SmartFires"]:CreateFire(coords, 8, fireType, false)
    end)
    
    -- Damage Grid
    TriggerEvent('ag_powerwater:server:restoreGrid', 'Power', isExplosion and -5.0 or -2.0)
end)

RegisterNetEvent('ag_powerwater:server:attemptTransformerFix', function(coords)
    local src = source
    local key = GetCoordKey(coords)
    local data = activeTransformerFires[key]
    if not data then return end
    
    local fdCount = CountFirefighters()
    
    if fdCount > 0 then
        AG.Notify.Show(src, 'Shutdown Complete. Fire Persists -> FD REQUIRED.', 'error')
    else
        -- No FD -> Electrician fixes it
         pcall(function()
            exports["SmartFires"]:StopFire(vector3(0,0,0), 0)
        end)
        
        -- Complete Dispatch Mission
        if data.missionId then CompleteDispatchMission(data.missionId) end
        
        activeTransformerFires[key] = nil
        
        local clientData = {} 
        for k, v in pairs(activeTransformerFires) do clientData[k] = v.coords end
        TriggerClientEvent('ag_powerwater:client:syncTransformerFires', -1, clientData)
        TriggerClientEvent('ag_powerwater:client:runStopFireCommand', -1)
        
        AG.Notify.Show(src, 'Transformer Verified. Systems Nominal.', 'success')
        TriggerEvent('ag_powerwater:server:restoreGrid', 'Power', 5.0)
    end
end)

RegisterNetEvent('ag_powerwater:server:fdConfirmTransformer', function(coords)
    local src = source
    local key = GetCoordKey(coords)
    local data = activeTransformerFires[key]
    
    if data then
        if data.missionId then CompleteDispatchMission(data.missionId) end
        activeTransformerFires[key] = nil
        
        local clientData = {} 
        for k, v in pairs(activeTransformerFires) do clientData[k] = v.coords end
        TriggerClientEvent('ag_powerwater:client:syncTransformerFires', -1, clientData)
        AG.Notify.Show(src, 'Transformer Area Secure.', 'success')
    end
end)

-- Sync on join
-- [[ ROUTINE MISSION GENERATOR ]]
local function GetRandomInterval()
    -- Convert minutes to milliseconds
    local min = Config.RoutineInterval.min * 60000
    local max = Config.RoutineInterval.max * 60000
    return math.random(min, max)
end

CreateThread(function()
    -- Initial Wait to let server startup
    Wait(10000)
    
    print('^2[AG-PowerWater] ^7Routine Mission Generator Started.')
    
    while true do
        local interval = GetRandomInterval()
        print('^3[AG-PowerWater] ^7Next Routine Mission in ' .. (interval / 60000) .. ' minutes.')
        Wait(interval)
        
        -- Check for online players? (Optional, skipping for now to ensure world feels alive)
        -- Pick Random Type
        local types = {'hydrant', 'house_call_electric', 'house_call_water', 'traffic', 'street_light'}
        
        -- Emergency Events (Lower Chance)
        if math.random() > 0.7 then table.insert(types, 'pipe_burst') end
        if math.random() > 0.8 then table.insert(types, 'transformer') end
        if math.random() > 0.8 then table.insert(types, 'turbine') end
        
        -- Maintenance Events (Medium Chance)
        if math.random() > 0.5 then table.insert(types, 'transformer_maintenance') end
        if math.random() > 0.5 then table.insert(types, 'turbine_maintenance') end
        if math.random() > 0.95 then table.insert(types, 'dam_maintenance') end -- Rare
        
        local missionType = types[math.random(#types)]
        
        if missionType == 'hydrant' and #Config.HydrantLocations > 0 then
            local loc = Config.HydrantLocations[math.random(#Config.HydrantLocations)]
            CreateDispatchMission('water', 'hydrant', loc, 'routine', 'Leaking Hydrant Reported')
            
        elseif missionType == 'house_call_electric' and #Config.HouseLocations > 0 then
            local loc = Config.HouseLocations[math.random(#Config.HouseLocations)]
            CreateDispatchMission('power', 'house_call', loc, 'routine', 'Residential Power Failure')
            
        elseif missionType == 'house_call_water' and #Config.HouseLocations > 0 then
            local loc = Config.HouseLocations[math.random(#Config.HouseLocations)]
            CreateDispatchMission('water', 'house_call', loc, 'routine', 'Customer Plumbing Issue')
            
        elseif missionType == 'traffic' and Config.TrafficLights and #Config.TrafficLights > 0 then
            local loc = Config.TrafficLights[math.random(#Config.TrafficLights)]
            CreateDispatchMission('power', 'traffic_light', loc, 'routine', 'Traffic Signal Malfunction')
            
        elseif missionType == 'street_light' and Config.StreetLights and #Config.StreetLights > 0 then
            local loc = Config.StreetLights[math.random(#Config.StreetLights)]
            CreateDispatchMission('power', 'street_light', loc, 'routine', 'Street Light Outage')
            
        elseif missionType == 'pipe_burst' and #Config.PipeLocations > 0 then
            local loc = Config.PipeLocations[math.random(#Config.PipeLocations)]
            CreateDispatchMission('water', 'pipe_burst', loc, 'emergency', 'MAJOR WATER MAIN BREAK')
            
        elseif missionType == 'transformer' and Config.MainTransformers and #Config.MainTransformers > 0 then
            local loc = Config.MainTransformers[math.random(#Config.MainTransformers)]
            TriggerEvent('ag_powerwater:server:electricalFailure', loc, true, 'electrical')
            
        elseif missionType == 'turbine' and Config.Turbines and #Config.Turbines > 0 then
            TriggerEvent('ag_powerwater:server:requestTurbineMission')

        elseif missionType == 'transformer_maintenance' and Config.MainTransformers and #Config.MainTransformers > 0 then
            local loc = Config.MainTransformers[math.random(#Config.MainTransformers)]
            CreateDispatchMission('power', 'transformer_maintenance', loc, 'routine', 'Substation Inspection Required')

        elseif missionType == 'turbine_maintenance' and Config.Turbines and #Config.Turbines > 0 then
            local index = math.random(#Config.Turbines)
            local data = Config.Turbines[index]
            CreateDispatchMission('power', 'turbine_maintenance', data.base, 'routine', 'Wind Turbine Diagnostics #'..index)

        elseif missionType == 'dam_maintenance' and Config.DamValves then
            -- Spawns rarely
            local loc = vector3(1663.0, -22.0, 173.0) -- Top of dam
            local mId = CreateDispatchMission('water', 'dam_maintenance', loc, 'emergency', 'DAM PRESSURE CRITICAL', { valvesFixed = 0, totalValves = #Config.DamValves })
        end
    end
end)

-- [[ DAM MISSION LOGIC ]]
RegisterNetEvent('ag_powerwater:server:requestDamMission', function()
    local loc = vector3(1663.0, -22.0, 173.0)
    CreateDispatchMission('water', 'dam_maintenance', loc, 'emergency', 'CRITICAL DAM INTEGRITY FAILURE', { valvesFixed = 0, totalValves = #Config.DamValves })
    TriggerClientEvent('ag_powerwater:client:notify', -1, 'EMERGENCY: LAND ACT DAM PRESSURE RISING!', 'error', 10000)
end)

RegisterNetEvent('ag_powerwater:server:turnDamValve', function(valveIndex)
    local src = source
    -- Find active Dam Mission
    local activeMissionId = nil
    
    if Missions then
        for id, m in pairs(Missions) do
            if m.subType == 'dam_maintenance' and m.status ~= 'completed' then
                activeMissionId = id
                break
            end
        end
    end
    
    if activeMissionId then
        local mission = Missions[activeMissionId]
        mission.data.valvesFixed = (mission.data.valvesFixed or 0) + 1
        
        TriggerClientEvent('ag_powerwater:client:syncDispatch', -1, Missions) -- Update UI progress if displayed
        AG.Notify.Show(src, 'Valve ' .. valveIndex .. ' Closed. Pressure Stabilizing...', 'success')
        
        if mission.data.valvesFixed >= mission.data.totalValves then
            CompleteDispatchMission(activeMissionId)
            AG.Notify.Show(-1, 'DAM INTEGRITY RESTORED. GOOD JOB.', 'success')
            exports['ag_powerwater']:RestoreGrid('Water', 15.0) -- Big Boost
        end
    else
        AG.Notify.Show(src, 'Valve Turned. (Routine Check)', 'info')
    end
end)

-- [[ MAINTENANCE COMPLETION LOGIC ]]
RegisterNetEvent('ag_powerwater:server:completeMaintenance', function(coords, type)
    local src = source
    local found = false
    
    if Missions then
        for id, m in pairs(Missions) do
            if m.status ~= 'completed' then
                -- Check matching type
                local isMatch = false
                if type == 'transformer' and m.subType == 'transformer_maintenance' then isMatch = true end
                if type == 'turbine' and m.subType == 'turbine_maintenance' then isMatch = true end
                
                if isMatch then
                    -- Check Distance (Server-side check)
                    local mCoords = vector3(m.coords.x, m.coords.y, m.coords.z)
                    local pCoords = vector3(coords.x, coords.y, coords.z)
                    if #(mCoords - pCoords) < 15.0 then
                        CompleteDispatchMission(id)
                        found = true
                        
                        -- Reward
                        if Config.PayPerMission then
                            local Player = AG.GetPlayer(src)
                            if Player then
                                local reward = 350
                                if AG.Framework == 'esx' then Player.addMoney(reward)
                                elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then Player.Functions.AddMoney('cash', reward) end
                            end
                        end
                        AG.Notify.Show(src, 'Maintenance Mission Completed +$350', 'success')
                        break
                    end
                end
            end
        end
    end
    
    if not found then
        -- Just a regular check, nominal reward
        -- Optional: Give small XP or money for proactive maintenance?
    end
end)

-- [[ DEBUG COMMANDS ]]
RegisterAdminCommand('pw_debug_miss', 'Trigger Random Mission (water/power)', function(source, args)
    local type = args[1] or 'water'
    if type == 'water' then
        TriggerEvent('ag_powerwater:server:requestWaterMission')
    elseif type == 'hydrant' then
        TriggerEvent('ag_powerwater:server:requestHydrantMission') 
    elseif type == 'turbine' then
        TriggerEvent('ag_powerwater:server:requestTurbineMission')
    elseif type == 'house' then
        TriggerEvent('ag_powerwater:server:requestHouseCall', source)
    end
    print('^2[AG-Debug] ^7Triggered mission type: ' .. type)
end)
