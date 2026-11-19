--[[
    March UI Library — Test / Demo UI
    ----------------------------------------------------------------
    Exercises every public component exposed by src.lua:

        Library.new()                Library.SendNotification()
        Library:load()               Library:UIVisiblity()
        Library:change_visiblity()   Library:Update1Run()
        TabManager:create_module()
        ModuleManager:create_paragraph / create_text / create_textbox /
                      create_checkbox / create_divider / create_slider /
                      create_dropdown / create_feature
        TextManager:Set()

    Place this file next to src.lua, then require it from your executor.
    Adjust the require path below if your layout differs.
    Press INSERT (or click the top-left minimize button) to toggle the menu.
]]

-- ---------------------------------------------------------------------------
-- Compatibility shim
-- ---------------------------------------------------------------------------
-- src.lua calls a global `tablein(...)` inside convertStringToTable(), which is
-- used by multi-select dropdowns. Most executors define it, but this keeps the
-- demo portable. Safe no-op if your environment already provides it.
tablein = tablein or table.insert

-- ---------------------------------------------------------------------------
-- Load the library
-- ---------------------------------------------------------------------------
-- Remote loader (main.lua) injects the library into getgenv(); in Roblox Studio
-- you can simply drop both files together and require src.lua directly.
local Library = getgenv().MAINUI_LIBRARY or require(script.Parent.src)
local GG = getgenv().GG

local ICONS = {
    home     = "rbxassetid://107819132007001",
    settings = "rbxassetid://79095934438045",
    info     = "rbxassetid://84232453189324",
}

local function log(...)
    print("[MarchTest]", ...)
end

local UI = Library.new()

-- ===========================================================================
-- TAB 1: MAIN
-- ===========================================================================
local mainTab = UI:create_tab("Main", ICONS.home)

-- ---------------------------------------------------------------------------
-- Module: Movement (left column) — sliders, checkbox, textbox, dropdown
-- ---------------------------------------------------------------------------
local movement = mainTab:create_module({
    title       = "Movement",
    description = "Player movement controls",
    flag        = "test_movement",
    callback    = function(state)
        log("Movement module:", state and "expanded" or "collapsed")
    end,
})

local humanoid = nil
task.spawn(function()
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
end)

movement:create_slider({
    title          = "Walk Speed",
    flag           = "test_walkspeed",
    minimum_value  = 16,
    maximum_value  = 200,
    value          = 16,
    round_number   = true,
    callback       = function(value)
        log("Walk speed set to", value)
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})

movement:create_slider({
    title          = "Jump Power",
    flag           = "test_jumppower",
    minimum_value  = 0,
    maximum_value  = 200,
    value          = 50,
    round_number   = true,
    callback       = function(value)
        log("Jump power set to", value)
        if humanoid then
            humanoid.JumpPower = value
        end
    end,
})

movement:create_checkbox({
    title    = "Noclip",
    flag     = "test_noclip",
    callback = function(state)
        log("Noclip:", state and "on" or "off")
    end,
})

movement:create_textbox({
    title       = "Display Name",
    flag        = "test_displayname",
    placeholder = "Type something and press Enter...",
    callback    = function(text)
        log("Display name changed to:", text)
    end,
})

movement:create_divider({
    title     = "Extra",
    showtopic = true,
})

movement:create_dropdown({
    title           = "Fly Mode",
    flag            = "test_flymode",
    options         = { "Off", "Smooth", "Instant", "Velocity" },
    maximum_options = 4,
    callback        = function(option)
        log("Fly mode:", option)
    end,
})

-- ---------------------------------------------------------------------------
-- Module: Information (right column) — paragraph, live text, multi-dropdown
-- ---------------------------------------------------------------------------
local liveText

local info = mainTab:create_module({
    title       = "Information",
    description = "Text elements & live updates",
    section     = "right",
    flag        = "test_info",
    callback    = function(state)
        log("Info module:", state and "expanded" or "collapsed")
        if liveText then
            liveText:Set({
                text = "Info module is now " .. (state and "EXPANDED" or "COLLAPSED") .. ".",
            })
        end
    end,
})

info:create_paragraph({
    title       = "Welcome",
    text        = "This paragraph demonstrates automatic height sizing and word wrapping inside a module.",
    customScale = 72,
})

liveText = info:create_text({
    text         = "Expand the module header to see this text update.",
    CustomYSize  = 32,
    customScale  = 42,
})

info:create_divider({
    title       = "Multi select",
    showtopic   = true,
})

info:create_dropdown({
    title           = "Permissions",
    flag            = "test_permissions",
    options         = { "Fly", "Noclip", "Speed", "ESP", "Aimbot" },
    maximum_options = 5,
    multi_dropdown  = true,
    callback        = function(option)
        log("Permission toggled:", option)
    end,
})

-- ---------------------------------------------------------------------------
-- Module: Features (left column) — keybind rows with check / button
-- ---------------------------------------------------------------------------
local features = mainTab:create_module({
    title       = "Features",
    description = "Keybinds, toggles & buttons",
    flag        = "test_features",
    callback    = function(state)
        log("Features module:", state and "expanded" or "collapsed")
    end,
})

features:create_feature({
    title           = "Auto Farm",
    flag            = "test_autofarm",
    default         = "Unknown",
    callback        = function(enabled)
        log("Auto Farm:", enabled and "enabled" or "disabled")
    end,
    button_callback = function()
        log("Auto Farm button clicked")
        Library.SendNotification({
            title    = "Auto Farm",
            text     = "Button callback fired successfully.",
            duration = 4,
        })
    end,
})

features:create_feature({
    title           = "Teleport",
    flag            = "test_teleport",
    default         = "Unknown",
    disablecheck    = true,
    button_callback = function()
        log("Teleport button clicked")
    end,
})

-- ===========================================================================
-- TAB 2: SETTINGS
-- ===========================================================================
local settingsTab = UI:create_tab("Settings", ICONS.settings)

-- ---------------------------------------------------------------------------
-- Module: Appearance (left column)
-- ---------------------------------------------------------------------------
local appearance = settingsTab:create_module({
    title       = "Appearance",
    description = "Customize this interface",
    flag        = "test_appearance",
    callback    = function(state)
        log("Appearance module:", state and "expanded" or "collapsed")
    end,
})

appearance:create_slider({
    title          = "Transparency (%)",
    flag           = "test_transparency",
    minimum_value  = 0,
    maximum_value  = 100,
    value          = 5,
    round_number   = true,
    callback       = function(value)
        -- Update1Run expects a string; "nil" restores the library default.
        UI:Update1Run(tostring(value / 100))
    end,
})

appearance:create_checkbox({
    title    = "Enable Notifications",
    flag     = "test_enable_notifs",
    callback = function(state)
        log("Notifications:", state and "enabled" or "disabled")
    end,
})

appearance:create_divider({
    title     = "Accent",
    showtopic = true,
})

appearance:create_dropdown({
    title           = "Theme Accent",
    flag            = "test_themeaccent",
    options         = { "Blue", "Red", "Green", "Purple" },
    maximum_options = 4,
    callback        = function(option)
        log("Theme accent:", option)
    end,
})

-- ---------------------------------------------------------------------------
-- Module: Notifications (right column)
-- ---------------------------------------------------------------------------
local notifications = settingsTab:create_module({
    title       = "Notifications",
    description = "Test the toast system",
    section     = "right",
    flag        = "test_notif_module",
    callback    = function(state)
        log("Notifications module:", state and "expanded" or "collapsed")
    end,
})

notifications:create_text({
    text        = "Use the buttons below to fire notifications in different styles.",
    CustomYSize = 34,
    customScale = 42,
})

notifications:create_feature({
    title           = "Success Toast",
    flag            = "test_toast_success",
    default         = "Unknown",
    disablecheck    = true,
    button_callback = function()
        Library.SendNotification({
            title    = GG.Language.Success,
            text     = "Operation completed successfully.",
            duration = 5,
        })
    end,
})

notifications:create_feature({
    title           = "Error Toast",
    flag            = "test_toast_error",
    default         = "Unknown",
    disablecheck    = true,
    button_callback = function()
        Library.SendNotification({
            title    = GG.Language.Error,
            text     = "Something went wrong. This is only a test.",
            duration = 5,
        })
    end,
})

-- ---------------------------------------------------------------------------
-- Module: Background (right column) — only in newer builds of src.lua
-- ---------------------------------------------------------------------------
if Library.create_background_settings then
    local bgModule = settingsTab:create_module({
        title       = "Background",
        description = "Custom image / video layer",
        section     = "right",
        flag        = "test_background",
        callback    = function(state)
            log("Background module:", state and "expanded" or "collapsed")
        end,
    })

    local bgOk, bgErr = pcall(function()
        Library:create_background_settings(bgModule)
    end)
    if not bgOk then
        log("Background controls unavailable:", bgErr)
    end
end

-- ===========================================================================
-- TAB 3: ABOUT
-- ===========================================================================
local aboutTab = UI:create_tab("About", ICONS.info)

local about = aboutTab:create_module({
    title       = "March Test UI",
    description = "Component showcase",
    flag        = "test_about",
    callback    = function(state)
        log("About module:", state and "expanded" or "collapsed")
    end,
})

about:create_paragraph({
    title       = "Controls",
    text        = "INSERT — toggle menu visibility\nMousedown — drag the window\nRight-click a module/checkbox — assign a keybind\nBackspace while binding — clear the keybind",
    customScale = 96,
})

about:create_divider({
    title       = "Status",
    showtopic   = true,
})

about:create_text({
    text         = "All components initialized. Check the output console for callback logs.",
    CustomYSize  = 34,
    customScale  = 42,
})

-- ===========================================================================
-- Finalize — preload assets, detect device, scale, open the window & blur.
-- ===========================================================================
UI:load()

Library.SendNotification({
    title    = "March Test UI",
    text     = "Demo loaded. Press INSERT to show/hide the menu.",
    duration = 6,
})

return UI
