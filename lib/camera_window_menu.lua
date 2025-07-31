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
    style = "player_input_table",
    column_count = 2,
  }

  table.add{
    type = "label",
    caption = {"windowed-cameras.width-slider-title"},
  }
  local width_flow = table.add{
    type = "flow",
    style = "player_input_horizontal_flow",
    direction = "horizontal",
  }
  width_flow.add{
    type = "slider",
    minimum_value = constants.camera_window_size_minimum,
    maximum_value = player.display_resolution.width,
  }
  width_flow.add{
    type = "textfield",
    style = "slider_value_textfield",
    text = "0",
    numeric = true,
    allow_decimal = false,
    allow_negative = false,
  }

  table.add{
    type = "label",
    caption = {"windowed-cameras.height-slider-title"},
  }
  local height_flow = table.add{
    type = "flow",
    style = "player_input_horizontal_flow",
    direction = "horizontal",
  }
  height_flow.add{
    type = "slider",
    minimum_value = constants.camera_window_size_minimum,
    maximum_value = player.display_resolution.height,
  }
  height_flow.add{
    type = "textfield",
    style = "slider_value_textfield",
    text = "0",
    numeric = true,
    allow_decimal = false,
    allow_negative = false,
  }

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

return CameraWindowMenu