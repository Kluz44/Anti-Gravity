local QBCore = exports['qb-core']:GetCoreObject()

--- Function to open unified Bank UI
local function OpenBankUI(tab)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openBanking",
        tab = tab or "dashboard"
    })
end

--- Integration of qs-interact equivalent target points for NPCs
-- Target interaction options based on PROMPT definition (Konto eröffnen, Einzahlen, Auszahlen, Kontostand, Rechnungen, Karten, Kredit)
local BankingInteractionOptions = {
    {
        label = "Konto eröffnen",
        icon = "fas fa-user-plus",
        action = function()
            OpenBankUI("create_account")
        end
    },
    {
        label = "Einzahlen",
        icon = "fas fa-arrow-up",
        action = function()
            -- Flow: 1. Konto wählen, 2. Betrag eingeben, 3. Bargeld prüfen, 4. bestätigen
            OpenBankUI("deposit")
        end
    },
    {
        label = "Auszahlen",
        icon = "fas fa-arrow-down",
        action = function()
            -- Flow: 1. Konto wählen, 2. Betrag eingeben, 3. prüfen (Konto / Tresor), 4. bestätigen
            OpenBankUI("withdraw")
        end
    },
    {
        label = "Kontostand",
        icon = "fas fa-wallet",
        action = function()
            OpenBankUI("balance")
        end
    },
    {
        label = "Rechnungen (Invoices)",
        icon = "fas fa-file-invoice-dollar",
        action = function()
            OpenBankUI("invoices")
        end
    },
    {
        label = "Bankkarten",
        icon = "fas fa-credit-card",
        action = function()
            OpenBankUI("cards")
        end
    },
    {
        label = "Kredit beantragen",
        icon = "fas fa-money-check-alt",
        action = function()
            OpenBankUI("loans")
        end
    }
}

--- Inject Interaction options to dynamically created NPCS
--- Prompt requirement: qs-interact not bridged, native injection.
function EthoriumBankingC.AddBankInteraction(entityId, npcName)
    -- We use our natively integrated system that behaves identical to qs-interact 
    -- but exists natively inside this resource to avoid bridging an export.
    EthoriumBankingC.RegisterBankNPC(entityId, npcName or "Bank Mitarbeiter", BankingInteractionOptions)
end

-- Wait to setup targets defined in DB
RegisterNetEvent('ethorium_banking:client:SyncInteractions', function(npcs)
    for _, pedData in ipairs(npcs) do
        -- Spawn Ped
        -- Apply EthoriumBankingC.AddBankInteraction(ped)
    end
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('bankAction', function(data, cb)
    local action = data.action
    local amount = tonumber(data.amount)
    
    if action == "deposit" then
        QBCore.Functions.TriggerCallback('ethorium_banking:server:Deposit', function(success, msg)
            if success then QBCore.Functions.Notify("Deposited $"..amount, "success") else QBCore.Functions.Notify(msg, "error") end
            cb(success)
        end, amount)
    elseif action == "withdraw" then
        QBCore.Functions.TriggerCallback('ethorium_banking:server:Withdraw', function(success, msg)
            if success then QBCore.Functions.Notify("Withdrew $"..amount, "success") else QBCore.Functions.Notify(msg, "error") end
            cb(success)
        end, amount)
    end
end)
