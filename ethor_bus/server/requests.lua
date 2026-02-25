-- =============================================
-- Stop Request System (Phase 2)
-- =============================================

RegisterCommand('busstoprequest', function(source, args)
    local src = source
    local player = AG.GetPlayer(src)
    
    if not args or #args < 2 then
        AG.Notify.Show(src, 'Nutzung: /busstoprequest [Name] [Grund]', 'error')
        return
    end
    
    local name = args[1]
    
    -- Rebuild the comment string
    local commentParts = {}
    for i = 2, #args do
        table.insert(commentParts, args[i])
    end
    local comment = table.concat(commentParts, " ")
    
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local head = GetEntityHeading(ped)
    
    local cData = {x = coords.x, y = coords.y, z = coords.z, h = head}
    
    -- In a full implementation, you'd get the actual companyId from the user's job.
    -- For now, we assume the default company (ID 1)
    local companyId = 1
    
    MySQL.insert('INSERT INTO bus_requests (company_id, coords, name, comment) VALUES (?, ?, ?, ?)', {
        companyId,
        json.encode(cData),
        name,
        comment
    }, function(id)
        if id then
            AG.Notify.Show(src, 'Haltestellen-Anfrage eingereicht!', 'success')
            if Config.Debug then print('^2[ethor_bus] ^7Stop Request '..id..' ('..name..') saved.') end
        end
    end)
end, false) -- Unrestricted command so Bosses can use it

-- Admin Fetch Requests
RegisterNetEvent('ethor_bus:server:FetchRequests', function()
    local src = source
    if not IsPlayerAceAllowed(src, 'command.buscreate') then return end
    
    local reqs = MySQL.query.await('SELECT * FROM bus_requests WHERE status = ?', {'pending'})
    
    -- You can trigger an admin client event here to display them in a list or print to console
    if #reqs > 0 then
        AG.Notify.Show(src, 'Es gibt ' .. #reqs .. ' offene Haltestellen-Anfragen.', 'info')
    end
end)
