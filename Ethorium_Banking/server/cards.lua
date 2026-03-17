local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Cards = {}

--- Quick hashing function for PINs
local function HashPIN(pin)
    -- In Lua, we don't have built-in bcrypt without a resource, we'll use a simple sha256 via a helper or simple fallback
    -- Native lua sha256 would require a library. For FiveM, QBCore crypto or a simple hash approach is used.
    -- QBCore.Functions.Math.GetHashKey is an option for basic masking if bcrypt isn't available.
    return tostring(GetHashKey(tostring(pin)))
end

--- Generates a random 16 digit card number
local function GenerateCardNumber()
    local isUnique = false
    local cardNum = ""

    while not isUnique do
        cardNum = string.format("%04d %04d %04d %04d", math.random(1000, 9999), math.random(1000, 9999), math.random(1000, 9999), math.random(1000, 9999))
        local result = MySQL.Sync.fetchAll('SELECT card_number FROM ethorium_cards WHERE card_number = ?', {cardNum})
        if #result == 0 then
            isUnique = true
        end
        Wait(10)
    end
    return cardNum
end

--- Create a new card for an account
function EthoriumBanking.Cards.CreateCard(account_iban, tier, raw_pin)
    if not Config.Cards[tier] then return false, "Invalid card tier" end
    
    local tierData = Config.Cards[tier]
    local balance = EthoriumBanking.Server.GetAccountBalance(account_iban)

    if not balance then return false, "Account not found" end
    if balance < tierData.requires_balance then
        return false, string.format("Insufficient balance for this tier. Requires %sG", tierData.requires_balance)
    end

    local card_number = GenerateCardNumber()
    local pin_hash = HashPIN(raw_pin)

    MySQL.Async.execute('INSERT INTO ethorium_cards (card_number, account_iban, tier, pin_hash) VALUES (?, ?, ?, ?)', {
        card_number,
        account_iban,
        tier,
        pin_hash
    })

    return true, card_number
end

--- Attempt a card transaction (POS or ATM)
function EthoriumBanking.Cards.ProcessCardPayment(card_number, raw_pin, amount, txSource, description)
    local result = MySQL.Sync.fetchAll('SELECT * FROM ethorium_cards WHERE card_number = ?', {card_number})
    if #result == 0 then return false, "Card not found" end

    local card = result[1]

    if card.is_locked == 1 then
        return false, "Card is locked. Please contact the bank."
    end

    local pin_hash = HashPIN(raw_pin)
    if card.pin_hash ~= pin_hash then
        local fails = card.failed_attempts + 1
        local maxFails = 3
        
        if fails >= maxFails then
            MySQL.Async.execute('UPDATE ethorium_cards SET is_locked = 1, failed_attempts = ? WHERE id = ?', {fails, card.id})
            return false, "PIN incorrect. Card has been locked."
        else
            MySQL.Async.execute('UPDATE ethorium_cards SET failed_attempts = ? WHERE id = ?', {fails, card.id})
            return false, string.format("PIN incorrect. %d attempts remaining.", maxFails - fails)
        end
    end

    -- PIN Correct, reset fail attempts if > 0
    if card.failed_attempts > 0 then
        MySQL.Async.execute('UPDATE ethorium_cards SET failed_attempts = 0 WHERE id = ?', {card.id})
    end

    -- Process limits and payment
    local updatedAmount = EthoriumBanking.Server.ProcessMoneyMovement(card.account_iban, amount, false, txSource, description)
    if not updatedAmount then
        return false, "Insufficient funds on linked account."
    end

    return true, "Payment successful"
end

--- Cron job for daily fees
function EthoriumBanking.Cards.ProcessDailyFees()
    local cards = MySQL.Sync.fetchAll('SELECT id, account_iban, tier FROM ethorium_cards WHERE is_locked = 0')
    
    for _, card in ipairs(cards) do
        local tierData = Config.Cards[card.tier]
        if tierData and tierData.monthly_fee > 0 then
            local success, err = EthoriumBanking.Server.ProcessMoneyMovement(card.account_iban, tierData.monthly_fee, false, "bank_transfer", "Daily Card Fee: " .. card.tier)
            if not success then
                EthoriumBanking.Server.Log("transactions", "Fee Failed", "Failed to charge fee for card ID " .. card.id .. ": " .. tostring(err), 16711680)
                -- Could lock card here if they can't pay the fee
            end
        end
    end
end

exports("CreateCard", EthoriumBanking.Cards.CreateCard)
exports("ProcessCardPayment", EthoriumBanking.Cards.ProcessCardPayment)
