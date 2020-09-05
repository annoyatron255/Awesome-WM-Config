local awful = require("awful")

local weather = {}

weather.location = "Minneapolis"
weather.units = "u" -- u for USA and m for metric

weather.pid = ""
weather.toggle = function()
	awful.spawn.easy_async("kill " .. weather.pid, function(stdout, stderr, reason, exit_code)
		weather.pid = ""
		if exit_code ~= 0 then
			weather.pid = awful.spawn("urxvt -sl 0 -name popup -geometry 125x38 "
				.. "-e zsh -c \"curl wttr.in/" .. weather.location .. "\\?"
				.. weather.units .. " 2> /dev/null | head -n -2 && read \"")
		end
	end)
end

return weather
