QBCore = nil
ESX = nil

if exports[Config.ExportNames.s1nLib]:getCurrentFrameworkName() == "qbcore" then
    QBCore = exports[Config.ExportNames.s1nLib]:getFrameworkObject()
elseif exports[Config.ExportNames.s1nLib]:getCurrentFrameworkName() == 'esx' then
    ESX = exports[Config.ExportNames.s1nLib]:getFrameworkObject()
end

local function init()
    Utils:Debug("Initializing...")

    exports[Config.ExportNames.s1nLib]:checkVersion("s1n_atmrobbery", GetCurrentResourceName())

    if Config.DiscordWebhook.enable then
        exports[Config.ExportNames.s1nLib]:initDiscordWebhook("s1n_atmrobbery", Config.DiscordWebhook)
    end

    Utils:Debug("Initialized")
end

init()