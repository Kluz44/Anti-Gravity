local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Creator = {}

--- Create a new Bank / ATM dynamically (Live Update)
function EthoriumBanking.Creator.CreateBank(name, typ, vaultStartBalance, dataObj)
    if not name or not typ then return false, "Invalid bank parameters." end
    
    local dataStr = json.encode(dataObj or {})
    local bal = vaultStartBalance or 0

    local insertId = MySQL.Sync.insert('INSERT INTO ethorium_banks (name, type, vault_balance, data) VALUES (?, ?, ?, ?)', {
        name,
        typ,
        bal,
        dataStr
    })

    if insertId then
        -- Notify all clients to refresh banks mapped
        TriggerClientEvent('ethorium_banking:client:RefreshBanks', -1)
        return true, "Bank Created ID: " .. insertId
    end
    return false, "DB Error"
end

--- Delete a Bank dynamically
function EthoriumBanking.Creator.DeleteBank(bank_id)
    MySQL.Async.execute('DELETE FROM ethorium_banks WHERE id = ?', {bank_id}, function(affected)
        if affected > 0 then
            TriggerClientEvent('ethorium_banking:client:RefreshBanks', -1)
        end
    end)
    return true
end

--- Get all banks (sent to clients upon connection)
function EthoriumBanking.Creator.GetAllBanks()
    return MySQL.Sync.fetchAll('SELECT * FROM ethorium_banks')
end

--- Main Admin Command handling
QBCore.Commands.Add("bankcreator", "Open the Bank Creator UI (Admin Only)", {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    -- In an actual setup check permissions here using QBCore.Functions.HasPermission
    -- Assuming admin rank allowed
    TriggerClientEvent('ethorium_banking:client:OpenCreatorUI', src)
end, "admin")

QBCore.Functions.CreateCallback('ethorium_banking:server:GetBanks', function(source, cb)
    local banks = EthoriumBanking.Creator.GetAllBanks()
    cb(banks)
end)
