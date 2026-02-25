-- =============================================
-- Advertising System (Phase 3)
-- =============================================

local activeAdsCache = {}

-- Fetch active ads into memory
local function RefreshAdsCache()
    local ads = MySQL.query.await('SELECT id, image_url, company_id FROM bus_ads WHERE is_active = 1')
    if ads then
        activeAdsCache = ads
    else
        activeAdsCache = {}
    end
end

CreateThread(function()
    Wait(2000)
    RefreshAdsCache()
end)

local function IsUrlWhitelisted(url)
    for _, domain in ipairs(Config.Ads.WhitelistDomains) do
        -- Simple check if the domain is in the URL
        if string.find(url, domain, 1, true) then
            return true
        end
    end
    return false
end

-- Boss/Admin command to add an ad
RegisterCommand('busaddad', function(source, args)
    local src = source
    if not IsPlayerAceAllowed(src, 'command.buscreate') then return end -- Using admin check for now
    
    if not args or #args < 1 then
        AG.Notify.Show(src, 'Nutzung: /busaddad [URL]', 'error')
        return
    end
    
    local url = args[1]
    
    if not IsUrlWhitelisted(url) then
        AG.Notify.Show(src, 'Diese URL-Domain ist nicht auf der Whitelist!', 'error')
        return
    end
    
    -- In a real scenario, this gets the DB company ID linked to the player's society job
    -- We assume company ID 1 exists as created in import.lua
    local companyId = 1
    
    MySQL.insert('INSERT INTO bus_ads (company_id, image_url, is_active) VALUES (?, ?, 1)', {companyId, url}, function(id)
        if id then
            AG.Notify.Show(src, 'Werbung erfolgreich hinzugefügt.', 'success')
            RefreshAdsCache()
            -- Broadcast immediately to all clients to update their UI
            TriggerClientEvent('ethor_bus:client:SyncAds', -1, activeAdsCache)
        end
    end)
end, false)

-- Client requests ads on join
RegisterNetEvent('ethor_bus:server:RequestAds', function()
    TriggerClientEvent('ethor_bus:client:SyncAds', source, activeAdsCache)
end)
