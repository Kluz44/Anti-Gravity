local QBCore = exports['qb-core']:GetCoreObject()

-- Native Integration of rep-talkNPC logic as per user request
-- Replaces our previous clone with the exact logic provided by rep-talkNPC

EthoriumBankingC = EthoriumBankingC or {}
local NPC = {}
local npcId = 0
local currentNPC = nil
local cam
local camRotation
local interactActive = false
local dialog = {}

local function CreateCam()
    local px, py, pz = table.unpack(GetEntityCoords(currentNPC.npc, true))
    local x, y, z = px + GetEntityForwardX(currentNPC.npc) * 1.2, py + GetEntityForwardY(currentNPC.npc) * 1.2, pz + 0.52
    local rx = GetEntityRotation(currentNPC.npc, 2)
    camRotation = rx + vector3(0.0, 0.0, 181.0)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, camRotation, GetGameplayCamFov())
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, 1, 1)
end

local function changeDialog(_label, _elements)
    local cloneE = {}
    for k,v in pairs (_elements) do
       if v.canInteract then
            local success, resp = pcall(v.canInteract)
            if success and resp then cloneE[#cloneE+1] = v end
       else
            cloneE[#cloneE+1] = v
       end
    end
    SendNUIMessage({
        action = "changeDialog",
        msg = _label,
        elements = cloneE
    })
    dialog = cloneE
end

local function updateMessage(label)
    SendNUIMessage({
        action = "updateMessage",
        msg = label
    })
end

local function talkNPC(_id)
    local npc = NPC[_id]
    currentNPC = npc
    CreateCam()
    interactActive = true
    SetNuiFocus(true, true)
    
    local cloneE = {}
    for k,v in pairs (npc.elements) do
       if v.canInteract then
            local success, resp = pcall(v.canInteract)
            if success and resp then cloneE[#cloneE+1] = v end
       else
            cloneE[#cloneE+1] = v
       end
    end

    SendNUIMessage({
        action = "show",
        msg = npc.startMSG,
        elements = cloneE,
        npcName = npc.name,
        npcTag = npc.tag or "NPC",
        npcColor = npc.color
    })
    dialog = cloneE
end

-- Re-implemented to support the structure used by our Ethorium banking configs previously
function EthoriumBankingC.RegisterBankNPC(entity, name, options)
    npcId = npcId + 1
    
    -- In Ethorium context, entity is already spawned by qs-interact loop but let's just attach directly
    NPC[entity] = {
        id = npcId,
        npc = entity,
        resource = GetInvokingResource(),
        coords = GetEntityCoords(entity),
        name = name,
        tag = "Bank",
        color = "blue",
        startMSG = "Willkommen in der Ethorium Bank! Wie kann ich Ihnen helfen?",
        elements = {}
    }

    -- Port the old Options into rep-talkNPC format
    for k, opt in pairs(options) do
        table.insert(NPC[entity].elements, {
            label = opt.label,
            shouldClose = true,
            action = function()
                SendNUIMessage({ action = "closeDialog" })
                SetNuiFocus(false, false)
                ClearFocus()
                RenderScriptCams(false, true, 1000, true, false)
                DestroyCam(cam, false)
                SetEntityAlpha(PlayerPedId(), 255, false)
                cam = nil
                interactActive = false
                dialog = {}
                
                -- Route logic to Bank UI
                if opt.actionId == "deposit" or opt.actionId == "withdraw" or opt.actionId == "transfer" or opt.actionId == "cards" or opt.actionId == "loans" or opt.actionId == "invoices" then
                    OpenBankUI(opt.actionId)
                end
            end
        })
    end

    -- Hook up Targets
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, {
            {
                name = 'bank_npc_' .. name,
                label = "Mit " .. name .. " sprechen",
                icon = "fas fa-user-friends",
                onSelect = function(data)
                    talkNPC(entity)
                end
            }
        })
    elseif Config.Target == 'qb-target' or Config.Target == 'qtarget' then
        exports[Config.Target]:AddTargetEntity(entity, {
            options = {
                {
                    action = function(ent)
                        talkNPC(ent)
                    end,
                    icon = "fas fa-user-friends",
                    label = "Mit " .. name .. " sprechen"
                }
            },
            distance = 3.0
        })
    end
end


RegisterNUICallback('close', function(data, cb)
    currentNPC = nil
    interactActive = false
    SetNuiFocus(false, false)
    ClearFocus()
    RenderScriptCams(false, true, 1000, true, false)
    DestroyCam(cam, false)
    SetEntityAlpha(PlayerPedId(), 255, false)
    cam = nil
    dialog = {}
    cb('ok')
end)

RegisterNUICallback('click', function(data, cb)
    SetPedTalk(currentNPC.npc)
    local idx = tonumber(data) + 1
    if dialog[idx].shouldClose then
        currentNPC = nil
        interactActive = false
        SetNuiFocus(false, false)
        ClearFocus()
        RenderScriptCams(false, true, 1000, true, false)
        DestroyCam(cam, false)
        SetEntityAlpha(PlayerPedId(), 255, false)
        cam = nil
        dialog = {}
        SendNUIMessage({ action = "closeDialog" })
    end
    dialog[idx].action()
    cb('ok')
end)

CreateThread(function()
    while true do
        if currentNPC and interactActive == true then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if #(pos - vector3(currentNPC.coords.x,currentNPC.coords.y, currentNPC.coords.z)) > 5 then
                currentNPC = nil
                interactActive = false
                SetNuiFocus(false, false)
                ClearFocus()
                RenderScriptCams(false, true, 1000, true, false)
                DestroyCam(cam, false)
                SetEntityAlpha(PlayerPedId(), 255, false)
                cam = nil
                dialog = {}
                SendNUIMessage({ action = "closeDialog" })
            end
        end
        Wait(500)
    end
end)

-- Public Exports (API identical to rep-talkNPC)
local function CreateNPC(_pedData, _elements)
    npcId = npcId + 1
    
    if type(_pedData.npc) ~= 'number' then _pedData.npc = joaat(_pedData.npc) end
    if not HasModelLoaded(_pedData.npc) then
        RequestModel(_pedData.npc)
        while not HasModelLoaded(_pedData.npc) do Wait(1) end
    end
    
    local ped = CreatePed(0, _pedData.npc, _pedData.coords.x, _pedData.coords.y, _pedData.coords.z, _pedData.coords.w, false, true)
    SetEntityHeading(ped, _pedData.coords.w)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedDiesWhenInjured(ped, false)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    TaskLookAtEntity(ped, PlayerPedId(), -1, 2048, 3)
    SetModelAsNoLongerNeeded(_pedData.npc)
    
    if _pedData.animName then
        RequestAnimDict(_pedData.animName)
        while not HasAnimDictLoaded(_pedData.animName) do Wait(1) end
        TaskPlayAnim(ped, _pedData.animName, _pedData.animDist or "base", 8.0, 0.0, -1, 1, 0, false, false, false)
    elseif _pedData.animScenario then
        TaskStartScenarioInPlace(ped, _pedData.animScenario, 0, true)
    end

    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'exported_npc_' .. _pedData.name,
                label = "Mit " .. _pedData.name .. " sprechen",
                icon = "fas fa-user-friends",
                onSelect = function(data)
                    talkNPC(ped)
                end
            }
        })
    elseif Config.Target == 'qb-target' or Config.Target == 'qtarget' then
        exports[Config.Target]:AddTargetEntity(ped, {
            options = {
                {
                    action = function(entity)
                        talkNPC(entity)
                    end,
                    icon = "fas fa-user-friends",
                    label = "Mit " .. _pedData.name .. " sprechen"
                }
            },
            distance = 3.0
        })
    end

    NPC[ped] = {
        id = npcId,
        npc = ped,
        resource = GetInvokingResource(),
        coords = _pedData.coords,
        name = _pedData.name,
        tag = _pedData.tag or "NPC",
        color = _pedData.color or "blue",
        startMSG = _pedData.startMSG or 'Hello',
        elements = _elements
    }
    
    return ped
end

exports('CreateNPC', CreateNPC)
exports('changeDialog', changeDialog)
exports('updateMessage', updateMessage)
