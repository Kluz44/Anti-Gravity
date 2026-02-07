local activeBursts = {} -- Key: missionId

-- [[ PTFX HELPER ]]
local function StartWaterEffect(coords)
    if not HasNamedPtfxAssetLoaded("core") then
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Wait(10)
        end
    end
    
    UseParticleFxAssetNextCall("core")
    local ptfx = StartParticleFxLoopedAtCoord("ent_ray_hydrant_spray", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
    return ptfx
end

-- [[ FLOODING SYSTEM ]]
local function StartFlood(coords, missionId)
    CreateThread(function()
        local size = 0.5
        local maxSize = 6.0
        local draining = false
        local growthRate = 0.05
        local drainRate = 0.1
        
        while true do
            Wait(50)
            
            -- Check if burst is resolved (draining phase)
            -- If mission is gone from activeBursts, we drain
            if not activeBursts[missionId] then
                draining = true
            end
            
            -- Logic
            if not draining then
                if size < maxSize then size = size + growthRate end
            else
                if size > 0 then 
                    size = size - drainRate 
                else
                    break -- Fully drained
                end
            end
            
            -- Render Decal
            AddDecal(
                1030, 
                coords.x, coords.y, coords.z, 
                0.0, 0.0, -1.0, -- Direction (Down)
                0.0, 1.0, 0.0,  -- Normal?
                size, size,     -- Width/Height
                0.3, 0.4, 0.5, 0.8, -- Color (Murky Water)
                1.0, false, false, false
            )
        end
    end)
end

-- [[ EVENTS ]]
RegisterNetEvent('ag_powerwater:client:syncWaterMissions', function(id, type, coords)
    -- Check if already active
    if activeBursts[id] then return end
    
    local burst = { coords = coords, id = id, type = type }
    activeBursts[id] = burst
    
    -- Visuals
    burst.ptfx = StartWaterEffect(coords)
    StartFlood(coords, id)
    
    -- Blip
    burst.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(burst.blip, 147)
    SetBlipColour(burst.blip, 3)
    SetBlipScale(burst.blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(type == 'hydrant' and "Broken Hydrant" or "Water Main Burst")
    EndTextCommandSetBlipName(burst.blip)
    
    -- Interaction
    if Config.Target == 'ox_target' then
        burst.zoneId = exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'repair_water_'..id,
                    icon = 'fas fa-wrench',
                    label = type == 'hydrant' and 'Repair Hydrant' or 'Fix Burst Pipe',
                    onSelect = function()
                        TriggerEvent('ag_powerwater:client:repairWaterMission', id, type)
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('ag_powerwater:client:clearWaterMission', function(id)
    local burst = activeBursts[id]
    if burst then
        StopParticleFxLooped(burst.ptfx, false)
        RemoveBlip(burst.blip)
        if burst.zoneId then exports.ox_target:removeZone(burst.zoneId) end
        activeBursts[id] = nil -- Triggers Flood Draining
    end
end)

RegisterNetEvent('ag_powerwater:client:repairWaterMission', function(id, type)
    AG.Notify.Show(source, 'Tightening Valve...', 'info')
    
    local animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    local animClip = 'machinic_loop_mechandplayer'
    lib.requestAnimDict(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, animClip, 8.0, 8.0, -1, 1, 0, false, false, false)
    
    if lib.skillCheck({'easy', 'easy', 'medium', 'hard'}, {'w', 'a', 's', 'd'}) then
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Leak Repaired!', 'success')
        
        -- Restore Grid
        local zone = GetNameOfZone(GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 10.0, zone)
        
        -- Finish Mission via Dispatch
        TriggerServerEvent('ag_powerwater:server:completeMission', id)
    else
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Valve slipped! Try again.', 'error')
    end
end)

RegisterNetEvent('ag_powerwater:client:repairPipe', function()
    AG.Notify.Show(source, 'Tightening Valve...', 'info')
    
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)
    
    if lib.skillCheck({'easy', 'easy', 'medium', 'hard'}, {'w', 'a', 's', 'd'}) then
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Pipe Repaired! Water flow stabilized.', 'success')
        
        -- Restore Water Grid
        local zone = GetNameOfZone(GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 10.0, zone)
        
        -- Finish Mission (Triggers Global Stop)
        TriggerServerEvent('ag_powerwater:server:finishWaterMission')
    else
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Valve slipped! Try again.', 'error')
    end
end)

-- Debug Command
RegisterCommand('burstpipe', function()
    -- Local test only
    local p = GetEntityCoords(PlayerPedId())
    local offset = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 3.0, 0.0)
    TriggerEvent('ag_powerwater:client:startPipeBurst', offset)
end)

-- [[ HYDRANT MISSION (BROKEN HYDRANT) ]]
RegisterNetEvent('ag_powerwater:client:startHydrantMission', function(coords)
    if currentBurst then
        StopParticleFxLooped(currentBurst.ptfx, false)
        RemoveBlip(currentBurst.blip)
        if currentBurst.zoneId then exports.ox_target:removeZone(currentBurst.zoneId) end
        currentBurst = nil
    end

    currentBurst = { coords = coords }

    -- 1. Visuals
    currentBurst.ptfx = StartWaterEffect(coords) -- Reusing existing helper

    -- 2. Blip
    currentBurst.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(currentBurst.blip, 564) -- Mechanics / Wrench
    SetBlipColour(currentBurst.blip, 3)   -- Blue
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Broken Hydrant")
    EndTextCommandSetBlipName(currentBurst.blip)
    SetBlipRoute(currentBurst.blip, true)

    -- 3. Interaction
    if Config.Target == 'ox_target' then
        currentBurst.zoneId = exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = 'fix_hydrant',
                    icon = 'fas fa-wrench',
                    label = 'Repair Hydrant',
                    onSelect = function()
                        TriggerEvent('ag_powerwater:client:repairHydrant')
                    end
                }
            }
        })
    end
    AG.Notify.Show(source, 'DISPATCH: Leaking Hydrant reported!', 'primary')
end)

RegisterNetEvent('ag_powerwater:client:repairHydrant', function()
    AG.Notify.Show(source, 'Replacing Seals...', 'info')
    
    TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_KNEEL", 0, true)
    
    if lib.skillCheck({'easy', 'medium'}, {'w', 'a', 's', 'd'}) then
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Hydrant fixed!', 'success')
        
        -- Reward
        local zone = GetNameOfZone(GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 5.0, zone)
        TriggerServerEvent('ag_powerwater:server:finishWaterMission')
    else
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Failed to seal.', 'error')
    end
end)

-- [[ WATER HOUSE CALLS ]]
local currentHouseJob = nil

RegisterNetEvent('ag_powerwater:client:startWaterHouseCall', function(coords)
    if currentHouseJob then RemoveBlip(currentHouseJob.blip) end
    
    currentHouseJob = { coords = coords }
    
    currentHouseJob.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(currentHouseJob.blip, 402) -- House Maintenance
    SetBlipColour(currentHouseJob.blip, 3)   -- Blue
    SetBlipRoute(currentHouseJob.blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("House Call: Plumbing")
    EndTextCommandSetBlipName(currentHouseJob.blip)

    if Config.Target == 'ox_target' then
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'fix_plumbing',
                    icon = 'fas fa-faucet',
                    label = 'Fix Plumbing',
                    onSelect = function()
                       AG.Notify.Show(source, 'Fixing Pipes...', 'info')
                       if lib.progressCircle({
                           duration = 5000,
                           label = 'Replacing Pipes',
                           useWhileDead = false,
                           canCancel = true,
                           disable = { move = true },
                           anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } 
                       }) then
                           AG.Notify.Show(source, 'Plumbing Fixed!', 'success')
                           RemoveBlip(currentHouseJob.blip)
                           currentHouseJob = nil
                           
                           TriggerServerEvent('ag_powerwater:server:finishHouseCall') -- Reusing House Call Payout Logic
                           TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 2.0, GetNameOfZone(coords))
                       else
                           AG.Notify.Show(source, 'Cancelled', 'error')
                       end
                    end
                }
            }
        })
    end
    AG.Notify.Show(source, 'DISPATCH: Resident reports plumbing issues.', 'primary')
end)


-- [[ DAM INSPECTION MISSION ]]
local damPoints = {}
local damProgress = 0

RegisterNetEvent('ag_powerwater:client:startDamMission', function()
    -- Clear old if exists
    for _, p in pairs(damPoints) do
        if p.blip then RemoveBlip(p.blip) end
        if p.zoneId then exports.ox_target:removeZone(p.zoneId) end
    end
    damPoints = {}
    damProgress = 0

    AG.Notify.Show(source, 'DISPATCH: Critical Inspection at Land Act Dam required.', 'primary')

    for i, coords in ipairs(Config.DamValves) do
        local point = { coords = coords, id = i }
        
        -- Blip
        point.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(point.blip, 354) -- Lightning/Bolt/Gear
        SetBlipColour(point.blip, 47)  -- Orange
        SetBlipScale(point.blip, 0.7)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Dam Valve " .. i)
        EndTextCommandSetBlipName(point.blip)
        
        -- Interaction
        if Config.Target == 'ox_target' then
            point.zoneId = exports.ox_target:addSphereZone({
                coords = coords,
                radius = 1.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'inspect_dam_' .. i,
                        icon = 'fas fa-cog',
                        label = 'Inspect Valve ' .. i,
                        onSelect = function()
                            TriggerEvent('ag_powerwater:client:inspectDamValve', i)
                        end
                    }
                }
            })
        end
        
        damPoints[i] = point
    end
    
    SetNewWaypoint(Config.DamValves[1].x, Config.DamValves[1].y)
end)

RegisterNetEvent('ag_powerwater:client:inspectDamValve', function(index)
    local p = damPoints[index]
    if not p then return end
    
    AG.Notify.Show(source, 'Inspecting Mechanism...', 'info')
    
    local animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    local animClip = 'machinic_loop_mechandplayer'
    lib.requestAnimDict(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, animClip, 8.0, 8.0, -1, 1, 0, false, false, false)
    
    if lib.skillCheck({'medium', 'medium', 'hard'}, {'w', 'a', 's', 'd'}) then
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Valve Status: OPTIMAL.', 'success')
        
        -- Remove this point
        RemoveBlip(p.blip)
        if p.zoneId then exports.ox_target:removeZone(p.zoneId) end
        damPoints[index] = nil
        damProgress = damProgress + 1
        
        -- Check Completion
        if damProgress >= #Config.DamValves then
            AG.Notify.Show(source, 'Dam Inspection Complete! Grid Stabilized.', 'success')
            damPoints = {}
            damProgress = 0
            
            TriggerServerEvent('ag_powerwater:server:finishWaterMission', true) -- true = IsBigMission
            TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 15.0, 'LosSantos') -- Dam feeds LS mostly
            TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 15.0, 'CountrySide')
            
            -- Play Sound or visual confirm?
        end
    else
        ClearPedTasks(PlayerPedId())
        AG.Notify.Show(source, 'Valve stuck! Try again.', 'error')
    end
end)


-- [[ HYDRANT MAINTENANCE (PASSIVE) ]]
-- Target all hydrants
CreateThread(function()
    if Config.Target == 'ox_target' then
        exports.ox_target:addModel(Config.WaterModels, {
            {
                name = 'check_pressure',
                icon = 'fas fa-tachometer-alt',
                label = 'Check Water Pressure',
                onSelect = function(data)
                     AG.Notify.Show(source, 'Checking Pressure...', 'info')
                     if lib.progressBar({
                        duration = 3000,
                        label = 'Reading Gauge',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true },
                        anim = { dict = 'amb@prop_human_bum_bin@idle_b', clip = 'idle_d' } 
                     }) then
                        
                        AG.Notify.Show(source, 'Pressure Normal.', 'success')
                        -- Small restore for standard maintenance
                        local zone = GetNameOfZone(GetEntityCoords(data.entity))
                        TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Water', 1.0, zone)
                     else
                        AG.Notify.Show(source, 'Cancelled', 'error')
                     end
                end
            }
        })
    end
end)
