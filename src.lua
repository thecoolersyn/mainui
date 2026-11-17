getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

-- Replace the SelectedLanguage with a reference to GG.Language
local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        tablein(result, trimmedValue)
    end

    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_March = CoreGui:FindFirstChild('March')

if old_March then
    Debris:AddItem(old_March, 0)
end

if not isfolder("March") then
    makefolder("March")
end


local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)


local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)


local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur


function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end


function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end


function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end


function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end


function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)  -- Use a thin part
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder

    -- Create a SpecialMesh to simulate the acrylic blur effect
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  -- Use Brick mesh or another type suitable for the effect
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  -- Small offset to prevent z-fighting
    specialMesh.Parent = part

    self._root = part  -- Store the part as root
end


function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    
    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end


function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    
    task.spawn(update)
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end


function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end


local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('March/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile('March/'..file_name..'.json') then
                self:save(file_name, config)
        
                return
            end
        
            local flags = readfile('March/'..file_name..'.json')
        
            if not flags then
                self:save(file_name, config)
        
                return
            end

            return HttpService:JSONDecode(flags)
        end)
    
        if not success_load then
            warn('failed to load config', result)
        end
    
        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        return result
    end
}, Config)

-- ========================================================================= --
--  The former media-upload background manager was replaced by the self-     --
--  contained graphical renderer defined below (Appearance / GraphicBackground). --
-- ========================================================================= --



local Library = {
    _config = Config:load(game.GameId),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library

-- ========================================================================= --
--  APPEARANCE SYSTEM — themes, visual styles, effects and embedded assets.   --
--  Everything lives inside src.lua: no external modules or asset files.      --
-- ========================================================================= --

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local function rgbarr(t)
    return Color3.fromRGB(t[1], t[2], t[3])
end

local function ckey(c)
    return math.floor(c.R * 255 + 0.5) .. ',' .. math.floor(c.G * 255 + 0.5) .. ',' .. math.floor(c.B * 255 + 0.5)
end

local function typeof_color(value)
    if typeof then
        return typeof(value) == 'Color3'
    end
    return type(value) == 'userdata'
end

local function hex_to_color(value)
    if type(value) ~= 'string' then return nil end
    local hex = value:gsub('#', ''):gsub('%s', '')
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return rgb(r, g, b)
end

local function color_to_hex(color)
    return string.format('#%02X%02X%02X',
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5))
end

-- Mutable token table. All colour assignments in the original library were
-- rewritten to reference these fields, so a theme change recolours live UI.
local Theme = {
    main      = rgb(12, 13, 15),
    secondary = rgb(22, 28, 38),
    accent    = rgb(152, 181, 255),
    stroke    = rgb(52, 66, 89),
    text      = rgb(255, 255, 255),
    subtext   = rgb(209, 222, 255),
    panel     = rgb(32, 38, 51),
    panelHover= rgb(42, 50, 66),
    toggleOff = rgb(66, 80, 115),
    text2     = rgb(210, 210, 210),
    muted     = rgb(180, 180, 180),
    muted2    = rgb(79, 79, 79)
}

local THEMES = {
    Midnight = {
        main={12,13,15}, secondary={22,28,38}, accent={152,181,255}, stroke={52,66,89},
        text={255,255,255}, subtext={209,222,255}, panel={32,38,51}, panelHover={42,50,66},
        toggleOff={66,80,115}, text2={210,210,210}, muted={180,180,180}, muted2={79,79,79}
    },
    Obsidian = {
        main={8,8,10}, secondary={18,18,22}, accent={225,225,235}, stroke={70,70,82},
        text={245,245,250}, subtext={200,200,220}, panel={28,28,33}, panelHover={40,40,47},
        toggleOff={80,80,92}, text2={215,215,225}, muted={170,170,185}, muted2={80,80,92}
    },
    Dracula = {
        main={40,42,54}, secondary={45,47,62}, accent={255,121,198}, stroke={98,84,150},
        text={248,248,242}, subtext={189,147,249}, panel={54,56,72}, panelHover={68,70,88},
        toggleOff={98,84,150}, text2={230,220,240}, muted={180,170,200}, muted2={98,84,150}
    },
    Nord = {
        main={46,52,64}, secondary={59,66,82}, accent={136,192,208}, stroke={76,86,106},
        text={236,239,244}, subtext={143,188,187}, panel={67,76,94}, panelHover={80,90,110},
        toggleOff={76,86,106}, text2={216,222,236}, muted={160,175,195}, muted2={76,86,106}
    },
    Catppuccin = {
        main={30,30,46}, secondary={49,50,68}, accent={203,166,247}, stroke={88,91,112},
        text={243,224,215}, subtext={166,173,200}, panel={49,50,68}, panelHover={65,66,86},
        toggleOff={88,91,112}, text2={230,210,205}, muted={175,170,190}, muted2={88,91,112}
    },
    AMOLED = {
        main={0,0,0}, secondary={8,8,8}, accent={0,255,136}, stroke={30,42,36},
        text={255,255,255}, subtext={140,255,200}, panel={14,18,16}, panelHover={24,30,26},
        toggleOff={30,42,36}, text2={215,235,225}, muted={150,190,175}, muted2={30,42,36}
    },
    Frost = {
        main={13,25,38}, secondary={20,40,58}, accent={127,219,255}, stroke={64,112,150},
        text={235,250,255}, subtext={168,220,255}, panel={25,50,72}, panelHover={34,64,88},
        toggleOff={64,112,150}, text2={215,240,255}, muted={155,195,220}, muted2={64,112,150}
    },
    Emerald = {
        main={10,20,18}, secondary={16,34,30}, accent={46,230,168}, stroke={40,100,82},
        text={232,255,246}, subtext={140,230,196}, panel={22,48,42}, panelHover={30,62,54},
        toggleOff={40,100,82}, text2={210,240,228}, muted={150,200,180}, muted2={40,100,82}
    },
    Crimson = {
        main={24,10,14}, secondary={40,16,22}, accent={255,59,92}, stroke={110,40,55},
        text={255,238,240}, subtext={255,160,175}, panel={52,22,30}, panelHover={68,30,40},
        toggleOff={110,40,55}, text2={245,215,220}, muted={210,160,170}, muted2={110,40,55}
    }
}

-- Each visual style is a complete graphical identity: gradient, lighting,
-- decorations, particle field and motion — not just a colour swap.
local STYLES = {
    Halloween = {
        colors = { top={22,6,36}, bottom={78,16,98}, glow={255,112,24} },
        surface = 0.13,
        glows = { {pos={0.16,0.22}, size=460, alpha=0.42}, {pos={0.84,0.76}, size=400, alpha=0.36} },
        decos = {
            {asset='dec_witchhat', pos={0.09,0.13}, size=150, rot=-18},
            {asset='dec_cobweb', pos={0.9,0.08}, size=190, rot=0, alpha=0.7},
            {asset='dec_cobweb', pos={0.05,0.72}, size=150, rot=170, alpha=0.6},
            {asset='dec_skull', pos={0.9,0.84}, size=92, rot=14, alpha=0.9},
            {asset='dec_moon', pos={0.72,0.16}, size=74, rot=0, alpha=0.85, color={255,190,110}}
        },
        extras = {
            {asset='dec_glow', pos={0.5,0.32}, size=520, color={255,90,20}, alpha=0.32, anim='float', amp=0.01, speed=0.5}
        },
        particle = { asset='dec_particle', color={255,142,42}, count=26, size={3,8}, vx=0.012, vy=0.035, drift=0.012, alpha=0.35 }
    },
    ['Deep Ocean'] = {
        colors = { top={2,10,32}, bottom={8,54,94}, glow={38,190,255} },
        surface = 0.14,
        glows = { {pos={0.28,0.12}, size=520, alpha=0.4}, {pos={0.72,0.86}, size=480, alpha=0.32} },
        decos = {
            {asset='dec_bubble', pos={0.1,0.2}, size=64, rot=0, alpha=0.55},
            {asset='dec_bubble', pos={0.87,0.3}, size=92, rot=0, alpha=0.4},
            {asset='dec_bubble', pos={0.18,0.82}, size=48, rot=0, alpha=0.5},
            {asset='dec_wave', pos={0.5,0.92}, size=520, rot=0, alpha=0.35}
        },
        extras = {
            {asset='dec_glow', pos={0.5,0.04}, size=620, color={120,235,255}, alpha=0.3, anim='float', amp=0.015, speed=0.35}
        },
        particle = { asset='dec_bubble', color={150,220,255}, count=22, size={6,18}, vx=0.008, vy=0.055, drift=0.02, alpha=0.45 }
    },
    ['Liquid Glass'] = {
        colors = { top={28,34,52}, bottom={14,20,36}, glow={180,220,255} },
        surface = 0.18,
        glows = { {pos={0.2,0.18}, size=480, alpha=0.35, color={170,200,255}}, {pos={0.8,0.8}, size=420, alpha=0.3, color={210,170,255}} },
        decos = {
            {asset='dec_glass', pos={0.12,0.24}, size=180, rot=-12, alpha=0.4},
            {asset='dec_glass', pos={0.88,0.72}, size=220, rot=14, alpha=0.34},
            {asset='dec_glass', pos={0.5,0.5}, size=340, rot=0, alpha=0.12}
        },
        extras = {
            {asset='dec_glow', pos={0.3,0.7}, size=560, color={200,225,255}, alpha=0.26, anim='float', amp=0.012, speed=0.4}
        },
        particle = { asset='dec_star', color={220,235,255}, count=10, size={3,6}, vx=0.006, vy=0.012, drift=0.008, alpha=0.3 }
    },
    Neon = {
        colors = { top={12,4,26}, bottom={30,6,52}, glow={255,64,220} },
        surface = 0.12,
        glows = { {pos={0.14,0.2}, size=440, alpha=0.42, color={255,60,200}}, {pos={0.86,0.78}, size=440, alpha=0.38, color={80,180,255}} },
        decos = {
            {asset='dec_ring', pos={0.1,0.78}, size=180, rot=0, alpha=0.45},
            {asset='dec_ring', pos={0.9,0.18}, size=140, rot=0, alpha=0.4, color={90,200,255}},
            {asset='dec_star', pos={0.5,0.1}, size=46, rot=0, alpha=0.7}
        },
        extras = {
            {asset='dec_glow', pos={0.5,0.5}, size=600, color={255,80,220}, alpha=0.26, anim='float', amp=0.02, speed=0.7}
        },
        particle = { asset='dec_particle', color={255,120,230}, count=24, size={2,6}, vx=0.014, vy=0.026, drift=0.014, alpha=0.4 }
    },
    Minimal = {
        colors = { top={20,21,27}, bottom={10,11,16}, glow={130,150,190} },
        surface = 0.1,
        glows = { {pos={0.5,0.05}, size=560, alpha=0.18, color={140,160,200}} },
        decos = {},
        extras = {
            {asset='dec_glow', pos={0.78,0.84}, size=420, color={110,140,190}, alpha=0.14, anim='float', amp=0.008, speed=0.25}
        },
        particle = { asset='dec_particle', color={190,200,220}, count=8, size={2,4}, vx=0.004, vy=0.008, drift=0.004, alpha=0.25 }
    },
    Aurora = {
        colors = { top={12,4,32}, bottom={52,14,92}, glow={172,92,255} },
        surface = 0.12,
        glows = { {pos={0.2,0.24}, size=540, alpha=0.44, color={150,70,255}}, {pos={0.82,0.72}, size=500, alpha=0.4, color={90,120,255}} },
        decos = {},
        extras = {
            {asset='dec_aurora', pos={0.5,0.18}, size=920, color={170,110,255}, alpha=0.5, anim='float', amp=0.03, speed=0.36},
            {asset='dec_aurora', pos={0.5,0.72}, size=860, color={90,180,255}, alpha=0.38, anim='float', amp=0.025, speed=0.24},
            {asset='dec_glow', pos={0.3,0.4}, size=460, color={210,140,255}, alpha=0.3, anim='float', amp=0.02, speed=0.5}
        },
        particle = { asset='dec_star', color={220,210,255}, count=30, size={2,7}, vx=0.006, vy=0.014, drift=0.01, alpha=0.5 }
    }
}

-- Embedded PNG assets (generated locally during development, base64 encoded
-- here so the published repository stays a single self-contained file).
local ASSET_DATA = {
    dec_aurora = 
        "iVBORw0KGgoAAAANSUhEUgAAAQAAAACACAYAAADktbcKAAAVEElEQVR42u1d0XbjSgqEnvn8/Zz9vDtiX/buZnSlbigKWs7I5+TElp3EkVVFUdC0/uvfJmIiaiIq//3Oun9xTBavE/nncxJ4LIId+/t2fu5/90/P/3b86hj5Zqc/YOfn9fRa/f01ptfPXR2fHrt4zW/P" ..
        "/f95Pb1eL177v2P2z58/v87Oz9/ct4vjVz9rl79n/run92X2O2avk/uf/3pMJq+Xi9esPmcRkZ/y3t4b76bBxx7O1CBP6uKYXfxe+1M/sJcA3ls18BFSmL2OCdY/ngxeAnhvLOArQABe8HuJQBcAtsnv/iPJ4CWA91YNfIYaiBIBmi7ckYG9BPDeXtBfP0YJIAP+WdSf" ..
        "Pb5TCCsy+Laq4CWA98YEvhKIwEMItlAD6gCqhwyuwP+tyOAlgPeGynwPAWRTAs9780T7lQrwEMaKDD6SEF4CeG8o8CMEgKgArwKYRX8G8CNpwcepg5cA3hsK/Ox3tgLQiYQ/k8CMDKKk4CGDxxLCSwDvjQl8BPxIc9As6l6B/+7YCvBZMpgRwiOI4SWAF/gZ4LNIIEIE" ..
        "FlABKwWgACkwSo0m9d3jLwG8N6qjrwUkgKQA6jTn7MIfMIAEukihQxXoSwAv6JHIvzoWJYQsCXic+QzoV6VDlnm4XRX8/CbdTirEBXd/EPBXBJC571UD3r6A1Wfmyf8jJGCAaVhBDG0pwBNdS33Y37IPI8FoLT9DAigRoCpg1pRjExVwPh4lgUg5cdWlKEnioCqAbtdS" ..
        "H04Is46zJxBEdBVdxuDzgj1CBNk0wBZqQAKAnz3nTRnYXsEWAtjtWupDyMBAwDNVhEp95M8CP0IMbDMwQwAzUmCTQEQFtKvMn86OKyUDp/Li73RpEUWgm6O+1+BDHjMIIOMBiDPyr4DvJYYMCUgjEShKAOyLmx3hdxgnTILYke8zor73mIcMOglgdgwlhhUJ3FUnxNGE" ..
        "5FWOWqUAKlxLVnTf2kCx2dH1EkA06nuAHzkeUQOSuBYz0j96f0UGslAACq4f0KoUYDzEvHoK+FcSTIvGUmXIMVvbz0R9RBF4fABx+FEe4EdAfxf5PeVBc7Qgr4aNsBcTaVQBVJctsuDXxpIe2iOeIQgmASDSH4n6DE8AUQKo/F8RAKoINKAGPFOHtNMErHYtq4HPKCka" ..
        "cf6cFrj9jOhfCX7vz1ebgJHozyQDCaiBVSrAUAEaTQEQEqh2/LUxBdDAxBnGgMrutt6I24+AP0sC3nIgo/yHPkaMwStC8A4V0W4FgJYuKktaHb6ABSbOsAii0/XvAr83HZilAswU4I4IPI+95OFRA7poXfZWjthl5UsF4CldIBJFmwmBlQ5EJr948zkrqPkz6vws8EeM" ..
        "wIgCsEAawAT/6rEG0gGvEsj6AspUAFVGRQTcDHMQceNXAEdIkuFZeBQACn4mAXjMQLYJ6E0B0GOoHyAOJVDVR6IMBZAtU2gxEWSqAAoMnoioAuScec4Lo9Gn4mvlBSAKIOIBRPP/u2OIOehVAnf/T1sfybkPwCtXnhD9q/4+A/haYOqgpT8k+lcTgrccmK0CsIHvJYOI" ..
        "Eti6CvcuBfCqAEYZMAt4ldouvuyGk5kPGO34y0h/5GtIbTUg2wHoJYJOJeDxNFoIYACmBaoE9KEkYM5xU5HNIph53ZOi/ygyA7MpANL15yEDthJYkcCjCGD2htmr2naRwMyBRcCvTSsktZEARuI1ElABrBQASQMipBAB/0yp7CQA9RJA1XZIKODZ1QAT/3pzBPzIYBXE" ..
        "/Mt2+0VBP4hewGpNQEUKECED788/PQ3QlQK4616K1ivR2v8OFRAhgOhjTS4Vzpb+ou29KOiH8NIAlgeARn5UIXiIYAcJaDYF8LxRNCojEb8iBagiAMZS4UzjT1XOPwiGYKYXwNsDEHX9swqA6QVUlNvLCKDS/KsmAO//xSIAaSYAhAQGgQi8agBRASz5j5JBpFmIQQKl" ..
        "rcA/QMaKLKtFU4AO8KMk8DQCyJKAV94ziCBbCmQSQEcqEMVVuwfgJQDkwq6M/lo8BTjyQXUQQKb8x1YAI0EC1QTAJIFsWdDjB1T4AIpMBEJVANvgyoJfm3L/ahUQrf9nSIAB+vGHEEBmzYAAAVa6+gBYucoO8FeagEZ6LuuboLX/q2NeI28EnvOSwHchAA8RoAqgrQrw" ..
        "A8hZmO5kpRLIkgEC9Mh5MlILcIXxNwjPVfYCeCcAdRCANw3I4qp0HkCUsSrXtncZgln3f0c+x4j+iOQfRAJgdAN6uwBRAjiEWxbc0RCkaBUg6wFUuv8VKwOrgG9NJiAz9/eQwGjyARAVwJD/x2n8F9sQrEyvQ6RwpQB2pgCdZUHEBGSQAKqaogbgFdiQvH8EyCBbDfCQ" ..
        "fUcJUInyP7MugDlDokwBWLP836EAKtQAMwVAFMBwkkAlAVSagJm8X8kewM5eAI1WASoVQEbuP8ED6E4DMiO/kRTAC/aRqApIUAV4ScC79NfzNRweQLYasKMUqJ+oAJj9ANFWSytOBaoUQLT05438I2EOoh6ASmwWAMvxZ5EAq8RetjfgD+cbZpgVGbOvMg3IGoAVCsDr" ..
        "ATDkP0oAKPizlQBvCuAhg4NMAsw0oMUDGEnXUoAaJSP6M0iAkQJUK4DZuWG5/1kCGAGVIQEfAK0CRFTAWBBBlASe4gNoVAF4SCCjArSJBDJVgEwKwKwERLsAs40/WbCjhiBbAWTk/4wIIiTAWBz0qD6AJ6QAiBkYHcvNyv+7TcBV+W8UEUBHGlBtAkbAPsAGIWnstE0T" ..
        "QLYZyDbJ/84yoJFMwYouwEjnH5sAEBWwWwHcgXqlBq6ei4wM6yKA8FoApCEoI2fRyN9pArKJAPFNGMM/EOOPpQbQXoDVRqsZD+BwEsGxII9ISvARCiC6HsDIHYAV5cDu6M9IAyJTgD0+QIQAZt+ZqUCmHThbAhwXZDAC5MBeHFRBAuUEUG0CdqUBDAKoqAboAwgAeY6l" ..
        "AJS0FDiqABhEIITUurUKEH2zVbvcVJmBLwFcPx5kEmA1BGVNQCT/jxCBBbyAzlKgZhuBGKsChWgAeneN+QQCsMIeAFb+fwfurAIY8qwU4AikAh5TsCoNYMzenG4M8mQC6Ij+350Asrk/kwRmKiByrq5+1ksCGeCPwLyAyJzAjiXBilQBKgkgMu46QwBIH8CTCcBbAlzV" ..
        "/++IIEICaDVATkDyXmMeY/Tqb9hCwg9AAYyEIdg5F4BSBqw2AZleQLSOHN13XiQ34MGKCSDa/YcCPtoPcBU5vV6TAJ2R5/9bFkoAJYInVgIU8QA8Sxk7CaCjH4BR/6/c/JG5BJgl/UfADDyD7XACI9Jbgu6BMCYqYDgVwiwdQJcGIz6AZpYD/0xIFuZ0m6wPwNobsAL4" ..
        "VX0AyKYfo0ABjFOkPb58RaLk6lxFzol3OfQIqICxKCNG5H9HCqBVVQBLMFO0/p9JA5gk0K0CGCVArwF4RwIRFWAi8usmIh7JIJPpjPz6dSzOB1MFiPDMdSsqA+pOE7AS/IzVgCjgs5OCvSsBGct/Eck/Tr/rHO2PRJ7MMgG9iui4OT8/vvz9g6ACOiduhUhhlgJ8ogeg" ..
        "D4/+GdLMXuxeBeAB/98y/9cN6A9gvHalCThTAmcyGKf7P778vysVwK4EPKIRiHFRs8GfmQ8Y3QkoQgLseW8eE5Ap/1dEYDcR3wP8A1CZqAcQmYp0JoM7ItAv52AEpgpJQ5t9mQLI5Coq+Br3LiOwwgBkGIHMCz262u8K/Of8fgZ+JPqzqgCRlCiiAo6b8xfpCZDE/20V" ..
        "+f9MAVR0A6L5f9YEVKC8Yo0+QGUKgLj/52j3KxD5V/n/If5ysySMQFQFeIng6tyK8JYGt1YBfhJyNGssAT5JAVT6ANE2YEbzz9nRP5LgzygAj0maOS8r+a8L8B8TlSXCXRUolX0APwhsxZ5zz1IAFR4AQwlEqgDoINDI6r8r4FeDP3NtZbyRu3PkAftwpA+rtQ4V8zZS" ..
        "nYCfoAB2VAF2K4BMvTti/p1LeV7ge+X/kTSZK8/NsSACdaQAR3IrtO0pwKd4ANV9AKgCkEROx1AAno63cSNTj4W5lwH/IfmSGFIFEAf4RpIIVk1F3s1aJDkTITP+PtQHUNUJGAV8x0CQbAmwQgGgNe+r6B8F+B3gmfIf9QDQTVIORxqgDuCPSZehZzs0cc5C0CzQ714T" ..
        "SQGsQM4+gQQyC4AY4DegCzDaASgBMEfve8B/SGzBGaMMyEwDVsfQFCCyLRot6nt2BnqiCVi1DkDIEZ/VDJRtApJTGc8S4PdKf+YagC4CyIB+BEEfGYWuXSnAX5OLh7EiEO0CjAyENELJxNNxuCsFiGwGahcr8Y4bEsgSAgL+6MwJZnokDvB6iSBrAGrgmmOmAL+97ooA" ..
        "ZjKSUdP2gjvaLlmxXbl3FR5zWbAGL3SP9DYngNFjiAcgjVUACfgAX5/3mIWoAoio3LI04G8CGE7nUhbljIjE3rnWPgN+CXyQCn44OvkZ+5LT2+JYJQlUGoAdBLACOyvyI/k/ogIMIYWfXxo/sls3aWLJbbatNrvzTsaTiH6g6MTb6ATcO0nOJoHvQACr6I5EfkYFQLsU" ..
        "QHTTBi2ouXfP20OGkyKgV1KVIjv+mkECrOif7YVn7pfgVQNRIvAoaWZvS0oBIKxV0XfP6qxDZqgrcIGJ4DmdgqVJzz54B4kEPDk/M/o/gQBWJMAq/3VUAdIKwLtxgxZM3ZEHm4DVKYAQUgBzSnVmzs8kAHFMBKoiAA8JVKQAFQvclgSwQwFUbr1VrQDY4Ffn/zLbCdcK" ..
        "KgI7CKCyTLqDBHZWAFyYQBWARwVUTN7p9ACY4NfkWgWWAvCCGZX9R4P8zzQDISRgBOB71fQWE/DTFUBlFWCn/I8oAHEAn6UCIqO/Mg1Aluwo9Y4KZxOAkEuAWtECfEcAAlQBnqQAugaVZtYvdCsAC0Zyhuw/BJuLx946zdsVyCIAIQVTxnwLdxXgr4QBWFUF6JL/jIVK" ..
        "2RmG1UbgQSaCTOmvMwWIrAuYLae2BPgj0b/SA7BMCpBtWDDBB3CwUwD9IBKIlgJRI9CAfD8i+9kbzkRbpaujfgUBMEnAMilAxATcoQIyaUB1JQAt73grAdEUgEkAXunvTQFYQ0FXwzYyZmA1AWxbDvxXcRdgFvyVaYCXBFgzC5Qwq4DREcggAET+M+bheas2FYbg0w3A" ..
        "MA7uUgBmxxLSDNTpATA2LamYXThLlbI+QCbaM+U/a7MZVj+APIwAWEpbqj0AZhWgK/pX7VnAIIGVT+ItBXpBG0kNVnP/V+9HpGbITNQIFOHJfGQAyEcTQPdW3JXg36UCop2AHvkvgbz8SNyvcP/ZOydFjECR+rz/YwhAmkzAp0T/6g1LKsuA4jDcogSAAp+1PTYzBcgo" ..
        "AJEe6b/dBIwQQLUJ+BQCqEoDGN2TKwLwlAOzoK+M/szNU9ndgZKU/uxmsZJWYNlYBXgJgFMFEDBqs4Ffuc8EoyEoYwhWy3/d1QhUQQDZSsDTPIAOAvAYgREzkEUCqPPP2DxFSSoAUQKfFv3hgSCfSAAdVYDuDUzZBBAFNCv6S6ICYMHeDbQnQAigR6O/F/zKXASEVgGe" ..
        "kgJU9gGgoN+hAKLgj6oBD/APx98WweYAGKF5Kwp+IS322VUBCJuAB/DG2QTAlP5WDP7K+n/GBBQwQh9JgjCS+7+DADJpgQRX/e1OASy6FkAe0AeQifzI2G1GP0A1AaDdgExVgOb+iAFoF/sgMAgABT8i/RlDY9tSACkoAe4igZ0+QOXehVkfICLtma5/Ztek2U5PdnOf" ..
        "nQqI4F1/HdcKVAY8APmfaQWOgLtS/lekAVJMmEwfgA14hvmHLOayYEOQkVIBFvg7KwBTBYB2ACq5CsAo/yFDQbMqgDXhBRmh7m0KQgF/BHP+bPOPgeA/K4HzMZYayID/cQrgV2AJMNMEREmgow+gGvxKrgKwVACj1s+U/7N83xxKQC8IYaUGMuRQ3f6rwi1/L6sAFSOL" ..
        "GNWATPSXIDiZ4NfiFCCqAtgdftnavwHXz50SWPkBd2QQIYAM+Lu6AEOdgFWjiy1hBlY3AXn/r64UwAhGoJDz+e7oH1kMZIvHZ0Lw+AAdBJBNE2mrAQ9wBgDrjVUAHx0JxgZ+ZRkQXRdQSQAieOkvM91Wb4hg5gXYReQ3AgF4qmid0R+uArA6lrwgzeb81uQBdMp/tgKQ" ..
        "DdFfkvV/CVScPEag1wuwQHrAlP+VJGDeFKByaqkRiYAl/6vSgAoTkJUGSFHkz4DfwOgvp6gvC/BbkAyETACdJGDRFEAe4AFUdQB2pQHdCiDTFCQPAL8Rzo1OSEAm4J+lApH0wApw1LYWIFuzrFQBT0gBUOCzd3q1jSSAGn7s7r9Z70QlCXhVAjuQbtkabJcJiBp/FVUA" ..
        "FgmwfJNsCiAJAugGvwUifhUJeA1Dk/rSn1aA/5wCVBoWiBH4BA8gE+13pAAIAQgZ+N4NXrKfpzkXyOjk9WxFYM4+hEcSAFq2iEy4ZXoC0cYRLTYCK0ggYwRmCUAkt8KvIvojxDCL/h4ykIBakEkX4kpBmrPlmZ4CHNJXAWCC3cCToYUqgNnc4dkiTICobMljrFq/JS9i" ..
        "JZiH6lASXpXgif7mWMTE+h+NSQCVrcAd0Z9JACzpz/YAGJ5A1OHPRn0rcLkVbCpS0vdZF+JqEZM4Zh/QB4Icjf3KLC9ACpkxSgAMn0TBJdToAiGRWrnfNcuRrQqypCABFTADP/OclCiAbgLouHh2EkBFOVAI4Bcg+meifnaeg5FyaNQsFMex1QrGNvD/TQDmkDLdBFDV" ..
        "+INEEM8HZ5sJQIKARXJ7docfM1J7SYFBBuJYa2COSUWrUWdbJgJFTAumBM9GfNY8AHMSgjR2dCELgyJEUAV8a1BrkSXDQrqGZwphpQBWwNfu8/U1BTDpW7FUQQKZVmArUgOeCw0tnZpw0wERbr7fLmcJMwQYwJ89P1MAqGlNXw5shdGflQ5I4XtQ8KKJgl+TSidTFRCC" ..
        "wVfR17+DEFhkEAG+BnY+st0eQDZXQSJ2FPDMkWAGjqDygl+TZUzvNupecHue+y7Az5CBTj4PdSgCW0R/cfYGlK0GXIGfUas0AhFUXGwWMJEEdHMzLq8lSABNETLtvPLhZKCkXoMZCXjWNWypAni7lqwxBahWAKgKiLi57POFKIGMsWffFPTeeQNW2Htg3ZOAZgoAdS3Z" ..
        "aUCnAlj9XzPDJurmVk1SRhuFXuDzyCAD9i0k8B/yl97g8QGrNAAAAABJRU5ErkJggg==",
    dec_bubble = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAACGklEQVR42u2bwVHEMAxFIw0FUMSeOVMBJVAERVAG9EAJVMB5uW4RdGBOmcloHEeSZVveSDMcdoeN/Z8l2VGUZQkLCws7sUHPwa5/6Yv7v0+P8HoXACSiR8AAr6J7wYDewjkCrK7TFcDepOlEP67p5eha" ..
        "b0/wrbn2EABHk+MI5gJpAQKsxR8Jp6ubs6PflsbtBoBOoiScI1oCYw+EBgK0El8jmgPDCgLOIp5edx2PCpZuwVArvodwjjdoPQFnFJ/zBq0n4GJwGustfm9cTRJE6erTmB8lnkLI5QSOF6Bmr/cifg+CJBRQ6voWJ7vWyVESCqi9KfGy+pz5lHSgZvXXwVJKN48QJF6A" ..
        "tYOmlG7eQJjsAjTz09jfigaAi/dcsBcGaBlr3nNBkxCY3bB3TW+k5XShJvt7N8luECEQAJS23fru8hwQHhAAzhEGph4wI4RqAPQ+YDYIrIpQqeLiEcL24KaqCKmesEzgCTldpjkgB8F7SKDFs7oShFHuXw2AFhMkN0IAcBkNgsb/Xlg/tJyEx0pR1aOxo91gcVAG42Z/" ..
        "FoDSbjAKQkrpZ/3jzqekA6UVlZFFESqafpauPrsiJHkU1Uv89vtSxcqkIpQrL3vLB7mOEc6BDi2Ki14gaIq5qD1G0nzQGgIAPOe+//xd3ms6RGCmHiGaC1YoNY1Sp+8Siz7B6BSNXuHoFo/3BeKNkXhn6LxvjYWFhZ3b/gFZ2AzTfHJ6IwAAAABJRU5ErkJggg==",
    dec_cobweb = 
        "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAHEElEQVR42u1dS67kIAxMLE7xDjuLOey7xswqUhSFgI0/ZYBlq7tDoDD+lO3j2GOPPfbYY489Vhzn84Pf339/97KsM2gvwdqjSH7083P+GXnoJWVG/wfpWVmfU7ib/vv77+/9mvDYxNExy+aHSoC3l3yC" ..
        "AW0RZtNnLIBWRibxnAg6IPZQAMDPz/nn2ujn5vYAYo/kVsB941sbfEmJN2mxTc7EZuAFgl4g9CiVWcGQWQHsAsD9xZ4K4FMX6N3I6/tP6XAHw5YOR6wn8LrrazrA171fOxGc01J79rb/dZ9DEjv6TRK0/AXcTXzTH7aEALAC7vf/tQlPi2BEN+gFYUaHVGolsHb/t0S2" ..
        "1cZs6eAAgPvi1k5ZCwTPzyw258vc3IAwigbWxO/98+d3LK6GHmBYS4jM14/YE/j1eU0nqOkHFgtYe76my3oGyVKOQdPkudB3EHCjixpA4PghsiiUlgeFOB67ngVqxQdaYjpCJK+sUBYNdH5t4FvQqBVkihTJq0U4y8hC1cT9ExAcEHjoB9qAOGZ1BXM+b7mGJZvJ+W0E" ..
        "YGpA0J6D5bsV6xf/sg64EgGRbZTdQ0mj9j9HtEvvaW//AZKH0lqysaOBI2Je42S8/Ye3+Jc+TxIcCwMA18zyBIFGuBjhTu55h1AJwH3x3slagCDb5nPNWKv3owg69qhOUHtmdvOsFdSCB4BEw5e+3JOS5qEoRvkmLD2UJJ2Itk+e80Jfymkmi2FUOmgAgqLTsLgg6Ln3" ..
        "LeILaAEgLUAQQmpWLwi4Sp+mNECnf7cA4QoAiWjnMIu4usas14KGQ+qUIJ1r7kno3D08RC/TMYujSbIGhJal+7bpmqd2Bv1AUzoQYl5+7TrQPBG910L21C8TJdCDrMFlFmmRRlfLNSRP/t2IrW+5ObVrYfbTfxwKlLARJjE32mfNCYjWDSKUTUIq21K77y1iB7Py/N2u" ..
        "AO5pGY0QeoLg7fqZtd4QIRRvklDOrQM+NWfKbIUm6Agu1yZ173oohllpaSkqhY6QJ61A0MNjsABCpKeRvLXm1v0eBQIOGGeKL1DkqR9FvYUkGAk0ZbI8rueRx4bfef1PupPmwkn/S2sOEmngLT2ezyPrk17juFn49SULqhVryHotnNohXM5iagd6kEK9PXNBCDOTpV/d" ..
        "+96T0ss8Ak3HLNXCrTZUy8/fm4votSm1tHeUQNOpkZww+jIWMf+eYpYI2cTRLCPqJRn2uGilp8q6RpBXGnfGIBOhBimsQIBWeMLjKvp6Z5q9rYt3KJkDbgSzkRARbV3HL+L0f3EdLIHQkniE2tzJMmk00vvWm83kNUeaucPXVzUTrwWWhLu1pGmPvkMZWCvaIjeCWSTN" ..
        "mbSWBoSo2Y46lJDoZaP5EVIg9Fo7lIW7pl3AyhoEltlMmv9Ns3T7lIhbD2aRdtSzR8pyfB2UicGqTS2LZhZF8A/cCkRo1+3tSRnXzkVEdvvWrgWup5OyNn7WPmkIzKKIsHOKK+CNYjYrs8hb4lCWfHavhlQSECDUBpZmM1GGSJd3vX6pJEDYfG7ZPMog7iPcuJLCVQib" ..
        "z/UfEOrGv4n5SAKHZuEqbx3gS1Ek1NPOySaOAAHivS/xH1Ak4+XrtCPdsz29kpFEP8dsLJkmb8UkHu2RdCQMn1+/K9k2nVtyxrLUTRbRH+YHeOPAW2bgeCe2RoBQG4CnRtOHKBvZ6zR+Fa6K4PZrPrNYt0ezruIRxeoZ6YaGFGgqKN43zQ6mnkROLxBYAf30SJj0Kn7s" ..
        "kVYWcRVZ/n+qaKD1KZFGGi3d1NbgolmqX2vG8iXWilVOQ8quYdnyCTSrhFjnOKYEgHehhBEmMUp207KZQehMYs+WeB7W11QA4Jwg60XWKJPvYXrTjO1QrCqUetUsStMwAr0Wf6sotcciW7XE2xJgoPEUGrMo0uNKM3fGQmLvfIEgkl8wLQAQizShSaawfgEeETzUYBaa" ..
        "ZJouFlAjnyDTuCLBWWaz998WF61U65sOsIwE0Kx/06pIjpjE0eqNvK8ARnKohEoe3RPwOe/ouZXsIh6dSdzbEi+KXkaZFDoLxg8KkTNKEhBSnVypiEf1A6C2xIPNDbQ47VFSAK0lHiwALJNGosrDjTp4PEFwejJsEYsqeFPJDzBiiFnTqJ6JR9buz7JZ1iAoWqc5W8t1" ..
        "TbPQcpOsTcQzcpOju3eMbpxnwMkKZGWWE+0tBbwjeVaSgFbpm4NMJY+0DpYihGQlblqCYHkAcBJAvX0WrflqzIFWp2n1XAVI5eC050Ez9gtELkp9ZO0dvNKIbPF6bELIGkWpNwAAzcFsZXG2BDCimSEyibcO4Fxle4XNXxIAkgJQWweYQA/gOnJWuP+nlwBaSt3MUqBs" ..
        "MR8Xi98ASGDCza4QEqIjhhua9WIUzwiEsk/72lKg7E1fWyEsqyh06OTMqPEf/EwbpKL0o0gAAAAASUVORK5CYII=",
    dec_glass = 
        "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAACO0lEQVR42u3Z0W3iQABFUY9FEZTjIlwHxVAHRbgcunC+IuWHCJgxHvPO+1utNkHcw4w3GQYzMzMzMzMzS1nZ4ouu63rx1m4UrJRrlwBEPyaGInw2hLJR/Jssm21uiaA0DC96BxhehTCKf+jdaq/kU+sX" ..
        "YLshmN/5x2PFp1/8Tk+DV06B0dP+d+7ZXqOj/7ufCZoAcPR/71Uwer+yBwAAjv/ka8AJsM8mV4D4EwA++RMAjv0JAHf+BIAHvgmA7Kf9BQDxARAfAPEBEB8A8QEQHwDxARAfAPEBEB8A8YfhDID4ZwB88s8AZB/7dwDEB0B8AMQHQHwAxAdAfADEB0B8AMQHQHwAxAdA" ..
        "fADEB0B8AMQHQPxkAOIHAxA/GID4wQDEDwYgfjAA8YMBiB8MQPxgAOIHAxA/GID4wQDEDwYgfjAA8YMBiB8MQPxgAOIHAxA/GID4wQDEDwYgfjAA8YMBiB8MQPxgAOIHAxA/GID4wQDEDwYgfjAA8YMBiB8MQPxgAOIHAxA/GID4wQDEDwewiO8KWMT3ELiI77+Bi/h+" ..
        "ELSI70fB4vtlkPgAiA+A+ACID4D4AIgPgPidAyilXP/8cf7w67uL/9bmB/0OeQXcxfcQKP6eAHa+Bmyj47/mBICg8/jNr4BnNFk/e7bXWPFFnQIHPvp/d2r0TW/e/+Mc+1XPAA90OQ06if/qVV1qvvu6rpcHf+VE+PAn/t1ntFL7av5BYJ098G0CAIRjhm8OAIbjRDcz" ..
        "MzMzM7PY/QAY/vHeNdBrRgAAAABJRU5ErkJggg==",
    dec_glow = 
        "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAVBklEQVR42u1d23LsOI4EKPXO/3/ubJeIeTnuYOMkgASp6tmHdYTDslwulysTdxBQM5MXPpS8r8VjtPkc2ngtb3wYcc+I31nv7zxndZ8H7gUC6Oa9XeD14DW8DX4Flr342K8Q4ZQAeij1ukkS3dRA/03p" ..
        "ty8Twf5JAuyq/C6g3yaAujdPDyWPAdK+oD22SfAWAd4AvrrumBAl/4cK+G9IvG2S5Ssk2CHALvgdiT8hxht+QcfW2iYZbIM0r5OgS4BvSbqSAO9og1Nf4E01b01CnGgDe5sAOyr4m8B3NEuHEF17fyLp39QMFAlYArwFfnRvlxy6mW94Q/ozAHfBPtEgWyRgCHBq4/Xw" ..
        "qyfJGxHCj9OnpKSwwDNgVvdPtEebBBUBujZfGz/rEOHEfOxqgeqN7JKgIsKOVjgmQUaAHYfv5Ct77808wVtOYEfqO0R4y1cI70UEeBv8LhE6z7FDiB3wKyewA2Tn3hs+Q0gCT4DdHP4u6LvXb2iFDgHeAp+57hDlmAT3C94/K5lvXVf+wW4oaCAjqMEbrcHj38g4GnBS" ..
        "JUlZo9dS/c2/7q0a4Btqn5H6LvC6QT5ppoalGYZ1VHtHK7AaY7vWcL8Q53ekUgsw2ccOIp/A5As6tt+HjUjCDKjoSCKt0ADVz6ypCSDh7y+Crw2Q2e9Hw7TIgS9gARiVFCKAZ6JlIjJYUKk8JcFvf/+Wfhq469RJQAgGdMaUDFITdVLBGty3QBN4YqzADkCEHXNk3yDB" ..
        "LXsl1q5HrwSwukkS9P2J+s/MgDbs+wREMMLnUGBivkaC+4VmjRPwo8ePBOhROIRjswmlU85Fkq7uZwjwWfgAWqh8hgStSOV+IY9/Cn5GihEAv4I8ikjhTSeQ9dajz8wcaOF7MCSQQsv8pgVuwu7vpG3/yU8h/IVKI1jTCZyADBOo8IwIP9ezAF9IUmStbaEpuJs5dKag" ..
        "0/kcixSru65MQkSGUy3ASP8FwB/LY1ZQ56L+0ccgwK9IUN0PTcG96QBWcf7p52iQJ/MP2MYRadTvDaj+FWz5RZDpAB7u96bzDawRomryupUgAXQCZSO7py8RYADpHyT4jGlg8wGM4+dV/nR/yxaNYAB0BT//+Z9mw0fRIkJRxh+4Nzz9TpzPSPkoSCAEGboE0MJ5qlK9" ..
        "SJpWgFcirD+7HPhe8lkSaOK3tIhwNxsqM1u7q+KlIIEW3w8y0RSRgDEDlac/g1DwR9oj8JHkVyTI8gTS9Af0Jk/tvAV8BGYGegX+iRnoOIGeBBNogwls/ABq34PPkECTbGQW1ZQaQKTXsKkHhMhAznyAERAiIk+WIt51Ai1JAnn7bu7aE2e46KEigZKRgiVlbMoHyHLn" ..
        "Wtw/Ad+D6a89CTqmoJMWtiT/z6j/iATThXuRBkAksEaYKF2tcDccP9lIyIyGAxip90E+LntNo5kKXq+nAy7L9yuQfnFE0AL8AUJEVvKzRpawGsgcoGRVfxYuDuDwaSLho/hZ5k9cREJIkmLK+nUkal+BLxCBJyAdnJFgzRpOskcg0wDQIbzJmL+j+qUR6o0E7EGQYDQ0" ..
        "DnNOAEm/BCncJ3AAJSCCOYClAN8/nzcPVuQzGIcwTQTJiwkfKUiAwNeCBCwZkDkbicaLbPAMsn8PsNER+AJSxxH4HvSsAMR4/sgh/JsJqBI9suEjSAK6NCU/0hrZcwrIOVRO4AgKPSPw+PUXCTRJ8Y6AaAM8f+UgWuLls05hqyv4tK4feelIghn1P37ZeP88F5Fr2EkF" ..
        "P0D1R4mVhwTfk8A7icM5mJqYAiXPAUItcDdtfyX5o5G4YQnQ8Q2ugnxZ48gMyr5Iss1JpbrEz9M4ou1rByP43pJOH7aSmIaBrPSL1F28Eth/JeL8jARXch0BfyXEHUE5V5ay73Q+wHBawAvQBOYke48n8AUURAC+XlA1jDBa4Lc8QCckFDLpM4ivDBEuYAIQCbJcQeQE" ..
        "XoHnv4JyORW/RgFPEu5V4Jt7nQbMwABtZFoUgKqIIMwDVB25ndO+FTFYElwJIS5AAOQ0ZupfAk1ggWQKsPs/mmE2wV8f+7iMoTptgDRFpQXS5tNOW/hbtX9thoAXuL4ITXA5x4nJB6AMoC/wPAX41yb43v4/iek1Rw5GC8B7d9Fhy3QGa+BgvUGCCPyfn13O/l9F2JiZ" ..
        "Ae8Ervb/AR66Nwe74Jsjp4GQEEUD/v23IvcfmoAqzlcyzu9oCCbL521+JvleU6DnyDqKPQEir3vVAKvkWwG+Lr9rAGxPhCd5355AC7AzD+HRMNb5Y07bDhJ8bUYBV6EJ1uvhzMAIzAByBOfS9DmdFtAg45e90WtYOAvwNXAIIy1gQAtoo7WcqgZmhZSROFlMcwf6vAIT" ..
        "4MG/wPcKiBLVIpBqXNX4A7THA0xA5vT5nMBVSD6S6kgLdNq/hekKZgcyV70B3TN/kUlAgHrb78mCzIa61rdBRAKrpz0D9SyF6h/Od1DQKKqgLdwC6ffE8KaiOi4G8bwbEcDuwIdB9gJoQYJI1V8JKe6AACMpAikwAd7ufwrwkWN4OQ2S+VNGHJePzIERja9/ywQy07x3" ..
        "TgNJ4ihWyaEL/M4VhIWIGB74AcxV5AQayMuPBbzK40eOoRU9Bgri/wFsfMcXM6Iq+FsY2D1VW42Fi7SBNFrGkGpHmuH+9fM7cBgHkH4N4v9V9X+Wv/1JwFfQBSxByzjK9xvI+GkQ7xtIC6++gXQPh3bHq+8eCxOizQuBHQGvC/joXhQeVhU6D/7PtSRZtSfo+lFnVtD3" ..
        "0jxww8wJEoIMeh8ALkkHLhMWosdcoLijhF8wgCZYr3W5HsARXHMAn+XrasslkP7VJ1jPDcryOlZ1fwWq3pIw0Kd+s7MDzGCIvzTfTap31jEUEuisWKNEUSiz+REJRpIPuILunI+z+3fi6V9Er98F7P4MvveARlXIzPGz7smgTtq3e3poFL4C4yBeANjbaYKVBOsnIhWK" ..
        "AuYC/Gr370DyEfgWfJ0LcWci3VY0f0RCZ9VYOGZAxKnjVx0gEeDdS2CjfQIoSj1fzvnLrhkTMBYiePAjYtjyWpH0R1LvQWfAjo57KTmGRth+AG2QQEntkZWXrwBkCTKDN/h+BXs1Dbf7HRQGTge+d/p8WvdybV3ewVvDR5TxROcAmEacncOjVCawux2MHS3LRgjr719F" ..
        "lBClfm8A/nAkiCKBz0IE7/SNhRTTPY8tf8Nchu4C2gF191SdVRbY/90BmMK0hHX6AbtHySTIBop70yVo9hAQ6inwAwbwB66AAJHqX1X+CuSqBS5n459EU2ZSz2pg25D43yqG94H0S0P6O+Qa5HRQVODxYZ+X+ltE/liuUTfQCj6y99OFeB+XxftR+6vka9CefqpdT8kQ" ..
        "hoFvg64H5IiyhFfgKCK/4AbRwXAx/Z8LuE+g8qdT++LUvrf9kkz/0JffO22sv6O6gjsfb5uLiBzedq/SjiKJ20n+z/d/OGfwB9gfEvwLgH8H109TYhEZugRhw7xWFHC6YkUPyTGCe5GtzsiBkke3I8If7nn+BM5glIyqXl+Um2cHQWgDzFbczxBAvwR457GDuDcIIiAy" ..
        "/ID/P675I+oOzv7OQ5C4a8+Z/gztAh09djRY9vaG0ep+JvkavOmVdPpS8r+Wz9v5BCPI+3fJuLM0WzY3m7afe8j/f/xffg9sU/i2/3kj+uXfYCnzuLnxtybI7EXP+/z6/DN4bPS71nit8/B9fEMjHzmBJxMr5WDJ8QyKNdOVUyuQ/b1n8faHiPzbFYD+dL/7JM81iXvs" ..
        "/93dG/zW4mtIgG+oHWvcM0LqZlCbn0AL+MoeagV/HAk+rjPo0yBatAHEglPBOwDaDtg7GqBDBnvhzRjFPdSUYQ54c6BLAOIExaA/ReR/l+uZfPruIWkQtyKCNYVm++N+CXjUfWqbZMj+UT9VwwPh8/PTJXTuYmb/D0n+HRSGHgD6BL1/bwrG2+9ja29glxRvvGA0oNHb" ..
        "/gecnzPXwTMC8H2SZwXx48zBx2mP6e4Z+DkaLdf1D+xFE5r+/r0BvJEDCdgXY2BGzgSHJR5XcZvOxn/A/RmAf4O5AI/73Y8jgZf+GcwQfNw5QjRydkp/o/hroK/f302JZ8gQDSWI5u1q8iZ50B+XUp0OfANSL0FFzzuFyM5/gFZAJHjc92ijyCP11FE5BL27/Po3DdBZ" ..
        "VxIBzw5bRmfyogENClSruW6bCPy103cA9Y+ctI8DNyLCs9x7HPCPew4JnMdJvFfW0AgtZ/EuRo2xWqCzVt2A2hcweEHdgcwnODod2XsJmjlGYvq89K82/kl8BAOzBKL//Unerym9VfItaY8IwKhwbT7OH6EeyT+MDk1KYCqmA90DnIF/gx68EUimAGlHJLDAP3jA1ycw" ..
        "cxZogpk4xdYwIe0wsLu7VoJ4dyTj1kby4h9XTh3BP/s0evZvUN7VZDQMMgNPQIIHmANEAgHO40wmkLPJH+b+Vk9gdco0W2CgLnSzwK5bsm7lcY6fui4bTc7qDTe/R1wPYTYmBp0N9P7A40hhQNIn+DrBHGArtoVPwofqpI7tNA9gyVgSfyhSSJX1BLt30FgWDYYuZPP/" ..
        "Jui9z2YEPQUJHkAGH71UJLBkoYQlDmKWRmY3nvx17y4mSSrhD0QLlKI1KZkm8D7BE0zmrMBHHbwDHPeW5HSQAcm3RBM84HceQApLyGFFFJA5j9asF/zNCZTmzDlNTIEVzssE2zXQwGWk9tdzeFcxleN2qeGqwyc6Hj5BSDcB+FGyCJGDNQOTcPw6EYOdFoMscOayUE8B" ..
        "sJY4dtEx6IeYyvEBhznMOYAzMBX+TfokyZ4I/Mc5f5HKnyBxZAU5qlwLGyJatx/AGk0IUcLICi0QecFSHM0WMLr1cq/lCsbIZ2Pi0ISw6bx8K7SB/3yS8C/bRYQqiVYkiKoowFAtwMhz5hZkBJHzdiUqP5rE/QDJZ0ayeOBGMOcvaupEBLBCpVthClCKGGmGCHhEBHar" ..
        "GZMutpvM+GXXaItGlBTKYl4/cp2RfAERgYJrTcbDRK1l0z3/E/gEMwF/ArJEJiEyBVL4Akxa2DITUOX/jRhCYIkqvxJvfwY7dh5y6ra6Ac0Gso7qJnRpo7fQgPSjmN8S8GdQQMpCQ7YmUDmTZXLolnqpADN1ItuvixYrZOBPNy9PGtO4UOyPRqNU7fBZiIZAjaKEGfgO" ..
        "VU6gWzVktUFqApi9M8xc+uyfQKPXZ3PNSjaa5QJRigYTP6sowJuXpyBCZOefQsVP0NY2Nx1FpnZAF4PKCVPBUiUpVqwiT/8UfAP2Xotp4eqcwCzBMhM7/jTAn83sYNRbkHVYVQ6gZSagiv2zbRVM2XcmEQO7ZeMBZ92RDxANX+zuCzDnEFoSJs7EUYyIYIUDaIX0GyH9" ..
        "VDWQWTycjST3NheBfwWefne/Dpq2KYnqR0MZhCCABBogukaOHksCC1bTSjNNnMX9v5HkJlK/HS2Q1fOvYP+ekcezNCk4KZisNZK9gaOYFCpJ3d6C2r8FCR/mUxKnc7KFHdk4N3CTWb+sAoiuq8aQWQxPYDdtjGT6piURwEyOXUUNmw/IE1jQDDobJLCguTRLIYvwRaM0" ..
        "JLyTjh/WEUQE8L19UVWQnXyJwEcNHlaMYpPG0sXoDZ+FRphFzr/KA2SaRxomgGomvcnc/85gAmusRc2GJcxiwYIFBSBxY+eMOGCZNa1GjhjjzBkB/iSqfbNh94VJCN1F35+RHrMEySEBfX3RGFUBjlqk9tGCRSt26bBr46RoaMnU9Sy0AqMpmPoAmywqW8mrPMDWNsok" ..
        "KhjFLF0B69NHMgu/Uv0jGMowyc5aK0KyWVxP4j5Lgo6qF6JmAKuBSkYEzCwa1NwxCRIoCNcsifGzJUuzWB3PRgFVxW2SZkGa4M+m1HfPEJTVQHYhoRS+wEhy9RUZUJVxJFqg2mk8m6dp0Js6m0SYyWMz8LuaoDqDaUwY2PH4GfA1OIo9gqbN6Wz9A1S5OeDRXkBmPrEQ" ..
        "nTVdDVD5BFI8brcVTIo8QXk41Bp9gUxyyIDkZSRAjqIVwGuxSjWaQ6zNjlpW5UZxfVbu3QW/kwGUTj8A6wNo0RGsxOiXDPxovw4q+BixaoWdsWNESChFRCCF2mc1SZcIwjh+yARYMYeedQaZGQLRJJAMfLRs0YK5wnqwBItRqUac5jHSTzgFn0kRU/0A7IFQ25lGmZAA" ..
        "hYgIfG8SKskfDduf5TA6fXdZT5+Q9f1T8BnVb10foKMNOqSIQkREhtnYSJbN1Fdyxx57xB1V7STRDm8Af9IZZN0ZQVVhZWtAcVGIUXBCKFqsLMTyiWzFjRRFrI42EGAKopEx9gIhpLimjo3fZPdvdRpYNxJEKK/vU75PsGE72pqNbH9n0GKVVcuqboz0y8uS353NEB4M" ..
        "qYCX4izgzuICczV+BWofDYw24RZVZ7uN2CELzJsZSb8lSaQTQjCSX50iLmcEGXEsfGdluZGjaFA6V8DRMQ0WKTNb0E9mHrLl2M4J6bfBpxJcd2M+kDW2Uma9BOwcoqjpo1L51fYy5jVX5+6Zmrwk0r9Dgi74FBHu5mmg7HwAQ4LOECqkAYzYXo4iADsYsmxJtbMbJXR6" ..
        "+hjSCUkC68wI+hYJdj6sCPUyE2AbewpsIzuY3ZsEeEaC+4rN3xkVe0qCKk9ggWqPiCDE369svzaHMrO+AAvaDgl2wD86HNqZGtbJEzBEYw6sRiVfC3yAjmbqxNMdKd3xIZg5i10fgM4EyoEmkIO0cWdMnRAJoK5ZYvIBHYlkoweR8zi/lQhSM+suM6rKq8xq+TcfJ42S" ..
        "rzZIadKvFDIndDomRL4g+SUBTknQIYMQoVz3q2xu6epO6O5MRmVMwS7oW5JfEeAtTSBEnL6jEdiVat2Vd6z3vJN63QG1q2naY2MzAnybBG9+FbLqtxOG7qSKZaNi17X9slP86RLgTRK8BfAuCd5IBUsTEHvhsSwJtgZGMwTYJcEJgExJd8fxY880vKkF3iDJTq6fmhTC" ..
        "EqBLghNtsHNv1wk8Wb/GzOqzFwjzFcnfIQBjW3d230rTuZPGCtaOI3g6h99eIMPO9Tb4OwToLj0+0RInzyFfdALlBdA6Et1R+a/sC9jZHsZ0DylxtuCkgGSHYL/hEMqhlHce98rHjgY4Sbboi1rjxOk73Xu8Q4Bd4HeSVP8IATqhVgfEXWK8bQbeiAxOyNLdFyj/DQKc" ..
        "aIMdQHeTPd/wAU6l9i0pPwLwP9Lz81zDdLF7AAAAAElFTkSuQmCC",
    dec_moon = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABD0lEQVR42u2aSQKDQAgEgf//ObkkOeQQjQNKY/UDdCgacMEMIYQQQgjV6PFS1/N5ZeCfm7j7bQB8Z7tz8GZmURm8grwy8O7ZT3GAYtbTAPwKXiH7SwDUM78EYCt4leynT4FbOGCK9Q8BmBZ8SQko1f9f" ..
        "ACZmnya4F8DU7OMAAABgG8Dk+scBAABAPgC1noEDAAAAszv3gZj2ft+mBFRcQA+w4l/jIwBM7gNxxoLECAArLugMIc5clZEHsNoLOkKIs398dIMQV22Odbnu5Y0tY8S+z3LkWm3sfOTwGat43s3OewLJXMVz9RG3WkKuOuuzHs9DcTcg8z6uNOoqALvCzK90lnd8CJr+" ..
        "GQ4hhBBqoidwMpQgGgDt7AAAAABJRU5ErkJggg==",
    dec_particle = 
        "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAC00lEQVR42o1Xa4+bMBAcP0Lukuuplfr//2SvCWCD+2UdTSZrrkgrCAFmPPt0aK3BjkAW6czG/wU8H41sF2ty3Q15AN4tyTn+BwEG3ug60HN7v84OOIN6xkooAQXexEDge1dAwbtls0RnJREGq98AVLOR" ..
        "YgCw5wPwE5E4CaEkKjRZcaXn6oHLQnZ83gG7TXTNikTHr51AMeD1YPVgF4zAz0ZgEjJHBFb7v0h8ednS8oH8HfxNzpO4gtOs2LsFwCwkvVRt2ZE/E9CbY5O4AxT1iymw0Hefgk5NFcji+07iYud3O5/tmUgfLvbfTC7S9KxGNvWzKpAk8nnlH0bgQkokAlnMshDT7OjX" ..
        "sWdBGKjACryb/QBwpd+9JhQDvxMprQfVnuN427w07Oa54Qrg09S42H8wv8/2Dgh4tWfWUTUdleIsrjiTEh8AfpISMPC/BL7YO2dyS/J6SnY6YBgUpoli4Argl6kBAF/kirsBZweQMyNwN+SWHEUVbU6dyCeA3/ZeJBecBNzrHw+LOD7iN7/5XnQW8+2RD4aKRinTq12h" ..
        "gPsi0JtZkfbL39md77fs3NwdK5TnPeAildsbgD/m/9lIcvrp98ATkdfLuastlgE9z3uqFbm+G7GbkVjsvqfKzr3AW3XvaieSXGv/XfJ+NnAlUaUCVm5g2Vl5oRpQnPLKeZ7p3kok7uSOhdSoMie2LCuvNMVwS+XaXqkZJVKwUowwgZlcUaUnPBTQUWqVggRxzZlyuwdU" ..
        "JcVmWf06UODFBXEwSPIqJ+r3ySHASiyOCwpnRpZxKhwMkNxgshDgMbzQivvqV7rHGfFQIAgBOJNMlWk3HvT9IrY6cfDkgtHRBLw4tX00luscMIyBJtslb6u10Sjl7Y4a5XYVmatTCzavEOGAQCICLy3Vmf12CrQqoJtXCaE12inPUXZEo61Zc4C2wY65ZQHdBx9NFKjs" ..
        "+zAgPWpqL9vzf8XQ47dgMlz+AAAAAElFTkSuQmCC",
    dec_ring = 
        "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAOaElEQVR42tVdW3LjRgwEGOYAqw9r73876UO5AZGPjR2GmRl0A5iRV1WuskXqYXaj8ZghoBJ8mJk6p2jiOfZc9HjVwwLHbdK5v/5xVYv8IzoB/JXA68z/EwS7CmBLkiNEAv1G4GsB6FlCWBExUDK8nQha" ..
        "BP5s4GeoQrUi2GQiwO8/hQCk5etC4FfEBay1R56Lvk+KBFps+VpAjkqyfAclsAlEgMiCkEAngu+BlD1/tRtgI/93/w2RQBeBr0Ggs/FAlhA2QQUscW7k/CEJ9M3gaxFpKjOEqO+3hUSwKiXQQvCrj80KCj/PsdO5liRGxs/bO0mgkyxfk+dVupTVgV/EstHXlJNAF4Kv" ..
        "k8gyS/6zbiACasTiaRKciaCTwGeBjLiEFVlBJgZgQWIATivBJwl0oeVHicJavi4IAivAZ0C2We5AJ4LPgBlVBZQAr4QLuBVH64waVJKgXSzqEGCG5WfPQ5UjA3aEFCss3GYpAUKASvCjVq8OAVaAzpAhQoTReRklGJLiSoCZll+tDu8E3SMDa/HIsSkxwYgAGRWoIsHv" ..
        "AnyECMixmTGBXQkwW/av57KqkQX+DmQD14v0KCZCBfgVGcbX358EqCrsoKB7Vp8F/h5YIEIXfh4TiODJ/iwSNAnABGoRuUeV4pUEXSeXgS1Ahhvo2ytIAMcA24TCzirw74GaQOt4xVr/o1ANZsQEVkEALbb8CuAzm0ykaBuWBYlQDT5NgjMBVoN/PYaA/1NyZWMJBIIS" ..
        "LOI8Ai6hAnxjY4DtNwD/TqaNmb0CFat5DBFuSd9vGRVgCRBN9XrgVwCPEIElgAUUwJKK8CPhBsIkUDP7I2j9miAJAv5Ph4iRBaZM5I8u3FhCDZaToEcADapBNfjq1AhQBdDC1C9DgCwJEHJQ6nQmQIX0Z2X/PngvxhVE9hYiWQBLgKga/BgAGvm87nOfBKiS/grwvff1" ..
        "4oxMLMDs+WOs0BrRvonIEyTBCOCUa0AIwMjw6HfW8tkaArsdTQr2+iFgZ0hwc1JERg2aJNiTllMRgN2TYLOVyV4lUE8X5lohVLBaqMDv1+/z4ZBAG59hne+uje/c+u56jgF20PrZY0ie7/l8BY4z9YlsJRCVec/qW88/A3WCdEB4JkA04PMIkQVfC2KQ7KbQUTTOAC9J" ..
        "EiDuhYoNWAKgAZoWgS8isoGEQ7OCbAqI+njU8q+veZDxQCog3AMVPiQCR1bhRkAiauMpUSQVNHKlUDtxgp4A0UGsIJ1z0BXMXqyi6O1unwpQZf2I3/9J+nzvWCYrkETah8j9AbqD6/FHIiugYgI1sz8D9XzveRR8JeKAT3eAfA9GxZibORG/a6D0e+4g4groItEOph/I" ..
        "biBP+u+D8xDw0bgjogLaAFsDdw2jaWLv/c+ffSd3HHkuSxsuznaJ9fobAf0C/H5U4jNkYG4d7+XXPZ9vhGvRQbyB7El4Ne5FaILr1QDOCpBZa2esn7Fw5PzqWGB0EXWgDlm16JGhSgW6329P9vxT0vq9ihwaCDLKgaaFvYjdECntVPl6MmzJXoWvwe1pIxX433ffSVkU" ..
        "MOfuretnQWVec60hMHcP2wA0cwBFwB1Jdks9H4J3PUEUSVtBYLZ69iLyfk++JUkCJhMQwHq0oQY6sHoLbD/TgSX3rvcPYt2i+fyeCP5Y349aH5MaRkjQes4I+dVGWqVA1I8SoLXY01MBLxZx3cBe1IQJ9f3IuoISGcP5ZyMWjkZKd82dRypgDqmNsHIbRO+eCoizmtl1" ..
        "E7vM67lzT6zWZX/EIZOQPvUgr0MrMFQgPtBByjhSASb/h7MASS6ujJZrI9F8NGD0sgEBIv+tcxG3BjmQwNACci4B4oZiAHZh4iX8wg9LtKzlb4476114a/jOo0MCvZRkUUtHU0EkGEQXs77UaE90+xIi9RMQVKbws5EEQf8vG6zs9a7BNggKDUw3kSKVFwzSqrEnpByt" ..
        "HYyCO8b6EeJsTlCoxK7gYxDIScCP9+oBEuxWGn3QWcAIrFdgLQHdT5BNDSUQC5jj973rc44JDCguIfsTkc8+ZwNUPLFNGC9zBxRh5A4kuSYwShNHP3r5vfd375gmgmABt+CL/NpEyuA03Ky7FwCOLiUzreCQ7V1KxAWbEwxeLdAGAd3WOWanzzoGu4ONTOXQmoCCShNK" ..
        "AyPgez7XA75FlA20KmlYJxKHtCJ+JbaBG7MQE3AD5Y+92PIjJPEIglQF0TrD5sQARwO0a5p3OPsGhNi/j+TsM4jw9Z5b4EYQTTRvQgtKyM5f6fjmls/Xhp/34gEhMorI+gOyn0LJegBtyFsw+FMyAGTIgd7ihajGKFXcBiTpHW+9V7Q7asZ4PpJxWSgLkKIvL8EtWhJc" ..
        "UNoG0bxHAKQGwhaaKjqdl7npbZGvl0TqgrgkJOvYSOtXJwWsHngpC42xSQCdBHhkY2l0vjAaCPZUQhtxQETZKki9xPC2N1p9dicyWlKOuIYMIJUDLKarxTYR1OwgZy24yN4i1DaweCXIEFkfmQU09d6rgsDv/NBv/N3suyiATfzyNnmU++iWbxvs9undLmYT/td3Db6e" ..
        "ogC2wBoiI117N2+efwwEPHs9bIIRhF6zJ7YyV98rJ84NGtoApncjx7n8ejSWd48BQY4kQNFJY5UGBCvSPhlUdN98Zmt1b+dua4fscVK9FgmO0/NHRzVQNTIpHAU/S6H3N1s8C7wBCzEtYhyNlUJzdgMdjZjh6BBipruY6mb3N8t9lCS9PfvHafXuuk9vc1b0BLi/X4D2" ..
        "L6PWLRnA7R1ZAMv0R1HvnZbMHk5Q13rf42K1R+fHOpJvg+MCXJus3++9/7Og2/l/CBCRntsCibMB6L3zjwb40gHzAElxOEpwABbPdPCMXLNbBIc9eU9bNtL3fHivAVIrqLPGxg65ZAHSkH8BZvZYot+PkaDbTMlnYoAoEQzotiHAzpje9igjt0+1/L4C0XvLDbAxwuro" ..
        "39j32ycEcp61o+miObc+WycovG7UuB4T5yZKpKGjCd8PEGks5akRO8zCPX+bUH59kKVYr/sm0pbtGPzdCwLN8f2HY/mHcM0iUaC8Rs/PyjRzTxR49J/A4wV+mDpp3ehOGVbaeh24lCzgoIQTEngDrRc1ulvUFeyAREc6W3oge35cnY5aRqiMgrdni2ANIJF4AG0kjWQM" ..
        "JhPLxJsUBxUdNxCxNi/aZiQayfd7dQPUt7MNIgWME5D834Jksb1gkebmbBE3omkRciPFNaA7GkQ+iH79aGt4tjMoCrgUDahm1ynSMQB6ITXQJEmJFcAeCZjBDUg+HlUA1vqNJAnjDrtpIHp3C/N4yL99AizQnZNJQ72gzzpbuqKBoCRdAGv93pApiz63Byp4rQvecwOo" ..
        "CmRug1Ig6GPvw/eaLkcsPhsrePLvrVGI1yyabX5QrQLR3jfWsfgN6Keb6RAeJUFkF9MjKf+CpIECpIAjeY2qgBE3QyKdOqVR81eiDiBgbj9LCVjrH6WdLhl2orP1KH9HVMCADIAp8vTARwpNStYBIiXiSGk4Y/3MWkM3C8js2jFHBdCWpgb2LUK7cRl5370llICZEyRk" ..
        "cQi1fmYzie1Etc8SufVZBdB5d9FFJwVar6I9+plJIUIGd4iriFi/VW4JY4gQUQFBhhoklYBdC/DmBaMLPigpvHF0EeuHZx3vRMNiLVCBe3AiF2r1ErT+KhVgyrxe8PYEt+lZZo9B9dQwIWYGoq3fZNAAKjs+Vsk1dmTpOuoOsgOjmCGSX8/3CMCOjWVHxv4k3gchCzMn" ..
        "SBMLYOzwSCYWEAL8sumhO1j2RYtEBl7o4wKWgQUfJdJVJbasRUbHo2miCLePMJKdML6/6QKkQAVYV/ABKMgWdEEVk0PRAZKRVcMe+M/CMfL07GB2fjAjx1ESROcDVtyHH50eKgHZrx4cjWwt+yLAH4H2ZpUj5D8EnxfAjIZjrZ/NsY1QBY8IDPglQ6O9SiDj89GtXL3H" ..
        "89L2TJ0tZEj51xvqaGQWIIELjP7+DKqQkDegNN//UwGizQ2FtNC/Bl/mo9G4UsnPntGfzyQWDyA1gxH4PyKzgFHpHxGgMiBsgfQXMWGUIZ1IPgVECyoVBJgFPkXaMwGEHPLEAMWQoDdqVkgFiDSgsolKgOzsQcAXYuex+90RAmTJUEUCCUh/dRCYDQqz4KNFKVQNRM1s" ..
        "C/b3VxCILAkifXir/D9beBkVjZ5F4EcUqPu6TwJErD8KPpMiokTI+n4NbKxESfEA1vZtAvjQd40QIJIxIAHjKzGMcqYCWPD3B7itK7qQkwb/7AKyo16y4DMkaClCNviraO/GAD/D8pEagEuAVSTw0rkqImSaLhqpCCzwMln2od/VzDTgSzMkQM9nJ5LciwmAqMBD+Nu4" ..
        "ZoLPkuKLAJL0rZUpY5YIrcklWnEnLdGgiQE+k9KFLf8cBCo5b25WTOC99iW5x0egEviU/I2bkVXFihRP0CBQA0MHWRIwaeVsIqx43IoCt6ngtwjA5tMIiNH00XvN6zcEfhX4cDWzRYBKJajIIpDXv74h6NGtW8vAZwgwKyaQwKg17zNei0DPBmEV6pACf0QAWRAYsudG" ..
        "3VOWFDeJ3ZEzmxBp8P9zkQZEmEECFmQG7Gz9P9szKZOXGwFsHnxVQwgQkeEIsJHPkKIhTmzjiMw+wpm/U+A3L1SBEugbXlM1ji3Trz8KihWRiAa/eyGK3cEMIrBLvlWVwOxdullQLUG6/4E/vDCLScBaeqUbqFwcegfwYfDdiwSSQBMEyRCo0hXMGnFXId3TwIcuUlAJ" ..
        "KtVgldxrARFmg1kKPnyxgsWirMVH3YFMXg6u6NfDBpFTwKcuSqESzDxnxTjYqlhgFnlg8OkLlSBBNcgzlaAqFayYHjoV/EoCZACuiOpnxATZZoyrlYIGP3RxCkiQJcIK0FeQofo5GvzUhZpIBF0AeLYSmB1iLd8BfBGRvwGpvcuA3Mh5zAAAAABJRU5ErkJggg==",
    dec_skull = 
        "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAACXklEQVR42u2dPXLCMBCFLQ3noeEEoeAIqVOnpsgRUlBTU3MEF+EEaXIhUnkmk0xsbGvfau3vKwFb8nu7svVnmgYAAAAAANZGilLR6+V8H3vM88trwgCh4BENSVFEfzocRp/v1rbVm5FqFX2K4FMN8TQj" ..
        "1SS8hehjzPAwItUgvlL4ISPUJqS1Cl+LEclD/JqE7zNCYUJCeF8jMuIPP/Za9EnMDYgsvtKEjPi+JmTE9zUhKyq9NBOqNaCLjqWJ/9uEklmQEd/XhNyAK5no980CMiB6Bqwt+ktnARkQOQPWGv0ls4AMWMJTEExn41n4brv/97vPr4/w5TWWEzJz2v8+ISyEsS6vm7yZ" ..
        "MnGTa4r6Er/3Lq9qA6ZeXJTjqjYgWiSrTMgRxB97HnV5PIbSD9BF0dD51OWRAWQAuBjQdTr61uCvgTmdMDKAJggwILIBj9wHSo8yDp1PWd7c9p8MWEITpMyCR8+jKK9E9EszYK4oY49Xl+dqwKN9gqkXVdtxpaLf5R5QeySrpyaT5+roEnO0u+1+1G/nllcy+k026anX" ..
        "Co0xwHvYQdoEKcaIuohWTJxYXU+2fCPJUgbqLLesJvUuyVKmHI/vfz47nd6a0tuRrPcLmzVBS8gExWZt+U757qLm3KStVrj9rJtqp7z50sSu8tfL+R4lEyyedtw7YqUuRjUpr3pbirQnHOEleup6hhqOVi/MwoCG+YBw0R8tCzZRDPDaQEEG0ATBqgy4tW3v0IX192QA" ..
        "GQAYgAGAARgAGIABgAEYABiAAdAs5T9kLN/F3zAnDAAAAAAAAAAAAFAp3xtOWr2P5Bm/AAAAAElFTkSuQmCC",
    dec_star = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAHO0lEQVR42uVbLc8kRRCu6u4VJAj+AUGdQIHDoMgpDBYM6uwZDCSXkAuOhAQDEkFQkGAQCBSWBIdA8Et2uguz86a2tp6qmvfC503Smdne2dmppz66vprpcogIExETUbucK9d6zvtM4HN0iDrb632sZG6B" ..
        "89VgZhmGeA4IbgHxDfyeABjPCgA7hJGaa2ZOf3c3JyI8DPGtQHB0j74mBwRN/H79OxE9UC+aEa8BaBei1mVOny0Qy7zXIiIaiVi3gGDv2gPAguGpQTfcQoSLIkRfswJmqf9Y5pmkvm9EJCPQbTs4+BzZBS6owQCc1y+8HPG3hOv/WobzWi3XHSdE5JSIdk+AaAXDiIzh" ..
        "rwqE14ANsNxHBm6ae9C4+u1IOJlJRC/YBC6uBAMYwGV0vwHua/AiY7vUM9oo6LweXRHOZq6qDsgODMD9Zqz7coDwxF6M3SFjG8iTgFZQgWwgw1g1hGRE/oZrxvIjgCWQgLv3GuAhEYH9IBicvOh+nBydb2a584wdJc+NnK/FIvJikdCuzj24N7MH+wv95LzQW47uL8cI" ..
        "emOq8yzcs7QKWM73ArcRCNY2IBAoMISa+2JEvl0IQM8T4F2ykSjSjlDm+XVj9fcxAkPZAne5AoB1fJriHhX1nhNXm0fB6nsrQC9KQ2U1iABARm8pKbDLpiXesyeiPUEuBDoIEGsT+gGDiAAgR++nAWInfgKRR8DYZbZFDlAPpGI4YAx1tsPOfwsA+O5y7wn8tieMGOC9" ..
        "YbwzkuWvB3PoZboxiPp7As6Jtxwu4/Fp3Z8Ox2cSRGlvkj0VaEFcnxHawUDxAhUMoV3CPEKRyFfGFQD3cYKOAGBXhkwCdIBj4/2d0O6sAC3IILHxJm9WgSNANCANPbAR7YAEWKK1yGtApwGg61jfyRDpVYCJiFtAMBfC4x6MAcYXCQBfXu47GSPoAXyfOOVqjMBXj4Ib" ..
        "BMJIbEUm/lYKGCx3U3G0m3M1gmw2GiSQxKgGQp7+D3PNRQBOSv8jnScTLDWHaI/wO7swjG6xyeG1om3wuD6AFFQlwHKeAef1e1gwEPfJUwEqpLmzvGEznPd09ggA3jLXAPEZ4eSFzy1IV6H6AAH7gJY/bcieFgH4BBi/Hnh6lRzEDXOHIbglmdwobc6BFIwD3EcZosii" ..
        "N5AhsvNkc4YDJBE5UQcG9gKl1Lr6LzqgBmTE+ijHPXqu5kchWUlAEjLb8Ck92/HEmXuciXRAsAvCcAiNEET3fUV/z/G5M/dekhvkgKlXyyAHHNdzP9C/6/jGmXtYLMQSi8jLIJ7vRPQL/X+O1y9+xHYZk4imBuAPev6OV7QKPHgOJGBTUjCtEfRyZ2+oFNUOzo//AWIf" ..
        "EtHZiHy41kaNCRact5WU7CHr1/8gse9eiN3U8GqM3iEDZE4FACOgcvu+SWSeiOizv4DYx4rYsyIWEewx8eqeERQVJHjgHk52kL+bRPSBk9l9coDYj5UIn5Xe2jr/clLpurCKaIGVmKg1pYGGheZ0aM3qWgyOaYj26oNR15g4LTI3kj4CMaGEcPtC02RwosJF5dj1WRc8" ..
        "Z9L1sYDULtBlIg3U5C16qPcuqsJqAnZOflQk/kP17A0Qn/UICgAESkCk682kl3W5ypMC264iQceGd5wN5zcHjC0ABYF001c4El1fQb7Nq9ZqdId66X4QAM39lUjCBNcZGGKrMC0oJDA4Z+UqMrm6IxIgjhpsgOAZNFRERn0NR88ZSMAyzQkrqMvZTM5RALaEy7MgARV7" ..
        "Ia3YiiLBn9kIy1pt/f2ZiB4lxD8yXt1mI7jABqxin6B4KuC1n6Jc2wQ5epu6Fqetjovir1/Yk4hZ7AsK/YcBKijigOGBIE6JWkzvbzM9OlwUfwnUYDkArEQVXDUYhSZklG4SJ9PrEd8ONEl5AAjq8EqAmE6F+cZxGgG3bRVlAZcSdWq1ewJwNr79DGzQTIziytxnFpGX" ..
        "QP9fB40QqATmtcv1IHP7vUP8O6BHsNIXOIPVYqI5JAF2joDB44vINlCykoNdYluwZE3QODELKgKXyOG4uFTYzkJJGL2cml1l39AWRHSVJW4CjzA0gsspIK5E71Efnq3UrqB6UwVAAn2eRRAW8hhRLGCDmKwPD8UTyI+IVgAKOLaCBMwqeIQ3xpFF5IUDvUDVbvGosqzV" ..
        "4GdF/JtOuo0KzdJScInhbhLPCK5Cy3nG9aae1ZzYgRPxp4ItEIe4maiJREawAasf+QHeVjZxCK9smdmS7TKrYBMy1bjxCZARjFYBMeLsbWbUOQM6YABRan4VjKK3cUqytNlw1vtmuM0OOF5Pv93EhJa/DAAK0u+RQUQ7yFAwtPbiaE+aoDjZO8j32EGqj9+I6NXCrtEV" ..
        "eIkVrrt+wXDEegVLnm1FZacPnx3dX0X9t/7GApndSC0iYASpABmdFdBZ5YW4HvGt0HBhc4CRgaVk1/hKPuMd5IXd40e202f9OpkrLAcrU5WUOJQcZpY/AV05zXDD+sARAAAAAElFTkSuQmCC",
    dec_wave = 
        "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAC/klEQVR42u2dy3EcMQxEpx2LInAQG4ROjkDBKAKfHISCUATORb6qSrvyfAASaL53VpFEo8EBOVPabQMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAGyC2g338/Xv73N7+e9ErqTQywJ+EYwtAA" ..
        "EYnHCM0M8CjpVxJ3b8yVjKDOyY9M1KpG0IpVX2m+2fwg+V/Hvjd+Rs9RoTfSqlu+227wea1H1ieqvq8JItYmkt+zSYxaj9jyY56vo9YaXSSi6vsYNkMr7Zk0IzCHc/dI82bppazucpULl2wTZI+vUQlzv2mL7g9G6aUZL19cb9WyLosy9dLIIE9WwvOOcf84muKsXkf0" ..
        "ULUPMPYk3N0QV/UaaoBAYZ63+K2zrBEy9WpjgEdBXEnc1YromPQr8alSMJGJcjNCVjxycHGl+bqtX87J774jjNBLLlu+224wSi+tJnplE0R19mUM0E3smeuatR6t/MydUXHVikR03fMMW0Erce6ek5AqeonEjzVBtR1SJH5Mf1BVL7m/jq32gqqaXppQCbcdAr05mqKi" ..
        "XsreuvYE4G6Iynpl3gPctvits6wRKuk1zQCPgriSuHtjuhghS68pBshOlJsRqsSjii6uNJ/7+tU1mI47QkXzqnMCOu0GVQ2r7qJXNsF3nX0Vk8pZ7Jnr6vKIklNAFSquW5Mq1657hmE7anXIAN3O3SMT0vWeQtE3S6uZoPu9hN1/Cx/VH7jcTC5jgKwXVN2vpCOugn/u" ..
        "EOjd0RQnd45SeikjAHdDHEl8db00MpBORhixM1bQS2cCubKQ6PE6JD1ar0jNDhkgMlFuRsiOJ2v8XQbITEy2wztW/ci5tEoFuZg3ek6tLmhXw0bNL6oqprOfsb4IrbRqU+X2iDrbrKvrWXqU+N2a1KNNuzhm+Z5QHH84cuqRy/HmUty2rVf1Lr8dHNofrFLxVt8DZLxw" ..
        "WSXxth+EXDHFSolf5oug7h+sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGzb9g+5mthiUwecQAAAAABJRU5ErkJggg==",
    dec_witchhat = 
        "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAADP0lEQVR42u3dMW4TQRSH8Z3VngAiSqq0XICCEkVKilSIIhfAQlQ5gA9AhZBzgRyAIpEiSgouQOuKEgWuEBqIjOWY7Hp3szPv91VxY8l+//fN29mduKoAAAAAAAAAlE+K/OEXJ8ubv3/PzvdDfhe1HohN" ..
        "rfs3vxYACECE7r/4+iG0BRiAAXR/ZAswAANY+yNbgAEYAAIQXP+RlwEGYADdH9kCDMAAuj+yBZqIqb/8/PT278OX3xkgavE3vRaA4PqPtgwYAg2Bsbp/fc3fNgNEsEDIITD64Fe8AXZZ+6NZwAzAALo/sgUYgAEgAPQfdhlgAAbQ/ZEtwACV4+HZcbN8f9t9af80jdH9" ..
        "qxw9f1eVcqy8zrn4m16j4ADcVew3808qaQYYR/+lDYOGQAbIaGLdP904cJ3Nj0fr/tIskJ0B1kNwNj/WxhH/S9jYl36lXhKaAcwAuj/yLMAADAABoP+wy0CjB6rQZwtr3d/P2cJcLWAGMAPo/sizAANUux0ry30GSLq/Cr09zABmAAgA/YcdBhmAAXR/ZAswAAPo/sgW" ..
        "YAAGgADQf9hlgAEYQPdHtgADMIDuj2wBBmAA3R/ZAsU+FXx58av39zw8esQAqJwO7pPrt3uDqPDx7KD39/y5uBrkO9j7eJ0YAGaAIenSvUNYxAwAAYj2A81T/h4YgAEgAPQfdhlgAJeBOn9qFhjzPGGj4NNfDoYMRKPoeQWi7zA0Yxd9cTX75/Wr1wq8/p3MDhajhaEZ" ..
        "sujrHwzdAnFXKPoIQ9N34RV9+FBsC0PbIDR9FD+Hopd0Y2dbGBYny5s2IWhKL3wUM6wGoY0NUpfi51D4b1+e9P6ez178mPznXjfC/0JQl1h8Rrj/oJ7uW3yFz49VG9xlgtpmTuybTXXX61LkuZ/gbiAEAC0DsG1vGvlcErYKQO6/io371TPZByi/87c1c902OZaDsnYC" ..
        "k3sB5a73vd0LEITyCr/T6WDPA0x3um87vCdPBJVxSdf1qi099DOB6L7v0seleprCU8GRQ9H2qqrv/Zk05XMBJQVjl8vnITflUikngx4iLEPtiYy5C5uin4+f6hat3w0sKBxTvq+SHK8us7AAAAAAAAAAAPzhN4P1ETkB2XwkAAAAAElFTkSuQmCC",
    icon_crosshair = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABC0lEQVR42u2aSxLEIAgFhfvf2WxnUpNJFfKz7LfXQAdRxDEQQgihYyWVH59zzi9jRNLt0dMjAAAAAAAAAAAADkK1B6DKw5B0cLoShnR0PBOEdnfec560CHgz+N8fXRnbAsCTAxbDPecq3QatBmckQY3+" ..
        "+6tO/BrvmRO0s/MZELRb2GcvB93paus+r0cUUAxRDBWG/+dY67jVJaddrsQjj7vmCIiq4FbLYU+7SIIAqFh3D+FY0Ro7fheQ3Zqc3t8iBwCgaZGStdS0+4VoNFSN3Noib4W9Eq1G7++rECKdT0uCVggZBRJ9gR06Q+3vBKONjjxZ0h0evA8YvBSlFgAAAAAAAAAAACGE" ..
        "EDpMF5WLtFgLWuGiAAAAAElFTkSuQmCC",
    icon_eye = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABRElEQVR42u2aQRKDMAwDsf7/5/RKZ5g2JLbkFu2llwKWo4TY5DiMMcYYY4wxhswYY5x/FYRa/FswEfH3CZgZbWYi0E08e0qgm3h2EkIp/Gz12f/9lAPuiPokstIN6CBemYToILzyPlQHZAbNcgM6imcm" ..
        "ISrFZ1q16hnRbdTpLlMFs1oLZCch2OIzaoHUxVY96lX3m00EOorPcMrs86Bc7OLEzj22kqja1V1dv9skWYkXilfcSi1Q5Qawgyyv72/GfdsBygbmzjRIc0BGEqqSu1SCs94C3xa4nQVwJ77oug9gbYZAe98m9gMynelawNWg+wHuCLUdHYbLUL0F3dngMKYYGPvw7H5A" ..
        "5tSKTl+GFAsr2FXZai1QVYVCUZpeiVV9HY6u5wNYvQeoGxXqYzLo0K1Rdp0ef0rsePo5QWOMMcYYYx7KC8HbYEYxwDH9AAAAAElFTkSuQmCC",
    icon_folder = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAtUlEQVR42u3aUQ6DIBBAQZZ4/yvTC5TEYpElzPvXshMkTbQUSZIk6cji1wtaa23ohyIiI0B9Y/in16YA+McAGRFixaIzPQ4xOvzdIXr3yIJQZw6f+fAb2gFPhvkGmgEn3hg+wwHYW39dvYCt/gfsjNDb" ..
        "gXXVVsyyI66Vz+NshDvnTi2HBwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABzUtfsnLnbALIDsHzaU3V6PS5IkSZIS9QFn80BYouoT9QAAAABJRU5ErkJggg==",
    icon_globe = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABrUlEQVR42u1b2w6DMAgtxP//5e5lJsa4Qbm1W895WqLjcgqWIrYGAAAAAMCuoGqFvfcuGkVEf0OAxuGZhNDKjlcQQb/geCYRNNP5qyOe/04nQDL+NPZ635MDT9e1sq3gTOfpDW+4f5PhTTnKcF67upJM" ..
        "SU5EJHCF8xUPQGskcJTzEeHuTQsLCVy9LUn3RspKIcDCsjU8K3RRROhnFkdW+drocBGQuT2NkjFim4kADctRJz2LHGsUHBGrISmPSoGrnPP3eZ2IyKKHPKuvCTttAeQtiD4RIOlk66rcDaxsYjzp7L13iw3uQqja8ehUO1bs0lhtSakEPXvszGjQRgW3zcG/HPoR9tEK" ..
        "Pb6ZpCAFdifgyM6xrEowKm25Ldj3b4WteTwDMoqLlVZfSp/Dq2yFusCzIDzjAJLlfOlp8E5CNRF3nakNEannNtIRGm2JeTpPGl3b9wTRFcZ7gYK9NuoZkNGwKekHWGuFCl1cXYhI90bKKimEZtQCn3SVFUIZgwpt0mAGZc8IWd/2jNQYnvMIZ+/N3oiQZLiHsDAniElR" ..
        "zApjWnzn7wUAAAAAYGO8AJBEyGMKd5qHAAAAAElFTkSuQmCC",
    icon_image = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABWElEQVR42u1aQQ7DIAwbFv//MjtVQtPaBkhCmtrnLooNOGDt8yEIgiAIgiDeiSL9sLXWHkeulFt+yEpe2jeykpf2j8zkJTyq9pl60vYXe0BmUIC3C1A9zl5k74CH8USeJvBy3agiwIJ86RBdBFjfv6Pf" ..
        "HTgGKYDxGIz+nqha574nekY6oh/AK3yIaobwSGAiT4K6I4biFHibAIcpak8EifFuF+CXvJYIfb2V2tgRS62KcPX70drYlcn1K6ed9Y3UNbkJjjSw+u3q1IHXql81OruqR80VEeBJ/l9GMHuutZ7dsCR/RnhEBOuMEZbkZ26Md2Ptqu6MMNhBftYXJHVHRcAu8ppirXxb" ..
        "vZxe0vCOHAG7yd/VsH5dItoTWDIyw+QBVg16Zgp4S/ChKkAW8lMCZCI/LEA28swER6dAln+NiXdAli1/xQPZz/1d/8hsfhlNmyAIgiAIQg1fYQ/8ZMPh4dEAAAAASUVORK5CYII=",
    icon_palette = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABS0lEQVR42u1aQQ7DMAgLqP//cnaa1MO0lmKTpLGP0wTGSSghtCYIgiAIgrAprNph771fkjKz1whwJ+CRgtjMgVcIYSsEzhTCZjzflXnCKoLPkGXZhQnAJsj2YwxSzKyN9ukrZGqmfUeuRFUB88vP06+P" ..
        "rxY8WgRjBH/+T1aYK1vZxUgLcHaGzNQRW/84QY9ARZVXXY066hxeOY2QitrKHDN/2+pH+fqs3/sqPl5FIJSZgbbKK8H2xpZYNOlU1gFZrsf0DQtyrtn+CEgACSABJIAEkADBb/GsF6Mnt8SDTQT1JsAqiA72FfT7WyQAlJ3yrvAqXaBHAkQuQBmCKDt3d4rP/hLM5uEr" ..
        "d4EQPB2lPqqLE7WT3YU+8lmKsfWju9QYzivqANTznI1egdF+fbUZIbR9TYhoRkhTYpoT1KRo06zwvtPigiAIgiDsiw9bBihYB8AFhwAAAABJRU5ErkJggg==",
    icon_panels = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAuUlEQVR42u3aMQ7DIAwFULBy/yvTvUMbU1ER8/6eyH4CD0BrIiIicmp69oMxxti+qd5v9xXVms/WGdWaz9YbFZvP1N1nfpLZYzs0/aneaAsHzO4DcAqgWgAAAAAAAAAAAACcmqvigYgVAADAuhkwcx7w" ..
        "PjdWnyksORO0BQAAAAAAAAAAAAAAAAAAAAAAAAAAAADgRIDdr8ay9fXq94Hf7iCiwuPIX+qOKi9EZ+uNSs9kn75iRURE/pwXI7M8YMs4TNEAAAAASUVORK5CYII=",
    icon_rotate = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABLUlEQVR42u2ayxKFIAxDbYf//2Xu5q4cRZQUmiHZW8hpeQgchyRJkiRJEplqrRURx3eH4LtXgu8+HCxjZ83MvsTp+W4JgKEMXZhqxXsLwRhm6rOxp7hvIFh241fmUMMoBAAiOyiAPW3ZLPNfJigEiKd2" ..
        "Ldr8F+NoEK0+WJR5hPHo1QSyEZplfjTubYWymB+phFafSpYMoc339qVkXOtnJqEwZT+i/cKcfQT0wph9ZHt05wFo2D5a/qvH/vZHYgIgAAIgAAIgAAIwD8B545P1r1AVMBMAcxU4479/yiEwuwrqX8sAZKmCURDOcicY1Y6jDyeiIaCP4j3ihCYKQsQ9BPXdICI27e0w" ..
        "ahKmfB+AXIEoX4hA4zG+EaIBEHmvTwUg4p2gJEmSJEmSJElD+gEyFcxDPCdchQAAAABJRU5ErkJggg==",
    icon_shield = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABLUlEQVR42u2bQQ6DMAwEWYv/fzm99oCgAsfrlNlLpUrE6yEhJXa3DSGEELJojDG+Px3aXUmffS9JVX7kTvzUXAEIdUu6GoZciR8ldPe6FgB+vdu/JJA51lQAFUZnx1DlFHctrRQAldOy0osyAlbu29ne" ..
        "9o5b0x0Pd7fcfdXEs0DE299HAAAAAAAAAAAAAAAAAAAAAAAAAAAAALbqis9mrkTFqkdgWb6jQ93PWYeMlQ9CM/zyEOxS/nb5iNXrAU99sgQ6dYE44sc/lMWe+ItuvUDVcdM7N5z9AXdiR/Z0mz0bjsZ/Al3O5oQOsTTbXAaEmeO3vkMVM0zdenaql1ZU78NXyVU3ZKlL" ..
        "B5erE03uHyySNPshSrt8BwDuNts2r8NXya16ALvsf4YQQujV+gB01dBQfW44lQAAAABJRU5ErkJggg==",
    icon_shield_alert = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABP0lEQVR42u1byw7DIAyrI/7/l9m1mtbHULCDsC+TJhUcl8BIvOMwDMMwDAl67/38qUBTBX33PQCw+EAd+C05ghCoFjRbDKgC/xXQ6HMlBHj7tt8EkDnWVAEYRGfPAeYSV6VWigDMZcnkgowJmed2NrdW" ..
        "8Wga4TB65LZVA88SIna/j1gAC2ABLMDWaEeBipDyeHUKWAALYAEsgAWwABbAAlgAUcdH3YmKVUtgWbyjQt9P2YeMlQuhGXy9CVZpf6t4YMUiRiYnp0AlF4hi/lC2xfoJKitNqN7C9zMZY9BS4Mrfw0qHq7lGVmdkL7fZImQFTvEIPRH7xxw5y6SB2XtAxqY5c3xUsaqo" ..
        "rDmo5tlhe5KCfQt7Co5tyEIVB5fKiQb1z1UAmL2J2i5fQQC1zbbMdfgpuFULsMv+Z8gwDGNrfAB3j/wueIEaRgAAAABJRU5ErkJggg==",
    icon_sliders = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAA3UlEQVR42u2ZQQrEMAwDY/3/z9kHLGwL6xopnTn20EaiOBJeCwAAAAAA3kh1v3Dvvb8+UlWuBuhp8b+eH2XAlUhXEzQh3tkETYl3NaFSD35L3I3hq/VyMIAgNHgLOIYiTQ0b10SoqYnrGoc1ce04dwHa" ..
        "oPsBn26XShPfnUqVJr7bBCWK7zRBqeK7TKANUoYwgCC0kgfhv6FIqcOrKxEqdYJ3xWElXmO0y+Qh6LY71GntztYA192hTmt3dga47w5pg5QhDCAIHdXuLP8A592hTmt31jOAdgcAAAAAYMMHkV+ELt9Wz0YAAAAASUVORK5CYII=",
    icon_sparkles = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABJUlEQVR42u2aQQ7DIAwEwer/v0xPkdoqKZgEbMPsOYq0E2MvhJQQQgghtKtydAOllPJlKGeVJ9m9AgCwQtlvBeAwfwVBCyevWgGtzTBH7Nw1CJr3vVZc82fPX0FhCgBgc4XoAb/r98kpELICDnP/TLY2" ..
        "TomQ1jRfuAXOcAC1tDYaniYHyOiv0zvDR1fQ8CXQA+HzuZ506PJA5MzUWRS2MD9lCrRUgpX5qZuhJ2d3yCRYM2dh/lYFzOrSo6GxGQJA4scIU8AiDHlprOLB/J29g2sAmoRnBUE8mLeEIJanNh4giMek1gtvqRwwayRyLJ64IcJeIO18SSL0DZEnIIT+M7TdDZGeL15r" ..
        "ijRBACROhNKKo3Dp+wGaA5btlgBRGCGEEEIItekNf9u0ZMY4E+gAAAAASUVORK5CYII=",
    icon_sword = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABG0lEQVR42u2ayw7DIAwEg///n91TpFyowsP2Ltm5V9UMhqI01yWEEEIIIYRAw909+jsMXT46gjGsfGQEyACttZa1HWC3QFYE2ABZEaADZESADxAdgSJAZARjvxStRrATboQrEYxRfud2MFb5XRGMeeV3" ..
        "RDDmsd8RwZjlRyaDIsCM/Juz4e/nTpCnvwdUyUMEqJQvD1AtXxoAQb4sAIp8SQAk+fQAaPKpARDl0wKgyqcEQJYPD4AuHxqAQT4sAIt8SAAm+ekAI4+okeWnAvT+t2eUHw7Qk2aVn3oi9OaBI4t8yCHIJD80AaetfMgEZLzVVTIBT7HnKveEP30GsE2CZb3McPQheAu7" ..
        "u7MdhPbln8DlixCjsBBCCCHEzQ88wOQrRSAR2QAAAABJRU5ErkJggg==",
    icon_user = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABA0lEQVR42u2ZQRLDIAwDsf//Z3rvtJ1CgizC7jmJkUzAmNYAAAAADiUqgvbe+9cBRcRjDfglvMqIdBQ/87y1AbNiFCZElfhPU3zk2S0M+CToHzGz71mvASMilDtBuv336vUg3bL/2G3QFQzAAAygFLZY" ..
        "9at2hXQ8Daqyz1lA1Q+4ktHVBVE6VoHKavD4Uvj4niBA416guRVDynXg+DogXIWrjIgd+oFLD1lq8bNt8VUmhHOBoyiYouLU5/TtqLwBcoiTu4gf7SFIDFCKX2VC7tC3WxknHfd65Xhyt+zfHS+fkP0r48ods39nXK7Grk6z6h7ee/zR34AZgAEYAAAAAABwIi9juqhO" ..
        "ZAui8wAAAABJRU5ErkJggg==",
    icon_users = 
        "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABGUlEQVR42u2ZQRaDMAhEhfvfOd23WosZRvvy/7Y2gxhwgtsGAAAAAGsSikXGGONj4YhQB9uhE+qAOhLRqZOdQVWuu0snO4OaDc6hE111OFuvLp2crc8jMXUT7NLJmad/Jv7++9V67tKR7IB/hwSQABJw" ..
        "vROfNZtqM3PrSHbAUXCzDtClEw6HdvV97dBJpSlRH1QcOql2ZvLjarPO8vMAgI2ZYNu4SlmfXTrL+4BwjLaqAbp0Sj5AZW2rvr57mDr9NL5luvJfl04pAUcLK+s5IsKlI7HCT/b10ibYZTvv/Jq0t266PXd1wqvU2buvdJzonvYt4WsCZsZLj7S6J+M1hqIk4Ibt7xqk" ..
        "/lIG7AASAAAAAAAAAAAAa/ECPvb0SvuM7hMAAAAASUVORK5CYII=",
}


local B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local B64_MAP = {}
for i = 1, #B64_CHARS do
    B64_MAP[B64_CHARS:sub(i, i)] = i - 1
end

local function decode_base64(data)
    data = data:gsub('[^%w%+/=]', '')
    local output = {}
    local index = 1
    while index <= #data do
        local a = B64_MAP[data:sub(index, index)] or 0
        local b = B64_MAP[data:sub(index + 1, index + 1)] or 0
        local c = B64_MAP[data:sub(index + 2, index + 2)] or 0
        local d = B64_MAP[data:sub(index + 3, index + 3)] or 0
        local n = a * 262144 + b * 4096 + c * 64 + d
        output[#output + 1] = string.char(math.floor(n / 65536) % 256)
        if data:sub(index + 2, index + 2) ~= '=' then
            output[#output + 1] = string.char(math.floor(n / 256) % 256)
        end
        if data:sub(index + 3, index + 3) ~= '=' then
            output[#output + 1] = string.char(n % 256)
        end
        index = index + 4
    end
    return table.concat(output)
end

local AssetManager = {
    _cache = {},
    _ready = false
}

function AssetManager:setup()
    if self._ready then return true end
    local ok = pcall(function()
        if not isfolder('March') then makefolder('March') end
        if not isfolder('March/assets') then makefolder('March/assets') end
    end)
    self._ready = ok
    return ok
end

function AssetManager:get(key)
    if self._cache[key] then return self._cache[key] end
    local encoded = ASSET_DATA[key]
    if not encoded then return nil end
    local path = 'March/assets/' .. key .. '.png'
    local written = pcall(function()
        if not isfile(path) then
            writefile(path, decode_base64(encoded))
        end
    end)
    if not written then return nil end
    local asset = nil
    for _ = 1, 3 do
        pcall(function()
            if typeof(getcustomasset) == 'function' then
                asset = getcustomasset(path)
            end
        end)
        if asset then break end
    end
    self._cache[key] = asset
    return asset
end

function AssetManager:refresh()
    self._cache = {}
    self._ready = false
    return self:setup()
end

local ROLE_FROM_KEY = {
    ['152,181,255'] = 'accent', ['22,28,38'] = 'secondary', ['12,13,15'] = 'main',
    ['52,66,89'] = 'stroke', ['32,38,51'] = 'panel', ['42,50,66'] = 'panelHover',
    ['66,80,115'] = 'toggleOff', ['209,222,255'] = 'subtext', ['210,210,210'] = 'text2',
    ['180,180,180'] = 'muted', ['255,255,255'] = 'text', ['155,155,155'] = 'muted',
    ['58,58,58'] = 'muted2', ['79,79,79'] = 'muted2'
}
local ROLE_ALIAS = { panelHover = 'panel', text2 = 'text', muted2 = 'muted' }

local function recolor_tree(root)
    if not root then return end
    local map = {}
    for key, role in pairs(ROLE_FROM_KEY) do map[key] = role end
    for role, color in pairs(Theme) do
        if typeof_color(color) then map[ckey(color)] = role end
    end
    local properties = { 'BackgroundColor3', 'TextColor3', 'ImageColor3', 'TextStrokeColor3' }
    for _, object in ipairs(root:GetDescendants()) do
        for _, property in ipairs(properties) do
            local ok, color = pcall(function() return object[property] end)
            if ok and typeof_color(color) then
                local role = map[ckey(color)]
                if role then
                    local target = Theme[role] or Theme[ROLE_ALIAS[role]]
                    if target then
                        pcall(function() object[property] = target end)
                    end
                end
            end
        end
    end
end

local Appearance = {
    ui = nil,
    style = 'Aurora',
    theme = 'Midnight',
    state = {
        background = { enabled = true, opacity = 1, particles = true, animation = 1, density = 1 },
        effects = { border = 'Rotating', intensity = 0.5, glow = true, animation = 1 },
        border = 'Rounded',
        surface = 0.12,
        custom = {}
    }
}

function Appearance:persist()
    local ui = self.ui
    if not ui then return end
    pcall(function()
        ui._config._appearance = {
            style = self.style,
            theme = self.theme,
            background = self.state.background,
            effects = self.state.effects,
            border = self.state.border,
            surface = self.state.surface,
            custom = self.state.custom
        }
        Config:save(game.GameId, ui._config)
    end)
end

function Appearance:init(library)
    self.ui = library
    local saved = library._config._appearance or {}
    if THEMES[saved.theme] then self.theme = saved.theme end
    if STYLES[saved.style] then self.style = saved.style end
    if type(saved.background) == 'table' then
        for k, v in pairs(saved.background) do self.state.background[k] = v end
    end
    if type(saved.effects) == 'table' then
        for k, v in pairs(saved.effects) do self.state.effects[k] = v end
    end
    if type(saved.custom) == 'table' then self.state.custom = saved.custom end
    if saved.border then self.state.border = saved.border end
    if type(saved.surface) == 'number' then self.state.surface = saved.surface end

    AssetManager:setup()
    self:apply_theme(self.theme)
    self:apply_style(self.style)
    self:apply_effects()
end

function Appearance:apply_theme(name)
    local definition = THEMES[name]
    if not definition then return false end
    self.theme = name
    for role, value in pairs(definition) do
        Theme[role] = rgbarr(value)
    end
    for role, hex in pairs(self.state.custom) do
        local color = hex_to_color(hex)
        if color and Theme[role] then Theme[role] = color end
    end
    recolor_tree(self.ui and self.ui._ui)
    if self.ui and self.ui.EffectManager then self.ui.EffectManager:apply() end
    if self.ui and self.ui.GraphicBackground then self.ui.GraphicBackground:refresh_colors() end
    self:persist()
    return true
end

function Appearance:set_color(role, hex)
    local color = hex_to_color(hex)
    if not color or not Theme[role] then return false end
    Theme[role] = color
    self.state.custom[role] = color_to_hex(color)
    recolor_tree(self.ui and self.ui._ui)
    if self.ui and self.ui.EffectManager then self.ui.EffectManager:apply() end
    self:persist()
    return true
end

function Appearance:apply_style(name)
    if not STYLES[name] then return false end
    self.style = name
    if self.ui and self.ui.GraphicBackground then
        self.ui.GraphicBackground:apply(name)
    end
    self:persist()
    return true
end

function Appearance:apply_effects()
    if self.ui and self.ui.EffectManager then
        self.ui.EffectManager:apply()
    end
    if self.ui and self.ui.GraphicBackground then
        self.ui.GraphicBackground:apply_settings()
    end
    self:persist()
end

function Appearance:apply_border()
    local radius = self.state.border == 'Sharp' and UDim.new(0, 2)
        or self.state.border == 'Soft' and UDim.new(0, 16)
        or UDim.new(0, 10)
    if self.ui and self.ui._ui then
        for _, object in ipairs(self.ui._ui:GetDescendants()) do
            if object:IsA('UICorner') then
                pcall(function()
                    if object.CornerRadius.Offset > 2 then
                        object.CornerRadius = radius
                    end
                end)
            end
        end
    end
    self:persist()
end

function Appearance:reset()
    self.state.custom = {}
    self.state.background = { enabled = true, opacity = 1, particles = true, animation = 1, density = 1 }
    self.state.effects = { border = 'Rotating', intensity = 0.5, glow = true, animation = 1 }
    self.state.border = 'Rounded'
    self.state.surface = 0.12
    self.theme = 'Midnight'
    self.style = 'Aurora'
    self:apply_theme(self.theme)
    self:apply_style(self.style)
    self:apply_effects()
    self:apply_border()
    return true
end

getgenv().ZenthraAppearance = Appearance

-- ========================================================================= --
--  GRAPHIC BACKGROUND — dedicated decorative renderer behind the window.    --
--  Layered gradients, ambient light, decorative artwork, animated particle  --
--  fields and per-style motion. Never transparent; fully self-contained.    --
-- ========================================================================= --

local GraphicBackground = {}
GraphicBackground.__index = GraphicBackground

function GraphicBackground.new(screenGui, container, library)
    local self = setmetatable({
        _screen = screenGui,
        _container = container,
        _library = library,
        _parts = {},
        _extras = {},
        _style = 'Aurora',
        _conn = nil
    }, GraphicBackground)

    local root = Instance.new('Frame')
    root.Name = 'GraphicBackground'
    root.Size = UDim2.fromScale(1, 1)
    root.Position = UDim2.fromScale(0, 0)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ZIndex = 0
    root.Active = false
    root.Selectable = false
    root.Parent = screenGui
    self._root = root

    local base = Instance.new('Frame')
    base.Name = 'Base'
    base.Size = UDim2.fromScale(1, 1)
    base.BackgroundColor3 = rgb(12, 4, 32)
    base.BorderSizePixel = 0
    base.ZIndex = 0
    base.Active = false
    base.Parent = root
    self._base = base

    local glows = Instance.new('Folder')
    glows.Name = 'AmbientLight'
    glows.Parent = root
    self._glows = glows

    local deco = Instance.new('Folder')
    deco.Name = 'Decorations'
    deco.Parent = root
    self._deco = deco

    local particles = Instance.new('Folder')
    particles.Name = 'Particles'
    particles.Parent = root
    self._particles = particles

    if container then
        container.ZIndex = 1
    end

    return self
end

function GraphicBackground:_stop()
    if self._conn then
        pcall(function() self._conn:Disconnect() end)
        self._conn = nil
    end
    self._parts = {}
    self._extras = {}
    pcall(function() self._particles:ClearAllChildren() end)
end

function GraphicBackground:apply(styleName)
    local definition = STYLES[styleName] or STYLES.Aurora
    self._style = STYLES[styleName] and styleName or 'Aurora'
    self:_stop()
    pcall(function()
        self._deco:ClearAllChildren()
        self._glows:ClearAllChildren()
    end)
    if self._gradient then
        pcall(function() self._gradient:Destroy() end)
        self._gradient = nil
    end

    local colors = definition.colors
    self._base.BackgroundColor3 = rgbarr(colors.bottom)
    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, rgbarr(colors.top)),
        ColorSequenceKeypoint.new(1, rgbarr(colors.bottom))
    }
    gradient.Rotation = 90
    gradient.Parent = self._base
    self._gradient = gradient

    for _, glow in ipairs(definition.glows or {}) do
        local image = Instance.new('ImageLabel')
        image.Name = 'Glow'
        image.Image = AssetManager:get('dec_glow') or ''
        image.ImageColor3 = glow.color and rgbarr(glow.color) or rgbarr(colors.glow)
        image.ImageTransparency = glow.alpha or 0.4
        image.Size = UDim2.fromOffset(glow.size, glow.size)
        image.Position = UDim2.fromScale(glow.pos[1], glow.pos[2])
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.ZIndex = 0
        image.Active = false
        image.Parent = self._glows
    end

    for _, item in ipairs(definition.decos or {}) do
        local image = Instance.new('ImageLabel')
        image.Name = item.asset
        image.Image = AssetManager:get(item.asset) or ''
        image.ImageColor3 = item.color and rgbarr(item.color) or Color3.new(1, 1, 1)
        image.ImageTransparency = item.alpha or 0
        if type(item.size) == 'table' then
            image.Size = UDim2.fromOffset(item.size[1], item.size[2])
        else
            image.Size = UDim2.fromOffset(item.size, item.size)
        end
        image.Position = UDim2.fromScale(item.pos[1], item.pos[2])
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.Rotation = item.rot or 0
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.ZIndex = 0
        image.Active = false
        image.Parent = self._deco
    end

    for _, item in ipairs(definition.extras or {}) do
        local image = Instance.new('ImageLabel')
        image.Name = 'Extra'
        image.Image = AssetManager:get(item.asset) or ''
        image.ImageColor3 = item.color and rgbarr(item.color) or Color3.new(1, 1, 1)
        image.ImageTransparency = item.alpha or 0.3
        local width = type(item.size) == 'table' and item.size[1] or item.size
        local height = type(item.size) == 'table' and item.size[2]
            or (item.asset == 'dec_aurora' and width * 0.32 or width)
        image.Size = UDim2.fromOffset(width, height)
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.Position = UDim2.fromScale(item.pos[1], item.pos[2])
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.ZIndex = 0
        image.Active = false
        image.Parent = self._deco
        table.insert(self._extras, {
            obj = image, x = item.pos[1], y = item.pos[2], anim = item.anim,
            amp = item.amp or 0.01, speed = item.speed or 0.4, phase = math.random() * 10,
            baseRot = item.rot or 0, rotSpeed = item.rotSpeed or 0
        })
    end

    if self._container then
        self._container.BackgroundTransparency = Appearance.state.surface or definition.surface or 0.12
    end

    self:_start_particles(definition.particle)
    return true
end

function GraphicBackground:refresh_colors()
    -- Style lighting stays independent of the colour theme by design, but the
    -- container surface and accent-driven extras are refreshed here.
    if self._container then
        self._container.BackgroundTransparency = Appearance.state.surface or 0.12
    end
end

function GraphicBackground:apply_settings()
    local state = Appearance.state.background
    if self._root then self._root.Visible = state.enabled ~= false end
    local particleFolder = self._particles
    if particleFolder then particleFolder.Visible = state.particles ~= false end
    if self._container then
        self._container.BackgroundTransparency = Appearance.state.surface or 0.12
    end
    if state.opacity ~= nil and self._base then
        self._base.BackgroundTransparency = math.clamp(1 - state.opacity, 0, 1)
    end
    local count = math.clamp(math.floor(#self._parts * (state.density or 1)), 0, #self._parts)
    for index, part in ipairs(self._parts) do
        part.obj.Visible = index <= count
    end
end

function GraphicBackground:_start_particles(config)
    if not config then return end
    local count = math.clamp(math.floor((config.count or 0) * (Appearance.state.background.density or 1)), 0, 80)
    if count <= 0 then return end
    local asset = AssetManager:get(config.asset or 'dec_particle') or ''
    for _ = 1, count do
        local image = Instance.new('ImageLabel')
        image.Name = 'Particle'
        image.Image = asset
        image.ImageColor3 = rgbarr(config.color or {255, 255, 255})
        image.ImageTransparency = config.alpha or 0.35
        local size = (config.size or {3, 7})[1] + math.random() * ((config.size or {3, 7})[2] - (config.size or {3, 7})[1])
        image.Size = UDim2.fromOffset(size, size)
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.Position = UDim2.fromScale(math.random(), math.random())
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.ZIndex = 0
        image.Active = false
        image.Parent = self._particles
        table.insert(self._parts, {
            obj = image,
            x = math.random(),
            y = math.random(),
            vx = (math.random() - 0.5) * (config.vx or 0.01),
            vy = -(config.vy or 0.03) * (0.5 + math.random()),
            drift = config.drift or 0.01,
            phase = math.random() * 10
        })
    end

    self._conn = RunService.RenderStepped:Connect(function(deltaTime)
        local animation = Appearance.state.effects.animation or 1
        local step = math.min(deltaTime, 0.05) * animation
        local currentTime = tick()
        for _, part in ipairs(self._parts) do
            part.y = part.y + part.vy * step
            part.x = part.x + (part.vx + math.sin(currentTime * 0.8 + part.phase) * part.drift) * step
            if part.y < -0.06 then
                part.y = 1.06
                part.x = math.random()
            end
            if part.x < -0.06 then part.x = 1.06
            elseif part.x > 1.06 then part.x = -0.06 end
            part.obj.Position = UDim2.fromScale(part.x, part.y)
        end
        for _, extra in ipairs(self._extras) do
            if extra.anim == 'float' then
                extra.obj.Position = UDim2.fromScale(
                    extra.x + math.sin(currentTime * extra.speed + extra.phase) * extra.amp,
                    extra.y + math.cos(currentTime * extra.speed * 0.7 + extra.phase) * extra.amp * 0.6)
            elseif extra.anim == 'rotate' then
                extra.obj.Rotation = extra.baseRot + currentTime * extra.rotSpeed * animation
            end
        end
    end)
end

function GraphicBackground:destroy()
    self:_stop()
    pcall(function() if self._root then self._root:Destroy() end end)
    self._root = nil
end

-- ========================================================================= --
--  EFFECT MANAGER — border FX, FX intensity, accent glow, animation speed.   --
-- ========================================================================= --

local EffectManager = {}
EffectManager.__index = EffectManager

function EffectManager.new(container, stroke, glow)
    local self = setmetatable({
        _container = container,
        _stroke = stroke,
        _glow = glow,
        _gradient = nil,
        _conn = nil
    }, EffectManager)
    self._conn = RunService.RenderStepped:Connect(function(deltaTime)
        self:update(deltaTime)
    end)
    return self
end

function EffectManager:apply()
    local stroke = self._stroke
    if not stroke then return end
    local settings = Appearance.state.effects
    local mode = settings.border or 'Rotating'
    local intensity = settings.intensity or 0.5

    if self._gradient then
        pcall(function() self._gradient:Destroy() end)
        self._gradient = nil
    end

    if mode == 'Hidden' then
        stroke.Transparency = 1
        stroke.Thickness = 1
    elseif mode == 'Static' then
        stroke.Color = Theme.accent
        stroke.Transparency = 0.75 - intensity * 0.5
        stroke.Thickness = 1 + intensity
    elseif mode == 'Pulse' then
        stroke.Color = Theme.accent
        stroke.Transparency = 0.6
        stroke.Thickness = 1 + intensity * 2
    elseif mode == 'Dual Neon' then
        stroke.Color = Theme.accent
        stroke.Transparency = 0.45 - intensity * 0.25
        stroke.Thickness = 2 + intensity * 2
        local gradient = Instance.new('UIGradient')
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Theme.accent),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Theme.accent)
        }
        gradient.Parent = stroke
        self._gradient = gradient
    else -- Rotating (default)
        stroke.Color = Theme.accent
        stroke.Transparency = 0.65 - intensity * 0.35
        stroke.Thickness = 1 + intensity
        local gradient = Instance.new('UIGradient')
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Theme.accent),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Theme.accent)
        }
        gradient.Parent = stroke
        self._gradient = gradient
    end

    local glow = self._glow
    if glow then
        glow.Visible = settings.glow == true
        glow.ImageColor3 = Theme.accent
        glow.ImageTransparency = 0.8 - intensity * 0.4
    end
end

function EffectManager:update(deltaTime)
    local settings = Appearance.state.effects
    local animation = settings.animation or 1
    local intensity = settings.intensity or 0.5
    if settings.border == 'Rotating' and self._gradient then
        self._gradient.Rotation = (self._gradient.Rotation + 55 * math.min(deltaTime, 0.05) * animation) % 360
    elseif settings.border == 'Pulse' and self._stroke then
        self._stroke.Transparency = 0.55 + math.sin(tick() * 2.4 * animation) * (0.18 + intensity * 0.22)
    end
end

function EffectManager:destroy()
    if self._conn then
        pcall(function() self._conn:Disconnect() end)
        self._conn = nil
    end
end



function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    
    self:create_ui()

    return self
end

-- Create Notification Container
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)  -- Fixed width (300px), dynamic height (Y)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)  -- Right side, offset by 10 from top
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false;
NotificationContainer.Parent = game:GetService("CoreGui").RobloxGui:FindFirstChild("RobloxCoreGuis") or Instance.new("ScreenGui", game:GetService("CoreGui").RobloxGui)
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

-- UIListLayout to arrange notifications vertically
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

-- Function to create notifications
function Library.SendNotification(settings)
    -- Create the notification frame (this will be managed by UIListLayout)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 60)  -- Width = 100% of NotificationContainer's width, dynamic height (Y)
    Notification.BackgroundTransparency = 1  -- Outer frame is transparent for layout to work
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer  -- Parent it to your NotificationContainer (the parent of the list layout)
    Notification.AutomaticSize = Enum.AutomaticSize.Y  -- Allow this frame to resize based on child height

    -- Add rounded corners to outer frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    -- Create the inner frame for the notification's content
    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)  -- Start with an initial height, width will adapt
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)  -- Positioned inside the outer notification frame
    InnerFrame.BackgroundColor3 = Theme.panel
    InnerFrame.BackgroundTransparency = 0.1
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y  -- Automatically resize based on its content

    -- Add rounded corners to the inner frame
    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    -- Title Label (with automatic size support)
    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification Title"
    Title.TextColor3 = Theme.text2
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)  -- Width is 1 (100% of parent width), height is fixed initially
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true  -- Enable wrapping
    Title.AutomaticSize = Enum.AutomaticSize.Y  -- Allow the title to resize based on content
    Title.Parent = InnerFrame

    -- Body Text (with automatic size support)
    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "This is the body of the notification."
    Body.TextColor3 = Theme.muted
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)  -- Width is 1 (100% of parent width), height is fixed initially
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true  -- Enable wrapping for long text
    Body.AutomaticSize = Enum.AutomaticSize.Y  -- Allow the body text to resize based on content
    Body.Parent = InnerFrame

    -- Force the size to adjust after the text is fully loaded and wrapped
    task.spawn(function()
        wait(0.1)  -- Allow text wrapping to finish
        -- Adjust inner frame size based on content
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10  -- Add padding
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)  -- Resize the inner frame
    end)

    -- Use task.spawn to ensure the notification tweening happens asynchronously
    task.spawn(function()
        -- Tween In the Notification (inner frame)
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()

        -- Wait for the duration before tweening out
        local duration = settings.duration or 5  -- Default to 5 seconds if not provided
        wait(duration)

        -- Tween Out the Notification (inner frame) to the right side of the screen
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)  -- Move to the right off-screen
        })
        tweenOut:Play()

        -- Remove the notification after it is done tweening out
        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end


function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end


function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end


function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end


function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end


function Library:create_ui()
    local old_March = CoreGui:FindFirstChild('March')

    if old_March then
        Debris:AddItem(old_March, 0)
    end

    local March = Instance.new('ScreenGui')
    March.ResetOnSpawn = false
    March.Name = 'March'
    March.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    March.Parent = CoreGui

    local AccentGlow = Instance.new('ImageLabel')
    AccentGlow.Name = 'AccentGlow'
    AccentGlow.Image = AssetManager:get('dec_glow') or ''
    AccentGlow.ImageColor3 = Theme.accent
    AccentGlow.ImageTransparency = 0.6
    AccentGlow.Size = UDim2.fromOffset(770, 550)
    AccentGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    AccentGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    AccentGlow.BackgroundTransparency = 1
    AccentGlow.BorderSizePixel = 0
    AccentGlow.ZIndex = 0
    AccentGlow.Active = false
    AccentGlow.Parent = March
    self._accentGlow = AccentGlow

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05000000074505806
    Container.BackgroundColor3 = Theme.main
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = March
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Theme.stroke
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    -- Dedicated graphical background layer + border/glow effect controllers.
    self.GraphicBackground = GraphicBackground.new(March, Container, self)
    self.BackgroundManager = self.GraphicBackground
    self.EffectManager = EffectManager.new(Container, UIStroke, AccentGlow)

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Theme.text
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Theme.text
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Theme.accent
    ClientName.TextTransparency = 0.20000000298023224
    ClientName.Text = 'March'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 31, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.0560000017285347, 0, 0.054999999701976776, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Theme.text
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.muted),
        ColorSequenceKeypoint.new(1, Theme.text)
    }
    UIGradient.Parent = ClientName
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.13600000739097595, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Theme.accent
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Theme.accent
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.02500000037252903, 0, 0.054999999701976776, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Theme.text
    Icon.Parent = Handler
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Theme.stroke
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Theme.text
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = March

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        if self.GraphicBackground then
            self.GraphicBackground:destroy()
            self.GraphicBackground = nil
        end
        if self.EffectManager then
            self.EffectManager:destroy()
            self.EffectManager = nil
        end
        self.BackgroundManager = nil

        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05000000074505806;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        March.Enabled = not March.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
    

    function self:load()
        local content = {}
    
        for _, object in March:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        pcall(function() ContentProvider:PreloadAsync(content) end)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
    
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        AcrylicBlur.new(Container)

        if self.GraphicBackground then
            self.GraphicBackground:apply_settings()
        end

        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)

                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Theme.accent
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Theme.accent
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Theme.text
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Theme.text
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string)
        local TabManager = {}

        local LayoutOrder = 0;

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Theme.secondary
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Theme.text
        TextLabel.TextTransparency = 0.7 -- 0.800000011920929
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Theme.text
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Theme.text),
            ColorSequenceKeypoint.new(0.7, Theme.muted),
            ColorSequenceKeypoint.new(1, Theme.muted2)
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Theme.text
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Theme.text
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Theme.text
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Theme.secondary
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Theme.stroke
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Theme.text
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Theme.accent
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Theme.text
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Theme.accent
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,0,0)'>March</font> user"
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Theme.text
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Theme.accent
            Description.TextTransparency = 0.699999988079071
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Theme.text
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Theme.toggleOff
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.699999988079071
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Theme.accent
            Keybind.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Theme.subtext
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Theme.text
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Theme.stroke
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Theme.stroke
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Theme.text
            Options.Parent = Module
            ModuleManager._options = Options
            ModuleManager._module = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            function ModuleManager:change_state(state: boolean)
                self._state = state

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.accent
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.accent,
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.toggleOff,
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)

                settings.callback(self._state)
            end
            
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
            
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = Theme.accent
                Circle.BackgroundColor3 = Theme.accent
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                    return
                end
                
                Library._choosing_keybind = true
                
                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)

                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)

                        TextLabel.Text = 'None'
                        
                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil

                        Library._choosing_keybind = false

                        return
                    end
                    
                    Connections['keybind_choose_start']:Disconnect()
                    Connections['keybind_choose_start'] = nil
                    
                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    
                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;

                local ParagraphManager = {}
                
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 70
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Theme.panel
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30) -- Initial size, auto-resized later
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule;
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                -- Title Label
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Theme.text2
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Theme.muted
                
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>March</font> user"
                end
                
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                -- Hover effect for Paragraph (optional)
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.panelHover
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.panel
                    }):Play()
                end)

                return ParagraphManager
            end

            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextManager = {}
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 50 -- Adjust the default height for text elements
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Theme.panel
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize) -- Initial size, auto-resized later
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Theme.muted
            
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi" -- Default text
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>March</font> user" -- Default rich text
                end
            
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
                -- Hover effect for TextFrame (optional)
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.panelHover
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.panel
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi" -- Default text
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(255,0,0)'>March</font> user" -- Default rich text
                    end
                end;
            
                return TextManager
            end
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextboxManager = {
                    _text = ""
                }
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 32
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Theme.text
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 10;
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Theme.text
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Theme.accent
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
            
                function TextboxManager:update_text(text: string)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                return TextboxManager
            end   

            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 11
                end
                TitleLabel.TextColor3 = Theme.text
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Theme.accent
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox
            
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 4)
                KeybindCorner.Parent = KeybindBox
            
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag] 
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") 
                    or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.accent
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.accent
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end
            
                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
            
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
            
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            ModuleManager:scale_keybind(true)
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag .. "_keybind"] then
                                Connections[settings.flag .. "_keybind"]:Disconnect()
                                Connections[settings.flag .. "_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
            
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag .. "_keybind"] then
                            Connections[settings.flag .. "_keybind"]:Disconnect()
                            Connections[settings.flag .. "_keybind"] = nil
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
            
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)
            
                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag .. "_keypress"] = keyPressConnection
            
                return CheckboxManager
            end

            function ModuleManager:create_divider(settings: any)
                -- Layout order management
                LayoutOrderModule = LayoutOrderModule + 1;
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 27
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                local dividerHeight = 1
                local dividerWidth = 207 -- Adjust this to fit your UI width
            
                -- Create the outer frame to control spacing above and below
                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20) -- Height here controls spacing above and below
                OuterFrame.BackgroundTransparency = 1 -- Fully invisible
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Theme.text -- 154, 182, 255
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Theme.text
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    -- Create the inner divider frame that will be placed in the middle of the OuterFrame
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Theme.text -- White color
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2) -- Center the divider vertically in the OuterFrame
                
                    -- Add a UIGradient to the divider for left and right transparency
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Theme.text),  -- Start with white
                        ColorSequenceKeypoint.new(0.5, Theme.text), -- Keep it white in the middle
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))  -- Fade to transparent on the right side
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),   
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0 -- Horizontal gradient (fade from left to right)
                
                    -- Optionally, you can add a corner radius for rounded ends
                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2) -- Small corner radius for smooth edges
                    UICorner.Parent = Divider

                end;
            
                return true;
            end
            
            function ModuleManager:create_slider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Theme.text
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Theme.text
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Theme.accent
                Drag.Parent = Slider
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.accent
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Theme.text),
                    ColorSequenceKeypoint.new(1, Theme.muted2)
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Theme.text
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.text
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Theme.text
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    
                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
    
                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold
    
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
    
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
    
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
    
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config);
                        end;
                    end)
                end


                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;
    
                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                return SliderManager
            end

            function ModuleManager:create_dropdown(settings: any)

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 44
                end;

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Theme.text
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Theme.text
                TextLabel.Parent = Dropdown
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.accent
                Box.Parent = TextLabel
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Theme.text
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Theme.text
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 10
                CurrentOption.BackgroundColor3 = Theme.text
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Theme.text
                Arrow.Parent = Header
                
                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Theme.text
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)
                    -- If multi-dropdown is enabled
                    if settings.multi_dropdown then
                        -- Split the CurrentOption.Text by commas into a table

                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;
                        
                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;
                
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        optionSkibidi = "nil";
                        if typeof(option) ~= 'string' then
                            optionSkibidi = option.Name;
                        else
                            optionSkibidi = option;
                        end;

                        local found = false
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}
                        -- Update the transparent effect of each option
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");
                
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else
                        -- For single dropdown, just set the CurrentOption.Text to the selected option
                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                -- Only update transparency for actual option text buttons
                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                
                    -- Save the configuration state
                    Config:save(game.GameId, Library._config)
                
                    -- Callback with the updated option(s)
                    settings.callback(option)
                end
                
                local CurrentDropSizeState = 0;

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    if self._state then
                        ModuleManager._multiplier += self._size

                        CurrentDropSizeState = self._size;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        ModuleManager._multiplier -= self._size

                        CurrentDropSizeState = 0;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Theme.text
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Theme.text
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)
    
                        if index > settings.maximum_options then
                            continue
                        end
    
                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    Dropdown:Destroy(true);
                    value.OrderValue = Dropdown.LayoutOrder
                    ModuleManager._multiplier -= CurrentDropSizeState
                    return ModuleManager:create_dropdown(value)
                end;

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1])
                end
    
                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_feature(settings)

                local checked = false;
                
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size);
                end
            
                Options.Size = UDim2.fromOffset(241, self._size);
            
                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 16)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule
            
                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer
            
                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                FeatureButton.TextSize = 11;
                FeatureButton.Size = UDim2.new(1, -35, 0, 16)
                FeatureButton.BackgroundColor3 = Theme.panel
                FeatureButton.TextColor3 = Theme.text2
                FeatureButton.Text = "    " .. settings.title or "    " .. "Feature"
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer
            
                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer
            
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer
            
                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                KeybindBox.Size = UDim2.new(0, 15, 0, 15)
                KeybindBox.BackgroundColor3 = Theme.accent
                KeybindBox.TextColor3 = Theme.text
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2;
                KeybindBox.Parent = RightContainer
            
                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner", KeybindBox)
                CheckboxCorner.CornerRadius = UDim.new(0, 3)

                local UIStroke = Instance.new("UIStroke", KeybindBox)
                UIStroke.Color = Theme.accent
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
                if not Library._config._flags then
                    Library._config._flags = {}
                end
            
                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end
            
                checked = Library._config._flags[settings.flag].checked
                KeybindBox.Text = Library._config._flags[settings.flag].BIND

                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "...";
                end;

                local UseF_Var = nil;
            
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and Theme.accent or Theme.panel
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1;

                    local UIStroke = Instance.new("UIStroke", Checkbox)
                    UIStroke.Color = Theme.accent
                    UIStroke.Thickness = 1
                    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                
                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox
            
                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and Theme.accent or Theme.panel
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then
                            settings.callback(checked)
                        end
                    end

                    UseF_Var = toggleState
                
                    Checkbox.MouseButton1Click:Connect(toggleState)

                else

                    UseF_Var = function()
                        settings.button_callback();
                    end;

                end;
            
                KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = newKey;
                            end;
                            Config:save(game.GameId, Library._config) -- Save new keybind
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[settings.flag].BIND = "Unknown"
                            KeybindBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        end
                    end)
                    Connections["keybind_input_" .. settings.flag] = inputConnection
                end)
            
                local keyPressConnection
                keyPressConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var();
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection
            
                FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then
                        settings.button_callback()
                    end
                end)

                if not settings.disablecheck then
                    settings.callback(checked);
                end;
            
                return FeatureContainer
            end                    

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        if input.KeyCode ~= Enum.KeyCode.Insert then
            return
        end

        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end

-- ========================================================================= --
--  APPLICATION — built directly into src.lua on top of the original library. --
--  Navigation, feature modules and the integrated GUI customisation page.    --
-- ========================================================================= --

local function resolve_icon(name)
    return AssetManager:get('icon_' .. name) or 'rbxassetid://6023426915'
end

local function get_humanoid()
    local player = Players.LocalPlayer
    if not player then return nil end
    local character = player.Character
    return character and character:FindFirstChildOfClass('Humanoid') or nil
end

local function apply_humanoid(property, value)
    pcall(function()
        local humanoid = get_humanoid()
        if humanoid then humanoid[property] = value end
    end)
end

local function module_open(self, flag)
    self._config._flags[flag] = true
end

local function color_field(self, module, title, flag, role)
    local swatch = nil
    module:create_textbox({
        title = title,
        flag = flag,
        placeholder = color_to_hex(Theme[role]),
        callback = function(text)
            if Appearance:set_color(role, text) and swatch then
                swatch.BackgroundColor3 = Theme[role]
            end
        end
    })
    local options = module._options
    if options then
        for _, object in ipairs(options:GetDescendants()) do
            if object:IsA('TextBox') and object.Name == 'Textbox'
                and object.PlaceholderText == color_to_hex(Theme[role]) then
                swatch = Instance.new('Frame')
                swatch.Name = 'Swatch'
                swatch.Size = UDim2.fromOffset(12, 10)
                swatch.AnchorPoint = Vector2.new(1, 0.5)
                swatch.Position = UDim2.new(1, -4, 0.5, 0)
                swatch.BackgroundColor3 = Theme[role]
                swatch.BorderSizePixel = 0
                swatch.ZIndex = 3
                swatch.Parent = object
                local corner = Instance.new('UICorner')
                corner.CornerRadius = UDim.new(0, 2)
                corner.Parent = swatch
                break
            end
        end
    end
    return swatch
end

function Library:build_application()
    local function tab(title, icon)
        local manager = self:create_tab(title, resolve_icon(icon))
        return manager
    end

    local function add(manager, settings)
        settings.flag = settings.flag or ('module_' .. tostring(math.random(1, 1e9)))
        settings.callback = settings.callback or function() end
        return manager:create_module(settings)
    end

    -- ---------------------------------------------------------------- Combat
    local combat = tab('Combat', 'crosshair')
    module_open(self, 'aimbot_open')
    local aim = add(combat, { section = 'left', title = 'Aimbot', description = 'Silent targeting assistance', flag = 'aimbot_open' })
    aim:create_checkbox({ title = 'Enabled', flag = 'aimbot', callback = function(v) getgenv().ZenthraAimbot = v end })
    aim:create_dropdown({ title = 'Target', flag = 'aim_target', options = { 'Head', 'Torso', 'Closest' }, maximum_options = 8, callback = function(v) getgenv().ZenthraTarget = v end })
    aim:create_slider({ title = 'Smoothness', flag = 'aim_smooth', minimum_value = 1, maximum_value = 100, value = 50, callback = function(v) getgenv().ZenthraSmooth = v end })
    local trigger = add(combat, { section = 'right', title = 'Trigger Bot', description = 'Automatic attack assist', flag = 'trigger_open' })
    trigger:create_checkbox({ title = 'Enabled', flag = 'triggerbot', callback = function(v) getgenv().ZenthraTrigger = v end })
    trigger:create_paragraph({ title = 'Note', text = 'Feature flags are stored in the config and can be bound to a key with right click.' })

    -- ------------------------------------------------------------- Detections
    local detections = tab('Detections', 'shield_alert')
    module_open(self, 'anticheat_open')
    local ac = add(detections, { section = 'left', title = 'Anti Detection', description = 'Client side safety options', flag = 'anticheat_open' })
    ac:create_checkbox({ title = 'Spoof Metadata', flag = 'spoof_meta', callback = function(v) getgenv().ZenthraSpoof = v end })
    ac:create_checkbox({ title = 'Hide Overlay', flag = 'hide_overlay', callback = function(v) getgenv().ZenthraHide = v end })

    -- ---------------------------------------------------------------- Visuals
    local visuals = tab('Visuals', 'eye')
    module_open(self, 'visuals_open')
    local esp = add(visuals, { section = 'left', title = 'Player ESP', description = 'See players through walls', flag = 'visuals_open' })
    esp:create_checkbox({ title = 'Enabled', flag = 'esp', callback = function(v) getgenv().ZenthraESP = v end })
    esp:create_checkbox({ title = 'Name Tags', flag = 'nametags', callback = function(v) getgenv().ZenthraNames = v end })
    esp:create_slider({ title = 'ESPs Limit', flag = 'esp_limit', minimum_value = 1, maximum_value = 32, value = 16, callback = function(v) getgenv().ZenthraESPLimit = v end })

    -- ----------------------------------------------------------------- Player
    local playerTab = tab('Player', 'user')
    module_open(self, 'player_open')
    local movement = add(playerTab, { section = 'left', title = 'Movement', description = 'Character speed and jumping', flag = 'player_open' })
    movement:create_slider({ title = 'Walk Speed', flag = 'walkspeed', minimum_value = 10, maximum_value = 200, value = 50, ignoresaved = true, callback = function(v) apply_humanoid('WalkSpeed', v) end })
    movement:create_slider({ title = 'Jump Power', flag = 'jumppower', minimum_value = 10, maximum_value = 100, value = 50, ignoresaved = true, callback = function(v) apply_humanoid('JumpPower', v) end })
    movement:create_checkbox({ title = 'Infinite Jump', flag = 'infjump', callback = function(v)
        getgenv().ZenthraInfJump = v
        if v then
            Connections['inf_jump'] = UserInputService.JumpRequest:Connect(function()
                apply_humanoid('Jump', true)
            end)
        elseif Connections['inf_jump'] then
            Connections:disconnect('inf_jump')
        end
    end })

    -- ------------------------------------------------------------------ Sword
    local sword = tab('Sword', 'sword')
    module_open(self, 'sword_open')
    local swordModule = add(sword, { section = 'left', title = 'Sword Tools', description = 'Sword enhancements', flag = 'sword_open' })
    swordModule:create_checkbox({ title = 'Sword Aura', flag = 'swordaura', callback = function(v) getgenv().ZenthraAura = v end })
    swordModule:create_slider({ title = 'Reach', flag = 'reach', minimum_value = 3, maximum_value = 30, value = 8, callback = function(v) getgenv().ZenthraReach = v end })

    -- ----------------------------------------------------------------- Avatar
    local avatar = tab('Avatar', 'users')
    module_open(self, 'avatar_open')
    local avatarModule = add(avatar, { section = 'left', title = 'Avatar', description = 'Cosmetic character settings', flag = 'avatar_open' })
    avatarModule:create_checkbox({ title = 'Force R15', flag = 'force_r15', callback = function(v) getgenv().ZenthraR15 = v end })
    avatarModule:create_slider({ title = 'Body Scale', flag = 'bodyscale', minimum_value = 50, maximum_value = 200, value = 100, callback = function(v) getgenv().ZenthraScale = v end })

    -- ------------------------------------------------------------------ World
    local world = tab('World', 'globe')
    module_open(self, 'world_open')
    local worldModule = add(world, { section = 'left', title = 'Environment', description = 'Lighting and atmosphere', flag = 'world_open' })
    worldModule:create_checkbox({ title = 'Fullbright', flag = 'fullbright', callback = function(v)
        pcall(function()
            Lighting.Brightness = v and 3 or 1
            Lighting.Ambient = v and Color3.new(0.6, 0.6, 0.6) or Color3.new(0, 0, 0)
        end)
    end })
    worldModule:create_slider({ title = 'Clock Time', flag = 'clocktime', minimum_value = 0, maximum_value = 24, value = 14, callback = function(v) pcall(function() Lighting.ClockTime = v end) end })

    -- ---------------------------------------------------------------- Blatant
    local blatant = tab('Blatant', 'shield')
    module_open(self, 'blatant_open')
    local blatantModule = add(blatant, { section = 'left', title = 'Blocking', description = 'Defensive automation', flag = 'blatant_open' })
    blatantModule:create_checkbox({ title = 'Auto Block', flag = 'autoblock', callback = function(v) getgenv().ZenthraAutoBlock = v end })
    blatantModule:create_checkbox({ title = 'Instant Block', flag = 'instablock', callback = function(v) getgenv().ZenthraInstantBlock = v end })

    -- -------------------------------------------------------------------- Misc
    local misc = tab('Misc', 'sliders')
    module_open(self, 'misc_open')
    local miscModule = add(misc, { section = 'left', title = 'General', description = 'Small utilities', flag = 'misc_open' })
    miscModule:create_checkbox({ title = 'Speed Feature', flag = 'speed_feature', callback = function(v) getgenv().ZenthraSpeedFeature = v end })
    miscModule:create_slider({ title = 'Sensitivity', flag = 'sens', minimum_value = 1, maximum_value = 100, value = 50, callback = function(v) getgenv().ZenthraSens = v end })
    miscModule:create_paragraph({ title = 'Toggle key', text = 'Press INSERT to show or hide the interface. Right click any control to assign a keybind.' })

    -- ---------------------------------------------------------------- Configs
    local configs = tab('Configs', 'folder')
    module_open(self, 'config_open')
    local configModule = add(configs, { section = 'left', title = 'Configuration', description = 'Save or reset preferences', flag = 'config_open' })
    configModule:create_feature({ title = 'Save config', flag = 'cfg_save', disablecheck = true, button_callback = function()
        Appearance:persist()
        pcall(function() Library.SendNotification({ title = 'Config', text = 'Appearance settings saved.', duration = 3 }) end)
    end })
    configModule:create_feature({ title = 'Reset config', flag = 'cfg_reset', disablecheck = true, button_callback = function()
        Appearance:reset()
        pcall(function() Library.SendNotification({ title = 'Config', text = 'Appearance reset to defaults.', duration = 3 }) end)
    end })

    -- ================================================================= GUI ===
    local gui = tab('GUI', 'panels')
    module_open(self, 'gui_style_open')
    module_open(self, 'gui_theme_open')
    module_open(self, 'gui_bg_open')
    module_open(self, 'gui_fx_open')
    module_open(self, 'gui_appearance_open')

    -- A. Visual Style -------------------------------------------------------
    local styleModule = add(gui, {
        section = 'left', title = 'Visual Style',
        description = 'Complete graphical identities', flag = 'gui_style_open'
    })
    styleModule:create_dropdown({
        title = 'Style', flag = 'gui_style',
        options = { 'Halloween', 'Deep Ocean', 'Liquid Glass', 'Neon', 'Minimal', 'Aurora' },
        maximum_options = 12,
        callback = function(value) Appearance:apply_style(tostring(value)) end
    })
    styleModule:create_paragraph({
        title = 'Complete looks',
        text = 'Each style rebuilds the background layer with its own artwork, lighting, particles and motion — not just a palette swap.'
    })

    -- B. Color Theme --------------------------------------------------------
    local themeModule = add(gui, {
        section = 'right', title = 'Color Theme',
        description = 'Colours only — independent of style', flag = 'gui_theme_open'
    })
    themeModule:create_dropdown({
        title = 'Theme', flag = 'gui_theme',
        options = { 'Midnight', 'Obsidian', 'Dracula', 'Nord', 'Catppuccin', 'AMOLED', 'Frost', 'Emerald', 'Crimson' },
        maximum_options = 12,
        callback = function(value) Appearance:apply_theme(tostring(value)) end
    })
    themeModule:create_divider({ showtopic = true, title = 'Appearance' })
    color_field(self, themeModule, 'Main color', 'color_main', 'main')
    color_field(self, themeModule, 'Secondary color', 'color_secondary', 'secondary')
    color_field(self, themeModule, 'Accent color', 'color_accent', 'accent')
    color_field(self, themeModule, 'Stroke color', 'color_stroke', 'stroke')
    color_field(self, themeModule, 'Text color', 'color_text', 'text')
    color_field(self, themeModule, 'Subtext color', 'color_subtext', 'subtext')

    -- C. Background ---------------------------------------------------------
    local bgModule = add(gui, {
        section = 'left', title = 'Background',
        description = 'Graphical atmosphere behind the menu', flag = 'gui_bg_open'
    })
    bgModule:create_checkbox({
        title = 'Enabled', flag = 'gui_bg_enabled',
        callback = function(value)
            Appearance.state.background.enabled = value
            Appearance:apply_effects()
        end
    })
    bgModule:create_slider({
        title = 'Opacity', flag = 'gui_bg_opacity',
        minimum_value = 0, maximum_value = 1, value = Appearance.state.background.opacity,
        callback = function(value)
            Appearance.state.background.opacity = value
            Appearance:apply_effects()
        end
    })
    bgModule:create_checkbox({
        title = 'Particles', flag = 'gui_bg_particles',
        callback = function(value)
            Appearance.state.background.particles = value
            Appearance:apply_effects()
        end
    })
    bgModule:create_slider({
        title = 'Density', flag = 'gui_bg_density',
        minimum_value = 0, maximum_value = 2, value = Appearance.state.background.density, ignoresaved = true,
        callback = function(value)
            Appearance.state.background.density = value
            Appearance:apply_effects()
        end
    })
    bgModule:create_divider({ showtopic = true, title = 'Window' })
    bgModule:create_slider({
        title = 'Surface', flag = 'gui_surface',
        minimum_value = 0, maximum_value = 0.5, value = Appearance.state.surface, ignoresaved = true,
        callback = function(value)
            Appearance.state.surface = value
            Appearance:apply_effects()
        end
    })
    bgModule:create_feature({ title = 'Preview style', flag = 'gui_preview', disablecheck = true, button_callback = function()
        Appearance:apply_style(Appearance.style)
    end })
    bgModule:create_feature({ title = 'Save settings', flag = 'gui_save', disablecheck = true, button_callback = function()
        Appearance:persist()
        pcall(function() Library.SendNotification({ title = 'GUI', text = 'Appearance saved.', duration = 3 }) end)
    end })
    bgModule:create_feature({ title = 'Refresh assets', flag = 'gui_refresh', disablecheck = true, button_callback = function()
        AssetManager:refresh()
        Appearance:apply_style(Appearance.style)
    end })

    -- D. Effects ------------------------------------------------------------
    local fxModule = add(gui, {
        section = 'right', title = 'Effects',
        description = 'Borders, glow and animation', flag = 'gui_fx_open'
    })
    fxModule:create_dropdown({
        title = 'Border FX', flag = 'gui_border_fx',
        options = { 'Static', 'Rotating', 'Pulse', 'Dual Neon', 'Hidden' },
        maximum_options = 8,
        callback = function(value)
            Appearance.state.effects.border = tostring(value)
            Appearance:apply_effects()
        end
    })
    fxModule:create_slider({
        title = 'FX intensity', flag = 'gui_fx_intensity',
        minimum_value = 0, maximum_value = 1, value = Appearance.state.effects.intensity,
        callback = function(value)
            Appearance.state.effects.intensity = value
            Appearance:apply_effects()
        end
    })
    fxModule:create_checkbox({
        title = 'Accent glow', flag = 'gui_glow',
        callback = function(value)
            Appearance.state.effects.glow = value
            Appearance:apply_effects()
        end
    })
    fxModule:create_slider({
        title = 'Animation', flag = 'gui_anim',
        minimum_value = 0, maximum_value = 3, value = Appearance.state.effects.animation,
        callback = function(value)
            Appearance.state.effects.animation = value
            Appearance:apply_effects()
        end
    })

    -- E. Appearance ---------------------------------------------------------
    local appearanceModule = add(gui, {
        section = 'right', title = 'Appearance',
        description = 'Border and restoration controls', flag = 'gui_appearance_open'
    })
    appearanceModule:create_dropdown({
        title = 'Border style', flag = 'gui_border_style',
        options = { 'Rounded', 'Sharp', 'Soft' }, maximum_options = 6,
        callback = function(value)
            Appearance.state.border = tostring(value)
            Appearance:apply_border()
        end
    })
    appearanceModule:create_feature({ title = 'Reset appearance', flag = 'gui_reset', disablecheck = true, button_callback = function()
        Appearance:reset()
        pcall(function() Library.SendNotification({ title = 'GUI', text = 'Appearance restored.', duration = 3 }) end)
    end })

    self._application_ready = true
    return self
end

-- ========================================================================= --
--  ENTRY POINT — the library is the application.                             --
-- ========================================================================= --

local _MainUI = Library.new()
_MainUI:build_application()
Appearance:init(_MainUI)
_MainUI:load()

Library.Instance = _MainUI
getgenv().ZenthraUI = _MainUI

return Library
