fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MateHUN [mhScripts]'
description 'Template used mCore'
version '1.0.0'

shared_scripts {
    'shared/**.*',
    '@es_extended/imports.lua',
    '@ox_lib/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/functions.lua',
    'server/init.lua',
    'server/main.lua'
}

client_scripts {
    'client/functions.lua',
    'client/main.lua',
    'client/createGame.lua',
    '@mate-grid/init.lua'
}

dependencies {
    'mCore',
    'oxmysql',
    'ox_lib',
    'mate-grid'
}

escrow_ignore {
    'shared/config.lua',
    '**/*.editable.lua'
}

files {
    'client/GetMoves.lua',
    'client/check.lua',
}
