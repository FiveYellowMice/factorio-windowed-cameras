local constants = {}

constants.mod_name = "windowed-cameras"
constants.style_prefix = string.gsub(constants.mod_name, "-", "_").."_"

constants.shortcut_create_window_name = constants.mod_name.."-create-window"
constants.input_zoom_in = "zoom-in"
constants.input_zoom_out = "zoom-out"

constants.camera_window_name_prefix = constants.mod_name.."-camera-window-"
constants.cemera_view_name = constants.mod_name.."-camera-view"

constants.zoom_init_power = 6
constants.zoom_exp_base = 1.75 ^ (1 / constants.zoom_init_power) -- such that the initial zoom of zoom_exp_base ^ zoom_init_power - 1 == 0.75

return constants