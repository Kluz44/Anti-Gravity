local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Integrations = {}

--- Calculate and split tax if ap-government is used
--- This assumes ap-government resource is active.
function EthoriumBanking.Integrations.ApplyTax(amount, taxType)
    local taxRate = 0
    local state = GetResourceState("ap-government")
    
    if state == "started" then
        -- Protected call in case export is missing
        local status, result = pcall(function()
            return exports['ap-government']:GetTaxRate(taxType)
        end)
        if status and type(result) == "number" then
            taxRate = result
        end
    end

    if taxRate > 0 then
        local taxAmount = math.floor(amount * (taxRate / 100))
        local remaining = amount - taxAmount
        -- The system would then route taxAmount to the Government account
        -- Example, ensuring government account exists
        local govIban = EthoriumBanking.Server.EnsureBusinessAccount("government")
        EthoriumBanking.Server.ProcessMoneyMovement(govIban, taxAmount, true, "government_tax", "Tax applied: " .. taxType)
        return remaining, taxAmount
    end

    return amount, 0
end

--- Validates if an employee can withdraw from a company account
--- Based on their job grade ('employee', 'manager', 'boss')
function EthoriumBanking.Integrations.ValidateBusinessWithdrawal(citizenid, jobName, jobGrade, amount)
    local gradeLimits = Config.BusinessPayouts

    local limit = gradeLimits[jobGrade] or 0
    if limit == -1 then return true, "Unlimited payout allowed." end

    if amount > limit then
        return false, string.format("Your rank (%s) limit for withdrawals is $%d", jobGrade, limit)
    end

    return true, "Within limit."
end

exports("ApplyTax", EthoriumBanking.Integrations.ApplyTax)
exports("ValidateBusinessWithdrawal", EthoriumBanking.Integrations.ValidateBusinessWithdrawal)
