local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Vaults = {}
EthoriumBanking.ActiveTransports = {}

--- Check vault status and alert security if necessary
function EthoriumBanking.Vaults.CheckVaultLimits(bank_id, current_balance)
    local limits = Config.VaultLimits
    
    if current_balance <= limits.critical_low then
        EthoriumBanking.Server.Log("admin", "VAULT CRITICAL (LOW)", "Bank ID: " .. bank_id .. " is critically low on cash! Balance: $" .. current_balance, 16711680)
        EthoriumBanking.Vaults.GenerateTransportJob(bank_id, "refill")
    elseif current_balance <= limits.warning_low then
        EthoriumBanking.Server.Log("admin", "VAULT WARNING (LOW)", "Bank ID: " .. bank_id .. " is running low on cash. Balance: $" .. current_balance, 16753920)
    elseif current_balance >= limits.critical_high then
        EthoriumBanking.Server.Log("admin", "VAULT CRITICAL (HIGH)", "Bank ID: " .. bank_id .. " has too much cash! Vulnerable to robbery. Balance: $" .. current_balance, 16711680)
        EthoriumBanking.Vaults.GenerateTransportJob(bank_id, "pickup")
    elseif current_balance >= limits.warning_high then
        EthoriumBanking.Server.Log("admin", "VAULT WARNING (HIGH)", "Bank ID: " .. bank_id .. " vault is filling up. Balance: $" .. current_balance, 16753920)
    end
end

--- Update vault balance (e.g. after a player withdrawal)
function EthoriumBanking.Vaults.UpdateVaultBalance(bank_id, amount, is_deposit)
    local result = MySQL.Sync.fetchAll('SELECT vault_balance FROM ethorium_banks WHERE id = ?', {bank_id})
    if #result == 0 then return false, "Bank not found" end

    local current = result[1].vault_balance
    local new_balance = current

    if is_deposit then
        new_balance = new_balance + amount
    else
        if current < amount then return false, "Vault does not have enough physical cash!" end
        new_balance = new_balance - amount
    end

    MySQL.Async.execute('UPDATE ethorium_banks SET vault_balance = ? WHERE id = ?', {new_balance, bank_id}, function()
        EthoriumBanking.Vaults.CheckVaultLimits(bank_id, new_balance)
    end)
    return true, new_balance
end

--- Generates a transport job
function EthoriumBanking.Vaults.GenerateTransportJob(bank_id, job_type)
    local jobId = "JOB-" .. math.random(1000, 9999)
    -- In a real setup, this would trigger an event for players with the security job to accept
    EthoriumBanking.ActiveTransports[jobId] = {
        bank_id = bank_id,
        type = job_type,
        status = "pending",
        assigned_to = nil
    }
    print("^3[Ethorium Banking] Transport Job Generated: " .. jobId .. " (" .. job_type .. ")^0")
    -- Here we would trigger client events to security firms via QBcore framework exports
end

--- Transport job completion
function EthoriumBanking.Vaults.CompleteTransportJob(jobId)
    local job = EthoriumBanking.ActiveTransports[jobId]
    if job and job.status == "in_progress" then
        job.status = "completed"
        -- Award security firm, modify vault, delete job
        local refill_amount = 500000
        if job.type == "refill" then
            EthoriumBanking.Vaults.UpdateVaultBalance(job.bank_id, refill_amount, true)
        elseif job.type == "pickup" then
            EthoriumBanking.Vaults.UpdateVaultBalance(job.bank_id, refill_amount, false)
        end
        EthoriumBanking.ActiveTransports[jobId] = nil
        return true, "Transport successful."
    end
    return false, "Job not valid or not active."
end

exports("UpdateVaultBalance", EthoriumBanking.Vaults.UpdateVaultBalance)
