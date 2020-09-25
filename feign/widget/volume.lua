local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local markup = require("feign.markup")

local volume = {}

local volume_bar = wibox.widget {
	color            = beautiful.normal_color,
	background_color = beautiful.transparent,
	forced_width     = 200,
	forced_height    = 25,
	margins          = 1,
	paddings         = 1,
	ticks            = false,
	buttons = gears.table.join(
		awful.button({ }, 1, function()
			volume.toggle_mute()
		end),
		awful.button({ }, 3, function()
			volume.toggle_mic_mute()
		end),
		awful.button({ }, 4, function()
			volume.inc(1)
		end),
		awful.button({ }, 5, function()
			volume.inc(-1)
		end)
	),
	widget = wibox.widget.progressbar
}

local status_textbox = wibox.widget {
	font = "Material Design Icons 10",
	widget = wibox.widget.textbox
}

local prev_vol
local prev_playback
volume.notify = function()
	awful.spawn.easy_async_with_shell("{amixer get Master && amixer get Capture ; }", function(stdout)
		local vol, playback = string.match(stdout, "Playback [%d]+ %[([%d]+)%%%] %[([%l]*)")
		local mic_vol, mic_playback = string.match(stdout, "Capture [%d]+ %[([%d]+)%%%] %[([%l]*)")

		if not vol or not playback or not mic_vol or not mic_playback then return end
		vol = tonumber(vol)
		mic_vol = tonumber(mic_vol)

		if vol ~= prev_volume or playback ~= prev_playback or mic_vol ~= prev_mic_vol or mic_playback ~= prev_mic_playback then
			prev_volume = vol
			prev_playback = playback

			prev_mic_volume = mic_vol
			prev_mic_playback = mic_playback

			volume_bar:set_value(vol / 100)

			local text = " Volume - " .. vol .. "%"
			local status_text = ""

			if vol == 0 or playback == "off" then
				status_text = status_text .. utf8.char(0xf0581)
				volume_bar.color = beautiful.muted_color
			else
				volume_bar.color = beautiful.normal_color
			end
			if mic_playback == "off" then
				status_text = status_text .. " " .. utf8.char(0xf036d)
			end
			status_textbox:set_markup(markup(beautiful.muted_color, status_text))

			if not volume.notification then
				volume.notification = naughty.notify({
					text = text,
					font = beautiful.mono_font,
					height = 40,
					width = 200,
					destroy = function() volume.notification = nil end
				})
				volume.notification.box:setup {
					layout = wibox.layout.fixed.vertical,
					{
						volume.notification.textbox,
						nil,
						status_textbox,
						layout = wibox.layout.align.horizontal,
					},
					{
						layout = wibox.layout.fixed.horizontal,
						volume_bar
					}
				}
			else
				naughty.replace_text(volume.notification, nil, text)
			end
		end
	end)
end

volume.inc = function(percent)
	if percent >= 0 then
		percent = "+" .. percent
	end
	awful.spawn.easy_async("pactl set-sink-volume 0 " .. percent .. "%", volume.notify)
end

volume.toggle_mute = function()
	awful.spawn.easy_async("amixer -q set Master toggle", volume.notify)
end

volume.toggle_mic_mute = function()
	awful.spawn.easy_async("amixer set Capture toggle", volume.notify)
end

return volume
