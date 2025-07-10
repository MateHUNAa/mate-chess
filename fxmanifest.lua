fx_version "cerulean"
game "gta5"
lua54 'yes'


author 'MateHUN [mhScripts]'
description 'Template used mCore'
version '1.0.0'


shared_scripts {
    "shared/**.*"
}

server_scripts {
    "server/functions.lua",
    "server/main.lua",
}

client_scripts {
    "client/functions.lua",
    "client/main.lua",
}

server_script "@oxmysql/lib/MySQL.lua"
shared_script '@es_extended/imports.lua'
shared_script '@ox_lib/init.lua'

dependency {
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
    "client/GetMoves.lua",
    "client/check.lua"
}
