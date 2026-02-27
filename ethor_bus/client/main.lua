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
            
            if isVehicleABus(veh) then
                local isDriver = GetPedInVehicleSeat(veh, -1) == ped

                if isDriver then
                    -- =========================================================
                    -- DRIVER LOGIC
                    -- =========================================================
                    if passengerUIVisible then
                        passengerUIVisible = false
                        SendNUIMessage({ action = "togglePassengerInBusUI", show = false })
                    end

                    if not inBus then
                        inBus = true
                        currentBus = veh
                        driverUIVisible = true
                        
                        SendNUIMessage({
                            action = "toggleDriverUI",
                            show = true,
                            info = {
                                line = "Außer Dienst",
                                nextStop = "Gewerbegebiet",
                                eta = "--:--",
                                pax = "0/50",
                                mood = 100
                            }
                        })
                    end
                    
                    -- Update Loop for Doors
                    -- Front doors: 0 (Fahrer) and 1 (Beifahrer)
                    -- Rear doors: 2 and 3
                    local doorFront = (GetVehicleDoorAngleRatio(veh, 0) > 0.1) or (GetVehicleDoorAngleRatio(veh, 1) > 0.1)
                    local doorRear = (GetVehicleDoorAngleRatio(veh, 2) > 0.1) or (GetVehicleDoorAngleRatio(veh, 3) > 0.1)
                    
                    SendNUIMessage({
                        action = "updateDriverUI",
                        info = {
                            doorFront = doorFront,
                            doorRear = doorRear
                        }
                    })
                    Wait(500) -- Refresh rate for doors

                else
                    -- =========================================================
                    -- PASSENGER LOGIC (Not Driver)
                    -- =========================================================
                    if driverUIVisible then
                        driverUIVisible = false
                        SendNUIMessage({ action = "toggleDriverUI", show = false })
                    end
                    
                    if not passengerUIVisible then
                        passengerUIVisible = true
                        inBus = true
                        currentBus = veh
                        SendNUIMessage({
                            action = "togglePassengerInBusUI",
                            show = true,
                            info = {
                                line = "Außer Dienst",
                                nextStop = "Gewerbegebiet",
                                eta = "--:--"
                            }
                        })
                    end
                    
                    SendNUIMessage({
                        action = "updatePassengerInBusUI",
                        info = {}
                    })
                    Wait(1000)
                end

            else
                -- In a vehicle, but NOT a bus
                if inBus then
                    inBus = false
                    currentBus = 0
                    if driverUIVisible then
                        driverUIVisible = false
                        SendNUIMessage({ action = "toggleDriverUI", show = false })
                    end
                    if passengerUIVisible then
                        passengerUIVisible = false
                        SendNUIMessage({ action = "togglePassengerInBusUI", show = false })
                    end
                end
                Wait(1000)
            end

        else
            -- Outside any vehicle
            if inBus then
                inBus = false
                currentBus = 0
                if driverUIVisible then
                    driverUIVisible = false
                    SendNUIMessage({ action = "toggleDriverUI", show = false })
                end
                if passengerUIVisible then
                    passengerUIVisible = false
                    SendNUIMessage({ action = "togglePassengerInBusUI", show = false })
                end
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

-- =============================================
-- Driver UI Drag Mode & Reset
-- =============================================

RegisterCommand('busdriveui', function()
    if inBus and driverUIVisible then
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "enableUIDragMode" })
    else
        AG.Notify.Show('Bus System', 'Du musst in einem Bus sitzen, um das UI zu bearbeiten!', 'error')
    end
end, false)

RegisterNUICallback('exitDragMode', function(data, cb)
    -- Called when ESC is pressed in the UI during drag mode
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterCommand('busuireset', function()
    if inBus and driverUIVisible then
        SendNUIMessage({ action = "resetUIPosition" })
        AG.Notify.Show('Bus System', 'UI Position wurde zurückgesetzt!', 'success')
    end
end, false)

-- =============================================
-- KeyBindings (Doors & Actions)
-- =============================================

local function toggleDoor(veh, doorIndex)
    if GetVehicleDoorAngleRatio(veh, doorIndex) > 0.1 then
        SetVehicleDoorShut(veh, doorIndex, false)
    else
        SetVehicleDoorOpen(veh, doorIndex, false, false)
    end
end

RegisterCommand('+bus_door_front', function()
    if inBus and currentBus ~= 0 then
        toggleDoor(currentBus, 0)
        toggleDoor(currentBus, 1)
    end
end, false)
RegisterKeyMapping('+bus_door_front', 'Bus: Vordere Türen (1&2)', 'keyboard', 'NUMPAD1')

RegisterCommand('+bus_door_rear', function()
    if inBus and currentBus ~= 0 then
        toggleDoor(currentBus, 2)
        toggleDoor(currentBus, 3)
    end
end, false)
RegisterKeyMapping('+bus_door_rear', 'Bus: Hintere Türen (3&4)', 'keyboard', 'NUMPAD2')

RegisterCommand('+bus_service', function()
    if inBus and currentTripId then
        TriggerServerEvent('ethor_bus:server:ToggleServiceMode', currentTripId)
    end
end, false)
RegisterKeyMapping('+bus_service', 'Bus: Service Mode (Beenden)', 'keyboard', 'NUMPAD4')

RegisterCommand('+bus_skip', function()
    if inBus and currentTripId then
        TriggerServerEvent('ethor_bus:server:ReportSkipStop', currentTripId, 5)
        AG.Notify.Show('Bus System', 'Haltestelle übersprungen.', 'error')
        if currentRouteStops and currentStopIndex then
            currentStopIndex = currentStopIndex + 1
            if currentStopIndex > #currentRouteStops then currentStopIndex = 1 end
        end
        TriggerEvent('ethor_bus:client:UpdateDriverUI')
    end
end, false)
RegisterKeyMapping('+bus_skip', 'Bus: Haltestelle überspringen', 'keyboard', 'NUMPAD5')

-- Stop Request (Passenger presses E)
local lastStopRequestTime = 0
RegisterCommand('+bus_stop_request', function()
    if inBus and currentBus ~= 0 then
        local ped = PlayerPedId()
        local isDriver = GetPedInVehicleSeat(currentBus, -1) == ped
        if not isDriver then
            local currentTime = GetGameTimer()
            if currentTime - lastStopRequestTime > 10000 then
                lastStopRequestTime = currentTime
                
                -- Play local passenger sound immediately
                SendNUIMessage({
                    action = "playSound",
                    file = "StopRequest"
                })
                
                -- Send up to server to sync to driver
                TriggerServerEvent('ethor_bus:server:SyncStopRequest', NetworkGetNetworkIdFromEntity(currentBus))
            else
                AG.Notify.Show('Bus System', 'Bitte warte einen Moment vor dem nächsten Haltewunsch.', 'error')
            end
        end
    end
end, false)
RegisterKeyMapping('+bus_stop_request', 'Bus: Haltewunsch (Passagier)', 'keyboard', 'E')

-- Stop Request Acknowledge (Driver presses NUM6)
RegisterCommand('+bus_clear_request', function()
    if inBus and currentBus ~= 0 then
        local ped = PlayerPedId()
        local isDriver = GetPedInVehicleSeat(currentBus, -1) == ped
        if isDriver then
            -- Tell server to clear the request
            TriggerServerEvent('ethor_bus:server:ClearStopRequest', NetworkGetNetworkIdFromEntity(currentBus))
            AG.Notify.Show('Bus System', 'Haltewunsch quittiert.', 'success')
        end
    end
end, false)
RegisterKeyMapping('+bus_clear_request', 'Bus: Haltewunsch Quittieren (Fahrer)', 'keyboard', 'NUMPAD6')

-- Client Event listener for synchronized Stop Requests
RegisterNetEvent('ethor_bus:client:ReceiveStopRequest', function(busNetId)
    if inBus and currentBus ~= 0 then
        -- Check if we are in the same bus that the request came from
        if NetworkGetNetworkIdFromEntity(currentBus) == busNetId then
            local ped = PlayerPedId()
            local isDriver = GetPedInVehicleSeat(currentBus, -1) == ped
            
            if isDriver then
                SendNUIMessage({
                    action = "playSound",
                    file = "StopRequest"
                })
                AG.Notify.Show('Linie', 'Haltewunsch ausgelöst!', 'warning')
            end
        end
    end
end)

-- Update Driver UI manually
RegisterNetEvent('ethor_bus:client:UpdateDriverUI', function()
    local nextStopName = "Gewerbegebiet"
    if currentRouteStops and currentStopIndex then
        local stop = currentRouteStops[currentStopIndex]
        if stop and stop.name then
            nextStopName = stop.name
        end
    end

    local cleanStopName = nextStopName:gsub("%s+", "") -- Remove spaces to match mp3 titles
    
    SendNUIMessage({
        action = "updateDriverUI",
        info = {
            nextStop = nextStopName
        }
    })
    
    SendNUIMessage({
        action = "updatePassengerInBusUI",
        info = {
            nextStop = nextStopName
        }
    })

    -- Play Sequence: NextStop.mp3 -> cleanStopName.mp3
    SendNUIMessage({
        action = "playSound",
        file = { "NextStop", cleanStopName }
    })
end)
