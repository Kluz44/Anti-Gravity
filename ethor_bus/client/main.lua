-- =============================================
-- Client Main Logic (ethor_bus)
-- =============================================

local isDispatchOpen = false
local inBus = false
local currentBus = 0
local driverUIVisible = false

-- Open Boss Dispatch UI
RegisterCommand('busboss', function()
    TriggerServerEvent('ethor_bus:server:RequestDispatchData')
end)

RegisterNetEvent('ethor_bus:client:OpenDispatchUI', function(data)
    if isDispatchOpen then return end
    isDispatchOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = "openDispatch",
        stops = data.stops or {},
        routes = data.routes or {}
    })
    
    AG.Notify.Show('Bus System', 'Dispatch UI geöffnet', 'success')
end)

RegisterNUICallback('actionDriverService', function(data, cb)
    if currentTripId then
        TriggerServerEvent('ethor_bus:server:ToggleServiceMode', currentTripId)
    end
    cb('ok')
end)

RegisterNUICallback('requestHeatmap', function(data, cb)
    TriggerServerEvent('ethor_bus:server:RequestHeatmap')
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    isDispatchOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('actionDriverSkip', function(data, cb)
    if currentTripId then
        -- Tell server we skipped
        TriggerServerEvent('ethor_bus:server:ReportSkipStop', currentTripId, 5) -- Example 5 pax missed
        AG.Notify.Show('Bus System', 'Haltestelle übersprungen. Rating-Abzug!', 'error')
        
        -- Advance route index locally to update UI
        if currentRouteStops and currentStopIndex then
            currentStopIndex = currentStopIndex + 1
            if currentStopIndex > #currentRouteStops then currentStopIndex = 1 end
        end
        TriggerEvent('ethor_bus:client:UpdateDriverUI')
    end
    cb('ok')
end)

RegisterNUICallback('driverAction', function(data, cb)
    if data.action == "toggle_service" then
        if currentTripId then
            TriggerServerEvent('ethor_bus:server:ToggleServiceMode', currentTripId)
        end
    end
    cb('ok')
end)

-- =============================================
-- Vehicle Loop & Driver UI
-- =============================================
local function isVehicleABus(veh)
    local model = GetEntityModel(veh)
    for _, busModel in ipairs(Config.BusModels) do
        if model == GetHashKey(busModel) then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped and isVehicleABus(veh) then
                if not inBus then
                    inBus = true
                    currentBus = veh
                    driverUIVisible = true
                    
                    SendNUIMessage({
                        action = "toggleDriverUI",
                        show = true,
                        info = {
                            line = "Ausser Dienst",
                            nextStop = "Gewerbegebiet",
                            eta = "--:--",
                            pax = "0/50",
                            mood = 100
                        }
                    })
                end
                
                -- Update Loop for Doors
                local doorFront = GetVehicleDoorAngleRatio(veh, 0) > 0.1 -- FL Door
                local doorRear = GetVehicleDoorAngleRatio(veh, 2) > 0.1  -- RL Door or specific bus doors
                
                SendNUIMessage({
                    action = "updateDriverUI",
                    info = {
                        doorFront = doorFront,
                        doorRear = doorRear
                    }
                })
                Wait(500) -- Refresh rate for doors
            else
                if inBus then
                    inBus = false
                    currentBus = 0
                    driverUIVisible = false
                    SendNUIMessage({ action = "toggleDriverUI", show = false })
                end
                Wait(1000)
            end
        else
            if inBus then
                inBus = false
                currentBus = 0
                driverUIVisible = false
                SendNUIMessage({ action = "toggleDriverUI", show = false })
            end
            Wait(2000)
        end
    end
end)

-- =============================================
-- Passenger UI & Target Registration
-- =============================================

local passengerStops = {}
RegisterNetEvent('ethor_bus:client:ReceiveStopBoard', function(stopId, data)
    SendNUIMessage({
        action = "updateStopBoard",
        stopId = stopId,
        boardData = data
    })
end)

-- Ads sync
local currentAds = {}
RegisterNetEvent('ethor_bus:client:SyncAds', function(ads)
    currentAds = ads
    SendNUIMessage({
        action = "updateAds",
        ads = ads,
        interval = Config.Ads.RotationInterval
    })
end)

-- Request Ads on Load
CreateThread(function()
    Wait(2500)
    TriggerServerEvent('ethor_bus:server:RequestAds')
end)

-- Heatmap Sync
RegisterNetEvent('ethor_bus:client:ReceiveHeatmap', function(data)
    if isDispatchOpen then
        SendNUIMessage({
            action = "updateHeatmap",
            heatmapData = data
        })
    end
end)

-- Live Tracking
RegisterNetEvent('ethor_bus:client:SyncLiveTracking', function(liveBuses)
    if isDispatchOpen then
        SendNUIMessage({
            action = "updateLiveTracking",
            buses = liveBuses
        })
    end
end)

-- Intercom
RegisterNetEvent('ethor_bus:client:ReceiveIntercom', function(msg)
    if isDriverUiOpen then
        -- Native GTA notification, or custom UI alert
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~[LEITSTELLE] ~w~" .. msg)
        DrawNotification(false, true)
        PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", true)
    end
end)

-- Maintenance / Service Mode
RegisterNetEvent('ethor_bus:client:ForceServiceMode', function()
    if isDriverUiOpen then
        SendNUIMessage({
            action = "updateDriverUI",
            info = { nextStop = "DEPOT (SERVICE MODE)" }
        })
    end
end)

local activeTargets = {}

RegisterNetEvent('ethor_bus:client:InitStopTargets', function(stops)
    if not Config.Target then return end
    
    for _, id in ipairs(activeTargets) do
        exports.ox_target:removeZone(id)
    end
    activeTargets = {}

    for _, stop in ipairs(stops) do
        local coords
        if type(stop.coords) == 'string' then 
            coords = json.decode(stop.coords) 
        else 
            coords = stop.coords 
        end
        
        if coords then
            local zoneId = exports.ox_target:addSphereZone({
                coords = vec3(coords.x, coords.y, coords.z),
                radius = 1.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'bus_stop_' .. stop.id,
                        icon = 'fa-solid fa-bus',
                        label = 'Fahrplan ansehen',
                        onSelect = function()
                            TriggerServerEvent('ethor_bus:server:RequestStopBoard', stop.id, stop.name)
                        end
                    }
                }
            })
            table.insert(activeTargets, zoneId)
        end
    end
end)

RegisterNetEvent('ethor_bus:client:OpenStopBoard', function(data)
    SetNuiFocus(true, true) -- We keep focus to let them click out or press ESC
    SendNUIMessage({
        action = "openPassengerUI",
        stopName = data.stopName,
        time = data.time,
        buses = data.buses
    })
end)

RegisterNUICallback('closeUI', function(data, cb)
    isDispatchOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closePassengerUI" })
    cb('ok')
end)
