-- Camera window GUI functionalities, encapsulates interactions with the GUI elements

local constants = require('constants')
local util = require('util')
local math2d = require('math2d') ---@module 'script.meta.math2d'
local shortcut = require('script.shortcut')
local CameraWindowMenu ---@module 'script.camera_window_menu'

local CameraWindow = {}

---Resides in storage,
---@class CameraWindow
---@field player LuaPlayer The player this window belongs to.
---@field ordinal uint32 The ordinal number of this window, unique within a player.
---@field frame LuaGuiElement? The associated GUI element, may be invalid.
---@field view_settings CameraViewSettings
---@field window_settings CameraWindowSettings
CameraWindow.prototype = {}
CameraWindow.prototype.__index = CameraWindow.prototype


---@class (exact) CameraViewSettings
---@field position math2d_position
---@field surface_index integer
---@field zoom number
---@field entity LuaEntity? If specified, keep this entity at the center of the camera, overrides `position` and `surface_index`.

---@class (exact) CameraWindowSettings
---@field size math2d_vector Screen-space size.


---@class CameraViewSpec
---@field position MapPosition? Position of the camera, defaults to (0, 0).
---@field surface_index integer? Surface index of the camera, defaults to the surface the player is on.
---@field zoom number? Zoom level of the camera, defaults to 0.75.
---@field entity LuaEntity? If specified, keep this entity at the center of the camera, overrides `position` and `surface_index`.


function CameraWindow.load_deps()
  CameraWindowMenu = require('script.camera_window_menu')
end

---Create a new camera window.
---@param player LuaPlayer
---@param reference (LuaPlayer | LuaGuiElement | CameraViewSpec)? Reference to set initial position/zoom/surface from.
---@param size [integer, integer]? Width and height of the window.
function CameraWindow:create(player, reference, size)
  -- Find the smallest ordinal that isn't taken by any existing window
  local new_ordinal = 1
  while self:get(player, new_ordinal) do
    new_ordinal = new_ordinal + 1
  end

  local instance = setmetatable({
    player = player,
    ordinal = new_ordinal,
    view_settings = {
      position = reference and math2d.position.ensure_xy(reference.position) or {x=0, y=0},
      surface_index = reference and reference.surface_index or player.surface_index,
      zoom = reference and reference.zoom or 0.75,
    },
    window_settings = {
      size = math2d.position.ensure_xy(size or constants.camera_window_size_default),
    },
  }--[[@as CameraWindow]], self.prototype)

  if reference then
    if reference.object_name == "LuaPlayer" then
      instance.view_settings.entity = reference.centered_on
    else
      instance.view_settings.entity = reference.entity
    end
  end

  storage.players[player.index].camera_windows[instance.ordinal] = instance

  return instance
end

---Get a specific window.
---@param player LuaPlayer | uint32 Player owning the window or index thereof.
---@param ordinal integer Ordinal of the window.
---@return CameraWindow?
function CameraWindow:get(player, ordinal)
  return storage.players[type(player) == "number" and player or player.index].camera_windows[ordinal]
end

---Obtain a CameraWindow from a LuaGuiElement.
---@param element LuaGuiElement
---@return CameraWindow?
function CameraWindow:from_element(element)
  while not util.string_starts_with(element.name, constants.camera_window_name_prefix) do
    element = element.parent
    if not element then return nil end
  end

  return self:get(element.player_index, element.tags.ordinal --[[@as integer]])
end

---Find the corresponding window of a CameraWindowMenu
---@param menu CameraWindowMenu
---@return CameraWindow?
function CameraWindow:for_menu(menu)
  local player = game.get_player(menu.frame.player_index)
  if not player then return nil end

  return self:get(player, menu.frame.tags.ordinal --[[@as integer]])
end

---Whether there is a camera window being edited.
---@param player LuaPlayer | uint32
---@return boolean
function CameraWindow:is_editing(player)
  return storage.players[type(player) == "number" and player or player.index].editing_camera_window ~= nil
end

---Get the CameraWindow that is currently being edited.
---@param player LuaPlayer | uint32
---@return CameraWindow?
function CameraWindow:get_editing(player)
  local ordinal = storage.players[type(player) == "number" and player or player.index].editing_camera_window
  if not ordinal then return nil end

  return self:get(player, ordinal)
end

---Exit window editing mode.
---@param player LuaPlayer
function CameraWindow:end_editing(player)
  local window = self:get_editing(player)
  if window then
    window:end_editing()
  end
end

---Update the visibilities of all camera windows.
---@param player LuaPlayer
function CameraWindow:update_visibility(player)
  local visibility_toggle = shortcut.get_toggled(player)
  local editing = self:get_editing(player)

  for _, window in pairs(storage.players[player.index].camera_windows) do
    window.frame.visible = visibility_toggle and (not editing or window:is_editing())
  end
end

---Create the frame GUI element if it does not exist.
---@return LuaGuiElement
function CameraWindow.prototype:create_frame()
  if self.frame and self.frame.valid then return self.frame end

  -- Destroy other frames with the same ordinal
  for _, gui_element in ipairs(self.player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      if gui_element.tags.ordinal == self.ordinal then
        gui_element.destroy()
      end
    end
  end

  self.frame = self.player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_name_prefix..self.ordinal,
    direction = "vertical",
    tags = {
      ordinal = self.ordinal,
      [constants.gui_tag_event_enabled] = true,
      on_location_changed = "update_menu_location",
    },
  }
  self.frame.style.width = self.window_settings.size.x
  self.frame.style.height = self.window_settings.size.y

  local header_flow = self.frame.add{
    type = "flow",
    direction = "horizontal",
    style = "frame_header_flow"
  }
  header_flow.drag_target = self.frame
  header_flow.add{
    type = "label",
    style = constants.style_prefix.."camera_window_title",
    caption = {"windowed-cameras.window-title", self.ordinal},
    ignored_by_interaction = true,
  }
  header_flow.add{
    type = "empty-widget",
    style = constants.style_prefix.."camera_window_dragger",
    ignored_by_interaction = true,
  }
  header_flow.add{
    type = "sprite-button",
    style = "frame_action_button",
    name = "clone-button",
    sprite = "utility/add_white",
    tooltip = {"windowed-cameras.clone-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "clone",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "frame_action_button",
    name = "edit-button",
    sprite = constants.sprite_edit_camera,
    tooltip = {"windowed-cameras.edit-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "toggle_editing",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "frame_action_button",
    name = "menu-button",
    sprite = constants.sprite_menu_button,
    tooltip = {"windowed-cameras.menu-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "toggle_menu",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "close_button",
    name = "close-button",
    sprite = "utility/close",
    tooltip = {"gui.close"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "destroy",
    },
  }

  local content_flow = self.frame.add{
    type = "frame",
    style = "inside_shallow_frame"
  }
  local camera = content_flow.add{
    type = "camera",
    name = "camera-view",
    style = constants.style_prefix.."camera_window_camera_view",
    position = self.view_settings.position,
    surface_index = self.view_settings.surface_index,
    zoom = self.view_settings.zoom,
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "toggle_editing",
    },
  }
  camera.entity = self.view_settings.entity

  return self.frame
end

function CameraWindow.prototype:destroy()
  -- None of these matter if the player has been removed
  if self.player.valid then
    self:end_editing()
    self:close_menu()
    self.frame.destroy()

    storage.players[self.player.index].camera_windows[self.ordinal] = nil

    -- Set shortcut to false when closing the last window
    if not next(storage.players[self.player.index].camera_windows) then
      shortcut.set_toggled(self.player, false)
    end
  end
end

function CameraWindow.prototype.__eq(a, b)
  return a.ordinal == b.ordinal
end

function CameraWindow.prototype:clone()
  CameraWindow:end_editing(self.player)

  local new_window = CameraWindow:create(self.player, self:get_camera(), self:get_size())
  -- Offset the new window a little
  new_window.frame.location = {self.frame.location.x + 20, self.frame.location.y + 20}
  return new_window
end

function CameraWindow.prototype:get_camera()
  return self.frame.children[2]["camera-view"]
end

function CameraWindow.prototype:get_edit_button()
  return self.frame.children[1]["edit-button"]
end

function CameraWindow.prototype:get_menu_button()
  return self.frame.children[1]["menu-button"]
end

---@return [integer, integer]
function CameraWindow.prototype:get_size()
  return {self.frame.style.minimal_width, self.frame.style.minimal_height}
end

---Resize the window.
---@param size [integer, integer]
---@param anchor "top-left" | "top-right" | nil
function CameraWindow.prototype:set_size(size, anchor)
  local player = game.get_player(self.frame.player_index)
  if not player then return end

  local old_size = self:get_size()
  local old_location = self.frame.location --[[@as GuiLocation]]

  self.frame.style.width = size[1]
  self.frame.style.height = size[2]

  if anchor == "top-right" then
    self.frame.location = {
      x = old_location.x - (size[1] - old_size[1]) * player.display_scale,
      y = old_location.y,
    }
  end
end

---@return boolean
function CameraWindow.prototype:is_editing()
  return self.ordinal == storage.players[self.player.index].editing_camera_window
end

function CameraWindow.prototype:toggle_editing()
  if not self:is_editing() then
    self:begin_editing()
  else
    self:end_editing()
  end
end

function CameraWindow.prototype:begin_editing()
  if self:is_editing() then return end

  -- End editing of other windows
  CameraWindow:end_editing(self.player)

  -- Open remote view at the position of the camera
  local camera = self:get_camera()
  self.player.set_controller{
    type = defines.controllers.remote,
    position = camera.position,
    surface = camera.surface_index,
  }
  self.player.zoom = camera.zoom
  self.player.centered_on = camera.entity

  self:get_edit_button().toggled = true
  storage.players[self.player.index].editing_camera_window = self.ordinal

  CameraWindow:update_visibility(self.player)
end

function CameraWindow.prototype:end_editing()
  if not self:is_editing() then return end

  -- Close remote view
  self.player.exit_remote_view()

  -- Clear entity selector
  local cursor_stack = self.player.cursor_stack
  if
    cursor_stack and
    cursor_stack.valid_for_read and
    cursor_stack.name == constants.track_entity_selector_name
  then
    cursor_stack.clear()
  end

  self:get_edit_button().toggled = false
  storage.players[self.player.index].editing_camera_window = nil

  CameraWindow:update_visibility(self.player)
end

---Update the settings of the camera view, unspecified fields remain unchanged.
---@param spec CameraViewSpec
function CameraWindow.prototype:update_view(spec)
  local camera = self:get_camera()
  local player = nil---@type LuaPlayer?
  if self:is_editing() then
    player = game.get_player(self.frame.player_index)
    if not player then return end
  end

  for _, field in ipairs{{"position"}, {"surface_index"}, {"zoom"}, {"entity", "centered_on"}} do
    local spec_field = field[1]
    local player_field = field[2] or field[1]

    if spec[spec_field] then
      camera[spec_field] = spec[spec_field]
      if player then
        player[player_field] = spec[spec_field]
      end
    end
  end
end

---@param player LuaPlayer
function CameraWindow.prototype:set_view_from_player(player)
  local camera = self:get_camera()
  camera.position = player.position
  camera.surface_index = player.surface_index
  camera.zoom = player.zoom
  camera.entity = player.centered_on
end

---@param entity LuaEntity?
---@return boolean success
function CameraWindow.prototype:select_tracked_entity(entity)
  local player = game.get_player(self.frame.player_index)
  if not player then return false end

  if not entity then
    player.create_local_flying_text{
      text = {"windowed-cameras.track-entity-selection-empty-message"},
      create_at_cursor = true,
    }
    return false
  end

  if entity.force_index ~= player.force_index then
    player.create_local_flying_text{
      text = {"windowed-cameras.track-entity-selection-force-differ-message"},
      create_at_cursor = true,
    }
    return false
  end

  -- Selecting tracked entity may happen in or outside of editing mode, we handle both
  if self:is_editing() then
    player.centered_on = entity
    self:set_view_from_player(player)
  else
    local camera = self:get_camera()
    camera.entity = entity
    camera.zoom = player.zoom
  end

  player.create_local_flying_text{
    text = {"windowed-cameras.track-entity-selection-success-message", entity.name_tag or entity.localised_name},
    create_at_cursor = true,
  }

  return true
end

function CameraWindow.prototype:toggle_menu()
  local menu = CameraWindowMenu:for_window(self)
  if not menu then
    CameraWindowMenu:create(self)
  else
    menu:destroy()
  end
end

function CameraWindow.prototype:close_menu()
  local menu = CameraWindowMenu:for_window(self)
  if menu then
    menu:destroy()
  end
end

function CameraWindow.prototype:update_menu_location()
  local menu = CameraWindowMenu:for_window(self)
  if menu then
    menu:align_location_to_window(self)
  end
end

return CameraWindow
