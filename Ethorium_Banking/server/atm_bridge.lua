local QBCore = exports['qb-core']:GetCoreObject()

RRP = RRP or {}
RRP.Locale = {}
function RRP.Locale.LoadLocale(lang) end
function RRP.Locale.T(key) return key end -- Simplistic fallback for locales since they are managed inside the script

RRP.Callback = {}
function RRP.Callback.Register(name, cb)
    QBCore.Functions.CreateCallback(name, function(source, defaultCb, ...)
        cb(source, ...)
        -- Wait, RRP.Callback register might expect the callback to return a value statically or via promise.
        -- Actually, QBCore uses cb(result).
        -- Let's look at how rrp callback uses it based on server script:
        -- RRP.Callback.Register('name', function(source, hType, ...) return data end)
    end)
end

-- Proper Callback Registration wrapper matching esx/qb-core
QBCore.Functions.CreateCallback('qb_realistic_atm:callbacks', function(source, cb, hType, ...)
    -- We can't easily hook into mysterious RRP.Callback.Register from the original file unless we override it carefully.
    -- Better is to let them register it in our fake object, and we execute it.
end)

-- Let's define the FULL RRP Server Mock
RRP = {
    Getters = {
        GetPlayerFromId = function(src) return QBCore.Functions.GetPlayer(src) end
    },
    GetPlayer = function(src) return QBCore.Functions.GetPlayer(src) end,
    GetIdentifier = function(src) 
        local p = QBCore.Functions.GetPlayer(src)
        return p and p.PlayerData.citizenid or nil
    end,
    Banking = {
        GetCashBalance = function(src)
            local p = QBCore.Functions.GetPlayer(src)
            return p and p.PlayerData.money['cash'] or 0
        end,
        GetBankBalance = function(src)
            local p = QBCore.Functions.GetPlayer(src)
            return p and p.PlayerData.money['bank'] or 0
        end,
        RemoveCash = function(src, amount)
            local p = QBCore.Functions.GetPlayer(src)
            if p then p.Functions.RemoveMoney('cash', amount, "atm") end
        end,
        AddCash = function(src, amount)
            local p = QBCore.Functions.GetPlayer(src)
            if p then p.Functions.AddMoney('cash', amount, "atm") end
        end,
        RemoveBank = function(src, amount)
            local p = QBCore.Functions.GetPlayer(src)
            if p then
                local iban = EthoriumBanking.Server.GetPersonalIban(p.PlayerData.citizenid)
                if iban then
                    EthoriumBanking.Server.ProcessMoneyMovement(iban, amount, false, "atm_withdraw", "ATM Withdrawal")
                else
                    p.Functions.RemoveMoney('bank', amount, "atm")
                end
            end
        end,
        AddBank = function(src, amount)
            local p = QBCore.Functions.GetPlayer(src)
            if p then
                local iban = EthoriumBanking.Server.GetPersonalIban(p.PlayerData.citizenid)
                if iban then
                    EthoriumBanking.Server.ProcessMoneyMovement(iban, amount, true, "atm_deposit", "ATM Deposit")
                else
                    p.Functions.AddMoney('bank', amount, "atm")
                end
            end
        end
    },
    Inventory = {
        SearchItemsByName = function(src, name)
            local p = QBCore.Functions.GetPlayer(src)
            if p then
                -- Return array of items matching name
                local items = p.Functions.GetItemsByName(name)
                if not items then return {} end
                if #items > 0 then return items else return {items} end
            end
            return {}
        end,
        GetItemMeta = function(item)
            return item.info or {}
        end,
        RegisterUsableItem = function(name, cb)
            QBCore.Functions.CreateUseableItem(name, function(source, item)
                cb(source, item)
            end)
        end
    },
    Notify = function(sys, src, msg)
        TriggerClientEvent('QBCore:Notify', src, msg)
    end
}

-- Handle RRP Callback Registration
RRP.Callback = {}
local registeredCallbacks = {}
function RRP.Callback.Register(name, func)
    registeredCallbacks[name] = func
    QBCore.Functions.CreateCallback(name, function(source, cb, ...)
        local result = func(source, ...)
        cb(result)
    end)
end

-- Helper for Ethorium Iban
EthoriumBanking.Server.GetPersonalIban = function(citizenid)
    local result = MySQL.Sync.fetchAll('SELECT iban FROM ethorium_accounts WHERE citizenid = ? AND type = ?', {citizenid, 'personal'})
    if #result > 0 then return result[1].iban end
    return nil
end
