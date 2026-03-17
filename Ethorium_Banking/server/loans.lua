local QBCore = exports['qb-core']:GetCoreObject()

EthoriumBanking = EthoriumBanking or {}
EthoriumBanking.Loans = {}

--- Validate a property as collateral
function EthoriumBanking.Loans.ValidateHouseCollateral(citizenid, house_id)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_houses WHERE id = ?', {house_id})
    if #result == 0 then return false, "House not found." end

    local house = result[1]

    if house.citizenid ~= citizenid and house.owner ~= citizenid then
        return false, "You do not own this property."
    end
    -- Prompt logic: exclude rented
    if house.rented and tonumber(house.rented) == 1 then
        return false, "Rented properties cannot be used as collateral."
    end
    -- Check if already used
    local loanCheck = MySQL.Sync.fetchAll('SELECT id FROM ethorium_loans WHERE collateral_type = ? AND collateral_id = ?', {'house', tostring(house_id)})
    if #loanCheck > 0 then
        return false, "This property is already used as collateral for an active loan."
    end

    -- Value calculation logic
    local value = house.creditPrice
    if not value or value <= 0 then
        if house.rentPrice and house.rentPrice > 0 then
            value = house.rentPrice * 50
        else
            value = 100000 -- Fallback Default
        end
    end

    return true, value
end

--- Validate a vehicle as collateral
function EthoriumBanking.Loans.ValidateVehicleCollateral(citizenid, plate)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid})
    if #result == 0 then return false, "Vehicle not found or you do not own it." end

    local vehicle = result[1]

    if vehicle.jobVehicle and tonumber(vehicle.jobVehicle) == 1 then return false, "Job vehicles are not valid collateral." end
    if vehicle.state and tonumber(vehicle.state) == 2 then return false, "Vehicle state invalid for collateral." end
    if vehicle.paymentsleft and tonumber(vehicle.paymentsleft) > 0 then return false, "Financed vehicles cannot be used." end
    if vehicle.balance and tonumber(vehicle.balance) > 0 then return false, "Vehicle has unpaid balance." end

    local loanCheck = MySQL.Sync.fetchAll('SELECT id FROM ethorium_loans WHERE collateral_type = ? AND collateral_id = ?', {'vehicle', tostring(plate)})
    if #loanCheck > 0 then
        return false, "This vehicle is already used as collateral for an active loan."
    end

    -- Values logic
    local engine = tonumber(vehicle.engine) or 1000
    local body = tonumber(vehicle.body) or 1000
    local depotPrice = tonumber(vehicle.depotprice) or 50000

    local condition = math.max(0.1, (engine + body) / 2000)
    local value = depotPrice * condition

    return true, value
end

--- Issue a new loan based on credit score
function EthoriumBanking.Loans.RequestLoan(account_iban, citizenid, creditScore, amount, collateralType, collateralId)
    -- Verify Score & Get terms
    local terms = nil    
    if creditScore >= Config.Loans.scores['high'].min then
        terms = Config.Loans.scores['high']
    elseif creditScore >= Config.Loans.scores['medium'].min then
        terms = Config.Loans.scores['medium']
    elseif creditScore >= Config.Loans.scores['low'].min then
        terms = Config.Loans.scores['low']
    else
        return false, "Credit score too low for a loan."
    end

    if amount > terms.max_amount then
        return false, string.format("Maximum loan amount for your score is $%d", terms.max_amount)
    end

    -- Verify Collateral
    local colValue = 0
    if collateralType == "house" then
        local isValid, res = EthoriumBanking.Loans.ValidateHouseCollateral(citizenid, collateralId)
        if not isValid then return false, res end
        colValue = res
    elseif collateralType == "vehicle" then
        local isValid, res = EthoriumBanking.Loans.ValidateVehicleCollateral(citizenid, collateralId)
        if not isValid then return false, res end
        colValue = res
    else
        return false, "A valid collateral (house or vehicle) is REQUIRED."
    end

    -- Payout the loan
    local payoutSuccess, err = EthoriumBanking.Server.ProcessMoneyMovement(account_iban, amount, true, "loan_payout", "Loan Issued. Score: " .. creditScore .. " Rate: " .. (terms.interest * 100) .. "%")
    if not payoutSuccess then return false, "Error paying out loan amounts: " .. err end

    -- Save loan record with full repayment total calculated
    local totalOwed = amount + (amount * terms.interest)

    MySQL.Async.execute('INSERT INTO ethorium_loans (citizenid, amount, remaining_amount, interest_rate, collateral_type, collateral_id, collateral_value) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        citizenid,
        amount,
        totalOwed,
        terms.interest,
        collateralType,
        tostring(collateralId),
        colValue
    })

    EthoriumBanking.Server.Log("loans", "Loan Issued", "Citizen: " .. citizenid .. "\nAmount: $" .. amount .. "\nCollateral: " .. collateralType .. " - " .. tostring(collateralId) .. "\nValue: $" .. colValue, 16753920)

    return true, "Loan issued successfully. Funds deposited."
end

exports("RequestLoan", EthoriumBanking.Loans.RequestLoan)
