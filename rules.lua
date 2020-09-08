local awful = require("awful")
local beautiful = require("beautiful")
local keys = require("keys")
local helpers = require("feign.helpers")
local feign = require("feign")
local prefs = require("prefs")

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = { },
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = keys.client_keys,
			buttons = keys.client_buttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap+awful.placement.no_offscreen,
			size_hints_honor = false
		}
	},

	-- Titlebars
	{
		rule_any = { type = { "dialog" } },
		properties = { titlebars_enabled = true }
	},
	-- Special rules
	{
		rule = { class = "firefox" },
		properties = { tag = prefs.tag_names[1] }
	},
	{
		rule = { class = "URxvt" },
		except_any = { instance = { "vis", "ncmpcpp" } },
		properties = { tag = prefs.tag_names[2] }
	},
	{
		rule = { class = "URxvt", instance = "ncmpcpp" },
		properties = { tag = prefs.tag_names[3] },
		callback = feign.widget.music_titlebar.create
	},
	{
		rule = { class = "URxvt", instance = "vis" },
		properties = {
			maximized = true,
			focusable = false,
			below = true,
			sticky = true,
			skip_taskbar = true
		}
	},
	{
		rule = { class = "URxvt", instance = "popup" },
		properties = {
			placement = awful.placement.top+awful.placement.center_horizontal,
			above = true,
			sticky = true,
			skip_taskbar = true,
			floating = true
		}
	},
	{
		rule = { class = "XTerm" },
		properties = { tag = prefs.tag_names[2] }
	},
	{
		rule = { class = "vlc" },
		properties = { tag = prefs.tag_names[3] }
	},
	{
		rule = { class = "mpv" },
		properties = { tag = prefs.tag_names[3] }
	},
	{
		rule = { class = "Thunderbird" },
		properties = { tag = prefs.tag_names[4] }
	},
	{
		rule = { class = "Steam" },
		properties = { tag = prefs.tag_names[6] }
	},
	{
		rule = { class = "Zathura" },
		properties = { tag = prefs.tag_names[5] }
	},
	{
		rule = { class = "libreoffice" },
		properties = { tag = prefs.tag_names[5] }
	},
	{
		rule = { class = "Terraria.bin.x86_64" },
		callback = helpers.no_picom_when_focused
	},
	{
		rule = { class = "WP-34s" },
		properties = {
			placement = awful.placement.right,
			is_fixed = true,
			skip_taskbar = true,
			ontop = true
		}
	}
}