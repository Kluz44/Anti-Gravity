local QBCore = exports['qb-core']:GetCoreObject()

--- Generate a unique IBAN
function EthoriumBanking.Server.GenerateIBAN()
    local prefix = Config.IBANPrefix
    local isUnique = false
    local iban = ""

    while not isUnique do
        iban = prefix .. tostring(math.random(10000000, 99999999))
        local result = MySQL.Sync.fetchAll('SELECT iban FROM ethorium_accounts WHERE iban = ?', {iban})
        if #result == 0 then
            isUnique = true
        end
        Wait(10)
    end
    return iban
end

--- Create a new bank account
function EthoriumBanking.Server.CreateAccount(accountType, citizenid, businessName)
    if not citizenid and not businessName then return false, "No owner provided." end
    
    local iban = EthoriumBanking.Server.GenerateIBAN()
    local balance = 0

    MySQL.Async.execute('INSERT INTO ethorium_accounts (iban, type, citizenid, business_name, balance, is_frozen) VALUES (?, ?, ?, ?, ?, ?)', {
        iban,
        accountType,
        citizenid,
        businessName,
        balance,
        0
    }, function(affectedRows)
        if affectedRows > 0 then
            EthoriumBanking.Server.Log("admin", "Account Created", "IBAN: " .. iban .. "\nType: " .. accountType .. "\nOwner: " .. (citizenid or businessName), 3066993)
        end
    end)
    return iban
end

--- Auto-create business account if not exists (checked during login/job update)
function EthoriumBanking.Server.EnsureBusinessAccount(businessName)
    local result = MySQL.Sync.fetchAll('SELECT iban FROM ethorium_accounts WHERE type = ? AND business_name = ?', {'business', businessName})
    if #result == 0 then
        local iban = EthoriumBanking.Server.CreateAccount('business', nil, businessName)
        print("^2[Ethorium Banking] Created new business account for: " .. businessName .. " ("..iban..")^0")
        return iban
    end
    return result[1].iban
end

--- Get account balance safely
function EthoriumBanking.Server.GetAccountBalance(iban)
    local result = MySQL.Sync.fetchAll('SELECT balance, is_frozen FROM ethorium_accounts WHERE iban = ?', {iban})
    if result[1] then
        if result[1].is_frozen == 1 then return false, "Account is frozen" end
        return result[1].balance
    end
    return false, "Account not found"
end

--- Modify account balance (MUST be used alongside CreateTransaction)
local function UpdateBalance(iban, amount, isAddition)
    local currentBalance = EthoriumBanking.Server.GetAccountBalance(iban)
    if type(currentBalance) ~= "number" then return false, "Invalid account" end

    local newBalance = currentBalance
    if isAddition then
        newBalance = newBalance + amount
    else
        if currentBalance < amount then return false, "Insufficient funds" end
        newBalance = newBalance - amount
    end

    MySQL.Sync.execute('UPDATE ethorium_accounts SET balance = ? WHERE iban = ?', {newBalance, iban})
    return newBalance
end

--- Process a full transaction (Balance update + Logging)
function EthoriumBanking.Server.ProcessMoneyMovement(iban, amount, isDeposit, txSource, description)
    if amount <= 0 then return false, "Amount must be positive." end
    
    if not EthoriumBanking.Server.IsValidSource(txSource) then
       return false, "Invalid transaction source."
    end

    -- Update balance
    local updatedBalance, err = UpdateBalance(iban, amount, isDeposit)
    if not updatedBalance then return false, err end

    -- Log transaction
    local txType = isDeposit and "deposit" or "withdraw"
    EthoriumBanking.Server.CreateTransaction(iban, amount, txType, txSource, description)

    return updatedBalance
end


exports("ProcessMoneyMovement", EthoriumBanking.Server.ProcessMoneyMovement)
exports("GetAccountBalance", EthoriumBanking.Server.GetAccountBalance)
