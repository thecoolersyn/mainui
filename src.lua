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
        table.insert(result, trimmedValue)
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
local old_Norepine = CoreGui:FindFirstChild('Norepine')

if old_Norepine then
    Debris:AddItem(old_Norepine, 0)
end

if not isfolder("Norepine") then
    makefolder("Norepine")
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
        local mesh = self._root:FindFirstChildOfClass('SpecialMesh')
        if mesh then
            mesh.Scale = Vector3.new(width, height, 0)
        end
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
            writefile('Norepine/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile('Norepine/'..file_name..'.json') then
                self:save(file_name, config)
        
                return
            end
        
            local flags = readfile('Norepine/'..file_name..'.json')
        
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
--  NOREPINE :: PURE BLACK THEME                                              --
--  Every surface colour below is neutral (R = G = B). No blue/purple tint.  --
-- ========================================================================= --
local Theme = {
    Name       = "Pure Black",
    Window     = Color3.fromRGB(14, 14, 14),     -- main window (opaque)
    Panel      = Color3.fromRGB(32, 32, 32),     -- modules / tabs / notifications
    PanelHover = Color3.fromRGB(40, 40, 40),     -- hovered panels
    Panel2     = Color3.fromRGB(28, 28, 28),     -- search box / inputs
    Track      = Color3.fromRGB(42, 42, 42),     -- toggle & slider tracks
    Knob       = Color3.fromRGB(14, 14, 14),     -- toggle knob when ON
    Muted      = Color3.fromRGB(140, 140, 140),  -- toggle knob when OFF / slider fill
    Stroke     = Color3.fromRGB(46, 46, 46),     -- resting outlines
    Text       = Color3.fromRGB(246, 246, 249),
    TextSoft   = Color3.fromRGB(220, 220, 220),
    TextBody   = Color3.fromRGB(170, 170, 170),
    TextDim    = Color3.fromRGB(150, 150, 150),
    Accent     = Color3.fromRGB(246, 246, 249),
}

-- Lucide icons used by notifications and module controls.
local ICONS = {
    Bell     = "rbxassetid://10709775704",
    BellRing = "rbxassetid://10709775560",
    Check    = "rbxassetid://10709790644",
    X        = "rbxassetid://10747384394",
}

-- Lucide tab icons (same set used by the original Norepine build).
local TAB_ICONS = {
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
    Gui        = "rbxassetid://10709781717",
}

local Accent = {
    Enabled   = true,
    Color     = Theme.Accent,
    BaseColor = Theme.Stroke,
    Speed     = 2.0,
    Glow      = 0.25
}

getgenv().NOREPINE_ACCENT = Accent
getgenv().NOREPINE_THEME = Theme

local function accent()
    return Accent.Color
end

local function accentDim()
    return Accent.Color:Lerp(Color3.new(0, 0, 0), 0.4)
end

local AccentTracks = {}
local AccentGradients = setmetatable({}, { __mode = "k" })
local accentConnection = nil

local function accentGradient()
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Accent.Color, Accent.Color)
    -- hard-edged bar. Peak alpha ~0.78 keeps it bright without looking neon.
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.25, 0.5),
        NumberSequenceKeypoint.new(0.5, 0.22),
        NumberSequenceKeypoint.new(0.75, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    AccentGradients[gradient] = true
    return gradient
end

local function accentStart()
    if accentConnection or not Accent.Enabled then
        return
    end

    accentConnection = RunService.RenderStepped:Connect(function(delta)
        local t = (tick() / math.max(0.15, Accent.Speed)) % 1
        local active = 0

        for track in pairs(AccentTracks) do
            if track.object and track.object.Parent then
                active += 1
                track.update(t)
            else
                AccentTracks[track] = nil
            end
        end

        if active == 0 then
            accentConnection:Disconnect()
            accentConnection = nil
        end
    end)
end

-- Smooth 0 -> 1 -> 0 pulse (flat at both ends) so glints fade in and out
-- instead of sliding across and snapping back at the end of the cycle.
local function glintPulse(phase, period)
    local p = ((tick() / math.max(0.5, period or (Accent.Speed * 3))) + (phase or 0)) % 1
    local s = math.sin(math.pi * p)
    return s * s, p
end

local function accentRegister(object, update)
    AccentTracks[{ object = object, update = update }] = true
    accentStart()
end

function Accent.SetColor(color)
    if typeof(color) ~= "Color3" then return end
    Accent.Color = color
    for gradient in pairs(AccentGradients) do
        gradient.Color = ColorSequence.new(color, color)
    end
end

function Accent.SetSpeed(seconds)
    Accent.Speed = math.max(0.15, tonumber(seconds) or Accent.Speed)
end

function Accent.SetEnabled(state)
    Accent.Enabled = state and true or false
    if not Accent.Enabled and accentConnection then
        accentConnection:Disconnect()
        accentConnection = nil
    elseif Accent.Enabled then
        accentStart()
    end
end

function Accent.Shutdown()
    if accentConnection then
        accentConnection:Disconnect()
        accentConnection = nil
    end
    table.clear(AccentTracks)
end

-- A soft light band that drifts across a surface. In the reference this is
-- part of the glass background itself, not a drawn line on top of the UI.
local function addGlassShimmer(object, name, peak)
    -- The band shape comes entirely from the UIGradient's transparency. The
    -- frame itself stays fully opaque; only the gradient fades the band in
    -- and out. Previously both layers were ~0.93 transparent at the same
    -- time, multiplying down to ~7% opacity and making the shimmer invisible.
    local shimmer = Instance.new('Frame')
    shimmer.Name = name or 'GlassShimmer'
    shimmer.Size = UDim2.fromScale(1, 1)
    shimmer.BackgroundColor3 = Color3.new(1, 1, 1)
    shimmer.BackgroundTransparency = 0
    shimmer.BorderSizePixel = 0
    shimmer.ZIndex = 0
    shimmer.Active = false
    shimmer.Selectable = false
    shimmer.Parent = object

    -- `peak` is the maximum opacity of the glow (kept low, ~0.06-0.1, so it
    -- reads as a soft light rather than a white bar). Convert to transparency.
    local peakOpacity = peak or 0.08
    local center = 1 - peakOpacity
    local gradient = Instance.new('UIGradient')
    -- A gentle colour gradient (cool white -> soft grey -> cool white) instead
    -- of a flat white band, so the glow has depth.
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 205, 215)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 205, 215))
    })
    -- Wide, smooth bell curve so the light fades gradually with no hard edge.
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.12, 0.93),
        NumberSequenceKeypoint.new(0.3, center + (1 - center) * 0.55),
        NumberSequenceKeypoint.new(0.5, center),
        NumberSequenceKeypoint.new(0.7, center + (1 - center) * 0.55),
        NumberSequenceKeypoint.new(0.88, 0.93),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Rotation = 45
    gradient.Parent = shimmer

    local phase = math.random()
    local period = 13 -- slow, calm sweep
    local function updateGlint()
        local pulse, p = glintPulse(phase, period)
        -- Drift gently across the surface; smaller range = calmer movement.
        gradient.Offset = Vector2.new((p - 0.5) * 1.0, 0)
    end
    accentRegister(shimmer, updateGlint)
    task.spawn(function()
        while shimmer.Parent do
            task.wait(1 / 30)
            if not accentConnection then updateGlint() end
        end
    end)

    return shimmer
end

-- A fixed white light band laid over a surface. Uses the same proven
-- UIGradient-transparency trick as the window shimmer, but never moves.
local function addStaticSheen(parent, name, peak, rotation)
    local sheen = Instance.new('Frame')
    sheen.Name = name or 'CardSheen'
    sheen.Size = UDim2.fromScale(1, 1)
    sheen.BackgroundColor3 = Color3.new(1, 1, 1)
    sheen.BackgroundTransparency = 0
    sheen.BorderSizePixel = 0
    sheen.ZIndex = 0
    sheen.Active = false
    sheen.Selectable = false
    sheen.Parent = parent

    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.28, 0.95),
        NumberSequenceKeypoint.new(0.5, peak or 0.55),
        NumberSequenceKeypoint.new(0.72, 0.95),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Rotation = rotation or 40
    gradient.Parent = sheen

    return sheen
end

-- Card face: an explicit overlay layer so the grey top-half gradient always
-- renders (a UIGradient directly on the card is ignored by this runtime).
local function addCardFace(parent, name, corner)
    local face = Instance.new('Frame')
    face.Name = name or 'CardFace'
    face.Size = UDim2.fromScale(1, 1)
    face.BackgroundColor3 = Color3.new(1, 1, 1)
    face.BackgroundTransparency = 0
    face.BorderSizePixel = 0
    face.ZIndex = 0
    face.Active = false
    face.Selectable = false
    face.Parent = parent

    local faceCorner = Instance.new('UICorner')
    faceCorner.CornerRadius = UDim.new(0, corner or 8)
    faceCorner.Parent = face

    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new(Color3.fromRGB(58, 58, 58), Color3.fromRGB(10, 10, 10))
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.35, 0.5),
        NumberSequenceKeypoint.new(0.7, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Rotation = 45
    gradient.Parent = face

    return face
end

local KEY_NAMES = {
    One = '1', Two = '2', Three = '3', Four = '4', Five = '5',
    Six = '6', Seven = '7', Eight = '8', Nine = '9', Zero = '0',
    LeftShift = 'LShift', RightShift = 'RShift',
    LeftControl = 'LCtrl', RightControl = 'RCtrl',
    LeftAlt = 'LAlt', RightAlt = 'RAlt',
    Return = 'Enter', Escape = 'Esc',
}

local function keyName(value)
    local name = tostring(value):gsub('Enum%.KeyCode%.', '')
    return KEY_NAMES[name] or name
end

-- Norepine rebind chip: small dark rounded square with a faint outline.
-- It is a single TextLabel that grows with its text (min 16x16).
local function makeRebindChip(parent, text)
    local chip = Instance.new('TextLabel')
    chip.Name = 'RebindChip'
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.Size = UDim2.fromOffset(16, 16)
    chip.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    chip.BackgroundTransparency = 0.1
    chip.BorderSizePixel = 0
    chip.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    chip.Text = text or '-'
    chip.TextSize = 10
    chip.TextColor3 = Color3.fromRGB(235, 235, 235)
    chip.TextXAlignment = Enum.TextXAlignment.Center
    chip.TextYAlignment = Enum.TextYAlignment.Center

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = chip

    local stroke = Instance.new('UIStroke')
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = chip

    local pad = Instance.new('UIPadding')
    pad.PaddingLeft = UDim.new(0, 5)
    pad.PaddingRight = UDim.new(0, 5)
    pad.Parent = chip

    local limit = Instance.new('UISizeConstraint')
    limit.MinSize = Vector2.new(16, 16)
    limit.Parent = chip

    chip.Parent = parent
    return chip
end

-- Module card face: a soft light falloff from the top-left corner into the
-- flat near-black card, like the Norepine module cards.
local function addModuleFace(parent, name)
    -- Solid backing first so the window shimmer cannot show through unevenly
    -- and make only one card look brighter than the others.
    local backing = Instance.new('Frame')
    backing.Name = 'CardBacking'
    backing.Size = UDim2.fromScale(1, 1)
    backing.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    backing.BackgroundTransparency = 0
    backing.BorderSizePixel = 0
    backing.ZIndex = 0
    backing.Parent = parent
    local backingCorner = Instance.new('UICorner')
    backingCorner.CornerRadius = UDim.new(0, 8)
    backingCorner.Parent = backing

    local face = Instance.new('Frame')
    face.Name = name or 'CardFace'
    face.Size = UDim2.fromScale(1, 1)
    face.BackgroundColor3 = Color3.new(1, 1, 1)
    face.BackgroundTransparency = 1
    face.BorderSizePixel = 0
    face.ZIndex = 0
    face.Active = false
    face.Selectable = false
    face.Parent = parent

    local faceCorner = Instance.new('UICorner')
    faceCorner.CornerRadius = UDim.new(0, 8)
    faceCorner.Parent = face

    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.62),
        NumberSequenceKeypoint.new(0.35, 0.82),
        NumberSequenceKeypoint.new(0.7, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Rotation = 30
    gradient.Parent = face

    return face
end

local function createAccentLine(parent, position, width, name)
    local clip = Instance.new("Frame")
    clip.Name = name
    clip.Size = UDim2.fromOffset(width, 5)
    clip.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset - 2)
    clip.BackgroundTransparency = 1
    clip.BorderSizePixel = 0
    clip.ClipsDescendants = true
    clip.Parent = parent

    local base = Instance.new("Frame")
    base.Name = "Base"
    base.Size = UDim2.new(1, 0, 0, 1)
    base.Position = UDim2.new(0, 0, 0.5, -0.5)
    base.BackgroundColor3 = Accent.BaseColor
    base.BackgroundTransparency = 0.5
    base.BorderSizePixel = 0
    base.Parent = clip

    local segment = Instance.new("Frame")
    segment.Name = "Segment"
    segment.Size = UDim2.fromOffset(math.max(40, math.floor(width * 0.6)), 1)
    segment.Position = UDim2.new(0, 0, 0.5, -0.5)
    segment.BackgroundColor3 = Accent.Color
    segment.BackgroundTransparency = 1
    segment.BorderSizePixel = 0
    segment.Parent = clip
    accentGradient().Parent = segment

    local phase = math.random()
    accentRegister(clip, function()
        local pulse, p = glintPulse(phase, Accent.Speed * 2)
        local length = segment.Size.X.Offset
        segment.Position = UDim2.new(0, (width - length) * (0.15 + 0.7 * p), 0.5, -0.5)
        segment.BackgroundTransparency = 1 - pulse
    end)
end

local function createAccentBorder(object, thickness)
    local base = object:FindFirstChild("BaseOutline") or Instance.new("UIStroke")
    base.Name = "BaseOutline"
    base.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    base.Color = Accent.BaseColor
    base.Transparency = 0.45
    base.Thickness = thickness or 1
    base.Parent = object

    local stroke = object:FindFirstChild("AccentOutline") or Instance.new("UIStroke")
    stroke.Name = "AccentOutline"
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Accent.Color
    stroke.Transparency = 0
    stroke.Thickness = thickness or 1
    stroke.Parent = object

    local gradient = stroke:FindFirstChild("AccentGradient") or Instance.new("UIGradient")
    gradient.Name = "AccentGradient"
    gradient.Color = ColorSequence.new(Accent.Color, Accent.Color)
    -- Bright short segment sweeping around the border. A single gradient
    -- controls visibility; the stroke itself stays at a low transparency.
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.42, 1),
        NumberSequenceKeypoint.new(0.48, 0.15),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.52, 0.15),
        NumberSequenceKeypoint.new(0.58, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Parent = stroke
    AccentGradients[gradient] = true

    local phase = math.random()
    stroke.Transparency = 0
    local function updateBorder()
        local pulse, p = glintPulse(phase)
        gradient.Rotation = p * 360
    end
    accentRegister(object, updateBorder)
    task.spawn(function()
        while stroke.Parent do
            task.wait(1 / 30)
            if not accentConnection then updateBorder() end
        end
    end)

    return stroke
end

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
--  CUSTOM BACKGROUND SUPPORT                                                --
--  Adds a real, separate background rendering layer behind the existing UI.  --
--  Supports images, GIFs, videos, local files, URLs, opacity, save/delete/   --
--  refresh and persistence through the library's original Config system.   --
-- ========================================================================= --

local BACKGROUND_FOLDER = 'Norepine/backgrounds'

local function bg_notify(title, text, duration)
    pcall(function()
        Library.SendNotification({ title = title, text = text, duration = duration or 3 })
    end)
end

local function bg_media_type(name)
    local ext = tostring(name or ''):lower():match('%.([%w]+)$')
    if ext == 'mp4' or ext == 'webm' or ext == 'mov' or ext == 'avi' then return 'video' end
    if ext == 'gif' or ext == 'png' or ext == 'jpg' or ext == 'jpeg' or ext == 'webp' or ext == 'bmp' or ext == 'tga' then return 'image' end
    return nil
end

local function bg_sanitize(name)
    return (tostring(name or ''):gsub('[^%w%._%-]', '_'))
end

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new(container, library)
    local self = setmetatable({
        _container = container,
        _library = library,
        _current_path = nil,
    }, BackgroundManager)

    pcall(function()
        if not isfolder('Norepine') then makefolder('Norepine') end
        if not isfolder(BACKGROUND_FOLDER) then makefolder(BACKGROUND_FOLDER) end
    end)

    -- Dedicated layer: rendered BEHIND the Handler (ZIndex 0 vs default 1),
    -- clipped by the Container, and never interactive.
    local layer = Instance.new('Frame')
    layer.Name = 'BackgroundLayer'
    layer.Size = UDim2.fromScale(1, 1)
    layer.Position = UDim2.fromScale(0, 0)
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.ZIndex = 0
    layer.Active = false
    layer.Selectable = false
    layer.Visible = false
    layer.Parent = container
    self._layer = layer

    local image = Instance.new('ImageLabel')
    image.Name = 'BackgroundImage'
    image.Size = UDim2.fromScale(1, 1)
    image.ScaleType = Enum.ScaleType.Crop
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.ZIndex = 0
    image.Active = false
    image.Selectable = false
    image.Visible = false
    image.Parent = layer
    self._image = image

    local ok, video = pcall(function()
        local v = Instance.new('VideoFrame')
        v.Name = 'BackgroundVideo'
        v.Size = UDim2.fromScale(1, 1)
        v.ScaleType = Enum.ScaleType.Crop
        v.BackgroundTransparency = 1
        v.BorderSizePixel = 0
        v.ZIndex = 0
        v.Active = false
        v.Selectable = false
        v.Visible = false
        v.Parent = layer
        return v
    end)
    self._video = ok and video or nil

    return self
end

function BackgroundManager:_state()
    local cfg = self._library._config
    cfg._appearance = cfg._appearance or {}
    cfg._appearance.background = cfg._appearance.background or {
        enabled = false,
        media = 'None',
        opacity = 1,
    }
    return cfg._appearance.background
end

function BackgroundManager:persist()
    pcall(function()
        Config:save(game.GameId, self._library._config)
    end)
end

function BackgroundManager:list()
    local out = { 'None' }
    pcall(function()
        for _, path in ipairs(listfiles(BACKGROUND_FOLDER)) do
            local name = tostring(path):match('([^/\\]+)$')
            if name and bg_media_type(name) then
                table.insert(out, name)
            end
        end
    end)
    table.sort(out, function(a, b)
        if a == 'None' then return true end
        if b == 'None' then return false end
        return a:lower() < b:lower()
    end)
    return out
end

function BackgroundManager:refresh()
    return self:list()
end

function BackgroundManager:set_enabled(state)
    self:_state().enabled = state == true
    self:apply()
    self:persist()
    return self:_state().enabled
end

function BackgroundManager:set_opacity(value)
    value = tonumber(value)
    if not value then return self:_state().opacity end
    value = math.clamp(value, 0, 1)
    self:_state().opacity = value
    self:apply()
    self:persist()
    return value
end

function BackgroundManager:set_media(name)
    name = tostring(name or 'None')
    if name == '' then name = 'None' end
    if name:match('^https?://') then
        return self:load_url(name)
    end
    if name ~= 'None' and not bg_media_type(name) then
        bg_notify('Background', 'Unsupported media type: ' .. name)
        return false, 'Unsupported media type'
    end
    self:_state().media = name
    if name ~= 'None' then self:_state().enabled = true end
    self:apply()
    self:persist()
    return true, name
end

function BackgroundManager:apply()
    local state = self:_state()
    local enabled = state.enabled == true
    local media = state.media or 'None'
    local opacity = tonumber(state.opacity) or 1

    self._layer.Visible = enabled
    self._image.Visible = false
    if self._video then self._video.Visible = false end
    self._current_path = nil

    if not enabled or media == 'None' then return true end

    local path = BACKGROUND_FOLDER .. '/' .. media
    if media:match('^https?://') then path = media end
    local kind = bg_media_type(media)
    if not kind then
        bg_notify('Background', 'Unsupported media type: ' .. tostring(media))
        return false, 'Unsupported media type'
    end

    local asset = nil
    pcall(function()
        if path:match('^https?://') then
            asset = path
        else
            asset = typeof(getcustomasset) == 'function' and getcustomasset(path) or nil
        end
    end)

    if not asset then
        bg_notify('Background', 'Could not load media: ' .. tostring(media))
        return false, 'Could not load media'
    end

    self._current_path = path

    if kind == 'video' and self._video then
        local ok = pcall(function()
            self._video.Video = asset
            self._video.ImageTransparency = 1 - math.clamp(opacity, 0, 1)
            self._video.Visible = true
        end)
        if not ok then
            self._video.Visible = false
            bg_notify('Background', 'This runtime cannot render video backgrounds')
            self._image.Image = asset
            self._image.ImageTransparency = 1 - math.clamp(opacity, 0, 1)
            self._image.Visible = true
        end
    else
        self._image.Image = asset
        self._image.ImageTransparency = 1 - math.clamp(opacity, 0, 1)
        self._image.Visible = true
    end

    return true
end

function BackgroundManager:load_url(url, save_name)
    url = tostring(url or '')
    if not url:match('^https?://') then
        bg_notify('Background', 'URL must start with http:// or https://')
        return false, 'Invalid URL'
    end

    local data
    local ok = pcall(function()
        if typeof(game.HttpGet) == 'function' then
            data = game:HttpGet(url, true)
        elseif typeof(httpget) == 'function' then
            data = httpget(url)
        end
    end)
    if not ok or not data or #data == 0 then
        bg_notify('Background', 'Download failed')
        return false, 'Download failed'
    end

    local ext = url:lower():match('%.([%w]+)%??[^/]*$') or 'png'
    local kind = bg_media_type('background.' .. ext) or 'image'
    if kind == 'video' and ext ~= 'mp4' and ext ~= 'webm' then ext = 'mp4' end

    local filename = bg_sanitize(save_name and save_name ~= '' and save_name or 'background') .. '.' .. ext
    local path = BACKGROUND_FOLDER .. '/' .. filename
    local wok = pcall(function() writefile(path, data) end)
    if not wok then
        bg_notify('Background', 'Could not save downloaded media')
        return false, 'Could not write file'
    end

    local state = self:_state()
    state.media = filename
    state.enabled = true
    self:apply()
    self:persist()
    bg_notify('Background', 'Loaded ' .. filename, 3)
    return true, filename
end

function BackgroundManager:save(save_name)
    local state = self:_state()
    local media = state.media or 'None'
    if media == 'None' or media:match('^https?://') then
        bg_notify('Background', 'Select a local background first')
        return false, 'No local media selected'
    end

    local src = BACKGROUND_FOLDER .. '/' .. media
    local data
    local ok = pcall(function() data = readfile(src) end)
    if not ok or not data then
        bg_notify('Background', 'Selected background file is missing')
        return false, 'Source media missing'
    end

    local name = bg_sanitize(save_name and save_name ~= '' and save_name or media)
    if not bg_media_type(name) then name = name .. '.png' end
    local path = BACKGROUND_FOLDER .. '/' .. name
    local wok = pcall(function() writefile(path, data) end)
    if not wok then
        bg_notify('Background', 'Could not save background')
        return false, 'Could not save'
    end

    bg_notify('Background', 'Saved as ' .. name, 3)
    return true, name
end

function BackgroundManager:delete(name)
    name = tostring(name or '')
    if name == '' or name == 'None' then
        bg_notify('Background', 'Nothing selected')
        return false, 'Nothing selected'
    end

    local path = BACKGROUND_FOLDER .. '/' .. name
    local ok = pcall(function()
        if typeof(delfile) == 'function' then
            delfile(path)
        elseif typeof(deletefile) == 'function' then
            deletefile(path)
        end
    end)
    if not ok then
        bg_notify('Background', 'Could not delete ' .. name)
        return false, 'Could not delete'
    end

    local state = self:_state()
    if state.media == name then
        state.media = 'None'
        state.enabled = false
        self:apply()
    end
    self:persist()
    bg_notify('Background', 'Deleted ' .. name, 3)
    return true, name
end

function BackgroundManager:destroy()
    pcall(function()
        if self._video then self._video.Video = nil end
        if self._layer then self._layer:Destroy() end
    end)
    self._layer = nil
    self._image = nil
    self._video = nil
end

-- Convenience API for the application / GUI page.
function Library:SetBackground(settings)
    local bg = self.BackgroundManager
    if not bg then return false, 'Background manager not ready' end
    settings = settings or {}
    if settings.enabled ~= nil then bg:set_enabled(settings.enabled) end
    if settings.opacity ~= nil then bg:set_opacity(settings.opacity) end
    if settings.media ~= nil then
        local media = tostring(settings.media)
        if media:match('^https?://') then
            return bg:load_url(media, settings.save_as)
        end
        return bg:set_media(media)
    end
    bg:apply()
    bg:persist()
    return true
end

function Library:GetBackgroundManager()
    return self.BackgroundManager
end

function Library:SetAccentColor(color)
    if typeof(color) == "Color3" then
        Accent.Color = color
    end
end

-- Attach ready-made background controls to any module created with
-- create_module().  This keeps navigation untouched while making the
-- background system fully usable from a settings page.
function Library:create_background_settings(module)
    if not module then return nil end
    local bg = self.BackgroundManager
    if not bg then return nil end
    local state = bg:_state()

    module:create_checkbox({
        title = 'Enabled',
        flag = '__zbg_enabled',
        callback = function(value) bg:set_enabled(value) end,
    })

    module:create_dropdown({
        title = 'Media',
        flag = '__zbg_media',
        options = bg:list(),
        maximum_options = 64,
        callback = function(value) bg:set_media(tostring(value)) end,
    })

    module:create_slider({
        title = 'Opacity',
        flag = '__zbg_opacity',
        minimum_value = 0,
        maximum_value = 1,
        value = state.opacity,
        callback = function(value) bg:set_opacity(value) end,
    })

    module:create_textbox({
        title = 'Media URL',
        flag = '__zbg_url',
        placeholder = 'https://.../background.png',
        callback = function(text) self._zbg_url = text end,
    })

    module:create_textbox({
        title = 'Save as',
        flag = '__zbg_name',
        placeholder = 'background',
        callback = function(text) self._zbg_name = text end,
    })

    -- ModuleManager does not expose its Options frame, so discover it from the
    -- last created control's parent.
    local options
    for _, obj in ipairs(self._ui:GetDescendants()) do
        if obj:IsA('TextBox') and obj.Name == 'Textbox' and obj.PlaceholderText == 'background' then
            options = obj.Parent
            break
        end
    end

    local function make_action(title, flag, callback)
        local btn = Instance.new('TextButton')
        btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        btn.Text = title
        btn.TextSize = 10
        btn.TextColor3 = Theme.TextSoft
        btn.BackgroundColor3 = Theme.Panel
        btn.BackgroundTransparency = 0.1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Size = UDim2.fromOffset(207, 22)
        btn.Name = flag
        if options then btn.Parent = options end
        local corner = Instance.new('UICorner')
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    make_action('Download and use', '__zbg_download', function()
        bg:load_url(self._zbg_url or '', self._zbg_name)
    end)
    make_action('Save background', '__zbg_save', function()
        bg:save(self._zbg_name)
    end)
    make_action('Delete selected background', '__zbg_delete', function()
        bg:delete(bg:_state().media)
    end)
    make_action('Refresh list', '__zbg_refresh', function()
        bg_notify('Background', #bg:refresh() - 1 .. ' available', 3)
    end)

    return bg
end





function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    
    self:create_ui()

    return self
end

-- Create Notification Container (unique name so re-injections clean up after
-- themselves instead of stacking hidden toast layers).
local NOTIF_NAME = "NorepineNotifications"
pcall(function()
    for _, obj in ipairs(CoreGui.RobloxGui:GetDescendants()) do
        if obj.Name == NOTIF_NAME then
            obj:Destroy()
        end
    end
end)

local NotifGui = CoreGui.RobloxGui:FindFirstChild('NorepineNotifGui') or Instance.new('ScreenGui', CoreGui.RobloxGui)
NotifGui.Name = 'NorepineNotifGui'
NotifGui.ResetOnSpawn = false

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = NOTIF_NAME
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.Position = UDim2.new(1, -310, 0, 12)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.Parent = NotifGui

-- UIListLayout to arrange notifications vertically
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

-- Norepine-style toast: Lucide bell, status check/x and a close button.
function Library.SendNotification(settings)
    settings = settings or {}
    local isOn = settings.state == true
    local StateIcon
    if settings.kind == "bell" then
        StateIcon = ICONS.Bell
    elseif settings.kind == "check" or settings.kind == "x" then
        StateIcon = (settings.kind == "check" and ICONS.Check or ICONS.X)
    else
        StateIcon = isOn and ICONS.Check or ICONS.X
    end

    local Notification = Instance.new("Frame")
    Notification.Name = "Notification"
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.AutomaticSize = Enum.AutomaticSize.Y
    Notification.Parent = NotificationContainer

    local Card = Instance.new("Frame")
    Card.Name = "Card"
    Card.Size = UDim2.new(1, 0, 0, 62)
    Card.AutomaticSize = Enum.AutomaticSize.Y
    Card.BackgroundColor3 = Theme.Window
    Card.BackgroundTransparency = 0
    Card.BorderSizePixel = 0
    Card.Parent = Notification

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Card

    -- Pure-black gradient face. Built as an explicit overlay frame so it
    -- renders on every device/runtime (a direct UIGradient is ignored by some).
    local Face = Instance.new("Frame")
    Face.Name = "Face"
    Face.Size = UDim2.fromScale(1, 1)
    Face.BackgroundColor3 = Color3.new(1, 1, 1)
    Face.BackgroundTransparency = 1
    Face.BorderSizePixel = 0
    Face.ZIndex = 0
    Face.Active = false
    Face.Selectable = false
    Face.Parent = Card
    local FaceCorner = Instance.new("UICorner")
    FaceCorner.CornerRadius = UDim.new(0, 8)
    FaceCorner.Parent = Face
    local FaceGradient = Instance.new("UIGradient")
    FaceGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    FaceGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.78),
        NumberSequenceKeypoint.new(0.55, 0.94),
        NumberSequenceKeypoint.new(1, 1)
    })
    FaceGradient.Rotation = 45
    FaceGradient.Parent = Face

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Accent.BaseColor
    Stroke.Transparency = 0.4
    Stroke.Thickness = 1
    Stroke.Parent = Card

    local TopStrip = Instance.new("Frame")
    TopStrip.Name = "TopStrip"
    TopStrip.Size = UDim2.new(1, 0, 0, 2)
    TopStrip.Position = UDim2.new(0, 0, 0, 0)
    TopStrip.BackgroundColor3 = settings.strip or Color3.fromRGB(235, 90, 150)
    TopStrip.BorderSizePixel = 0
    TopStrip.Parent = Card

    local Icon = Instance.new("ImageLabel")
    Icon.Name = "Icon"
    Icon.Image = StateIcon
    Icon.ImageColor3 = Color3.new(1, 1, 1)
    Icon.Size = UDim2.fromOffset(18, 18)
    Icon.Position = UDim2.fromOffset(12, 12)
    Icon.BackgroundTransparency = 1
    Icon.Parent = Card

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification"
    Title.TextColor3 = Theme.Text
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 12
    Title.Size = UDim2.new(1, -76, 0, 16)
    Title.Position = UDim2.fromOffset(38, 10)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Card

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or ""
    Body.TextColor3 = Theme.TextBody
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 10
    Body.Size = UDim2.new(1, -76, 0, 16)
    Body.Position = UDim2.fromOffset(38, 28)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = Card

    -- Timer line at the bottom: starts full and shrinks to the left as the
    -- notification approaches its dismissal, showing remaining time.
    local Timer = Instance.new("Frame")
    Timer.Name = "Timer"
    Timer.Size = UDim2.new(1, 0, 0, 2)
    Timer.Position = UDim2.new(0, 0, 1, -2)
    Timer.AnchorPoint = Vector2.new(0, 0)
    Timer.BackgroundColor3 = accent()
    Timer.BackgroundTransparency = 0.25
    Timer.BorderSizePixel = 0
    Timer.Parent = Card

    local Close = Instance.new("TextButton")
    Close.Name = "Close"
    Close.Text = "×"
    Close.TextColor3 = Theme.TextDim
    Close.Font = Enum.Font.SourceSans
    Close.TextSize = 16
    Close.Size = UDim2.fromOffset(16, 16)
    Close.Position = UDim2.new(1, -22, 0, 12)
    Close.BackgroundTransparency = 1
    Close.AutoButtonColor = false
    Close.Parent = Card

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        local out = TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 320, 0, 0),
            BackgroundTransparency = 1
        })
        out:Play()
        out.Completed:Connect(function() Notification:Destroy() end)
    end
    Close.MouseButton1Click:Connect(dismiss)

    task.spawn(function()
        Card.Position = UDim2.new(1, 320, 0, 0)
        local tweenIn = TweenService:Create(Card, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()
        local duration = settings.duration or 4
        -- Drain the timer line linearly over the visible lifetime.
        local timeTween = TweenService:Create(Timer, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 0, 2)
        })
        timeTween:Play()
        task.wait(duration)
        dismiss()
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
    local old_Norepine = CoreGui:FindFirstChild('Norepine')

    if old_Norepine then
        Debris:AddItem(old_Norepine, 0)
    end

    local Norepine = Instance.new('ScreenGui')
    Norepine.ResetOnSpawn = false
    Norepine.Name = 'Norepine'
    Norepine.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Norepine.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Theme.Window
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Norepine
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container
    
    createAccentBorder(Container)

    -- The moving light lives in the glass background, not as a UI line.
    addGlassShimmer(Container, 'WindowShimmer', 0.08)

    -- Custom background: separate rendering layer behind the Handler.
    self.BackgroundManager = BackgroundManager.new(Container, self)

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    -- Faint white glints that drift to random spots across the glass.
    local glints = {}
    for _ = 1, 12 do
        local dot = Instance.new('Frame')
        dot.Name = 'Glint'
        dot.Size = UDim2.fromOffset(2, 2)
        dot.Position = UDim2.fromOffset(math.random(10, 680), math.random(10, 460))
        dot.BackgroundColor3 = Color3.new(1, 1, 1)
        dot.BackgroundTransparency = math.random(82, 95) / 100
        dot.BorderSizePixel = 0
        dot.ZIndex = 0
        dot.Parent = Handler
        local corner = Instance.new('UICorner')
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        table.insert(glints, dot)
    end
    task.spawn(function()
        while Handler.Parent do
            task.wait(math.random(15, 40) / 10)
            for _, dot in ipairs(glints) do
                if dot.Parent then
                    TweenService:Create(dot, TweenInfo.new(math.random(10, 25) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = UDim2.fromOffset(math.random(10, 680), math.random(10, 460))
                    }):Play()
                end
            end
        end
    end)
    
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
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 0)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextButton')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Theme.Text
    ClientName.TextTransparency = 0
    ClientName.Text = 'Norepine'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.fromOffset(0, 16)
    ClientName.AutomaticSize = Enum.AutomaticSize.X
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.fromOffset(20, 21)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.TextSize = 14
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.AutoButtonColor = false
    ClientName.Parent = Handler

    local font_params = Instance.new('GetTextBoundsParams')
    font_params.Text = 'Norepine'
    font_params.Font = ClientName.FontFace
    font_params.Size = 14
    font_params.Width = 10000
    local z_width = TextService:GetTextBoundsAsync(font_params).X

    local SubTitle = Instance.new('TextLabel')
    SubTitle.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    SubTitle.TextColor3 = Theme.TextDim
    SubTitle.Text = 'Blade Ball'
    SubTitle.Name = 'SubTitle'
    SubTitle.Size = UDim2.fromOffset(0, 12)
    SubTitle.AutomaticSize = Enum.AutomaticSize.X
    SubTitle.AnchorPoint = Vector2.new(0, 0.5)
    SubTitle.Position = UDim2.new(0, 20 + z_width + 10, 0, 23)
    SubTitle.BackgroundTransparency = 1
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.TextSize = 9
    SubTitle.BorderSizePixel = 0
    SubTitle.Parent = Handler

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Accent.BaseColor
    Divider.Parent = Handler

    local ContentContainer = Instance.new('Frame')
    ContentContainer.Name = 'ContentContainer'
    ContentContainer.Position = UDim2.fromOffset(170, 60)
    ContentContainer.Size = UDim2.fromOffset(520, 410)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = Handler

    local ContentCorner = Instance.new('UICorner')
    ContentCorner.CornerRadius = UDim.new(0, 6)
    ContentCorner.Parent = ContentContainer


    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local SearchFrame = Instance.new('Frame')
    SearchFrame.Name = 'SearchFrame'
    SearchFrame.Position = UDim2.fromOffset(418, 16)
    SearchFrame.Size = UDim2.fromOffset(190, 26)
    SearchFrame.BackgroundColor3 = Theme.Panel2
    SearchFrame.BackgroundTransparency = 0.1
    SearchFrame.BorderSizePixel = 0
    SearchFrame.Parent = Handler

    local SearchCorner = Instance.new('UICorner')
    SearchCorner.CornerRadius = UDim.new(0, 4)
    SearchCorner.Parent = SearchFrame

    local SearchStroke = Instance.new('UIStroke')
    SearchStroke.Color = Accent.BaseColor
    SearchStroke.Transparency = 0.5
    SearchStroke.Thickness = 1
    SearchStroke.Parent = SearchFrame

    local SearchIcon = Instance.new('ImageLabel')
    SearchIcon.Image = 'rbxassetid://7734052925'
    SearchIcon.ImageColor3 = Theme.TextDim
    SearchIcon.Size = UDim2.fromOffset(12, 12)
    SearchIcon.Position = UDim2.fromOffset(8, 7)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Parent = SearchFrame

    local SearchBox = Instance.new('TextBox')
    SearchBox.Name = 'SearchInput'
    SearchBox.Position = UDim2.fromOffset(22, 0)
    SearchBox.Size = UDim2.fromOffset(162, 26)
    SearchBox.BackgroundTransparency = 1
    SearchBox.Font = Enum.Font.SourceSans
    SearchBox.TextSize = 10
    SearchBox.TextColor3 = Theme.Text
    SearchBox.PlaceholderColor3 = Theme.TextDim
    SearchBox.PlaceholderText = 'Search'
    SearchBox.Text = ''
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = SearchFrame

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Theme.TextDim
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = '–'
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.fromOffset(660, 20)
    Minimize.Size = UDim2.fromOffset(24, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 18
    Minimize.TextTransparency = 1
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local MinimizeIcon = Instance.new('ImageLabel')
    MinimizeIcon.Image = 'rbxassetid://10734896206'
    MinimizeIcon.ImageColor3 = Theme.TextDim
    MinimizeIcon.Size = UDim2.fromOffset(14, 14)
    MinimizeIcon.Position = UDim2.fromScale(0.5, 0.5)
    MinimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIcon.BackgroundTransparency = 1
    MinimizeIcon.Parent = Minimize

    ClientName.MouseButton1Click:Connect(function()
        self:toggle_visibility()
    end)

    local UIScale = Instance.new('UIScale')
    UIScale.Scale = 622 / 698
    UIScale.Parent = Container    
    
    self._ui = Norepine
    self._modules = {}

    -- Search filters module cards by the start of their title. Typing "au"
    -- keeps "Auto Spam" / "Auto Parry" and hides everything else.
    local function apply_search()
        local query = SearchBox.Text:lower()
        for _, entry in ipairs(self._modules) do
            local title = entry.title:lower()
            entry.object.Visible = (query == "" or title:sub(1, #query) == query)
        end
    end
    Connections['module_search'] = SearchBox:GetPropertyChangedSignal('Text'):Connect(apply_search)

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
        if self.BackgroundManager then
            self.BackgroundManager:destroy()
            self.BackgroundManager = nil
        end

        -- disconnects itself when the final track disappears.
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        Norepine.Enabled = not Norepine.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        self._ui_open = state
        if state then
            -- Restore full window: show all content, brand back at top-left.
            SubTitle.Visible = true
            ClientName.AnchorPoint = Vector2.new(0, 0.5)
            ClientName.Position = UDim2.fromOffset(20, 21)
            for _, name in ipairs({ 'Tabs', 'SearchFrame', 'Minimize', 'Divider', 'ContentContainer' }) do
                local obj = Handler:FindFirstChild(name)
                if obj and obj:IsA('GuiObject') then obj.Visible = true end
            end
            for _, section in ipairs(Sections:GetChildren()) do
                if section:IsA('GuiObject') then section.Visible = true end
            end
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            -- Minimized: only the centered brand, nothing else.
            SubTitle.Visible = false
            for _, name in ipairs({ 'Tabs', 'SearchFrame', 'Minimize', 'Divider', 'ContentContainer' }) do
                local obj = Handler:FindFirstChild(name)
                if obj and obj:IsA('GuiObject') then obj.Visible = false end
            end
            for _, section in ipairs(Sections:GetChildren()) do
                if section:IsA('GuiObject') then section.Visible = false end
            end
            ClientName.Position = UDim2.fromOffset(52, 26)
            ClientName.AnchorPoint = Vector2.new(0.5, 0.5)
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end

    -- Single source of truth for every open/close entry point (Insert key,
    -- brand click, minimize dash and the "Toggle key" feature).
    function self:toggle_visibility()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
        return self._ui_open
    end
    

    function self:load()
        local content = {}
    
        for _, object in Norepine:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        ContentProvider:PreloadAsync(content)
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

        if self.BackgroundManager then
            self.BackgroundManager:apply()
        end

        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            local bar = object:FindFirstChild('TabBar')
            local icon = object:FindFirstChild('Icon')
            local face = object:FindFirstChild('TabFace')

            if object == tab then
                if face then face.Visible = true end
                if bar then
                    TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0
                    }):Play()
                end
                TweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.05
                }):Play()
                TweenService:Create(object.TextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.05,
                    TextColor3 = Theme.Text
                }):Play()
                if icon then
                    TweenService:Create(icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.1,
                        ImageColor3 = Theme.Text
                    }):Play()
                end

                continue
            end

            if face then face.Visible = false end
            if bar then
                TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
            end
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
            end
            TweenService:Create(object.TextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                TextTransparency = 0.45,
                TextColor3 = Theme.TextDim
            }):Play()
            if icon then
                TweenService:Create(icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.45,
                    ImageColor3 = Theme.TextDim
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
        local icon_id = icon or TAB_ICONS[title]

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 30)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Theme.Panel
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local TabBar = Instance.new('Frame')
        TabBar.Name = 'TabBar'
        TabBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TabBar.AnchorPoint = Vector2.new(0, 0.5)
        TabBar.BackgroundTransparency = 1
        TabBar.Position = UDim2.new(0, 4, 0.5, 0)
        TabBar.Size = UDim2.new(0, 2, 0, 18)
        TabBar.BorderSizePixel = 0
        TabBar.BackgroundColor3 = accent()
        TabBar.ZIndex = 2
        TabBar.Parent = Tab

        local Icon = Instance.new('ImageLabel')
        Icon.Name = 'Icon'
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.Image = icon_id or ''
        Icon.ImageColor3 = Theme.TextDim
        Icon.ImageTransparency = 0.45
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.Position = UDim2.new(0, 16, 0.5, 0)
        Icon.Size = UDim2.fromOffset(14, 14)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Theme.TextDim
        TextLabel.TextTransparency = 0.45
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0, 36, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab

        -- The focused tab carries the same top-to-bottom grey gradient as
        -- the cards. Hovering only brightens text; it never shows the card.
        local TabFace = addCardFace(Tab, 'TabFace', 6)
        TabFace.Visible = false

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 400)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.55, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
        RightSection.Size = UDim2.new(0, 243, 0, 400)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6246, 0, 0.55, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

        Tab.MouseEnter:Connect(function()
            local info = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            TweenService:Create(TextLabel, info, {
                TextColor3 = Theme.Text,
                TextTransparency = 0.08
            }):Play()
            TweenService:Create(Icon, info, {
                ImageColor3 = Theme.Text,
                ImageTransparency = 0.08
            }):Play()
        end)

        Tab.MouseLeave:Connect(function()
            local active = Tab.BackgroundTransparency < 1
            local info = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            TweenService:Create(TextLabel, info, {
                TextColor3 = active and Theme.Text or Theme.TextDim,
                TextTransparency = active and 0.05 or 0.45
            }):Play()
            TweenService:Create(Icon, info, {
                ImageColor3 = active and Theme.Text or Theme.TextDim,
                ImageTransparency = active and 0.1 or 0.45
            }):Play()
        end)

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0,
                _no_toggle = settings.notoggle == true or settings.Module_NoToggle == true,
                _module_rebind = settings.Module_Rebind,
                _content_rebind = settings.Module_ContentRebind
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
            Module.Parent = settings.section

            if self._modules then
                table.insert(self._modules, { object = Module, title = settings.title or '' })
            end


            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.new(1, 1, 1)
            UIStroke.Transparency = 0.9
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
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module

            addModuleFace(Header, 'CardFace')

            -- Static gradient strip along the card's top edge. Only the
            -- window's outer border animates; card borders never move.
            local EdgeStrip = Instance.new('Frame')
            EdgeStrip.Name = 'EdgeStrip'
            EdgeStrip.Size = UDim2.new(1, 0, 0, 1)
            EdgeStrip.Position = UDim2.new(0, 0, 0, 0)
            EdgeStrip.BorderSizePixel = 0
            EdgeStrip.ZIndex = 3
            EdgeStrip.Parent = Header

            local EdgeGradient = Instance.new('UIGradient')
            EdgeGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0))
            EdgeGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.45),
                NumberSequenceKeypoint.new(1, 1)
            })
            EdgeGradient.Parent = EdgeStrip

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = accent()
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,0,0)'>Norepine</font> user"
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
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Theme.TextBody
            Description.TextTransparency = 0.35
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 12
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.1
            Toggle.Position = UDim2.new(0, 194, 0, 68)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.fromOffset(30, 16)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Theme.Track
            Toggle.Visible = not ModuleManager._no_toggle
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.05
            Circle.Position = UDim2.new(0, 2, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Theme.Muted
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = makeRebindChip(Header, '-')
            Keybind.Name = 'Keybind'
            Keybind.Position = UDim2.fromOffset(17, 68)
            Keybind.ZIndex = 2
            Keybind.Visible = ModuleManager._module_rebind ~= false
            local TextLabel = Keybind

            -- Notification bell (on by default). Every state change of this
            -- module sends a Norepine-style toast only while this is enabled.
            local notifyFlag = settings.flag .. '_notify'
            if Library._config._flags[notifyFlag] == nil then
                Library._config._flags[notifyFlag] = true
            end
            ModuleManager._notify = Library._config._flags[notifyFlag] ~= false

            local NotifyBell = Instance.new('ImageButton')
            NotifyBell.Name = 'NotifyBell'
            NotifyBell.Image = ICONS.Bell
            NotifyBell.Visible = not ModuleManager._no_toggle
            NotifyBell.ImageColor3 = Theme.TextBody
            NotifyBell.ImageTransparency = ModuleManager._notify and 0.3 or 0.7
            NotifyBell.Size = UDim2.fromOffset(14, 14)
            NotifyBell.Position = UDim2.fromOffset(170, 69)
            NotifyBell.BackgroundTransparency = 1
            NotifyBell.AutoButtonColor = false
            NotifyBell.Parent = Header

            NotifyBell.MouseButton1Click:Connect(function()
                ModuleManager._notify = not ModuleManager._notify
                Library._config._flags[notifyFlag] = ModuleManager._notify
                Config:save(game.GameId, Library._config)
                NotifyBell.ImageColor3 = Theme.TextBody
                NotifyBell.ImageTransparency = ModuleManager._notify and 0.3 or 0.7
                Library.SendNotification({
                    title = 'Notifications',
                    text = tostring(settings.title) .. ': ' .. (ModuleManager._notify and 'on' or 'off'),
                    kind = ModuleManager._notify and 'check' or 'x'
                })
            end)
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Accent.BaseColor
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            -- Public runtime setters (used by the global API).
            function ModuleManager:_set_no_toggle(state)
                self._no_toggle = state == true
                Toggle.Visible = not self._no_toggle
                NotifyBell.Visible = not self._no_toggle
                if self._no_toggle then
                    self._state = true
                    Module.Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                end
            end
            function ModuleManager:_set_module_rebind(state)
                self._module_rebind = state ~= false
                Keybind.Visible = self._module_rebind
            end
            function ModuleManager:_set_content_rebind(state)
                self._content_rebind = state ~= false
                for _, chip in ipairs(Module:GetDescendants()) do
                    if chip.Name == 'KeybindBox' then chip.Visible = self._content_rebind end
                end
            end

            function ModuleManager:change_state(state: boolean)
                -- no-toggle modules are always open and never flip state.
                if self._no_toggle then
                    state = true
                end
                self._state = state

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = accent()
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Knob,
                        Position = UDim2.new(0, 16, 0.5, 0)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Track
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Muted,
                        Position = UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)

                if self._notify then
                    Library.SendNotification({
                        title = tostring(settings.title),
                        text = tostring(settings.title) .. ' is ' .. (state and 'enabled' or 'disabled') .. '.',
                        state = state,
                        duration = 3
                    })
                end

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
                    local keybind_string = keyName(tostring(Library._config._keybinds[settings.flag]))

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
            
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    
                    TextLabel.Text = keyName(Library._config._keybinds[settings.flag])
                else
                    TextLabel.Text = '-'
                end
            end

            if ModuleManager._no_toggle then
                ModuleManager._state = true
                -- Expand after content is added via change_state; here _size is still 0.
                settings.callback(true)
            elseif Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = accent()
                Circle.BackgroundColor3 = Theme.Knob
                Circle.Position = UDim2.new(0, 16, 0.5, 0)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = keyName(tostring(Library._config._keybinds[settings.flag]))
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return
                end

                -- Only the keybind pill starts a capture; the rest of the
                -- header keeps its normal left-click toggle.
                local ap, as, p = Keybind.AbsolutePosition, Keybind.AbsoluteSize, input.Position
                if not Keybind.Visible
                    or p.X < ap.X or p.X > ap.X + as.X
                    or p.Y < ap.Y or p.Y > ap.Y + as.Y then
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

                        TextLabel.Text = '-'
                        
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

                    local keybind_string = keyName(tostring(Library._config._keybinds[settings.flag]))
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then return end
                if ModuleManager._no_toggle then return end
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
                Paragraph.BackgroundColor3 = Theme.Panel
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
                Title.TextColor3 = Theme.TextSoft
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
                Body.TextColor3 = Theme.TextBody
                
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>Norepine</font> user"
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
                        BackgroundColor3 = Theme.PanelHover
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Panel
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
                TextFrame.BackgroundColor3 = Theme.Panel
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
                Body.TextColor3 = Theme.TextBody
            
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi" -- Default text
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>Norepine</font> user" -- Default rich text
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
                        BackgroundColor3 = Theme.PanelHover
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Panel
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi" -- Default text
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(255,0,0)'>Norepine</font> user" -- Default rich text
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
                Label.TextColor3 = Theme.Text
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 12;
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Theme.Text
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = accent()
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
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                end
                TitleLabel.TextColor3 = Theme.Text
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = makeRebindChip(Checkbox,
                    Library._config._keybinds[settings.flag] and keyName(Library._config._keybinds[settings.flag]) or "-")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.AnchorPoint = Vector2.new(1, 0.5)
                KeybindBox.Position = UDim2.new(1, -36, 0.5, 0)
                KeybindBox.ZIndex = 2
                KeybindBox.Visible = ModuleManager._content_rebind ~= false
                local KeybindLabel = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.1
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.fromOffset(30, 16)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Track
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(1, 0)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.05
                Fill.Position = UDim2.new(0, 2, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.Size = UDim2.fromOffset(12, 12)
                Fill.BackgroundColor3 = Theme.Muted
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = accent(),
                            BackgroundTransparency = 0.05
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, 16, 0.5, 0),
                            BackgroundColor3 = Theme.Knob
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = Theme.Track,
                            BackgroundTransparency = 0.05
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, 2, 0.5, 0),
                            BackgroundColor3 = Theme.Muted
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
                    if Library._choosing_keybind then return end
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    if Library._choosing_keybind then return end
                    local ap, as, p = KeybindBox.AbsolutePosition, KeybindBox.AbsoluteSize, input.Position
                    if not KeybindBox.Visible
                        or p.X < ap.X or p.X > ap.X + as.X
                        or p.Y < ap.Y or p.Y > ap.Y + as.Y then
                        return
                    end
            
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
                            KeybindLabel.Text = "-"
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
            
                        local keybind_string = keyName(tostring(Library._config._keybinds[settings.flag]))
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
                    TextLabel.TextColor3 = Theme.Text -- 154, 182, 255
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
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    -- Create the inner divider frame that will be placed in the middle of the OuterFrame
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White color
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2) -- Center the divider vertically in the OuterFrame
                
                    -- Add a UIGradient to the divider for left and right transparency
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),  -- Start with white
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Keep it white in the middle
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  -- Fade handled by Transparency sequence below
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
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = accent()
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
                Fill.BackgroundColor3 = accent()
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 79, 79))
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.Text
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
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

                local notifyFlag = settings.flag .. '_notify'
                if Library._config._flags[notifyFlag] == nil then
                    Library._config._flags[notifyFlag] = false
                end
                DropdownManager._notify = Library._config._flags[notifyFlag] == true

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
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 190, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown

                local NotifyBell = Instance.new('ImageButton')
                NotifyBell.Name = 'NotifyBell'
                NotifyBell.Image = ICONS.Bell
                NotifyBell.ImageColor3 = DropdownManager._notify and accent() or Theme.TextDim
                NotifyBell.ImageTransparency = DropdownManager._notify and 0 or 0.5
                NotifyBell.Size = UDim2.fromOffset(12, 12)
                NotifyBell.Position = UDim2.fromOffset(195, 0)
                NotifyBell.BackgroundTransparency = 1
                NotifyBell.AutoButtonColor = false
                NotifyBell.Parent = Dropdown
                NotifyBell.MouseButton1Click:Connect(function()
                    DropdownManager._notify = not DropdownManager._notify
                    Library._config._flags[notifyFlag] = DropdownManager._notify
                    Config:save(game.GameId, Library._config)
                    NotifyBell.ImageColor3 = DropdownManager._notify and accent() or Theme.TextDim
                    NotifyBell.ImageTransparency = DropdownManager._notify and 0 or 0.5
                end)

                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = accent()
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
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Theme.Text
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 12
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
                Arrow.Image = 'rbxassetid://7733717447'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

                        local optionSkibidi = "nil";
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

                    if DropdownManager._notify then
                        local label = (typeof(option) == "string" and option) or (option and option.Name) or tostring(option)
                        Library.SendNotification({
                            title = tostring(settings.title),
                            text = label,
                            kind = "bell",
                            duration = 3
                        })
                    end
                
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
                        Option.TextSize = 12
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Theme.Text
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
                FeatureButton.Size = UDim2.new(1, -95, 0, 16)
                FeatureButton.BackgroundTransparency = 1
                FeatureButton.TextColor3 = Theme.TextSoft
                FeatureButton.Text = settings.title or "Feature"
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer
            
                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 90, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer
            
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer
            
                local KeybindBox = makeRebindChip(RightContainer, "-")
                KeybindBox.LayoutOrder = 2

                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Text = ""
                KeybindButton.Parent = KeybindBox
            
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
                KeybindBox.Text = keyName(Library._config._flags[settings.flag].BIND)

                if settings.flag == 'z_toggle_key' then
                    local bound = Library._config._flags[settings.flag].BIND
                    self._toggle_key = (bound ~= "Unknown" and Enum.KeyCode[bound]) or nil
                end

                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "...";
                end;

                local UseF_Var = nil;
            
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and accent() or Theme.Panel
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1;

                    local UIStroke = Instance.new("UIStroke", Checkbox)
                    UIStroke.Color = accent()
                    UIStroke.Thickness = 1
                    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                
                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox
            
                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and accent() or Theme.Panel
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
                        -- The demo's "Toggle key" row drives window visibility.
                        if settings.flag == 'z_toggle_key' and self.toggle_visibility then
                            self:toggle_visibility()
                        end
                        if settings.button_callback then
                            settings.button_callback()
                        end
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
                            if settings.flag == 'z_toggle_key' then
                                self._toggle_key = (newKey ~= "Unknown" and Enum.KeyCode[newKey]) or nil
                            end
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = keyName(newKey);
                            end;
                            Config:save(game.GameId, Library._config) -- Save new keybind
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if process then
            return
        end

        if input.KeyCode == Enum.KeyCode.Insert
            or (self._toggle_key and input.KeyCode == self._toggle_key) then
            self:toggle_visibility()
        end
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self:toggle_visibility()
    end)

    -- ===================== GLOBAL PUBLIC API ===================== --
    -- Game name shown next to the brand (the "Blade Ball" text).
    function self:SetGameName(name: string)
        SubTitle.Text = tostring(name or '')
        SubTitle.Visible = self._ui_open and SubTitle.Text ~= ''
    end
    function self:GetGameName()
        return SubTitle.Text
    end

    -- Expose the three module rebind/toggle controls as simple setters that
    -- can be called on any ModuleManager returned by create_module().
    Library.Module_NoToggle = function(module)
        if not module then return end
        module._no_toggle = true
        if module._set_no_toggle then module:_set_no_toggle(true) end
    end
    Library.Module_Rebind = function(module, state)
        if not module then return end
        module._module_rebind = state ~= false
        if module._set_module_rebind then module:_set_module_rebind(state) end
    end
    Library.Module_ContentRebind = function(module, state)
        if not module then return end
        module._content_rebind = state ~= false
        if module._set_content_rebind then module:_set_content_rebind(state) end
    end

    getgenv().NOREPINE_UI = self
    getgenv().NOREPINE_API = {
        UI = self,
        SetGameName = function(name) self:SetGameName(name) end,
        GetGameName = function() return self:GetGameName() end,
        Module_NoToggle = Library.Module_NoToggle,
        Module_Rebind = Library.Module_Rebind,
        Module_ContentRebind = Library.Module_ContentRebind,
    }

    return self
end

return Library