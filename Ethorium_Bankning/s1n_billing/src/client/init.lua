local function init()
    -- Initialize the UI (sending config stuff)
    Functions:InitUI()

    -- Added key mapping for opening the billing menu
    exports[Config.ExportNames.s1nLib]:addKeyMapping({
        key = Config.Keys.openBillingMenu,
        mapperID = "keyboard",
        description = Config.Translation.UI_OPEN_BILLING_MENU,
        onPressed = Functions.OpenBillingMenu
    })
end

init()