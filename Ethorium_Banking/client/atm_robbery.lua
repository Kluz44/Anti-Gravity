local QBCore = exports['qb-core']:GetCoreObject()

-- ATM Robbery / Vault logic client side
-- Triggered generally by an item use (like a vault hook)

RegisterNetEvent('ethorium_banking:client:UseVaultHook', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    -- Check nearest bank from cached list (EthoriumBankingC.InitBanks)
    -- Start minigame, alarm
    -- TriggerServerEvent('ethorium_banking:server:TriggerAlarm', bankId)
    -- TriggerServerEvent('ethorium_banking:server:VaultRobbed', bankId)
    print("Vault Hook Used. Implement Minigame here.")
end)
