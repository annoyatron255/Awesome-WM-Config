--[[
	annoyatron255's main theme
	awesome v4.3
--]]

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local keys = require("keys")
local prefs = require("prefs")
local feign = require("feign")
local helpers = require("feign.helpers")
local markup = require("feign.markup")

local theme					= {}
theme.dir					= os.getenv("HOME") .. "/.config/awesome/themes/little_parade"
-- Settings
theme.border_width				= 0
theme.menu_height				= prefs.dpi(16)
theme.menu_width				= prefs.dpi(130)
theme.useless_gap 				= 0
theme.taglist_spacing				= 0
theme.tasklist_disable_icon			= true
theme.titlebar_size				= 1
theme.floating_titlebar_size			= prefs.dpi(5)

theme.wallpaper					= theme.dir .. "/wall.png"
theme.wallpaper_16x10				= theme.dir .. "/wall_16x10.png"
-- Fonts
theme.font					= "Fira Sans Medium 10.5"
theme.taglist_font				= "FontAwesome 10.5" -- FontAwesome v4.7
theme.mpd_font					= "FontAwesome 6" -- FontAwesome v4.7
theme.mono_font					= "Fira Mono 10.5"

theme.hotkeys_font				= "Fira Mono 9"
-- Colors
theme.base_color				= "#000000E3"
theme.normal_color				= "#FFFFFF"
theme.accent_color				= "#11AAFC"
theme.muted_color				= "#777777"
theme.transparent				= "#00000000"

theme.fg_normal					= theme.normal_color
theme.fg_focus					= theme.accent_color
theme.bg_normal					= theme.transparent
theme.bg_focus					= theme.transparent
theme.fg_urgent					= theme.transparent
theme.bg_urgent					= theme.normal_color

theme.tasklist_bg_urgent			= theme.normal_color
theme.tasklist_fg_urgent			= "#000000"
theme.tasklist_fg_minimize			= theme.muted_color

theme.border_normal				= theme.base_color
theme.border_focus				= theme.accent_color

theme.taglist_fg_focus				= theme.accent_color
theme.taglist_bg_focus				= theme.transparent
theme.taglist_fg_occupied			= theme.muted_color
theme.taglist_bg_occupied			= theme.transparent

theme.titlebar_bg_normal			= theme.base_color
theme.titlebar_bg_focus				= theme.accent_color

theme.hotkeys_bg				= theme.base_color
theme.bg_systray				= theme.base_color

theme.menu_bg_normal				= theme.base_color
theme.menu_bg_focus				= theme.base_color

theme.notification_bg				= theme.base_color
theme.notification_fg				= theme.normal_color
-- Icons
theme.awesome_icon				= theme.dir .. "/icons/awesome.png"
theme.menu_submenu_icon				= theme.dir .. "/icons/submenu.png"

theme.layout_tile				= theme.dir .. "/icons/tile.png"
theme.layout_tileleft				= theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom				= theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop				= theme.dir .. "/icons/tiletop.png"
theme.layout_fairv				= theme.dir .. "/icons/fairv.png"
theme.layout_fairh				= theme.dir .. "/icons/fairh.png"
theme.layout_spiral				= theme.dir .. "/icons/spiral.png"
theme.layout_dwindle				= theme.dir .. "/icons/dwindle.png"
theme.layout_max				= theme.dir .. "/icons/max.png"
theme.layout_fullscreen				= theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier				= theme.dir .. "/icons/magnifier.png"
theme.layout_floating				= theme.dir .. "/icons/floating.png"

-- Textclock
local mytextclock = wibox.widget.textclock(" %H:%M")
mytextclock.font = theme.font

-- Calendar
feign.widget.calendar.attach(mytextclock)

-- Eminent-like task filtering
local orig_taglist_filter = awful.widget.taglist.filter.all

-- Taglist label functions
awful.widget.taglist.filter.all = function(t, args)
	if t.selected or #helpers.focusable(t:clients()) > 0 then
		return orig_taglist_filter(t, args)
	end
end

local mysystray = wibox.widget.systray()
mysystray:set_base_size(prefs.dpi(16))
--mysystray:set_visible(false)

-- Hide mylayoutbox 
client.connect_signal("focus", function() 
	awful.screen.focused().mylayoutbox:set_visible(false)
end)

-- Current mode status textbox
theme.mymodebox = wibox.widget.textbox("")

theme.myrecordbox = wibox.widget.textbox("")
theme.myrecordbox:buttons(gears.table.join(
	awful.button({ }, 1, function()
		awful.spawn("kill -s SIGINT " .. record_pid)
		record_pid = nil
		theme.myrecordbox.text = ""
	end)
))

function theme.set_wallpaper(s)
	-- Wallpaper
	local wallpaper = theme.wallpaper
	-- If wallpaper is a function, call it with the screen
	if type(wallpaper) == "function" then
		wallpaper = wallpaper(s)
	end
	gears.wallpaper.maximized(wallpaper, s, false)
end

function theme.at_screen_connect(s)
	-- Set wallpaper on new screen
	theme.set_wallpaper(s)

	-- Tags
	awful.tag(prefs.tag_names, s, awful.layout.suit.tile)

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()

	-- Create an imagebox widget which will contain an icon indicating which layout we're using
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({ }, 1, function() awful.layout.inc(1) end),
		awful.button({ }, 3, function() awful.layout.inc(-1) end),
		awful.button({ }, 5, function() awful.layout.inc(1) end),
		awful.button({ }, 4, function() awful.layout.inc(-1) end)
	))
	s.mylayoutbox:set_visible(false)

	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(
		s,
		awful.widget.taglist.filter.all,
		keys.taglist_buttons,
		{font = theme.taglist_font}
	)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(
		s,
		awful.widget.tasklist.filter.currenttags,
		keys.tasklist_buttons
	)

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = prefs.dpi(18),
		bg = theme.base_color,
		fg = theme.normal_color
	})

	s.mywibox:setup {
		layout = wibox.container.margin,
		left = 5,
		right = 5,
		{
			layout = wibox.layout.align.horizontal,
			{ -- Left widgets
				layout = wibox.layout.fixed.horizontal,
				s.mylayoutbox,
				s.mytaglist,
				theme.mymodebox,
				s.mypromptbox
			},
			s.mytasklist, -- Middle widget
			{ -- Right widgets
				layout = wibox.layout.fixed.horizontal,
				mysystray,
				feign.widget.mpd.widget,
				theme.myrecordbox,
				feign.widget.battery.widget,
				mytextclock
			}
		}
	}
end

return theme
