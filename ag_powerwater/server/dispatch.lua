local Missions = {}
local MissionIDInfo = 1
local GetActiveTechnicians -- Forward declaration

function GenerateMissionID()
    MissionIDInfo = MissionIDInfo + 1
    return MissionIDInfo
end

-- Create a new Mission and broadcast
function CreateDispatchMission(type, subType, coords, priority, label, data)
    local id = GenerateMissionID()
    
    Missions[id] = {
        id = id,
        type = type,       -- 'power' or 'water'
        subType = subType, -- 'turbine_fire', 'pipe_burst', 'maintenance'
        coords = coords,
        priority = priority, -- 'emergency' or 'routine'
        label = label,
        status = 'open',   -- 'open', 'assigned', 'progress', 'completed'
        assigned = {},     -- List of player sources
        data = data or {}  -- Extra data (e.g. Turbine Index)
    }
    
    TriggerClientEvent('ag_powerwater:client:syncDispatch', -1, Missions)
    return id
end

function GetMission(id)
    return Missions[id]
end

function CompleteDispatchMission(id)
    if Missions[id] then
        Missions[id].status = 'completed'
        
        -- Reset status of assigned players to 'available'
        if Missions[id].assigned then
            for _, src in ipairs(Missions[id].assigned) do
                TechnicianStatus[src] = 'available'
            end
            -- Push tech update
            local techs = GetActiveTechnicians()
            TriggerClientEvent('ag_powerwater:client:activeTechsUpdate', -1, techs)
        end

        -- Archive or delete? For now mark completed so UI shows it green.
        -- Delete after delay.
        SetTimeout(60000, function() 
            Missions[id] = nil 
            TriggerClientEvent('ag_powerwater:client:syncDispatch', -1, Missions)
        end)
        TriggerClientEvent('ag_powerwater:client:syncDispatch', -1, Missions)
    end
end

local TechnicianStatus = {} -- [src] = 'available' | 'busy' | 'break'

-- Update Status
RegisterNetEvent('ag_powerwater:server:setStatus', function(status)
    local src = source
    if status == 'available' or status == 'busy' or status == 'break' then
        TechnicianStatus[src] = status
        -- Push update to all clients
        local techs = GetActiveTechnicians()
        TriggerClientEvent('ag_powerwater:client:activeTechsUpdate', -1, techs)
    end
end)

RegisterNetEvent('ag_powerwater:server:claimMission', function(id)
    local src = source
    local mission = Missions[id]
    if not mission then return end
    
    -- Add player to assigned list
    local alreadyAssigned = false
    mission.assigned = mission.assigned or {} -- robust check
    for _, p in ipairs(mission.assigned) do if p == src then alreadyAssigned = true end end
    
    if not alreadyAssigned then
        table.insert(mission.assigned, src)
        mission.status = 'assigned'
        
        -- Auto-set Status to Busy
        TechnicianStatus[src] = 'busy'
        
        TriggerClientEvent('ag_powerwater:client:syncDispatch', -1, Missions)
        
        -- Push tech update
        local techs = GetActiveTechnicians()
        TriggerClientEvent('ag_powerwater:client:activeTechsUpdate', -1, techs)
        
        AG.Notify.Show(src, 'Dispatch: You joined the mission.', 'success')
    end
end)

-- [[ PLAYER LIST SYNC ]]
function GetActiveTechnicians()
    local technicians = {}
    local players = GetPlayers()
    
    for _, src in ipairs(players) do
        src = tonumber(src)
        local jobName = "unknown"
        local charName = GetPlayerName(src) -- Fallback
        local gradeLabel = ""

        if AG.Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                jobName = xPlayer.job.name
                -- ESX usually changes job name for off-duty, so checking name is enough
                if jobName == 'power' or jobName == 'water' or (Config.FireJobs and table.contains(Config.FireJobs, jobName)) then
                    charName = xPlayer.getName()
                    gradeLabel = xPlayer.job.grade_label
                    local gradeName = xPlayer.job.grade_name
                    
                    table.insert(technicians, {
                        source = src,
                        name = charName,
                        job = jobName,
                        grade = gradeLabel,
                        grade_name = gradeName,
                        status = TechnicianStatus[src] or 'available'
                    })
                end
            end
        elseif AG.Framework == 'qbcore' or AG.Framework == 'qbox' then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                jobName = Player.PlayerData.job.name
                local isOnDuty = Player.PlayerData.job.onduty
                
                if (jobName == 'power' or jobName == 'water' or (Config.FireJobs and table.contains(Config.FireJobs, jobName))) and isOnDuty then
                    charName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
                    gradeLabel = Player.PlayerData.job.grade.name
                    -- For QBCore, grade name IS the label usually, level is the id
                    -- We'll use level as grade_name just in case for mapping, or the label itself
                    local gradeLevel = Player.PlayerData.job.grade.level
                    
                    table.insert(technicians, {
                        source = src,
                        name = charName,
                        job = jobName,
                        grade = gradeLabel,
                        grade_name = gradeLabel, -- QBCore compatibility
                        level = gradeLevel,
                        status = TechnicianStatus[src] or 'available'
                    })
                end
            end
        end
    end
    return technicians
end

-- Used by Tablet initialization
RegisterNetEvent('ag_powerwater:server:requestDispatchData', function()
    local src = source
    local techs = GetActiveTechnicians()
    
    -- GetClockHours is client side. We let client calculate isDay.
    TriggerClientEvent('ag_powerwater:client:receiveDispatchData', src, Missions, techs)
end)

-- Helper
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end
