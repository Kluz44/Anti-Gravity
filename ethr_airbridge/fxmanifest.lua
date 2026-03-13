fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'ethr_airbridge'
author 'Ethorium'
description 'Gruppen-Flug/Absprung System mit Check-in, Fenster, AI-Flug, Jump & Cooldown'
version '1.3.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared_notify.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

dependencies {
    'ox_lib',
    'ox_target', -- optional; enable if you want target-only interaction
    'qb-core'
}
