# API Reference

## CameraViewSpec

@*field* `position` MapPosition? — Position of the camera, defaults to (0, 0).

@*field* `surface_index` integer? — Surface index of the camera, defaults to the surface the player is on.

@*field* `zoom` number? — Zoom level of the camera, defaults to 0.75.

@*field* `entity` LuaEntity? — If specified, keep this entity at the center of the camera, overrides `position` and `surface_index`.

## remote.windowed-cameras

### create

```lua
remote.call("windowed-cameras", "create", player, spec, size)
```

Create a new camera window.

@*param* `player` LuaPlayer — The player to create the camera window for.

@*param* `spec` CameraViewSpec — Specifies what the camera looks at.

@*param* `size` [integer, integer]? — Size of the camera window frame.

@*return* integer — Ordinal of the new window.

### destroy

```lua
remote.call("windowed-cameras", "destroy", player, ordinal)
```

Destroy a camera window.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

### update_view

```lua
remote.call("windowed-cameras", "update_view", player, ordinal, spec)
```

Update the settings of a camera view, unspecified parameters are unchanged.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*param* `spec` CameraViewSpec — Specifies what the camera looks at.

### get_camera_element

```lua
remote.call("windowed-cameras", "get_camera_element", player, ordinal)
```

Get the camera view LuaGuiElement in a window. It's best to treat the obtained element as read-only.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*return* LuaGuiElement

### get_window_frame

```lua
remote.call("windowed-cameras", "get_window_frame", player, ordinal)
```

Get the window frame LuaGuiElement of a camera window. It's best to treat the obtained element as read-only.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*return* LuaGuiElement

### get_window_size

```lua
remote.call("windowed-cameras", "get_window_size", player, ordinal)
```

Get the size of a camera window.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*return* [integer, integer]

### set_window_size

```lua
remote.call("windowed-cameras", "set_window_size", player, ordinal, size)
```

Set the size of a camera window.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*param* `size` [integer, integer] — The new size to set to.

### get_window_location

```lua
remote.call("windowed-cameras", "get_window_location", player, ordinal)
```

Get the location of a camera window on screen.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*return* GuiLocation

### set_window_location

```lua
remote.call("windowed-cameras", "set_window_location", player, ordinal, location)
```

Set the location of a camera window on screen.

@*param* `player` LuaPlayer — The player the camera window belongs to.

@*param* `ordinal` integer — The ordinal of the camera window.

@*param* `location` GuiLocation — The new location to set to.

