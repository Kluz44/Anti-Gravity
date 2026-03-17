CamDui = {}
CamDui.__index = CamDui

function CamDui:new(ratios, currentATM, camOffset, camRot, duiRes1, duiRes2, originalDict, originalTexture)
    local self = setmetatable({}, CamDui)
    self.currentATM = currentATM
    self.ratios = ratios
    self.cam = nil
    self.camOffset = camOffset
    self.camRot = camRot
    self.dui = RRP.Dui:new({
        url = ("nui://%s/html/index.html"):format(GetCurrentResourceName()),
        width = duiRes1,
        height = duiRes2,
        debug = false
    })

    self.originalDict = originalDict
    self.originalTexture = originalTexture
    self.newDict = nil
    self.newTexture = nil

    return self
end

function CamDui:setCam()
    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamFov(self.cam, Config.CameraFov or 70.0)
    local camCoords = GetOffsetFromEntityInWorldCoords(self.currentATM, self.camOffset.x, self.camOffset.y,
        self.camOffset.z)
    SetCamCoord(self.cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(self.cam, self.currentATM, self.camRot.x, self.camRot.y, self.camRot.z, true)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, true, Config.CamEase, true, true)
end

function CamDui:startInputHandler()

    Citizen.CreateThread(function()
        local resX, resY = GetActualScreenResolution()
        local function handleButtonClick(action)
            buttonAction(action, self.dui.duiObject)
            --SendDuiMessage(self.duiobject, json.encode({ action = "buttonClick", btn = action }))
        end
        SetNuiFocus(false, true)
        local IsControlJustPressed = IsControlJustPressed
        local GetActualScreenResolution = GetActiveScreenResolution
        local GetNuiCursorPosition = GetNuiCursorPosition
        local exitKeys = Config.ExitKeys

        local baseGameRatio = 16 / 9
        local baseResRatio = 1920 / 1080
        while CurrentAtm do
            Citizen.Wait(0)
            EnableControlAction(0, 24, true)
            if IsControlJustPressed(0, 24) then
                local gameRatio = GetAspectRatio(false)
                local resX, resY = GetActualScreenResolution()

                local cursorX, cursorY = GetNuiCursorPosition()
                local cursorRatX = cursorX / resX
                local cursorRatY = cursorY / resY
    
                local resRatio = resX / resY
                local baseRatio = 16 / 9
                for i, ratio in ipairs(self.ratios) do
                   local ratioX = ratio.x
                   local ratioX2 = ratio.x2
                    local ratioY = ratio.y
                    local ratioY2 = ratio.y2
    
                    if math.abs(gameRatio - resRatio) > 0.1 then
                        local diffRatio =  resRatio / gameRatio
                        ratioX = ratioX * diffRatio + (1 - diffRatio) / 2
                        ratioX2 = ratioX2 * diffRatio + (1 - diffRatio) / 2
                    end
    
                    if math.abs(baseResRatio - resRatio) > 0.1 then
                        local diffRatio =  baseResRatio /  resRatio
                        ratioX = ratioX * diffRatio + (1 - diffRatio) / 2
                        ratioX2 = ratioX2 * diffRatio + (1 - diffRatio) / 2
                    end

                    if cursorRatX >= ratioX and cursorRatX <= ratioX2 and cursorRatY >= ratioY and cursorRatY <= ratioY2 then
                        handleButtonClick(self.ratios[i].action)
                        break
                    end
                end
            end

            for _, key in ipairs(exitKeys) do
                if IsControlJustPressed(0, key) then
                    handleButtonClick("CARD")
                end
            end
        end
        SetNuiFocus(false, false)
    end)
end

local DuiIsReady = false
function CamDui:changeTexture(atmModelHash)
    DuiIsReady = false
    local atmData = Config.ATMs[atmModelHash]

    repeat
        self.dui:sendMessage({
            action = "getDuiState",
        })        
        Wait(50)
    until DuiIsReady
   
    self.dui:sendMessage({
        action = "openATM",
        show = true,
        modelName = atmData.modelName,
        colorHash = atmData.colorHash,
        btnColorHash = atmData.btnColorHash,
        waterMarkLink = atmData.waterMarkLink,
    })

    local txdId = self.dui.dictName
    local textureId = self.dui.txtName
    RemoveReplaceTexture(self.originalDict, self.originalTexture)
    AddReplaceTexture(self.originalDict, self.originalTexture, txdId, textureId)
    self.newDict = txdId
    self.newTexture = textureId
    --SetNuiFocus(false, true)
    if Config.DisablePincode then
        Pages.AccountSelectorPage(self.dui.duiObject)
        --Pages.HomePage(self.dui.duiObject)
    else
        Pages.CreatePinCodeReqPage(self.dui.duiObject)
    end
end

function CamDui:destroy()
    if self.cam then
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(self.cam, false)
        self.cam = nil
    end
    self.dui:sendMessage({
        action = "openATM",
        show = false,
    })
    if self.dui then
        self.dui:remove()
        self.dui = nil
    end
    if self.newDict and self.newTexture then
        RemoveReplaceTexture(self.originalDict, self.originalTexture)
    end
end

RegisterNuiCallback("duiIsReady", function(data, cb)
    DuiIsReady = true
    cb({ success = true })
end)

