local function init()
    Functions:CreateTables()

    -- Check the version of the script
    exports[Config.ExportNames.s1nLib]:checkVersion("s1n_billing")

    -- Check if the Discord Webhook is enabled and initialize it
    if Config.DiscordWebhook.enable then
        exports[Config.ExportNames.s1nLib]:initDiscordWebhook("s1n_billing", Config.DiscordWebhook)
    end
end

init()