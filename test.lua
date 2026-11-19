tablein = tablein or table.insert

local Library = getgenv().MAINUI_LIBRARY or require(script.Parent.src)
local TweenService = game:GetService("TweenService")
local UI = Library.new()

local ICONS = {
    Combat     = "rbxassetid://10734975486",
    Detections = "rbxassetid://10734951847",
    Visuals    = "rbxassetid://10723346959",
    Player     = "rbxassetid://10747373176",
    Sword      = "rbxassetid://10734909540",
    Avatar     = "rbxassetid://10747373426",
    World      = "rbxassetid://10723404337",
    Blatant    = "rbxassetid://10734962068",
    Misc       = "rbxassetid://10734950309",
    Configs    = "rbxassetid://10723387563",
    Gui        = "rbxassetid://10709781717"
}

local function noop() end

do
    local flags = Library._config._flags
    flags.z_compact = true
    flags.z_3d_modules = true
    flags.z_title_sweep = true
    flags.z_pill_sweep = true
    flags.z_bg_enabled = true
    flags.z_theme = "Pure Black"
end

local TABS = { "Combat", "Detections", "Visuals", "Player", "Sword",
               "Avatar", "World", "Blatant", "Misc", "Configs", "Gui" }

local tabs = {}
for _, name in ipairs(TABS) do
    tabs[name] = UI:create_tab(name, ICONS[name])
end

local guiTab
do
    local tabContainer = UI._ui.Container.Handler.Tabs
    for _, object in ipairs(tabContainer:GetChildren()) do
        if object.Name == "Tab" and object:FindFirstChild("TextLabel")
            and object.TextLabel.Text == "Gui" then
            guiTab = object
            break
        end
    end
end

local function activateGui()
    local handler = UI._ui.Container.Handler
    local pin = handler.Pin

    for _, object in ipairs(handler.Tabs:GetChildren()) do
        if object.Name == "Tab" then
            local active = (object == guiTab)
            local info = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            TweenService:Create(object, info, {
                BackgroundTransparency = active and 0.5 or 1
            }):Play()

            local label = object:FindFirstChild("TextLabel")
            if label then
                TweenService:Create(label, info, {
                    TextTransparency = active and 0.2 or 0.7,
                    TextColor3 = active
                        and Color3.fromRGB(246, 246, 249)
                        or Color3.fromRGB(255, 255, 255)
                }):Play()
            end

            local icon = object:FindFirstChild("Icon")
            if icon then
                TweenService:Create(icon, info, {
                    ImageTransparency = active and 0.2 or 0.8
                }):Play()
            end

            if active then
                TweenService:Create(pin, info, {
                    Position = UDim2.fromScale(0.026, 0.142 + object.LayoutOrder * 0.0626)
                }):Play()
            end
        end
    end

    local sections = handler.Sections:GetChildren()
    for i, section in ipairs(sections) do
        section.Visible = (i >= #sections - 1)
    end
end

activateGui()

local gui = tabs.Gui

local interface = gui:create_module({
    title = "Interface",
    description = "Window behavior",
    flag = "z_interface",
    callback = noop
})

local toggles = {
    { "Hide on minimized",      "z_hide_min",      false },
    { "Start minimized",        "z_start_min",     false },
    { "Compact when minimized", "z_compact",       true  },
    { "3D Modules",             "z_3d_modules",    true  },
    { "Title sweep FX",         "z_title_sweep",   true  },
    { "Pill sweep FX",          "z_pill_sweep",    true  },
    { "Keybind list",           "z_keybind_list",  false },
}

for _, row in ipairs(toggles) do
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

local notifications = gui:create_module({
    title = "Notifications",
    description = "Where toast appear",
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

local appearance = gui:create_module({
    title = "Appearance",
    description = "Customize the menu colors",
    section = "right",
    flag = "z_appearance",
    callback = noop
})

appearance:create_dropdown({
    title = "Theme",
    flag = "z_theme",
    options = {
        "Halloween", "Pure Black", "Deep Ocean",
        "Crimson Eclipse", "Sakura Midnight"
    },
    maximum_options = 5,
    callback = function(option)
        if option == "Pure Black" then
            Library:SetAccentColor(Color3.fromRGB(246, 246, 249))
        end
    end
})

appearance:create_text({ text = "Main color", CustomYSize = 22, customScale = 32 })
appearance:create_text({ text = "Secondary",  CustomYSize = 22, customScale = 32 })

local background = gui:create_module({
    title = "Background",
    description = "Image, GIF or video behind the menu",
    flag = "z_background",
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

for _, manager in ipairs({ interface, notifications, appearance, background }) do
    pcall(function() manager:change_state(true) end)
end

for _, object in ipairs(UI._ui:GetDescendants()) do
    if object.Name == "KeybindBox" and object:IsA("Frame") and object.Parent then
        object.Visible = false
    elseif object.Name == "Keybind" and object:IsA("Frame")
        and object.Parent and object.Parent.Name == "Header" then
        object.Visible = false
    elseif object:IsA("TextLabel") and object.Text == "LeftControl" then
        object.Size = UDim2.fromOffset(70, 15)
    elseif object:IsA("ImageLabel") and object.Name == "Icon"
        and object.Parent and object.Parent.Name == "Header" then
        object.Visible = false
    end
end

UI:load()
activateGui()
return UI
