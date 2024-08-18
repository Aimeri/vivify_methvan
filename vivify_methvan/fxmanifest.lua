fx_version 'cerulean'
game 'gta5'

author 'Aimeri'
description 'vivify_methvan'
version '1.0.0'

lua54 'yes'

dependencies {
    'qb-target',
    'qb-menu',
	'progressbar'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

shared_scripts {
    --'@ox_lib/init.lua'
}