fx_version 'cerulean'
game 'gta5'

author 'QB-Detran System'
description 'Sistema completo de Detran para QBCore'
version '1.0.0'

ui_page 'nui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/images/*.png',
    'nui/qrcode.min.js'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib'
}

lua54 'yes'