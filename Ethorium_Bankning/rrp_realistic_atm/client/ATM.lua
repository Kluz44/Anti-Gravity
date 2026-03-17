ATM = {}
ATM.__index = ATM

function ATM:new(currentATM, atmStringCoords, pinCodeHash, cardNumber)
    local self = setmetatable({}, ATM)
    self.currentATM = currentATM
    self.atmId = atmStringCoords
    self.selectedAccount = nil
    self.pinCodeHash = pinCodeHash
    self.cardNumber = cardNumber
    if not DoesEntityExist(currentATM) then
        TriggerServerEvent("qb_realistic_atm:handlers", "exitATM", self.atmId)
        error("ERROR: ATM entity does not exist")
    end
    self.atmModelHash = GetEntityModel(currentATM)
    local res = Config.DuiRes[self.atmModelHash] or Config.DuiRes.Default
    self.cam_dui = CamDui:new(  Config.Ratios[self.atmModelHash], 
                                currentATM,
                                Config.CamOffsets[self.atmModelHash] or Config.CamOffsets.Default,
                                Config.CamRots[self.atmModelHash] or Config.CamRots.Default, 
                                res[1], res[2],
                                Config.ATMs[self.atmModelHash].OriginalDict,
                                Config.ATMs[self.atmModelHash].OriginalTexture)
    return self
end

-- handlers atm lights
function ATM:enableScorched()
    if not Config.Scorched.SetScorched then return end
    if not DoesEntityExist(self.currentATM) then return end
    if Config.Scorched.CustomFuncEnable then
        Config.Scorched.CustomFuncEnable(self.currentATM)
        return
    end
    SetEntityRenderScorched(self.currentATM, true)
end

function ATM:changeTexture()
    Citizen.CreateThread(function()
        self.cam_dui:changeTexture(self.atmModelHash)
    end)
end

function ATM:disableScorched()
    if not Config.Scorched.SetScorched then return end
    if not DoesEntityExist(self.currentATM) then return end
    if Config.Scorched.CustomFuncDisable then
        Config.Scorched.CustomFuncDisable(self.currentATM)
        return
    end
    SetEntityRenderScorched(self.currentATM, true)
    SetEntityRenderScorched(self.currentATM, false)
end

function ATM:setSelectedAccount(account)
    self.selectedAccount = account
end

function ATM:withdraw(amount)
    if Config.QbBankingAccountSelector then
        if self.selectedAccount.account_name == "checking" then
            return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'withdraw', amount)
        else
            return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'sharedAccountWithdraw', self.selectedAccount, amount)

        end
    else
        return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'withdraw', amount)
    end
end

function ATM:getBalance()
    if Config.QbBankingAccountSelector  then
        if self.selectedAccount.account_name == "checking" then
            return RRP.Banking.GetBankBalance()
        else
            return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'sharedAccountGetBalance', self.selectedAccount)
        end
    else
        return RRP.Banking.GetBankBalance()
    end
end

function ATM:deposit(amount)
    if Config.QbBankingAccountSelector  then
        if self.selectedAccount.account_name == 'checking' then
            return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'deposit', amount)
        else
            return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'sharedAccountDeposit', self.selectedAccount, amount)
        end
    else
        return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'deposit', amount)    
    end
end

function ATM:checkPin(value)
   return GetHashKey(value) == self.pinCodeHash
end

function ATM:changePin(newPin)
    if GetHashKey(newPin) ~= self.pinCodeHash then
        return RRP.Callback.await('qb_realistic_atm:callbacks', false, 'changePin', newPin, self.cardNumber)
    end
    return false
end

function ATM:destroy()
    AnimHandler.removeCardAnim(function()
        ResetEntityAlpha(PlayerPedId())
    end)
    RRP.Controls.EnableControls()
    stopDeathStatus()
    self:enableScorched()
    if self.cam_dui then
        self.cam_dui:destroy()
    end
    self.cam_dui = nil
    self.currentATM = nil
    TriggerServerEvent("qb_realistic_atm:handlers", "exitATM", self.atmId)
    CurrentAtm = nil
end