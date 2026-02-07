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
    'client/interact.lua',
    'client/water.lua',
    'client/wind.lua',
    'client/main.lua'
}

server_scripts {
    'server/storage.lua',
    'server/main.lua',
    'server/grid.lua',
    'server/dispatch.lua',
    'server/missions.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/nui_integration.js',
    'web/ag_logo.png',
    'web/ag_map_day.jpg',
    'web/ag_map_night.jpg'
}

dependencies {
    'oxmysql'
}

