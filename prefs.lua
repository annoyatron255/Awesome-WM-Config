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
	"7", "8", "9",
	"F1", "F2", "F3", "F4", "F5", "F6",
	"F7", "F8", "F9", "F10", "F11", "F12"
}

prefs.terminal = "urxvtc" -- Other terminals not tested or recommended and will probably not work
prefs.compositor = [[picom --backend glx --force-win-blend --use-damage --glx-fshader-win '
	uniform float opacity;
	uniform bool invert_color;
	uniform sampler2D tex;
	void main() {
		vec4 c = texture2D(tex, gl_TexCoord[0].xy);
		if (!invert_color) { // Hack to allow picom exceptions
			// Change the vec4 to your desired key color
			vec4 vdiff = abs(vec4(0.0, 0.0039, 0.0, 1.0) - c); // #000100
			float diff = max(max(max(vdiff.r, vdiff.g), vdiff.b), vdiff.a);
			// Change the vec4 to your desired output color
			if (diff < 0.001)
				c = vec4(0.0, 0.0, 0.0, 0.890196); // #000000E3
		}
		c *= opacity;
		gl_FragColor = c;
	}'
]]
prefs.editor = os.getenv("EDITOR") or "vim"
prefs.theme = "little_parade"

prefs.theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), prefs.theme)

prefs.temp_dir = os.getenv("XDG_RUNTIME_DIR")

prefs.mpd_password = ""
prefs.mpd_socket = prefs.temp_dir .. "/mpd/socket"
prefs.mpd_music_dir = os.getenv("HOME") .. "/Music"

return prefs
