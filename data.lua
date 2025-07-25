local constants = require("__windowed-cameras__/lib/constants.lua")

data:extend{
  {
    type = "shortcut",
    name = constants.shortcut_create_window_name,
    icon_size = 32,
    icon = "__windowed-cameras__/graphics/icons/add-camera-x32.png",
    small_icon_size = 24,
    small_icon = "__windowed-cameras__/graphics/icons/add-camera-x24.png",
    action = "lua",
  }
}