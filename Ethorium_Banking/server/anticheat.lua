local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Security = {}

-- Already implemented core anti-cheat in core.lua (TraceID + Source checking).
-- This file implements strict overriding of QBCore money functions if needed,
-- or exposes an event to alert admins if scripts try to bypass Ethorium.

-- Optional: Overriding AddMoney and RemoveMoney
-- NOTE: Replacing QBCore internal functions via direct metamethods is risky,
-- A safer approach is providing an explicit export that other resources *must* use,
-- and running a cron job or event listener to catch standalone "give money" events.

RegisterNetEvent('ethorium_banking:server:AntiCheatAlert', function(details, suspectId)
    local src = source
    if suspectId then src = suspectId end

    EthoriumBanking.Server.Log("admin", "ANTI-CHEAT TRIGGERED", "Player ID: " .. src .. "\nDetails: " .. details, 16711680)
    print("^1[Ethorium AntiCheat] Player " .. src .. " flagged: " .. details .. "^0")
end)

-- The majority of anti-cheat rules (TraceID requirement, Valid Sources only, no direct balance setting)
-- are enforced directly inside the EthoriumBanking.Server.CreateTransaction function in core.lua.

exports("TriggerAntiCheat", function(details, suspectId)
    TriggerEvent('ethorium_banking:server:AntiCheatAlert', details, suspectId)
end)
