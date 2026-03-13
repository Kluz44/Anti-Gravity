local Flights = {} -- table of flight instances, indexed by flightId
local flightCounter = 0
local PendingQueue = {} -- The queue of players waiting to fly
local queueWindowEndsAt = 0 -- When the current open boarding window closes
local activeDispatching = false -- Anti-spam for dispatcher

local function debug(msg) if Config.Debug then print(('[ethr_airbridge][server] %s'):format(msg)) end end

-- ===== Helpers =====
local function createFlightInstance()
    flightCounter = flightCounter + 1
    local flightId = flightCounter
    Flights[flightId] = {
        id = flightId,
        participants = {},
        assignedSeats = {},
        boarded = {},
        host = nil,
        planeNetId = nil,
        joinOrder = {},
        seatCandidates = nil,
        _watchdogActive = false
    }
    return Flights[flightId]
end

local function getFlightForPlayer(src)
    for _, f in pairs(Flights) do
        if f.participants[src] then return f end
    end
    return nil
end

local function participantsCount(f)
    local c=0; for _ in pairs(f.participants) do c=c+1 end; return c
end

local function cleanupFlight(fId)
    Flights[fId] = nil
end

-- ===== DUI Update Helper =====
local function updateDuiState()
    local qCount = #PendingQueue
    if qCount > 0 then
        local paxLimit = Config.MaxPlayersPerFlight or 10
        if queueWindowEndsAt > 0 then
            local remaining = math.max(0, queueWindowEndsAt - os.time())
            if remaining == 0 and activeDispatching then
                exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, 0, "Boarding..")
            else
                exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, remaining, "Check-in")
            end
        else
            exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, 0, "Standby")
        end
    else
        if activeDispatching or next(Flights) then
            exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, Config.FlightCooldownSeconds or 180, "Noch nicht verfügbar")
        else
            exports['ethorium_dui']:AddFlight(Config.Luftfahrzeugkennzeichen, 0, "Standby")
        end
    end
end


local function startEmptyWatchdog(f)
    if f._watchdogActive then return end
    f._watchdogActive = true
    CreateThread(function()
        debug(('Empty-watchdog gestartet für Flight %d.'):format(f.id))
        while Flights[f.id] and f.planeNetId do
            Wait(3000)
            if participantsCount(f) == 0 then
                debug(('Watchdog: keine Teilnehmer mehr für Flight %d -> Guided Despawn an Host.'):format(f.id))
                if f.host then TriggerClientEvent('ethr_airbridge:guidedDespawn', f.host) end
                return
            end
        end
        if Flights[f.id] then f._watchdogActive = false end
    end)
end

-- ===== Client confirms boarded =====
RegisterNetEvent('ethr_airbridge:clientBoarded', function()
    local src = source
    local f = getFlightForPlayer(src)
    if f then
        f.boarded[src] = true
        debug(('Client %d confirmed boarded (Flight %d).'):format(src, f.id))
    end
end)

-- ===== Guided Despawn complete =====
RegisterNetEvent('ethr_airbridge:hostDespawned', function()
    local src = source
    local f = getFlightForPlayer(src)
    if not f or src ~= f.host then return end
    debug(('Host bestätigt: guided despawn für Flight %d abgeschlossen.'):format(f.id))
    cleanupFlight(f.id)
end)

-- ===== Reliable boarding resend =====
local function nextFreeSeatPersistent(f)
    if not f.seatCandidates or #f.seatCandidates == 0 then return nil end
    local used = {} 
    for _, seat in pairs(f.assignedSeats) do if seat ~= nil then used[seat] = true end end
    for i=1, #f.seatCandidates do 
        local s = f.seatCandidates[i]
        if not used[s] then return s end 
    end
    return nil
end

local function ensureBoardingAll(f, retries, intervalMs)
    retries = retries or 10
    intervalMs = intervalMs or 3000
    local attempt = 0
    local function tick()
        if not Flights[f.id] then return end
        attempt = attempt + 1
        if not f.planeNetId then return end
        local pending = {} 
        for p, _ in pairs(f.participants) do 
            if not f.boarded[p] then pending[#pending+1] = p end 
        end
        if #pending == 0 then debug(('All participants boarded for Flight %d.'):format(f.id)); return end
        debug(('Flight %d Boarding retry %d: resending to %d players'):format(f.id, attempt, #pending))
        for _, p in ipairs(pending) do
            if not f.assignedSeats[p] then f.assignedSeats[p] = nextFreeSeatPersistent(f) end
            TriggerClientEvent('ethr_airbridge:boardPlane', p, f.planeNetId, f.assignedSeats[p])
            if Notify and Notify.Server then Notify.Server(p, 'Boarding läuft – du wirst zum Flugzeug gebracht.', 'primary', 3200)
            else TriggerClientEvent('chat:addMessage', p, { args = { '^3[Airbridge]^7 Boarding läuft – du wirst zum Flugzeug gebracht.' } }) end
        end
        if attempt < retries then SetTimeout(intervalMs, tick) end
    end
    SetTimeout(500, tick)
end

-- ===== The Dispatcher (Central logic for generating flights) =====
local function triggerDispatcher()
    if activeDispatching or #PendingQueue == 0 then return end

    activeDispatching = true
    updateDuiState() -- Setzt DUI in "unavailable" oder cooldown state
    debug('Dispatch-Prozess gestartet.')

    -- Wait cooldown if there is an active flight
    if next(Flights) ~= nil then
        debug('Flugzeuge aktiv. Warte auf Cooldown bevor nächstes Flugzeug freigegeben wird.')
        Wait((Config.FlightCooldownSeconds or 180) * 1000)
    end
    
    if #PendingQueue == 0 then 
        activeDispatching = false
        updateDuiState()
        return 
    end

    local paxLimit = Config.MaxPlayersPerFlight or 10
    local nextBatch = {}
    local amountToTake = math.min(paxLimit, #PendingQueue)

    -- Take players from the queue
    for i=1, amountToTake do
        table.insert(nextBatch, table.remove(PendingQueue, 1))
    end
    
    -- Create flight instance
    local f = createFlightInstance()
    for _, src in ipairs(nextBatch) do
        f.participants[src] = true
        f.boarded[src] = false
        table.insert(f.joinOrder, src)
    end

    -- Assign host
    f.host = nextBatch[1]
    
    debug(('Generiere Flight %d für %d Spieler (Host: %d). %d Spieler verbleiben in Queue.'):format(f.id, #nextBatch, f.host, #PendingQueue))

    -- Inform participants
    for _, src in ipairs(nextBatch) do
        if Notify and Notify.Server then Notify.Server(src, 'Dein Flug ist bereit. Boarding beginnt.', 'success') end
    end
    if Notify and Notify.ServerAll then Notify.ServerAll('Flugzeug-Boarding läuft. Bitte bereitmachen.', 'primary', 5000) end

    TriggerClientEvent('ethr_airbridge:hostAssign', f.host, true)
    -- Tell host to spawn plane
    TriggerClientEvent('ethr_airbridge:startNow', f.host, true, GetPlayers())

    activeDispatching = false

    -- If there are still people pending, update DUI to show Cooldown.
    if #PendingQueue > 0 then
        updateDuiState()
        -- Start the next dispatch cycle asynchronously
        CreateThread(function()
            triggerDispatcher()
        end)
    else
        queueWindowEndsAt = 0
        updateDuiState()
    end
end

local function manageQueueWindow()
    if queueWindowEndsAt > 0 then return end -- Already running
    queueWindowEndsAt = os.time() + (Config.CheckInWindowMinutes * 60)
    updateDuiState()
    
    CreateThread(function()
        while os.time() < queueWindowEndsAt and #PendingQueue < (Config.MaxPlayersPerFlight or 10) do
            Wait(1000)
        end
        
        -- Window ended OR full
        if #PendingQueue > 0 then
            triggerDispatcher()
        end
    end)
end


-- ===== Core: Check-In =====
RegisterNetEvent('ethr_airbridge:checkIn', function()
    local src=source
    
    -- Check if player is already in a flight or queue
    if getFlightForPlayer(src) then
        if Notify and Notify.Server then Notify.Server(src,'Du bist bereits auf einem aktiven Flug.','error') end
        return
    end

    for _, p in ipairs(PendingQueue) do
        if p == src then
            if Notify and Notify.Server then Notify.Server(src,'Du bist bereits eingecheckt. Bitte warte auf den Abflug.','error') end
            return
        end
    end

    -- Add to queue
    table.insert(PendingQueue, src)
    
    local paxLimit = Config.MaxPlayersPerFlight or 10
    local position = #PendingQueue

    -- 1. If currently dispatching, just inform them they are in queue for next flight
    if activeDispatching then
        if Notify and Notify.Server then 
            Notify.Server(src, ('Check-in erfolgreich. Position in Warteschlange: %d. Warte auf Cooldown.'):format(position), 'success') 
        end
        return
    end

    -- 2. Start instant
    if Config.StartMode == 'instant' then
        if Notify and Notify.Server then Notify.Server(src, 'Check-in bestätigt.', 'success') end
        if position >= paxLimit then
            triggerDispatcher()
        elseif position == 1 then
            -- Optional start timer for instant if not full yet
            CreateThread(function()
                Wait(15000)
                triggerDispatcher()
            end)
        end
        return
    end

    -- 3. Window Mode
    manageQueueWindow()
    local remaining = math.max(0, queueWindowEndsAt - os.time())
    
    if position >= paxLimit then
        if Notify and Notify.Server then Notify.Server(src, ('Check-in erfolgreich (Limit %d erreicht). Flug wird vorbereitet.'):format(paxLimit), 'success') end
        -- It will auto-trigger because of the manageQueueWindow loop breaking early.
    else
        if Notify and Notify.Server then Notify.Server(src, ('Check-in bestätigt (Warteposition: %d). Abflugfenster schließt in ca. %d Min.'):format(position, math.max(1, math.ceil(remaining/60))), 'success') end
    end
end)

-- ===== Host reported plane =====
RegisterNetEvent('ethr_airbridge:reportPlaneNetId', function(netId, seatList)
    local src=source
    local f = getFlightForPlayer(src)
    if not f or src ~= f.host then return end
    
    f.planeNetId = netId
    f.seatCandidates = seatList or {}
    debug(('Host meldet NetID: %s für Flight %d; Seats: %d'):format(tostring(netId), f.id, #f.seatCandidates))
    
    local used = {} 
    local function nextFreeSeatInit() 
        for i=1, #f.seatCandidates do 
            local s = f.seatCandidates[i]
            if not used[s] then used[s] = true; return s end 
        end 
        return nil 
    end
    
    for _, p in ipairs(f.joinOrder) do 
        if f.participants[p] then f.assignedSeats[p] = nextFreeSeatInit() end 
    end
    
    for p, _ in pairs(f.participants) do 
        TriggerClientEvent('ethr_airbridge:boardPlane', p, netId, f.assignedSeats[p]) 
    end
    
    ensureBoardingAll(f)
    startEmptyWatchdog(f)
end)

-- ===== Player jumped =====
RegisterNetEvent('ethr_airbridge:playerJumped', function()
    local src = source
    local f = getFlightForPlayer(src)
    
    if f then
        f.participants[src] = nil
        f.assignedSeats[src] = nil
        f.boarded[src] = nil
        debug(('Player %d jumped from Flight %d; remaining: %d'):format(src, f.id, participantsCount(f)))
        if participantsCount(f) == 0 and f.host then
            TriggerClientEvent('ethr_airbridge:guidedDespawn', f.host)
        end
    else
        -- Might be in queue
        for i, p in ipairs(PendingQueue) do
            if p == src then table.remove(PendingQueue, i); break end
        end
    end
end)

-- ===== Host says empty (legacy) =====
RegisterNetEvent('ethr_airbridge:flightEmpty', function()
    local src = source
    local f = getFlightForPlayer(src)
    if f and f.host == src then
        debug(('Host meldet: Flight %d leer -> guided despawn an Host.'):format(f.id))
        TriggerClientEvent('ethr_airbridge:guidedDespawn', f.host)
    end
end)

-- ===== Player disconnect =====
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Remove from queue
    for i, p in ipairs(PendingQueue) do
        if p == src then 
            table.remove(PendingQueue, i)
            return
        end
    end

    local f = getFlightForPlayer(src)
    if f then
        f.participants[src] = nil
        f.assignedSeats[src] = nil
        f.boarded[src] = nil
        
        if src == f.host then
            debug(('Host disconnected from Flight %d -> Attempting Host Migration...'):format(f.id))
            
            local newHost = nil
            for p, _ in pairs(f.participants) do
                if p ~= src then newHost = p; break end
            end

            if newHost then
                f.host = newHost
                debug(('Flight %d: Host Migrated to Player %d.'):format(f.id, newHost))
                if Notify and Notify.Server then Notify.Server(newHost, 'Du hast versehentlich die Steuerung übernommen (Der Flugkapitän ist abgestürzt). Du bist nun der Host für diesen Flug.', 'inform') end
                TriggerClientEvent('ethr_airbridge:hostMigration', newHost, f.planeNetId)
            else
                debug(('Flight %d: No more passengers left for Host Migration -> Hard reset for this instance'):format(f.id))
                if Notify and Notify.ServerAll then Notify.ServerAll('Ein laufender Flug wurde abgebrochen (Flugzeug leer).', 'error') end
                
                -- Delete the plane via server side brute force if needed by broadcasting to whoever is still alive
                TriggerClientEvent('ethr_airbridge:forceDespawn', -1, f.planeNetId)
                cleanupFlight(f.id)
            end
        end
    end
end)

-- ===== Simple command =====
RegisterCommand('airbridge', function(src, args)
    local sub = (args[1] or 'status'):lower()
    if sub == 'status' then
        local activeCount = 0
        for _ in pairs(Flights) do activeCount = activeCount + 1 end
        TriggerClientEvent('chat:addMessage', src, { args = { ('^3[Airbridge]^7 Queue: %d | Aktive Flüge: %d | Dispatching: %s'):format(#PendingQueue, activeCount, tostring(activeDispatching)) } })
        if queueWindowEndsAt > 0 then
            local windowIn = math.max(0, queueWindowEndsAt - os.time())
            TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Aktuelles Boarding endet in: '..tostring(windowIn)..'s' } })
        end
        return
    end
    if sub == 'start' then
        if #PendingQueue > 0 and not activeDispatching then
            queueWindowEndsAt = 0 -- Force end
            triggerDispatcher()
            TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Force start signal gesendet.' } })
        else
            TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Nichts zu starten oder bereits Dispatch im Gange.' } })
        end
        return
    end
    TriggerClientEvent('chat:addMessage', src, { args = { '^3[Airbridge]^7 Nutzung: /airbridge status | /airbridge start' } })
end, false)
