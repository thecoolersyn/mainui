# Norepine UI — API Documentation

A Roblox UI library with a Pure Black theme. This document covers every public
function, the globals that get published, and the settings tables each element
accepts.

## Loading

Load the bootstrap in your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/thecoolersyn/mainui/HEAD/main.lua"))()
```

`main.lua` fetches `src.lua` and `test.lua` from the same repo and runs them in
order. Alternatively, load `src.lua` yourself:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/thecoolersyn/mainui/HEAD/src.lua"))()
local UI = Library.new()
-- create tabs / modules here
UI:load()
```

## Globals published by src.lua

| Global | Type | Description |
|--------|------|-------------|
| `getgenv().NOREPINE_LIB` | table | The `Library` table returned by `src.lua`. |
| `getgenv().NOREPINE_UI` | table | The live `UI` instance returned by `Library.new()`. |
| `getgenv().NOREPINE_API` | table | Convenience API wrapper (see below). |
| `getgenv().NOREPINE_THEME` | table | The active theme color palette. |
| `getgenv().NOREPINE_ACCENT` | table | The animated accent controller. |
| `getgenv().GG` | table | Language strings table. |

---

## 1. Library (static) functions

Call these on the `Library` table (e.g. `Library.SetAccentColor(...)` or
`Library:SetAccentColor(...)`).

### `Library.new()`
Creates and returns a new `UI` instance. Call this once, then build tabs and
modules on it, then call `UI:load()`.

### `Library.SendNotification(settings)`
Shows a toast in the top-right corner. Returns nothing.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `title` | string | `"Notification"` | Bold title line. |
| `text` | string | `""` | Body line. |
| `state` | boolean | `nil` | `true` shows a white checkmark, `false` shows a white cross. |
| `kind` | string | `nil` | `"bell"` shows the bell icon; `"check"` / `"x"` force those icons. |
| `strip` | Color3 | pink | Color of the thin 2px strip along the top of the toast. |
| `duration` | number | `5` | Seconds the toast stays before sliding out. |

Icon rules (only **one** icon is ever shown per toast):
- Module enabled  -> checkmark
- Module disabled  -> cross
- Dropdown mode changed -> bell

### `Library:SetAccentColor(color: Color3)`
Sets the accent color used by toggles, borders and highlights.

### `Library:SetBackground(settings)` -> `(boolean, ...)`
Controls the custom background layer.

| Setting | Type | Description |
|---------|------|-------------|
| `enabled` | boolean | Show/hide the background. |
| `opacity` | number (0-1) | Background opacity. |
| `media` | string | File name (in `Norepine/backgrounds`) or an `http(s)` URL. URLs are downloaded and saved. |
| `save_as` | string | File name when downloading a URL. |

Returns `true` on success, or `false, err` on failure.

### `Library:GetBackgroundManager()` -> table
Returns the internal `BackgroundManager` for advanced use.

### `Library:create_background_settings(module)`
Adds a ready-made "Background" settings page (checkbox, media dropdown,
opacity slider, URL/name textboxes and action buttons) to a module.

### `Library:flag_type(flag, typeName)` -> boolean
Checks whether a saved config flag currently matches the given Luau type
(`"boolean"`, `"number"`, `"string"`, ...).

### `Library:remove_table_value(tbl, value)`
Removes the first occurrence of `value` from `tbl`.

---

## 2. UI instance functions

These are called on the object returned by `Library.new()`. The returned
instance is also available as `getgenv().NOREPINE_UI`.

### `UI:create_tab(title, icon?)` -> TabManager
Adds a navigation tab. `icon` is a Roblox asset id string (Lucide assets are
used by the demo). Returns a `TabManager` used to create modules.

### `UI:load()`
Finishes setup: preloads images, applies screen scaling, tweens the window
open and starts the background/shimmer. **Call this once after building all
tabs and modules.**

### `UI:toggle_visibility()` -> boolean
Toggles the window between open (698x479) and minimized (104x52). Returns the
new open state (`true` = open). Also bound to the `Insert` key and the
configured "Toggle key".

### `UI:change_visiblity(state: boolean)`
Sets the window open (`true`) or minimized (`false`) explicitly. When
minimized only the centered "Norepine" brand is shown.

### `UI:SetGameName(name: string)` / `UI:GetGameName()` -> string
Sets/reads the small game name shown next to the brand (default "Blade Ball").
See also `NOREPINE_API.SetGameName` below.

### `UI:Update1Run(value)`
Sets the window background transparency. Pass `"nil"` to reset to opaque, or a
number to set it directly.

### `UI:UIVisiblity()`
Toggles the whole `ScreenGui`'s `Enabled` property (show/hide everything).

### `UI:removed(action)`
Registers a callback fired once when the UI's ScreenGui is removed.

### `UI:get_screen_scale()` / `UI:get_device()`
Internal helpers used during `load()` for mobile scaling and device detection.

---

## 3. TabManager functions

Returned by `UI:create_tab()`.

### `Tab:create_module(settings)` -> ModuleManager
Creates a module card. Settings:

| Setting | Type | Description |
|---------|------|-------------|
| `title` | string | Card title. |
| `description` | string | Subtitle under the title. |
| `flag` | string | Save/config key for this module. |
| `section` | `"left"` / `"right"` | Which column the card goes in (default left). |
| `callback` | function(state) | Called whenever the module toggles. |
| `notoggle` / `Module_NoToggle` | boolean | If `true`, the card is always open, has **no toggle button or bell**, and exposes its content permanently (see Image 4). |
| `Module_Rebind` | boolean | Set `false` to hide the module-level rebind chip. Default shown. |
| `Module_ContentRebind` | boolean | Set `false` to hide all rebind chips on the content rows. Default shown. |

---

## 4. ModuleManager functions

Returned by `Tab:create_module()`. Every `create_*` function returns a manager
for that element.

### `Module:change_state(state: boolean)`
Opens/closes the module (toggles it). Ignored — forced open — for `notoggle`
modules.

### `Module:SetGameName`, rebind controls (via the global API)
See section 6 for `Module_NoToggle`, `Module_Rebind` and `Module_ContentRebind`.

### `Module:create_checkbox(settings)` -> CheckboxManager
A labeled pill toggle row.

| Setting | Type | Description |
|---------|------|-------------|
| `title` | string | Row label. |
| `flag` | string | Config key. |
| `callback` | function(state) | Called when toggled. |
| `_defaultState` | boolean | Helper default (see `test.lua`). |

Supports keybinding the row: left-click its rebind chip then press a key
(Left-click the chip with `-`, or press Backspace to clear).

### `Module:create_dropdown(settings)` -> DropdownManager
A selectable list.

| Setting | Type | Description |
|---------|------|-------------|
| `title` | string | Row label. |
| `flag` | string | Config key. |
| `options` | table | Array of strings. |
| `maximum_options` | number | Max options to list. |
| `multi_dropdown` | boolean | Allow multiple selections. |
| `callback` | function(option) | Called on selection; sends a bell toast when this dropdown's notify bell is enabled. |

### `Module:create_slider(settings)` -> SliderManager
A draggable value slider.

| Setting | Type | Description |
|---------|------|-------------|
| `title` | string | Row label. |
| `flag` | string | Config key. |
| `minimum_value` / `maximum_value` | number | Range. |
| `value` | number | Initial value. |
| `round_number` | boolean | Round to integers. |
| `ignoresaved` | boolean | Don't persist to config. |
| `callback` | function(number) | Called while dragging. |

### `Module:create_textbox(settings)` -> TextboxManager
A text input. Settings: `title`, `flag`, `placeholder`, `callback(text)`.

### `Module:create_text(settings)`
A block of body text. Settings: `text`, `rich` (RichText), `richtext`,
`CustomYSize`, `customScale`. `TextManager:Set(new_settings)` updates it.

### `Module:create_paragraph(settings)`
A titled paragraph with a header and wrapped body. Settings: `title`, `text`,
`rich`, `richtext`, `customScale`.

### `Module:create_divider(settings)`
A horizontal separator. Settings: `showtopic` (adds a centered title),
`title`, `disableline`.

### `Module:create_feature(settings)`
A feature row with an optional checkbox and a keybind chip. Settings:
`title`, `flag`, `default` (key name), `disablecheck` (no checkbox — button
only), `callback(state)`, `button_callback()`.

---

## 5. Accent controller (`getgenv().NOREPINE_ACCENT`)

| Function | Description |
|----------|-------------|
| `Accent.SetColor(color)` | Set the accent color. |
| `Accent.SetSpeed(seconds)` | Set the border-sweep speed. |
| `Accent.SetEnabled(bool)` | Enable/disable the animated accent. |
| `Accent.Shutdown()` | Stop all accent animations. |

---

## 6. Global convenience API (`getgenv().NOREPINE_API`)

A flat wrapper so scripts can use the library without holding references.

```lua
local API = getgenv().NOREPINE_API
```

| Field | Description |
|-------|-------------|
| `API.UI` | The live UI instance (same as `NOREPINE_UI`). |
| `API.SetGameName(name)` | Change the game name shown next to the brand. |
| `API.GetGameName()` | Returns the current game name. |
| `API.Module_NoToggle(module)` | Make a module permanently open with no toggle button/bell. Pass the ModuleManager returned by `create_module()`. |
| `API.Module_Rebind(module, bool)` | Show (`true`) or hide (`false`) the module-level rebind chip. |
| `API.Module_ContentRebind(module, bool)` | Show/hide the rebind chips on that module's content rows. |

Example:

```lua
local API = getgenv().NOREPINE_API
API.SetGameName("Rivals")

local UI = API.UI
local tab = UI:create_tab("Main")
local mod = tab:create_module({ title = "Always On", flag = "always" })

-- Never collapses, no module toggle:
API.Module_NoToggle(mod)
-- Hide the module rebind chip but keep per-row rebind chips:
API.Module_Rebind(mod, false)
API.Module_ContentRebind(mod, true)
```

The same controls can be set directly in `create_module`'s settings table via
`notoggle`, `Module_Rebind` and `Module_ContentRebind` (see section 3).

---

## 7. Config persistence

Flags and keybinds are saved to `Norepine/<gameId>.json` via `HttpService`.
Toggle/slider/dropdown/textbox states are stored under `_flags`, keybinds under
`_keybinds`. The config is loaded automatically when `src.lua` runs.

## 8. Theming

`getgenv().NOREPINE_THEME` holds the palette:

| Key | Meaning |
|-----|---------|
| `Window` | Main window background. |
| `Panel` | Module card background. |
| `PanelHover` | Hovered panel. |
| `Panel2` | Search box / inputs. |
| `Track` | Toggle & slider tracks. |
| `Knob` | Toggle knob (on). |
| `Muted` | Knob (off) / slider fill. |
| `Stroke` | Outlines. |
| `Text`, `TextSoft`, `TextBody`, `TextDim` | Text shades. |
| `Accent` | Default accent color. |

Files are stored in `Norepine/` (configs) and `Norepine/backgrounds/`
(custom backgrounds).
