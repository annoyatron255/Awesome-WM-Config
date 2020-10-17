local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")
local prefs = require("prefs")
local markup = require("feign.markup")
local feign = require("feign")

local mpd = {}

mpd.now = {}

local notification_timout = 3

local request_notification = false

-- {{{ MPD controls
mpd.toggle = function()
	awful.spawn("mpc toggle")
end

mpd.stop = function()
	awful.spawn("mpc stop")
end

mpd.next_track = function()
	awful.spawn("mpc next")
end

mpd.prev_track = function()
	awful.spawn("mpc prev")
end

mpd.repeat_cycle = function()
	if mpd.now.repeat_mode and mpd.now.single_mode then
		awful.spawn.with_shell("mpc repeat off; mpc single off")
	elseif mpd.now.repeat_mode and not mpd.now.single_mode then
		awful.spawn("mpc single on")
	else
		awful.spawn("mpc repeat on")
	end
end

mpd.repeat_cycle_notify = function()
	if mpd.notification then
		naughty.reset_timeout(mpd.notification, notification_timout)
	end
	request_notification = true
	mpd.repeat_cycle()
end

mpd.random_toggle = function()
	awful.spawn("mpc random")
end

mpd.random_toggle_notify = function()
	if mpd.notification then
		naughty.reset_timeout(mpd.notification, notification_timout)
	end
	request_notification = true
	mpd.random_toggle()
end
-- }}}

-- {{{ MPD widget
mpd.widget = wibox.widget.textbox()

mpd.widget:buttons(gears.table.join(
	awful.button({ }, 1, function()
		mpd.toggle()
	end),
	awful.button({ }, 2, function()
		mpd.random_toggle_notify()
	end),
	awful.button({ }, 3, function()
		mpd.repeat_cycle_notify()
	end),
	awful.button({ }, 5, function()
		mpd.next_track()
	end),
	awful.button({ }, 4, function()
		mpd.prev_track()
	end),
	awful.button({ }, 9, function()
		mpd.next_track()
	end),
	awful.button({ }, 8, function()
		mpd.prev_track()
	end)
))

mpd.widget:connect_signal("mouse::enter", function()
	if mpd.now.state == "play" then
		request_notification = true
		mpd.update()
	end
end)

mpd.update_widget = function(mpd_now)
	local str = ""
	if mpd_now.state == "play" then
		str = "   " .. utf8.char(0xf04c) .. " "
	elseif mpd_now.state == "pause" then
		str = "   " .. utf8.char(0xf04b) .. " "
	end

	mpd.widget:set_markup(markup.font(beautiful.mpd_font, markup(beautiful.normal_color, str)))
end
awesome.connect_signal("feign::mpd_update", function(mpd_now)
	mpd.update_widget(mpd_now)
end)
-- }}}

-- {{{ MPD notification
local notification_widget
local notification_widget_width
mpd.update_notification = function(mpd_now)
	local album_art = ""

	local construct_notification = function()
		local title_textbox = wibox.widget {
			markup = markup.font("Fira Sans Bold 18", mpd_now.title),
			valign = "center",
			widget = wibox.widget.textbox
		}
		local artist_textbox = wibox.widget {
			markup = mpd_now.artist,
			widget = wibox.widget.textbox
		}
		local album_textbox = wibox.widget {
			markup = mpd_now.album,
			widget = wibox.widget.textbox
		}
		if mpd_now.date then
			album_textbox:set_text(album_textbox:get_text() .. " (" ..mpd_now.date .. ")")
		end

		-- Repeat/random status widget
		local status_widget
		if not status_widget then
			status_widget = wibox.widget {
				{
					align = "center",
					font = "FontAwesome 11.5",
					text = utf8.char(0xf074) .. " ",
					id = "random_icon",
					buttons = awful.button({ }, 1, function()
						mpd.random_toggle_notify()
					end),
					widget = wibox.widget.textbox
				},
				{
					{
						align = "center",
						font = "FontAwesome 11.5",
						text = utf8.char(0xf021),
						id = "repeat_icon",
						buttons = awful.button({ }, 1, function()
							mpd.repeat_cycle_notify()
						end),
						widget = wibox.widget.textbox
					},
					{
						align = "center",
						font = "Fira Sans Bold 7",
						text = "1" .. utf8.char(0x2009),
						id = "single_icon",
						widget = wibox.widget.textbox
					},
					layout = wibox.layout.stack
				},
				layout = wibox.layout.fixed.horizontal
			}
		end
		--Random icon colors
		local random_icon = status_widget:get_children_by_id("random_icon")[1]
		if mpd_now.random_mode then
			random_icon:set_markup(markup(beautiful.accent_color, random_icon.text))
		else
			random_icon:set_markup(markup(beautiful.muted_color, random_icon.text))
		end
		-- Repeat icon shape and colors
		local single_icon = status_widget:get_children_by_id("single_icon")[1]
		local repeat_icon = status_widget:get_children_by_id("repeat_icon")[1]
		single_icon:set_visible(mpd_now.single_mode)

		if mpd_now.repeat_mode then
			single_icon:set_markup(markup(beautiful.accent_color, single_icon.text))
			repeat_icon:set_markup(markup(beautiful.accent_color, repeat_icon.text))
		else
			single_icon:set_markup(markup(beautiful.muted_color, single_icon.text))
			repeat_icon:set_markup(markup(beautiful.muted_color, repeat_icon.text))
		end

		local extra_margin_width
		local image_width
		if album_art ~= "" then
			image_width = 95
			extra_margin_width = 15
		else
			image_width = 0
			extra_margin_width = 10
		end
		local info_width = math.max(
			title_textbox:get_preferred_size(),
			artist_textbox:get_preferred_size(),
			album_textbox:get_preferred_size() + 100
		)
		notification_widget_width = info_width + image_width + extra_margin_width

		notification_widget = wibox.widget {
			{
				{
					{
						title_textbox,
						{
							nil,
							{
								max_value = mpd_now.time,
								value = mpd_now.elapsed,
								forced_height = 2,
								background_color = beautiful.transparent,
								color = beautiful.accent_color,
								widget = wibox.widget.progressbar
							},
							nil,
							expand = "outside",
							id = "progress_bar_bounding",
							layout = wibox.layout.align.vertical
						},
						{
							artist_textbox,
							{
								album_textbox,
								nil,
								status_widget,
								layout = wibox.layout.align.horizontal
							},
							layout = wibox.layout.fixed.vertical
						},
						buttons = gears.table.join(
							awful.button({ }, 4, function()
								awful.spawn.easy_async("mpc seek +10", function()
									naughty.reset_timeout(mpd.notification,
									                      notification_timout)
								end)
							end),
							awful.button({ }, 5, function()
								awful.spawn.easy_async("mpc seek -10", function()
									naughty.reset_timeout(mpd.notification,
									                      notification_timout)
								end)
							end)
						),
						layout = wibox.layout.align.vertical
					},
					top = 2,
					bottom = 2,
					forced_width = info_width,
					widget = wibox.container.margin
				},
				nil,
				{
					nil,
					{
						image = album_art,
						forced_width = image_width,
						buttons = gears.table.join(
							awful.button({ }, 1, function()
								naughty.destroy(mpd.notification)
							end),
							awful.button({ }, 4, function()
								naughty.reset_timeout(mpd.notification,
								                      notification_timout)
								feign.widget.volume.inc(1)
							end),
							awful.button({ }, 5, function()
								naughty.reset_timeout(mpd.notification,
								                      notification_timout)
								feign.widget.volume.inc(-1)
							end)
						),
						widget = wibox.widget.imagebox
					},
					nil,
					expand = "outside",
					layout = wibox.layout.align.vertical
				},
				layout = wibox.layout.align.horizontal
			},
			top = 5,
			bottom = 5,
			left = 5,
			right = 0,
			widget = wibox.container.margin
		}

		notification_widget:get_children_by_id("progress_bar_bounding")[1]
			:connect_signal("button::press", function(widget, lx, ly, button, mods, find_widgets_result)
			if button == 1 then
				local percent = math.floor(lx / find_widgets_result.widget_width * 100)
				request_notification = true
				awful.spawn.easy_async("mpc seek " .. percent .. "%", function()
					naughty.reset_timeout(mpd.notification, notification_timout)
					mpd.update()
				end)
			end
		end)

		awesome.emit_signal("feign::mpd_update_notification", mpd_now)
	end

	if not string.match(mpd_now.file, "http.*://") then -- local file instead of http stream
		local path = string.format("%s/%s", prefs.mpd_music_dir,
			string.match(mpd_now.file, ".*/"))
		local cmd = string.format("find '%s' -maxdepth 1 -type f | egrep -i -m1 '%s'",
			path:gsub("'", "'\\''"), "*\\.(jpg|jpeg|png|gif)$")

		awful.spawn.easy_async_with_shell(cmd, function(stdout)
			album_art = stdout:gsub("\n", "")

			construct_notification()
		end)
	else
		construct_notification()
	end
end
awesome.connect_signal("feign::mpd_update", function(mpd_now)
	mpd.update_notification(mpd_now)
end)

local notification_update_timer = gears.timer {
	timeout = 0.5,
	callback = function()
		request_notification = true
		mpd.update()
	end
}

local prev_notification_widget_width
mpd.show_notification = function()
	if notification_widget_width ~= prev_notification_widget_width then
		prev_notification_widget_width = notification_widget_width
		naughty.destroy(mpd.notification)
	end
	if not mpd.notification then
		notification_update_timer:start()
		mpd.notification = naughty.notify({
			height = 100,
			width = notification_widget_width,
			timout = notification_timout,
			destroy = function()
				mpd.notification = nil
				notification_update_timer:stop()
			end
		})
	end

	mpd.notification.box:set_widget(notification_widget)
end

local prev_title
awesome.connect_signal("feign::mpd_update_notification", function(mpd_now)
	-- Notification update
	if request_notification or (prev_title ~= mpd_now.title and mpd_now.state == "play") then
		prev_title = mpd_now.title
		mpd.show_notification()
	elseif mpd_now.state == "pause" then
		prev_title = nil
	end

	request_notification = false
end)
-- }}}

-- {{{ MPD protocol/updating
mpd.update = function()
	local mpd_cmd = "printf \"" .. prefs.mpd_password .. "status\\ncurrentsong\\nclose\\n\""
		.. " | socat -T3 unix-connect:" .. prefs.mpd_socket .. " stdio"

	awful.spawn.easy_async_with_shell(mpd_cmd, function(stdout)
		local mpd_now = {
			random_mode  = false,
			single_mode  = false,
			repeat_mode  = false,
			consume_mode = false,
			pls_pos      = nil,
			pls_len      = nil,
			state        = nil,
			file         = nil,
			name         = nil,
			artist       = "Unknown Artist",
			title        = nil,
			album        = nil,
			genre        = nil,
			track        = nil,
			date         = nil,
			time         = nil, -- Immediate update required for accuracy
			elapsed      = nil  -- ^
		}

		for line in string.gmatch(stdout, "[^\n]+") do
			for k, v in string.gmatch(line, "([%w]+):[%s](.*)$") do
				if     k == "state"          then mpd_now.state        = v
				elseif k == "file"           then mpd_now.file         = v
				elseif k == "Name"           then mpd_now.name         = gears.string.xml_escape(v)
				elseif k == "Artist"         then mpd_now.artist       = gears.string.xml_escape(v)
				elseif k == "Title"          then mpd_now.title        = gears.string.xml_escape(v)
				elseif k == "Album"          then mpd_now.album        = gears.string.xml_escape(v)
				elseif k == "Genre"          then mpd_now.genre        = gears.string.xml_escape(v)
				elseif k == "Track"          then mpd_now.track        = gears.string.xml_escape(v)
				elseif k == "Date"           then mpd_now.date         = gears.string.xml_escape(v)
				elseif k == "Time"           then mpd_now.time         = tonumber(v)
				elseif k == "elapsed"        then mpd_now.elapsed      = tonumber(string.match(v, "%d+"))
				elseif k == "song"           then mpd_now.pls_pos      = tonumber(v)
				elseif k == "playlistlength" then mpd_now.pls_len      = tonumber(v)
				elseif k == "repeat"         then mpd_now.repeat_mode  = v ~= "0"
				elseif k == "single"         then mpd_now.single_mode  = v ~= "0"
				elseif k == "random"         then mpd_now.random_mode  = v ~= "0"
				elseif k == "consume"        then mpd_now.consume_mode = v ~= "0"
				end
			end
		end

		if not mpd_now.title then
			if mpd_now.name then
				mpd_now.title = mpd_now.name
			else
				mpd_now.title = mpd_now.file:match("([^/]*)%..+")
			end
		end

		if not mpd_now.album then
			if mpd_now.file:match("http.*://") then
				mpd_now.album = "Web Stream"
			else
				mpd_now.album = mpd_now.file:match("(.*)/")
			end
		end

		mpd.now = mpd_now
		awesome.emit_signal("feign::mpd_update", mpd_now)
	end)
end

-- Kill old processes
awful.spawn.easy_async_with_shell("pgrep -xf \"mpc idleloop\" | xargs kill", function()
	awful.spawn.with_line_callback("mpc idleloop", {
		stdout = function(line)
			mpd.update()
		end
	})
end)
-- }}}

return mpd
