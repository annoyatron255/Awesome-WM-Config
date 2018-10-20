--[[
	annoyatron255's main theme
	awesome 4.2
	3 July 2018
--]]

local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local awesome, client, os = awesome, client, os

local theme					= {}
theme.dir					= os.getenv("HOME") .. "/.config/awesome/themes/little_parade"
-- Settings
theme.border_width				= 0
theme.menu_height				= 16
theme.menu_width				= 130
theme.useless_gap 				= 0
theme.taglist_spacing				= 0
theme.tasklist_disable_icon			= true
theme.titlebar_size				= 1
theme.floating_titlebar_size			= 5

theme.wallpaper					= theme.dir .. "/wall.png"
-- Fonts
theme.font					= "Fira Sans Medium 10.5"
theme.taglist_font				= "FontAwesome 10.5" -- FontAwesome v4.7
theme.mpd_font					= "FontAwesome 6" -- FontAwesome v4.7
theme.mono_font					= "Fira Mono 10.5"
-- Colors
theme.base_color				= "#000000F3"
theme.normal_color				= "#BBBBBB"
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

local markup = lain.util.markup

theme.tagnames = { 
	utf8.char(0xf269), -- Firefox
	utf8.char(0xf120), -- Terminal
	utf8.char(0xf001), -- Music
	utf8.char(0xf0e0), -- Mail
	utf8.char(0xf1b6), -- Steam
	"6", "7", "8", "9"
}

-- Textclock
local mytextclock = wibox.widget.textclock(" %H:%M")
mytextclock.font = theme.font

-- Calender
theme.cal = lain.widget.cal({
	attach_to = { mytextclock },
	followtag = true,
	notification_preset = {
		font = theme.mono_font,
		fg = theme.normal_color,
		bg = theme.base_color
	}
})

-- MPD
function theme.mpd_toggle()
	os.execute("mpc toggle")
	theme.mpd.update()
end

function theme.mpd_stop()
	os.execute("mpc stop")
	theme.mpd.update()
end

function theme.mpd_next()
	os.execute("mpc next")
	theme.mpd.update()
end

function theme.mpd_prev()
	os.execute("mpc prev")
	theme.mpd.update()
end

function theme.mpd_repeat_cycle()
	local repeat_mode
	if mpd_now.repeat_mode and mpd_now.single_mode then
		os.execute("mpc repeat off")
		os.execute("mpc single off")
		repeat_mode = "OFF"
	elseif mpd_now.repeat_mode and not mpd_now.single_mode then
		os.execute("mpc single on")
		repeat_mode = "SINGLE"
	else
		os.execute("mpc repeat on")
		repeat_mode = "ALL"
	end
	local notification_text = "Repeat: " .. repeat_mode
	if not theme.mpd.notification_repeat then
		theme.mpd.notification_repeat = naughty.notify({
			text = notification_text,
			destroy = function() theme.mpd.notification_repeat = nil end
		})
	else
		naughty.replace_text(theme.mpd.notification_repeat, nil, notification_text)
	end
	theme.mpd.update()
end

function theme.mpd_random_toggle()
	local random_mode
	if mpd_now.random_mode then
		random_mode = "OFF"
	else
		random_mode = "ON"
	end
	os.execute("mpc random")
	local notification_text = "Random: " .. random_mode
	if not theme.mpd.notification_random then
		theme.mpd.notification_random = naughty.notify({
			text = notification_text,
			destory = function() theme.mpd.notification_random = nil end
		})
	else
		naughty.replace_text(theme.mpd.notification_random, nil, notification_text)
	end
	theme.mpd.update()
end



theme.mpd = lain.widget.mpd({
	followtag = true,
	settings = function()
		local state
		local notification_text
		if mpd_now.state == "play" then
			state = "   " .. utf8.char(0xf04b) .. " "
		elseif mpd_now.state == "pause" then
			state = "   " .. utf8.char(0xf04c) .. " "
		else
			state = ""
		end

		if mpd_now.title == "N/A" then
			notification_text = mpd_now.file
		else
			notification_text = string.format("%s\n%s (%s) - %s", mpd_now.title,
				mpd_now.artist, mpd_now.album, mpd_now.date)
		end

		widget:set_markup(markup.font(theme.mpd_font, markup(theme.normal_color, state)))
		mpd_notification_preset = {
			title = "Now playing",
			timeout = 6,
			text = notification_text
		}
	end,
})

theme.mpd.widget:buttons(gears.table.join(
	awful.button({ }, 1, function()
		theme.mpd_toggle()
	end),
	awful.button({ }, 2, function()
		theme.mpd_random_toggle()
	end),
	awful.button({ }, 3, function()
		theme.mpd_repeat_cycle()
	end),
	awful.button({ }, 4, function()
		theme.mpd_next()
	end),
	awful.button({ }, 5, function()
		theme.mpd_prev()
	end)
))

-- Visualizer
-- terminal pretty much needs to be urxvt(c)
function theme.spawn_visualizer(s, terminal)
	awful.spawn(terminal .. "\
		-font 'xft:Fira Mono:size=10'\
		-scollBar false\
		-depth 32\
		-bg rgba:0000/0000/0000/0000\
		-lineSpace 14\
		-letterSpace 0\
		-name vis\
		-e sh -c 'export XDG_CONFIG_HOME=" .. theme.dir .. " && \
		vis -c " .. theme.dir .. "/vis/config" .. s.index .. "'"
	)
end

----Battery

-- ALSA volume
theme.volume = lain.widget.alsabar({
	width = 200,
	height = 25,
	colors = {
		background = theme.base_color,
		mute = theme.muted_color,
		unmute = theme.normal_color
	},
	notification_preset = {
		font = theme.mono_font,
		fg = theme.fg_normal
	}
})

-- Super hacky volume bar notifications
function theme.volume.notify()
	theme.volume.update(theme.volume.notify_callback)
end

local volume_textbox = wibox.widget.textbox()

function theme.volume.notify_callback()
	local backup_notification
	if  theme.volume.notification then
		backup_notification = theme.volume.notification
		naughty.destroy(theme.volume.notification, naughty.notificationClosedReason.dismissedByCommand, true)
	end
	theme.volume.notification = naughty.notify({
		height = 40,
		width = 200,
		destroy = function() theme.volume.notification = nil end
	})
	if volume_now.status == "on" then
		volume_textbox:set_markup(markup.font(theme.mono_font, " Volume - " .. volume_now.level .. "%"))
	else
		volume_textbox:set_markup(markup.font(theme.mono_font, " Volume - " .. volume_now.level .. "% [Muted]"))
	end
	theme.volume.notification.box:setup {
		layout = wibox.layout.fixed.vertical,
		{
			layout = wibox.layout.fixed.horizontal,
			volume_textbox,
		},
		{
			layout = wibox.layout.fixed.horizontal,
			theme.volume.bar
		}
	}
	backup_notification.box.visible = false
end

-- Weather
theme.weather = lain.widget.weather({
	city_id = 5025219 -- Eden Prairie
})

-- Eminent-like task filtering
local orig_taglist_filter = awful.widget.taglist.filter.all

-- Taglist label functions
awful.widget.taglist.filter.all = function(t, args)
	if t.selected or #focusable(t:clients()) > 0 then
		return orig_taglist_filter(t, args)
	end
end

local mysystray = wibox.widget.systray()
mysystray:set_base_size(16)
--mysystray:set_visible(false)

-- Hide mylayoutbox 
client.connect_signal("focus", function() 
	awful.screen.focused().mylayoutbox:set_visible(false)
end)

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
	awful.tag(theme.tagnames, s, awful.layout.suit.tile)

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()

	-- Create an imagebox widget which will contain an icon indicating which layout we're using
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({ }, 1, function() awful.layout.inc(1) end),
		awful.button({ }, 3, function() awful.layout.inc(-1) end),
		awful.button({ }, 4, function() awful.layout.inc(1) end),
		awful.button({ }, 5, function() awful.layout.inc(-1) end)
	))
	s.mylayoutbox:set_visible(false)

	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(
		s,
		awful.widget.taglist.filter.all,
		awful.util.taglist_buttons,
		{font = theme.taglist_font}
	)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(
		s,
		awful.widget.tasklist.filter.currenttags,
		awful.util.tasklist_buttons
	)

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = 18,
		bg = theme.base_color,
		fg = theme.normal_color
	})

	s.mywibox:setup {
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			s.mylayoutbox,
			s.mytaglist,
			s.mypromptbox
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			mysystray,
			theme.mpd.widget,
			mytextclock
		}
	}
end

return theme
