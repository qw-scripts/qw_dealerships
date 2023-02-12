fx_version 'cerulean'
game 'gta5'

description 'Dealerships for FiveM'
author 'qw-scripts'
version '0.1.0'

client_scripts {
    'client/**/*'
}

server_scripts {
    'server/**/*',
    '@oxmysql/lib/MySQL.lua'
}

shared_scripts {
    'shared/**/*',
    '@ox_lib/init.lua'
}

files {
    'locales/*.json'
}

lua54 'yes'
