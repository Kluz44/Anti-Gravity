local currentTurbine = nil

local currentTurbine = nil

-- [[ EVENTS ]]
RegisterNetEvent('ag_powerwater:client:runStopFireCommand', function()
    -- Force stop fires in the area (called when Electrician fixes it without FD)
    ExecuteCommand('stopfire 150')
    ExecuteCommand('stopsmoke 150')
end)

RegisterNetEvent('ag_powerwater:client:startTurbineMission', function(index, isFire)
    -- Cleanup
    TriggerEvent('ag_powerwater:client:stopTurbineMission')
    
    local data = Config.Turbines[index]
    if not data then return end
    
    currentTurbine = { index = index, isFire = isFire, coords = data.base }
    
    -- 1. Visuals & Notifications
    if isFire then
        -- Fire is spawned by Server via SmartFires export
        AG.Notify.Show(source, 'DISPATCH: ALERT! Wind Turbine #' .. index .. ' Nacelle Fire!', 'error')
    else
        AG.Notify.Show(source, 'DISPATCH: Routine Maintenance required at Turbine #' .. index, 'info')
    end
    
    -- 2. Blip
    currentTurbine.blip = AddBlipForCoord(data.base.x, data.base.y, data.base.z)
    SetBlipSprite(currentTurbine.blip, isFire and 436 or 566) -- Damage vs Cog
    SetBlipColour(currentTurbine.blip, isFire and 1 or 5)     -- Red vs Yellow
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(isFire and "TURBINE FIRE" or "Turbine Maint")
    EndTextCommandSetBlipName(currentTurbine.blip)
    SetBlipRoute(currentTurbine.blip, true)
    
    -- 3. Interaction (Base Panel)
    if Config.Target == 'ox_target' then
        currentTurbine.zoneId = exports.ox_target:addBoxZone({
            coords = data.base,
            size = vector3(2, 2, 2),
            debug = Config.Debug,
            options = {
                {
                    name = 'fix_turbine',
                    icon = isFire and 'fas fa-fire-extinguisher' or 'fas fa-tools',
                    label = isFire and 'INITIATE EMERGENCY SHUTDOWN' or 'Run Diagnostics',
                    onSelect = function()
                        TriggerEvent('ag_powerwater:client:fixTurbine')
                    end
                },
                {
                    name = 'fire_override',
                    icon = 'fas fa-clipboard-check',
                    label = 'CONFIRM AREA SECURE (FD)',
                    groups = Config.FireJobs, -- Restricted to Firefighters
                    onSelect = function()
                         -- FD confirms fire is out
                         if currentTurbine and currentTurbine.isFire then
                             if lib.progressBar({
                                duration = 3000,
                                label = 'Verifying Fire Extinguished...',
                                useWhileDead = false,
                                canCancel = true,
                                disable = { move = true }
                             }) then
                                 TriggerServerEvent('ag_powerwater:server:firefighterExtinguish')
                             end
                         else
                             AG.Notify.Show(source, 'No active fire logic.', 'error')
                         end
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('ag_powerwater:client:fixTurbine', function()
    if not currentTurbine then return end
    
    local action = currentTurbine.isFire and 'Emergency Shutdown Sequence...' or 'Running Diagnostics...'
    local difficulty = currentTurbine.isFire and {'medium', 'hard', 'hard'} or {'easy', 'medium'}
    
    AG.Notify.Show(source, action, 'info')
    
    if lib.skillCheck(difficulty, {'w', 'a', 's', 'd'}) then
        -- We act locally but final decision is server side (based on FD count)
        if currentTurbine.isFire then
             -- We don't extinguish locally yet. We wait for server response.
        else
            AG.Notify.Show(source, 'Diagnostics Green. Efficiency Optimized.', 'success')
            TriggerServerEvent('ag_powerwater:server:restoreGridZone', 'Power', 5.0, 'CountrySide')
        end
        
        TriggerServerEvent('ag_powerwater:server:attemptTurbineFix', currentTurbine.isFire)
    else
        AG.Notify.Show(source, 'Sequence Failed! System Unresponsive.', 'error')
    end
end)

RegisterNetEvent('ag_powerwater:client:stopTurbineMission', function()
    if currentTurbine then
        if currentTurbine.ptfx then StopParticleFxLooped(currentTurbine.ptfx, false) end
        if currentTurbine.hydrant then DeleteEntity(currentTurbine.hydrant) end -- Cleanup Hydrant
        RemoveBlip(currentTurbine.blip)
        if currentTurbine.zoneId then exports.ox_target:removeZone(currentTurbine.zoneId) end
        currentTurbine = nil
    end
end)

-- Debug
RegisterCommand('turbinefire', function()
    TriggerEvent('ag_powerwater:client:startTurbineMission', 1, true)
end)
