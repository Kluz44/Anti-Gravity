Functions = {}

--
-- Interact with the UI
--


local targetSigned = false
local signed = false

local initialized = false

-- Initialize the UI by sending the config data
function Functions:InitUI()
    Utils:Debug("Initializing the UI")

    while not initialized do
        SendNUIMessage({
            action = "init",
            data = {
                translations = Config.Translation,
                dynamicValues = {
                    ["UI_VAT"] = Config.Invoice.vat.rate * 100
                },
                features = {
                    vat = {
                        enabled = Config.Invoice.vat.enabled,
                        rate = Config.Invoice.vat.rate
                    }
                }
            }
        })

        Wait(500)
    end
end
RegisterNUICallback("receivedInit", function(data, callback)
    initialized = true

    callback({ "ok" })
end)

-- Open the billing menu
function Functions:OpenBillingMenu()
    Utils:Debug("Opening the billing menu")

    SendNUIMessage({
        action = "openUI",
        data = {
            allowReviewSomeoneInvoices = Functions:HasPermission("REVIEW_SOMEONE_INVOICES"),
            allowManageCompanyInvoices = Functions:HasPermission("MANAGE_COMPANY_INVOICES"),
        }
    })
    SetNuiFocus(true, true)
end
exports("openBillingMenu", function ()
    return Functions:OpenBillingMenu()
end)

-- Called by the UI to set the focus after closing the menus
function Functions:CloseBillingMenu(dataObject)
    Utils:Debug("Closing the billing menu")

    if dataObject then
        if dataObject.keepFocus then return end
    end

    SetNuiFocus(false, false)
end
RegisterNUICallback("closeUI", function(data, callback)
    Functions:CloseBillingMenu(data)

    callback({ "ok" })
end)

-- Close the UI
function Functions:CloseUI(dataObject)
    SendNUIMessage({
        action = "closeUI",
        data = dataObject or {}
    })
end

--
-- Invoices
--

-- Send an invite to the player to accept the invoice
-- @param dataObject table The data of the invoice
-- @return boolean true if the player has accepted the invoice, false otherwise
function Functions:SendInviteToPlayer(dataObject)
    Utils:Debug(("Sending an invite with the data: %s"):format(json.encode(dataObject)))

    API:NotifyPlayer(Config.Translation.NOTIFICATION_SENDING_INVOICE_TO_PLAYER)

    local result = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("sendInviteToPlayer", dataObject)

    return result
end

-- Receive an invite to accept or refuse an invoice from a player
-- @param dataObject table The data of the invoice
-- @return boolean true if the player has accepted the invoice, false otherwise
function Functions:ReceiveInviteFromPlayer(dataObject)
    Utils:Debug(("Receiving an invoice with the data: %s"):format(json.encode(dataObject)))

    API:NotifyPlayer(Config.Translation.NOTIFICATION_RECEIVED_INVOICE)

    local promise = promise.new()

    Citizen.CreateThread(function()
        local startTime = GetGameTimer()

        while GetGameTimer() - startTime < 30000 do
            -- ACCEPT with Y
            if IsControlJustReleased(0, 246) then
                API:NotifyPlayer(Config.Translation.NOTIFICATION_ACCEPTED_INVOICE)

                promise:resolve(true)
                return

            -- REFUSE with N
            elseif IsControlJustReleased(0, 249) then
                API:NotifyPlayer(Config.Translation.NOTIFICATION_REFUSED_INVOICE)

                promise:resolve(false)
                return
            end

            Citizen.Wait(0)
        end

        -- Timeout
        API:NotifyPlayer(Config.Translation.NOTIFICATION_NOT_ANSWERED_IN_TIME)

        promise:resolve(false)
    end)

    return Citizen.Await(promise)
end
exports[Config.ExportNames.s1nLib]:registerEvent("receiveInviteFromPlayer", function(callback, dataObject)
    callback(Functions:ReceiveInviteFromPlayer(dataObject))
end)

-- Create an invoice
-- @param dataObject table The data of the invoice
-- @return boolean true if the invoice has been created, false otherwise
function Functions:CreateInvoice(dataObject)
    Utils:Debug("Creating an invoice")

    Utils:Debug(("The invoice data: %s"):format(json.encode(dataObject)))

    -- TODO: Refactor to use a schema using s1n_lib
    if not dataObject.item or dataObject.item == "" or dataObject.item == "default" then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_INVOICE_ITEM_INVALID)

        return false
    end

    if not dataObject.amount or dataObject.amount <= 0 then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_INVOICE_AMOUNT_INVALID)

        return false
    end

    if not dataObject.date or dataObject.date == "" then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_INVOICE_DATE_INVALID)

        return false
    end

    if dataObject.note and string.len(dataObject.note) > Config.Invoice.note.maxLength then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_INVOICE_NOTE_TOO_LONG:format(Config.Invoice.note.maxLength))

        return false
    end

    local closestPlayers = exports[Config.ExportNames.s1nLib]:getClosestPlayers()

    if #closestPlayers == 0 then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_NO_PLAYER_NEARBY)

        return false
    end

    dataObject.receiver = closestPlayers[1].playerSource

    local accepted = self:SendInviteToPlayer(dataObject)

    if not accepted then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_PLAYER_REFUSED_INVITE)

        return false
    end

    exports[Config.ExportNames.s1nLib]:triggerServerCallback("createInvoice", function(success)
        if not success then
            API:NotifyPlayer(Config.Translation.NOTIFICATION_SOMETHING_WENT_WRONG)

            return
        end

        API:NotifyPlayer(Config.Translation.NOTIFICATION_INVOICE_CREATED)
    end, dataObject)

    return true
end
RegisterNUICallback("createInvoice", function(data, callback)
    callback(Functions:CreateInvoice(data))
end)

-- Called when the page 'create-invoice' is loaded
function Functions:OnLoadCreateInvoice()
    Utils:Debug("Loading the create invoice form")

    -- Get the player's job to load the job's items
    local job = exports[Config.ExportNames.s1nLib]:getPlayerJob({
        mappedData = {
            name = true
        }
    })

    local returnData = {
        defaultItems = Config.Invoice.defaultItems,
        jobsItems = {}
    }

    -- If the player is in a job, load the job's items
    local jobsItems = Config.Invoice.jobsItems[job.name]

    if jobsItems then
        returnData.jobsItems = jobsItems.defaultItems
    end

    return returnData
end
RegisterNUICallback("load-create-invoice", function(data, callback)
    callback(Functions:OnLoadCreateInvoice(data))
end)

-- Called when the page 'manage-invoices' is loaded
function Functions:OnLoadManageInvoices(dataObject)
    Utils:Debug(("Loading the manage invoices form with the data: %s"):format(json.encode(dataObject)))

    local invoices = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("getSenderPersonalInvoices", dataObject)

    return { invoices = invoices }
end
RegisterNUICallback("load-manage-invoices", function(data, callback)
    callback(Functions:OnLoadManageInvoices(data))
end)

-- Called when the page 'manage-company-invoices' is loaded
function Functions:OnLoadManageCompanyInvoices(dataObject)
    Utils:Debug(("Loading the manage company invoices form with the data: %s"):format(json.encode(dataObject)))

    local invoices = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("getCompanyInvoices", dataObject)

    return { invoices = invoices }
end
RegisterNUICallback("load-manage-company-invoices", function(data, callback)
    callback(Functions:OnLoadManageCompanyInvoices(data))
end)

-- Called when the pay button is clicked on an invoice
-- @param dataObject table The data of the invoice
-- @return (boolean, string) true if the invoice has been paid, false otherwise and the error key
function Functions:PayInvoice(dataObject)
    Utils:Debug(("Paying the invoice with the data: %s"):format(json.encode(dataObject)))

    local result, errorKey = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("payInvoice", dataObject)

    return result, errorKey
end
RegisterNUICallback("payInvoice", function(data, callback)
    local result, errorKey = Functions:PayInvoice(data)

    if not result then
        exports[Config.ExportNames.s1nLib]:showNotification(Config.Translation[errorKey])
    end

    callback(result)
end)

-- Called when the pay all button is clicked
-- @param dataObject table The data of the invoices
-- @return (boolean, string) true if the invoices have been paid, false otherwise and the error key
function Functions:PayAllInvoices(dataObject)
    Utils:Debug("Paying all invoices with the data: %s", dataObject)

    local result = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("payAllInvoices", dataObject)

    return result
end
RegisterNUICallback("payAllInvoices", function(data, callback)
    local result, errorKey = Functions:PayAllInvoices(data)

    if not result then
        exports[Config.ExportNames.s1nLib]:showNotification(Config.Translation[errorKey])
    end

    callback(result)
end)

-- Called when the page 'review-invoices' is loaded
function Functions:OnLoadReviewInvoices(dataObject)
    Utils:Debug(("Loading the review invoices form with the data: %s"):format(json.encode(dataObject)))

    return true
end
RegisterNUICallback("load-review-invoices", function(data, callback)
    callback(Functions:OnLoadReviewInvoices(data))
end)

-- Called when the button "button-review-invoices-lookup" is clicked
-- @param dataObject table The data of the invoices
-- @return table The invoices
function Functions:LookupCitizenInvoices(dataObject)
    Utils:Debug(("Looking up the citizen invoices with the data: %s"):format(json.encode(dataObject)))

    if not dataObject.targetName or not dataObject.targetName:match("%a+%s%a+") then
        API:NotifyPlayer("You need to provide a valid citizen name. Example: Firstname Lastname")

        return false
    end

    local invoices = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("lookupCitizenInvoices", dataObject)
    if not invoices then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_NO_CITIZEN_NAMED_LIKE_THAT)

        return false
    end

    return { invoices = invoices }
end
RegisterNUICallback("lookupCitizenInvoices", function(data, callback)
    callback(Functions:LookupCitizenInvoices(data))
end)

--
-- Contracts
--

-- Reset the contract variables
function Functions:ResetContractVariables()
    targetSigned = false
    signed = false
end

-- Start the process of creating a contract
-- @param dataObject table The data of the contract
-- @return table|boolean The contract data or false if the contract has not been created
function Functions:CreateContract(dataObject)
    Utils:Debug("Creating a contract")

    Utils:Debug(("The contract data: %s"):format(json.encode(dataObject)))

    if dataObject.contractAmount <= 0 then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_CONTRACT_AMOUNT_INVALID)

        return false
    end

    if not dataObject.item or dataObject.item == "" or dataObject.item == "default" then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_CONTRACT_ITEM_INVALID)

        return false
    end

    if dataObject.item == "inventory-item" and (not dataObject.inventoryItem.quantity or dataObject.inventoryItem.quantity == "") then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_CONTRACT_QUANTITY_INVALID)

        return false
    end

    if dataObject.item == "vehicle" then
        if dataObject.nearestVehicle == -1 then
            API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_CONTRACT_VEHICLE_INVALID)

            return false
        end
    end

    --[[
    -- TODO (future update): Add an invite to the player to sign the contract to avoid people spamming the contract creation
    local accepted, timeout = exports[Config.ExportNames.s1nLib]:invitePlayerToAction("signDealContract", {
        timeout = 1000 * 60 * 5 -- TODO: Add a Config variable
    })

    if timeout then
        API:NotifyPlayer("The player has not signed the contract in time")
        return
    end

    if not accepted then
        API:NotifyPlayer("The player has refused the contract")
        return
    end
    ]]

    self:ResetContractVariables()

    local contractData = {
        contractType = dataObject.item, -- item or vehicle
        sellerName = exports[Config.ExportNames.s1nLib]:getPlayerFullName(),
        closestPlayer = dataObject.closestPlayer,
        contractAmount = dataObject.contractAmount,
    }

    if dataObject.item == "vehicle" then
        contractData.vehicle = dataObject.nearestVehicle
    elseif dataObject.item == "inventory-item" then
        contractData.inventoryItem = dataObject.inventoryItem
    end

    -- Send the contract to the other player to sign it
    local result = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("sendContractToPlayer", contractData)
    if not result then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_SOMETHING_WENT_WRONG)

        return false
    end

    contractData.contractID = result.contractID

    return contractData
end
RegisterNUICallback("createContract", function(dataObject, callback)
    callback(Functions:CreateContract(dataObject))
end)

-- Called when the player received a contract from another player
-- @param dataObject table The data of the contract
function Functions:ReceiveContractFromPlayer(dataObject)
    self:ResetContractVariables()

    SendNUIMessage({
        action = "openContractUI",
        data = dataObject
    })
    SetNuiFocus(true, true)

    return { ok = true }
end
exports[Config.ExportNames.s1nLib]:registerEvent("receiveContractFromPlayer", function(callback, dataObject)
    callback(Functions:ReceiveContractFromPlayer(dataObject))
end)

-- Called when the page 'create-contract' is loaded
function Functions:OnLoadCreateContract()
    Utils:Debug("Loading the create contract form")

    local closestPlayer = exports[Config.ExportNames.s1nLib]:getClosestPlayer({
        baseCoords = GetEntityCoords(PlayerPedId()),
        maxDistance = Config.Contract.closestPlayer.distance,
    }, {
        mapData = {
            identifier = true,
            frameworkName = true,
            playerSource = true
        }
    })
    if not closestPlayer then
        API:NotifyPlayer(Config.Translation.NOTIFICATION_ERROR_NO_PLAYER_NEARBY)

        return false
    end

    Utils:Debug("The closest player: %s", closestPlayer)

    local inventoryItems = exports[Config.ExportNames.s1nLib]:getPlayerItems({}, {
        mapData = {
            label = true,
            name = true,
            amount = true
        }
    })
    Utils:Debug("The player's inventory items: %s", inventoryItems)
    local nearestVehicle = exports[Config.ExportNames.s1nLib]:getNearestVehicle({ distance = Config.Contract.closestOwnedVehicle.distance, owned = true })
    Utils:Debug("The nearest vehicle: %s", nearestVehicle)

    return {
        inventoryItems = inventoryItems,
        nearestVehicle = nearestVehicle,
        closestPlayer = closestPlayer
    }
end
RegisterNUICallback("load-create-contract", function(data, callback)
    callback(Functions:OnLoadCreateContract(data))
end)

function Functions:SignContract(dataObject)
    Utils:Debug(("Signing the contract with the data: %s"):format(json.encode(dataObject)))

    local success, errorKey = exports[Config.ExportNames.s1nLib]:awaitTriggerServerEvent("signDealContract", dataObject)
    if not success then
        if errorKey then
            API:NotifyPlayer(Config.Translation[errorKey])
        else
            API:NotifyPlayer(Config.Translation.NOTIFICATION_SOMETHING_WENT_WRONG)

            self:CloseUI()
        end

        return false
    end

    if targetSigned then
        self:CloseUI()
    end

    signed = true

    return { ok = true }
end
RegisterNUICallback("contractSigned", function(data, callback)
    callback(Functions:SignContract(data))
end)

-- Called when the contract has been signed by the target player
function Functions:ContractSignedByTarget(dataObject)
    SendNUIMessage({
        action = "contractSignedByTarget",
        data = dataObject
    })

    targetSigned = true

    if not signed then return end

    Wait(1000)

    self:CloseUI()

    return { ok = true }
end
exports[Config.ExportNames.s1nLib]:registerEvent("contractSignedByTarget", function(callback, dataObject)
    callback(Functions:ContractSignedByTarget(dataObject))
end)

--
-- Permissions
--

-- Check if the player has the permission to do something
-- @param permission string The permission to check
-- @return boolean true if the player has the permission, false otherwise
function Functions:HasPermission(permission)
    -- TODO: Move HasPermission to s1nLib to handle all the permissions
    local job = exports[Config.ExportNames.s1nLib]:getPlayerJob({
        lowercaseJobName = true,
        lowercaseJobGradeName = true,
        mapData = {
            name = true,
            grade = {
                name = true
            }
        }
    })

    local jobName = job.name
    local jobGradeName = job.grade.name

    Utils:Debug(("Checking the permission %s for the job %s and the job grade %s"):format(permission, jobName, jobGradeName))

    if not Config.Permissions[permission] then
        return false
    end

    if not Config.Permissions[permission].jobs[jobName] then
        return false
    end

    if not Config.Permissions[permission].jobs[jobName][jobGradeName] then
        return false
    end

    Utils:Debug(("The player has the permission %s"):format(permission))

    return true
end