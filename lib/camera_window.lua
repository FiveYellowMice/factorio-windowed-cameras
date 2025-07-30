-- Camera window GUI functionalities, encapsulates interactions with the GUI elements

local constants = require('lib/constants.lua')

---@class CameraWindow
---@field window LuaGuiElement
---@field camera LuaGuiElement
local prototype = {}

local CameraWindow = {
  __index = prototype,
}

---Create a new camera window.
---@param player LuaPlayer
function CameraWindow:create(player)
  local instance = setmetatable({}, self)

  -- Find the largest ordinal of existing windows, the new window will have an ordinal of that + 1
  local n_window = 0
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      n_window = math.max(n_window, tonumber(gui_element.tags.ordinal) or 0)
    end
  end
  local window_ordinal = n_window + 1

  instance.window = player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_name_prefix..window_ordinal,
    direction = "vertical",
    tags = {ordinal = window_ordinal},
  }
  instance.window.style.size = {400, 400}

  local header_flow = instance.window.add{
    type = "flow",
    direction = "horizontal",
    style = "frame_header_flow"
  }
  header_flow.drag_target = instance.window
  header_flow.add{
    type = "label",
    style = constants.style_prefix.."camera_window_title",
    caption = {"windowed-cameras.window-title", window_ordinal},
    ignored_by_interaction = true,
  }
  header_flow.add{
    type = "empty-widget",
    style = constants.style_prefix.."camera_window_dragger",
    ignored_by_interaction = true,
  }
  header_flow.add{
    type = "sprite-button",
    style = "close_button",
    name = constants.camera_window_close_button_name,
    sprite = "utility/close",
    tooltip = {"gui.close"},
    mouse_button_filter = {"left"},
    tags = {
      on_click = "destroy",
    },
  }

  local content_flow = instance.window.add{
    type = "frame",
    style = "inside_shallow_frame"
  }
  instance.camera = content_flow.add{
    type = "camera",
    name = constants.cemera_view_name,
    style = constants.style_prefix.."camera_window_camera_view",
    position = player.position,
    surface_index = player.surface_index,
    zoom = player.zoom,
  }

  return instance
end

---Obtain a CameraWindow from a LuaGuiElement.
---@param element LuaGuiElement
---@return CameraWindow?
function CameraWindow:from(element)
  while not util.string_starts_with(element.name, constants.camera_window_name_prefix) do
    element = element.parent
    if not element then return nil end
  end

  local instance = setmetatable({}, self)
  instance.window = element
  instance.camera = element.children[2][constants.cemera_view_name]
  return instance
end

---Find the CameraWindow that is currently being edited.
---Temporarily it just finds the first window
---@return CameraWindow?
function CameraWindow:get_editing(player)
  local window = nil
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      window = gui_element
      break
    end
  end
  if not window then return nil end

  local instance = setmetatable({}, self)
  instance.window = window
  instance.camera = window.children[2][constants.cemera_view_name]
  return instance
end

function prototype:destroy()
  self.window.destroy()
end

---@param player LuaPlayer
function prototype:set_view_from_player(player)
  self.camera.position = player.position
  self.camera.zoom = player.zoom
end

return CameraWindow