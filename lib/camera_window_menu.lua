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

  for _, dimension in ipairs{"width", "height"} do
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
      minimum_value = constants.camera_window_size_minimum,
      maximum_value = player.display_resolution[dimension],
      tags = {
        [constants.gui_tag_event_enabled] = true,
        on_value_changed = "handle_slider_changed",
      },
    }
    flow.add{
      type = "textfield",
      name = "textfield",
      style = "slider_value_textfield",
      text = "0",
      numeric = true,
      allow_decimal = false,
      allow_negative = false,
      tags = {
        [constants.gui_tag_event_enabled] = true,
        on_text_changed = "handle_slider_text_changed",
      },
    }
  end

  -- Place the menu just below the menu button
  menu.location = {
    x = window.window.location.x + (window.window.style.minimal_width - 68) * player.display_scale,
    y = window.window.location.y + 40 * player.display_scale,
  }

  window:get_menu_button().toggled = true

  return setmetatable({
    frame = menu,
  }, self)
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

function prototype:destroy()
  local window = CameraWindow:for_menu(self)

  self.frame.destroy()

  if window then
    window:get_menu_button().toggled = false
  end
end

function prototype:handle_slider_changed()
  for _, dimension in ipairs{"width", "height"} do
    local slider = self.frame["table"][dimension]["slider"] ---@type LuaGuiElement
    local textfield = self.frame["table"][dimension]["textfield"] ---@type LuaGuiElement

    textfield.text = tostring(slider.slider_value)
  end
end

function prototype:handle_slider_text_changed()
  for _, dimension in ipairs{"width", "height"} do
    local slider = self.frame["table"][dimension]["slider"] ---@type LuaGuiElement
    local textfield = self.frame["table"][dimension]["textfield"] ---@type LuaGuiElement

    local number = tonumber(textfield.text) or 0
    if number >= slider.get_slider_minimum() and number <= slider.get_slider_maximum() then
      slider.slider_value = number
    end
  end
end

return CameraWindowMenu