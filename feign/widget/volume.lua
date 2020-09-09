local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local naughty = require("naughty")

local volume = {}

local volume_bar = wibox.widget {
	color            = beautiful.normal_color,
	background_color = beautiful.transparent,
	forced_width     = 200,
	forced_height    = 25,
	margins          = 1,
	paddings         = 1,
	ticks            = false,
	widget           = wibox.widget.progressbar
}

local prev_vol
local prev_playback
volume.notify = function()
	awful.spawn.easy_async_with_shell("amixer get Master", function(stdout)
		local vol, playback = string.match(stdout, "([%d]+)%%.*%[([%l]*)")

		if not vol or not playback then return end
		vol = tonumber(vol)

		if vol ~= prev_volume or playback ~= prev_playback then
			prev_volume = vol
			prev_playback = playback

			volume_bar:set_value(vol / 100)

			local text = " Volume - " .. vol .. "%"
			if vol == 0 or playback == "off" then
				text = text .. " [M]"
				volume_bar.color = beautiful.muted_color
			else
				volume_bar.color = beautiful.normal_color
			end

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
						layout = wibox.layout.fixed.horizontal,
						volume.notification.textbox,
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
	awful.spawn("amixer set Capture toggle")
end

return volume
