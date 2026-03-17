Functions = Functions or {}

-- Used for the cooldown between robberies (as a player)
Functions.lastRobberyTime = false

Helpers = Helpers:New()

-- Initialize the script
local alreadyInitialized = false

QBCore = nil
ESX = nil

-- Initialize the script client-side
function Functions:Init()
    if alreadyInitialized then
        return
    end

    alreadyInitialized = true

    Utils:Debug("Initializing...")

    if exports[Config.ExportNames.s1nLib]:getCurrentFrameworkName() == "qbcore" then
        QBCore = exports[Config.ExportNames.s1nLib]:getFrameworkObject()
    elseif exports[Config.ExportNames.s1nLib]:getCurrentFrameworkName() == 'esx' then
        ESX = exports[Config.ExportNames.s1nLib]:getFrameworkObject()
    end

    self:AddTargetInteractions()

    Utils:Debug("Initialized successfully !")
end

-- Add target interactions
function Functions:AddTargetInteractions()
    CreateThread(function()
        exports[Config.ExportNames.s1nLib]:addTargetModels({
            models = Config.AtmModels,
            options = {{
                type = 'client',
                event = 's1n_atmrobbery:startRobbery',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.RobATM,
                canInteract = function(entity, distance, data)
                    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                    if not netId then
                        NetworkRegisterEntityAsNetworked(entity)
                        netId = NetworkGetNetworkIdFromEntity(entity)
                        SetNetworkIdCanMigrate(netId, true)
                        SetNetworkIdExistsOnAllMachines(netId, true)
                    end

                    return not Storage.CooldownAtms[netId] and Config.EnableDrill and not Storage.DrilledAtms[netId]
                end
            }, {
                type = 'client',
                event = 's1n_atmrobbery:plantc4',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.C4ATM,
                canInteract = function(entity, distance, data)
                    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                    if not netId then
                        NetworkRegisterEntityAsNetworked(entity)
                        netId = NetworkGetNetworkIdFromEntity(entity)
                        SetNetworkIdCanMigrate(netId, true)
                        SetNetworkIdExistsOnAllMachines(netId, true)
                    end

                    return not Storage.CooldownAtms[netId] and Config.EnableC4 and not Storage.DrilledAtms[netId]
                end
            }, {
                type = 'client',
                event = 's1n_atmrobbery:attachRopeToAtm',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.AttachRope,
                canInteract = function(entity, distance, data)
                    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                    if not netId then
                        NetworkRegisterEntityAsNetworked(entity)
                        netId = NetworkGetNetworkIdFromEntity(entity)
                        SetNetworkIdCanMigrate(netId, true)
                        SetNetworkIdExistsOnAllMachines(netId, true)
                    end

                    return Storage.DrilledAtms[netId] and not Storage.AttachedAtms[netId].atm
                end
            }, {
                type = 'client',
                event = 's1n_atmrobbery:detachRopeFromAtm',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.DetachRope,
                canInteract = function(entity, distance, data)
                    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                    if not netId then
                        NetworkRegisterEntityAsNetworked(entity)
                        netId = NetworkGetNetworkIdFromEntity(entity)
                        SetNetworkIdCanMigrate(netId, true)
                        SetNetworkIdExistsOnAllMachines(netId, true)
                    end

                    return Storage.DrilledAtms[netId] and Storage.AttachedAtms[netId].atm
                end
            }, {
                type = 'client',
                event = 's1n_atmrobbery:drillAtm',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.DrillATM,
                canInteract = function(entity, distance, data)
                    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                    if not netId then
                        NetworkRegisterEntityAsNetworked(entity)
                        netId = NetworkGetNetworkIdFromEntity(entity)
                        SetNetworkIdCanMigrate(netId, true)
                        SetNetworkIdExistsOnAllMachines(netId, true)
                    end

                    return Storage.DrilledAtms[netId] and not Storage.BrokeAtms[netId] and
                               Storage.CanBeDrilledAtms[netId] and distance < 1.5
                end
            }, {
                type = 'client',
                event = 's1n_atmrobbery:searchAtm',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.SearchATM,
                canInteract = function(entity, distance, data)
                    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                    if not netId then
                        NetworkRegisterEntityAsNetworked(entity)
                        netId = NetworkGetNetworkIdFromEntity(entity)
                        SetNetworkIdCanMigrate(netId, true)
                        SetNetworkIdExistsOnAllMachines(netId, true)
                    end

                    return
                        Storage.DrilledAtms[netId] and Storage.BrokeAtms[netId] and not Storage.SearchedAtms[netId] and
                            distance < 1.5
                end
            }},
            interactionDistance = 2.5
        })

        if Config.UseQBTarget then
            Utils:Debug("Using QB-Target")

            exports['qb-target']:AddTargetBone({'boot'}, {
                options = {{
                    type = 'client',
                    event = 's1n_atmrobbery:attachRopeToVehicle',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.AttachRope,
                    canInteract = function(entity, distance, data)
                        return Helpers:IsVehicleWhitelisted(entity) and Storage.IsRopeInHand and
                                   not Storage.AttachedAtms[Helpers.atmpropnetid].vehicle
                    end
                }, {
                    type = 'client',
                    event = 's1n_atmrobbery:detachRopeFromVehicle',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.DetachRope,
                    canInteract = function(entity, distance, data)
                        return Helpers:IsVehicleWhitelisted(entity) and not Storage.IsRopeInHand and
                                   Storage.AttachedAtms[Helpers.atmpropnetid] and
                                   Storage.AttachedAtms[Helpers.atmpropnetid].vehicle
                    end
                }},
                distance = 2.5
            })

        else
            Utils:Debug("Using OX-Target")

            --[[
            exports['ox_target']:addModel(Config.AtmModels, {
                {
                    name = 's1n_atmrobbery:robatm',
                    event = 's1n_atmrobbery:startRobbery',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.RobATM,
                    canInteract = function(entity, distance, coords, name, boneId)
                        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                        if not netId then
                            NetworkRegisterEntityAsNetworked(entity)
                            netId = NetworkGetNetworkIdFromEntity(entity)
                            SetNetworkIdCanMigrate(netId, true)
                            SetNetworkIdExistsOnAllMachines(netId, true)
                        end

                        return not Storage.CooldownAtms[netId] and Config.EnableDrill and not Storage.DrilledAtms[netId]
                    end
                },
                {
                    name = 's1n_atmrobbery:robatmc4',
                    event = 's1n_atmrobbery:plantc4',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.C4ATM,
                    canInteract = function(entity, distance, coords, name, boneId)
                        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                        if not netId then
                            NetworkRegisterEntityAsNetworked(entity)
                            netId = NetworkGetNetworkIdFromEntity(entity)
                            SetNetworkIdCanMigrate(netId, true)
                            SetNetworkIdExistsOnAllMachines(netId, true)
                        end

                        return not Storage.CooldownAtms[netId] and Config.EnableC4 and not Storage.DrilledAtms[netId]
                    end
                },
                {
                    name = 's1n_atmrobbery:attachtorope',
                    event = 's1n_atmrobbery:attachRopeToAtm',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.AttachRope,
                    canInteract = function(entity, distance, coords, name, boneId)
                        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                        if not netId then
                            NetworkRegisterEntityAsNetworked(entity)
                            netId = NetworkGetNetworkIdFromEntity(entity)
                            SetNetworkIdCanMigrate(netId, true)
                            SetNetworkIdExistsOnAllMachines(netId, true)
                        end

                        return Storage.DrilledAtms[netId] and not Storage.AttachedAtms[netId].atm
                    end
                },
                {
                    name = 's1n_atmrobbery:detachrope',
                    event = 's1n_atmrobbery:detachRopeFromAtm',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.DetachRope,
                    canInteract = function(entity, distance, coords, name, boneId)
                        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                        if not netId then
                            NetworkRegisterEntityAsNetworked(entity)
                            netId = NetworkGetNetworkIdFromEntity(entity)
                            SetNetworkIdCanMigrate(netId, true)
                            SetNetworkIdExistsOnAllMachines(netId, true)
                        end

                        return Storage.DrilledAtms[netId] and Storage.AttachedAtms[netId].atm
                    end
                },
                {
                    name = 's1n_atmrobbery:drillatm',
                    event = 's1n_atmrobbery:drillAtm',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.DrillATM,
                    canInteract = function(entity, distance, coords, name, boneId)
                        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                        if not netId then
                            NetworkRegisterEntityAsNetworked(entity)
                            netId = NetworkGetNetworkIdFromEntity(entity)
                            SetNetworkIdCanMigrate(netId, true)
                            SetNetworkIdExistsOnAllMachines(netId, true)
                        end

                        return Storage.DrilledAtms[netId] and not Storage.BrokeAtms[netId] and Storage.CanBeDrilledAtms[netId] and #(coords - GetEntityCoords(Helpers.atmprop)) < 1.5
                    end
                },
                {
                    name = 's1n_atmrobbery:searchatm',
                    event = 's1n_atmrobbery:searchAtm',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.SearchATM,
                    canInteract = function(entity, distance, coords, name, boneId)
                        local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

                        if not netId then
                            NetworkRegisterEntityAsNetworked(entity)
                            netId = NetworkGetNetworkIdFromEntity(entity)
                            SetNetworkIdCanMigrate(netId, true)
                            SetNetworkIdExistsOnAllMachines(netId, true)
                        end

                        return Storage.DrilledAtms[netId] and Storage.BrokeAtms[netId] and not Storage.SearchedAtms[netId] and #(coords - GetEntityCoords(Helpers.atmprop)) < 1.5
                    end
                }
            })
            ]]
            exports['ox_target']:addGlobalVehicle({{
                bones = 'boot',
                name = 'atmrobberyvehicleattach',
                event = 's1n_atmrobbery:attachRopeToVehicle',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.AttachRope,
                canInteract = function(entity, distance, coords, name, boneId)
                    return Helpers:IsVehicleWhitelisted(entity) and Storage.IsRopeInHand and
                               not Storage.AttachedAtms[Helpers.atmpropnetid].vehicle and
                               #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5
                end
            }, {
                bones = 'boot',
                name = 'atmrobberyvehicledetach',
                event = 's1n_atmrobbery:detachRopeFromVehicle',
                icon = 'fa-solid fa-arrow-right-to-bracket',
                label = Config.Translation.DetachRope,
                canInteract = function(entity, distance, coords, name, boneId)
                    return Helpers:IsVehicleWhitelisted(entity) and not Storage.IsRopeInHand and
                               Storage.AttachedAtms[Helpers.atmpropnetid] and
                               Storage.AttachedAtms[Helpers.atmpropnetid].vehicle and
                               #(coords - GetEntityBonePosition_2(entity, boneId)) < 0.5
                end
            }})
        end
    end)
end

-- Check if the player can start a robbery
-- @param dataObject table The data object containing the robbery type and the ATM net ID
function Functions:CheckStartRobbery(dataObject)
    Utils:Debug("CheckStartRobbery: called")

    -- Check if the cooldown is still active.
    if Functions.lastRobberyTime and (GetGameTimer() - Functions.lastRobberyTime) < Config.Robberies.cooldown then
        API:NotifyPlayer(Config.Translation.CooldownBeforeNextRobbery:format(
            exports[Config.ExportNames.s1nLib]:formatTime(Config.Robberies.cooldown -
                                                              (GetGameTimer() - Functions.lastRobberyTime))))
        return
    end

    exports[Config.ExportNames.s1nLib]:triggerServerCallback("s1n_atmrobbery:canStartRobbery",
        function(receivedDataObject)
            if not receivedDataObject.canContinue then
                if receivedDataObject.errorMessage then
                    API:NotifyPlayer(receivedDataObject.errorMessage)
                    return
                end

                if dataObject.robberyType == "drill" then
                    API:NotifyPlayer(Config.Translation.MissingRope)
                    return
                elseif dataObject.robberyType == "c4" then
                    API:NotifyPlayer(Config.Translation.MissingC4)
                    return
                end
            end

            if dataObject.robberyType == "drill" then
                Helpers:StartDrillScene()
            elseif dataObject.robberyType == "c4" then
                Helpers:PlantBomb(dataObject.atmNetId)
            end
        end, dataObject)
end
