fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Anti-Gravity Team'
description 'Framework Agnostic Template with Buffered DB'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
    'lib/bridge.lua',
    'config.lua',
    'lib/locale.lua',
    'lib/modules/inventory.lua',
    'lib/modules/notify.lua',
    'lib/modules/garage.lua',
    'lib/modules/phone.lua',
    'locales/en.lua',
    'locales/de.lua'
}

client_scripts {
    'client/admin.lua',
    'client/main.lua',
    'client/peds.lua'
}

server_scripts {
    'server/storage.lua',
    'server/admin.lua',
    'server/main.lua',
    'server/import.lua',
    'server/demand.lua',
    'server/persistence.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'data.json',
    'data/busstops.json',
    'data/routes.json'
}

dependencies {
    'oxmysql'
}

