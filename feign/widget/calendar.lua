local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local markup = require("feign.markup")
local prefs = require("prefs")

local calendar = {}

calendar.events = {}

calendar.get_events = function()
	awful.spawn.easy_async("curl " .. prefs.cal_url, function(stdout)
		local curr_date = os.date("*t")

		local index  = 1
		for day in string.gmatch(stdout, "RRULE:FREQ=WEEKLY;BYDAY=(%u%u)[^\n]+") do
			calendar.events[index] = {}
			calendar.events[index].start_date = {}
			calendar.events[index].end_date = {}

			local wday_conv = {SU = 1, MO = 2, TU = 3, WE = 4, TH = 5, FR = 6, SA = 7}

			calendar.events[index].start_date.wday = wday_conv[day]
			calendar.events[index].end_date.wday = wday_conv[day]
			--[[if day == "SU" then
				calendar.events[index].start_date.wday = 1
				calendar.events[index].end_date.wday = 1
			elseif day == "MO" then
				calendar.events[index].start_date.wday = 2
				calendar.events[index].end_date.wday = 2
			elseif day == "TU" then
				calendar.events[index].start_date.wday = 3
				calendar.events[index].end_date.wday = 3
			elseif day == "WE" then
				calendar.events[index].start_date.wday = 4
				calendar.events[index].end_date.wday = 4
			elseif day == "TH" then
				calendar.events[index].start_date.wday = 5
				calendar.events[index].end_date.wday = 5
			elseif day == "FR" then
				calendar.events[index].start_date.wday = 6
				calendar.events[index].end_date.wday = 6
			elseif day == "SA" then
				calendar.events[index].start_date.wday = 7
				calendar.events[index].end_date.wday = 7
			end--]]
			index = index + 1
		end

		index  = 1
		for hour, min in string.gmatch(stdout, "DTSTART;TZID=America/Chicago:[%d]+T(%d%d)(%d%d)[^\n]+") do
			calendar.events[index].start_date.hour = tonumber(hour)
			calendar.events[index].start_date.min = tonumber(min)
			index = index + 1
		end

		index  = 1
		for hour, min in string.gmatch(stdout, "DTEND;TZID=America/Chicago:[%d]+T(%d%d)(%d%d)[^\n]+") do
			calendar.events[index].end_date.hour = tonumber(hour)
			calendar.events[index].end_date.min = tonumber(min)
			index = index + 1
		end

		index  = 1
		for summary in string.gmatch(stdout, "SUMMARY:([^\n]+)") do
			calendar.events[index].summary = summary
			index = index + 1
		end

		table.sort(calendar.events, function(k1, k2)
			if k1.start_date.hour < k2.start_date.hour then
				return true
			elseif (k1.start_date.hour == k2.start_date.hour) and (k1.start_date.min < k2.start_date.min) then
				return true
			else
				return false
			end
		end)
	end)
end
calendar.get_events()

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
			height = 290,
			timeout = timeout,
			destroy = function()
				calendar.notification = nil
				calendar.offset = 0
			end
		}
	end

	local event_summary = "No Pending Events"
	local event_time = ""
	local curr_date = os.date("*t")
	for _, event in ipairs(calendar.events) do
		if event.start_date.wday == curr_date.wday and
		   (curr_date.hour * 60 + curr_date.min) < (event.end_date.hour * 60 + event.end_date.min) then
			event_summary = event.summary
			event_time = event.start_date.hour .. ":" .. event.start_date.min
			   .. "–" .. event.end_date.hour .. ":" .. event.end_date.min
			break
		end
	end

	calendar.notification.box:setup {
		{
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
			{
				{
					text = event_summary,
					widget = wibox.widget.textbox
				},
				nil,
				{
					text = event_time,
					widget = wibox.widget.textbox
				},
				layout = wibox.layout.align.horizontal
			},
			layout = wibox.layout.fixed.vertical
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
