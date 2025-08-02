local constants = require("lib/constants.lua")

data:extend{
  {
    type = "shortcut",
    name = constants.shortcut_toggle_display_name,
    icons = {
      {
        icon = "__"..constants.mod_name.."__/graphics/icons/camera-x56.png",
        icon_size = 56,
      }
    },
    small_icons = {
      {
        icon = "__"..constants.mod_name.."__/graphics/icons/camera-x24.png",
        icon_size = 24,
      }
    },
    toggleable = true,
    action = "lua",
    associated_control_input = constants.input_toggle_display,
  },

  {
    type = "sprite",
    name = constants.sprite_edit_camera,
    filename = "__core__/graphics/icons/mip/move-tag.png",
    size = 32,
    invert_colors = true,
  },
  {
    type = "sprite",
    name = constants.sprite_menu_button,
    filename = "__core__/graphics/icons/mip/expand-panel-white.png",
    size = 64,
  },

  {
    type = "custom-input",
    name = constants.input_toggle_display,
    key_sequence = "CONTROL + TAB",
  },

  -- As a workaround for the absence of an on_player_zoom event, we listen on the zoom in and out controls being pressed
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
style[constants.style_prefix.."camera_window_menu_frame"] = {
  type = "frame_style",
  padding = 8,
  use_header_filler = false,
}

style[constants.style_prefix.."invalid_value_slider_value_textfield"] = {
  type = "textbox_style",
  parent = "invalid_value_short_number_textfield",
  horizontal_align = "center",
}