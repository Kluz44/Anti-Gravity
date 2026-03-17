local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = {}
EthoriumBanking.Server = {}

--- Logs action to Discord webhook
function EthoriumBanking.Server.Log(webhookType, title, message, color)
    local webhookUrl = Config.Webhooks[webhookType]
    if not webhookUrl or webhookUrl == "ENTER_WEBHOOK_HERE" then return end

    local embed = {
        {
            ["color"] = color or 16711680, -- Default red
            ["title"] = "**".. title .."**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "Ethorium Banking | " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({username = "Ethorium Banking", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

--- Validates if a transaction source is legit according to rules
function EthoriumBanking.Server.IsValidSource(source)
    for _, validSource in ipairs(Config.ValidSources) do
        if source == validSource then return true end
    end
    return false
end

--- Generates a unique trace ID
function EthoriumBanking.Server.GenerateTraceId()
    local characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local trace_id = "TRC-"
    for i=1, 12 do
        local rand = math.random(1, #characters)
        trace_id = trace_id .. string.sub(characters, rand, rand)
    end
    return trace_id
end

--- Master function for creating money movements (transactions)
--- Rules: direct setting of balance is FORBIDDEN. Must use this function.
function EthoriumBanking.Server.CreateTransaction(account_iban, amount, txType, txSource, description)
    local src = source

    if not account_iban or not amount or not txType or not txSource then
        EthoriumBanking.Server.Log("admin", "SYSTEM ALERT", "Attempted transaction with missing parameters. IBAN: " .. tostring(account_iban) .. " Source: " .. tostring(txSource), 16711680)
        return false, "Missing transaction parameters."
    end

    if not EthoriumBanking.Server.IsValidSource(txSource) then
        EthoriumBanking.Server.Log("admin", "ANTI-CHEAT ALERT", "Invalid transaction source used: " .. txSource .. " for amount: " .. amount, 16711680)
        print("^1[Ethorium Banking] ANTI-CHEAT ALERT: Invalid transaction source blocked: " .. txSource .. "^0")
        return false, "Invalid money source."
    end

    local trace_id = EthoriumBanking.Server.GenerateTraceId()

    -- Insert into DB
    MySQL.Async.insert('INSERT INTO ethorium_transactions (trace_id, account_iban, amount, type, source, description) VALUES (?, ?, ?, ?, ?, ?)', {
        trace_id,
        account_iban,
        amount,
        txType,
        txSource,
        description or ""
    }, function(id)
        if id then
            EthoriumBanking.Server.Log("transactions", "New Transaction", "Type: " .. txType .. "\nAmount: $" .. amount .. "\nIBAN: " .. account_iban .. "\nSource: " .. txSource .. "\nTraceID: " .. trace_id, 3066993)
        end
    end)

    return true, trace_id
end

-- Export core transaction functions for use by other scripts safely if necessary
exports("CreateTransaction", EthoriumBanking.Server.CreateTransaction)
exports("GenerateTraceId", EthoriumBanking.Server.GenerateTraceId)

AddEventHandler("onResourceStart", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    print("^2[Ethorium Banking] Core initialized.^0")
end)
