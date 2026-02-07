local GridState = {}

-- Initialize Zones
local function InitZones()
    -- Default Structure
    for zoneKey, data in pairs(Config.ZoneDefinitions) do
        GridState[zoneKey] = { Power = 100, Water = 100 }
    end
end

InitZones()

-- Load Grid State from DB
CreateThread(function()
    Wait(2000) -- Wait for storage to init
    local loadedData = AG.GetData("city_grid_zones")
    if loadedData then
        -- Merge loaded data with defined zones (in case config changed)
        for k, v in pairs(loadedData) do
            if GridState[k] then
                GridState[k] = v
            end
        end
        print('^2[AG-PowerWater] ^7Multi-Zone Grid Loaded.')
    else
        -- Save initial state
        AG.SetData("city_grid_zones", GridState)
    end
    
    TriggerClientEvent('ag_powerwater:client:updateGrid', -1, GridState)
end)

-- Helper to trigger blackout across various weather scripts
local function SetBlackout(state)
    if GlobalState.Blackout == state then return end -- No change
    
    GlobalState.Blackout = state
    
    -- 1. CD EasyTime
    if GetResourceState('cd_easytime') == 'started' then
        TriggerEvent('cd_easytime:PauseSync', state) -- Usually needed to force blackout override?
        -- CD Easytime usually has a blackout command or export, checking docs mental model...
        -- Common generic command:
        TriggerClientEvent('cd_easytime:ForceBlackout', -1, state) 
    end

    -- 2. QB-WeatherSync
    if GetResourceState('qb-weathersync') == 'started' then
        TriggerEvent('qb-weathersync:server:setBlackout', state)
    end
    
    -- 3. vSync / vSyncR
    if GetResourceState('vSync') == 'started' or GetResourceState('vSyncR') == 'started' then
        TriggerEvent('vSync:requestBlackout', state)
    end
end

-- Save Grid State Helper
local function SaveGrid()
    AG.SetData("city_grid_zones", GridState)
    TriggerClientEvent('ag_powerwater:client:updateGrid', -1, GridState)
    
    -- Check for Cascading Failure
    local failedZones = 0
    local totalZones = 0
    
    for zone, stats in pairs(GridState) do
        totalZones = totalZones + 1
        if stats.Power < Config.Grid.BlackoutLimit then
            failedZones = failedZones + 1
        end
    end
    
    -- Cascading Logic: If more than 30% of zones fail, the whole grid collapses
    if failedZones >= 3 then
        if not GlobalState.Blackout then
            print('^1[AG-PowerWater] ^7CASCADING FAILURE! ' .. failedZones .. ' Zones Critical. GLOBAL BLACKOUT.')
            SetBlackout(true)
            TriggerClientEvent('ag_powerwater:client:notify', -1, 'CRITICAL ALERT: CITY-WIDE POWER GRID FAILURE DETECTED', 'error', 10000)
        end
    else
        if GlobalState.Blackout then
            print('^2[AG-PowerWater] ^7Grid Stabilized. Blackout Lifted.')
            SetBlackout(false)
        end
    end
end

-- Decay Loop
CreateThread(function()
    while true do
        Wait(Config.Grid.DecayInterval * 60 * 1000)
        
        local decayMin = Config.Grid.DecayAmount.min
        local decayMax = Config.Grid.DecayAmount.max
        
        for zone, stats in pairs(GridState) do
            local decay = math.random(decayMin, decayMax)
            stats.Power = math.max(0, stats.Power - decay)
            stats.Water = math.max(0, stats.Water - decay)
            -- print('^3[AG-PowerWater] ^7Decay in ' .. zone .. ': -' .. decay .. '%')
        end
        
        SaveGrid()
    end
end)

-- Helper: Map GTA Zone Name to Our Zone Key
local function GetZoneKey(gtaZoneName)
    for key, data in pairs(Config.ZoneDefinitions) do
        for _, z in ipairs(data.zones) do
            if z == gtaZoneName then return key end
        end
    end
    return 'LosSantos' -- Fallback
end

-- Export for Missions to Restore Power
function RestoreGrid(type, amount, gtaZoneName)
    local key = GetZoneKey(gtaZoneName or 'UNKNOWN')
    
    if GridState[key] then
        if type == 'Power' then
            GridState[key].Power = math.min(100, GridState[key].Power + amount)
        elseif type == 'Water' then
            GridState[key].Water = math.min(100, GridState[key].Water + amount)
        end
        SaveGrid()
        return true
    end
    return false
end

exports('RestoreGrid', RestoreGrid)

-- Handle specific events needing restore (Wrapped)
-- Handle specific events needing restore (Wrapped)
RegisterNetEvent('ag_powerwater:server:restoreGrid', function(type, amount)
    -- Simplified: Restores Default Zone if zone not provided
    -- Ideal: Client sends zone, but for now we fallback to global 'LosSantos' key or loop all?
    -- We'll just call RestoreGrid which defaults to 'LosSantos' if name is nil.
    RestoreGrid(type, amount, nil) 
end)

-- Re-implementing the handler to accept Zone Name from client
RegisterNetEvent('ag_powerwater:server:restoreGridZone', function(type, amount, zoneName)
    RestoreGrid(type, amount, zoneName)
end)


-- On Player Join, sync state
RegisterNetEvent('ag_powerwater:server:playerJoined', function()
    TriggerClientEvent('ag_powerwater:client:updateGrid', source, GridState)
end)

-- Debug Command
CreateThread(function()
    while not AG.Framework do Wait(1000) end
    
    -- Ensure global helper exists
    if RegisterAdminCommand then
        RegisterAdminCommand('ag_debug_grid', 'Toggle Grid Debug UI', function(source, args)
            if source == 0 then -- Console
                for k, v in pairs(GridState) do
                     print(k .. ': Power ' .. v.Power .. '% | Water ' .. v.Water .. '%')
                end
            else
                TriggerClientEvent('ag_powerwater:client:toggleDebug', source, GridState)
            end
        end)
    else
        print('^1[AG-PowerWater] ^7Critical: RegisterAdminCommand helper not found despite wait.^7')
    end
end)
