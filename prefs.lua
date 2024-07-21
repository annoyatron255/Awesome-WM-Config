local awful = require("awful")

local prefs = {}

awful.layout.layouts = {
	awful.layout.suit.tile,
	awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom,
	awful.layout.suit.tile.top,
	awful.layout.suit.fair,
	awful.layout.suit.fair.horizontal,
}

prefs.tag_names = {
	utf8.char(0xf269), -- Firefox
	utf8.char(0xf120), -- Terminal
	utf8.char(0xf001), -- Music
	utf8.char(0xf0e0), -- Mail
	utf8.char(0xf15b), -- Documents
	utf8.char(0xf1b6), -- Steam
	utf8.char(0xf03d), -- Zoom
	"8", "9",
	"F1", "F2", "F3", "F4", "F5", "F6",
	"F7", "F8", "F9", "F10", "F11", "F12"
}

prefs.terminal = "alacritty msg create-window" -- Other terminals not tested or recommended and will probably not work
prefs.compositor = "picom --backend glx --force-win-blend --use-damage --window-shader-fg-rule "
	.. os.getenv("HOME") .. "/Code/picom-shaders/fake-transparency-fshader.glsl:'class_g = \"firefox\"' "
	.. "--window-shader-fg-rule "
	.. os.getenv("HOME") .. "/Code/picom-shaders/fake-full-transparency-fshader.glsl:'class_g = \"cava\"'"
prefs.editor = os.getenv("EDITOR") or "vim"
prefs.theme = "little_parade"

prefs.theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), prefs.theme)

prefs.temp_dir = os.getenv("XDG_RUNTIME_DIR")

prefs.mpd_password = ""
prefs.mpd_socket = prefs.temp_dir .. "/mpd/socket"
prefs.mpd_music_dir = os.getenv("HOME") .. "/Music"

return prefs
