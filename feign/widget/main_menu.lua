local freedesktop = require("freedesktop")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local prefs = require("prefs")

local menu_entries = {
	{ "hotkeys",     function() return false, hotkeys_popup.show_help end },
	{ "edit config", string.format("%s -e %s %s", prefs.terminal, prefs.editor, awesome.conffile) },
	{ "restart",     awesome.restart },
	{ "quit",        awesome.quit }
}

local main_menu = freedesktop.menu.build({
	icon_size = beautiful.menu_height or 16,
	before = {
		{ "Awesome", menu_entries, beautiful.awesome_icon }
	},
	after = {
		{ "Open terminal", prefs.terminal }
	}
})

return main_menu
