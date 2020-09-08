local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local markup = require("feign.markup")

local battery = {}

battery.list = {}

battery.timeout = 60

battery.widget = wibox.widget.textbox()
battery.ac = false

awful.spawn.easy_async_with_shell("find /sys/class/power_supply/BAT?",
	function(stdout, stderr, reason, exit_code)
		if not (exit_code == 0) then
			return
		end

		for line in string.gmatch(stdout, "[^\n]+") do
			battery.list[#battery.list + 1] = line
		end

		cmd = "cat /sys/class/power_supply/AC/online "
		for _, bat in ipairs(battery.list) do
			cmd = cmd .. bat .. "/energy_now " .. bat .. "/energy_full "
		end

		awful.widget.watch(cmd, battery.timeout, function(_, stdout)
			local is_now = true
			local is_ac = true
			local now_total = 0
			local full_total = 0
			for line in string.gmatch(stdout, "[^\n]+") do
				if is_ac then
					battery.ac = (line == "1")
					is_ac = false
				elseif is_now then
					now_total = now_total + tonumber(line)
					is_now = false
				else
					full_total = full_total + tonumber(line)
					is_now = true
				end
			end

			battery.percent = math.floor(math.min(100, (now_total / full_total) * 100))

			if battery.ac then
				battery.widget:set_markup(markup(beautiful.normal_color,
					markup.font(beautiful.font, " " .. battery.percent .. "+")))
			else
				battery.widget:set_markup(markup(beautiful.normal_color,
					markup.font(beautiful.font, " " .. battery.percent .. "%")))
			end
		end)
	end
)

return battery
