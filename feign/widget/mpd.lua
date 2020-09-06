local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")
local prefs = require("prefs")
local markup = require("feign.markup")

local mpd = {}

mpd.now = {}

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
	local repeat_mode

	if mpd.now.repeat_mode and mpd.now.single_mode then
		repeat_mode = "OFF"
	elseif mpd.now.repeat_mode and not mpd.now.single_mode then
		repeat_mode = "SINGLE"
	else
		repeat_mode = "ALL"
	end

	local notification_text = "Repeat: " .. repeat_mode
	if not mpd.notification_repeat then
		mpd.notification_repeat = naughty.notify({
			text = notification_text,
			destroy = function() mpd.notification_repeat = nil end
		})
	else
		naughty.replace_text(mpd.notification_repeat, nil, notification_text)
	end

	mpd.repeat_cycle()
end

mpd.random_toggle = function()
	awful.spawn("mpc random")
end

mpd.random_toggle_notify = function()
	local random_mode

	if mpd.now.random_mode then
		random_mode = "OFF"
	else
		random_mode = "ON"
	end

	local notification_text = "Random: " .. random_mode
	if not mpd.notification_random then
		mpd.notification_random = naughty.notify({
			text = notification_text,
			destory = function() mpd.notification_random = nil end
		})
	else
		naughty.replace_text(mpd.notification_random, nil, notification_text)
	end

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
	end)
))

mpd.widget_update = function()
	local str = ""
	if mpd.now.state == "play" then
		str = "   " .. utf8.char(0xf04c) .. " "
	elseif mpd.now.state == "pause" then
		str = "   " .. utf8.char(0xf04b) .. " "
	end

	mpd.widget:set_markup(markup.font(beautiful.mpd_font, markup(beautiful.normal_color, str)))
end
-- }}}

-- {{{ MPD notification
mpd.show_notification = function()
	if not string.match(mpd.now.file, "http.*://") then -- local file instead of http stream
		local path = string.format("%s/%s", prefs.mpd_music_dir,
			string.match(mpd.now.file, ".*/"))
		local cmd = string.format("find '%s' -maxdepth 1 -type f | egrep -i -m1 '%s'",
			path:gsub("'", "'\\''"), "*\\.(jpg|jpeg|png|gif)$")

		awful.spawn.easy_async_with_shell(cmd, function(stdout)
			local album_art = stdout:gsub("\n", "")

			local title_textbox = wibox.widget {
				markup = markup.font("Fira Sans Bold 18", mpd.now.title),
				valign = "center",
				widget = wibox.widget.textbox
			}
			local artist_textbox = wibox.widget {
				text = mpd.now.artist,
				widget = wibox.widget.textbox
			}
			local album_textbox = wibox.widget {
				text = mpd.now.album .. " (" .. mpd.now.date .. ")",
				widget = wibox.widget.textbox
			}
			local w = math.max(
				title_textbox:get_preferred_size(),
				artist_textbox:get_preferred_size(),
				album_textbox:get_preferred_size()
			)

			naughty.destroy(mpd.notification)
			mpd.notification = naughty.notify({
				height = 100,
				width = 130 + w,
				destroy = function() mpd.notification = nil end
			})
			mpd.notification.box:setup {
				{
					{
						{
							title_textbox,
							nil,
							{
								artist_textbox,
								album_textbox,
								layout = wibox.layout.fixed.vertical
							},
							layout = wibox.layout.align.vertical
						},
						top = 3,
						bottom = 3,
						widget = wibox.container.margin
					},
					nil,
					{
						image = album_art,
						widget = wibox.widget.imagebox
					},
					layout = wibox.layout.align.horizontal
				},
				margins = 5,
				widget = wibox.container.margin
			}
		end)
	end
end
-- }}}

-- {{{ MPD protocol/updating
local prev_title
mpd.update = function()
	local mpd_cmd = "printf \"" .. prefs.mpd_password .. "status\\ncurrentsong\\nclose\\n\""
		.. " | socat -T3 unix-connect:" .. prefs.mpd_socket .. " stdio"

	awful.spawn.easy_async_with_shell(mpd_cmd, function(stdout)
		mpd.now = {
			random_mode  = false,
			single_mode  = false,
			repeat_mode  = false,
			consume_mode = false,
			pls_pos      = nil,
			pls_len      = nil,
			state        = nil,
			file         = nil,
			name         = nil,
			artist       = nil,
			title        = "hi",
			album        = nil,
			genre        = nil,
			track        = nil,
			date         = nil,
			time         = nil, -- Immediate update required for accuracy
			elapsed      = nil  -- ^
		}

		for line in string.gmatch(stdout, "[^\n]+") do
			for k, v in string.gmatch(line, "([%w]+):[%s](.*)$") do
				if     k == "state"          then mpd.now.state        = v
				elseif k == "file"           then mpd.now.file         = v
				elseif k == "Name"           then mpd.now.name         = gears.string.xml_unescape(v)
				elseif k == "Artist"         then mpd.now.artist       = gears.string.xml_unescape(v)
				elseif k == "Title"          then mpd.now.title        = gears.string.xml_unescape(v)
				elseif k == "Album"          then mpd.now.album        = gears.string.xml_unescape(v)
				elseif k == "Genre"          then mpd.now.genre        = gears.string.xml_unescape(v)
				elseif k == "Track"          then mpd.now.track        = gears.string.xml_unescape(v)
				elseif k == "Date"           then mpd.now.date         = gears.string.xml_unescape(v)
				elseif k == "Time"           then mpd.now.time         = v
				elseif k == "elapsed"        then mpd.now.elapsed      = string.match(v, "%d+")
				elseif k == "song"           then mpd.now.pls_pos      = v
				elseif k == "playlistlength" then mpd.now.pls_len      = v
				elseif k == "repeat"         then mpd.now.repeat_mode  = v ~= "0"
				elseif k == "single"         then mpd.now.single_mode  = v ~= "0"
				elseif k == "random"         then mpd.now.random_mode  = v ~= "0"
				elseif k == "consume"        then mpd.now.consume_mode = v ~= "0"
				end
			end
		end

		awesome.emit_signal("feign::mpd_update", mpd.now)

		-- Notification update
		if prev_title ~= mpd.now.title and mpd.now.state == "play" then
			prev_title = mpd.now.title
			mpd.show_notification()
		elseif mpd.now.state == "pause" then
			prev_title = nil
		end

		-- Widget update
		mpd.widget_update()
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
