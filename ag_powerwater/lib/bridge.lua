AG = {}
AG.System = {}
AG.Framework = nil

-- Attempt to detect the active framework
-- Attempt to detect the active framework and other systems
CreateThread(function()
    -- 1. Core Framework Detection
    while not AG.Framework do
        Wait(100)
        if GetResourceState('qbox') == 'started' then
            AG.Framework = 'qbox'
            print('^2[AG-Template] ^7Framework Detected: ^5Qbox^7')
        elseif GetResourceState('qb-core') == 'started' then
            AG.Framework = 'qbcore'
            QBCore = exports['qb-core']:GetCoreObject()
            print('^2[AG-Template] ^7Framework Detected: ^5QB-Core^7')
        elseif GetResourceState('es_extended') == 'started' then
            AG.Framework = 'esx'
            ESX = exports['es_extended']:getSharedObject()
            print('^2[AG-Template] ^7Framework Detected: ^5ESX^7')
        end
    end

    -- 2. Helper function to find first running resource from list
    local function DetectSystem(systemName, resourceList)
        Wait(100) -- Small delay ensures manifest loads
        for _, resource in ipairs(resourceList) do
            if GetResourceState(resource) == 'started' then
                AG.System[systemName] = resource
                print(string.format('^2[AG-Template] ^7%s System Detected: ^5%s^7', systemName, resource))
                return
            end
        end
        print(string.format('^3[AG-Template] ^7No %s System Detected (Defaulting or None)', systemName))
    end
    
    -- Verify Config.Target setting
    if Config.Target then
        if GetResourceState(Config.Target) == 'started' then
             print(string.format('^2[AG-Template] ^7Target System Active: ^5%s^7', Config.Target))
        else
             print(string.format('^1[AG-Template] ^7Config.Target is set to ^5%s^7 but resource is NOT started!', Config.Target))
        end
    else
        print('^3[AG-Template] ^7Targeting Disabled. Using DrawText/Markers fallback.^7')
    end

    -- 3. Detect Specific Systems based on Config (or hardcoded lists if Config isn't ready immediately)
    -- Start async threads to check for other resources
    CreateThread(function()
        if not Config or not Config.Detectables then return end
        
        DetectSystem('Notify', Config.Detectables.Notify)
        DetectSystem('Inventory', Config.Detectables.Inventory)
        DetectSystem('Phone', Config.Detectables.Phone)
        DetectSystem('Garage', Config.Detectables.Garage)
        DetectSystem('Clothing', Config.Detectables.Clothing)
        DetectSystem('Weather', Config.Detectables.Weather)
    end)
    
end)

function AG.GetPlayer(source)
    if AG.Framework == 'qbox' or AG.Framework == 'qbcore' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)
    elseif AG.Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
    return nil
end
