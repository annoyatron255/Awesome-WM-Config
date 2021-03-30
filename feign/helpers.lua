local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local prefs = require("prefs")

local helpers = {}

helpers.instance_exists = function(clients, instance)
	for _, c in ipairs(clients) do
		if c.instance == instance then
			return c
		end
	end
	return false
end

helpers.focusable = function(clients)
	local out_clients = {}
	for _, c in ipairs(clients) do
		if awful.client.focus.filter(c) then
			table.insert(out_clients, c)
		end
	end
	return out_clients
end

helpers.no_picom_when_focused = function(c)
	c:connect_signal("focus", function(c)
		awful.spawn("killall picom")
	end)

	c:connect_signal("unfocus", function(c)
		awful.spawn(prefs.compositor)
	end)
end

helpers.terminal_size_adjust = function(c)
	awesome.sync()
	if c.screen.index == 1 then
		awful.spawn("xdotool key --window "
		            .. tostring(c.window) .. " Ctrl+0")
	else
		awful.spawn("xdotool key --window "
		            .. tostring(c.window) .. " Ctrl+minus")
	end
end

-- {{{ Borders
helpers.get_border_position = function(c)
	local s = awful.screen.focused()

	local titlebar_size = beautiful.titlebar_size

	local titlebar_position = "top"

	if c.x - s.workarea["x"] - beautiful.titlebar_size <= 0 then
		titlebar_position = "left"
	elseif c.x - s.workarea["x"] + c.width - s.workarea["width"] + beautiful.titlebar_size + 10 >= 0 then
		titlebar_position = "right"
	end

	return titlebar_position
end

helpers.border_adjust = function(c)
	if c.floating then
		return
	end

	local border_position = helpers.get_border_position(c)

	pcall(function()
		local top_titlebar_margin = c._private.titlebars["top"].drawable:get_children_by_id("active_margin")[1]
		top_titlebar_margin:set_left(0)
		top_titlebar_margin:set_right(0)

		if #helpers.focusable(awful.screen.focused().clients) > 1 and not c.maximized then
			if border_position == "left" then
				top_titlebar_margin:set_left(beautiful.titlebar_size)
			elseif border_position == "right" then
				top_titlebar_margin:set_right(beautiful.titlebar_size)
			end
		end
	end)

	awful.titlebar.hide(c, "bottom")
	awful.titlebar.hide(c, "left")
	awful.titlebar.hide(c, "right")

	if #helpers.focusable(awful.screen.focused().clients) > 1 and not c.maximized then
		awful.titlebar(c, {
			size = beautiful.titlebar_size,
			position = border_position
		})
	end
end
-- }}} Borders

-- {{{ Special program run
-- Convert to string to terminal emulator syntax if in terminal_programs
-- Also sets the instance of program to the command name; may need changing if terminal ~= urxvt(c)
helpers.terminal_program = function(cmd)
	local program = cmd:match("^([^ ]+)")
	return prefs.terminal .. " -name " .. program .. " -e " .. cmd
end

helpers.popup_program = function(cmd)
	return prefs.terminal .. " -name popup -geometry 160x20 -e zsh -c \"source $HOME/.zshrc && " .. cmd .. "\""
end

helpers.popup_when_no_args = function(cmd)
	if cmd:match(" ") then
		return cmd
	else
		return helpers.popup_program(cmd)
	end
end

helpers.special_run_commands = {
	{"ncmpcpp", helpers.terminal_program},
	{"vim",     helpers.terminal_program},
	{"htop",    helpers.terminal_program},
	{"top",     helpers.terminal_program},
	{"man",     helpers.terminal_program},
	{"bash",    helpers.terminal_program},
	{"sh",      helpers.terminal_program},
	{"zsh",     helpers.terminal_program},
	{"m",       helpers.popup_when_no_args},
	{"o",       helpers.popup_when_no_args},
	{"t",       helpers.popup_program},
	{"tx",      helpers.popup_program},
	{"shader",  helpers.popup_when_no_args}
}

helpers.parse_for_special_run_commands = function(in_cmd)
	local command = in_cmd:match("^([^ ]+)")
	for _, cmd in ipairs(helpers.special_run_commands) do
		if command == cmd[1] then
			return cmd[2](in_cmd)
		end
	end
	return in_cmd
end

-- Accepts rules
-- input: table of tables with command string and rule table
helpers.run_once = function(cmd_arr)
	for _, cmd in ipairs(cmd_arr) do
		awful.spawn.easy_async_with_shell(string.format("pgrep -f -u $USER '%s' > /dev/null", cmd[1]),
			function(stdout, stderr, reason, exit_code)
				if exit_code ~= 0 then
					awful.spawn(helpers.parse_for_special_run_commands(cmd[1]), cmd[2])
				end
			end
		)
	end
end
-- }}}

-- {{{ Stacks
helpers.cycle_stack = function()
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
			c:emit_signal("request::activate", "key.stack", {raise = true})
		else
			c.minimized = true
		end
		c:swap(og_c)
		n = n + 1
	end
end

helpers.reverse_cycle_stack = function()
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
			c:emit_signal("request::activate", "key.stack", {raise = true})
		else
			c.minimized = true
		end
		c:swap(og_c)
		n = n + 1
	end
end
-- }}}

return helpers
