-- Table of constants that is used across all game stages.
-- The string values are put here to make it easy to keep track of where they are used.

local constants = {}

constants.mod_name = "windowed-cameras"
constants.style_prefix = string.gsub(constants.mod_name, "-", "_").."_"

constants.shortcut_toggle_display_name = constants.mod_name.."-toggle-display"
constants.input_toggle_display = constants.mod_name.."-toggle-display"
constants.input_zoom_in = "zoom-in"
constants.input_zoom_out = "zoom-out"

constants.sprite_edit_camera = constants.mod_name.."-edit-camera"
constants.sprite_menu_button = constants.mod_name.."-menu-button"

constants.camera_window_name_prefix = constants.mod_name.."-camera-window-main-"
constants.camera_window_menu_name_prefix = constants.mod_name.."-camera-window-menu-"

constants.gui_tag_event_enabled = constants.mod_name.."-event-enabled"

constants.camera_window_size_minimum = 100

return constants