Functions = {}

-- TODO: Use s1nLib storage system
-- The pending contracts to be signed
Functions.pendingContracts = {}

--
-- Database
--

-- Create the tables
function Functions:CreateTables()
    Utils:Debug("Creating the tables")

    SQL:Execute([[
        CREATE TABLE IF NOT EXISTS s1n_invoices (
            reference_id VARCHAR(255) PRIMARY KEY,
            sender_identifier VARCHAR(255) NOT NULL,
            sender_full_name VARCHAR(255) DEFAULT NULL,
            receiver_identifier VARCHAR(255) DEFAULT NULL,
            receiver_full_name VARCHAR(255) DEFAULT NULL,
            company_name VARCHAR(255) DEFAULT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            due_at DATETIME NOT NULL,
            item TEXT NOT NULL,
            note TEXT DEFAULT NULL,
            amount BIGINT NOT NULL,
            is_paid BOOLEAN NOT NULL DEFAULT FALSE
        )
    ]])
end

--
-- Invoices
--

-- Check if an invoice exists
-- @param referenceId string The reference ID of the invoice
-- @return boolean Whether the invoice exists
function Functions:DoesInvoiceExist(referenceId)
    local result = SQL:Execute("SELECT COUNT(*) AS `count` FROM `s1n_invoices` WHERE `reference_id` = ?", {referenceId})

    return result[1].count > 0
end
exports("doesInvoiceExist", function(...)
    return Functions:DoesInvoiceExist(...)
end)

-- Generate a reference ID for an invoice
-- @return string The reference ID
function Functions:GenerateReferenceID()
    local newInvoiceReferenceId

    repeat
        -- Generate a random reference ID in this format: INV-XXXYXYYX (X is a random number and Y is a random letter)
        newInvoiceReferenceId = ("INV-%s%s%s%s%s%s%s%s"):format(
            math.random(0, 9),
            math.random(0, 9),
            math.random(0, 9),
            string.char(math.random(65, 90)),
            math.random(0, 9),
            string.char(math.random(65, 90)),
            math.random(0, 9),
            math.random(0, 9)
        )
    until not Functions:DoesInvoiceExist(newInvoiceReferenceId)

    return newInvoiceReferenceId
end

-- Create an invoice
-- @param playerSource number The player's server ID
-- @param dataObject table The data of the invoice
-- @return boolean Whether the invoice was created successfully
function Functions:CreateInvoice(playerSource, dataObject)
    Utils:Debug("Creating an invoice")

    -- TODO: Check schema using s1n_lib

    Utils:Debug(("The invoice data: %s"):format(json.encode(dataObject)))

    local senderIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(playerSource)

    if not senderIdentifier then
        return false
    end

    local receiverIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(dataObject.receiver)

    if not receiverIdentifier then
        return false
    end

    local newInvoiceReferenceId = Functions:GenerateReferenceID()

    local senderFullName = exports[Config.ExportNames.s1nLib]:getPlayerFullName(playerSource)
    local receiverFullName = exports[Config.ExportNames.s1nLib]:getPlayerFullName(dataObject.receiver)

    -- If the player is trying to create an invoice as a society
    if dataObject.isJob then
        local job = exports[Config.ExportNames.s1nLib]:getPlayerJob(playerSource, {
            mapData = {
                name = true
            }
        })

        -- WIP: Check if the company associated with the job exists in the database to avoid creating an invoice for a non-existing company

        local societyName = job.name

        if exports[Config.ExportNames.s1nLib]:getCurrentFrameworkName() == "esx" then
            societyName = ("society_%s"):format(societyName)
        end

        if not exports[Config.ExportNames.s1nLib]:getSocietyAccount(societyName) then
            Utils:Debug(("The company %s does not exist"):format(societyName))

            return false
        end

        SQL:Execute("INSERT INTO s1n_invoices (reference_id, sender_identifier, sender_full_name, receiver_identifier, receiver_full_name, company_name, created_at, updated_at, due_at, item, note, amount) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW(), ?, ?, ?, ?)", {
            newInvoiceReferenceId,
            senderIdentifier,
            senderFullName,
            receiverIdentifier,
            receiverFullName,
            societyName,
            dataObject.date,
            dataObject.item,
            dataObject.note,
            dataObject.amount
        })
    else
        SQL:Execute("INSERT INTO s1n_invoices (reference_id, sender_identifier, sender_full_name, receiver_identifier, receiver_full_name, created_at, updated_at, due_at, item, note, amount) VALUES (?, ?, ?, ?, ?, NOW(), NOW(), ?, ?, ?, ?)", {
            newInvoiceReferenceId,
            senderIdentifier,
            senderFullName,
            receiverIdentifier,
            receiverFullName,
            dataObject.date,
            dataObject.item,
            dataObject.note,
            dataObject.amount
        })
    end

    API:SendDiscordLog(Config.Translation.WEBHOOK_INVOICE_CREATED:format(senderFullName, receiverFullName, dataObject.amount, dataObject.item))

    return true
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("createInvoice", function(playerSource, callback, dataObject)
    callback(Functions:CreateInvoice(playerSource, dataObject))
end)
exports("createInvoice", function(...)
    return Functions:CreateInvoice(...)
end)

-- Send an invite to a player to accept an invoice
-- @param playerSource number The player's server ID
-- @param dataObject table The data of the invite
-- @return boolean Whether the invite was sent successfully
function Functions:SendInviteToPlayer(playerSource, dataObject)
    Utils:Debug("Sending an invite to the player")

    local accepted = exports[Config.ExportNames.s1nLib]:awaitTriggerClientEvent("receiveInviteFromPlayer", dataObject.receiver, dataObject)

    Utils:Debug(("The player %s the invite"):format(accepted and "accepted" or "declined"))

    return accepted
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("sendInviteToPlayer", function(playerSource, callback, dataObject)
    callback(Functions:SendInviteToPlayer(playerSource, dataObject))
end)

-- Get the invoices of a given player
-- @param playerSource (optional) number The player's server ID
-- @param dataObject table The data object
-- @return table|boolean The invoices or false if an error occurred
function Functions:GetInvoices(playerSource, dataObject)
    Utils:Debug("Getting the invoices")

    local playerIdentifier

    if dataObject.targetIdentifier then
        playerIdentifier = dataObject.targetIdentifier
    else
        playerIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(playerSource)
    end

    if not playerIdentifier then
        return false
    end

    local invoicesSelectQuery = [[
         SELECT
            `reference_id` AS `id`,
            `is_paid` AS `payed`,
            `sender_full_name` AS `sender`,
            `receiver_full_name` AS `receiver`,
            `company_name` AS `companyName`,
            CASE
                WHEN `sender_identifier` = ? THEN TRUE
                ELSE FALSE
            END AS `sent`,
            `created_at` AS `createdAt`,
            `due_at` AS `dueAt`,
            `amount`,
            `item`,
            `note`
        FROM `s1n_invoices`
        WHERE `sender_identifier` = ? OR `receiver_identifier` = ?
    ]]

    if dataObject.limit then
        invoicesSelectQuery = ("%s LIMIT %d"):format(invoicesSelectQuery, dataObject.limit)
    end

    if dataObject.offset then
        invoicesSelectQuery = ("%s OFFSET %d"):format(invoicesSelectQuery, dataObject.offset)
    end

    local invoices = SQL:Execute(invoicesSelectQuery, { playerIdentifier, playerIdentifier, playerIdentifier })

    return invoices
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("getSenderPersonalInvoices", function(playerSource, callback, dataObject)
    callback(Functions:GetInvoices(playerSource, dataObject))
end)
exports("getSenderPersonalInvoices", function(...)
    return Functions:GetInvoices(...)
end)

-- Get the company invoices of a player
-- @param playerSource number The player's server ID who wants to get the company invoices associated with his job
function Functions:GetCompanyInvoices(playerSource)
    Utils:Debug("Getting the company invoices")

    local job = exports[Config.ExportNames.s1nLib]:getPlayerJob(playerSource, {
        mapData = {
            name = true
        }
    })
    if not job then
        return false
    end

    local jobName = job.name

    Utils:Debug(("The job name: %s"):format(jobName))

    local societyName = jobName

    if exports[Config.ExportNames.s1nLib]:getCurrentFrameworkName() == "esx" then
        societyName = ("society_%s"):format(societyName)
    end

    local invoicesSelectQuery = SQL:Execute([[
         SELECT
            `reference_id` AS `id`,
            `is_paid` AS `payed`,
            `sender_full_name` AS `sender`,
            `receiver_full_name` AS `receiver`,
            `company_name` AS `companyName`,
            CASE
                WHEN `sender_identifier` = ? THEN TRUE
                ELSE FALSE
            END AS `sent`,
            `created_at` AS `createdAt`,
            `due_at` AS `dueAt`,
            `amount`,
            `item`
        FROM `s1n_invoices`
        WHERE `company_name` = ?
    ]], {societyName, societyName})

    Utils:Debug(json.encode(invoicesSelectQuery))

    return invoicesSelectQuery
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("getCompanyInvoices", function(playerSource, callback, dataObject)
    callback(Functions:GetCompanyInvoices(playerSource, dataObject))
end)
exports("getCompanyInvoices", function(...)
    return Functions:GetCompanyInvoices(...)
end)

-- Mark an invoice as paid
-- @param dataObject table The data of the invoice
function Functions:MarkInvoiceAsPaid(dataObject)
    SQL:Execute("UPDATE `s1n_invoices` SET `is_paid` = TRUE, `updated_at` = NOW() WHERE `reference_id` = ?", {dataObject.id})

    Utils:Debug(("The invoice with the ID %s has been marked as paid"):format(dataObject.id))
end
exports("markInvoiceAsPaid", function(...)
    Functions:MarkInvoiceAsPaid(...)
end)

-- Pay an invoice
-- @param playerSource number The player's server ID
-- @param dataObject table The data of the invoice
-- @return boolean Whether the invoice was paid successfully
function Functions:PayInvoice(playerSource, dataObject)
    Utils:Debug("Paying an invoice")

    local playerIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(playerSource)

    if not playerIdentifier then
        return false
    end

    local invoice = SQL:Execute("SELECT `is_paid`, `sender_identifier`, `amount`, `company_name` FROM `s1n_invoices` WHERE `reference_id` = ?", {dataObject.id})[1]

    if not invoice then
        Utils:Debug(("The invoice with the ID %s does not exist"):format(dataObject.id))

        return false
    end

    if invoice.is_paid then
        Utils:Debug(("%s tried to pay an invoice that has already been paid"):format(playerIdentifier))

        return false
    end

    if exports[Config.ExportNames.s1nLib]:getPlayerBankMoney(playerSource) < invoice.amount then
        return false, "NOTIFICATION_YOU_DONT_HAVE_ENOUGH_MONEY_IN_BANK"
    end

    local senderSource = exports[Config.ExportNames.s1nLib]:getPlayerSourceFromIdentifier(invoice.sender_identifier)

    local amountToPay = invoice.amount
    local vatAmount

    -- If the VAT system is enabled, set the amount to pay to the total amount with the VAT included
    if Config.Invoice.vat.enabled then
        vatAmount = math.ceil(amountToPay * Config.Invoice.vat.rate)
        amountToPay = amountToPay + vatAmount
    end

    -- If the invoice is a job invoice
    if invoice.company_name then
        Utils:Debug("The invoice is a job invoice")

        if not exports[Config.ExportNames.s1nLib]:transferBankMoneyToSociety(playerSource, invoice.company_name, invoice.amount) then
            Utils:Debug("The player tried to pay an invoice as a company but the company doesn't exist")

            return false
        end
    else
        -- If the sender is online
        if senderSource then
            if not exports[Config.ExportNames.s1nLib]:transferBankMoney(playerSource, senderSource, invoice.amount) then
                return false
            end

            exports[Config.ExportNames.s1nLib]:notifyPlayer(senderSource, Config.Translation.NOTIFICATION_INVOICE_HAS_BEEN_PAID:format(dataObject.id))
        else
            if not exports[Config.ExportNames.s1nLib]:transferBankMoneyToOfflinePlayer(playerSource, invoice.sender_identifier, invoice.amount) then
                return false
            end

            -- TODO (future update): Add him to a queue if he's not online and notify him when he's online (when playerLoaded event is called from s1nLib)
        end
    end

    -- Add the VAT to the beneficiary company like the government for example
    if Config.Invoice.vat.enabled then
        exports[Config.ExportNames.s1nLib]:addMoneyToSocietyAccount(Config.Invoice.vat.beneficiaryCompany, vatAmount)
    end

    exports[Config.ExportNames.s1nLib]:notifyPlayer(playerSource, Config.Translation.NOTIFICATION_YOU_HAVE_PAID_INVOICE:format(invoice.amount, dataObject.id))
    self:MarkInvoiceAsPaid({ id = dataObject.id })

    API:SendDiscordLog(Config.Translation.WEBHOOK_INVOICE_PAID:format(playerIdentifier, dataObject.id))

    return true
end
-- TODO (future update): Add in s1nLib, the possibility to add input validator (check the data schema sent by the client) on the registerServerCallback
exports[Config.ExportNames.s1nLib]:registerServerCallback("payInvoice", function(playerSource, callback, dataObject)
    callback(Functions:PayInvoice(playerSource, dataObject))
end)

-- Pay all invoices
-- @param playerSource number The player's server ID
-- @return (boolean, string) Whether the invoices were paid successfully and the error key if an error occurred
function Functions:PayAllInvoices(playerSource)
    Utils:Debug("Paying all invoices")

    local playerIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(playerSource)

    if not playerIdentifier then
        return false
    end

    local invoices = SQL:Execute("SELECT `reference_id`, `amount` FROM `s1n_invoices` WHERE `receiver_identifier` = ? AND `is_paid` = FALSE", {playerIdentifier})

    if not invoices then
        return false
    end

    if #invoices == 0 then
        return false
    end

    local totalAmount = 0

    for _, invoice in ipairs(invoices) do
        totalAmount = totalAmount + invoice.amount

        if Config.Invoice.vat.enabled then
            totalAmount = totalAmount + Functions:CalculateVAT(invoice.amount)
        end
    end

    if exports[Config.ExportNames.s1nLib]:getPlayerBankMoney(playerSource) < totalAmount then
        return false, "NOTIFICATION_YOU_DONT_HAVE_ENOUGH_MONEY_IN_BANK"
    end

    for _, invoice in ipairs(invoices) do
        if not Functions:PayInvoice(playerSource, { id = invoice.reference_id }) then
            return false
        end
    end

    return true
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("payAllInvoices", function(playerSource, callback)
    callback(Functions:PayAllInvoices(playerSource))
end)

-- Lookup the invoices of a citizen
-- @param playerSource number The player's server ID who wants to lookup the invoices
-- @param dataObject table The data object
-- @return table|boolean The invoices or false if an error occurred
function Functions:LookupCitizenInvoices(playerSource, dataObject)
    local playerJob = exports[Config.ExportNames.s1nLib]:getPlayerJob(playerSource, {
        lowercaseJobName = true,
        lowercaseJobGradeName = true,
        mapData = {
            name = true,
            grade = {
                name = true,
            },
        }
    })
    if not Config.Permissions.REVIEW_SOMEONE_INVOICES.jobs[playerJob.name][playerJob.grade.name] then
        return false
    end

    -- dataObject.fullName must be like "Firstname Lastname", if not it will return false .
    if not dataObject.targetName or not dataObject.targetName:match("%a+%s%a+") then
        return false
    end

    local targetIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifierFromFullName({ fullName = dataObject.targetName })
    if not targetIdentifier then
        return false
    end

    local invoices = self:GetInvoices(nil, { targetIdentifier = targetIdentifier })
    if not invoices then
        return false
    end

    API:SendDiscordLog(Config.Translation.WEBHOOK_LOOKUP_CITIZEN_INVOICES:format(exports[Config.ExportNames.s1nLib]:getPlayerFullName(playerSource), dataObject.targetName))

    return invoices
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("lookupCitizenInvoices", function(playerSource, callback, dataObject)
    callback(Functions:LookupCitizenInvoices(playerSource, dataObject))
end)

--
-- Contracts
--

-- Send a contract to a player to show it to him
-- @param playerSource number The player's server ID
-- @param dataObject table The data of the contract
-- @return boolean
function Functions:SendContractToPlayer(playerSource, dataObject)
    Utils:Debug("Sending a contract to the player")

    local targetSource = exports[Config.ExportNames.s1nLib]:getPlayerSourceFromIdentifier(dataObject.closestPlayer.identifier)

    if not targetSource then
        return false
    end

    local contractID = #Functions.pendingContracts + 1

    -- Store the contract in the pending contracts, waiting for both players to sign it and proceed to the transaction
    local contractObject = {
        type = dataObject.contractType,
        amount = dataObject.contractAmount,
        buyerObject = dataObject.closestPlayer,
        sellerObject = {
            identifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(playerSource),
            playerSource = playerSource,
            name = dataObject.sellerName
        }
    }

    if dataObject.contractType == "vehicle" then
        contractObject.vehicle = dataObject.vehicle
    elseif dataObject.contractType == "inventory-item" then
        contractObject.inventoryItem = dataObject.inventoryItem
    end

    Functions.pendingContracts[contractID] = contractObject

    dataObject.contractID = contractID

    -- Show the contract UI to the player
    exports[Config.ExportNames.s1nLib]:awaitTriggerClientEvent("receiveContractFromPlayer", targetSource, dataObject)

    API:SendDiscordLog(Config.Translation.WEBHOOK_CONTRACT_SENT_TO:format(dataObject.sellerName, dataObject.closestPlayer.name))

    return {
        contractID = contractID,
    }
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("sendContractToPlayer", function(playerSource, callback, dataObject)
    callback(Functions:SendContractToPlayer(playerSource, dataObject))
end)

-- Transfer an item from a player to another
-- @param sellerSource number The player's server ID who sells the item
-- @param buyerSource number The player's server ID who buys the item
-- @param itemObject table The item object
-- @return boolean Whether the item was transferred successfully
function Functions:TransferItem(sellerSource, buyerSource, itemObject)
    Utils:Debug("Transferring an item, sellerSource: %s, buyerSource: %s, itemObject: %s", sellerSource, buyerSource, itemObject)

    if not exports[Config.ExportNames.s1nLib]:hasItemInInventory(sellerSource, itemObject.name, itemObject.quantity) then
        return false, "NOTIFICATION_CONTRACT_TRANSACTION_FAILED_SELLER_DOESNT_OWN_ITEM"
    end

    if not exports[Config.ExportNames.s1nLib]:canCarryItem({ playerSource = buyerSource, itemName = itemObject.name, amount = itemObject.quantity }) then
        return false, "NOTIFICATION_CONTRACT_TRANSACTION_FAILED_BUYER_INVENTORY_FULL"
    end

    -- Transfer the item from the seller to the buyer
    if not exports[Config.ExportNames.s1nLib]:transferInventoryItem({ playerSource = sellerSource, targetPlayerSource = buyerSource, itemName = itemObject.name, amount = itemObject.quantity }) then
        return false
    end

    return true
end

-- Transfer a vehicle from a player to another
-- @param buyerSource number The player's server ID who buys the vehicle
-- @param plate string The plate of the vehicle
-- @return boolean Whether the vehicle was transferred successfully
function Functions:TransferVehicle(buyerSource, plate)
    Utils:Debug("Transferring a vehicle, buyerSource: %s, plate: %s", buyerSource, plate)

    local targetIdentifier = exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(buyerSource)
    if not targetIdentifier then
        return false
    end

    -- TODO: Check if the seller owns the vehicle directly in transferVehicleOwnership with the ownerIdentifier being passed
    if not exports[Config.ExportNames.s1nLib]:transferVehicleOwnership({ plate = plate, targetIdentifier = targetIdentifier }) then
        return false
    end

    return true
end

-- Sign a contract and proceed to the transaction if both have signed
-- @param playerSource number The player's server ID
-- @param dataObject table The data of the contract
-- @return boolean
function Functions:SignContract(playerSource, dataObject)
    Utils:Debug("The player signed the contract with dataObject=%s", dataObject)

    local contract = Functions.pendingContracts[dataObject.contractID]

    if not contract then
        Utils:Debug("Couldn't find the contract with the ID %s", dataObject.contractID)
        return false
    end

    -- Check if both have signed the contract and then proceed to the transaction
    if contract.buyerObject.identifier == exports[Config.ExportNames.s1nLib]:getPlayerIdentifier(playerSource) then
        contract.buyerObject.signed = true

        -- Send an event to the seller to notify him that the buyer has signed the contract
        exports[Config.ExportNames.s1nLib]:awaitTriggerClientEvent("contractSignedByTarget", contract.sellerObject.playerSource, { name = contract.buyerObject.frameworkName, party = "buyer" })
    else
        contract.sellerObject.signed = true

        -- Send an event to the buyer to notify him that the seller has signed the contract
        exports[Config.ExportNames.s1nLib]:awaitTriggerClientEvent("contractSignedByTarget", contract.buyerObject.playerSource, { name = contract.sellerObject.name, party = "seller" })
    end

    -- TODO: refactor to avoid contract.X : re-use

    if contract.buyerObject.signed and contract.sellerObject.signed then
        Utils:Debug("Both players have signed the contract")

        if not exports[Config.ExportNames.s1nLib]:transferBankMoney(contract.buyerObject.playerSource, contract.sellerObject.playerSource, contract.amount) then
            exports[Config.ExportNames.s1nLib]:notifyPlayer(contract.sellerObject.playerSource, Config.Translation.NOTIFICATION_CONTRACT_TRANSACTION_FAILED_BUYER_NOT_ENOUGH_MONEY_IN_BANK)
            exports[Config.ExportNames.s1nLib]:notifyPlayer(contract.buyerObject.playerSource, Config.Translation.NOTIFICATION_CONTRACT_TRANSACTION_FAILED_NOT_ENOUGH_MONEY_IN_BANK)

            return false
        end

        Utils:Debug("Money transferred successfully, now proceeding to the item/vehicle transfer")

        if contract.type == "inventory-item" then
            if not self:TransferItem(contract.sellerObject.playerSource, contract.buyerObject.playerSource, contract.inventoryItem) then
                return false
            end
        elseif contract.type == "vehicle" then
            if not self:TransferVehicle(contract.buyerObject.playerSource, contract.vehicle.plate) then
                return false
            end
        end

        exports[Config.ExportNames.s1nLib]:notifyPlayer(contract.sellerObject.playerSource, Config.Translation.NOTIFICATION_CONTRACT_VALIDATED)
        exports[Config.ExportNames.s1nLib]:notifyPlayer(contract.buyerObject.playerSource, Config.Translation.NOTIFICATION_CONTRACT_VALIDATED)

        Functions.pendingContracts[dataObject.contractID] = nil

        API:SendDiscordLog(Config.Translation.WEBHOOK_CONTRACT_SIGNED_BY_BOTH_PARTIES:format(contract.sellerObject.name, contract.buyerObject.name))
    end

    return true
end
exports[Config.ExportNames.s1nLib]:registerServerCallback("signDealContract", function(playerSource, callback, dataObject)
    callback(Functions:SignContract(playerSource, dataObject))
end)

--
-- Misc
--

-- Calculate the VAT based on the amount and the VAT rate
-- @param amount number The amount to calculate the VAT
-- @return number The VAT amount
function Functions:CalculateVAT(amount)
    return math.ceil(amount * Config.Invoice.vat.rate)
end