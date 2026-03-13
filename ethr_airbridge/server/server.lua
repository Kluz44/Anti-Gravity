local Flight = {
    active=false, inCooldown=false,
    windowEndsAt=0, startAt=0,
    participants={}, assignedSeats={}, boarded={},
    host=nil, planeNetId=nil, joinOrder={}, seatCandidates=nil,
    _watchdogActive=false
}

local function debug(msg) if Config.Debug then print(('[ethr_airbridge][server] %s'):format(msg)) end end

-- ===== Helpers =====
local function participantsCount()
    local c=0; for _ in pairs(Flight.participants) do c=c+1 end; return c
end

local function resetFlight()

    Flight.active=false
    Flight.windowEndsAt=0
    Flight.startAt=0
    Flight.participants={}
    Flight.assignedSeats={}
    Flight.boarded={}
    Flight.host=nil
    Flight.planeNetId=nil
    Flight.joinOrder={}
    Flight.seatCandidates=nil
    Flight._watchdogActive=false
end

local function resetFlight_new()

    exports['ethorium_dui']:RemoveFlight(Config.Luftfahrzeugkennzeichen)
    exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, Config.FlightCooldownSeconds, "Noch nicht verfügbar")
  
    Flight.inCooldown=true
    debug('Flight reset -> cooldown starts')
    SetTimeout((Config.FlightCooldownSeconds or 60)*1000, function()
        Flight.inCooldown=false
        debug('Cooldown over')
        if Notify and Notify.ServerAll then
            Notify.ServerAll('Die Maschine ist zurück. Einchecken wieder möglich.', 'success', 6000)
            resetFlight()
            exports['ethorium_dui']:RemoveFlight(Config.Luftfahrzeugkennzeichen)
            exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, 0, "Standby")
        else
            for _, id in ipairs(GetPlayers()) do TriggerClientEvent('chat:addMessage', id, { args = { '^3[Airbridge]^7 Die Maschine ist zurück. Einchecken wieder möglich.' } }) end
        end
    end)
end


local function startEmptyWatchdog()
    if Flight._watchdogActive then return end
    Flight._watchdogActive=true
    CreateThread(function()
        debug('Empty-watchdog gestartet.')
        while Flight.active and Flight.planeNetId do
            Wait(3000)
            if participantsCount()==0 then
                debug('Watchdog: keine Teilnehmer mehr -> Guided Despawn an Host.')
                if Flight.host then
                    TriggerClientEvent('ethr_airbridge:guidedDespawn', Flight.host)
                end
                -- Server wartet jetzt auf Host-Bestätigung
                return
            end
        end
        Flight._watchdogActive=false
    end)
end

-- ===== Client confirms boarded =====
RegisterNetEvent('ethr_airbridge:clientBoarded', function()
    local src=source; Flight.boarded[src]=true
    debug(('Client %d confirmed boarded.'):format(src))
end)

-- ===== Guided Despawn complete =====
RegisterNetEvent('ethr_airbridge:hostDespawned', function()
    local src=source
    if src ~= Flight.host then return end
    debug('Host bestätigt: guided despawn abgeschlossen.')
    --resetFlight()
end)

-- ===== Reliable boarding resend =====
local function nextFreeSeatPersistent()
    if not Flight.seatCandidates or #Flight.seatCandidates==0 then return nil end
    local used={} for _, seat in pairs(Flight.assignedSeats) do if seat~=nil then used[seat]=true end end
    for i=1,#Flight.seatCandidates do local s=Flight.seatCandidates[i]; if not used[s] then return s end end
    return nil
end

local function ensureBoardingAll(retries, intervalMs)
    retries = retries or 10
    intervalMs = intervalMs or 3000
    local attempt = 0
    local function tick()
        attempt = attempt + 1
        if not Flight.planeNetId then return end
        local pending={} for p,_ in pairs(Flight.participants) do if not Flight.boarded[p] then pending[#pending+1]=p end end
        if #pending==0 then debug('All participants boarded.'); return end
        debug(('Boarding retry %d: resending to %d players'):format(attempt, #pending))
        for _,p in ipairs(pending) do
            if not Flight.assignedSeats[p] then Flight.assignedSeats[p]=nextFreeSeatPersistent() end
            TriggerClientEvent('ethr_airbridge:boardPlane', p, Flight.planeNetId, Flight.assignedSeats[p])
            if Notify and Notify.Server then Notify.Server(p, 'Boarding läuft – du wirst zum Flugzeug gebracht.', 'primary', 3200)
            else TriggerClientEvent('chat:addMessage', p, { args = { '^3[Airbridge]^7 Boarding läuft – du wirst zum Flugzeug gebracht.' } }) end
        end
        if attempt < retries then SetTimeout(intervalMs, tick) end
    end
    SetTimeout(500, tick)
end

-- ===== Core: Check-In =====
RegisterNetEvent('ethr_airbridge:checkIn', function()
    local src=source
    if Flight.inCooldown then
        if Notify and Notify.Server then Notify.Server(src,'Warte auf Rückkehr der Maschine (Cooldown aktiv).','error') else TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Warte auf Rückkehr der Maschine (Cooldown aktiv).' } }) end
        return
    end

    if Flight.planeNetId then
        Flight.participants[src]=true; Flight.boarded[src]=false
        if not Flight.assignedSeats[src] then Flight.assignedSeats[src]=nextFreeSeatPersistent() end
        TriggerClientEvent('ethr_airbridge:boardPlane', src, Flight.planeNetId, Flight.assignedSeats[src])
        if Notify and Notify.Server then Notify.Server(src,'Boarding läuft – du wirst zum Flugzeug gebracht.','primary',5000) end
        ensureBoardingAll()
        return
    end

    Flight.participants[src]=true; Flight.boarded[src]=false
    if not Flight.host then Flight.host=src; TriggerClientEvent('ethr_airbridge:hostAssign', Flight.host, true) end
    local seen=false for _,p in ipairs(Flight.joinOrder) do if p==src then seen=true break end end
    if not seen then table.insert(Flight.joinOrder, src) end

    if Config.StartMode=='instant' then
        local startIn=15; Flight.startAt=os.time()+startIn; Flight.active=true
        if Notify and Notify.Server then Notify.Server(src,('Check-in bestätigt. Start in %d Sekunden.'):format(startIn),'success') end
        if Notify and Notify.ServerAll then Notify.ServerAll('Boarding läuft. Bitte bereitmachen.','primary',5000) end
        TriggerClientEvent('ethr_airbridge:hostAssign', Flight.host, true)
        return
    end

    if Flight.windowEndsAt==0 then
        Flight.windowEndsAt=os.time()+(Config.CheckInWindowMinutes*60); Flight.startAt=Flight.windowEndsAt; Flight.active=true
        if Notify and Notify.Server then Notify.Server(src,('Check-in bestätigt. Abflugfenster geöffnet (%d Min).'):format(Config.CheckInWindowMinutes),'success') end
        if Notify and Notify.ServerAll then Notify.ServerAll(('Flugfenster geöffnet: %d Min. Am NPC einchecken!'):format(Config.CheckInWindowMinutes),'primary',7000) end
        exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen,Config.CheckInWindowMinutes*60,"Check-in")
        CreateThread(function()
            while Flight.active and os.time()<Flight.windowEndsAt do
                local remaining=Flight.windowEndsAt-os.time()
                if remaining<= (Config.FinalReminderSeconds or 30) then
                    for p,_ in pairs(Flight.participants) do if Notify and Notify.Server then Notify.Server(p,('Abflug in %d Sekunden.'):format(remaining),'primary') end end
                    Wait(1000)
                else
                    for p,_ in pairs(Flight.participants) do if Notify and Notify.Server then Notify.Server(p,('Flug in %d Min.'):format(math.ceil(remaining/60)),'primary') end end
                    Wait((Config.ReminderIntervalSeconds or 60)*1000)
                end
            end
            if Flight.active then
                if not Flight.host then for p,_ in pairs(Flight.participants) do Flight.host=p; TriggerClientEvent('ethr_airbridge:hostAssign', Flight.host, true); break end end
                if Flight.host then TriggerClientEvent('ethr_airbridge:startNow', Flight.host, true, GetPlayers()) resetFlight_new() else
                    if Notify and Notify.ServerAll then Notify.ServerAll('Flugfenster abgelaufen – keine Teilnehmer.','primary') end
                    if not exports['ethorium_dui']:RemoveFlight(Config.Luftfahrzeugkennzeichen) then
                    exports['ethorium_dui']:AddFlight("TEST-123", 0, "Standby")
                    end
                    Flight.active=false; Flight.windowEndsAt=0; Flight.startAt=0
                end
            end
        end)
    else
        local remaining=Flight.windowEndsAt-os.time()
        if Notify and Notify.Server then Notify.Server(src,('Check-in bestätigt. Abflug in ca. %d Min.'):format(math.max(1,math.ceil(remaining/60))),'success') end
    end
end)

-- ===== Host reported plane =====
RegisterNetEvent('ethr_airbridge:reportPlaneNetId', function(netId, seatList)
    local src=source; if src~=Flight.host then return end
    Flight.planeNetId=netId; Flight.seatCandidates=seatList or {}; debug(('Host meldet NetID: %s; Seats: %d'):format(tostring(netId), #Flight.seatCandidates))
    local used={} local function nextFreeSeatInit() for i=1,#Flight.seatCandidates do local s=Flight.seatCandidates[i]; if not used[s] then used[s]=true return s end end return nil end
    for _,p in ipairs(Flight.joinOrder) do if Flight.participants[p] then Flight.assignedSeats[p]=nextFreeSeatInit() end end
    for p,_ in pairs(Flight.participants) do TriggerClientEvent('ethr_airbridge:boardPlane', p, netId, Flight.assignedSeats[p]) end
    ensureBoardingAll()
    startEmptyWatchdog() -- Start server-side empty check
end)

-- ===== Player jumped =====
RegisterNetEvent('ethr_airbridge:playerJumped', function()
    local src=source
    if Flight.participants[src] then Flight.participants[src]=nil end
    if Flight.assignedSeats[src] then Flight.assignedSeats[src]=nil end
    if Flight.boarded[src] then Flight.boarded[src]=nil end
    debug(('Player %d jumped; remaining: %d'):format(src, participantsCount()))
    -- Wenn jetzt leer: guided despawn anstoßen
    if participantsCount()==0 and Flight.host then
        TriggerClientEvent('ethr_airbridge:guidedDespawn', Flight.host)
    end
end)

-- ===== Host says empty (legacy) =====
RegisterNetEvent('ethr_airbridge:flightEmpty', function()
    local src=source; if src~=Flight.host then return end
    debug('Host meldet: Flugzeug leer -> guided despawn an Host.')
    if Flight.host then TriggerClientEvent('ethr_airbridge:guidedDespawn', Flight.host) end
end)

-- ===== Player disconnect =====
AddEventHandler('playerDropped', function()
    local src=source
    if Flight.participants[src] then Flight.participants[src]=nil end
    if Flight.assignedSeats[src] then Flight.assignedSeats[src]=nil end
    if Flight.boarded[src] then Flight.boarded[src]=nil end
    if src==Flight.host and Flight.active then
        debug('Host disconnected -> Hard reset')
        if Notify and Notify.ServerAll then Notify.ServerAll('Flug abgebrochen (Host getrennt).','error') end
        resetFlight_new()
    end
end)

-- ===== Simple command =====
RegisterCommand('airbridge', function(src, args)
    local sub=(args[1] or 'status'):lower()
    if sub=='status' then
        local now=os.time()
        local startIn=Flight.startAt>0 and math.max(Flight.startAt-now,0) or 0
        local windowIn=Flight.windowEndsAt>0 and math.max(Flight.windowEndsAt-now,0) or 0
        TriggerClientEvent('chat:addMessage', src, { args = { ('^3[Airbridge]^7 aktiv:%s cooldown:%s host:%s pax:%d'):format(Flight.active and 'ja' or 'nein', Flight.inCooldown and 'ja' or 'nein', Flight.host or '-', participantsCount()) } })
        if Flight.active then
            if windowIn>0 then TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Sammelfenster endet in: '..tostring(windowIn)..'s' } }) end
            if startIn>0 then TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Geplanter Start in: '..tostring(startIn)..'s' } }) end
        end
        return
    end
    if sub=='start' then
        if Flight.host then TriggerClientEvent('ethr_airbridge:startNow', Flight.host, true, GetPlayers()); TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Startsignal gesendet.' } })
        else TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Kein Host verfügbar.' } }) end
        return
    end
    TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Nutzung: /airbridge status | /airbridge start' } })
end, false)
