fx_version "cerulean"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

author '_G[S]cripts'
description 'Gizmo for RedM'
version '1.0.6'

shared_script 'config.lua'

client_scripts {
  'utils/*.lua',
  'client/*.lua'
}

ui_page 'web/dist/index.html'

files {
  'locales/*.json',
	'web/dist/index.html',
	'web/dist/**/*',
}

-- Provide 'object_gizmo' exports
provide 'object_gizmo'