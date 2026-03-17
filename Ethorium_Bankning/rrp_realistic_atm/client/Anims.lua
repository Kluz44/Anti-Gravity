-- TODO: implement rrp_base anim, obj creator
local isInAnim = false

local function isAnimEnded()
    return not isInAnim
end

local function goToCoords(atm)
    local ped = PlayerPedId()
    local atmCoords = GetEntityCoords(atm)
    local waitTime = 3000
    local atmHeading = GetEntityHeading(atm)
    local atmPedCoords = GetOffsetFromEntityInWorldCoords(atm, 0.0, -0.6, 0.0) -- Adjust the offset as needed
    if #(GetEntityCoords(ped).xy - atmPedCoords.xy) > 0.1 then
        TaskGoStraightToCoord(ped, atmPedCoords.x, atmPedCoords.y, atmPedCoords.z, 1.0, waitTime, atmHeading, 0.0)
        atmPedCoords = vector2(atmPedCoords.x, atmPedCoords.y)
        Wait(50)
        while waitTime > 0 do
            waitTime = waitTime - 100
            Wait(100)
            if #(GetEntityCoords(ped).xy - atmPedCoords) < 0.1 then
                break
            end
        end
    end
    Wait(500)
    TaskTurnPedToFaceCoord(ped, atmCoords.x, atmCoords.y, atmCoords.z, -1)
    Wait(1000) -- Wait for the player to turn
end

local function insertCardAnim(cb)
    isInAnim = true
    local animSettings = Config.AnimSettings.InsertCard

    local playerPed = PlayerPedId()
    local gender = IsPedMale(playerPed) and "Male" or "Female"
    local atmType = CurrentAtm.atmModelHash

    local dict = animSettings[gender].Insert.Dict[atmType]
    local anim = animSettings[gender].Insert.Anim[atmType]
    if not dict then
        dict = animSettings[gender].Insert.Dict.Default
    end
    if not anim then
        anim = animSettings[gender].Insert.Anim.Default
    end
    if animSettings.Object then
        local model = Config.Objects.Card
        local playerPed = playerPed
        local boneIndex = GetPedBoneIndex(playerPed, 28422)
        local pedCoords = GetEntityCoords(playerPed) - vector3(0.0, 0.0, 1.0)
        local spawnE = animSettings.IsLocal and "LocalObject" or "Object"
        local cardObj = RRP.Spawn[spawnE](model, pedCoords - vector3(0.0, 0.0, -2.0), false, false)
        FreezeEntityPosition(cardObj, true)
        if not animSettings.IsLocal then
            TriggerServerEvent("qb_realistic_atm:handlers", "regCard", ObjToNet(cardObj))
        end
        local offset = vector3(0.1, 0.03, -0.05)
        local rot = vector3(0.0, 0.0, 180.0)
        AttachEntityToEntity(cardObj, playerPed, boneIndex, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, true, true,
            false, true, 1, true)
        RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
        Wait(1500)
        ClearPedTasks(playerPed)
        DetachEntity(cardObj, false, false)
        local atmObject = CurrentAtm.currentATM
        local modelHash = GetEntityModel(atmObject)
        local offset = Config.Offsets.CardPos[modelHash] or Config.Offsets.CardPos.Default
        local coords = GetOffsetFromEntityInWorldCoords(atmObject, offset.First.x, offset.First.y, offset.First.z)
        SetEntityCoords(cardObj, coords.x, coords.y, coords.z)
        local heading = GetEntityHeading(atmObject)
        SetEntityRotation(cardObj, -90.0, 90.0, heading, 2, true)
        local isSliding = false
        local secondCoords = GetOffsetFromEntityInWorldCoords(atmObject, offset.Second.x, offset.Second.y,
            offset.Second.z)
        local GetGameTimer = GetGameTimer
        local timeout = GetGameTimer() + 3000 -- 3 seconds timeout
            while not isSliding do
            --isSliding = slideObjectInOneDirection(cardObj, secondCoords, "y", 0.01)
            sSliding = SlideObject(cardObj, secondCoords.x, secondCoords.y, secondCoords.z, 0.0015, 0.003, 0.002, false)
            if GetGameTimer() > timeout then
                break
            end
            Wait(30)
        end
        SetEntityAsMissionEntity(cardObj, true, true)
        SetEntityCoords(cardObj, secondCoords.x, secondCoords.y, secondCoords.z)
        SetEntityAlpha(playerPed, 120, false)
        isInAnim = false
        return cb(cardObj)
    else
        local playerPed = PlayerPedId()
        RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
        Wait(1500)
        ClearPedTasks(playerPed)
        SetEntityAlpha(playerPed, 120, false)
        isInAnim = false
        return cb()
    end
end

local function removeCardAnim(cb)
    isInAnim = true
    local playerPed = PlayerPedId()
    local gender = IsPedMale(playerPed) and "Male" or "Female"
    local atmType = CurrentAtm.atmModelHash
    local animsettings = Config.AnimSettings.InsertCard[gender].Remove

    local dict = animsettings.Dict[atmType]
    local anim = animsettings.Anim[atmType]
    if not dict then
        dict = animsettings.Dict.Default
    end
    if not anim then
        anim = animsettings.Anim.Default
    end
    local playerPed = playerPed
    local cardObj = CurrentAtm.cardObject
    local atmObject = CurrentAtm.currentATM
    if cardObj and DoesEntityExist(cardObj) then
        local isSliding = false
        local modelHash = GetEntityModel(atmObject)
        local offset = Config.Offsets.CardPos[modelHash] or Config.Offsets.CardPos.Default
        local secondCoords = GetOffsetFromEntityInWorldCoords(atmObject, offset.First.x, offset.First.y, offset.First.z)
        local GetGameTimer = GetGameTimer
        local timeout = GetGameTimer() + 3000 -- 3 seconds timeout
        while not isSliding do
            --isSliding = slideObjectInOneDirection(cardObj, secondCoords, "y", 0.01)
            isSliding = SlideObject(cardObj, secondCoords.x, secondCoords.y, secondCoords.z, 0.0015, 0.003, 0.002, false)
            if GetGameTimer() > timeout then
                break
            end
            Wait(30)
        end
    end
    RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(1000)
    if cardObj then
        local boneIndex = GetPedBoneIndex(playerPed, 28422)
        local rot = vector3(0.0, 0.0, 180.0)
        local offset = vector3(0.1, 0.03, -0.05)
        AttachEntityToEntity(cardObj, playerPed, boneIndex, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, true, true,
            false, true, 1, true)
    end
    Wait(1000)

    ClearPedTasks(playerPed)
    if cardObj then
        DetachEntity(cardObj, false, false)
        DeleteEntity(cardObj)
    end
    isInAnim = false
    return cb()
end

local function insertCashAnim(cb)
    isInAnim = true
    local animSettings = Config.AnimSettings.MoneyDepositAndWithdraw

    local playerPed = PlayerPedId()
    local gender = IsPedMale(playerPed) and "Male" or "Female"
    local atmType = CurrentAtm.atmModelHash

    local dict = animSettings[gender].Insert.Dict[atmType]
    local anim = animSettings[gender].Insert.Anim[atmType]
    if not dict then
        dict = animSettings[gender].Insert.Dict.Default
    end
    if not anim then
        anim = animSettings[gender].Insert.Anim.Default
    end

    if not animSettings.Object then
        RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
        Wait(3000)
        ClearPedTasks(playerPed)
        isInAnim = false
        return cb()
    end
    local model = Config.Objects.Cash
    local playerPed = playerPed
    local boneIndex = GetPedBoneIndex(playerPed, 57005)
    local pedCoords = GetEntityCoords(playerPed) - vector3(0.0, 0.0, 1.0)

    local spawnE = animSettings.IsLocal and "LocalObject" or "Object"
    local cashObj = RRP.Spawn[spawnE](model, pedCoords, false, false)

    if not animSettings.IsLocal then
        TriggerServerEvent("qb_realistic_atm:handlers", "regMoney", ObjToNet(cashObj))
    end
    AttachEntityToEntity(cashObj, playerPed, boneIndex, 0.1, 0.03, -0.05, 0.0, 0.0, 180.0, true, true, false, true, 1,
        true)
    RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(1500)
    DetachEntity(cashObj, false, false)
    FreezeEntityPosition(cashObj, true)
    ClearPedTasks(playerPed)
    local atmObject = CurrentAtm.currentATM
    local modelHash = GetEntityModel(atmObject)
    local offset = Config.Offsets.MoneyDeposit[modelHash] or Config.Offsets.MoneyDeposit.Default
    local coords = GetOffsetFromEntityInWorldCoords(atmObject, offset.First.x, offset.First.y, offset.First.z)
    SetEntityCoords(cashObj, coords.x, coords.y, coords.z)
    local heading = GetEntityHeading(atmObject) + 90
    SetEntityRotation(cashObj, offset.Rot.x, offset.Rot.y, heading, 2, true)
    local isSliding = false
    local secondCoords = GetOffsetFromEntityInWorldCoords(atmObject, offset.Second.x, offset.Second.y, offset.Second.z)



    local GetGameTimer = GetGameTimer
    local timeout = GetGameTimer() + 3000
    local i = 0
    while not isSliding do
        isSliding = SlideObject(cashObj, secondCoords.x, secondCoords.y, secondCoords.z, 0.0015, 0.003, 0.002, false)
        if GetGameTimer() > timeout then
            break
        end
        Wait(30)
    end

    DeleteEntity(cashObj)
    isInAnim = false
    return cb()
end

local function insertCashAnimBack(cb)
    isInAnim = true

    local animSettings = Config.AnimSettings.MoneyDepositAndWithdraw
    local playerPed = PlayerPedId()
    local gender = IsPedMale(playerPed) and "Male" or "Female"
    local atmType = CurrentAtm.atmModelHash

    local dict = animSettings[gender].Insert.Dict[atmType]
    local anim = animSettings[gender].Insert.Anim[atmType]
    if not dict then
        dict = animSettings[gender].Insert.Dict.Default
    end
    if not anim then
        anim = animSettings[gender].Insert.Anim.Default
    end

    if not animSettings.Object then
        RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
        Wait(3000)
        ClearPedTasks(playerPed)
        isInAnim = false
        return cb()
    end

    local model = Config.Objects.Cash
    local spawnE = animSettings.IsLocal and "LocalObject" or "Object"
    local atmObject = CurrentAtm.currentATM
    local modelHash = GetEntityModel(atmObject)
    local offset = Config.Offsets.MoneyDeposit[modelHash] or Config.Offsets.MoneyDeposit.Default
    local coords = GetOffsetFromEntityInWorldCoords(atmObject,offset.Second.x, offset.Second.y, offset.Second.z)
    local cashObj = RRP.Spawn[spawnE](model, coords, false, false)
    local heading = GetEntityHeading(atmObject) + 90

    SetEntityRotation(cashObj, offset.Rot.x, offset.Rot.y, heading, 2, true)


    if not animSettings.IsLocal then
        TriggerServerEvent("qb_realistic_atm:handlers", "regMoney", ObjToNet(cashObj))
    end

    local isSliding = false
    local secondCoords = GetOffsetFromEntityInWorldCoords(atmObject, offset.First.x, offset.First.y, offset.First.z)
    local GetGameTimer = GetGameTimer
    local timeout = GetGameTimer() + 3000 -- 3 seconds timeout
    while not isSliding do
        --isSliding = slideObjectInOneDirection(cashObj, secondCoords, "y", 0.01)
        isSliding = SlideObject(cashObj, secondCoords.x, secondCoords.y, secondCoords.z, 0.0015, 0.003, 0.002, false)
        if GetGameTimer() > timeout then
            break
        end
        Wait(30)
    end
    Wait(500)
    RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(1500)

    local boneIndex = GetPedBoneIndex(playerPed, 57005)

    AttachEntityToEntity(cashObj, playerPed, boneIndex, 0.1, 0.03, -0.05, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
    Wait(1000)
    DetachEntity(cashObj, false, false)
    DeleteEntity(cashObj)
    ClearPedTasks(playerPed)
    isInAnim = false
    return cb()
end

local function removeCashAnim(cb)
    isInAnim = true
    local animSettings = Config.AnimSettings.MoneyDepositAndWithdraw

    local playerPed = PlayerPedId()
    local gender = IsPedMale(playerPed) and "Male" or "Female"
    local atmType = CurrentAtm.atmModelHash

    local dict = animSettings[gender].Remove.Dict[atmType]
    local anim = animSettings[gender].Remove.Anim[atmType]
    if not dict then
        dict = animSettings[gender].Remove.Dict.Default
    end
    if not anim then
        anim = animSettings[gender].Remove.Anim.Default
    end

    if not animSettings.Object then
        RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
        Wait(3000)
        ClearPedTasks(playerPed)
        isInAnim = false
        return cb()
    end
    local model = Config.Objects.Cash
    local playerPed = playerPed
    local boneIndex = GetPedBoneIndex(playerPed, 57005)
    local pedCoords = GetEntityCoords(playerPed) - vector3(0.0, 0.0, 1.0)

    local spawnE = animSettings.IsLocal and "LocalObject" or "Object"
    local cashObj = RRP.Spawn[spawnE](model, pedCoords, false, false)

    if not animSettings.IsLocal then
        TriggerServerEvent("qb_realistic_atm:handlers", "regMoney", ObjToNet(cashObj))
    end
    FreezeEntityPosition(cashObj, true)
    local atmObject = CurrentAtm.currentATM
    local modelHash = GetEntityModel(atmObject)
    local offset = Config.Offsets.MoneyWithdraw[modelHash] or Config.Offsets.MoneyWithdraw.Default
    local coords = GetOffsetFromEntityInWorldCoords(atmObject, offset.First.x, offset.First.y, offset.First.z)
    SetEntityCoords(cashObj, coords.x, coords.y, coords.z)
    local heading = GetEntityHeading(atmObject) + 90
    SetEntityRotation(cashObj, offset.Rot.x, offset.Rot.y, heading, 2, true)
    local isSliding = false
    local secondCoords = GetOffsetFromEntityInWorldCoords(atmObject, offset.Second.x, offset.Second.y, offset.Second.z)
    local GetGameTimer = GetGameTimer
    local timeout = GetGameTimer() + 3000 -- 3 seconds timeout
    while not isSliding do
        --isSliding = slideObjectInOneDirection(cashObj, secondCoords, "y", 0.01)
        isSliding = SlideObject(cashObj, secondCoords.x, secondCoords.y, secondCoords.z, 0.0015, 0.003, 0.002, false)
        if GetGameTimer() > timeout then
            break
        end
        Wait(30)
    end
    RRP.Anim.PlayPedAnim(playerPed, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(1500)
    AttachEntityToEntity(cashObj, playerPed, boneIndex, 0.1, 0.03, -0.05, 0.0, 0.0, 180.0, true, true, false, true, 1,
        true)
    Wait(1000)
    ClearPedTasks(playerPed)
    DetachEntity(cashObj, false, false)
    DeleteEntity(cashObj)
    isInAnim = false
    return cb()
end

AnimHandler = {
    insertCardAnim = insertCardAnim,
    removeCardAnim = removeCardAnim,
    insertCashAnim = insertCashAnim,
    removeCashAnim = removeCashAnim,
    isAnimEnded = isAnimEnded,
    goToCoords = goToCoords,
    insertCashAnimBack = insertCashAnimBack,
}
