local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBankingC = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Initialize banking logic, fetch banks
    QBCore.Functions.TriggerCallback('ethorium_banking:server:GetBanks', function(banks)
        EthoriumBankingC.InitBanks(banks)
    end)
end)

RegisterNetEvent('ethorium_banking:client:RefreshBanks', function()
    QBCore.Functions.TriggerCallback('ethorium_banking:server:GetBanks', function(banks)
        EthoriumBankingC.InitBanks(banks)
    end)
end)

function EthoriumBankingC.InitBanks(banks)
    print("[Ethorium Banking] Banks Loaded: " .. #banks)
    -- Here we would parse 'banks' which contain data (JSON) of Peds and Interaction points.
    -- Since the prompt specifies 'qs-interact' integrated native source code,
    -- we handle this in interact.lua using exports or exact native code.
end
