local USED_ATMs = {}
local PLAYERS_CACHE = {}
local DAILY_TRANSACTIONS = {}
local function resetDailyTransactions()
    DAILY_TRANSACTIONS = {}
end

local function getCurrentDate()
    return os.date('%Y-%m-%d')
end

local function updateDailyTransactions(identifier, amount, transactionType)
    local date = getCurrentDate()
    if not DAILY_TRANSACTIONS[identifier] then
        DAILY_TRANSACTIONS[identifier] = {}
    end
    if not DAILY_TRANSACTIONS[identifier][date] then
        DAILY_TRANSACTIONS[identifier][date] = { deposit = { count = 0, amount = 0 }, withdraw = { count = 0, amount = 0 } }
    end
    if not DAILY_TRANSACTIONS[identifier][date][transactionType] then
        DAILY_TRANSACTIONS[identifier][date][transactionType] = { count = 0, amount = 0 }
    end
    DAILY_TRANSACTIONS[identifier][date][transactionType].count = DAILY_TRANSACTIONS[identifier][date][transactionType]
    .count + 1
    DAILY_TRANSACTIONS[identifier][date][transactionType].amount = DAILY_TRANSACTIONS[identifier][date][transactionType]
    .amount + amount
end

local function canPerformTransaction(identifier, amount, transactionType)
    local date = getCurrentDate()
    if not DAILY_TRANSACTIONS[identifier] or not DAILY_TRANSACTIONS[identifier][date] then
        return true, true -- No transactions yet, free transaction
    end
    local transactionData = DAILY_TRANSACTIONS[identifier][date][transactionType]
    if not transactionData then
        DAILY_TRANSACTIONS[identifier][date][transactionType] = { count = 0, amount = 0 }
        return true, true -- No transactions of this type yet, free transaction
    end
    if Config.Tax[transactionType].DailyLimit ~= -1 and transactionData.count >= Config.Tax[transactionType].DailyLimit then
        return false, 'daily_trans_limit'
    end
    if Config.Tax[transactionType].DailyLimitAmount ~= -1 and transactionData.amount + amount > Config.Tax[transactionType].DailyLimitAmount then
        return false, 'daily_trans_amount'
    end
    if transactionData.count >= Config.Tax[transactionType].FreeTransactions then
        return true, false -- Exceeded free transactions, taxable
    end
    if transactionData.amount + amount > Config.Tax[transactionType].Free then
        return true, false -- Exceeded free amount, taxable
    end
    return true, true      -- Free transaction
end

local callbacks = {
    useATM = function(source, coordsString, needPin)
        if USED_ATMs[coordsString] then
            local playerId = USED_ATMs[coordsString].source
            if RRP.Getters.GetPlayerFromId(playerId) then
                return false
            else
                if DoesEntityExist(USED_ATMs[coordsString].cardObj) then
                    DeleteEntity(USED_ATMs[coordsString].cardObj)
                end
                if DoesEntityExist(USED_ATMs[coordsString].moneyObj) then
                    DeleteEntity(USED_ATMs[coordsString].moneyObj)
                end
                PLAYERS_CACHE[playerId] = nil
                USED_ATMs[coordsString] = nil
            end
        end
        USED_ATMs[coordsString] = {
            source = source,
            coordsString = coordsString,
            cardObj = nil,
            moneyObj = nil,
        }
        PLAYERS_CACHE[source] = coordsString

        if needPin then
            if Framework == "esx" or Config.PinInDB then
                local pincode = MySQL.Sync.fetchScalar('SELECT `pincode` FROM users WHERE identifier = ?', { identifier })
                pincode = tostring(pincode)
                return true, {
                    money = RRP.Banking.GetCashBalance(source),
                    bank = RRP.Banking.GetBankBalance(source),
                    pincodeHash = GetHashKey(pincode),
                }
            else
                local pins = {}
                local cards= RRP.Inventory.SearchItemsByName(source, Config.ItemName)
                for i=1, #cards, 1 do
                    pins[i] = GetHashKey(RRP.Inventory.GetItemMeta(cards[i]).cardPin)
                end
                return true, {
                    money = RRP.Banking.GetCashBalance(source),
                    bank = RRP.Banking.GetBankBalance(source),
                    pins = pins,
                }
            end
        else
            return true, {
                money = RRP.Banking.GetCashBalance(source),
                bank = RRP.Banking.GetBankBalance(source),
            }
        end
    
       
    end,
    changePin = function(source, newPin, cardNumber)
        local xPlayer = RRP.GetPlayer(source)
        newPin = tonumber(newPin)
        if not newPin then
            return false
        end
        if #tostring(newPin) ~= 4 then
            print("Pincode must be 4 digits long...")
            return false
        end
        if not cardNumber then
            print("Cardnumber is missing...")
            return false
        end

        local cards = RRP.Inventory.SearchItemsByName(source, Config.ItemName)
        for _, card in ipairs(cards) do
            if RRP.Inventory.GetItemMeta(card).cardNumber == cardNumber then
                local item = xPlayer.PlayerData.items[card.slot]
                RRP.Inventory.GetItemMeta(item).cardPin = newPin
                xPlayer.Functions.SetInventory(xPlayer.PlayerData.items, true)
                return true
            end
        end
        return false
    end,
    deposit = function(source, amount)
        local identifier = RRP.GetIdentifier(source)
        local money = RRP.Banking.GetCashBalance(source)

        if amount < Config.Tax.Deposit.Min or amount > Config.Tax.Deposit.Max then
            --notify(source, 'Invalid deposit amount')
            return false, "inv_amount"
        end

        if money < amount then
            --notify(source, 'You do not have enough money')
            return false, "not_enough_cash"
        end

        local canPerform, isFree = canPerformTransaction(identifier, amount, 'Deposit')
        if not canPerform then
            --notify(source, isFree)
            return false, isFree
        end

        local tax = 0
        if not isFree then
            tax = math.max(Config.Tax.Deposit.MinTax, amount * Config.Tax.Deposit.Percent)
        end

        if money < amount + tax and not Config.Tax.Deposit.CanMinus then
            --notify(source, 'You do not have enough money to cover the tax')
            return false, "not_enough_cash_tax"
        end
        RRP.Banking.RemoveCash(source, amount + tax)
        RRP.Banking.AddBank(source, amount)
        updateDailyTransactions(identifier, amount, 'Deposit')
        --notify(source, 'You have deposited $%d with a tax of $%d', amount, tax)
        TransActionLogger.logDeposit(source, 'checking', amount, 'DEPOSIT', 'deposit', 'player')
        if tax > 0 then
            TransActionLogger.logWithdraw(source, 'checking', tax, 'TAX', 'withdraw', 'player')
        end
        return true
    end,
    withdraw = function(source, amount)
        local identifier = RRP.GetIdentifier(source)
        local bank = RRP.Banking.GetBankBalance(source)

        if amount < Config.Tax.Withdraw.Min or amount > Config.Tax.Withdraw.Max then
            --notify(source, 'Invalid withdrawal amount')
            return false, "inv_amount"
        end

        if bank < amount then
            --notify(source, 'You do not have enough money in your bank')
            return false, "not_enough_bank"
        end

        local canPerform, isFree = canPerformTransaction(identifier, amount, 'Withdraw')
        if not canPerform then
            --notify(source, isFree)
            return false, isFree
        end

        local tax = 0
        if not isFree then
            tax = math.max(Config.Tax.Withdraw.MinTax, amount * Config.Tax.Withdraw.Percent)
        end

        if bank < amount + tax and not Config.Tax.Withdraw.CanMinus then
            --notify(source, 'You do not have enough money in your bank to cover the tax')
            return false, "not_enough_bank_tax"
        end

        RRP.Banking.RemoveBank(source, amount + tax)
        RRP.Banking.AddCash(source, amount)
        updateDailyTransactions(identifier, amount, 'Withdraw')
        --notify(source, 'You have withdrawn $%d with a tax of $%d', amount, tax)
        TransActionLogger.logWithdraw(source, 'checking', amount, 'WITHDRAW', 'withdraw', 'player')
            --exports['qb-banking']:CreateBankStatement(source, 'checking', amount, 'WITHDRAW', 'withdraw', 'player')
        if tax > 0 then
            TransActionLogger.logWithdraw(source, 'checking', tax, 'TAX', 'withdraw', 'player')
            --exports['qb-banking']:CreateBankStatement(source, 'checking', tax, 'TAX', 'withdraw', 'player')
        end
       
        return true
    end
}

if Framework == "esx" then
    callbacks.changePin = ESXOverride.changePin
end

if Config.QbBankingAccountSelector then
    callbacks.getAccountsData = function(src) 
        local Player = RRP.GetPlayer(src)
        local identifier = Player.PlayerData.citizenid
        local function getAccounts()
            local job = Player.PlayerData.job
            local gang = Player.PlayerData.gang
            if job.isboss or gang.isboss then
                local sharedAccounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE citizenid = ? OR JSON_CONTAINS(users, ?) OR account_name = ? OR account_name = ?', { identifier, json.encode(identifier), job.name, gang.name })
                return sharedAccounts
            elseif job.isboss then
                local sharedAccounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE citizenid = ? OR JSON_CONTAINS(users, ?) OR account_name = ?', { identifier, json.encode(identifier), job.name })
                return sharedAccounts
            elseif gang and gang.isboss then
                local sharedAccounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE citizenid = ? OR JSON_CONTAINS(users, ?) OR account_name = ?', { identifier, json.encode(identifier), gang.name })
                return sharedAccounts
            else
                local sharedAccounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE citizenid = ? OR JSON_CONTAINS(users, ?)', { identifier, json.encode(identifier) })
                return sharedAccounts
            end
        end

        local sharedAccounts = getAccounts()
        local accounts = {
            {account_name = 'checking', account_type = 'checking', account_balance = Player.PlayerData.money.bank, id = src}
        }
        if sharedAccounts then
            for _, account in ipairs(sharedAccounts) do
                accounts[#accounts + 1] = {
                    id = account.id,
                    account_name = account.account_name,
                    account_type = account.account_type,
                    account_balance = account.account_balance,
                }
            end
        end
        return accounts
    end
    callbacks.sharedAccountDeposit = function(src, acc, amount)
        local accountName = acc.account_name
        local accountType = acc.account_type
        local account = exports['qb-banking']:GetAccount(accountName)
        if not account then print("account not found") return false end
        if account.account_type ~= accountType then return false end

        local Player = RRP.GetPlayer(src)
        local money  = RRP.Banking.GetCashBalance(src)
        local hasPermission = false
        if accountType == "job" then
            local job = Player.PlayerData.job
           hasPermission = job.isboss
        elseif accountType == "shared" then
            if account.citizenid == Player.PlayerData.citizenid then
                hasPermission = true
            end
            if not hasPermission then
                if string.find(account.users, Player.PlayerData.citizenid) then
                    hasPermission = true
                end
            end
        elseif accountType == "gang" then
            local gang = Player.PlayerData.gang
            hasPermission = gang.isboss
        end
        if not hasPermission then print("no perm") return false end


        if amount < Config.Tax.Deposit.Min or amount > Config.Tax.Deposit.Max then
            return false
        end

        if money < amount then
            return false
        end

        local canPerform, isFree = canPerformTransaction(accountName, amount, 'Deposit')
        if not canPerform then
            return false
        end

        local tax = 0
        if not isFree then
            tax = math.max(Config.Tax.Deposit.MinTax, amount * Config.Tax.Deposit.Percent)
        end

        if money < amount + tax and not Config.Tax.Deposit.CanMinus then
            return false
        end

        Player.Functions.RemoveMoney('cash', amount)
        exports['qb-banking']:AddMoney(accountName, amount, Player.PlayerData.name)
        updateDailyTransactions(accountName, amount, 'Deposit')
        exports['qb-banking']:CreateBankStatement(src, accountName, amount, 'DEPOSIT', 'deposit', 'player')
        if tax > 0 then
            exports['qb-banking']:CreateBankStatement(src, accountName, tax, 'TAX', 'deposit', 'player')
        end
        return true
    end
    callbacks.sharedAccountWithdraw = function(src, acc, amount)
        local accountName = acc.account_name
        local accountType = acc.account_type
        local account = exports['qb-banking']:GetAccount(accountName)
        if not account then return false end
        if account.account_type ~= accountType then return false end
        local Player = RRP.GetPlayer(src)
        local hasPermission = false
        if accountType == "job" then
            local job = Player.PlayerData.job
            hasPermission = job.isboss
        elseif accountType == "shared" then
            if account.citizenid == Player.PlayerData.citizenid then
                hasPermission = true
            end
            if not hasPermission then
                if string.find(account.users, Player.PlayerData.citizenid) then
                    hasPermission = true
                end
            end
        elseif accountType == "gang" then
            local gang = Player.PlayerData.gang
            hasPermission = gang.isboss
        end
        if not hasPermission then return false end
        if amount < Config.Tax.Withdraw.Min or amount > Config.Tax.Withdraw.Max then
            return false
        end
        if account.account_balance < amount then
            return false
        end
        local canPerform, isFree = canPerformTransaction(accountName, amount, 'Withdraw')
        if not canPerform then
            return false
        end
        local tax = 0
        if not isFree then
            tax = math.max(Config.Tax.Withdraw.MinTax, amount * Config.Tax.Withdraw.Percent)
        end
        if account.account_balance < amount + tax and not Config.Tax.Withdraw.CanMinus then
            return false
        end

        Player.Functions.AddMoney('cash', amount)
        exports['qb-banking']:RemoveMoney(accountName, amount, Player.PlayerData.name)
        updateDailyTransactions(accountName, amount, 'Withdraw')
        exports['qb-banking']:CreateBankStatement(src, accountName, amount, 'WITHDRAW', 'withdraw', 'player')
        if tax > 0 then
            exports['qb-banking']:CreateBankStatement(src, accountName, tax, 'TAX', 'withdraw', 'player')
        end
        return true
    end
    callbacks.sharedAccountGetBalance = function(src, acc)
        local accountName = acc.account_name
        local accountType = acc.account_type
        local account = exports['qb-banking']:GetAccount(accountName)
        if not account then return false end
        if account.account_type ~= accountType then return false end
        return account.account_balance
    end
end

if Framework == "esx" then
    RRP.Inventory.RegisterUsableItem(Config.ItemName, function(source, item)
        if RRP.Inventory.GetItemMeta(item).cardPin == nil then
            print("pincode is missing...")
            return
        end
        local identifier = RRP.GetIdentifier(source)
        local pincode = MySQL.Sync.fetchScalar('SELECT `pincode` FROM users WHERE identifier = ?', { identifier })
        pincode = tostring(pincode)
        TriggerClientEvent('qb_realistic_atm:openATM', source, GetHashKey(pincode), nil)
    end)
else
    RRP.Inventory.RegisterUsableItem(Config.ItemName, function(source, item)
        if RRP.Inventory.GetItemMeta(item).cardPin == nil then
            print("pincode is missing...")
            return
        end
        local identifier = RRP.GetIdentifier(source)
        local itemMeta = RRP.Inventory.GetItemMeta(item)
        if identifier ~= itemMeta.citizenid then
            RRP.Notify(Config.NotifySystem, source, RRP.Locale.T('card_not_yours'))
            return
        end
        TriggerClientEvent('qb_realistic_atm:openATM', source, GetHashKey(itemMeta.cardPin), itemMeta.cardNumber)
    end)
end



local handlers = {
    exitATM = function(source, atm)
        if not USED_ATMs[atm] then return end
        if USED_ATMs[atm].source == source then
            USED_ATMs[atm] = nil
            PLAYERS_CACHE[source] = nil
        end
    end,
    regCard = function(source, atm, cardObj)
        if not USED_ATMs[atm] then return end
        if USED_ATMs[atm].source == source then
            USED_ATMs[atm].cardObj = cardObj
        end
    end,
    regMoney = function(source, atm, moneyObj)
        if not USED_ATMs[atm] then return end
        if USED_ATMs[atm].source == source then
            USED_ATMs[atm].moneyObj = moneyObj
        end
    end
}

if not Config.AnimSettings.InsertCard.Object then
    if not Config.AnimSettings.InsertCard.IsLocal then
        handlers.regCard = nil
    end
end

if not Config.AnimSettings.MoneyDepositAndWithdraw.Object then
    if not Config.AnimSettings.MoneyDepositAndWithdraw.IsLocal then
        handlers.regMoney = nil
    end
end

RegisterNetEvent('qb_realistic_atm:handlers', function(hType, ...)
    local src = source
    if not handlers[hType] then
        return
    end
    return handlers[hType](src, ...)
end)

RRP.Callback.Register('qb_realistic_atm:callbacks', function(source, hType, ...)
    if not callbacks[hType] then
        return false
    end
    return callbacks[hType](source, ...)
end)

if Config.AnimSettings.InsertCard.Object or Config.AnimSettings.MoneyDepositAndWithdraw.Object then
    AddEventHandler('playerDropped', function()
        local src = source
        if PLAYERS_CACHE[src] then
            local atm = USED_ATMs[PLAYERS_CACHE[src]]
            if DoesEntityExist(atm.cardObj) then
                DeleteEntity(atm.cardObj)
            end
            if DoesEntityExist(atm.moneyObj) then
                DeleteEntity(atm.moneyObj)
            end
            USED_ATMs[PLAYERS_CACHE[src]] = nil
            PLAYERS_CACHE[src] = nil
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    local data = {
        dailyTransactions = DAILY_TRANSACTIONS,
        remainingTime = os.time() % Config.ResetDailyTransactionsTime
    }

    SaveResourceFile(resourceName, 'data.json', json.encode(data), -1)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    local data = LoadResourceFile(resourceName, 'data.json')
    local success = false
    if data then
        local decodedData = nil
        success, decodedData = pcall(function() return json.decode(data) end)
        if success then
            data = decodedData
            DAILY_TRANSACTIONS = data.dailyTransactions or {}
            local remainingTime = data.remainingTime or Config.ResetDailyTransactionsTime
            CreateThread(function()
                Wait(remainingTime * 1000)
                resetDailyTransactions()
                while true do
                    Wait(Config.ResetDailyTransactionsTime * 1000)
                    resetDailyTransactions()
                end
            end)
        else
            print("Error decoding JSON data: " .. tostring(decodedData))
        end
    end
    if not success then
        resetDailyTransactions()
        CreateThread(function()
            while true do
                Wait(Config.ResetDailyTransactionsTime * 1000)
                resetDailyTransactions()
            end
        end)
    end
end)
