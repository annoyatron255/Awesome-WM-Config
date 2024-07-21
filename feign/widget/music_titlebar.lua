local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local markup = require("feign.markup")
local gears = require("gears")
local markup = require("feign.markup")
local feign = require("feign")

local music_titlebar = {}

music_titlebar.update = function(mpd_now)
	if mpd_now.state == "play" then
		music_titlebar.widget:get_children_by_id("play_pause_icon")[1]:set_markup(
			markup(beautiful.muted_color, utf8.char(0xf03e4) .. " ")
		)
	elseif mpd_now.state == "pause" then
		music_titlebar.widget:get_children_by_id("play_pause_icon")[1]:set_markup(
			markup(beautiful.muted_color, utf8.char(0xf040a) .. " ")
		)
	end

	music_titlebar.widget:get_children_by_id("track_line")[1]:set_markup(
		markup(beautiful.normal_color, mpd_now.title)
	)
	local subline_text = string.format("%s — %s", mpd_now.artist, mpd_now.album)
	if mpd_now.date then
		subline_text = subline_text .. " (" .. mpd_now.date .. ")"
	end
	music_titlebar.widget:get_children_by_id("track_subline")[1]:set_markup(
		markup(beautiful.muted_color, subline_text)
	)

	-- Random icon colors
	local random_icon = music_titlebar.widget:get_children_by_id("random_icon")[1]
	if mpd_now.random_mode then
		random_icon:set_markup(markup(beautiful.accent_color, random_icon.text))
	else
		random_icon:set_markup(markup(beautiful.muted_color, random_icon.text))
	end

	-- Repeat icon shape and colors
	local single_icon = music_titlebar.widget:get_children_by_id("single_icon")[1]
	local repeat_icon = music_titlebar.widget:get_children_by_id("repeat_icon")[1]
	single_icon:set_visible(mpd_now.single_mode)

	if mpd_now.repeat_mode then
		single_icon:set_markup(markup(beautiful.accent_color, single_icon.text))
		repeat_icon:set_markup(markup(beautiful.accent_color, repeat_icon.text))
	else
		single_icon:set_markup(markup(beautiful.muted_color, single_icon.text))
		repeat_icon:set_markup(markup(beautiful.muted_color, repeat_icon.text))
	end
end

awesome.connect_signal("feign::mpd_update", function(mpd_now)
	if music_titlebar.widget then
		music_titlebar.update(mpd_now)
	end
end)

music_titlebar.create = function(c)
	if music_titlebar.widget == nil then
		local left_icons_font = "Material Design Icons 19"
		music_titlebar.widget = wibox.widget {
			{ -- Left icon grid
				{ -- Current playlist
					align = "center",
					font = left_icons_font,
					markup = markup(beautiful.muted_color, " " .. utf8.char(0xf0cb8) .. " "),
					buttons = awful.button({ }, 1, function()
						awful.spawn("xdotool key --window "..tostring(client.focus.window).." 1")
					end),
					widget = wibox.widget.textbox
				},
				{ -- File browser
					align = "center",
					font = left_icons_font,
					markup = markup(beautiful.muted_color, utf8.char(0xf1359) .. " "),
					buttons = awful.button({ }, 1, function()
						awful.spawn("xdotool key --window "..tostring(client.focus.window).." 2")
					end),
					widget = wibox.widget.textbox
				},
				{ -- Album browser
					align = "center",
					font = left_icons_font,
					markup = markup(beautiful.muted_color, utf8.char(0xf0025) .. " "),
					buttons = awful.button({ }, 1, function()
						awful.spawn("xdotool key --window "..tostring(client.focus.window).." 4")
					end),
					widget = wibox.widget.textbox
				},
				{ -- Previous track
					align = "center",
					font = left_icons_font,
					markup = markup(beautiful.muted_color, " " .. utf8.char(0xf04ae) .. " "),
					buttons = awful.button({ }, 1, function()
						feign.widget.mpd.prev_track()
					end),
					widget = wibox.widget.textbox
				},
				{ -- Play/pause
					align = "center",
					font = left_icons_font,
					markup = markup(beautiful.muted_color, utf8.char(0xf040a) .. " "),
					id = "play_pause_icon",
					buttons = gears.table.join(
						awful.button({ }, 1, function()
							feign.widget.mpd.toggle()
						end),
						awful.button({ }, 4, function()
							awful.spawn.easy_async("pactl set-sink-volume 0 +1%",
								beautiful.volume.notify)
						end),
						awful.button({ }, 5, function()
							awful.spawn.easy_async("pactl set-sink-volume 0 -1%",
								beautiful.volume.notify)
						end)
					),
					widget = wibox.widget.textbox
				},
				{ -- Next track
					align = "center",
					font = left_icons_font,
					markup = markup(beautiful.muted_color, utf8.char(0xf04ad) .. " "),
					buttons = awful.button({ }, 1, function()
						feign.widget.mpd.next_track()
					end),
					widget = wibox.widget.textbox
				},
				forced_num_cols = 3,
				forced_num_rows = 2,
				homogeneous = false,
				layout = wibox.layout.grid
			},
			{ -- Center title/track info
				{
					--[[nil, -- Left side
					{
						{ -- Track title]]
							align = "center",
							font = "Fira Sans Bold 18",
							id = "track_line",
							widget = wibox.widget.textbox
						--[[},
						step_function = wibox.container.scroll.step_functions.linear_increase,
						speed = 50,
						extra_space = 100,
						fps = 60,
						layout = wibox.container.scroll.horizontal
					},
					expand = "outside",
					layout = wibox.layout.align.horizontal -- So text is centered when not scrolling]]
				},
				nil, -- Middle
				{
					--[[nil, -- Left side
					{
						{ -- Track info]]
							align = "center",
							font = beautiful.font,
							id = "track_subline",
							widget = wibox.widget.textbox
						--[[},
						step_function = wibox.container.scroll.step_functions.linear_increase,
						speed = 50,
						extra_space = 50,
						fps = 60,
						layout = wibox.container.scroll.horizontal
					},
					expand = "outside",
					layout = wibox.layout.align.horizontal -- So text is centered when not scrolling]]
				},
				layout = wibox.layout.align.vertical
			},
			{ -- Right repeat/random icons

				{
					align = "center",
					font = "FontAwesome 20",
					text = utf8.char(0xf074),
					id = "random_icon",
					buttons = awful.button({ }, 1, function()
						feign.widget.mpd.random_toggle()
					end),
					widget = wibox.widget.textbox
				},
				{
					{
						align = "center",
						font = "FontAwesome 20",
						text = "  " .. utf8.char(0xf021) .. "  ",
						id = "repeat_icon",
						buttons = awful.button({ }, 1, function()
							feign.widget.mpd.repeat_cycle()
						end),
						widget = wibox.widget.textbox
					},
					{
						align = "center",
						font = "Fira Sans Bold 9",
						text = "1" .. utf8.char(0x2009),
						id = "single_icon",
						widget = wibox.widget.textbox
					},
					layout = wibox.layout.stack
				},
				layout = wibox.layout.fixed.horizontal
			},
			layout = wibox.layout.align.horizontal,
		}
	end

	awful.titlebar(c, {
		size = 55,
		position = "top",
		bg = beautiful.base_color
	}):setup {
		{
			music_titlebar.widget,
			layout = wibox.layout.stack
		},
		id = "active_margin",
		color = beautiful.accent_color,
		widget = wibox.container.margin
	}

	c:connect_signal("focus", function(c)
		c._private.titlebars["top"].drawable
			:get_children_by_id("active_margin")[1]
			:set_color(beautiful.border_focus)
	end)

	c:connect_signal("unfocus", function(c)
		c._private.titlebars["top"].drawable
			:get_children_by_id("active_margin")[1]
			:set_color(beautiful.border_normal)
	end)

	-- Update once
	feign.widget.mpd.update()
end

return music_titlebar
