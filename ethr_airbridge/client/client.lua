local flight = { isHost=false, plane=nil, planeNetId=nil, pilots={}, isOnboard=false, attached=false }

local function dprint(msg) if Config.Debug then print(('[ethr_airbridge][client] %s'):format(msg)) end end

RegisterNetEvent('ethr_airbridge:notify', function(msg, type, duration)
    if Notify and Notify.Client then Notify.Client(msg, type, duration) else TriggerEvent('chat:addMessage', { args = { '^3[Airbridge]^7 ' .. tostring(msg) } }) end
end)

local function useE() return (Config.InteractionMode=='ekey' or Config.InteractionMode=='both' or Config.InteractionMode=='radial') end
local function useTarget() return (Config.InteractionMode=='target' or Config.InteractionMode=='both') end
local function useRadial() return (Config.InteractionMode=='radial') or (Config.Interact and Config.Interact.Radial and Config.Interact.Radial.Enabled) end
local function hasOxTarget() return pcall(function() return exports.ox_target ~= nil end) end
local function hasOxLib() return lib ~= nil end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3DToScreen2D(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35); SetTextFont(4); SetTextProportional(1); SetTextColour(255,255,255,215); SetTextOutline(); SetTextEntry("STRING"); SetTextCentre(1); AddTextComponentString(text); DrawText(_x,_y)
        local f=(string.len(text)/22); DrawRect(_x,_y+0.0125,0.015+f*0.018,0.03,0,0,0,120)
    end
end

local function buildPassengerSeatList(veh, modelName)
    local pref = Config.SeatPolicy and Config.SeatPolicy.PerModelPreferred
    if pref and modelName and pref[modelName] then return pref[modelName] end
    local list = {}; if not veh or not DoesEntityExist(veh) then return list end
    local exclude = {}; for _,s in ipairs(Config.SeatPolicy.AlwaysExclude or {-1,0}) do exclude[s]=true end
    local max = GetVehicleMaxNumberOfPassengers(veh) or 0
    for s=1,(max+2) do if not exclude[s] then list[#list+1]=s end end
    return list
end

local checkPed
local function ensureCheckPed()
    if DoesEntityExist(checkPed) then return end
    local pedCfg=Config.CheckInPed
    lib.requestModel(pedCfg.model,5000)
    checkPed=CreatePed(4,pedCfg.model,pedCfg.coords.x,pedCfg.coords.y,pedCfg.coords.z-1.0,pedCfg.coords.w,false,true)
    SetEntityInvincible(checkPed,true); SetBlockingOfNonTemporaryEvents(checkPed,true); FreezeEntityPosition(checkPed,true)
    if pedCfg.scenario then TaskStartScenarioInPlace(checkPed,pedCfg.scenario,0,true) end
    if useTarget() and hasOxTarget() then
        exports.ox_target:addLocalEntity(checkPed, {{ name='ethr_airbridge_checkin', label=(Config.Interact and Config.Interact.TargetLabel) or 'Einchecken', distance=(Config.Interact and Config.Interact.TargetDistance) or 2.5, onSelect=function() TriggerServerEvent('ethr_airbridge:checkIn') end }})
        dprint('ox_target Interaktion aktiv.')
    end
end

CreateThread(function() Wait(1500); ensureCheckPed(); local any=(useTarget() and hasOxTarget()) or useE() or (useRadial() and hasOxLib()); if not any then print('[ethr_airbridge] WARN: Keine nutzbare Interaktion aktiv.') end end)

CreateThread(function()
    while true do Wait(0)
        if not checkPed or not DoesEntityExist(checkPed) then Wait(500) goto continue end
        local pedPos=GetEntityCoords(cache.ped); local tgt=Config.CheckInPed.coords; local dist = #(pedPos - vec3(tgt.x,tgt.y,tgt.z))
        if useE() and (Config.Interact and Config.Interact.Show3DText) then local maxD=(Config.Interact and (Config.Interact.EKeyDistance or 2.2)) or 2.2; if dist<=maxD then DrawText3D(tgt.x,tgt.y,tgt.z+1.0,(Config.Interact.Text3D or '[E] Einchecken')) end end
        if useE() then local maxD=(Config.Interact and (Config.Interact.EKeyDistance or 2.2)) or 2.2; if dist<=maxD and IsControlJustPressed(0,38) then TriggerServerEvent('ethr_airbridge:checkIn') end end
        if useRadial() and hasOxLib() then local rCfg=Config.Interact.Radial or {}; local rDist=rCfg.Distance or 2.5; if dist<=rDist then local VK={E=38,F=23,G=47,H=74,L=182}; local scan=VK[((rCfg.Key or 'G'):sub(1,1):upper())] or 47; BeginTextCommandDisplayHelp("STRING"); AddTextComponentSubstringPlayerName((' %s drücken für %s'):format((rCfg.Key or 'G'), rCfg.Title or 'Airbridge')); EndTextCommandDisplayHelp(0,false,true,0); if IsControlJustPressed(0,scan) then lib.registerRadial({ id='ethr_airbridge_radial', title=rCfg.Title or 'Airbridge', options={{ label=rCfg.OptionText or 'Einchecken', icon='plane', onSelect=function() TriggerServerEvent('ethr_airbridge:checkIn') end }} }); lib.showRadial('ethr_airbridge_radial') end end end
        ::continue::
    end
end)

RegisterNetEvent('ethr_airbridge:hostAssign', function(state) flight.isHost = state and true or false; if flight.isHost then dprint('Ich bin Host dieses Flugs.') end end)

-- ===== Stronger seat warp =====
local function trySetPedIntoVehicle(ped, veh, seat)
    SetPedIntoVehicle(ped, veh, seat)
    Wait(120)
    if IsPedInAnyVehicle(ped,false) then return true end
    TaskWarpPedIntoVehicle(ped, veh, seat)
    Wait(200)
    return IsPedInAnyVehicle(ped,false)
end

-- ===== StartNow: spawn plane & crew, AI mission, report seats =====
RegisterNetEvent('ethr_airbridge:startNow', function(isHost, players)
    if not isHost or not flight.isHost then return end
    lib.requestModel(Config.PlaneModel,10000); lib.requestModel(Config.PilotModel,10000); lib.requestModel(Config.CopilotModel,10000); lib.requestModel(Config.CrewModel,10000)
    local sp=Config.StartPoint
    local plane=CreateVehicle(Config.PlaneModel, sp.x,sp.y,sp.z, sp.w, true, false)
    while not DoesEntityExist(plane) do Wait(0) end
    SetEntityAsMissionEntity(plane,true,true); SetVehicleEngineOn(plane,true,true,false); SetVehicleUndriveable(plane,false); SetVehicleDoorsLocked(plane,4); ControlLandingGear(plane,1)
    if SetEntityDistanceCullingRadius then SetEntityDistanceCullingRadius(plane, 100000.0) else Citizen.InvokeNative(0x5F6DF3D92271E8A1, plane, 100000.0) end
    SetVehicleMaxSpeed(plane,200.0); SetVehicleEnginePowerMultiplier(plane,15.0); SetVehicleEngineTorqueMultiplier(plane,1.6); SetPlaneTurbulenceMultiplier(plane,0.0)
    local pilot=CreatePedInsideVehicle(plane,1,Config.PilotModel,-1,true,false)
    local copilot=CreatePedInsideVehicle(plane,1,Config.CopilotModel,0,true,false)
    local crew1=CreatePedInsideVehicle(plane,1,Config.CrewModel or Config.CopilotModel,1,true,false)
    local crew2=CreatePedInsideVehicle(plane,1,Config.CrewModel or Config.CopilotModel,2,true,false)
    local crew3=CreatePedInsideVehicle(plane,1,Config.CrewModel or Config.CopilotModel,3,true,false)
    local crew4=CreatePedInsideVehicle(plane,1,Config.CrewModel or Config.CopilotModel,4,true,false)
    for _,p in ipairs({pilot,copilot,crew1,crew2,crew3,crew4}) do SetBlockingOfNonTemporaryEvents(p,true); SetPedCanBeTargetted(p,false); SetPedFleeAttributes(p,0,false); SetPedCombatAttributes(p,46,true); SetPedCanBeDraggedOut(p, not (Config.Pilot.NoDrag)); SetPedCanRagdoll(p, not (Config.Pilot.BlockRagdoll)); if Config.Pilot.Godmode then SetEntityInvincible(p,true) end end
    local ep=Config.EndPoint
    TaskPlaneMission(pilot, plane, 0,0, ep.x,ep.y,ep.z, 4, Config.FlightSpeed or 85.0, 0.0,0.0, Config.CruiseAltitude, 100.0, true)
    if (Config.Pilot.KeepGearUpTick or 0) > 0 then CreateThread(function() while DoesEntityExist(plane) do if GetLandingGearState(plane) ~= 1 then ControlLandingGear(plane,1) end Wait(Config.Pilot.KeepGearUpTick) end end) end
    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(plane)):lower()
    local seatList = buildPassengerSeatList(plane, modelName)
    local netId = NetworkGetNetworkIdFromEntity(plane); SetNetworkIdExistsOnAllMachines(netId,true); SetNetworkIdCanMigrate(netId,true)
    SetVehicleForwardSpeed(plane, Config.FlightSpeed or 85.0)
    flight.plane=plane; flight.pilots={pilot,copilot,crew1,crew2,crew3,crew4}; flight.planeNetId=netId
    TriggerServerEvent('ethr_airbridge:reportPlaneNetId', netId, seatList)

    -- Host loop: pax count -> guided despawn request (legacy path)
    CreateThread(function()
        while DoesEntityExist(plane) do
            Wait(800)
            local seatedPax=0; local max=GetVehicleMaxNumberOfPassengers(plane) or 0; for s=1,(max+2) do if not IsVehicleSeatFree(plane,s) then seatedPax=seatedPax+1 end end
            local attachedPax=0; local peds=GetGamePool('CPed'); for i=1,#peds do local pp=peds[i]; if DoesEntityExist(pp) and IsPedAPlayer(pp) and IsEntityAttachedToEntity(pp,plane) then attachedPax=attachedPax+1 end end
            if (seatedPax + attachedPax) == 0 then
                TriggerServerEvent('ethr_airbridge:flightEmpty')
                break
            end
        end
    end)
end)

-- ===== Guided despawn (host only) =====
RegisterNetEvent('ethr_airbridge:guidedDespawn', function()
    if not flight.isHost then return end
    local plane = flight.plane
    if not plane or not DoesEntityExist(plane) then TriggerServerEvent('ethr_airbridge:hostDespawned'); return end
    local function taskTo(point, cruiseAlt, speedOverride)
        TaskPlaneMission(flight.pilots[1], plane, 0,0, point.x,point.y,point.z, 4, speedOverride or 0.0, 0.0,0.0, cruiseAlt or Config.CruiseAltitude, 100.0, true)
    end
    local off=Config.DespawnOffset
    local tgt=vec3(Config.EndPoint.x+off.x, Config.EndPoint.y+off.y, Config.EndPoint.z+off.z)
    taskTo(vec4(tgt.x,tgt.y,tgt.z,0.0), Config.CruiseAltitude, Config.Loiter and Config.Loiter.SpeedOverride or 0.0)
    local timeout=GetGameTimer()+15000
    while DoesEntityExist(plane) and GetGameTimer()<timeout do
        local pos=GetEntityCoords(plane)
        if #(pos - tgt) < (Config.Loiter and Config.Loiter.ArriveThreshold or 250.0) then break end
        if GetLandingGearState(plane) ~= 1 then ControlLandingGear(plane,1) end
        Wait(300)
    end
    -- delete pilots + plane
    if flight.pilots then for _,pp in ipairs(flight.pilots) do if pp and DoesEntityExist(pp) then DeleteEntity(pp) end end end
    if DoesEntityExist(plane) then DeleteVehicle(plane) end
    flight.plane=nil; flight.pilots={}; flight.planeNetId=nil
    TriggerServerEvent('ethr_airbridge:hostDespawned')
end)

-- ===== Boarding =====
RegisterNetEvent('ethr_airbridge:boardPlane', function(netId, assignedSeat)
    flight.planeNetId=netId
    local plane=NetworkGetEntityFromNetworkId(netId)
    local ped=cache.ped

    local function stageToStartPoint()
        local sp = Config.StartPoint
        local stage = vec3(sp.x, sp.y, sp.z - 2.0)
        SetEntityCoordsNoOffset(ped, stage.x, stage.y, stage.z, false, false, false)
        ClearPedTasksImmediately(ped)
    end

    -- ensure plane is streamed
    local t0 = GetGameTimer()
    while not DoesEntityExist(plane) and GetGameTimer() - t0 < 2000 do
        plane = NetworkGetEntityFromNetworkId(netId); Wait(50)
    end
    if not DoesEntityExist(plane) then
        stageToStartPoint()
        local timeout=GetGameTimer()+10000
        while not DoesEntityExist(plane) and GetGameTimer()<timeout do plane=NetworkGetEntityFromNetworkId(netId); Wait(80) end
    end
    if not DoesEntityExist(plane) then
        TriggerEvent('chat:addMessage', { args = { '^3[Airbridge]^7 Fehler: Flugzeug nicht synchronisiert (NetID).' } })
        return
    end

    -- Move near plane and prep
    local stage = GetOffsetFromEntityInWorldCoords(plane, 0.0, -8.0, -2.0)
    SetEntityCoordsNoOffset(ped, stage.x, stage.y, stage.z, false, false, false)
    ClearPedTasksImmediately(ped)
    if SetVehicleDoorsLockedForPlayer then SetVehicleDoorsLockedForPlayer(plane, PlayerId(), false) end
    SetVehicleDoorsLockedForAllPlayers(plane, false); SetVehicleDoorsLocked(plane, 1)
    SetPedRagdollOnCollision(ped, false)

    -- Request control
    local triesCtrl=0
    while NetworkGetEntityOwner and NetworkGetEntityOwner(plane) ~= PlayerId() and triesCtrl<15 do
        NetworkRequestControlOfEntity(plane); Wait(80); triesCtrl=triesCtrl+1
    end

    -- Try assigned seat first with stronger warp method
    local seated=false
    if assignedSeat and IsVehicleSeatFree(plane, assignedSeat) then
        for i=1,4 do if trySetPedIntoVehicle(ped, plane, assignedSeat) then seated=true break end end
    end

    -- Then any passenger seat
    if not seated then
        local max=GetVehicleMaxNumberOfPassengers(plane) or 0
        for s=1,(max+2) do
            if s~=-1 and s~=0 and IsVehicleSeatFree(plane,s) then
                for i=1,3 do if trySetPedIntoVehicle(ped, plane, s) then seated=true break end end
                if seated then break end
            end
        end
    end

    if not seated then
        -- Cargo fallback
        local chosen=false
        if Config.CargoAttachOffsets and #Config.CargoAttachOffsets>0 then
            for i=1,#Config.CargoAttachOffsets do local off=Config.CargoAttachOffsets[i]; AttachEntityToEntity(ped,plane,0,off.x,off.y,off.z,0.0,0.0,0.0,false,false,true,false,2,true); Wait(40); if IsEntityAttachedToEntity(ped,plane) then chosen=true break end end
        end
        if not chosen then AttachEntityToEntity(ped,plane,0,0.0,-2.2,0.85,0.0,0.0,0.0,false,false,true,false,2,true) end
        flight.attached=true; if Notify and Notify.Client then Notify.Client('Alle Sitze voll – du bist im Laderaum gesichert.','inform') end
    else flight.isOnboard=true end

    TriggerServerEvent('ethr_airbridge:clientBoarded')
    CreateThread(function() Wait(1200); SetVehicleDoorsLocked(plane,4); SetVehicleDoorsLockedForAllPlayers(plane,true) end)

    -- Jump thread
    CreateThread(function()
        while DoesEntityExist(plane) and (flight.isOnboard or flight.attached) do Wait(0)
            BeginTextCommandDisplayHelp("STRING"); AddTextComponentSubstringPlayerName(Config.HelpTextPressToJump or 'F drücken zum Springen'); EndTextCommandDisplayHelp(0,false,true,0)
            if IsControlJustPressed(0,75) then
                GiveWeaponToPed(ped, `GADGET_PARACHUTE`, 1, false, true)
                if flight.attached then
                    DetachEntity(ped,true,true); flight.attached=false
                else
                    SetVehicleDoorsLockedForAllPlayers(plane,false); SetVehicleDoorsLocked(plane,1)
                    TaskLeaveVehicle(ped,plane,4160); Wait(250)
                    if IsPedInAnyVehicle(ped,false) then TaskLeaveVehicle(ped,plane,0); Wait(300) end
                    if IsPedInAnyVehicle(ped,false) then local pos=GetOffsetFromEntityInWorldCoords(plane,0.0,-6.0,-2.0); SetEntityCoordsNoOffset(ped,pos.x,pos.y,pos.z,false,false,false); ClearPedTasksImmediately(ped) end
                    CreateThread(function() Wait(500); SetVehicleDoorsLocked(plane,4); SetVehicleDoorsLockedForAllPlayers(plane,true) end)
                end
                local v=GetEntityVelocity(plane); SetEntityVelocity(ped, v.x,v.y, math.max(v.z-10.0, -25.0))
                flight.isOnboard=false; TriggerServerEvent('ethr_airbridge:playerJumped'); if Notify and Notify.Client then Notify.Client('Viel Erfolg! Du hast abgesprungen.','success',4000) end
                return
            end
        end
    end)
end)

RegisterNetEvent('ethr_airbridge:forceDespawn', function()
    if not flight.isHost then return end
    local plane=flight.plane
    if plane and DoesEntityExist(plane) then if flight.pilots then for _,p in ipairs(flight.pilots) do if p and DoesEntityExist(p) then DeleteEntity(p) end end end DeleteVehicle(plane) end
    flight.plane=nil; flight.pilots={}; flight.planeNetId=nil; flight.isOnboard=false; flight.attached=false; dprint('ForceDespawn (sofort).')
end)

RegisterNetEvent('ethr_airbridge:forceDisembark', function(reason)
    local ped=cache.ped
    if IsEntityAttached(ped) then DetachEntity(ped,true,true) end
    if IsPedInAnyVehicle(ped,false) then TaskLeaveAnyVehicle(ped,256,0); Wait(300) end
    local c=Config.CheckInPed.coords; local safe=vec3(c.x+math.random(-2,2), c.y+math.random(-2,2), c.z)
    SetEntityCoordsNoOffset(ped, safe.x,safe.y,safe.z, false,false,false)
    flight.isOnboard=false; flight.attached=false
    if Notify and Notify.Client then Notify.Client(reason or 'Du wurdest vom Flug entfernt.','error',6000) end
end)

RegisterNetEvent('ethr_airbridge:AddFlight', function(countdownLeft)

        exports['ethorium_dui']:AddFlight("TEST-123", countdownLeft, "Check-in")
end)

RegisterNetEvent('ethr_airbridge:infoCooldown', function(Cooldown)

        
        exports['ethorium_dui']:RemoveFlight("TEST-123")
        exports['ethorium_dui']:AddFlight("TEST-123", Cooldown, "Noch nicht verfügbar")
end)

RegisterNetEvent('ethr_airbridge:remove', function()

        
        exports['ethorium_dui']:RemoveFlight("TEST-123")
        exports['ethorium_dui']:AddFlight("TEST-123", 0, "Standby")
end)