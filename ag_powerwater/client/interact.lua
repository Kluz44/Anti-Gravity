local function IsInUtilityVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false end
    -- Check for specific utility vehicles (add more models to config later)
    local model = GetEntityModel(veh)
    return model == GetHashKey('utility') or model == GetHashKey('utillitruck')
end

local function IsNearTop(entity)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local eCoords = GetEntityCoords(entity)
    -- Check if player is elevated (ladder/bucket)
    return pCoords.z > eCoords.z - 2.0 
end

-- [[ HELPER: PLAYER JOB ]]
local function GetPlayerJob()
    if AG.Framework == 'esx' then
        return ESX.GetPlayerData().job.name
    elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
        local p = QBCore.Functions.GetPlayerData()
        return p.job.name
    end
    return "none"
end

local function IsFireJob()
    local myJob = GetPlayerJob()
    for _, job in ipairs(Config.FireJobs or {}) do
        if job == myJob then return true end
    end
    return false
end

-- [[ TRANSFORMER FIRES ]]
local activeTransformerFires = {}

local function GetCoordKey(coords)
    return math.floor(coords.x) .. "_" .. math.floor(coords.y)
end

RegisterNetEvent('ag_powerwater:client:syncTransformerFires', function(data)
    activeTransformerFires = data
end)

TriggerServerEvent('ag_powerwater:server:requestFireSync')

local function IsTransformerBurning(entity)
    local coords = GetEntityCoords(entity)
    local key = GetCoordKey(coords)
    return activeTransformerFires[key] ~= nil
end

-- [[ TOOL HELPER ]]
local function GetToolRequirement(toolKey)
    if not Config.RequireTools or not Config.Items then return nil end
    return Config.Items[toolKey]
end

-- Setup Target for Traffic Lights
CreateThread(function()
    local models = { 
        'prop_traffic_01a', 'prop_traffic_01b', 'prop_traffic_01d', 
        'prop_traffic_lightset_01', 'prop_traffic_02a' 
    } 

    if Config.Target == 'ox_target' then
        exports.ox_target:addModel(models, {
            {
                name = 'repair_traffic',
                icon = 'fas fa-tools',
                label = 'Repair Traffic Light',
                items = GetToolRequirement('Toolbox'),
                onSelect = function(data)
                    TriggerEvent('ag_powerwater:client:repairTraffic', data.entity)
                end
            },
            {
                name = 'inspect_transformer',
                icon = 'fas fa-search',
                label = 'Inspect Transformer',
                items = GetToolRequirement('Multimeter'),
                onSelect = function(data)
                    TriggerEvent('ag_powerwater:client:inspectTransformer', data.entity)
                end
            }
        })
    end

    -- Setup Transformer Target
    local bigTransformers = { 'prop_high_voltage_01', 'prop_transformer_01', 'prop_substation_transformer_01' }
    local smallBoxes = { 'prop_elecbox_01a', 'prop_elecbox_02a', 'prop_elecbox_03a', 'prop_elecbox_04a', 'prop_elecbox_05a', 'prop_feed_box_01' }
    
    local allElectricModels = {}
    for _, m in ipairs(bigTransformers) do table.insert(allElectricModels, m) end
    for _, m in ipairs(smallBoxes) do table.insert(allElectricModels, m) end

    if Config.Target == 'ox_target' then
        exports.ox_target:addModel(allElectricModels, {
            {
                name = 'inspect_electric',
                icon = 'fas fa-bolt',
                label = 'Inspect Grid Component',
                items = GetToolRequirement('Multimeter'),
                canInteract = function(entity)
                    return not IsTransformerBurning(entity)
                end,
                onSelect = function(data)
                    TriggerEvent('ag_powerwater:client:inspectElectric', data.entity)
                end
            },
            {
                name = 'repair_electric_fire',
                icon = 'fas fa-fire-extinguisher',
                label = 'EMERGENCY SHUTDOWN',
                canInteract = function(entity)
                    return IsTransformerBurning(entity)
                end,
                onSelect = function(data)
                    TriggerEvent('ag_powerwater:client:fixTransformerFire', data.entity)
                end
            },
            {
                name = 'fd_electric_secure',
                icon = 'fas fa-clipboard-check',
                label = 'CONFIRM AREA SECURE (FD)',
                canInteract = function(entity)
                    return IsTransformerBurning(entity) and IsFireJob()
                end,
                onSelect = function(data)
                    TriggerEvent('ag_powerwater:client:fdConfirmTransformer', data.entity)
                end
            }
        })
    end
end)

-- ... (Existing Events) ...

-- [[ TURBINE MAINTENANCE ]]
CreateThread(function()
    if Config.Target == 'ox_target' and Config.Turbines then
        for i, turbine in ipairs(Config.Turbines) do
            exports.ox_target:addSphereZone({
                coords = turbine.base,
                radius = 2.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'inspect_turbine_'..i,
                        icon = 'fas fa-server',
                        label = 'Run Turbine Diagnostics',
                        items = GetToolRequirement('Multimeter'), -- Or Tablet? Using Multimeter for consistency
                        onSelect = function()
                            TriggerEvent('ag_powerwater:client:inspectTurbine', turbine.base)
                        end
                    }
                }
            })
        end
    end
end)

-- ... (Existing Turbine Logic) ...

-- [[ DAM VALVE INTERACTIONS ]]
CreateThread(function()
    if Config.Target == 'ox_target' and Config.DamValves then
        for i, valveCoords in ipairs(Config.DamValves) do
            exports.ox_target:addSphereZone({
                coords = valveCoords,
                radius = 1.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'turn_valve_'..i,
                        icon = 'fas fa-sync',
                        label = 'Turn Pressure Valve',
                        items = GetToolRequirement('Wrench'),
                        onSelect = function()
                            TriggerEvent('ag_powerwater:client:turnDamValve', i)
                        end
                    }
                }
            })
        end
    end
end)

-- ... (Existing Dam Logic) ...


-- Transformer/Box Inspection Logic
RegisterNetEvent('ag_powerwater:client:inspectElectric', function(entity)
    local model = GetEntityModel(entity)
    -- Determine Type
    local isBig = false
    local bigModels = { 
        [GetHashKey('prop_high_voltage_01')] = true, 
        [GetHashKey('prop_transformer_01')] = true, 
        [GetHashKey('prop_substation_transformer_01')] = true 
    }
    if bigModels[model] then isBig = true end

    AG.Notify.Show(source, 'Inspecting Component...', 'info')
    
    if lib.progressBar({
        duration = 5000,
        label = isBig and 'Analyzing High Voltage Transformer' or 'Checking Fuse Box',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true },
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
    }) then
        -- Random chance to find issue
        if math.random(1, 100) > 30 then
            AG.Notify.Show(source, 'Readings Unstable! Stabilization Required!', 'error')
            Wait(1000)
            
            -- Skill Check
            local difficulty = isBig and {'medium', 'hard'} or {'easy', 'medium'}
            local success = lib.skillCheck(difficulty, {'w', 'a', 's', 'd'})
            
            if success then
                AG.Notify.Show(source, 'Systems Stabilized.', 'success')
                TriggerServerEvent('ag_powerwater:server:restoreGrid', 'Power', isBig and 5.0 or 2.0)
                
                -- Check for Maintenance Mission Completion
                TriggerServerEvent('ag_powerwater:server:completeMaintenance', GetEntityCoords(entity), 'transformer')
            else
                -- FAILURE LOGIC
                local coords = GetEntityCoords(entity)
                
                if isBig then
                    -- BIG TRANSFORMER: Explosion + Electrical Fire
                    AG.Notify.Show(source, 'CRITICAL COOLING FAILURE!', 'error', 2000)
                    Wait(500)
                    AddExplosion(coords.x, coords.y, coords.z, 2, 0.5, true, false, 1.0)
                    TriggerServerEvent('ag_powerwater:server:electricalFailure', coords, true, 'electrical') -- isExplosion, fireType
                else
                    -- SMALL BOX: Sparks/Shock or Electro Fire
                    local severity = math.random(1, 100)
                    if severity > 50 then
                        -- Critical: Electro Fire
                        AG.Notify.Show(source, 'SHORT CIRCUIT! FIRE ALERT!', 'error')
                        TriggerServerEvent('ag_powerwater:server:electricalFailure', coords, false, 'electrical') -- No Explode, electrical
                    else
                        -- Stage 1: Sparks + Shock
                        AG.Notify.Show(source, 'ARCFOLT DETECTED! ZAP!', 'error')
                        
                        -- Spark PTFX
                        RequestNamedPtfxAsset("core")
                        while not HasNamedPtfxAssetLoaded("core") do Wait(10) end
                        UseParticleFxAssetNextCall("core")
                        StartParticleFxNonLoopedAtCoord("ent_dst_elec_fire_sparks", coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, 1.5, false, false, false)
                        
                        -- Damage Player
                        ApplyDamageToPed(PlayerPedId(), 10, false)
                        -- Ragdoll
                        SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, false, false, false)
                    end
                end
            end
        else
            AG.Notify.Show(source, 'System Nominal.', 'success')
            -- Even if nominal, if a mission asked to inspect it, we complete it?
            -- Usually maintenance implies "fix" or "verify".
            -- If nominal, we verified it.
            TriggerServerEvent('ag_powerwater:server:completeMaintenance', GetEntityCoords(entity), 'transformer')
        end
    else
        AG.Notify.Show(source, 'Inspection Cancelled', 'error')
    end
end)

-- [[ TURBINE MAINTENANCE ]]
CreateThread(function()
    if Config.Target == 'ox_target' and Config.Turbines then
        for i, turbine in ipairs(Config.Turbines) do
            exports.ox_target:addSphereZone({
                coords = turbine.base,
                radius = 2.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'inspect_turbine_'..i,
                        icon = 'fas fa-server',
                        label = 'Run Turbine Diagnostics',
                        onSelect = function()
                            TriggerEvent('ag_powerwater:client:inspectTurbine', turbine.base)
                        end
                    }
                }
            })
        end
    end
end)

RegisterNetEvent('ag_powerwater:client:inspectTurbine', function(coords)
    AG.Notify.Show(source, 'Connecting to Turbine Control...', 'info')
    if lib.progressBar({
        duration = 6000,
        label = 'Running Diagnostics Sequence',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true },
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' }
    }) then
        if lib.skillCheck({'medium', 'medium', 'hard'}, {'w', 'a', 's', 'd'}) then
            AG.Notify.Show(source, 'Diagnostics Complete. Efficiency Optimized.', 'success')
            TriggerServerEvent('ag_powerwater:server:restoreGrid', 'Power', 3.0)
            TriggerServerEvent('ag_powerwater:server:completeMaintenance', coords, 'turbine')
        else
            AG.Notify.Show(source, 'Diagnostics Failed. Connection Timeout.', 'error')
        end
    else
        AG.Notify.Show(source, 'Cancelled', 'error')
    end
end)

-- [[ DAM VALVE INTERACTIONS ]]
CreateThread(function()
    if Config.Target == 'ox_target' and Config.DamValves then
        for i, valveCoords in ipairs(Config.DamValves) do
            exports.ox_target:addSphereZone({
                coords = valveCoords,
                radius = 1.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'turn_valve_'..i,
                        icon = 'fas fa-sync',
                        label = 'Turn Pressure Valve',
                        onSelect = function()
                            TriggerEvent('ag_powerwater:client:turnDamValve', i)
                        end
                    }
                }
            })
        end
    end
end)

RegisterNetEvent('ag_powerwater:client:turnDamValve', function(index)
    AG.Notify.Show(source, 'Turning Heavy Valve...', 'info')
    if lib.progressBar({
        duration = 8000, -- Takes time
        label = 'Stabilizing Pressure',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true },
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' }
    }) then
        if lib.skillCheck({'hard', 'hard'}, {'w', 'a', 's', 'd'}) then
            TriggerServerEvent('ag_powerwater:server:turnDamValve', index)
        else
            AG.Notify.Show(source, 'Valve Stuck! Try Again.', 'error')
        end
    end
end)

-- Repair Fire Event
RegisterNetEvent('ag_powerwater:client:fixTransformerFire', function(entity)
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)
    
    if lib.skillCheck({'medium', 'hard'}, {'w', 'a', 's', 'd'}) then
         TriggerServerEvent('ag_powerwater:server:attemptTransformerFix', GetEntityCoords(entity))
         ClearPedTasks(PlayerPedId())
    else
         AG.Notify.Show(source, 'Shutdown Failed!', 'error')
         ClearPedTasks(PlayerPedId())
    end
end)

-- FD Confirm Event
RegisterNetEvent('ag_powerwater:client:fdConfirmTransformer', function(entity)
    if lib.progressBar({
        duration = 3000,
        label = 'Verifying Safety...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true },
        anim = { dict = 'amb@world_human_clipboard@male@idle_a', clip = 'idle_a' } -- Clipboard Check
    }) then
        TriggerServerEvent('ag_powerwater:server:fdConfirmTransformer', GetEntityCoords(entity))
    end
end)

-- Repair Traffic Event
RegisterNetEvent('ag_powerwater:client:repairTraffic', function(entity)
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)

    -- Minigame Trigger
    local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'w', 'a', 's', 'd'}) 
    
    ClearPedTasks(PlayerPedId())
    
    if success then
        AG.Notify.Show(source, 'Traffic Light Repaired!', 'success')
        TriggerServerEvent('ag_powerwater:server:restoreGrid', 'Power', 0.5)
    else
        AG.Notify.Show(source, 'Repair Failed', 'error')
    end
end)

-- NUI Callback from Minigame
RegisterNUICallback('wireGameCallback', function(data, cb)
    SetNuiFocus(false, false)
    if data.success then
        AG.Notify.Show(source, 'Cables Connected!', 'success')
        TriggerServerEvent('ag_powerwater:server:restoreGrid', 'Power', 1.0)
    else
        AG.Notify.Show(source, 'Connection Failed', 'error')
    end
    cb('ok')
end)

-- Street Light Cable Repair (Triggered via target or command for now)
RegisterNetEvent('ag_powerwater:client:fixCables', function()
    -- Check for Utility Vehicle or Ladder
    if not IsInUtilityVehicle() and not IsNearTop(PlayerPedId()) then
        AG.Notify.Show(source, 'You need a Bucket Truck or Ladder!', 'error')
        return
    end

    AG.Notify.Show(source, 'Connecting Cables...', 'info')
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startWireGame'
    })
end)

-- Temporary Command to test Cable Game
RegisterCommand('fixcables', function()
    TriggerEvent('ag_powerwater:client:fixCables')
end)

-- [[ HOUSE CALLS ]]
local currentJob = nil

RegisterNetEvent('ag_powerwater:client:startHouseCall', function(coords)
    if currentJob then
        RemoveBlip(currentJob.blip)
    end
    
    currentJob = { coords = coords }
    
    -- Create Blip
    currentJob.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(currentJob.blip, 354) -- Lightning Bolt
    SetBlipColour(currentJob.blip, 5)   -- Yellow
    SetBlipRoute(currentJob.blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("House Call: Power Issue")
    EndTextCommandSetBlipName(currentJob.blip)
    
    -- Create Zone or Target
    if Config.Target == 'ox_target' then
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'repair_house',
                    icon = 'fas fa-tools',
                    label = 'Repair Fuse Box',
                    onSelect = function()
                        TriggerEvent('ag_powerwater:client:repairHouse')
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('ag_powerwater:client:repairHouse', function()
    AG.Notify.Show(source, 'Checking Breakers...', 'info')
    if lib.skillCheck({'easy', 'easy', 'medium'}, {'w', 'a', 's', 'd'}) then
        AG.Notify.Show(source, 'Power Restored for Resident!', 'success')
        
        -- Cleanup
        if currentJob then
            RemoveBlip(currentJob.blip)
            currentJob = nil 
            -- Note: Target zone isn't removed in this simple implementation, 
            -- ideally we use removeZone if ID saved.
        end
        
        TriggerServerEvent('ag_powerwater:server:finishHouseCall')
        TriggerServerEvent('ag_powerwater:server:restoreGrid', 'Power', 2.0)
    else
        AG.Notify.Show(source, 'Failed to fix breaker.', 'error')
    end
end)

RegisterCommand('housecall', function()
    TriggerServerEvent('ag_powerwater:server:requestHouseCall')
end)
