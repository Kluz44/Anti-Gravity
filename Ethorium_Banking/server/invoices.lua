local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Invoices = {}

--- Generate unique reference code for open invoices
local function GenerateReference()
    local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local ref = "REF-"
    for i=1, 6 do
        local rand = math.random(1, #characters)
        ref = ref .. string.sub(characters, rand, rand)
    end
    return ref
end

--- Create an open invoice (Requires manual payment)
function EthoriumBanking.Invoices.CreateInvoice(sender_identifier, receiver_citizenid, amount, reason)
    if not sender_identifier or not receiver_citizenid or not amount or amount <= 0 then
        return false, "Invalid invoice details"
    end

    local reference = GenerateReference()

    MySQL.Async.execute('INSERT INTO ethorium_invoices (sender_identifier, receiver_citizenid, amount, reason, reference, status) VALUES (?, ?, ?, ?, ?, ?)', {
        sender_identifier,
        receiver_citizenid,
        amount,
        reason,
        reference,
        'unpaid'
    }, function(_)
        EthoriumBanking.Server.Log("transactions", "New Invoice Generated", "Reference: " .. reference .. "\nReceiver: " .. receiver_citizenid .. "\nAmount: $" .. amount, 16753920)
    end)
    return true, reference
end

--- Pay an open invoice
function EthoriumBanking.Invoices.PayInvoice(payer_account_iban, reference)
    local result = MySQL.Sync.fetchAll('SELECT * FROM ethorium_invoices WHERE reference = ? AND status = ?', {reference, 'unpaid'})
    if #result == 0 then return false, "Invoice not found or already paid." end

    local invoice = result[1]
    
    -- Try taking money from payer
    local success, err = EthoriumBanking.Server.ProcessMoneyMovement(payer_account_iban, invoice.amount, false, "invoice_payment", "Paid Invoice " .. reference)
    if not success then return false, "Insufficient funds to pay invoice." end

    -- Money logic for sender - find sender business or personal
    -- This requires logic that isn't completely defined in prompt, assumes sender could be job or citizenid.
    -- If sender is a job name e.g. 'police', need a Government or Business account.
    local senderIban = EthoriumBanking.Server.EnsureBusinessAccount(invoice.sender_identifier)
    EthoriumBanking.Server.ProcessMoneyMovement(senderIban, invoice.amount, true, "invoice_payment", "Received Payment for Invoice " .. reference)

    -- Update status
    MySQL.Async.execute('UPDATE ethorium_invoices SET status = ? WHERE id = ?', {'paid', invoice.id})

    EthoriumBanking.Server.Log("transactions", "Invoice Paid", "Reference: " .. reference .. "\nPayer IBAN: " .. payer_account_iban .. "\nAmount: $" .. invoice.amount, 3066993)
    return true, "Invoice paid successfully."
end

--- Create a direct Receipt (Instant deduction, e.g. POS or Gas Station)
--- Requires 'plate' for Gas Station transactions (enforced by logic)
function EthoriumBanking.Invoices.CreateReceipt(payer_account_iban, receiver_identifier, amount, reason, isGasStation, vehiclePlate)
    if isGasStation and not vehiclePlate then
        return false, "No vehicle plate provided for gas station receipt."
    end
    
    local fullReason = reason
    if isGasStation then
        fullReason = string.format("Gas Station Receipt - Vehicle: %s", vehiclePlate)
    end

    -- Deduct directly
    local success, err = EthoriumBanking.Server.ProcessMoneyMovement(payer_account_iban, amount, false, "receipt_purchase", fullReason)
    if not success then return false, err end
    
    -- Give money to receiver business
    local receiverIban = EthoriumBanking.Server.EnsureBusinessAccount(receiver_identifier)
    EthoriumBanking.Server.ProcessMoneyMovement(receiverIban, amount, true, "receipt_purchase", fullReason)

    -- Log to Webhooks specifically with plate if gas station
    if isGasStation then
        EthoriumBanking.Server.Log("transactions", "Gas Receipt Paid", "Vehicle: " .. vehiclePlate .. "\nAmount: $" .. amount .. "\nIBAN: " .. payer_account_iban, 65280)
    end
    
    return true, "Receipt successfully processed."
end

exports("CreateInvoice", EthoriumBanking.Invoices.CreateInvoice)
exports("PayInvoice", EthoriumBanking.Invoices.PayInvoice)
exports("CreateReceipt", EthoriumBanking.Invoices.CreateReceipt)
