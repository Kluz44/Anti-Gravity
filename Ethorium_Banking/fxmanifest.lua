fx_version 'cerulean'
game 'gta5'

description 'Ethorium Banking - Unified Banking, Billing, and Card System'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/de.lua',
    'config.lua',
    'atm/config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/core.lua',
    'client/interact.lua',
    'client/ethorium_interact.lua',
    'client/creator.lua',
    'client/atm_robbery.lua',
    'client/atm_bridge.lua',
    'atm/client/CamDUI.lua',
    'atm/client/ATM.lua',
    'atm/client/InputField.lua',
    'atm/client/pageHandlers.lua',
    'atm/client/Anims.lua',
    'atm/client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/accounts.lua',
    'server/cards.lua',
    'server/invoices.lua',
    'server/loans.lua',
    'server/creator.lua',
    'server/vault.lua',
    'server/integrations.lua',
    'server/anticheat.lua',
    'server/atm_bridge.lua',
    'atm/server/TransactionLogger.lua',
    'atm/server/server.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'web/atm/index.html',
    'web/atm/style.css',
    'web/atm/script.js',
    'web/atm/fleeca-logo.webp',
    'web/atm/atm2.webp',
    'web/atm/numPadBeep.flac',
    'web/atm/cashcounter.flac',
    'atm/data.json',
    'atm/locales/*.json'
}

lua54 'yes'
