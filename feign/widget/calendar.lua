local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local markup = require("feign.markup")

local calendar = {}

calendar.offset = 0

calendar.get_date_with_offset = function()
	local date = os.date("*t")

	date.month = date.month + calendar.offset

	while date.month > 12 do
		date.month = date.month - 12
		date.year = date.year + 1
	end

	while date.month < 1 do
		date.month = date.month + 12
		date.year = date.year - 1
	end

	return date
end

calendar.show = function(timeout)
	if not timeout then timeout = 5 end

	if not calendar.notification then
		calendar.notification = naughty.notify {
			width = 300,
			height = 220,
			timeout = timeout,
			destroy = function()
				calendar.notification = nil
				calendar.offset = 0
			end
		}
	end

	calendar.notification.box:setup {
		{
			date = calendar.get_date_with_offset(),
			font = beautiful.mono_font,
			start_sunday = true,
			long_weekdays = true,
			widget = wibox.widget.calendar.month,
			fn_embed = function(widget, flag, date)
				if flag == "focus" and calendar.offset == 0 then
					widget:set_markup(markup.bold(markup(beautiful.accent_color, widget:get_text())))
				elseif flag == "focus" and calendar.offset ~= 0 then
					widget:set_markup(markup(beautiful.normal_color, widget:get_text()))
				elseif flag == "weekday" then
					widget:set_markup(markup.bold(widget:get_text()))
				elseif flag == "header" then
					widget:set_markup(markup.font("Fira Sans 13", widget:get_text()))
				end
				return widget
			end
		},
		left = 10,
		right = 10,
		top = 10,
		bottom = 3,
		widget = wibox.container.margin
	}
end

calendar.hide = function()
	if calendar.notification then
		naughty.destroy(calendar.notification)
	end
end

calendar.inc = function(offset)
	calendar.offset = calendar.offset + offset
	calendar.show(0)
end

calendar.attach = function(widget)
	widget:connect_signal("mouse::enter", function() calendar.show() end)
	widget:connect_signal("mouse::leave", function() calendar.hide() end)

	widget:buttons(gears.table.join(
		awful.button({}, 1, function() calendar.inc(-1) end),
		awful.button({}, 3, function() calendar.inc(1) end),
		awful.button({}, 4, function() calendar.inc(-1) end),
		awful.button({}, 5, function() calendar.inc(1) end)
	))
end

return calendar
