-- =============================================
-- Admin Creator Infrastructure (Phase 1)
-- =============================================
local editingStop = nil
local debugEnabled = false

-- State Variables for current editing
local currentStopData = {
    id = nil,
    name = nil,
    coords = nil,
    approach_coords = nil,
    exit_coords = nil,
    queue_coords = {},
    base_demand = 5,
    rush_profile = 'default'
}

-- Toggle Debug Overlay
RegisterCommand('busdebug', function()
    debugEnabled = not debugEnabled
    AG.Notify.Show('Bus System', 'Debug Overlay: ' .. tostring(debugEnabled), 'info')
    
    if debugEnabled then
        CreateThread(function()
            while debugEnabled do
                Wait(0)
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)

                -- Draw Editing Stop Data
                if editingStop then
                    -- Main Stop Coords
                    if currentStopData.coords then
                        DrawMarker(28, currentStopData.coords.x, currentStopData.coords.y, currentStopData.coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 150, false, false, 2, false, nil, nil, false)
                    end
                    -- Approach Coords
                    if currentStopData.approach_coords then
                        DrawMarker(1, currentStopData.approach_coords.x, currentStopData.approach_coords.y, currentStopData.approach_coords.z - 1.0, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 0.5, 0, 255, 0, 150, false, false, 2, false, nil, nil, false)
                        DrawLine(currentStopData.coords.x, currentStopData.coords.y, currentStopData.coords.z, currentStopData.approach_coords.x, currentStopData.approach_coords.y, currentStopData.approach_coords.z, 0, 255, 0, 255)
                    end
                    -- Exit Coords
                    if currentStopData.exit_coords then
                        DrawMarker(28, currentStopData.exit_coords.x, currentStopData.exit_coords.y, currentStopData.exit_coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 0, 255, 150, false, false, 2, false, nil, nil, false)
                    end
                    -- Queue Coords
                    for i, q in ipairs(currentStopData.queue_coords) do
                        DrawMarker(28, q.x, q.y, q.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 255, 255, 0, 150, false, false, 2, false, nil, nil, false)
                    end
                end
            end
        end)
    end
end, true)

RegisterCommand('buscreate', function()
    editingStop = true
    currentStopData = {
        id = nil,
        name = nil,
        coords = nil,
        approach_coords = nil,
        exit_coords = nil,
        queue_coords = {},
        base_demand = 5,
        rush_profile = 'default'
    }
    AG.Notify.Show('Bus System', 'Creator Modus gestartet. Nutze /busset ...', 'success')
    if not debugEnabled then ExecuteCommand('busdebug') end
end, true)

RegisterCommand('busset', function(source, args)
    if not editingStop then
        AG.Notify.Show('Bus System', 'Du bist nicht im Creator Modus (/buscreate)', 'error')
        return
    end

    local type = args[1]
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local head = GetEntityHeading(ped)
    local coordData = {x = pos.x, y = pos.y, z = pos.z, h = head}

    if type == 'main' then
        currentStopData.coords = coordData
        AG.Notify.Show('Bus System', 'Main Halt gesetzt (Prop Position/Sign)', 'success')
    elseif type == 'approach' then
        currentStopData.approach_coords = coordData
        AG.Notify.Show('Bus System', 'Approach gesetzt (Wo der Bus hält)', 'success')
    elseif type == 'exit' then
        currentStopData.exit_coords = coordData
        AG.Notify.Show('Bus System', 'Exit Point gesetzt (Wo Peds hingehen nach Ausstieg)', 'success')
    elseif type == 'queue' then
        table.insert(currentStopData.queue_coords, coordData)
        AG.Notify.Show('Bus System', 'Queue Point ' .. #currentStopData.queue_coords .. ' gesetzt', 'success')
    elseif type == 'demand' then
        if args[2] then
            currentStopData.base_demand = tonumber(args[2])
            AG.Notify.Show('Bus System', 'Base Demand gesetzt: ' .. args[2], 'success')
        end
    else
        AG.Notify.Show('Bus System', 'Typen: main, approach, exit, queue, demand', 'info')
    end
end, true)

RegisterCommand('bussave', function(source, args)
    if not editingStop then return end
    if not currentStopData.coords then
        AG.Notify.Show('Bus System', 'Main Coords fehlen!', 'error')
        return
    end
    
    local id = args[1]
    local name = args[2]

    if not id or not name then
        AG.Notify.Show('Bus System', 'Nutzung: /bussave [id_ohne_leerzeichen] [Anzeigename]', 'error')
        return
    end

    currentStopData.id = id
    currentStopData.name = name

    TriggerServerEvent('ethor_bus:server:SaveStop', currentStopData)
    AG.Notify.Show('Bus System', 'Stop gespeichert: ' .. name, 'success')
    
    editingStop = false
    if debugEnabled then ExecuteCommand('busdebug') end
end, true)
