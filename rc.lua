--[[
	annoytron255's awesome config
	awesome v4.2-489-g99fbe2ae
	27 October 2018
--]]

-- {{{ Include libraries
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local lain = require("lain")
local freedesktop = require("freedesktop")
--local menubar = require("menubar")

local hotkeys_popup = require("awful.hotkeys_popup").widget
local hotkeys_popup_keys = require("awful.hotkeys_popup.keys")
-- }}}

collectgarbage("setstepmul", 10000)

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

		naughty.notify({ preset = naughty.config.presets.critical,
		                 title = "Errors occured during runtime!",
		        	 text = tostring(err) })
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions
local modkey = "Mod4"

local terminal = "urxvtc" -- Other terminals not tested or recommended and will probably not work
local editor = os.getenv("EDITOR") or "vim"
local chosen_theme = "little_parade"

local terminal_programs = {"ncmpcpp", "vim", "htop", "top", "man"}

local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
beautiful.init(theme_path)
beautiful.theme_assets.recolor_layout(beautiful, beautiful.accent_color)

hotkeys_popup_keys.tmux.add_rules_for_terminal({ rule = { name = "tmux"}})

awful.layout.layouts = {
	awful.layout.suit.tile,
	awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom,
	awful.layout.suit.tile.top,
	awful.layout.suit.fair,
	awful.layout.suit.fair.horizontal,
}
-- }}}

-- {{{ Helper functions
local function client_instance_exists(clients, instance)
	for _, c in ipairs(clients) do
		if c.instance == instance then
			return c
		end
	end
	return false
end

function focusable(clients)
	local out_clients = {}
	for _, c in ipairs(clients) do
		if awful.client.focus.filter(c) then
			table.insert(out_clients, c)
		end
	end
	return out_clients
end

gears.timer {
	timeout = 60,
	autostart = true,
	callback = function()
		collectgarbage()
	end
}

-- Convert to string to terminal emulator syntax if in terminal_programs
-- Also sets the instance of program to the command name; may need changing if terminal ~= urxvt(c)
local function parse_for_terminal_programs(cmd)
	local program = cmd:match("^([^ ]+)")
	for _, p in ipairs(terminal_programs) do
		if program == p then
			return terminal .. " -name " .. program .. " -e " .. cmd
		end
	end
	return cmd
end

local previous_coords = {}
function mouse_media_callback(pointer_coords)
	if previous_coords.y - pointer_coords.y >= 5 then
		os.execute(string.format("amixer -q set %s 1%%+", beautiful.volume.channel))
		beautiful.volume.notify()
		mouse.coords {
			y = previous_coords.y
		}
	elseif pointer_coords.y - previous_coords.y >= 5 then
		os.execute(string.format("amixer -q set %s 1%%-", beautiful.volume.channel))
		beautiful.volume.notify()
		mouse.coords {
			y = previous_coords.y
		}
	end
	if previous_coords.x - pointer_coords.x >= 150 then
		beautiful.mpd_prev()
		mouse.coords {
			x = previous_coords.x
		}
	elseif pointer_coords.x - previous_coords.x >= 150 then
		beautiful.mpd_next()
		mouse.coords {
			x = previous_coords.x
		}
	end
	return true
end
-- }}}

-- {{{ Autostart
-- Accepts rules; however, the current release (4.2) applies rules in a weird order: rules won't work
local function run_once(cmd_arr)
	for _, cmd in ipairs(cmd_arr) do
		awful.spawn.easy_async_with_shell(string.format("pgrep -u $USER -x '%s' > /dev/null", cmd[1]),
			function(stdout, stderr, reason, exit_code)
				if exit_code ~= 0 then
					awful.spawn(parse_for_terminal_programs(cmd[1]), cmd[2])
				end
			end
		)
	end
end

run_once({
	{"xcompmgr"},
	{"light-locker"},
	{"urxvtd"},
	{"redshift"},
	{"unclutter"},
	--{"nm-applet"},
	--{"kdeconnect-indicator"},
	{"firefox"},
	{"ncmpcpp", {screen = 3}},
	{"thunderbird", {screen = 3}},
	--{"steam", {screen = 2}}
})

-- Manually apply rules to certain clients due aforemetioned awesome 4.2 issues
--[[for c in awful.client.iterate(function(c) return awful.rules.match(c, {class = "Thunderbird"}) end) do
	c.screen = 3
end--]]

-- }}}

-- {{{ Menu
local myawesomemenu = {
	{ "hotkeys", function() return false, hotkeys_popup.show_help end },
	{ "manual", terminal .. " -e man awesome" },
	{ "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
	{ "restart", awesome.restart },
	{ "quit", function() awesome.quit() end }
}

--[[awful.util.mymainmenu = awful.menu({
	items = {
		{ "awesome", myawesomemenu, beautiful.awesome_icon },
		{ "open terminal", terminal }
	}
})--]]
awful.util.mymainmenu = freedesktop.menu.build({
	icon_size = beautiful.menu_height or 16,
	before = {
		{ "Awesome", myawesomemenu, beautiful.awesome_icon }
	},
	after = {
		{ "Open terminal", terminal }
	}
})
-- }}}

awful.util.taglist_buttons = gears.table.join(
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
	awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
	awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = gears.table.join(
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
		awful.client.focus.byidx(1)
	end),
	awful.button({ }, 5, function()
		awful.client.focus.byidx(-1)
	end)
)


-- {{{ Screen
-- Re-set wallpaper on screen geometry changes such as resolution
screen.connect_signal("property::geometry", function(s) beautiful.set_wallpaper(s) end)

-- Wibox setup in theme files
awful.screen.connect_for_each_screen(function(s)
	beautiful.at_screen_connect(s)
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
	awful.button({ }, 3, function() awful.util.mymainmenu:toggle() end),
	awful.button({ }, 4, awful.tag.viewnext),
	awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
	awful.key({ modkey }, "p",
		function()
			awful.spawn.with_shell("import -window root $HOME/Pictures/ScreenShots/$(date +%Y%m%d%H%M%S).png")
		end,
		{description = "take screenshot", group = "awesome"}
	),
	awful.key({ modkey }, "x",
		function()
			awful.spawn("light-locker-command -l")
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
			awful.util.mymainmenu:show()
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
			mkdir -p /tmp/urxvtc_ids/
			echo $$ > /tmp/urxvtc_ids/$WINDOWID
			--]]
			if client.focus then
				local term_id = "/tmp/urxvtc_ids/" .. client.focus.window
				awful.spawn.with_shell(terminal ..
					" -cd $([ -f " .. term_id .. " ] && \
					readlink -e /proc/$(cat " .. term_id .. ")/cwd || \
					echo $HOME)"
				)
			else
				awful.spawn(terminal)
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

	-- Layout
	awful.key({ modkey }, "space",
		function()
			awful.layout.inc(1)
			awful.screen.focused().mylayoutbox:set_visible(true)
		end,
		{description = "select next layout", group = "layout"}
	),
	awful.key({ modkey, "Control" }, "space",
		function()
			awful.layout.inc(-1)
			awful.screen.focused().mylayoutbox:set_visible(true)
		end,
		{description = "select previous layout", group = "layout"}
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
			beautiful.cal.show(7)
		end,
		{description = "calender popup", group = "launcher"}
	),
	awful.key({ modkey }, "w",
		function()
			if beautiful.weather then
				beautiful.weather.show(7)
			end
		end,
		{description = "weather popup", group = "launcher"}
	),

	-- ALSA volume control
	awful.key({ modkey }, "=",
		function()
			os.execute(string.format("amixer -q set %s 1%%+", beautiful.volume.channel))
			beautiful.volume.notify()
		end,
		{description = "increase ALSA volume", group = "media"}
	),
	awful.key({ modkey }, "-",
		function()
			os.execute(string.format("amixer -q set %s 1%%-", beautiful.volume.channel))
			beautiful.volume.notify()
		end,
		{description = "decrease ALSA volume", group = "media"}
	),
	awful.key({ modkey }, "0",
		function()
			os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
			beautiful.volume.notify()
		end,
		{description = "toggle ALSA volume", group = "media"}
	),

	-- MPD Control
	awful.key({ modkey }, "]",
		function()
			beautiful.mpd_toggle()
		end,
		{description = "play/pause mpd", group = "media"}
	),
	awful.key({ modkey }, "BackSpace",
		function()
			beautiful.mpd_stop()
		end,
		{description = "stop mpd", group = "media"}
	),
	awful.key({ modkey }, "[",
		function()
			beautiful.mpd_prev()
		end,
		{description = "previous track mpd", group = "media"}
	),
	awful.key({ modkey }, "\\",
		function()
			beautiful.mpd_next()
		end,
		{description = "next track mpd", group = "media"}
	),
	awful.key({ modkey }, "'",
		function()
			beautiful.mpd_repeat_cycle()
		end,
		{description = "change repeat mpd", group = "media"}
	),
	awful.key({ modkey }, ";",
		function()
			beautiful.mpd_random_toggle()
		end,
		{description = "toggle shuffle mpd", group = "media"}
	),

	awful.key({ modkey }, "v",
		function()
			local s = awful.screen.focused()
			local c = client_instance_exists(s.all_clients, "vis")
			if c then
				c:kill()	
			else -- Terminal basically has to be urxvt here
				beautiful.spawn_visualizer(s, terminal)
			end
		end,
		{description = "toggle visualizer", group = "media"}
	),

	awful.key({ modkey }, "g",
		function()
			if not mousegrabber.isrunning() then
				previous_coords.x = mouse.coords().x
				previous_coords.y = mouse.coords().y
				mousegrabber.run(mouse_media_callback, "cross")
			end
		end,
		function()
			mousegrabber.stop()
		end,
		{description = "mouse media gestures", group = "media"}
	),

	-- Prompt
	awful.key({ modkey }, "r",
		function()
			--awful.screen.focused().mypromptbox:run()
			awful.prompt.run {
				prompt = "Run: ",
				hooks = {
					{{}, "Return", function(cmd)
						return parse_for_terminal_programs(cmd)
					end}
				},
				textbox = awful.screen.focused().mypromptbox.widget,
				history_path = gears.filesystem.get_dir("cache") .. "/history",
				completion_callback = awful.completion.shell,
				exe_callback = function(cmd)
					awful.spawn.with_shell(cmd)
				end
			}
		end,
		{description = "run prompt", group = "launcher"}
	),

	-- Modes
	awful.key({ modkey }, "z",
		function()
			root.keys(gears.table.join(globalkeys, modekeys, resizekeys))
			beautiful.mymodebox.markup = lain.util.markup.font(beautiful.font, "-- RESIZE MODE --")
		end,
		{description = "resize mode", group = "modes"}
	)
)

modekeys = gears.table.join(
	awful.key({ }, "Escape",
		function()
			root.keys(globalkeys)
			beautiful.mymodebox.text = ""
		end,
		{description = "normal mode", group = "modes"}
	)
)

resizekeys = gears.table.join(
	awful.key({ }, "h",
		function()
			awful.tag.incmwfact(-0.05)
		end,
		{description = "decrease master width factor", group = "resize mode"}
	),
	awful.key({ }, "l",
		function()
			awful.tag.incmwfact(0.05)
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
			awful.tag.incncol(-1)
		end,
		{description = "decrease number of columns", group = "resize mode"}
	),
	awful.key({ "Control" }, "l",
		function()
			awful.tag.incncol(1)
		end,
		{description = "increase number of columns", group = "resize mode"}
	),
	awful.key({ "Control" }, "j",
		function()
			awful.tag.incnmaster(-1)
		end,
		{description = "decrease number of masters", group = "resize mode"}
	),
	awful.key({ "Control" }, "k",
		function()
			awful.tag.incnmaster(1)
		end,
		{description = "increase number of masters", group = "resize mode"}
	),
	awful.key({ }, "r",
		function()
			local t = awful.tag.selected()
			if t then
				t.master_width_factor = 0.5
				t.column_count = 1
				t.master_count = 1
			end
		end,
		{description = "reset size", group = "resize mode"}
	)
)

clientkeys = gears.table.join(
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
			----awful.rules.apply(c)
		end,
		{description = "move to screen", group = "client"}
	),
	awful.key({ modkey, "Control" }, "j",
		function(c)
			c:move_to_screen(c.screen.index + 1)
			----awful.rules.apply(c)
		end,
		{description = "move to next screen", group = "client"}
	),
	awful.key({ modkey, "Control" }, "k",
		function(c)
			c:move_to_screen(c.screen.index - 1)
			----awful.rules.apply(c)
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

-- Bind all key numbers to tags
-- Be careful: we use keycodes to make it works on any keyboard layout
-- This should map on the top row of your keyboard, usually 1 to 9
for i = 1, 9 do
	-- Hack to only show tags 1 and 9 in the shortcut window
	local descr_view, descr_toggle, descr_move, descr_toggle_focus
	if i == 1 or i == 9 then
		descr_view = {description = "view tag #", group = "tag"}
		descr_toggle = {description = "toggle tag #", group = "tag"}
		descr_move = {description = "move client to tag #", group = "tag"}
		descr_toggle_focus = {description = "toggle client tag #", group = "tag"}
	end
	globalkeys = gears.table.join(globalkeys,
		-- View tag only
		awful.key({ modkey, "Shift" }, "#" .. i + 9,
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
		awful.key({ modkey }, "#" .. i + 9,
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
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
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
		awful.key({ modkey, "Control" }, "#" .. i + 9,
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
end

----awful.mouse.resize.add_leave_callback(awful.rules.apply, "mouse.move")

clientbuttons = gears.table.join(
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
	awful.button({ modkey }, 3,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
			awful.mouse.client.resize(c)
		end
	)
)

-- Set keys
root.keys(globalkeys)
-- }}} Key bindings

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = { },
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap+awful.placement.no_offscreen,
			size_hints_honor = false
		}
	},

	-- Titlebars
	{
		rule_any = { type = { "dialog" } },
		properties = { titlebars_enabled = true }
	},
	-- Special rules
	{
		rule = { class = "Firefox" },
		properties = { tag = beautiful.tagnames[1], floating = false }
	},
	{
		rule = { class = "URxvt" },
		except_any = { instance = { "vis", "ncmpcpp" } },
		properties = { tag = beautiful.tagnames[2] }
	},
	{
		rule = { class = "URxvt", instance = "ncmpcpp" },
		properties = { tag = beautiful.tagnames[3] }
	},
	{
		rule = { class = "URxvt", instance = "vis" },
		properties = {
			maximized = true,
			focusable = false,
			below = true,
			sticky = true,
			skip_taskbar = true
		}
	},
	{
		rule = { class = "XTerm" },
		properties = { tag = beautiful.tagnames[2] }
	},
	{
		rule = { class = "vlc" },
		properties = { tag = beautiful.tagnames[3] }
	},
	{
		rule = { class = "Thunderbird" },
		properties = { tag = beautiful.tagnames[4] }
	},
	{
		rule = { class = "Steam" },
		properties = { tag = beautiful.tagnames[5] }
	}
}
-- }}}

-- {{{ Helper functions
local titlebar_position = "top"

local function border_adjust(c)
	if c.floating then
		return
	end
	awful.titlebar.hide(c, "top")
	awful.titlebar.hide(c, "bottom")
	awful.titlebar.hide(c, "left")
	awful.titlebar.hide(c, "right")

	local s = awful.screen.focused()

	local titlebar_size = beautiful.titlebar_size

	if c.x - s.workarea["x"] - beautiful.titlebar_size <= 0 then
		titlebar_position = "left"
	elseif c.x - s.workarea["x"] + c.width - s.workarea["width"] + beautiful.titlebar_size + 10 >= 0 then
		titlebar_position = "right"
	else
		titlebar_position = "top"
	end

	if #focusable(awful.screen.focused().clients) > 1 and not c.maximized then
		awful.titlebar(c, {
			size = titlebar_size,
			position = titlebar_position
		})
	end
end
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	-- if not awesome.startup then awful.client.setslave(c) end
	
	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

client.connect_signal("request::titlebars", function(c)
	local buttons = gears.table.join(
		awful.button({ }, 1, function()
			c:emit_signal("request::activate", "titlebar", {raise = true})
			awful.mouse.client.move(c)
		end),
		awful.button({ }, 3, function()
			c:emit_signal("request::activate", "titlebar", {raise = true})
			awful.mouse.client.resize(c)
		end)
	)

	awful.titlebar(c, {
		size = beautiful.floating_titlebar_size,
		position = "top"
	}):setup {
		buttons = buttons,
		layout = wibox.layout.flex.horizontal
	}
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

--client.connect_signal("property::position", border_adjust)
--client.connect_signal("property::shape_bounding", border_adjust)
client.connect_signal("focus", border_adjust)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}
