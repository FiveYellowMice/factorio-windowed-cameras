local constants = require('constants')
local util = require('util')
local math2d = require('math2d') ---@module 'script.meta.math2d'
local CameraWindow ---@module "script.camera_window"

local CameraWindowMenu = {}

---A menu belonging to a camera window. Resides in storage.
---@class CameraWindowMenu
---@field window CameraWindow The camera window this menu belongs to.
---@field frame LuaGuiElement? The associated GUI element, may be invalid.
CameraWindowMenu.prototype = {}
CameraWindowMenu.prototype.__index = CameraWindowMenu.prototype


function CameraWindowMenu.load_deps()
  CameraWindow = require('script.camera_window')
end

---Create a menu.
---@param window CameraWindow
---@return CameraWindowMenu?
function CameraWindowMenu:create(window)
  local instance = setmetatable({
    window = window,
  } --[[@as CameraWindowMenu]], self.prototype)

  window.menu = instance

  instance.window:get_menu_button().toggled = true
  instance:create_frame()

  return instance
end

---Obtain a CameraWindowMenu from a LuaGuiElement.
---@param element LuaGuiElement
---@return CameraWindowMenu?
function CameraWindowMenu:from_element(element)
  while not util.string_starts_with(element.name, constants.camera_window_menu_name_prefix) do
    element = element.parent
    if not element then return nil end
  end

  return CameraWindow:get(element.player_index, element.tags.ordinal --[[@as integer]]).menu
end

---@param event EventData.on_player_display_resolution_changed | EventData.on_player_display_scale_changed
function CameraWindowMenu:on_display_resolution_scale_changed(event)
  for _, window in pairs(storage.players[event.player_index].camera_windows) do
    if window.menu then
      window.menu:align_location_to_window()
      window.menu:update_max_window_size()
    end
  end
end

---Create the frame GUI element if it does not exist.
---@return LuaGuiElement
function CameraWindowMenu.prototype:create_frame()
  if self.frame and self.frame.valid then return self.frame end

  self.frame = self.window.player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_menu_name_prefix..self.window.ordinal,
    style = constants.style_prefix.."camera_window_menu_frame",
    direction = "vertical",
    tags = {
      ordinal = self.window.ordinal,
    }
  }

  local table = self.frame.add{
    type = "table",
    name = "table",
    style = "player_input_table",
    column_count = 2,
  }

  for dimension, dimension_size in pairs{x = "width", y = "height"} do
    table.add{
      type = "label",
      caption = {"windowed-cameras."..dimension_size.."-slider-label"},
    }
    local flow = table.add{
      type = "flow",
      name = dimension_size,
      style = "player_input_horizontal_flow",
      direction = "horizontal",
    }
    flow.add{
      type = "slider",
      name = "slider",
      minimum_value = constants.camera_window_size_minimum[dimension],
      maximum_value = self.window.window_settings.size[dimension] + 1, --- to be changed by update_max_window_size()
      value_step = 1,
      value = self.window.window_settings.size[dimension],
      tags = {
        [constants.gui_tag_event_enabled] = true,
        on_value_changed = "handle_slider_changed",
      },
    }
    flow.add{
      type = "textfield",
      name = "textfield",
      style = "slider_value_textfield",
      text = tostring(self.window.window_settings.size[dimension]),
      numeric = true,
      allow_decimal = false,
      allow_negative = false,
      tags = {
        [constants.gui_tag_event_enabled] = true,
        on_text_changed = "handle_slider_text_changed",
      },
    }
  end

  local buttons_flow = self.frame.add{
    type = "flow",
    name = "buttons",
    direction = "horizontal",
  }
  buttons_flow.add{
    type = "button",
    name = "track-entity-button",
    caption = {"windowed-cameras.track-entity-button-caption"},
    tooltip = {"windowed-cameras.track-entity-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "handle_track_entity_clicked",
    }
  }

  self:align_location_to_window()
  self:update_max_window_size()

  return self.frame
end

function CameraWindowMenu.prototype:destroy_frame()
  if self.frame then
    self.frame.destroy()
    self.frame = nil
  end
end

function CameraWindowMenu.prototype:destroy()
  self:destroy_frame()
  self.window:get_menu_button().toggled = false

  self.window.menu = nil
end

---Place the menu just below the menu button of a window.
function CameraWindowMenu.prototype:align_location_to_window()
  self.window:create_frame()
  local offset = {x = self.window.frame.style.minimal_width - 68, y = 40}
  self:create_frame().location = math2d.position.add(
    self.window.frame.location,
    math2d.position.multiply_scalar(offset, self.window.player.display_scale)
  )
end

---Set the max value of window size sliders to match the screen size.
function CameraWindowMenu.prototype:update_max_window_size()
  for _, dimension_size in ipairs{"width", "height"} do
    local slider = self.frame["table"][dimension_size]["slider"] ---@type LuaGuiElement
    slider.set_slider_minimum_maximum(
      slider.get_slider_minimum(),
      self.window.player.display_resolution[dimension_size] / self.window.player.display_scale
    )

    -- To make the slider update its dragger location, we change the slider value to something else and back
    local value = slider.slider_value
    slider.slider_value = slider.get_slider_minimum()
    slider.slider_value = value
  end
end

function CameraWindowMenu.prototype:handle_slider_changed()
  local window_size = {width = 0, height = 0}

  for dimension_size in pairs(window_size) do
    local slider = self.frame["table"][dimension_size]["slider"] ---@type LuaGuiElement
    local textfield = self.frame["table"][dimension_size]["textfield"] ---@type LuaGuiElement

    -- Set text to slider value
    textfield.text = tostring(slider.slider_value)

    window_size[dimension_size] = slider.slider_value
  end

  -- Resize the window
  -- Anchoring to top right so that the menu button stays at the same place relative to the menu
  self.window.window_settings.size = {x = window_size.width, y = window_size.height}
  self.window:update_size("top-right")
end

function CameraWindowMenu.prototype:handle_slider_text_changed()
  local window_size = {width = 0, height = 0}

  for dimension_size in pairs(window_size) do
    local slider = self.frame["table"][dimension_size]["slider"] ---@type LuaGuiElement
    local textfield = self.frame["table"][dimension_size]["textfield"] ---@type LuaGuiElement

    local number = tonumber(textfield.text) or 0
    -- Set slider value to text, or make textfield red if text is invalid
    if number >= slider.get_slider_minimum() and number <= slider.get_slider_maximum() then
      textfield.style = "slider_value_textfield"
      slider.slider_value = number
    else
      textfield.style = constants.style_prefix.."invalid_value_slider_value_textfield"
    end

    window_size[dimension_size] = slider.slider_value
  end

  -- Resize the window
  -- Anchoring to top right so that the menu button stays at the same place relative to the menu
  self.window.window_settings.size = {x = window_size.width, y = window_size.height}
  self.window:update_size("top-right")
end

function CameraWindowMenu.prototype:handle_track_entity_clicked()
  local player = self.window.player

  -- Give the player an entity selection tool.
  -- Do not begin editing, as the way to end editing may be confusing without prior establishment.

  -- Clear cursor to not destroy player's currently held item.
  if not player.clear_cursor() then return end
  -- cursor_stack may be nil for spectators or dead players, so we are unable to give an item to them.
  if not player.cursor_stack then goto error end
  -- The API doc says `set_stack` may fail, but it is not clear when it would fail.
  -- So just show a generic error message regardless.
  if not player.cursor_stack.set_stack(constants.track_entity_selector_name) then goto error end

  player.cursor_stack.label = tostring(self.frame.tags.ordinal)

  -- Close the menu.
  self:destroy()

  do return end

  ::error::
  player.create_local_flying_text{
    text = {"windowed-cameras.track-entity-give-selector-failed-message"},
    create_at_cursor = true,
  }
end

return CameraWindowMenu
