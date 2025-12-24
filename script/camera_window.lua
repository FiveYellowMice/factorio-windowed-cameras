local constants = require('constants')
local util = require('util')
local math2d = require('math2d') ---@module 'script.meta.math2d'
local shortcut ---@module 'script.shortcut'
local CameraWindowMenu ---@module 'script.camera_window_menu'

local CameraWindow = {}

---Represents a camera window. Owns a GUI element. Resides in storage,
---@class CameraWindow
---@field player LuaPlayer The player this window belongs to.
---@field ordinal uint32 The ordinal number of this window, unique within a player.
---@field frame LuaGuiElement? The associated GUI element, may be invalid.
---@field menu CameraWindowMenu? The menu belonging to this window, if any.
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
  shortcut = require('script.shortcut')
end

---Create a new camera window.
---@param player LuaPlayer
---@param reference (LuaPlayer | LuaGuiElement | CameraViewSpec)? Reference to set initial position/zoom/surface from.
---@param size math2d_vector? Width and height of the window.
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
      size = size or constants.camera_window_size_default,
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

  instance:create_frame()

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
  for _, window in pairs(storage.players[player.index].camera_windows) do
    window:update_visibility()
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

  self:update_visibility()
  self:update_size()
  self:update_view()

  return self.frame
end

function CameraWindow.prototype:destroy_frame()
  if self.frame then
    self.frame.destroy()
    self.frame = nil
  end
end

function CameraWindow.prototype:destroy()
  -- None of these matter if the player has been removed
  if self.player.valid then
    self:end_editing()
    self:close_menu()
    self:destroy_frame()

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

  local new_window = CameraWindow:create(self.player, self:get_camera(), self.window_settings.size)
  -- Offset the new window a little
  self:create_frame()
  new_window.frame.location = {self.frame.location.x + 20, self.frame.location.y + 20}
  return new_window
end

function CameraWindow.prototype:get_camera()
  return self:create_frame().children[2]["camera-view"]
end

function CameraWindow.prototype:get_edit_button()
  return  self:create_frame().children[1]["edit-button"]
end

function CameraWindow.prototype:get_menu_button()
  return  self:create_frame().children[1]["menu-button"]
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

  -- Open remote view at the position of this camera window
  self.player.set_controller{
    type = defines.controllers.remote,
    position = self.view_settings.position,
    surface = self.view_settings.surface_index,
  }
  self.player.zoom = self.view_settings.zoom
  self.player.centered_on = self.view_settings.entity

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

---Update the visibility of the window.
function CameraWindow.prototype:update_visibility()
  if not self.frame or not self.frame.valid then return end

  self.frame.visible =
    shortcut.get_toggled(self.player) and
    (not CameraWindow:is_editing(self.player) or self:is_editing())
end

---Update the size of the window.
---@param anchor "top-left" | "top-right" | nil
function CameraWindow.prototype:update_size(anchor)
  self:create_frame()
  local old_size = {x = self.frame.style.minimal_width, y = self.frame.style.minimal_height}
  local old_location = self.frame.location --[[@as GuiLocation]]

  self.frame.style.width = self.window_settings.size.x
  self.frame.style.height = self.window_settings.size.y

  if anchor == "top-right" then
    self.frame.location = {
      x = old_location.x - (self.window_settings.size.x - old_size.x) * self.player.display_scale,
      y = old_location.y,
    }
  end
end

---Update view settings of the camera view.
function CameraWindow.prototype:update_view()
  local camera = self:get_camera()

  camera.position = self.view_settings.position
  camera.surface_index = self.view_settings.surface_index
  camera.zoom = self.view_settings.zoom
  camera.entity = self.view_settings.entity
end

---@param player LuaPlayer
function CameraWindow.prototype:set_view_from_player(player)
  self.view_settings.position = math2d.position.ensure_xy(player.position)
  self.view_settings.surface_index = player.surface_index
  self.view_settings.zoom = player.zoom
  self.view_settings.entity = player.centered_on

  self:update_view()
end

---@param entity LuaEntity?
---@return boolean success
function CameraWindow.prototype:select_tracked_entity(entity)
  if not entity then
    self.player.create_local_flying_text{
      text = {"windowed-cameras.track-entity-selection-empty-message"},
      create_at_cursor = true,
    }
    return false
  end

  if entity.force_index ~= self.player.force_index then
    self.player.create_local_flying_text{
      text = {"windowed-cameras.track-entity-selection-force-differ-message"},
      create_at_cursor = true,
    }
    return false
  end

  -- Selecting tracked entity may happen in or outside of editing mode, we handle both
  if self:is_editing() then
    self.player.centered_on = entity
    self:set_view_from_player(self.player)
  else
    self.view_settings.entity = entity
    self.view_settings.zoom = self.player.zoom
    self:update_view()
  end

  self.player.create_local_flying_text{
    text = {"windowed-cameras.track-entity-selection-success-message", entity.name_tag or entity.localised_name},
    create_at_cursor = true,
  }

  return true
end

function CameraWindow.prototype:toggle_menu()
  if not self.menu then
    CameraWindowMenu:create(self)
  else
    self.menu:destroy()
  end
end

function CameraWindow.prototype:close_menu()
  if self.menu then
    self.menu:destroy()
  end
end

function CameraWindow.prototype:update_menu_location()
  if self.menu then
    self.menu:align_location_to_window()
  end
end

return CameraWindow
