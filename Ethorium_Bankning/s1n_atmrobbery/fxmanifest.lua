fx_version "cerulean"

description "S1nScripts ATM Robbery"
author "S1nScripts"
version '1.16.1'

lua54 'yes'

game "gta5"

shared_scripts {
    'configuration/shared/**/**',
    'languages/english.lua',
    'src/shared/*'
}

client_scripts {
    'src/client/services/api.lua',
    'src/client/controllers/events.lua',
    'src/client/services/helpers.lua',
    'src/client/services/storage.lua',
    'src/client/services/functions.lua',
    'src/client/init.lua'
}

server_scripts {
    'configuration/server/**/**',

    'src/server/init.lua',
    'src/server/api.lua',
    'src/server/functions.lua'
}

dependencies {
    '/onesync',
    's1n_lib'
}

escrow_ignore {
    "**/**",
}
dependency '/assetpacks'