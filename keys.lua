local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local helpers = require("feign.helpers")
local prefs = require("prefs")
local feign = require("feign")

local keys = {}

local modkey = "Mod4"

-- {{{ Keyboard keys
-- Global keys
keys.global_keys = gears.table.join(
	awful.key({ modkey }, "p",
		function()
			local s_geo = mouse.screen.geometry
			awful.spawn("import -window root -crop " ..
				s_geo.width .. "x" .. s_geo.height ..
				"+" .. s_geo.x .. "+" .. s_geo.y ..
				" " .. os.getenv("HOME") .. "/Pictures/ScreenShots/" ..
				os.date("%Y-%m-%d@%H:%M:%S") .. ".png")
		end,
		{description = "screenshot current screen", group = "awesome"}
	),
	awful.key({ modkey, "Shift" }, "p",
		function()
			local s_geo = mouse.screen.geometry
			awful.spawn("import " .. os.getenv("HOME") ..
				"/Pictures/ScreenShots/" ..
				os.date("%Y-%m-%d@%H:%M:%S") .. ".png")
		end,
		{description = "screenshot selection", group = "awesome"}
	),
	awful.key({ modkey, "Control" }, "p",
		function()
			if record_pid then
				awful.spawn("kill -s SIGINT " .. record_pid)
				record_pid = nil
				beautiful.myrecordbox.text = ""
			else
				local s = mouse.screen
				record_pid = awful.spawn("ffmpeg -video_size " ..
					s.geometry.width .. "x" .. s.geometry.height ..
					" -framerate 60 -f x11grab -i :0.0+" ..
					s.geometry.x .. "," .. s.geometry.y ..
					" -f pulse -ac 2 -i default -c:v libx264 -crf 18 -preset ultrafast " ..
					os.getenv("HOME") .. "/Videos/ScreenRecord/" ..
					os.date("%Y-%m-%d@%H:%M:%S") .. ".mp4")
				beautiful.myrecordbox.markup = feign.markup.font(
					beautiful.mpd_font, " " .. utf8.char(0xf03d))
			end
		end,
		{description = "record current screen", group = "awesome"}
	),
	awful.key({ modkey }, "x",
		function()
			lockscreen.lockscreen()
		end,
		{description = "lock screen", group = "awesome"}
	),
	awful.key({ modkey }, "q",
		hotkeys_popup.show_help,
		{description = "show help", group = "awesome"}
	),
	awful.key({ modkey }, "l",
		function()
			awful.client.focus.byidx(1)
		end,
		{description = "focus next", group = "client"}
	),
	awful.key({ modkey }, "h",
		function()
			awful.client.focus.byidx(-1)
		end,
		{description = "focus previous", group = "client"}
	),
	awful.key({ modkey }, "a",
		function()
			--awful.util.mymainmenu:show()
			feign.widget.calendar.show()
		end,
		{description = "show main menu", group = "awesome"}
	),
	-- Layout manipulation
	awful.key({ modkey }, "j",
		function()
			awful.client.swap.byidx(1)
		end,
		{description = "swap with next", group = "client"}
	),
	awful.key({ modkey }, "k",
		function()
			awful.client.swap.byidx(-1)
		end,
		{description = "swap with previous", group = "client"}
	),
	awful.key({ modkey, "Control" }, "l",
		function()
			awful.screen.focus_relative(1)
		end,
		{description = "focus the next screen", group = "screen"}
	),
	awful.key({ modkey, "Control" }, "h",
		function()
			awful.screen.focus_relative(-1)
		end,
		{description = "focus the previous screen", group = "screen"}
	),
	awful.key({ modkey }, "u",
		awful.client.urgent.jumpto
		{description = "jump to urgent client", group = "client"}
	),
	awful.key({ modkey }, "Tab",
		function()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end,
		{description = "go back", group = "client"}
	),

	-- Show/Hide Wibox
	awful.key({ modkey }, "b",
		function()
			awful.screen.focused().mywibox.visible = not awful.screen.focused().mywibox.visible
		end,
		{description = "hide wibox", group = "awesome"}
	),

	-- Standard program
	awful.key({ modkey }, "Return",
		function()
			--[[
				Open in working directory of focused terminal,
				to work put this in your .bashrc/.zshrc/etc.:
				if [ -n "$WINDOWID" ]; then
					mkdir -p /tmp/urxvtc_ids/
					echo $$ > /tmp/urxvtc_ids/$WINDOWID
				fi
			--]]
			if client.focus then
				local term_id = "/tmp/urxvtc_ids/" .. client.focus.window
				awful.spawn.with_shell(prefs.terminal ..
					" -cd \"$([ -f " .. term_id .. " ] && \
					readlink -e /proc/$(cat " .. term_id .. ")/cwd || \
					echo $HOME)\""
				)
			else
				awful.spawn(prefs.terminal)
			end
		end,
		{description = "open a terminal", group = "launcher"}
	),
	awful.key({ modkey, "Control"}, "r",
		awesome.restart,
		{description = "reload awesome", group = "awesome"}
	),
	awful.key({ modkey, "Control"}, "q",
		awesome.quit,
		{description = "quit awesome", group = "awesome"}
	),

	awful.key({ modkey, "Control" }, "n",
		function()
			local c = awful.client.restore()
			-- Focus restored client
			if c then
				c:emit_signal("request::activate", "key.unminimize", {raise = true})
			end
		end,
		{description = "restore minimized", group = "client"}
	),

	-- Widget popups
	awful.key({ modkey, "Control" }, "c",
		function()
			feign.widget.calendar.show(5)
		end,
		{description = "calender popup", group = "launcher"}
	),
	awful.key({ modkey }, "w",
		function()
			feign.widget.weather.toggle()
		end,
		{description = "weather popup", group = "launcher"}
	),

	-- ALSA volume control
	awful.key({ modkey }, "=",
		function()
			feign.widget.volume.inc(1)
		end,
		{description = "increase ALSA volume", group = "media"}
	),
	awful.key({ modkey }, "-",
		function()
			feign.widget.volume.inc(-1)
		end,
		{description = "decrease ALSA volume", group = "media"}
	),
	awful.key({ modkey }, "0",
		function()
			feign.widget.volume.toggle_mute()
		end,
		{description = "toggle ALSA volume", group = "media"}
	),
	awful.key({ }, "XF86AudioRaiseVolume",
		function()
			feign.widget.volume.inc(1)
		end
	),
	awful.key({ }, "XF86AudioLowerVolume",
		function()
			feign.widget.volume.inc(-1)
		end
	),
	awful.key({ }, "XF86AudioMute",
		function()
			feign.widget.volume.toggle_mute()
		end
	),

	-- MPD Control
	awful.key({ modkey }, "]",
		function()
			feign.widget.mpd.toggle()
		end,
		{description = "play/pause mpd", group = "media"}
	),
	awful.key({ modkey }, "BackSpace",
		function()
			feign.widget.mpd.stop()
		end,
		{description = "stop mpd", group = "media"}
	),
	awful.key({ modkey }, "[",
		function()
			feign.widget.mpd.prev_track()
		end,
		{description = "previous track mpd", group = "media"}
	),
	awful.key({ modkey }, "\\",
		function()
			feign.widget.mpd.next_track()
		end,
		{description = "next track mpd", group = "media"}
	),
	awful.key({ modkey }, "'",
		function()
			feign.widget.mpd.repeat_cycle_notify()
		end,
		{description = "change repeat mpd", group = "media"}
	),
	awful.key({ modkey }, ";",
		function()
			feign.widget.mpd.random_toggle_notify()
		end,
		{description = "toggle shuffle mpd", group = "media"}
	),

	awful.key({ modkey }, "v",
		function()
			feign.widget.visualizer.toggle()
		end,
		{description = "toggle visualizer", group = "media"}
	),

	-- Brightness
	awful.key({ }, "XF86MonBrightnessUp",
		function()
			feign.widget.brightness.inc(5)
		end
	),

	awful.key({ }, "XF86MonBrightnessDown",
		function()
			feign.widget.brightness.inc(-5)
		end
	),

	-- Display key
	awful.key({ }, "XF86Display",
		function()
			awful.spawn.raise_or_spawn("lxrandr")
		end,
		{description = "spawn lxrandr", group = "launcher"}
	),

	awful.key({ }, "XF86Launch1",
		function()
			for c in awful.client.iterate(function (c) return awful.rules.match(c, {class = "WP-34s"}) end) do
				if c ~= client.focus then
					client.focus = c
					c:raise()
					return
				else
					c:kill()
					return
				end
			end

			awful.spawn("/home/jack/Junk/wp-34s/WP-34s")
		end,
		{description = "spawn calculator", group = "launcher"}
	),

	-- Prompt
	awful.key({ modkey }, "r",
		function()
			awful.prompt.run {
				prompt = "Run: ",
				hooks = {
					{{}, "Return", function(cmd)
						return helpers.parse_for_special_run_commands(cmd)
					end}
				},
				textbox = awful.screen.focused().mypromptbox.widget,
				history_path = gears.filesystem.get_dir("cache") .. "/history",
				completion_callback = awful.completion.shell,
				exe_callback = function(cmd)
					awful.spawn.with_shell("source $HOME/.zshrc && " .. cmd)
				end
			}
		end,
		{description = "run prompt", group = "launcher"}
	),

	awful.key({ modkey }, "`",
		function()
			local og_c = client.focus

			if og_c == nil then
				return
			end

			local matcher = function(c)
				return (c.window == og_c.window or
					awful.widget.tasklist.filter.minimizedcurrenttags(c, c.screen))
					and c:tags()[#c:tags()] == og_c:tags()[#og_c:tags()]
			end

			local n = 0
			for c in awful.client.iterate(matcher) do
				if n == 0 then
				elseif n == 1 then
					og_c.minimized = true
					c.minimized = false
					client.focus = c
					c:raise()
				else
					c.minimized = true
				end
				c:swap(og_c)
				n = n + 1
			end
		end,
		{description = "cycle stack", group = "tag"}
	),
	awful.key({ modkey, "Control" }, "`",
		function()
			local og_c = client.focus

			if og_c == nil then
				return
			end

			local matcher = function(c)
				return awful.widget.tasklist.filter.minimizedcurrenttags(c, c.screen)
					and c:tags()[#c:tags()] == og_c:tags()[#og_c:tags()]
			end

			local stack = {}
			for c in awful.client.iterate(matcher) do
				stack[#stack+1] = c
			end
			stack[#stack+1] = og_c

			local n = 0
			for _, c in ipairs(gears.table.reverse(stack))  do
				if n == 0 then
				elseif n == 1 then
					og_c.minimized = true
					c.minimized = false
					client.focus = c
					c:raise()
				else
					c.minimized = true
				end
				c:swap(og_c)
				n = n + 1
			end
		end,
		{description = "reverse cycle stack", group = "tag"}
	),
	awful.key({ modkey }, "space",
		function()
			local win_list = ""
			local choice_file = "/run/user/1000/window_choice"

			local searchable_windows = function(c)
				return not awful.rules.matches(c, {
					rule = { instance = "vis" }
				})
			end

			local client_table = {}
			for c in awful.client.iterate(searchable_windows) do
				client_table[#client_table+1] = c
				win_list = win_list .. #client_table .. " " .. c.name
				if c.class == "URxvt" then
					win_list = win_list .. " — " .. c.instance
				else
					win_list = win_list .. " — " .. c.class
				end
				win_list = win_list .. "\n"
			end
			win_list = win_list:sub(1, -2) -- Remove trailing newline

			local fzf_command = "echo '" .. win_list .. "' | fzf --with-nth=2.."

			-- Don't source zshrc and don't use urxvtc
			local popup_program = function(cmd)
				return "urxvt -name popup -geometry 160x20 -e zsh -c \"" .. cmd .. "\""
			end

			awful.spawn.easy_async(popup_program(fzf_command .. " > " .. choice_file), function()
				awful.spawn.easy_async("cat " .. choice_file, function(stdout, stderr, reason, exit_code)
					if exit_code == 0 then
						local index = tonumber(stdout:match("^([^ ]+)"))
						client_table[index]:jump_to(true)
					end
				end)
			end)
		end,
		{description = "fzf client selector", group = "client"}
	),
	awful.key({ modkey, "Control" }, "space",
		function()
			local og_c = client.focus

			local win_list = ""
			local choice_file = "/run/user/1000/window_choice"

			local current_stack = function(c)
				return awful.widget.tasklist.filter.minimizedcurrenttags(c, c.screen)
					and c:tags()[#c:tags()] == og_c:tags()[#og_c:tags()]
			end

			local client_table = {}
			for c in awful.client.iterate(current_stack) do
				client_table[#client_table+1] = c
				win_list = win_list .. #client_table .. " " .. c.name
				if c.class == "URxvt" then
					win_list = win_list .. " — " .. c.instance
				else
					win_list = win_list .. " — " .. c.class
				end
				win_list = win_list .. "\n"
			end
			win_list = win_list:sub(1, -2) -- Remove trailing newline

			local fzf_command = "echo '" .. win_list .. "' | fzf --with-nth=2.."

			-- Don't source zshrc and don't use urxvtc
			local popup_program = function(cmd)
				return "urxvt -name popup -geometry 160x20 -e zsh -c \"" .. cmd .. "\""
			end

			awful.spawn.easy_async(popup_program(fzf_command .. " > " .. choice_file), function()
				awful.spawn.easy_async("cat " .. choice_file, function(stdout, stderr, reason, exit_code)
					if exit_code == 0 then
						local c = client_table[tonumber(stdout:match("^([^ ]+)"))]
						og_c.minimized = true
						c.minimized = false
						c:swap(og_c)
						client.focus = c
						c:raise()
					end
				end)
			end)
		end,
		{description = "fzf stack selector", group = "client"}
	),


	-- Modes
	awful.key({ modkey }, "z",
		function()
			root.keys(gears.table.join(keys.global_keys, keys.mode_keys, keys.resize_keys))
			beautiful.mymodebox.markup = feign.markup.font(beautiful.font, "— RESIZE MODE —")
		end,
		{description = "resize mode", group = "modes"}
	)
)

-- Keys available in alternate modes
keys.mode_keys = gears.table.join(
	awful.key({ }, "Escape",
		function()
			root.keys(keys.global_keys)
			beautiful.mymodebox.text = ""
		end,
		{description = "normal mode", group = "modes"}
	)
)

-- Resize mode keys
keys.resize_keys = gears.table.join(
	awful.key({ }, "h",
		function()
			local tags = awful.screen.focused().selected_tags
			awful.tag.incmwfact(-0.05, tags[#tags])
		end,
		{description = "decrease master width factor", group = "resize mode"}
	),
	awful.key({ }, "l",
		function()
			local tags = awful.screen.focused().selected_tags
			awful.tag.incmwfact(0.05, tags[#tags])
		end,
		{description = "increase master width factor", group = "resize mode"}
	),
	awful.key({ }, "j",
		function()
			awful.client.incwfact(-0.05)
		end,
		{description = "decrease client width factor", group = "resize mode"}
	),
	awful.key({ }, "k",
		function()
			awful.client.incwfact(0.05)
		end,
		{description = "increase client width factor", group = "resize mode"}
	),
	awful.key({ "Control" }, "h",
		function()
			local tags = awful.screen.focused().selected_tags
			awful.tag.incncol(-1, tags[#tags])
		end,
		{description = "decrease number of columns", group = "resize mode"}
	),
	awful.key({ "Control" }, "l",
		function()
			local tags = awful.screen.focused().selected_tags
			awful.tag.incncol(1, tags[#tags])
		end,
		{description = "increase number of columns", group = "resize mode"}
	),
	awful.key({ "Control" }, "j",
		function()
			local tags = awful.screen.focused().selected_tags
			awful.tag.incnmaster(-1, tags[#tags])
		end,
		{description = "decrease number of masters", group = "resize mode"}
	),
	awful.key({ "Control" }, "k",
		function()
			local tags = awful.screen.focused().selected_tags
			awful.tag.incnmaster(1, tags[#tags])
		end,
		{description = "increase number of masters", group = "resize mode"}
	),
	awful.key({ }, "r",
		function()
			local tags = awful.screen.focused().selected_tags
			local t = tags[#tags]
			if t then
				t.master_width_factor = 0.5
				t.column_count = 1
				t.master_count = 1
			end
		end,
		{description = "reset size", group = "resize mode"}
	),
	-- Layout
	awful.key({ }, "space",
		function()
			awful.layout.inc(1)
			awful.screen.focused().mylayoutbox:set_visible(true)
		end,
		{description = "select next layout", group = "resize mode"}
	),
	awful.key({ "Control" }, "space",
		function()
			awful.layout.inc(-1)
			awful.screen.focused().mylayoutbox:set_visible(true)
		end,
		{description = "select previous layout", group = "resize mode"}
	)
)

keys.client_keys = gears.table.join(
	awful.key({ modkey }, "f",
		function(c)
			local opacity = c.fullscreen and 1 or 0
			c.screen.mywibox.visible = c.fullscreen
			c.fullscreen = not c.fullscreen
			c:raise()
			for _, client in ipairs(c.screen.clients) do
				if client ~= c and awful.client.focus.filter(client) then
					client.opacity = opacity
				end
			end
		end,
		{description = "toggle fullscreen", group = "client"}
	),
	awful.key({ modkey }, "c",
		function(c)
			c:kill()
		end,
		{description = "close", group = "client"}
	),
	awful.key({ modkey, "Control" }, "f",
		function(c)
			c.floating = not c.floating
		end,
		{description = "toggle floating", group = "client"}
	),
	awful.key({ modkey }, "s",
		function(c)
			c:move_to_screen()
		end,
		{description = "move to screen", group = "client"}
	),
	awful.key({ modkey, "Control" }, "j",
		function(c)
			c:move_to_screen(c.screen.index + 1)
		end,
		{description = "move to next screen", group = "client"}
	),
	awful.key({ modkey, "Control" }, "k",
		function(c)
			c:move_to_screen(c.screen.index - 1)
		end,
		{description = "move to previous screen", group = "client"}
	),
	awful.key({ modkey }, "t",
		function(c)
			c.ontop = not c.ontop
		end,
		{description = "toggle keep on top", group = "client"}
	),
	awful.key({ modkey }, "n",
		function(c)
			c.minimized = true
		end,
		{description = "minimize", group = "client"}
	),
	awful.key({ modkey }, "m",
		function(c)
			c.maximized = not c.maximized
			c:raise()
		end,
		{description = "maximize", group = "client"}
	)
)

local tag_keys = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9",
	{"F1",  "XF86AudioMute"},         {"F2",  "XF86AudioLowerVolume"},
	{"F3",  "XF86AudioRaiseVolume"},  {"F4",  "XF86AudioMicMute"},
	{"F5",  "XF86MonBrightnessDown"}, {"F6",  "XF86MonBrightnessUp"},
	{"F7",  "XF86Display"},           {"F8",  "XF86WLAN"},
	{"F9",  "XF86Tools"},             {"F10", "XF86Bluetooth"},
	{"F11", "XF86Launch1"},           {"F12", "XF86Favorites"}
}

-- Bind all key numbers to tags
for i, k in ipairs(tag_keys) do
	-- Hack to only show tags 1, 9, F1, and F12 in the shortcut window
	local descr_view, descr_toggle, descr_move, descr_toggle_focus
	if i == 1 or i == 9 or i == 10 or i == 21 then
		descr_view = {description = "view tag", group = "tag"}
		descr_toggle = {description = "toggle tag", group = "tag"}
		descr_move = {description = "move client to tag", group = "tag"}
		descr_toggle_focus = {description = "toggle client tag", group = "tag"}
	end

	local key_list = {}
	if type(k) == "table" then
		key_list = k
	else
		key_list[1] = k
	end

	for _, key in ipairs(key_list) do
		keys.global_keys = gears.table.join(keys.global_keys,
			-- View tag only
			awful.key({ modkey, "Shift" }, key,
				function()
					local screen = awful.screen.focused()
					local tag = screen.tags[i]
					if tag then
						tag:view_only()
					end
				end,
				descr_view
			),
			-- Toggle tag display
			awful.key({ modkey }, key,
				function()
					local screen = awful.screen.focused()
					local tag = screen.tags[i]
					if tag then
						awful.tag.viewtoggle(tag)
					end
				end,
				descr_toggle
			),
			-- Move client to tag
			awful.key({ modkey, "Control", "Shift" }, key,
				function()
					if client.focus then
						local tag = client.focus.screen.tags[i]
						if tag then
							client.focus:move_to_tag(tag)
						end
					end
				end,
				descr_move
			),
			-- Toggle tag on focused client
			awful.key({ modkey, "Control" }, key,
				function()
					if client.focus then
						local tag = client.focus.screen.tags[i]
						if tag then
							client.focus:toggle_tag(tag)
						end
					end
				end,
				descr_toggle_focus
			)
		)
		-- Only show first in list for help
		descr_view = nil
		descr_toggle = nil
		descr_move = nil
		descr_toggle_focus = nil
	end
end
-- }}} Keyboard keys

-- {{{ Mouse buttons
-- Client mouse buttons
keys.client_buttons = gears.table.join(
	awful.button({ }, 1,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
		end
	),
	awful.button({ modkey }, 1,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
			awful.mouse.client.move(c)
		end
	),
	awful.button({ modkey }, 2,
		function(c)
			c:kill()
		end
	),
	awful.button({ modkey }, 3,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
			awful.mouse.client.resize(c)
		end
	)
)

-- Taglist mouse buttons
keys.taglist_buttons = gears.table.join(
	awful.button({ }, 3, function(t) t:view_only() end),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({ }, 1, awful.tag.viewtoggle),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
	awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end)
)

-- Tasklist mouse buttons
keys.tasklist_buttons = gears.table.join(
	awful.button({ }, 1, function(c)
		if c.floating and c ~= client.focus or c.minimized then
			c.minimized = false
			c:emit_signal("request::activate", "tasklist", {raise = true})
		else
			c.minimized = true
		end
	end),
	awful.button({ }, 2, function(c)
		c:kill()
	end),
	awful.button({ }, 3, function(c)
		for _, client in ipairs(c.screen.clients) do
			if awful.client.focus.filter(client) then
				client.minimized = true
			end
		end
		c.minimized = false
		c:emit_signal("request::activate", "tasklist", {raise = true})

	end),
	awful.button({ }, 4, function()
		awful.client.focus.byidx(-1)
	end),
	awful.button({ }, 5, function()
		awful.client.focus.byidx(1)
	end)
)

-- Titlebar mouse buttons
keys.titlebar_buttons =  gears.table.join(
	awful.button({ }, 1, function()
		local c = mouse.object_under_pointer()
		c:emit_signal("request::activate", "titlebar", {raise = true})
		awful.mouse.client.move(c)
	end),
	awful.button({ }, 3, function()
		local c = mouse.object_under_pointer()
		c:emit_signal("request::activate", "titlebar", {raise = true})
		awful.mouse.client.resize(c)
	end)
)

-- Root window mouse buttons
keys.root_buttons = gears.table.join(
	awful.button({ }, 3, function() awful.util.mymainmenu:toggle() end),
	awful.button({ }, 5, awful.tag.viewnext),
	awful.button({ }, 4, awful.tag.viewprev)
)
-- }}} Mouse buttons

root.keys(keys.global_keys)
root.buttons(keys.root_buttons)

return keys
