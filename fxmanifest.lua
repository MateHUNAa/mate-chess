fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MateHUN [mhScripts]'
description 'Template used mCore'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
     "shared/**.*",
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua',
    'server/main.lua'
}

client_scripts {
     "shared/**.*",
    'client/main.lua',
    'client/createGame.lua',
    '@mate-grid/init.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'mate-grid'
}

escrow_ignore {
    'shared/config.lua',
    '**/*.editable.lua'
}
