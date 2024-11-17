--[[
	annoytron255's awesome config
	awesome v4.3
--]]

-- {{{ Include libraries
local beautiful = require("beautiful")
local prefs = require("prefs")

beautiful.init(prefs.theme_path)
beautiful.theme_assets.recolor_layout(beautiful, beautiful.accent_color)

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local naughty = require("naughty")
local keys = require("keys")
local helpers = require("feign.helpers")
lockscreen = require("feign.widget.lockscreen") -- Global for awesome-client

local hotkeys_popup = require("awful.hotkeys_popup").widget
local hotkeys_popup_keys = require("awful.hotkeys_popup.keys")
-- }}}

-- Add tmux help to popup
hotkeys_popup_keys.tmux.add_rules_for_terminal({ rule = { name = "tmux"}})

-- {{{ Hasten garbage collection
collectgarbage("setstepmul", 10000)
gears.timer {
	timeout = 60,
	autostart = true,
	callback = function()
		collectgarbage()
	end
}
-- }}}

-- {{{ Error handling
-- Startup errors
if awesome.startup_errors then
	naughty.notify({ preset = naughty.config.presets.critical,
	                 title = "Errors occured during startup!",
	                 text = awesome.startup_errors })
end

-- Runtime errors
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		if in_error then return end
		in_error = true

		if not string.find(tostring(err), "C stack overflow") then
			naughty.notify({ preset = naughty.config.presets.critical,
					 title = "Errors occured during runtime!",
					 text = tostring(err) })
		end
		in_error = false
	end)
end
-- }}}

-- {{{ Behavior tweaks
-- Make awesome use last tag's rather than first tag's layout
function awful.screen.object.get_selected_tag(s)
	local tags = awful.screen.object.get_selected_tags(s)
	local debug_source = debug.getinfo(3, "S").source
	if string.match(debug_source, "client") or
	   string.match(debug_source, "layout") then
		return tags[#tags]
	end
	return tags[1]
end
-- }}}

-- {{{ Autostart
helpers.run_once({
	{"systemctl --user start awesome-session.service"},
	{"alacritty --class Alacritty,Alacritty"},
	{"urxvtd"},
	{prefs.compositor},
	{"easystroke"},
	{"libinput-gestures"},
	{"xss-lock /home/jack/.config/awesome/scripts/start_locker.sh"},
	{"redshift"},
	{"unclutter"},
	{"nm-applet"},
	{"blueman-applet"},
	{"firefox"},
	{"thunderbird"},
	{"ncmpcpp"}
})
-- }}}

-- {{{ Rules
require("rules")
-- }}}

awful.ewmh.add_activate_filter(function(c)
	if c.class == "zoom" then return false end
end, "ewmh")

-- {{{ Signals
-- Re-set wallpaper on screen geometry changes such as resolution
screen.connect_signal("property::geometry", function(s) beautiful.set_wallpaper(s) end)

-- Wibox setup in theme files
awful.screen.connect_for_each_screen(function(s)
	beautiful.at_screen_connect(s)
end)

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	if not awesome.startup then awful.client.setslave(c) end

	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

--[[client.connect_signal("manage", function(c)
	local parent = awful.client.focus.history.get(c.screen, 1)
	if not parent then return end

	local term_id = "/tmp/terminal_ids/" .. parent.window

	awful.spawn.easy_async("cat " .. term_id, function(parent_window_pid)
		awful.spawn.easy_async_with_shell("pstree -Tpas " .. c.pid .. " | sed '3q;d' | grep -o '[0-9]*$' | tr -d '\n'", function(parent_process_pid)
			if parent_process_pid == parent_window_pid and parent.class == "URxvt" then
				c:connect_signal("unmanage", function(c)
					parent.minimized = false
				end)

				parent.minimized = true
				c.minimized = false
				--c:emit_signal("request::activate", "test1", {raise = true})
				c:swap(parent)

				c:connect_signal("swapped", function()
					local cls = gears.table.reverse(client.get(parent.screen))
					local past_c = true
					for _, v in ipairs(cls) do
						if past_c and v ~= c then
							parent:swap(v)
							naughty.notify({text = "test2"})
						elseif v == c then
							past_c = false
							naughty.notify({text = "test"})
						end
					end
				end)
			end
		end)
	end)
end)--]]

client.connect_signal("request::titlebars", function(c)
	awful.titlebar(c, {
		size = beautiful.floating_titlebar_size,
		position = "top"
	}):setup {
		buttons = keys.titlebar_buttons,
		layout = wibox.layout.flex.horizontal
	}
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("property::position", helpers.border_adjust)
client.connect_signal("focus", helpers.border_adjust)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}
