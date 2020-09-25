local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")

-- Brightness bar notification
local brightness = {}

local brightness_bar = wibox.widget {
	color            = beautiful.normal_color,
	background_color = beautiful.transparent,
	forced_width     = 200,
	forced_height    = 25,
	margins          = 1,
	paddings         = 1,
	ticks            = false,
	buttons = gears.table.join(
		awful.button({ }, 1, function()
			brightness.inc(1)
		end),
		awful.button({ }, 3, function()
			brightness.inc(-1)
		end),
		awful.button({ }, 4, function()
			brightness.inc(1)
		end),
		awful.button({ }, 5, function()
			brightness.inc(-1)
		end)
	),
	widget = wibox.widget.progressbar
}

brightness.notify = function()
	local brightness_now
	awful.spawn.easy_async_with_shell("xbacklight", function(cmd_out)
		local val = math.floor(tonumber(cmd_out))

		if not val then return end

		if val ~= brightness_now then
			brightness_now = val
			brightness_bar:set_value(brightness_now / 100)

			local text = " Brightness - " .. brightness_now .. "%"

			if not brightness_notification then
				brightness_notification = naughty.notify({
					text = text,
					font = beautiful.mono_font,
					width = 200,
					height = 40,
					destroy = function() brightness_notification = nil end
				})
				brightness_notification.box:setup {
					layout = wibox.layout.fixed.vertical,
					{
						layout = wibox.layout.fixed.horizontal,
						brightness_notification.textbox
					},
					{
						layout = wibox.layout.fixed.horizontal,
						brightness_bar
					}
				}
			else
				naughty.replace_text(brightness_notification, nil, text)
			end
		end
	end)
end

brightness.inc = function(percent)
	if percent >= 0 then
		percent = "+" .. percent
	end
	awful.spawn.easy_async("xbacklight " .. percent, brightness.notify)
end

return brightness
