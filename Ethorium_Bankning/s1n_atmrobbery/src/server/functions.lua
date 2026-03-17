Functions = {}

Functions.robberyCooldowns = {}

function Functions:HasEnoughPoliceOfficers()
    local policeOnline = 0

    for notificationJobName, _ in pairs(Config.NotificationJobs) do
        local onlinePlayers = exports[Config.ExportNames.s1nLib]:getOnlinePlayers({
            filterData = {
                jobName = notificationJobName
            }
        })

        policeOnline = policeOnline + #onlinePlayers
    end

    local enoughPoliceOfficers = policeOnline >= Config.MinPoliceOnline

    return enoughPoliceOfficers
end

-- TODO: To be removed because it is used in the first check event
exports[Config.ExportNames.s1nLib]:registerServerCallback("s1n_atmrobbery:enoughPoliceOfficers",
    function(playerSource, callback)
        callback(Functions:HasEnoughPoliceOfficers())
    end)

if ESX then
    ESX.RegisterServerCallback('s1n_atmrobbery:checkItem', function(source, cb, items)
        local esxPlayer = ESX.GetPlayerFromId(source)

        for _, itemName in pairs(items) do
            if Config.UseQuasarInventory then
                if exports['qs-inventory']:GetItemTotalAmount(source, itemName) == 0 then
                    return cb(false)
                end
            elseif Config.UseOXInventory then
                if exports['ox_inventory']:GetItemCount(source, itemName) == 0 then
                    return cb(false)
                end
            else
                local item = esxPlayer.getInventoryItem(itemName)

                -- Check if the item exists and if the player has it
                if not item then
                    return cb(false)
                end
                if item.count == 0 then
                    return cb(false)
                end
            end
        end

        cb(true)
    end)

elseif QBCore then

    QBCore.Functions.CreateCallback('s1n_atmrobbery:checkItem', function(source, cb, items)
        local qbPlayer = QBCore.Functions.GetPlayer(source)

        for _, itemName in pairs(items) do
            if Config.UseQuasarInventory then
                if exports['qs-inventory']:GetItemTotalAmount(source, itemName) == 0 then
                    return cb(false)
                end
            elseif Config.UseOXInventory then
                if exports['ox_inventory']:GetItemCount(source, itemName) == 0 then
                    return cb(false)
                end
            else
                local item = qbPlayer.Functions.GetItemByName(itemName)

                -- Check if the item exists and if the player has it
                if not item then
                    return cb(false)
                end
                if not item.amount == 0 then
                    return cb(false)
                end
            end
        end

        cb(true)
    end)
end

-- Check if there still is a cooldown between robberies for this specific atm position
-- @param atmPositionHash string The atm position hash
-- @return boolean Whether there is a cooldown between robberies for this specific atm position
function Functions:CheckRobberyAtmCooldown(atmPositionHash)
    if not Functions.robberyCooldowns then
        return true
    end

    -- If the atm position hash is not in the robbery cooldowns, it means that the atm has never been robbed
    if not Functions.robberyCooldowns[atmPositionHash] then
        return true
    end

    local lastRobbed = Functions.robberyCooldowns[atmPositionHash].lastRobbed

    if GetGameTimer() - lastRobbed < Config.Robberies.atmCooldown then
        return false
    end

    return true
end

-- Get the remaining time of the cooldown between robberies for this specific atm position
-- @param atmPositionHash string The atm position hash
-- @return number The remaining time of the cooldown between robberies for this specific atm position
function Functions:GetRobberyAtmCooldownRemainingTime(atmPositionHash)
    local lastRobbed = Functions.robberyCooldowns[atmPositionHash].lastRobbed

    if GetGameTimer() - lastRobbed < Config.Robberies.atmCooldown then
        local remainingTime = Config.Robberies.atmCooldown - (GetGameTimer() - lastRobbed)
        return remainingTime
    end

    return 0
end

-- Called before starting a robbery
exports[Config.ExportNames.s1nLib]:registerServerCallback("s1n_atmrobbery:canStartRobbery",
    function(playerSource, callback, dataObject)
        local canContinue = true

        local nearAtmPosition = exports[Config.ExportNames.s1nLib]:isNearAnATM({
            playerSource = playerSource,
            maxDistance = 30
        })
        if not nearAtmPosition.found then
            Utils:Debug(
                "The player is far from an ATM position. If the position is not detected, you're probably using a custom mapping. If so, go to s1n_lib/configuration/utils.config.lua and look for atmModels")
            return false
        end

        if not Functions:HasEnoughPoliceOfficers() then
            callback({
                canContinue = false,
                errorMessage = Config.Translation.NotEnoughPolice
            })
            return
        end

        local atmPositionHash = exports[Config.ExportNames.s1nLib]:hashVector3(nearAtmPosition.position)

        if not Functions:CheckRobberyAtmCooldown(atmPositionHash) then
            callback({
                canContinue = false,
                errorMessage = Config.Translation.CooldownBetweenSpecificATMRobbery:format(
                    exports[Config.ExportNames.s1nLib]:formatTime(
                        Functions:GetRobberyAtmCooldownRemainingTime(atmPositionHash)))
            })
            return
        end

        if dataObject.robberyType == "drill" then
            -- This means that someone is trying to hack the script
            if not Config.EnableDrill then
                Utils:Debug("Drill robbery is disabled")
                return false
            end

            if not exports[Config.ExportNames.s1nLib]:hasItemInInventory(playerSource, Config.Items.rope) then
                canContinue = false
            end

            if not exports[Config.ExportNames.s1nLib]:hasItemInInventory(playerSource, Config.Items.drill) then
                canContinue = false
            end
        elseif dataObject.robberyType == "c4" then
            -- This means that someone is trying to hack the script
            if not Config.EnableC4 then
                Utils:Debug("C4 robbery is disabled")
                return false
            end

            if not exports[Config.ExportNames.s1nLib]:hasItemInInventory(playerSource, Config.Items.c4) then
                canContinue = false
            end
        end

        if canContinue then
            if not Functions.robberyCooldowns[atmPositionHash] then
                Functions.robberyCooldowns[atmPositionHash] = {}
            end

            Functions.robberyCooldowns[atmPositionHash].lastRobbed = GetGameTimer()
        end

        callback({
            canContinue = canContinue
        })
    end)

RegisterServerEvent('s1n_atmrobbery:addDrilledAtm', function(netId)
    TriggerClientEvent('s1n_atmrobbery:addDrilledAtm', -1, netId)
end)

RegisterServerEvent('s1n_atmrobbery:updateAttachedAtm', function(netId, type, targetEntityNetId)
    TriggerClientEvent('s1n_atmrobbery:updateAttachedAtm', -1, netId, type, targetEntityNetId)
end)

RegisterServerEvent('s1n_atmrobbery:addCanBeDrilledAtm', function(netId)
    TriggerClientEvent('s1n_atmrobbery:addCanBeDrilledAtm', -1, netId)
end)

RegisterServerEvent('s1n_atmrobbery:addBrokenAtm', function(netId)
    TriggerClientEvent('s1n_atmrobbery:addBrokenAtm', -1, netId)
end)

RegisterServerEvent('s1n_atmrobbery:addSearchedAtm', function(netId)
    TriggerClientEvent('s1n_atmrobbery:addSearchedAtm', -1, netId)
end)

RegisterServerEvent('s1n_atmrobbery:clearAtm', function(netId)
    TriggerClientEvent('s1n_atmrobbery:clearAtm', -1, netId)
end)

RegisterServerEvent('s1n_atmrobbery:giveReward', function(type)
    local playerSource = source

    Utils:Debug("Giving reward to player : " .. GetPlayerName(playerSource))

    local reward = math.random(Config.AtmReward.min, Config.AtmReward.max)

    if ESX then
        local esxPlayer = ESX.GetPlayerFromId(playerSource)
        if not esxPlayer then
            return
        end

        if Config.CashItem.enable then
            if Config.UseQuasarInventory then
                exports['qs-inventory']:AddItem(src, Config.CashItem.itemName, reward)
            elseif Config.UseOXInventory then
                exports['ox_inventory']:AddItem(src, Config.CashItem.itemName, reward)
            else
                esxPlayer.addInventoryItem(Config.CashItem.itemName, reward)
            end
        else
            esxPlayer.addAccountMoney('money', reward)
        end

        TriggerClientEvent('s1n_atmrobbery:notification', playerSource, (Config.Translation.Reward):format(reward))

        if type == 1 then
            API:SendDiscordLog(('%s received $%s for ended successfully the Drill Robbery'):format(GetPlayerName(
                playerSource), reward))
        elseif type == 2 then
            API:SendDiscordLog(('%s received $%s for ended successfully the C4 Robbery'):format(GetPlayerName(
                playerSource), reward))
        end
    elseif QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(playerSource)
        if not qbPlayer then
            return
        end

        if Config.CashItem.enable then
            if Config.UseQuasarInventory then
                exports['qs-inventory']:AddItem(playerSource, Config.CashItem.itemName, reward)
            elseif Config.UseOXInventory then
                exports['ox_inventory']:AddItem(playerSource, Config.CashItem.itemName, reward)
            else
                qbPlayer.Functions.AddItem(Config.CashItem.itemName, reward)
            end
        else
            qbPlayer.Functions.AddMoney('cash', reward)
        end

        TriggerClientEvent('s1n_atmrobbery:notification', playerSource, (Config.Translation.Reward):format(reward))

        if type == 1 then
            API:SendDiscordLog(('%s received $%s for ended successfully the Drill Robbery'):format(GetPlayerName(
                playerSource), reward))
        elseif type == 2 then
            API:SendDiscordLog(('%s received $%s for ended successfully the C4 Robbery'):format(GetPlayerName(
                playerSource), reward))
        end
    end
end)

RegisterServerEvent('s1n_atmrobbery:policeAlert', function(coords)
    Utils:Debug("Sending police alert")

    API:SendAlert(coords)

    if ESX then
        for _, player in pairs(GetPlayers()) do
            local esxPlayer = ESX.GetPlayerFromId(player)

            if esxPlayer then
                if Config.NotificationJobs[esxPlayer.job.name] then
                    API:SendAlertToPoliceOfficer(player, coords)
                end
            end
        end
    elseif QBCore then
        for _, player in pairs(GetPlayers()) do
            local qbPlayer = QBCore.Functions.GetPlayer(tonumber(player))

            if qbPlayer then
                if Config.NotificationJobs[qbPlayer.PlayerData.job.name] then
                    API:SendAlertToPoliceOfficer(player, coords)
                end
            end
        end
    end
end)

RegisterServerEvent('s1n_atmrobbery:log', function(type)
    local playerSource = source

    if type == 1 then
        API:SendDiscordLog(('%s just started a Drill Robbery'):format(GetPlayerName(playerSource)))
    elseif type == 2 then
        API:SendDiscordLog(('%s just started a C4 Robbery'):format(GetPlayerName(playerSource)))
    end
end)

RegisterServerEvent('s1n_atmrobbery:removeItem', function(item)
    local source = source
    Utils:Debug("Removing item : " .. item .. "for player : " .. GetPlayerName(source))

    if ESX then
        local esxPlayer = ESX.GetPlayerFromId(source)
        if not esxPlayer then
            return
        end

        if Config.UseQuasarInventory then
            exports['qs-inventory']:RemoveItem(source, item, 1)
        elseif Config.UseOXInventory then
            exports['ox_inventory']:RemoveItem(source, item, 1)
        else
            esxPlayer.removeInventoryItem(item, 1)
        end
    elseif QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        if not qbPlayer then
            return
        end

        if Config.UseQuasarInventory then
            exports['qs-inventory']:RemoveItem(source, item, 1)
        elseif Config.UseOXInventory then
            exports['ox_inventory']:RemoveItem(source, item, 1)
        else
            qbPlayer.Functions.RemoveItem(item, 1)
        end
    end
end)

RegisterServerEvent('s1n_atmrobbery:giveRopeBack', function()
    if ESX then
        local esxPlayer = ESX.GetPlayerFromId(source)
        esxPlayer.addInventoryItem(Config.Items.rope, 1)
    elseif QBCore then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        qbPlayer.Functions.AddItem(Config.Items.rope, 1)
    end
end)
