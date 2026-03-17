fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'RRP scripts'
description 'Realistic ATM'
version '1.1.1'


files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fleeca-logo.webp',
    'html/atm2.webp',
    'html/numPadBeep.flac',
    'html/cashcounter.flac',
    'data.json',
    'locales/*.json',
}

ui_page 'html/index.html'

shared_scripts {
    '@rrp_base/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'esx_overrides/server.lua',
    'server/TransactionLogger.lua',
    'server/server.lua'
}

client_scripts {
    'client/CamDUI.lua',
    'client/ATM.lua',
    'client/InputField.lua',
    'client/pageHandlers.lua',
    'client/Anims.lua',
    'client/main.lua',
}

dependencies {
    'rrp_base'
}

escrow_ignore {
    'client/*.lua',
    'server/*.lua',
    'locales/*.json',
    'esx_overrides/server.lua',
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/*.flac',
    'web/*.webp',
    'data.json',
    'config.lua',
}

dependency '/assetpacks'