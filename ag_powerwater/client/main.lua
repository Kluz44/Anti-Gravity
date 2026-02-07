-- Client Logic Entry Point
local isUiOpen = false

-- Command to open the UI
-- [[ DISPATCH SYSTEM ]]
local activeMissions = {}
local processedMissions = {} -- IDs we have already set up visuals for

RegisterNetEvent('ag_powerwater:client:syncDispatch', function(missions)
    activeMissions = missions
    
    -- 1. Check for New Missions
    for id, mission in pairs(activeMissions) do
        if not processedMissions[id] and mission.status ~= 'completed' then
            -- START VISUALS
            if mission.subType == 'pipe_burst' or mission.subType == 'hydrant' then
                TriggerEvent('ag_powerwater:client:syncWaterMissions', id, mission.subType, mission.coords)
            elseif mission.subType == 'turbine_fire' then
                -- Trubines are handled by existing logic usually, but let's ensure visuals
                -- TriggerEvent('ag_powerwater:client:startTurbineMission', mission.data.index, true)
            elseif mission.subType == 'house_call' then
                TriggerEvent('ag_powerwater:client:startHouseCall', mission.coords, id)
            end
            processedMissions[id] = true
        end
    end
    
    -- 2. Check for Removed/Completed Missions
    for id, _ in pairs(processedMissions) do
        if not activeMissions[id] or activeMissions[id].status == 'completed' then
            -- STOP VISUALS
            TriggerEvent('ag_powerwater:client:clearWaterMission', id)
            TriggerEvent('ag_powerwater:client:clearHouseCall', id)
            -- Turbine/Transformer handled by specific events usually, but good to have generic clear
            
            processedMissions[id] = nil
        end
    end
    
    if isUiOpen then
        SendNUIMessage({
            action = 'updateMissions',
            data = activeMissions
        })
    end
end)

RegisterNetEvent('ag_powerwater:client:updateGrid', function(data)
    gridData = data
    
    -- Calculate Averages
    local totalPower, totalWater, zoneCount = 0, 0, 0
    for _, zone in pairs(gridData) do
        totalPower = totalPower + (zone.Power or 100)
        totalWater = totalWater + (zone.Water or 100)
        zoneCount = zoneCount + 1
    end
    
    local avgPower = zoneCount > 0 and math.floor(totalPower / zoneCount) or 100
    local avgWater = zoneCount > 0 and math.floor(totalWater / zoneCount) or 100
    
    if isUiOpen then
        SendNUIMessage({
            action = 'openDispatch', -- Or a specific updateStats action if supported, but openDispatch updates everything
            data = {
                stats = { power = avgPower, water = avgWater }
            }
        })
    end
end)

RegisterCommand('gridtablet', function()
    TriggerServerEvent('ag_powerwater:server:requestDispatchData')
    AG.Notify.Show(source, 'Opening...', 'info')
end)

RegisterNetEvent('ag_powerwater:client:openTablet', function()
    TriggerServerEvent('ag_powerwater:server:requestDispatchData')
    AG.Notify.Show(source, 'Opening...', 'info')
end)

-- Tablet Animation Variables
local tabletObject = nil
local tabletDict = 'amb@world_human_seat_wall_tablet@female@base'
local tabletAnim = 'base'
local tabletProp = 'prop_cs_tablet'
local tabletBone = 60309
local tabletOffset = vector3(0.03, 0.002, -0.0)
local tabletRot = vector3(10.0, 160.0, 0.0)

local function StopTabletAnimation()
    if tabletObject then
        DeleteEntity(tabletObject)
        tabletObject = nil
    end
    ClearPedTasks(PlayerPedId())
end

local function StartTabletAnimation()
    local ped = PlayerPedId()
    
    -- Load Animation
    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do Wait(10) end
    
    -- Load Prop
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do Wait(10) end
    
    -- Play Animation
    TaskPlayAnim(ped, tabletDict, tabletAnim, 8.0, -8.0, -1, 50, 0, false, false, false)
    
    -- Attach Prop
    tabletObject = CreateObject(tabletProp, 0, 0, 0, true, true, false)
    AttachEntityToEntity(tabletObject, ped, GetPedBoneIndex(ped, tabletBone), 
        tabletOffset.x, tabletOffset.y, tabletOffset.z, 
        tabletRot.x, tabletRot.y, tabletRot.z, 
        true, true, false, true, 1, true)
end

RegisterNetEvent('ag_powerwater:client:receiveDispatchData', function(missions, techs)
    local hour = GetClockHours()
    local isDay = (hour >= 6 and hour < 21) -- Client Side Time check

    -- Calculate Grid Averages
    local totalPower, totalWater, zoneCount = 0, 0, 0
    if gridData then
        for _, zone in pairs(gridData) do
            totalPower = totalPower + (zone.Power or 100)
            totalWater = totalWater + (zone.Water or 100)
            zoneCount = zoneCount + 1
        end
    end
    
    local avgPower = zoneCount > 0 and math.floor(totalPower / zoneCount) or 100
    local avgWater = zoneCount > 0 and math.floor(totalWater / zoneCount) or 100

    activeMissions = missions
    SetNuiFocus(true, true)
    
    -- TRIGGER ANIMATION
    StartTabletAnimation()

    print('[AG-Debug] Opening Tablet UI via NUI Message...') -- DEBUG
    SendNUIMessage({
        action = 'openDispatch',
        data = {
            missions = activeMissions,
            techs = techs,
            isDay = isDay,
            mySource = GetPlayerServerId(PlayerId()),
            grid = gridData, -- Send full grid
            stats = { power = avgPower, water = avgWater }
        }
    })
    isUiOpen = true
end)

-- Helper function for counting table keys
function table_count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

RegisterNUICallback('claimMission', function(data, cb)
    TriggerServerEvent('ag_powerwater:server:claimMission', data.id)
    if data.x and data.y then SetNewWaypoint(data.x, data.y) end
    cb('ok')
end)

RegisterNetEvent('ag_powerwater:client:activeTechsUpdate', function(techs)
    if isUiOpen then
        SendNUIMessage({
            action = 'openDispatch', 
            data = { techs = techs }
        })
    end
end)

RegisterNUICallback('setStatus', function(data, cb)
    local status = data.status
    TriggerServerEvent('ag_powerwater:server:setStatus', status)
    cb('ok')
end)

-- Close UI Callback
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    isUiOpen = false
    StopTabletAnimation() -- STOP ANIMATIONS
    cb('ok')
end)

-- CRITICAL: Force UI closed on resource start
CreateThread(function()
    Wait(2000)
    print('[AG-PowerWater] Force closing UI on startup')
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    isUiOpen = false
end)

-- Example Action Callback
RegisterNUICallback('action', function(data, cb)
    print('UI Action Triggered:', data.type)
    TriggerServerEvent('ag_powerwater:server:exampleEvent', data)
    cb('ok')
end)

-- Power & Water: Debug Visualization
local showDebug = false
local gridData = {} -- Stores all zones

RegisterNetEvent('ag_powerwater:client:toggleDebug', function(data)
    showDebug = not showDebug
    gridData = data
    AG.Notify.Show(source, 'Grid Debug: ' .. (showDebug and 'ON' or 'OFF'), 'primary')
end)

-- Helper to find zone at specific coords
local function GetGridZoneAtCoords(coords)
    local myZone = GetNameOfZone(coords) -- e.g. 'AIRP'
    
    for key, data in pairs(Config.ZoneDefinitions) do
        for _, z in ipairs(data.zones) do
            if z == myZone then return key, data.label end
        end
    end
    return 'Unknown', 'Unknown Area'
end

-- Export for External Scripts (rcore_fuel, etc.)
-- Usage: if not exports['ag_powerwater']:IsGridActive(GetEntityCoords(entity), true) then return false end
exports('IsGridActive', function(coords, notify)
    if not coords then return true end
    local zoneKey, _ = GetGridZoneAtCoords(coords)
    local stats = gridData[zoneKey]
    
    -- If zone exists and power is below limit -> Inactive
    if stats and stats.Power < (Config.Grid and Config.Grid.BlackoutLimit or 20) then
        if notify then
            AG.Notify.Show(source, 'Stromausfall! Zapfsäule tot.', 'error')
        end
        return false
    end
    return true
end)

-- Helper to find current logical zone for player
local function GetCurrentZoneKey()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return GetGridZoneAtCoords(coords)
end

-- Efficient Debug Loop
CreateThread(function()
    local sleep = 1000
    local currentStats = { label = 'Loading...', power = 0, water = 0 }

    while true do
        if showDebug then
            sleep = 0 -- Render Frame
            
            -- Update Stats occasionally (every 60 frames approx to save perf)
            -- Or just do it every frame, GetNameOfZone is fast enough.
            if GetGameTimer() % 500 < 20 then
                local zoneKey, zoneLabel = GetCurrentZoneKey()
                local stats = gridData[zoneKey] or { Power = 0, Water = 0 }
                currentStats.label = zoneLabel
                currentStats.key = zoneKey
                currentStats.power = stats.Power
                currentStats.water = stats.Water
            end

            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName("~y~[AG Grid Debug]~w~\nZone: " .. currentStats.label .. "\nPower: " .. currentStats.power .. "%\nWater: " .. currentStats.water .. "%")
            EndTextCommandDisplayText(0.5, 0.05)
        else
            sleep = 1000 -- Hibernate
        end
        Wait(sleep)
    end
end)

-- Global Grid Update Listener
RegisterNetEvent('ag_powerwater:client:updateGrid', function(data)
    gridData = data
    
    -- Calculate Averages
    local totalPower, totalWater, zoneCount = 0, 0, 0
    for _, zone in pairs(gridData) do
        totalPower = totalPower + (zone.Power or 100)
        totalWater = totalWater + (zone.Water or 100)
        zoneCount = zoneCount + 1
    end
    
    local avgPower = zoneCount > 0 and math.floor(totalPower / zoneCount) or 100
    local avgWater = zoneCount > 0 and math.floor(totalWater / zoneCount) or 100
    
    if isUiOpen then
        SendNUIMessage({
            action = 'openDispatch', 
            data = { 
                stats = { power = avgPower, water = avgWater },
                grid = gridData 
            }
        })
    end
end)

-- [[ VISUAL BLACKOUT HANDLER ]]
-- Manages local blackout state based on the zone you are standing in.
CreateThread(function()
    local lastBlackoutState = false
    
    while true do
        Wait(1000) -- Check every second
        
        local zoneKey, _ = GetCurrentZoneKey()
        local stats = gridData[zoneKey]
        local shouldBlackout = false

        -- Check Local Zone Failure
        if stats and stats.Power < Config.Grid.BlackoutLimit then
            shouldBlackout = true
        end
        
        -- Apply Visual State
        -- Note: SetArtificialLightsState(true) turns lights OFF (Blackout).
        -- We only force it if our grid demands it. 
        -- If global weather script says blackout, it usually sets this to true anyway.
        if shouldBlackout and not lastBlackoutState then
            SetArtificialLightsState(true)
            lastBlackoutState = true
        elseif not shouldBlackout and lastBlackoutState then
            SetArtificialLightsState(false)
            lastBlackoutState = false
        end
        
        -- Enforce state loop (to prevent weather scripts from overriding instantly)
        if lastBlackoutState then
            SetArtificialLightsState(true)
        end
    end
end)
