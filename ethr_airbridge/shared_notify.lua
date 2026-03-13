Notify = {}

local function chat(msg)
    TriggerEvent('chat:addMessage', { args = { '^3[Airbridge]^7 ' .. msg } })
end

local function mapType(system, t)
    t = (t or 'inform'):lower()

    if system == 'qb' then
        -- QBCore kennt i.d.R.: primary, success, error
        if t == 'inform' or t == 'info' or t == 'notice' then return 'primary' end
        if t == 'warning' or t == 'warn' then return 'primary' end
        if t == 'success' or t == 'error' then return t end
        return 'primary'
    elseif system == 'okok' then
        -- okokNotify: success, info, warning, error
        if t == 'inform' or t == 'primary' or t == 'notice' then return 'info' end
        if t == 'warn' then return 'warning' end
        if t == 'success' or t == 'error' then return t end
        return 'info'
    elseif system == 'myth' then
        -- mythic_notify: success, inform, error, (optional: warning)
        if t == 'primary' or t == 'info' or t == 'notice' then return 'inform' end
        if t == 'warn' then return 'warning' end
        if t == 'success' or t == 'error' or t == 'inform' then return t end
        return 'inform'
    elseif system == 'ox' then
        -- ox_lib: types sind frei wählbar; wir normalisieren auf info/success/error
        if t == 'inform' or t == 'primary' or t == 'info' or t == 'notice' then return 'info' end
        if t == 'warn' or t == 'warning' then return 'warning' end
        if t == 'success' or t == 'error' then return t end
        return 'info'
    end

    -- Chat-Fallback
    return 'info'
end

function Notify.Client(msg, type, duration)
    local sys = (Config.NotifySystem or 'print')
    local t = mapType(sys, type)
    local dur = duration or 5000

    if sys == 'qb' then
        local ok, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and QBCore and QBCore.Functions and QBCore.Functions.Notify then
            -- QBCore nimmt (text, type, length)
            QBCore.Functions.Notify(msg, t, math.ceil(dur/1000)*1000)
            return
        end
    elseif sys == 'okok' and exports['okokNotify'] then
        exports['okokNotify']:Alert('Airbridge', msg, dur, t) -- t gemappt auf okok-Typen
        return
    elseif sys == 'myth' then
        -- Mythic: type = success/inform/error/warning
        TriggerEvent('mythic_notify:client:SendAlert', { type = t, text = msg, length = dur })
        return
    elseif sys == 'ox' then
        if lib and lib.notify then
            lib.notify({ title = 'Airbridge', description = msg, type = t, duration = dur })
            return
        end
    end

    chat(msg)
end

function Notify.Server(src, msg, type, duration)
    TriggerClientEvent('ethr_airbridge:notify', src, msg, type, duration or 5000)
end

function Notify.ServerAll(msg, type, duration)
    TriggerClientEvent('ethr_airbridge:notify', -1, msg, type, duration or 5000)
end
