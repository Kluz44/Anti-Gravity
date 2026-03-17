local blockTarget = false
IsDead = false
CurrentAtm = nil
local checkingDeathStatus = false
function startCheckDeathStatus()
    if checkingDeathStatus then
        return
    end
    checkingDeathStatus = true
    Citizen.CreateThread(function()
        while checkingDeathStatus and CurrentAtm do
            Wait(1300)
            IsDead = RRP.CheckDeadStatus()
        end
    end)
end

function stopDeathStatus()
    checkingDeathStatus = false
end

-- < DEAD status 

local block = false

local function openATM(atmEntity, pin, cardNumber)
    if block then
        return
    end
    block = true
    if CurrentAtm then
        CurrentAtm:destroy()
        CurrentAtm = nil
        block = false
        return
    end
    local atmCoords = GetEntityCoords(atmEntity)
    local atmStringCoords = Shared.CoordsToString(atmCoords)
    RRP.Callback('qb_realistic_atm:callbacks', false, function(response, data)
        if not response then
            RRP.Notify(Config.NotifySystem, RRP.Locale.T('unsuccess'), RRP.Locale.T('atm_used'))
            blockTarget = false
            block = false
            return
        end
        RRP.Controls.DisableControls()
        AnimHandler.goToCoords(atmEntity)
        CurrentAtm = ATM:new(atmEntity, atmStringCoords, pin, cardNumber)
        Citizen.CreateThread(function()
            if CurrentAtm then
                CurrentAtm.cam_dui:setCam()
                AnimHandler.insertCardAnim(function(cardObj)
                    if CurrentAtm then
                        CurrentAtm.cardObject = cardObj
                    end
                end)
            end
        end)
        CurrentAtm:changeTexture()
        CurrentAtm.cam_dui:startInputHandler()
        CurrentAtm:disableScorched()
        startCheckDeathStatus()
        blockTarget = false
        block = false
    end, 'useATM', atmStringCoords)
end

RegisterNetEvent("qb_realistic_atm:openATM", function(pin, cardNumber)
    local playerCoords = GetEntityCoords(PlayerPedId())
    for hash, _ in pairs(Config.ATMs) do
        local atm = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.5, hash, false, false, false)
        if atm ~= 0 and DoesEntityExist(atm) then
            openATM(atm, pin, cardNumber)
            break
        end
    end
end)



if Config.Target then
    Citizen.CreateThread(function()
        Wait(1000)
        local option = {}

        for k, v in pairs(Config.TargetOptions) do
            option[k] = v
        end

        if not option.canInteract then
            option.canInteract = function(entity)
                return not G_CurrentAtmHandler and not blockTarget
            end
        end

        if not option.onSelect then
            option.onSelect = function(data)
                blockTarget = true
                openATM(data.entity)
            end
        end


        local models = {}
        for modelHash, _ in pairs(Config.ATMs) do
            table.insert(models, modelHash)
        end

        RRP.Target.addModel(models, { option })

    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if CurrentAtm then
            ResetEntityAlpha(PlayerPedId())
            local dui = CurrentAtm.cam_dui
            dui:destroy()
            CurrentAtm:destroy()
            stopDeathStatus()
        end
    end
end)