fx_version 'cerulean'

game 'gta5'

lua54 'yes'

version '1.0.2'

ui_page 'html/index.html'

shared_scripts {
    'shared/*'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/version.lua',
}

files {
    'html/**/*'
}

escrow_ignore {
    'shared/config.lua',
    'examples.lua'
}

dependency '/assetpacks'

dependency '/assetpacks'