local logDeposit, logWithdraw = nil, nil
--playerId, account, amount, reason, statementType, accountType)
-- My Shared Account ('checking')
--deposit, withdraw
--accountType: player, job, gang
if Config.BankSystem == "qb" then
    logDeposit = function(playerId, account, amount, reason, statementType, accountType)
        statementType = "deposit"
        exports['qb-banking']:CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    end
    logWithdraw = function(playerId, account, amount, reason, statementType, accountType)
        statementType = "withdraw"
        exports['qb-banking']:CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    end
	logDeposit = function(playerId, account, amount, reason, statementType, accountType)
        statementType = "deposit"
        exports['s1n_banking']:CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    end
	 logWithdraw = function(playerId, account, amount, reason, statementType, accountType)
        statementType = "withdraw"
        exports['s1n_banking']:CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    end
elseif Config.BankSystem == "esx" then
    logDeposit = function(playerId, account, amount, reason, statementType, accountType)
        exports.esx_banking:logTransaction(playerId, reason, "DEPOSIT", amount)
    end

    logWithdraw = function(playerId, account, amount, reason, statementType, accountType)
        exports.esx_banking:logTransaction(playerId, reason, "WITHDRAW", amount)
    end
elseif Config.BankSystem == "sky_banking" then
    logDeposit = function(playerId, account, amount, reason, statementType, accountType)
        exports['sky_banking']:logTransaction(playerId, "deposit", reason, false, amount)
    end
    logWithdraw = function(playerId, account, amount, reason, statementType, accountType)
        exports['sky_banking']:logTransaction(playerId, "withdraw", reason, true, amount)
    end
else
    logDeposit = function() end
    logWithdraw = function() end
end

TransActionLogger = {
    logDeposit = logDeposit,
    logWithdraw = logWithdraw
}