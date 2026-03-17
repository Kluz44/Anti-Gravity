fx_version 'cerulean'

author 'S1nScripts'
description "S1nScripts Billing/Contract System"
version '1.1.6'

lua54 'yes'

game 'gta5'

shared_scripts {
    "configuration/shared/*.lua",

    "languages/english.lua",

    "src/shared/*.lua",
}

client_scripts {
    "src/client/functions.lua",
    "src/client/api.lua",

    "src/client/init.lua",
}

server_scripts {
    "configuration/server/*.lua",

    "src/server/sql.lua",
    "src/server/functions.lua",
    "src/server/api.lua",

    "src/server/init.lua",
}

ui_page "src/web/index.html"

files {
    "src/web/index.html",
    "src/web/main.js",
    "src/web/main.css",
    "src/web/assets/**/*.*"
}

dependencies {
    '/onesync',
    's1n_lib'
}

escrow_ignore {
    "**.*",
}
dependency '/assetpacks'