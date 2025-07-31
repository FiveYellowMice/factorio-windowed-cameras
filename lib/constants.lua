-- Table of constants that is used across all game stages.
-- The string values are put here to make it easy to keep track of where they are used.

local constants = {}

constants.mod_name = "windowed-cameras"
constants.gui_name_prefix = constants.mod_name.."-"
constants.style_prefix = string.gsub(constants.mod_name, "-", "_").."_"

constants.shortcut_toggle_display_name = constants.mod_name.."-toggle-display"
constants.input_toggle_display = constants.mod_name.."-toggle-display"
constants.input_zoom_in = "zoom-in"
constants.input_zoom_out = "zoom-out"

constants.sprite_edit_camera = constants.mod_name.."-edit-camera"
constants.sprite_menu_button = constants.mod_name.."-menu-button"

constants.camera_window_name_prefix = constants.gui_name_prefix.."camera-window-main-"
constants.clone_button_name = constants.gui_name_prefix.."clone-button"
constants.camera_edit_button_name = constants.gui_name_prefix.."edit-button"
constants.camera_window_menu_button_name = constants.gui_name_prefix.."menu-button"
constants.close_button_name = constants.gui_name_prefix.."close-button"
constants.cemera_view_name = constants.gui_name_prefix.."camera-view"
constants.camera_window_menu_name_prefix = constants.gui_name_prefix.."camera-window-menu-"

constants.camera_window_size_minimum = 100

return constants