BtnHandlers = {}
local CurrentPage = nil
local INPUT = nil
local DUI = nil

function buttonAction(action, duiobject)
    if action == "CARD" then
        if CurrentAtm then
            CurrentAtm:destroy()
        end
        return
    end
    if BtnHandlers[action] then
        SendDuiMessage(DUI, json.encode({
            action = "playSound",
            audioFile = Config.AudioSettings.NumPad.audioFile,
            volume = Config.AudioSettings.NumPad.audioVolume
        }))
        BtnHandlers[action](duiobject)
       
    end
end

local function createNumPadHandlers(enterFn, cancelFn)
    for i = 0, 9 do
        BtnHandlers['num-' .. i] = function()
            if INPUT then
                INPUT:addCharacter(tostring(i))
            end
        end
    end
    BtnHandlers['CANCEL'] = cancelFn
    BtnHandlers['CLEAR'] = function()
        if INPUT then
            INPUT:clear()
        end
    end 
    BtnHandlers['ENTER'] = enterFn
end

local function accountSelectorPage(dui)
    DUI = dui
    if Config.QbBankingAccountSelector then
        local accounts =  RRP.Callback.await('qb_realistic_atm:callbacks', false, 'getAccountsData')
        local title = RRP.Locale.T('createAccountSelectorPage.title')
        local description = RRP.Locale.T('createAccountSelectorPage.description')
        local selectedOptionTitle = RRP.Locale.T('createAccountSelectorPage.selectedOptionTitle')
        local buttons = {}
        local index = nil
        for k, v in ipairs(accounts) do
            index = nil
            if k == 1 then index = 3
            elseif k == 2 then index = 8
            elseif k == 3 then index = 7
            elseif k == 4 then index = 6
            elseif k == 5 then index = 2
            elseif k == 6 then index = 5
            elseif k == 7 then index = 1
            end
            table.insert(buttons, {index = index, text = v.account_name, fn = function()
                CurrentAtm:setSelectedAccount(v)
                Pages.HomePage(dui)
            end})
           
        end

        return createPage(dui, title, selectedOptionTitle, description, buttons)
    else
        return Pages.HomePage(dui)
    end
end

function createPage(dui, title, subtitle, description, buttons, input)
    local btns = {}
    if buttons then
        for i, button in ipairs(buttons) do
            if button.fn then
                BtnHandlers['btn-' .. button.index] = button.fn
            end
            btns[i] = {
                index = button.index,
                text = button.text,
            }
        end
    end
    SendDuiMessage(dui, json.encode({
        action = "createPage",
        title = title,
        subtitle = subtitle,
        description = description,
        buttons = btns,
        input = input,
    }))
end

local function createHomePage(dui)
    DUI = dui
    local title = RRP.Locale.T('homepage.title')
    local subtitle = RRP.Locale.T('homepage.subtitle')
    local description = RRP.Locale.T('homepage.description')
    local buttons = {
        {index = 2, text = RRP.Locale.T('homepage.buttons.info'), fn = Pages.InfoPage},
        {index = 3, text = RRP.Locale.T('homepage.buttons.change_pin'), fn = Pages.ChangePinCode1},
        {index = 6, text = RRP.Locale.T('homepage.buttons.balance'), fn = Pages.BalancePage},
        {index = 7, text = RRP.Locale.T('homepage.buttons.withdraw'), fn = Pages.WithdrawPage},
        {index = 8, text = RRP.Locale.T('homepage.buttons.deposit'), fn = Pages.DepositPage},
        {index = 4, text = RRP.Locale.T('homepage.buttons.exit'), fn = function()
            CurrentAtm:destroy()
        end}
    }
    BtnHandlers = {}
    return createPage(dui, title, subtitle, description, buttons)
end

function createPinCodeReqPage(dui)
    DUI = dui
    local title = RRP.Locale.T('pin_code.request.title')
    local subtitle = RRP.Locale.T('pin_code.request.subtitle')
    local description = RRP.Locale.T('pin_code.request.description')
    local inputElement = '<div class="inputField" maxlength="4" size="4" type="password" class="div">'
    INPUT = InputField:new(DUI, 4, 'password')
    BtnHandlers = {}

    createNumPadHandlers(function()
        local pinCode = INPUT:getValue()
        if CurrentAtm:checkPin(pinCode) then
            return accountSelectorPage(DUI)
            --return createHomePage(DUI)
        else
            local title = RRP.Locale.T('pin_code.error.title')
            local subtitle = RRP.Locale.T('pin_code.error.subtitle')
            local description = RRP.Locale.T('pin_code.error.description')
            local buttons = {
                {index = 4, text = RRP.Locale.T('pin_code.error.retry_button'), fn = function()
                    createPinCodeReqPage(dui)
                end},
            }
            createPage(DUI, title, subtitle, description, buttons)
        end
    end, function()
        -- Cancel action
    end)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = function()
            CurrentAtm:destroy()
        end},
    }

    return createPage(DUI, title, subtitle, description, buttons, inputElement)
end

--wait

local function createWaitPage(time)
    time = time or 0
    local title = RRP.Locale.T('wait_page.title')
    local subtitle = RRP.Locale.T('wait_page.subtitle')
    local description = RRP.Locale.T('wait_page.description')
    createPage(DUI, title, subtitle, description)
    Wait(time)
end

local function createInfoPage(dui)
    local title = RRP.Locale.T('info_page.title')
    local subtitle = RRP.Locale.T('info_page.subtitle')
    local description = RRP.Locale.T('info_page.description')
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    BtnHandlers = {}
    createPage(dui, title, subtitle, description, buttons)
    Wait(1500)
end

local function createSuccessPinPage(dui)
    local title = RRP.Locale.T('pin_code.change_success.title')
    local subtitle = RRP.Locale.T('pin_code.change_success.subtitle')
    local description = RRP.Locale.T('pin_code.change_success.description')
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(dui, title, subtitle, description, buttons)
end

local function createErrorPinPage(dui)
    local title = RRP.Locale.T('pin_code.change_fail.title')
    local subtitle = RRP.Locale.T('pin_code.change_fail.subtitle')
    local description = RRP.Locale.T('pin_code.change_fail.description')
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(dui, title, subtitle, description, buttons)
end

local function changePinCode2(dui)
    local title = RRP.Locale.T('changepin2.title')
    local subtitle = RRP.Locale.T('changepin2.subtitle')
    local description = RRP.Locale.T('changepin2.description')
    local inputElement = '<div class="inputField" maxlength="4" size="4" type="password" class="div">'
    local prevInputValue = INPUT:getValue()
    INPUT:clear()
    INPUT = InputField:new(dui, 4, 'password')
    createNumPadHandlers(function()
        if INPUT:getValue() == prevInputValue then
            local success = CurrentAtm:changePin(INPUT:getValue())
            if success then
                createSuccessPinPage(dui)
            else
                createErrorPinPage(dui)
            end
        else
            createErrorPinPage(dui)
        end
    end, function()
    
    end)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common_back'), fn = Pages.HomePage},
    }
    return createPage(dui, title, subtitle, description, buttons, inputElement)
end
local denominations = {100, 50, 20, 10, 5, 2, 1} -- {20000, 10000, 5000, 2000, 1000, 500}

local function breakdownAmount(amount)
    local breakdown = {}
    local remainingAmount = amount

    for _, denom in ipairs(denominations) do
        if remainingAmount >= denom then
            breakdown[denom] = math.floor(remainingAmount / denom)
            remainingAmount = remainingAmount % denom
        end
    end

    return breakdown
end

local function formatBreakdown(breakdown)
    local description = ''
    local total = 0

    for denom, count in pairs(breakdown) do
        description = description .. string.format("%d x %d<br>", denom, count)
        total = total + (denom * count)
    end

    description = description .. string.format("Sum = %d", total)

    return { description = description, total = total }
end

-- withdraw
local function createReceiptPage(dui, amount)
    SendDuiMessage(DUI, json.encode({
        action = "playSound",
        audioFile = Config.AudioSettings.CashCounter.audioFile,
        volume = Config.AudioSettings.CashCounter.audioVolume
    }))
    local title = RRP.Locale.T('receipt_page.title')
    local subtitle = RRP.Locale.T('receipt_page.subtitle')
    local breakdown = breakdownAmount(amount)
    local formattedBreakdown = formatBreakdown(breakdown)
    local description = RRP.Locale.T('receipt_page.description', formattedBreakdown.description, formattedBreakdown.total)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
        {index = 8, text = RRP.Locale.T('receipt_page.more'), fn = Pages.WithdrawPage},
    }
    AnimHandler.removeCashAnim(function()
        -- Animation handler
    end)
    while not AnimHandler.isAnimEnded() do
        Citizen.Wait(0)
    end
    return createPage(dui, title, subtitle, description, buttons)
end

local function createUnsuccessWithDrawPage(dui, errmsg)
    local title = RRP.Locale.T('unsuccessful_withdraw.title')
    local subtitle = RRP.Locale.T('unsuccessful_withdraw.subtitle')
    errmsg = RRP.Locale.T(errmsg)
    local description = errmsg
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(dui, title, subtitle, description, buttons)
end

local function createOtherAmountPageW(dui)
    local title = RRP.Locale.T('other_amount_page_W.title')
    local subtitle = RRP.Locale.T('other_amount_page_W.subtitle')
    local description = RRP.Locale.T('other_amount_page_W.description')
    local inputElement = '<div class="inputField" maxlength="10" size="10" type="text" class="div">'
    INPUT = InputField:new(dui, 10, 'text')
    BtnHandlers = {}

    createNumPadHandlers(function()
        local amount = tonumber(INPUT:getValue())

        if amount < Config.Tax.Withdraw.Min or amount > Config.Tax.Withdraw.Max then
            --notify(source, 'Invalid withdrawal amount')
            createUnsuccessWithDrawPage(dui, 'inv_amount')
        end
        local balance = CurrentAtm:getBalance()
        if amount > balance then
            amount = balance
        end

        local success, msg = CurrentAtm:withdraw(amount)
        if success then
            createReceiptPage(dui, amount)
        else
            createUnsuccessWithDrawPage(dui, msg)
        end
    end, function()
    
    end)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(dui, title, subtitle, description, buttons, inputElement)
end



local function createWithdrawPage(dui)
    local title = RRP.Locale.T('withdraw_page.title')
    local subtitle = RRP.Locale.T('withdraw_page.subtitle')
    local description = RRP.Locale.T('withdraw_page.description')
    local buttons = {
        {index = 2, text = '2000$', fn = function() 
            createWaitPage(800)
            local success, msg = CurrentAtm:withdraw(2000)
            if success then
                createReceiptPage(dui, 2000)
            else
                createUnsuccessWithDrawPage(dui, msg)
            end
         end},
        {index = 3, text = '5000$', fn = function() 
            createWaitPage(800)
            local success, msg = CurrentAtm:withdraw(5000)
            if success then
                createReceiptPage(dui, 5000)
            else
                createUnsuccessWithDrawPage(dui, msg)
            end
         end},
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
        {index = 6, text = '10000$', fn = function() 
            createWaitPage(800)
            local success, msg = CurrentAtm:withdraw(10000)
            if success then
                createReceiptPage(dui, 10000)
            else
                createUnsuccessWithDrawPage(dui, msg)
            end
         end},
        {index = 7, text = '20000$', fn = function() 
            createWaitPage(800)
            local success, msg = CurrentAtm:withdraw(20000)
            if success then
                createReceiptPage(dui, 20000)
            else
                createUnsuccessWithDrawPage(dui, msg)
            end
         end},
        {index = 8, text = RRP.Locale.T('withdraw_page.other'), fn = function() 
            createOtherAmountPageW(dui)
            --createWaitPage()
         end},
    }
    BtnHandlers = {}
    for _, button in ipairs(buttons) do
        BtnHandlers['btn-' .. button.index] = button.fn
    end
    return createPage(dui, title, subtitle, description, buttons)
end

-- pin code

local function changePinCode1(dui)
    local title = RRP.Locale.T('changepin1.title')
    local subtitle = RRP.Locale.T('changepin1.subtitle')
    local description = RRP.Locale.T('changepin1.description')
    local inputElement = '<div class="inputField" maxlength="4" size="4" type="password" class="div">'
    INPUT = InputField:new(dui, 4, 'password')
    BtnHandlers = {}

    createNumPadHandlers(function()
        Pages.ChangePinCode2(dui)
    end, function()
    
    end)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(dui, title, subtitle, description, buttons, inputElement)
end

-- balance

local function createBalancePage()
    local title = RRP.Locale.T('balance_page.title')
    local subtitle = RRP.Locale.T('balance_page.subtitle')
    local description = RRP.Locale.T('balance_page.description', CurrentAtm:getBalance())
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(DUI, title, subtitle, description, buttons)
end

-- deposit

local function waitForDeposit()
    SendDuiMessage(DUI, json.encode({
        action = "playSound",
        audioFile = Config.AudioSettings.CashCounter.audioFile,
        volume = Config.AudioSettings.CashCounter.audioVolume
    }))
    local title = RRP.Locale.T('wait_for_deposit.title')
    local subtitle = RRP.Locale.T('wait_for_deposit.subtitle')
    local description = RRP.Locale.T('wait_for_deposit.description')
    --local buttons = {
        --{index = 4, text =  RRP.Locale.T('common.cancel'), fn = Pages.HomePage},
    --}
    BtnHandlers = {}
    createPage(DUI, title, subtitle, description, nil)
    AnimHandler.insertCashAnim(function()

    end)
    while not AnimHandler.isAnimEnded() do
        Citizen.Wait(0)
    end
    Wait(800)
end

local function createSuccessDepositPage(amount)
    local title = RRP.Locale.T('success_deposit_page.title')
    local subtitle = RRP.Locale.T('success_deposit_page.subtitle')
    local description = RRP.Locale.T('success_deposit_page.description', amount)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
        {index = 8, text =  RRP.Locale.T('success_deposit_page.more_deposit'), fn = Pages.DepositPage},
    }
    return createPage(DUI, title, subtitle, description, buttons)
end 

local function createUnsuccessDepositPage(msg)
    local title = RRP.Locale.T('unsuccess_deposit_page.title')
    local subtitle = RRP.Locale.T('unsuccess_deposit_page.subtitle')
    msg = RRP.Locale.T(msg)
    local description = msg
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.DepositPage},
    }
    return createPage(DUI, title, subtitle, description, buttons)
end

local function createApprovedDepositPage(amount)
    if amount < Config.Tax.Deposit.Min or amount > Config.Tax.Deposit.Max then
        --notify(source, 'Invalid deposit amount')
        createUnsuccessDepositPage('inv_amount')
        AnimHandler.insertCashAnimBack(function()
            -- Animation handler
        end)
        return
    end

    if amount > RRP.Banking.GetCashBalance() then
       amount = RRP.Banking.GetCashBalance()
    end

    local title = RRP.Locale.T('approved_deposit_page.title')
    local subtitle = RRP.Locale.T('approved_deposit_page.subtitle')
    local description = RRP.Locale.T('approved_deposit_page.description', amount)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = function()
            Pages.HomePage(DUI)
            AnimHandler.insertCashAnimBack(function()
                -- Animation handler
            end)
        end},
        {index = 8, text = RRP.Locale.T('approved_deposit_page.approvedBtn'), fn = function()
            local success, msg = CurrentAtm:deposit(amount)
            if success then
                createSuccessDepositPage(amount)
            else
                createUnsuccessDepositPage(msg)
                AnimHandler.insertCashAnimBack(function()
                    -- Animation handler
                end)
            end
        end},
    }
    return createPage(DUI, title, subtitle, description, buttons)
end

local function createOtherAmountPageD()
    local title = RRP.Locale.T('other_amount_page_D.title')
    local subtitle = RRP.Locale.T('other_amount_page_D.subtitle')
    local description = RRP.Locale.T('other_amount_page_D.description')
    local inputElement = '<div class="inputField" maxlength="10" size="10" type="text" class="div">'
    INPUT = InputField:new(DUI, 10, 'text')
    BtnHandlers = {}

    createNumPadHandlers(function()
        local amount = tonumber(INPUT:getValue())
        if amount then
            waitForDeposit()
            createWaitPage(0)
            createApprovedDepositPage(amount)
        end
    end, function()
    
    end)
    local buttons = {
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
    }
    return createPage(DUI, title, subtitle, description, buttons, inputElement)
end



local function createDepositPage(dui)
    local title = RRP.Locale.T('createDepositPage.title')
    local description = RRP.Locale.T('createDepositPage.description')
    local subtitle = RRP.Locale.T('createDepositPage.subtitle')
    BtnHandlers = {}
    local buttons = {
        {index = 2, text = '2000$', fn = function() 
            waitForDeposit()
            createWaitPage(0)
            createApprovedDepositPage(2000)
         end},
        {index = 3, text = '5000$', fn = function() 
            waitForDeposit()
            createWaitPage(0)
            createApprovedDepositPage(5000)
         end},
        {index = 4, text = RRP.Locale.T('common.back'), fn = Pages.HomePage},
        {index = 6, text = '10000$', fn = function() 
            waitForDeposit()
            createWaitPage(0)
            createApprovedDepositPage(10000)
         end},
        {index = 7, text = '20000$', fn = function() 
            waitForDeposit()
            createWaitPage(0)
            createApprovedDepositPage(20000)
         end},
        {index = 8, text = RRP.Locale.T('createDepositPage.other'), fn = function() 
            createOtherAmountPageD(dui)
            --createWaitPage()
         end},
    }
    return createPage(dui, title, subtitle, description, buttons)
end


Pages = {
    AccountSelectorPage = accountSelectorPage,
    HomePage = createHomePage,
    InfoPage = createInfoPage,
    ChangePinCode1 = changePinCode1,
    ChangePinCode2 = changePinCode2,
    SuccessPinPage = createSuccessPinPage,
    ErrorPinPage = createErrorPinPage,
    BalancePage = createBalancePage,
    WithdrawPage = createWithdrawPage,
    ReceiptPage = createReceiptPage,
    UnsuccessWithDrawPage = createUnsuccessWithDrawPage,
    OtherAmountPageW = createOtherAmountPageW,
    OtherAmountPageD = createOtherAmountPageD,
    CreatePinCodeReqPage = createPinCodeReqPage,
    DepositPage = createDepositPage,
}


