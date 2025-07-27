local constants = require("lib/constants.lua")

data:extend{
  {
    type = "shortcut",
    name = constants.shortcut_create_window_name,
    icons = {
      {
        icon = "__"..constants.mod_name.."__/graphics/icons/add-camera-x56.png",
        icon_size = 56,
      }
    },
    small_icons = {
      {
        icon = "__"..constants.mod_name.."__/graphics/icons/add-camera-x24.png",
        icon_size = 24,
      }
    },
    action = "lua",
  }
}