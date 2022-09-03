local awful = require("awful")
local beautiful = require("beautiful")
local prefs = require("prefs")
local helpers = require("feign.helpers")

local visualizer = {}

-- terminal pretty much needs to be urxvt(c)
visualizer.spawn = function(s)
	if not s then
		s = awful.screen.focused()
	end
	awful.spawn("urxvtc \
		-font 'xft:Fira Mono:size=10'\
		-scollBar false\
		-sl 0\
		-depth 32\
		-bg rgba:0000/0000/0000/0000\
		--highlightColor rgba:0000/0000/0000/0000\
		-lineSpace 14\
		-letterSpace 0\
		-name vis\
		-e sh -c 'export XDG_CONFIG_HOME=" .. beautiful.dir .. " && \
		vis -c " .. beautiful.dir .. "/vis/config" .. s.index .. "'"
	)
end

visualizer.kill = function(s)
	if not s then
		s = awful.screen.focused()
	end

	local c = helpers.instance_exists(s.all_clients, "vis")
	if c then
		c:kill()
	end
end

visualizer.toggle = function(s)
	if not s then
		s = awful.screen.focused()
	end

	local c = helpers.instance_exists(s.all_clients, "vis")
	if c then
		c:kill()
	else
		visualizer.spawn(s)
	end
end

return visualizer
