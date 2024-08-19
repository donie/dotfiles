-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
	{ family = "Berkeley Mono", weight = "Medium" },
	{ family = "FiraCode Nerd Font Mono", weight = "Regular" },
})
config.font_size = 14.5
config.initial_cols = 162
config.initial_rows = 66
-- config.color_scheme = "Monokai (terminal.sexy)"
-- config.color_scheme = "Gruvbox Dark (Gogh)"
-- config.color_scheme = "Tokyo Night (Gogh)"
config.color_scheme = "Vs Code Dark+ (Gogh)"
config.enable_tab_bar = false
config.window_background_opacity = 0.975

-- and finally, return the configuration to wezterm
return config
