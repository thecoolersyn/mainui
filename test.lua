tablein = tablein or table.insert

local Library = getgenv().NOREPINE_LIB or require(script.Parent.src)
local TweenService = game:GetService("TweenService")
local UI = Library.new()

local TABS = { "Combat", "Detections", "Visuals", "Player", "Sword",
               "Avatar", "World", "Blatant", "Misc", "Configs", "Gui" }

local tabs = {}
for _, name in ipairs(TABS) do
    tabs[name] = UI:create_tab(name)
end

local function noop() end

-- Left column: Interface — no toggle, content always shown
local interface = tabs.Combat:create_module({
    title = "Interface",
    description = "Window behavior",
    flag = "z_interface",
    no_toggle = true,
    rebind = true,
    callback = noop
})

for _, row in ipairs({
    { "Hide on minimized",      "z_hide_min",      false },
    { "Start minimized",        "z_start_min",     false },
    { "Compact when minimized", "z_compact",       true  },
    { "3D Modules",             "z_3d_modules",    true  },
    { "Title sweep FX",         "z_title_sweep",   true  },
    { "Pill sweep FX",          "z_pill_sweep",    true  },
    { "Keybind list",           "z_keybind_list",  false },
}) do
    interface:create_checkbox({
        title = row[1],
        flag = row[2],
        callback = noop,
        _defaultState = row[3]
    })
end

interface:create_feature({
    title = "Toggle key",
    flag = "z_toggle_key",
    default = "LeftControl",
    disablecheck = true,
    button_callback = noop
})

-- Right column: Notifications
local notifications = tabs.Combat:create_module({
    title = "Notifications",
    description = "Where toasts appear",
    section = "right",
    flag = "z_notifications",
    callback = noop
})

notifications:create_dropdown({
    title = "Position",
    flag = "z_toast_position",
    options = { "Right Bottom", "Right Top", "Left Bottom", "Left Top" },
    maximum_options = 4,
    callback = noop
})

notifications:create_text({ text = "Preview", CustomYSize = 26, customScale = 38 })
notifications:create_text({ text = "Preview (Content)", CustomYSize = 26, customScale = 38 })

-- Right column: Appearance
local appearance = tabs.Combat:create_module({
    title = "Appearance",
    description = "Customize the menu colors",
    section = "right",
    flag = "z_appearance",
    callback = noop
})

appearance:create_dropdown({
    title = "Theme",
    flag = "z_theme",
    options = { "Halloween", "Pure Black", "Deep Ocean", "Crimson Eclipse", "Sakura Midnight" },
    maximum_options = 5,
    callback = function(option)
        if option == "Pure Black" then
            Library:SetAccentColor(Color3.fromRGB(246, 246, 249))
        end
    end
})

appearance:create_text({ text = "Main color", CustomYSize = 22, customScale = 32 })
appearance:create_text({ text = "Secondary",  CustomYSize = 22, customScale = 32 })

-- Background module (left column)
local background = tabs.Combat:create_module({
    title = "Background",
    description = "Image, GIF or video behind the menu",
    flag = "z_background",
    no_toggle = true,
    rebind = false,
    callback = noop
})

background:create_checkbox({
    title = "Enabled",
    flag = "z_bg_enabled",
    callback = noop
})

background:create_dropdown({
    title = "Media",
    flag = "z_bg_media",
    options = { "None", "Image", "Video" },
    maximum_options = 3,
    callback = noop
})

background:create_slider({
    title = "Opacity",
    flag = "z_bg_opacity",
    minimum_value = 0,
    maximum_value = 1,
    value = 1,
    callback = noop
})

-- Demo: a toggle that reveals a dependent double-point slider. The slider is
-- hidden and its callback is suppressed until "Randomized accuracy" is on.
local accuracy = tabs.Combat:create_module({
    title = "Accuracy",
    description = "Toggle-gated range slider",
    section = "right",
    flag = "z_accuracy",
    no_toggle = true,
    rebind = false,
    callback = noop
})
accuracy:create_checkbox({
    title = "Randomized accuracy",
    flag = "z_rand_acc",
    callback = noop
})
accuracy:create_slider({
    title = "Accuracy range",
    flag = "z_acc_range",
    minimum_value = 0,
    maximum_value = 100,
    value = 25,
    value2 = 75,
    double_point = true,
    require_flag = "z_rand_acc",
    callback = function(min, max) end
})

for _, manager in ipairs({ interface, notifications, appearance, background }) do
    pcall(function() manager:change_state(true) end)
end

UI:load()
return UI
