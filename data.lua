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
  },

  {
    type = "custom-input",
    name = constants.input_zoom_in,
    key_sequence = "",
    linked_game_control = "zoom-in",
  },
  {
    type = "custom-input",
    name = constants.input_zoom_out,
    key_sequence = "",
    linked_game_control = "zoom-out",
  },
  {
    type = "custom-input",
    name = constants.input_move_up,
    key_sequence = "",
    linked_game_control = "move-up",
  },
  {
    type = "custom-input",
    name = constants.input_move_down,
    key_sequence = "",
    linked_game_control = "move-down",
  },
  {
    type = "custom-input",
    name = constants.input_move_left,
    key_sequence = "",
    linked_game_control = "move-left",
  },
  {
    type = "custom-input",
    name = constants.input_move_right,
    key_sequence = "",
    linked_game_control = "move-right",
  },
}

local style = data.raw["gui-style"]["default"]

style[constants.style_prefix.."camera_window_title"] = {
  type = "label_style",
  parent = "frame_title",
  top_margin = -3,
}

style[constants.style_prefix.."camera_window_dragger"] = {
  type = "empty_widget_style",
  parent = "draggable_space",
  horizontally_stretchable = "on",
  right_margin = 4,
  height = 24
}

style[constants.style_prefix.."camera_window_camera_view"] = {
  type = "camera_style",
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
}