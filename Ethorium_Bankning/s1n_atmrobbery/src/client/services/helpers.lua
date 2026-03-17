Helpers = { }
Helpers.__index = Helpers

function Helpers:New()
    local object = { }
    setmetatable(object, Helpers)

    object.vehicle = nil
    object.rope = nil
    object.atmprop = nil
    object.atmpropnetid = nil
    object.cashprop = nil
    object.moneytarget = nil

    return object
end

function Helpers:LoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)

        while not HasModelLoaded(model) do Wait(0) end
    end
end

function Helpers:GetClosestAtm()
    Utils:Debug("Getting closest atm")

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, model in pairs(Config.AtmModels) do
        local closestObject = GetClosestObjectOfType(playerCoords, 5.0, GetHashKey(model))

        if DoesEntityExist(closestObject) then
            Utils:Debug("Found closest atm : " .. model)

            return closestObject, model
        end
    end
end

function Helpers:NetworkAttachRopeToVehicle(atmNetId, targetEntityNetId)
    Utils:Debug(("Network: Attaching rope to vehicle (atmNetID=%s, targetEntityNetID=%s)"):format(atmNetId, targetEntityNetId))

    local vehicle = NetworkGetEntityFromNetworkId(targetEntityNetId)
    local atmProp = NetworkGetEntityFromNetworkId(atmNetId)
    local atmCoords = GetEntityCoords(atmProp)

    Utils:Debug(("Network: Attaching rope to vehicle (atmProp=%s, vehicle=%s, atmCoords=%s)"):format(atmProp, vehicle, atmCoords))

    AttachEntitiesToRope(self.rope, vehicle, atmProp, GetOffsetFromEntityInWorldCoords(vehicle, 0, -1.8, 0.0), atmCoords.x, atmCoords.y, atmCoords.z + 1.0, 7.0, 0, 0, 'rope_attach_a', 'rope_attach_b')
end

function Helpers:AttachRopeToVehicle()
    Utils:Debug("Start: Attaching rope to vehicle")

    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then return Utils:Debug("Player MUST NOT be in a vehicle") end

    local closestVehicle

    if ESX then
        closestVehicle = ESX.Game.GetClosestVehicle()
    elseif QBCore then
        closestVehicle = QBCore.Functions.GetClosestVehicle()
    end

    self.vehicle = closestVehicle

    TaskTurnPedToFaceEntity(playerPed, self.vehicle, 1000)

    -- Sync Rope between players
    local vehicleNetId

    if not NetworkGetEntityIsNetworked(self.vehicle) then
        Utils:Debug(("AttachRopeToVehicle: Registering vehicle as networked: %s"):format(self.vehicle))
        NetworkRegisterEntityAsNetworked(self.vehicle)
        vehicleNetId = NetworkGetNetworkIdFromEntity(self.vehicle)
        SetNetworkIdCanMigrate(vehicleNetId, true)
        SetNetworkIdExistsOnAllMachines(vehicleNetId, true)
    else
        vehicleNetId = NetworkGetNetworkIdFromEntity(self.vehicle)
    end
    
    Utils:Debug(("AttachRopeToVehicle: Getting vehicle netId: %s"):format(vehicleNetId))

    TriggerServerEvent('s1n_atmrobbery:updateAttachedAtm', self.atmpropnetid, 'vehicle', vehicleNetId)

    -- Use to have control for freezing
    NetworkRequestControlOfEntity(self.atmprop)

    -- Create persistant entity
    SetEntityAsMissionEntity(self.atmprop, false, false)

    FreezeEntityPosition(self.atmprop, false)

    Utils:Debug("Check freeze position for ATM: " .. tostring(IsEntityPositionFrozen(self.atmprop)))
    SetObjectPhysicsParams(self.atmprop, 170.0, -1.0, 30.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0)

    Storage.IsRopeInHand = false

    self:Notification(Config.Translation.GoFarAway)

    while true do
        if #(Storage.BaseAtmLocation - GetEntityCoords(self.atmprop)) > Config.DrillAfterDistance then
            Utils:Debug("Added ATM to CanBeDrill with netId: " .. self.atmpropnetid)
            TriggerServerEvent('s1n_atmrobbery:addCanBeDrilledAtm', self.atmpropnetid)

            break
        end

        Wait(1000)
    end
end

function Helpers:NetworkAttachRopeToAtm(atmNetId, targetEntityNetId)
    Utils:Debug("Network: Attaching rope to atm")

    local atmProp = NetworkGetEntityFromNetworkId(atmNetId)
    local atmCoords = GetEntityCoords(atmProp)

    local targetEntity = NetworkGetEntityFromNetworkId(targetEntityNetId)

    RopeLoadTextures()

    self.rope = AddRope(1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1, 7.0, 1.0, 0, 0, 0, 0, 0, 0)

    AttachEntitiesToRope(self.rope, atmProp, targetEntity, atmCoords.x, atmCoords.y, atmCoords.z + 1.0, GetPedBoneCoords(targetEntity, 6286, 0.0, 0.0, 0.0), 7.0, 0, 0, 'rope_attach_a', 'rope_attach_b')
end

-- Attach a rope to an ATM
function Helpers:AttachRopeToAtm()
    Utils:Debug("Start: Attaching rope to atm")

    if not exports[Config.ExportNames.s1nLib]:hasItemInInventory(Config.Items.rope, 1) then
        return Helpers:Notification(Config.Translation.MissingRope)
    end

    local closestAtm, _ = Helpers:GetClosestAtm()
    if not closestAtm then return end

    -- Removing the rope item because it's been used
    TriggerServerEvent('s1n_atmrobbery:removeItem', Config.Items.rope)

    local atmObject, _ = Helpers:GetClosestAtm()
    if not atmObject then return end

    Utils:Debug("Closest atm found")

    self.atmprop = atmObject
    self.atmpropnetid = NetworkGetNetworkIdFromEntity(self.atmprop)

    Storage.BaseAtmLocation = GetEntityCoords(self.atmprop)

    local playerPed = PlayerPedId()

    NetworkRequestControlOfEntity(self.atmprop)

    -- Sync Rope between players
    local playerNetId = NetworkGetNetworkIdFromEntity(playerPed)

    Utils:Debug("Added ATM to AttachedAtms with netId: " .. self.atmpropnetid .. " | playerNetId " .. playerNetId)

    TriggerServerEvent('s1n_atmrobbery:updateAttachedAtm', self.atmpropnetid, 'atm', playerNetId)

    Storage.IsRopeInHand = true
end

function Helpers:NetworkDetachRopeFromAtm(atmNetId)
    Utils:Debug("Network: Detaching rope from atm")

    local atmProp = NetworkGetEntityFromNetworkId(atmNetId)

    DetachRopeFromEntity(self.rope, atmProp)
    DeleteRope(self.rope)
end

function Helpers:DetachRopeFromAtm()
    Utils:Debug("Start: Detaching rope from atm")

    TriggerServerEvent("s1n_atmrobbery:giveRopeBack")

    TriggerServerEvent('s1n_atmrobbery:updateAttachedAtm', self.atmpropnetid, 'atm')

    Storage.IsRopeInHand = false
end

function Helpers:LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(50)
    end
end

function Helpers:LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(0)
    end
end

function Helpers:StartDrillRobbery()
    Utils:Debug("Starting drill scene")

    TriggerServerEvent('s1n_atmrobbery:policeAlert', GetEntityCoords(PlayerPedId()))
    TriggerServerEvent('s1n_atmrobbery:log', 1)

    local defaultPlayerCoords = GetEntityCoords(PlayerPedId())

    local object, model = Helpers:GetClosestAtm()
    local defaultAtmCoords = GetEntityCoords(object)
    local defaultAtmHeading = GetEntityHeading(object)

    -- INFO: If I don't create a new one, there will be an issue with the fact that it will disappear after a specific distance
    SetEntityAsMissionEntity(object, false, true)
    DeleteEntity(object)

    object = CreateObject(model, defaultAtmCoords, true, true, false)
    FreezeEntityPosition(object, true)
    SetEntityHeading(object, defaultAtmHeading)

    self.atmprop = object
    self.atmpropnetid = NetworkGetNetworkIdFromEntity(object)

    if not NetworkDoesNetworkIdExist(self.atmpropnetid) then
        NetworkRegisterEntityAsNetworked(self.atmprop)
        self.atmpropnetid = NetworkGetNetworkIdFromEntity(self.atmprop)
    end

    local atmCoords = GetEntityCoords(self.atmprop)
    atmCoords = vector3(atmCoords.x, atmCoords.y, atmCoords.z + 1.8)

    local atmRotation = GetEntityRotation(self.atmprop)
    Helpers:LoadAnimDict('anim_heist@hs3f@ig9_vault_drill@laser_drill@')
    Helpers:LoadModel('hei_p_m_bag_var22_arm_s')
    Helpers:LoadModel('hei_prop_heist_drill')

    RequestAmbientAudioBank('DLC_HEIST_FLEECA_SOUNDSET', 0)
    RequestAmbientAudioBank('DLC_MPHEIST\\HEIST_FLEECA_DRILL', 0)
    RequestAmbientAudioBank('DLC_MPHEIST\\HEIST_FLEECA_DRILL_2', 0)
    RequestNamedPtfxAsset('scr_gr_bunk')

    while not HasNamedPtfxAssetLoaded('scr_gr_bunk') do Wait(0) end

    UseParticleFxAssetNextCall('scr_gr_bunk')

    local soundId = GetSoundId()
    local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)

    SetCamActive(cam, true)
    RenderScriptCams(true, 0, 3000, 1, 0)

    local bag = CreateObject('hei_p_m_bag_var22_arm_s', defaultPlayerCoords, 1, 0, 0)
    local drill = CreateObject('hei_prop_heist_drill', defaultPlayerCoords, 1, 0, 0)
    local intro = NetworkCreateSynchronisedScene(atmCoords, atmRotation, 2, true, false, 1065353216, 0, 1.3)

    NetworkAddPedToSynchronisedScene(PlayerPedId(), intro, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'intro', 4.0, -4.0, 1033, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, intro, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'bag_intro', 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(drill, intro, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'intro_drill_bit', 1.0, -1.0, 1148846080)

    local startCam = NetworkCreateSynchronisedScene(atmCoords, atmRotation, 2, true, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(PlayerPedId(), startCam, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'drill_straight_start', 4.0, -4.0, 1033, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, startCam, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'bag_drill_straight_start', 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(drill, startCam, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'drill_straight_start_drill_bit', 1.0, -1.0, 1148846080)

    local exitCam = NetworkCreateSynchronisedScene(atmCoords, atmRotation, 2, true, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(PlayerPedId(), exitCam, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'exit', 4.0, -4.0, 1033, 0, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bag, exitCam, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'bag_exit', 1.0, -1.0, 1148846080)
    NetworkAddEntityToSynchronisedScene(drill, exitCam, 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'exit_drill_bit', 1.0, -1.0, 1148846080)
    NetworkStartSynchronisedScene(intro)
    PlayCamAnim(cam, 'intro_cam', 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', atmCoords, atmRotation, 0, 2)
    Wait(GetAnimDuration('anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'intro') * 1000)
    NetworkStartSynchronisedScene(startCam)
    PlayCamAnim(cam, 'drill_straight_start_cam', 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', atmCoords, atmRotation, 0, 2)
    PlaySoundFromEntity(soundId, 'Drill', drill, 'DLC_HEIST_FLEECA_SOUNDSET', 1, 0)

    local particleHandle = StartParticleFxLoopedAtCoord('scr_gr_bunk_mill_metal_shards', atmCoords, 0.0, 0.0, 0.0, 5.0, false, false, false)
    SetParticleFxLoopedColour(particleHandle, 0, 255, 0 ,0)

    if exports['ox_lib']:progressBar({
        duration = Config.ProgressDuration.drillfirst,
        label = Config.Translation.DrillingAtm,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true }
    }) then
        StopSound(soundId)
        NetworkStartSynchronisedScene(exitCam)
        StopParticleFxLooped(particleHandle, false)

        PlayCamAnim(cam, 'exit_cam', 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', atmCoords, atmRotation, 0, 2)

        Wait(GetAnimDuration('anim_heist@hs3f@ig9_vault_drill@laser_drill@', 'exit') * 1000)

        RenderScriptCams(false, false, 0, 1, 0)
        DestroyCam(cam, false)

        ClearPedTasks(PlayerPedId())
        DeleteObject(bag)
        DeleteObject(drill)

        TriggerServerEvent('s1n_atmrobbery:addDrilledAtm', self.atmpropnetid)
    end
end

-- This function is called when the player is close enough to the ATM and wants to start the robbery
function Helpers:StartDrillScene()
    Utils:Debug("Checking if there is enough police online")

    exports[Config.ExportNames.s1nLib]:triggerServerCallback("s1n_atmrobbery:enoughPoliceOfficers", function(areEnough)
        if not areEnough then
            return Helpers:Notification(Config.Translation.NotEnoughPolice)
        end

        Functions.lastRobberyTime = GetGameTimer()

        self:StartDrillRobbery()
    end)
end

function Helpers:DrillAtm()
    Utils:Debug("Drilling atm")
    TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_CONST_DRILL', 0, true)

    if exports['ox_lib']:progressBar({
        duration = Config.ProgressDuration.drillsecond,
        label = Config.Translation.DrillingAtm,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true }
    }) then
        ClearPedTasks(PlayerPedId())

        local position = GetEntityCoords(PlayerPedId())
        self:LoadModel("prop_tool_jackham")
        local drillToolObject = GetClosestObjectOfType(position.x, position.y, position.z, 15.0, "prop_tool_jackham", false, false, false)
        SetEntityAsMissionEntity(drillToolObject, false, true)
        DeleteObject(drillToolObject)

        TriggerServerEvent('s1n_atmrobbery:addBrokenAtm', self.atmpropnetid)
    end
end

function Helpers:NetworkDetachRopeFromVehicle(targetEntityNetId)
    Utils:Debug("Network: Detaching atm")

    local vehicle = NetworkGetEntityFromNetworkId(targetEntityNetId)

    DetachRopeFromEntity(self.rope, vehicle)
end

function Helpers:DetachAtm()
    Utils:Debug("Start: Detaching atm")

    local vehicleNetId = NetworkGetNetworkIdFromEntity(self.vehicle)

    TriggerServerEvent('s1n_atmrobbery:updateAttachedAtm', self.atmpropnetid, 'vehicle', vehicleNetId)
end

function Helpers:SearchAtm()
    Utils:Debug("Searching atm")

    Helpers:LoadAnimDict('missexile3')
    TaskPlayAnim(PlayerPedId(), 'missexile3', 'ex03_dingy_search_case_base_michael', 8.0, -8.0, -1, 1, 0, false, false, false)

    if exports['ox_lib']:progressBar({
        duration = Config.ProgressDuration.search,
        label = Config.Translation.SearchingAtm,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true }
    }) then
        ClearPedTasks(PlayerPedId())

        TriggerServerEvent('s1n_atmrobbery:addSearchedAtm', self.atmpropnetid)
        TriggerServerEvent('s1n_atmrobbery:clearAtm', self.atmpropnetid)

        if math.random(1, 100) < Config.GetMoneyChance then
            TriggerServerEvent('s1n_atmrobbery:giveReward', 1)
        else
            self:Notification(Config.Translation.NoMoney)
        end

        Utils:Debug("Searching atm finished successfully")
    end
end

function Helpers:CreateRobberyBlip(coords)
    Utils:Debug("Creating robbery blip")

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 2.0)
    SetBlipColour(blip, 3)
    PulseBlip(blip)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Translation.BlipName)
    EndTextCommandSetBlipName(blip)

    SetTimeout(Config.NotificationTimeout, function()
        Utils:Debug("Removing robbery blip")
        RemoveBlip(blip)
    end)
end

function Helpers:ClearAtm(netId)
    Utils:Debug("Clearing atm")

    Storage.CooldownAtms[netId] = true

    SetTimeout(Config.AtmCooldown, function()
        DeleteEntity(self.atmprop)
        DeleteRope(self.rope)
        Storage.DrilledAtms[netId] = nil
        Storage.AttachedAtms[netId] = nil
        Storage.BrokeAtms[netId] = nil
        Storage.SearchedAtms[netId] = nil
        Storage.CanBeDrilledAtms[netId] = nil
        Storage.CooldownAtms[netId] = nil
    end)
end

function Helpers:StartBombRobbery()
    Utils:Debug("Planting bomb")

    TriggerServerEvent('s1n_atmrobbery:log', 2)
    TriggerServerEvent('s1n_atmrobbery:policeAlert', GetEntityCoords(PlayerPedId()))

    local object, model = Helpers:GetClosestAtm()

    self.atmprop = object
    self.atmpropnetid = NetworkGetNetworkIdFromEntity(object)

    if not NetworkDoesNetworkIdExist(self.atmpropnetid) then
        NetworkRegisterEntityAsNetworked(object)
        self.atmpropnetid = NetworkGetNetworkIdFromEntity(object)
    end

    Utils:Debug(("Atm prop net id : %s"):format(self.atmpropnetid))

    if Config.UseOXInventory then
        local c4SlotID = exports['ox_inventory']:GetSlotIdWithItem(Config.Items.c4)
        if not c4SlotID then return Utils:Debug("Player doesn't have the c4 item") end

        exports['ox_inventory']:useSlot(c4SlotID)
        Utils:Debug("Used c4 item with ox_inventory")
    else
        -- OX Inventory doesn't let using this native
        local stickyBombHash = GetHashKey('weapon_stickybomb')

        GiveWeaponToPed(PlayerPedId(), stickyBombHash, 1, false, true)
        SetCurrentPedWeapon(PlayerPedId(), stickyBombHash, true)
    end

    local coords = GetEntityCoords(object)
    local heading = GetEntityHeading(object)

    TaskPlantBomb(PlayerPedId(), coords.x, coords.y, coords.z, heading)
    self:Notification(Config.Translation.Detonate)

    SetTimeout(2000, function()
        TriggerServerEvent('s1n_atmrobbery:removeItem', Config.Items.c4)
    end)

    while true do
        if IsControlJustReleased(0, 47) then
            -- If the player doesn't have the control on the entity, the FreezeEntityPosition won't work
            if not NetworkHasControlOfEntity(object) then
                NetworkRequestControlOfEntity(object)
            end

            while not NetworkHasControlOfEntity(object) do
                Wait(0)
            end

            FreezeEntityPosition(object, false)
            TriggerServerEvent('s1n_atmrobbery:clearAtm', self.atmpropnetid)

            if math.random(1, 100) < Config.GetMoneyChance then
                self:CreateMoneyProp()
            else
                self:Notification(Config.Translation.NoMoney)
            end

            break
        end

        Wait(0)
    end
end

function Helpers:PlantBomb(netId)
    Utils:Debug("Checking if there is enough police online")

    exports[Config.ExportNames.s1nLib]:triggerServerCallback("s1n_atmrobbery:enoughPoliceOfficers", function(areEnough)
        if not areEnough then
            return Helpers:Notification(Config.Translation.NotEnoughPolice)
        end

        Functions.lastRobberyTime = GetGameTimer()

        self:StartBombRobbery()
    end)
end

function Helpers:IsVehicleWhitelisted(entity)
    if not Config.EnableVehicleWhitelist then return true end

    local vehicleModel = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(entity)))
    return Config.WhitelistVehicles[vehicleModel]
end

function Helpers:CreateMoneyProp()
    Utils:Debug("Creating money prop")

    local coords = GetOffsetFromEntityInWorldCoords(self.atmprop, 0.0, -1.0, 0.0)

    self:LoadModel('h4_prop_h4_cash_stack_01a')
    self.cashprop = CreateObject('h4_prop_h4_cash_stack_01a', coords.x, coords.y, coords.z, true, false)

    PlaceObjectOnGroundProperly(self.cashprop)
    FreezeEntityPosition(self.cashprop, true)

    if Config.UseQBTarget then
        exports['qb-target']:AddBoxZone('pickupcash', coords, 1, 1, {
            name = 'pickupcash',
            debugPoly = false
        }, {
            options = {
                {
                    type = 'client',
                    event = 's1n_atmrobbery:pickupCash',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.PickupCash
                }
            },
            distance = 2.5
        })
    else
        self.moneytarget = exports['ox_target']:addBoxZone({
            coords = coords,
            size = vector3(1, 1, 1),
            options = {
                {
                    name = 'pickupcash',
                    event = 's1n_atmrobbery:pickupCash',
                    icon = 'fa-solid fa-arrow-right-to-bracket',
                    label = Config.Translation.PickupCash
                }
            }
        })
    end
end

function Helpers:PickupCash()
    Utils:Debug("Picking up the cash")

    self:LoadAnimDict('pickup_object')

    TaskPlayAnim(PlayerPedId(), 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 1, 0, false, false, false)

    if exports['ox_lib']:progressBar({
        duration = 1800,
        label = Config.Translation.PickingupMoney,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true }
    }) then
        ClearPedTasks(PlayerPedId())

        SetEntityAsMissionEntity(self.cashprop, false, true)
        DeleteEntity(self.cashprop)

        if Config.UseQBTarget then
            exports['qb-target']:RemoveZone('pickupcash')
        else
            exports['ox_target']:removeZone(self.moneytarget)
        end

        TriggerServerEvent('s1n_atmrobbery:giveReward', 2)
        Utils:Debug("Picking up the cash finished successfully")
    end
end

function Helpers:Notification(message)
    if ESX then
        ESX.ShowNotification(message)
    elseif QBCore then
        QBCore.Functions.Notify(message)
    end
end