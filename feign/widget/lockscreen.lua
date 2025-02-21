local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local gears = require("gears")
local glib = require("lgi").GLib
local pam = require("liblua_pam")
local beautiful = require("beautiful")
local feign = require("feign")
local prefs = require("prefs")

local lockscreen = {}

local function setup_lockscreen(s)
	local lockscreen_box = wibox({
		visible = false,
		ontop = true,
		screen = s
	})
	awful.placement.maximize(lockscreen_box)
	lockscreen_box.bg = "#000000"

	local wallpaper = beautiful.wallpaper
	if math.abs(s.geometry.width/s.geometry.height - 16/10) < 0.01 then
		wallpaper = beautiful.wallpaper_16x10
	end

	s.lockscreen_box = lockscreen_box
	s.lockscreen_box:setup {
		{
			image = wallpaper,
			resize = true,
			widget = wibox.widget.imagebox
		},
		{
			{
				widget = wibox.widget.textbox
			},
			{
				{
					font = "Fira Sans " .. tostring(110 * s.geometry.height / 1440),
					align = "center",
					valign = "bottom",
					widget = wibox.widget.textclock("%H:%M")
				},
				{
					font = "Fira Sans " .. tostring(24 * s.geometry.height / 1440),
					align = "center",
					valign = "top",
					widget = wibox.widget.textclock("%A, %B %-d, %Y")
				},
				layout = wibox.layout.flex.vertical
			},
			id = "clock",
			layout = wibox.layout.ratio.horizontal
		},
		{
			{
				widget = wibox.widget.textbox -- Dummy
			},
			margins = 0,
			color = beautiful.accent_color,
			id = "margin_border",
			layout = wibox.container.margin
		},
		layout = wibox.layout.stack
	}

	if math.abs(s.geometry.width/s.geometry.height - 16/10) < 0.01 then
		s.lockscreen_box:get_children_by_id("clock")[1]:set_ratio(2, 0.325)
	else
		s.lockscreen_box:get_children_by_id("clock")[1]:set_ratio(2, 0.425)
	end
end

awful.screen.connect_for_each_screen(setup_lockscreen)
screen.connect_signal("property::geometry", setup_lockscreen)

local function check_password(password)
	return pam.auth_current_user(password)
end

local function show_lockscreen()
	for s in screen do
		s.lockscreen_box:get_children_by_id("margin_border")[1].margins = 0
		s.lockscreen_box.visible = true
	end
end

local function hide_lockscreen()
	for s in screen do
		s.lockscreen_box.visible = false
	end
end

local function update_border(seq_len)
	local stage = (seq_len % 5)
	local thickness = prefs.dpi(5)

	for s in screen do
		local margin = s.lockscreen_box:get_children_by_id("margin_border")[1]
		if stage == 0 then
			margin.left = 0
			margin.right = 0
			margin.top= 0
			margin.bottom = 0
		elseif stage == 1 then
			margin.left = 0
			margin.right = 0
			margin.top= 0
			margin.bottom = thickness
		elseif stage == 2 then
			margin.left = thickness
			margin.right = 0
			margin.top= 0
			margin.bottom = thickness
		elseif stage == 3 then
			margin.left = thickness
			margin.right = 0
			margin.top= thickness
			margin.bottom = thickness
		elseif stage == 4 then
			margin.left = thickness
			margin.right = thickness
			margin.top= thickness
			margin.bottom = thickness
		end
	end
end

local function get_creds()
	if not mousegrabber.isrunning() then
		mousegrabber.run(function() return true end, "arrow")
	end

	local lockscreen_enabled = true
	local keygrabber

	local function password_loop()
		local buffer = ""
		keygrabber = awful.keygrabber {
			autostart = true,
			keybindings = {
				{{ }, "XF86AudioRaiseVolume", function()
					feign.widget.volume.inc(1)
				end},
				{{ }, "XF86AudioLowerVolume", function()
					feign.widget.volume.inc(-1)
				end},
				{{ }, "XF86AudioMute", function()
					feign.widget.volume.toggle_mute()
				end},
				{{ }, "XF86AudioMicMute", function()
					feign.widget.volume.toggle_mic_mute()
				end},
				{{ }, "XF86MonBrightnessUp", function()
					feign.widget.brightness.inc(5)
				end},
				{{ }, "XF86MonBrightnessDown", function()
					feign.widget.brightness.inc(-5)
				end}
			},
			keypressed_callback = function(_, _, key, event)
				local seq_len = glib.utf8_strlen(buffer, -1)

				if key == "BackSpace" and seq_len > 0 then
					buffer = glib.utf8_substring(buffer, 0, seq_len - 1)
					seq_len = seq_len - 1
				elseif key == "Escape" then
					buffer = ""
					seq_len = 0
				elseif glib.utf8_strlen(key, -1) == 1 then
					buffer = buffer .. key
					seq_len = seq_len + 1
				end

				update_border(seq_len)
			end,
			stop_key = "Return",
			stop_callback = function()
				if lockscreen_enabled == false then
					return
				elseif check_password(buffer) then
					lockscreen_enabled = false
					mousegrabber.stop()
					awful.spawn("pkill fprintd-verify")
					hide_lockscreen()
				else
					fingerprint_loop()
					password_loop()
				end
			end
		}
	end
	password_loop()

	function fingerprint_loop()
		--[[awful.spawn.easy_async("fprintd-verify", function(stdout, stderr, reason, exit_code)
			if exit_code == 0 or exit_code == 1 then
				if stdout:match("verify%-match") then
					lockscreen_enabled = false
					keygrabber:stop()
					mousegrabber.stop()
					hide_lockscreen()
					awful.spawn("killall fprintd-verify")
				elseif lockscreen_enabled == true then
					fingerprint_loop()
				end
			end
		end)]]
	end
	fingerprint_loop()
end

lockscreen.lockscreen = function()
	show_lockscreen()
	get_creds()
end

return lockscreen
