-- Camera window menu GUI functionalities, encapsulates interactions with the GUI elements

local constants = require('lib/constants.lua')
local util = require('util')

---@class CameraWindowMenu
---@field frame LuaGuiElement
local prototype = {}

local CameraWindowMenu = {
  __index = prototype,
}

---@module "lib.camera_window"
local CameraWindow = nil
function CameraWindowMenu.set_window_module(module)
  CameraWindow = module
end

---Create a menu.
---@param window CameraWindow
---@return CameraWindowMenu?
function CameraWindowMenu:create(window)
  local player = game.get_player(window.window.player_index)
  if not player then return nil end

  local ordinal = window.window.tags.ordinal
  local window_size = window:get_size()

  local menu = player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_menu_name_prefix..ordinal,
    style = constants.style_prefix.."camera_window_menu_frame",
    direction = "vertical",
    tags = {
      ordinal = ordinal,
    }
  }

  local table = menu.add{
    type = "table",
    name = "table",
    style = "player_input_table",
    column_count = 2,
  }

  for dimension_i, dimension in ipairs{"width", "height"} do
    table.add{
      type = "label",
      caption = {"windowed-cameras."..dimension.."-slider-label"},
    }
    local flow = table.add{
      type = "flow",
      name = dimension,
      style = "player_input_horizontal_flow",
      direction = "horizontal",
    }
    flow.add{
      type = "slider",
      name = "slider",
      minimum_value = constants.camera_window_size_minimum[dimension_i],
      maximum_value = window_size[dimension_i] + 1, --- to be changed by update_max_window_size()
      value_step = 1,
      value = window_size[dimension_i],
      tags = {
        [constants.gui_tag_event_enabled] = true,
        on_value_changed = "handle_slider_changed",
      },
    }
    flow.add{
      type = "textfield",
      name = "textfield",
      style = "slider_value_textfield",
      text = tostring(window_size[dimension_i]),
      numeric = true,
      allow_decimal = false,
      allow_negative = false,
      tags = {
        [constants.gui_tag_event_enabled] = true,
        on_text_changed = "handle_slider_text_changed",
      },
    }
  end

  local instance = setmetatable({
    frame = menu,
  }, self)

  instance:align_location_to_window(window)
  instance:update_max_window_size()

  window:get_menu_button().toggled = true

  return instance
end

---Obtain a CameraWindowMenu from a LuaGuiElement.
---@param element LuaGuiElement
---@return CameraWindowMenu?
function CameraWindowMenu:from(element)
  while not util.string_starts_with(element.name, constants.camera_window_menu_name_prefix) do
    element = element.parent
    if not element then return nil end
  end

  return setmetatable({
    frame = element,
  }, self)
end

---Find the corresponding menu of a CameraWindow
---@param window CameraWindow
---@return CameraWindowMenu?
function CameraWindowMenu:for_window(window)
  local player = game.get_player(window.window.player_index)
  if not player then return nil end

  local frame = nil
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_menu_name_prefix) then
      if gui_element.tags.ordinal == window.window.tags.ordinal then
        frame = gui_element
        break
      end
    end
  end
  if not frame then return nil end
  
  return setmetatable({
    frame = frame,
  }, self)
end

---@param event EventData.on_player_display_resolution_changed | EventData.on_player_display_scale_changed
function CameraWindowMenu:on_display_resolution_scale_changed(event)
  local player = game.get_player(event.player_index)
  if not player then return nil end

  for _, gui_element in ipairs(player.gui.screen.children) do
    local camera_window_menu = CameraWindowMenu:from(gui_element)
    if camera_window_menu then
      camera_window_menu:align_location_to_window()
      camera_window_menu:update_max_window_size()
    end
  end
end

function prototype:destroy()
  local window = CameraWindow:for_menu(self)

  self.frame.destroy()

  if window then
    window:get_menu_button().toggled = false
  end
end

---Place the menu just below the menu button of a window.
---@param window? CameraWindow
function prototype:align_location_to_window(window)
  window = window or CameraWindow:for_menu(self)
  if not window then return end

  local player = game.get_player(self.frame.player_index)
  if not player then return end

  self.frame.location = {
    x = window.window.location.x + (window.window.style.minimal_width - 68) * player.display_scale,
    y = window.window.location.y + 40 * player.display_scale,
  }
end

---Set the max value of window size sliders to match the screen size.
function prototype:update_max_window_size()
  local player = game.get_player(self.frame.player_index)
  if not player then return end

  for _, dimension in ipairs{"width", "height"} do
    local slider = self.frame["table"][dimension]["slider"] ---@type LuaGuiElement
    slider.set_slider_minimum_maximum(
      slider.get_slider_minimum(),
      player.display_resolution[dimension] / player.display_scale
    )

    -- To make the slider update its dragger location, we change the slider value to something else and back
    local value = slider.slider_value
    slider.slider_value = slider.get_slider_minimum()
    slider.slider_value = value
  end
end

function prototype:handle_slider_changed()
  local window_size = {width = 0, height = 0}

  for dimension in pairs(window_size) do
    local slider = self.frame["table"][dimension]["slider"] ---@type LuaGuiElement
    local textfield = self.frame["table"][dimension]["textfield"] ---@type LuaGuiElement

    -- Set text to slider value
    textfield.text = tostring(slider.slider_value)

    window_size[dimension] = slider.slider_value
  end

  -- Resize the window
  local window = CameraWindow:for_menu(self)
  if window then
    window:set_size{window_size.width, window_size.height}
  end
end

function prototype:handle_slider_text_changed()
  local window_size = {width = 0, height = 0}

  for dimension in pairs(window_size) do
    local slider = self.frame["table"][dimension]["slider"] ---@type LuaGuiElement
    local textfield = self.frame["table"][dimension]["textfield"] ---@type LuaGuiElement

    local number = tonumber(textfield.text) or 0
    -- Set slider value to text, or make textfield red if text is invalid
    if number >= slider.get_slider_minimum() and number <= slider.get_slider_maximum() then
      textfield.style = "slider_value_textfield"
      slider.slider_value = number
    else
      textfield.style = constants.style_prefix.."invalid_value_slider_value_textfield"
    end

    window_size[dimension] = slider.slider_value
  end

  -- Resize the window
  local window = CameraWindow:for_menu(self)
  if window then
    window:set_size{window_size.width, window_size.height}
  end
end

return CameraWindowMenu