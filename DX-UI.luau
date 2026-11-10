local DX = {
    Version = "0.0.1.1",
    Flags = {},
    Themes = {},
    Theme = "DX-SR",
    Windows = {},
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

DX.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
DX.Glass = false
DX.ClickSound = "rbxassetid://15675032796"
DX.ClickVolume = 0.5

local FONT_FAMILY = "rbxasset://fonts/families/Montserrat.json"
local Weight = Enum.FontWeight
local AutoX = Enum.AutomaticSize.X
local AutoY = Enum.AutomaticSize.Y
local Horizontal = Enum.FillDirection.Horizontal
local Round = UDim.new(1, 0)

local function GetFont(weight)
    return Font.new(FONT_FAMILY, weight or Weight.Medium)
end

local BaseTheme = {
    Background = Color3.fromHex("#0A0F1E"),
    Element = Color3.fromHex("#111A31"),
    ElementHover = Color3.fromHex("#17223F"),
    Field = Color3.fromHex("#0A1022"),
    Stroke = Color3.fromHex("#1F2D52"),
    Accent = Color3.fromHex("#3B82F6"),
    Accent2 = Color3.fromHex("#22D3EE"),
    Text = Color3.fromHex("#EAF0FF"),
    SubText = Color3.fromHex("#9AABD4"),
    Icon = Color3.fromHex("#A7B6DD"),
    Success = Color3.fromHex("#30FF6A"),
    Warning = Color3.fromHex("#FBBF24"),
    Error = Color3.fromHex("#F43F5E"),
}

local function Variant(overrides)
    local theme = table.clone(BaseTheme)
    for key, value in pairs(overrides) do theme[key] = value end
    return theme
end

DX.Themes["DX-SR"] = BaseTheme
DX.Themes.Midnight = Variant({
    Accent = Color3.fromHex("#8B5CF6"), Accent2 = Color3.fromHex("#EC4899"),
    Background = Color3.fromHex("#0E0A1E"),
    Element = Color3.fromHex("#18122F"), ElementHover = Color3.fromHex("#20183D"), Field = Color3.fromHex("#0D0920"),
    Stroke = Color3.fromHex("#2C2350"), SubText = Color3.fromHex("#AFA2D6"), Icon = Color3.fromHex("#B6A9DE"),
})
DX.Themes.Emerald = Variant({
    Accent = Color3.fromHex("#10B981"), Accent2 = Color3.fromHex("#A3E635"),
    Background = Color3.fromHex("#08130F"),
    Element = Color3.fromHex("#0F231B"), ElementHover = Color3.fromHex("#142D23"), Field = Color3.fromHex("#081510"),
    Stroke = Color3.fromHex("#1C3D30"), SubText = Color3.fromHex("#9DC9B6"), Icon = Color3.fromHex("#A5D4C0"),
})
DX.Themes.Crimson = Variant({
    Accent = Color3.fromHex("#F43F5E"), Accent2 = Color3.fromHex("#FB923C"),
    Background = Color3.fromHex("#140A0D"),
    Element = Color3.fromHex("#221117"), ElementHover = Color3.fromHex("#2B161D"), Field = Color3.fromHex("#12080B"),
    Stroke = Color3.fromHex("#40202A"), SubText = Color3.fromHex("#D3A5AF"), Icon = Color3.fromHex("#DDB0BA"),
})

local Themed = {}
local ThemeHooks = {}
local GlassTargets = {}

local function CurrentTheme()
    return DX.Themes[DX.Theme] or BaseTheme
end

local function Tween(object, time, properties, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function ThemeMap(object)
    local map = Themed[object]
    if not map then
        map = {}
        Themed[object] = map
        object.Destroying:Once(function()
            Themed[object] = nil
            GlassTargets[object] = nil
        end)
    end
    return map
end

local function Bind(object, property, key)
    ThemeMap(object)[property] = key
    object[property] = CurrentTheme()[key]
end

local function Retheme(object, property, key, time)
    ThemeMap(object)[property] = key
    Tween(object, time or 0.25, {[property] = CurrentTheme()[key]})
end

local function OnTheme(hook)
    table.insert(ThemeHooks, hook)
    hook(CurrentTheme())
end

local GlassLevels = {Background = 0.38, Element = 0.48, Field = 0.30}
local GlassHooks = {}

local function OnGlass(hook, owner)
    table.insert(GlassHooks, hook)
    if owner then
        owner.Destroying:Once(function()
            local index = table.find(GlassHooks, hook)
            if index then table.remove(GlassHooks, index) end
        end)
    end
    hook(DX.Glass)
end

local AcrylicEffect
local AcrylicMuted = {}

local function AcrylicQuality()
    local ok, level = pcall(function() return UserSettings():GetService("UserGameSettings").SavedQualityLevel end)
    return not ok or level.Value == 0 or level.Value >= 8
end

local function SyncGlassBlur()
    local on = false
    if DX.Glass and AcrylicQuality() then
        for _, window in ipairs(DX.Windows) do
            if window.Opened and not window.Destroyed then
                on = true
                break
            end
        end
    end
    if on and not (AcrylicEffect and AcrylicEffect.Parent) then
        for _, holder in ipairs({Lighting, workspace.CurrentCamera}) do
            for _, effect in ipairs(holder:GetChildren()) do
                if effect:IsA("DepthOfFieldEffect") and effect.Enabled then
                    AcrylicMuted[effect] = true
                    effect.Enabled = false
                end
            end
        end
        if not AcrylicEffect then
            AcrylicEffect = Instance.new("DepthOfFieldEffect")
            AcrylicEffect.Name = "DXAcrylic"
            AcrylicEffect.FarIntensity = 0
            AcrylicEffect.InFocusRadius = 0.1
            AcrylicEffect.NearIntensity = 1
        end
        AcrylicEffect.Parent = Lighting
    elseif not on then
        if AcrylicEffect then AcrylicEffect.Parent = nil end
        for effect in pairs(AcrylicMuted) do pcall(function() effect.Enabled = true end) end
        table.clear(AcrylicMuted)
    end
end

local function ResetGlassBlur()
    if AcrylicEffect then AcrylicEffect.Parent = nil end
    task.delay(0.5, SyncGlassBlur)
end

pcall(function()
    UserSettings():GetService("UserGameSettings"):GetPropertyChangedSignal("SavedQualityLevel"):Connect(ResetGlassBlur)
end)
pcall(function()
    settings().Rendering:GetPropertyChangedSignal("QualityLevel"):Connect(ResetGlassBlur)
end)

function DX:SetGlass(state)
    DX.Glass = state and true or false
    for object, levels in pairs(GlassTargets) do
        pcall(Tween, object, 0.35, {BackgroundTransparency = DX.Glass and levels[2] or levels[1]})
    end
    for _, hook in ipairs(GlassHooks) do pcall(hook, DX.Glass) end
    SyncGlassBlur()
end

local function ScaleOf(object)
    local value = 1
    while object and not object:IsA("LayerCollector") do
        local uiScale = object:FindFirstChildOfClass("UIScale")
        if uiScale then value *= uiScale.Scale end
        object = object.Parent
    end
    return value
end

function DX:SetTheme(name)
    if not DX.Themes[name] then return false end
    DX.Theme = name
    local theme = CurrentTheme()
    for object, map in pairs(Themed) do
        local properties = {}
        for property, key in pairs(map) do properties[property] = theme[key] end
        pcall(Tween, object, 0.35, properties)
    end
    for _, hook in ipairs(ThemeHooks) do pcall(hook, theme) end
    return true
end

local WindThemeKeys = {Outline = "Stroke", Placeholder = "SubText", Button = "Element"}

function DX:AddTheme(name, theme)
    if type(name) == "table" then
        theme, name = name, name.Name
    end
    local mapped = {}
    for key, value in pairs(theme or {}) do
        if typeof(value) == "Color3" then mapped[WindThemeKeys[key] or key] = value end
    end
    DX.Themes[name] = Variant(mapped)
    return name
end

function DX:GetCurrentTheme()
    return DX.Theme
end

function DX:GetThemes()
    local list = {}
    for name in pairs(DX.Themes) do table.insert(list, name) end
    table.sort(list)
    return list
end

local ClickPlayer
local function PlayClick()
    if not DX.ClickSound then return end
    pcall(function()
        if not ClickPlayer or not ClickPlayer.Parent then
            ClickPlayer = Instance.new("Sound")
            ClickPlayer.Name = "DXClick"
            ClickPlayer.Parent = game:GetService("SoundService")
        end
        ClickPlayer.SoundId = DX.ClickSound
        ClickPlayer.Volume = DX.ClickVolume
        ClickPlayer.TimePosition = 0
        ClickPlayer:Play()
    end)
end

local ActiveFlashes = setmetatable({}, {__mode = "k"})

local function FlashActivation(target)
    if not target.Parent or not target.Visible then return end
    local previous = ActiveFlashes[target]
    if previous then previous:Destroy() end
    local stroke = Instance.new("UIStroke")
    stroke.Name = "Activation"
    stroke.Color = Color3.new(1, 1, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1.25
    stroke.Transparency = 0.24
    stroke.Parent = target
    ActiveFlashes[target] = stroke
    Tween(stroke, DX.IsMobile and 0.16 or 0.23, {Transparency = 1}).Completed:Once(function()
        if ActiveFlashes[target] == stroke then ActiveFlashes[target] = nil end
        stroke:Destroy()
    end)
end

local function New(className, properties, children)
    local object = Instance.new(className)
    if (className == "TextButton" or className == "ImageButton") and not (properties and properties.PressFeedback == false) then
        object.Activated:Connect(function()
            PlayClick()
            FlashActivation(object)
        end)
    end
    if properties then
        for key, value in pairs(properties) do
            if key == "Theme" then
                for property, themeKey in pairs(value) do Bind(object, property, themeKey) end
            elseif key ~= "Parent" and key ~= "PressFeedback" then
                object[key] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do child.Parent = object end
    end
    local themed = properties and properties.Theme and properties.Theme.BackgroundColor3
    if themed and GlassLevels[themed] and object.BackgroundTransparency == 0 then
        GlassTargets[object] = {0, GlassLevels[themed]}
        if DX.Glass then object.BackgroundTransparency = GlassLevels[themed] end
    end
    if properties and properties.Parent then object.Parent = properties.Parent end
    return object
end

local function Corner(radius)
    return New("UICorner", {CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8)})
end

local function Frost(parent, radius, opacity, rimEnabled)
    local surface
    OnGlass(function(enabled)
        if enabled and not surface then
            surface = New("Frame", {
                Name = "GlassSurface",
                Position = UDim2.fromOffset(1, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = opacity,
                BorderSizePixel = 0,
                ZIndex = math.max(1, parent.ZIndex - 1),
                Parent = parent,
            }, {Corner(math.max(0, radius - 1))})
            New("UIGradient", {
                Rotation = 115,
                Transparency = NumberSequence.new(0, 0.94),
                Parent = surface,
            })
            if rimEnabled ~= false then
                New("UIStroke", {
                    Color = Color3.new(1, 1, 1),
                    Transparency = 0.8,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = surface,
                })
            end
        end
        if surface then surface.Visible = enabled end
    end, parent)
end

local function Stroke(key, transparency, thickness)
    return New("UIStroke", {
        Theme = {Color = key or "Stroke"},
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(left, right, top, bottom)
    right = right or left
    top = top or left
    bottom = bottom or top
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
end

local function List(padding, direction, horizontal, vertical)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
end

local function Text(properties)
    properties.Name = properties.Name or "Label"
    properties.BackgroundTransparency = 1
    properties.FontFace = properties.FontFace or GetFont()
    properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
    properties.Theme = properties.Theme or {TextColor3 = "Text"}
    return New("TextLabel", properties)
end

local function AccentGradient(parent, rotation)
    local gradient = New("UIGradient", {Rotation = rotation or 0, Parent = parent})
    OnTheme(function(theme)
        gradient.Color = ColorSequence.new(theme.Accent, theme.Accent2)
    end)
    return gradient
end

local IconProvider
pcall(function()
    IconProvider = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
end)

function DX:GetIcon(name)
    if type(name) == "number" then return "rbxassetid://" .. name end
    if type(name) ~= "string" or name == "" then return nil end
    if name:find("^rbxasset") or name:find("^rbxthumb") or name:find("^https?://") then return name end
    if tonumber(name) then return "rbxassetid://" .. name end
    if IconProvider and IconProvider.GetIcon then
        local ok, image = pcall(IconProvider.GetIcon, name)
        if ok and type(image) == "string" then return image end
    end
    return nil
end

local function IsTintable(name)
    return type(name) == "string" and not (name:find("^rbx") or name:find("^https?://") or tonumber(name))
end

local function Icon(name, size, themeKey, properties)
    local image = DX:GetIcon(name)
    if not image then return nil end
    properties = properties or {}
    properties.Name = properties.Name or "Icon"
    properties.Image = image
    properties.BackgroundTransparency = 1
    properties.Size = properties.Size or UDim2.fromOffset(size or 16, size or 16)
    if themeKey and IsTintable(name) then properties.ImageColor3 = Color3.new(1, 1, 1) end
    return New("ImageLabel", properties)
end

local function SafeCall(callback, ...)
    if type(callback) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(callback, table.unpack(args, 1, args.n))
        if not ok then warn("[DX-UI] " .. tostring(err)) end
    end)
end

local function PointerPosition(input)
    if input and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.MouseButton1) then
        return Vector2.new(input.Position.X, input.Position.Y)
    end
    return UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
end

local function IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local FadeTokens = setmetatable({}, {__mode = "k"})
local function FadeThrough(fader, object, home, time, target, from)
    FadeTokens[fader] = (FadeTokens[fader] or 0) + 1
    local token = FadeTokens[fader]
    for _, child in ipairs(fader:GetChildren()) do
        if child ~= object and child:IsA("GuiObject") then child.Parent = home end
    end
    object.Parent = fader
    fader.Visible = true
    if from then fader.Position = from end
    Tween(fader, time, {GroupTransparency = target, Position = UDim2.new()})
    task.delay(time, function()
        if FadeTokens[fader] ~= token or target ~= 0 or not fader.Parent or object.Parent ~= fader then return end
        object.Parent = home
        fader.Visible = false
    end)
end

local function MovesPointer(start, input)
    return start and (input == start or start.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
end

local function EndsPointer(start, input)
    return start and (input == start or start.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
end

local function Draggable(handles, target, window, onDrag)
    local pointer, startPointer, startPosition, startOrigin, motion
    for _, handle in ipairs(handles) do
        handle.Active = true
        handle.InputBegan:Connect(function(input)
            if window.WindowPointer or not window.Opened or not IsPress(input) then return end
            if motion then motion:Cancel() end
            pointer = input
            window.WindowPointer = input
            startPointer = PointerPosition(input)
            startPosition = target.Position
            startOrigin = target.AbsolutePosition
            onDrag(handle, true)
        end)
    end
    table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
        if not window.Opened or not MovesPointer(pointer, input) then return end
        local delta = PointerPosition(input) - startPointer
        local bounds = target.Parent.AbsoluteSize
        local size = target.AbsoluteSize
        local maxX = math.max(8, bounds.X - size.X - 8)
        local maxY = math.max(8, bounds.Y - size.Y - 28)
        local x = math.clamp(startOrigin.X + delta.X, 8, maxX) - startOrigin.X
        local y = math.clamp(startOrigin.Y + delta.Y, 8, maxY) - startOrigin.Y
        motion = Tween(target, DX.IsMobile and 0.06 or 0.04, {
            Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + x, startPosition.Y.Scale, startPosition.Y.Offset + y),
        }, Enum.EasingStyle.Quad)
    end))
    table.insert(window.Connections, UserInputService.InputEnded:Connect(function(input)
        if not EndsPointer(pointer, input) then return end
        pointer = nil
        window.WindowPointer = nil
        onDrag(nil, false)
    end))
end

local function GuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local coreOk = pcall(function()
        local probe = Instance.new("Folder")
        probe.Parent = game:GetService("CoreGui")
        probe:Destroy()
    end)
    if coreOk then return game:GetService("CoreGui") end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function ScreenGui(name, order)
    return New("ScreenGui", {
        Name = name,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = order or 100,
        Parent = GuiParent(),
    })
end

local OrderCounter = 0
local function NextOrder()
    OrderCounter += 1
    return OrderCounter
end

local function ActionButton(parent, config, onClick)
    local variant = config.Variant or "Secondary"
    local button = New("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = AutoX,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = variant == "Tertiary" and 1 or 0,
        Parent = parent,
    }, {Corner(8), Padding(16, 16, 0, 0), List(6, Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)})
    local textKey = variant == "Tertiary" and "Accent" or "Text"
    if variant == "Primary" then
        AccentGradient(button, 0)
    elseif variant == "Secondary" then
        Bind(button, "BackgroundColor3", "Element")
        Stroke("Stroke").Parent = button
    end
    local icon = config.Icon and Icon(config.Icon, 15, variant ~= "Primary" and textKey or nil, {LayoutOrder = 1, Parent = button})
    if icon and variant == "Primary" then icon.ImageColor3 = Color3.new(1, 1, 1) end
    local label = Text({
        Text = config.Title or config.Name or "Button",
        TextSize = 14,
        FontFace = GetFont(Weight.SemiBold),
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = AutoX,
        LayoutOrder = 2,
        Theme = variant == "Primary" and {} or {TextColor3 = textKey},
        Parent = button,
    })
    if variant == "Primary" then label.TextColor3 = Color3.new(1, 1, 1) end
    local scale = New("UIScale", {Parent = button})
    button.MouseEnter:Connect(function() Tween(scale, 0.25, {Scale = 1.04}, Enum.EasingStyle.Back) end)
    button.MouseLeave:Connect(function() Tween(scale, 0.2, {Scale = 1}) end)
    button.MouseButton1Down:Connect(function() Tween(scale, 0.1, {Scale = 0.94}) end)
    button.MouseButton1Up:Connect(function() Tween(scale, 0.3, {Scale = 1.04}, Enum.EasingStyle.Back) end)
    button.Activated:Connect(function()
        SafeCall(config.Callback)
        if onClick then onClick() end
    end)
    return button
end

local function CreateDialog(gui, config, onClosed)
    config = config or {}
    local Dialog = {}
    local overlay = New("TextButton", {Name = "Dialog", 
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = gui,
    })
    local card = New("Frame", {Name = "Card", 
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(config.Width or 380, 0),
        AutomaticSize = AutoY,
        Theme = {BackgroundColor3 = "Background"},
        ZIndex = 101,
        Parent = overlay,
    }, {Corner(14), Stroke("Stroke"), Padding(20, 20, 18, 18), List(14)})
    local scale = New("UIScale", {Scale = 0.85, Parent = card})
    local head = New("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
    local textX = 0
    if config.Icon and DX:GetIcon(config.Icon) then
        local box = New("Frame", {Size = UDim2.fromOffset(34, 34), Theme = {BackgroundColor3 = "Accent"}, BackgroundTransparency = 0.82, Parent = head}, {Corner(9)})
        Icon(config.Icon, 18, "Accent", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = box})
        textX = 46
    end
    local title = Text({Text = config.Title or "Dialog", TextSize = 17, FontFace = GetFont(Weight.Bold), Position = UDim2.fromOffset(textX, 0), Size = UDim2.new(1, -textX, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
    local content = Text({Text = config.Content or config.Description or "", TextSize = 14, Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LineHeight = 1.15, LayoutOrder = 2, Parent = card})
    local buttons = New("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 3, Parent = card}, {List(8, Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)})
    local closed = false
    function Dialog:Close()
        if closed then return end
        closed = true
        Tween(overlay, 0.2, {BackgroundTransparency = 1})
        Tween(scale, 0.2, {Scale = 0.9}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function()
            overlay:Destroy()
            if onClosed then onClosed() end
        end)
    end
    Dialog.Cancel = Dialog.Close
    function Dialog:Show() return Dialog end
    function Dialog:SetTitle(value) title.Text = value end
    function Dialog:SetContent(value) content.Text = value end
    Dialog.UpdateTitle = Dialog.SetTitle
    Dialog.UpdateDescription = Dialog.SetContent
    for index, buttonConfig in ipairs(config.Buttons or {{Title = "OK", Variant = "Primary"}}) do
        local button = ActionButton(buttons, buttonConfig, function() Dialog:Close() end)
        button.LayoutOrder = index
    end
    Tween(overlay, 0.25, {BackgroundTransparency = 0.45})
    Tween(scale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
    return Dialog
end

function DX:Popup(config)
    local gui = ScreenGui("DX-UI-Popup", 1100)
    return CreateDialog(gui, config, function() gui:Destroy() end)
end

local NotifyGui
local NotifyHolders = {}
local NotifyTypes = {
    Info = {"info", "Accent"},
    Success = {"circle-check", "Success"},
    Warning = {"triangle-alert", "Warning"},
    Error = {"circle-x", "Error"},
}

local function NotifyScale()
    local camera = workspace.CurrentCamera
    local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min(size.X / 900, size.Y / 540), 0.75, 1)
end

local function FitNotifyScale()
    for _, holder in pairs(NotifyHolders) do
        local scale = holder:FindFirstChildOfClass("UIScale")
        if scale then scale.Scale = NotifyScale() end
    end
end

local function GetNotifyHolder(top)
    local key = top and "Top" or "Corner"
    local holder = NotifyHolders[key]
    if holder and holder.Parent then return holder end
    if not (NotifyGui and NotifyGui.Parent) then
        NotifyGui = ScreenGui("DX-UI-Notifications", 1200)
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(FitNotifyScale)
    end
    holder = New("Frame", {Name = top and "TopNotifications" or "Notifications",
        AnchorPoint = top and Vector2.new(0.5, 0) or Vector2.new(1, 1),
        Position = top and UDim2.new(0.5, 0, 0, 14) or UDim2.new(1, -18, 1, -18),
        Size = UDim2.new(0, top and 340 or 320, 1, -36),
        BackgroundTransparency = 1,
        Parent = NotifyGui,
    }, {
        List(10, nil, top and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Right, top and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom),
        New("UIScale", {Scale = NotifyScale()}),
    })
    NotifyHolders[key] = holder
    return holder
end

function DX:Notify(config)
    config = config or {}
    local Notification = {}
    local top = config.Placement == "Top"
    local holder = GetNotifyHolder(top)
    local hidden = top and UDim2.fromOffset(0, -180) or UDim2.fromOffset(360, 0)
    local kind = NotifyTypes[config.Type or "Info"] or NotifyTypes.Info
    local accent = kind[2]
    local tint = typeof(config.Color) == "Color3" and config.Color or nil
    local image = config.Image and DX:GetIcon(config.Image)
    local duration = config.Duration or config.Lifetime or 5
    local boxSize = image and 46 or 32
    local function Paint(properties, property)
        properties.Theme = properties.Theme or {}
        if tint then
            properties[property] = tint
        else
            properties.Theme[property] = accent
        end
        return properties
    end
    local wrap = New("Frame", {Name = "Notification", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = top and -NextOrder() or NextOrder(), Parent = holder})
    local media = image and config.Layout == "Media"
    local card = New("Frame", {Name = "Card",
        Size = UDim2.new(1, 0, 0, media and 88 or 0),
        AutomaticSize = media and Enum.AutomaticSize.None or AutoY,
        Position = hidden,
        Theme = {BackgroundColor3 = "Background"},
        Parent = wrap,
    }, media and {Corner(12)} or {Corner(12), Padding(14, 14, 12, 12), List(8)})
    New("UIStroke", Paint({Transparency = 0.55, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card}, "Color"))
    local title, subtitle, content, close, timer, fill
    if media then
        New("Frame", Paint({Name = "Glow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.86, Parent = card}, "BackgroundColor3"), {Corner(12), New("UIGradient", {Transparency = NumberSequence.new(0, 1)})})
        local box = New("Frame", Paint({Name = "Media", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(68, 68), BackgroundTransparency = 0.72, Parent = card}, "BackgroundColor3"), {Corner(10), New("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(0, 0.55)})})
        New("UIStroke", Paint({Transparency = 0.3, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = box}, "Color"))
        New("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, -10), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = image, Parent = box})
        title = Text({Text = config.Title or "DX-SR Hub", TextSize = 15, FontFace = GetFont(Weight.SemiBold), Position = UDim2.fromOffset(90, 12), Size = UDim2.new(1, -164, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, RichText = true, Parent = card})
        close = New("ImageButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0, 21), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Image = DX:GetIcon("x") or "", ImageColor3 = Color3.new(1, 1, 1), Parent = card})
        local pill = New("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0, 21), Size = UDim2.fromOffset(0, 18), AutomaticSize = AutoX, Theme = {BackgroundColor3 = "Field"}, Parent = card}, {Corner(Round), Padding(7, 7, 0, 0)})
        timer = Text({Text = math.ceil(duration) .. "s", TextSize = 11, FontFace = GetFont(Weight.SemiBold), Theme = {TextColor3 = "SubText"}, Size = UDim2.fromScale(0, 1), AutomaticSize = AutoX, Parent = pill})
        local chip = New("Frame", Paint({Position = UDim2.fromOffset(90, 34), Size = UDim2.fromOffset(0, 18), AutomaticSize = AutoX, BackgroundTransparency = 0.82, Visible = config.SubTitle ~= nil, Parent = card}, "BackgroundColor3"), {Corner(Round), Padding(8, 8, 0, 0)})
        subtitle = Text(Paint({Text = config.SubTitle or "", TextSize = 11, FontFace = GetFont(Weight.Bold), Size = UDim2.fromScale(0, 1), AutomaticSize = AutoX, RichText = true, Parent = chip}, "TextColor3"))
        content = Text({Text = config.Content or config.Description or "", TextSize = 13, Theme = {TextColor3 = "SubText"}, Position = UDim2.fromOffset(90, 56), Size = UDim2.new(1, -100, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, RichText = true, Parent = card})
        local track = New("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 90, 1, -10), Size = UDim2.new(1, -100, 0, 3), Theme = {BackgroundColor3 = "Field"}, Parent = card}, {Corner(Round)})
        fill = New("Frame", Paint({Size = UDim2.fromScale(1, 1), Parent = track}, "BackgroundColor3"), {Corner(Round)})
    else
        local head = New("Frame", {Size = UDim2.new(1, 0, 0, boxSize), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
        local box = New("Frame", Paint({Size = UDim2.fromOffset(boxSize, boxSize), BackgroundTransparency = image and 0.8 or 0.85, Parent = head}, "BackgroundColor3"), {Corner(image and 10 or 8)})
        if image then
            New("UIStroke", Paint({Transparency = 0.4, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = box}, "Color"))
            New("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = image, Parent = box})
        else
            local icon = Icon(config.Icon or kind[1], 17, accent, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = box})
            if icon and tint then
                ThemeMap(icon).ImageColor3 = nil
                icon.ImageColor3 = Color3.new(1, 1, 1)
            end
        end
        local left = boxSize + 12
        title = Text({Text = config.Title or "DX-SR Hub", TextSize = 15, FontFace = GetFont(Weight.SemiBold), Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -(left + 70), config.SubTitle and 0.55 or 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
        if config.SubTitle then
            subtitle = Text(Paint({Text = config.SubTitle, TextSize = 12, FontFace = GetFont(Weight.SemiBold), Position = UDim2.new(0, left, 0.55, 0), Size = UDim2.new(1, -(left + 70), 0.45, 0), TextTruncate = Enum.TextTruncate.AtEnd, RichText = true, Parent = head}, "TextColor3"))
        end
        close = New("ImageButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Image = DX:GetIcon("x") or "", ImageColor3 = Color3.new(1, 1, 1), Parent = head})
        local pill = New("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -26, 0.5, 0), Size = UDim2.fromOffset(0, 20), AutomaticSize = AutoX, Theme = {BackgroundColor3 = "Field"}, Parent = head}, {Corner(Round), Padding(8, 8, 0, 0)})
        timer = Text({Text = math.ceil(duration) .. "s", TextSize = 12, FontFace = GetFont(Weight.SemiBold), Theme = {TextColor3 = "SubText"}, Size = UDim2.fromScale(0, 1), AutomaticSize = AutoX, Parent = pill})
        content = Text({Text = config.Content or config.Description or "", TextSize = 13, Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LayoutOrder = 2, Parent = card})
        content.Visible = content.Text ~= ""
        local track = New("Frame", {Size = UDim2.new(1, 0, 0, 3), Theme = {BackgroundColor3 = "Field"}, LayoutOrder = 3, Parent = card}, {Corner(Round)})
        fill = New("Frame", Paint({Size = UDim2.fromScale(1, 1), Parent = track}, "BackgroundColor3"), {Corner(Round)})
    end
    local closed = false
    function Notification:Close()
        if closed then return end
        closed = true
        Tween(card, 0.35, {Position = hidden}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.3, function()
            Tween(wrap, 0.25, {Size = UDim2.new(1, 0, 0, 0)})
            task.delay(0.26, function() wrap:Destroy() end)
        end)
    end
    Notification.Cancel = Notification.Close
    function Notification:SetTitle(value) title.Text = value end
    function Notification:SetSubTitle(value) if subtitle then subtitle.Text = value end end
    function Notification:SetContent(value) content.Text = value content.Visible = value ~= "" end
    Notification.UpdateTitle = Notification.SetTitle
    Notification.UpdateDescription = Notification.SetContent
    close.Activated:Connect(function() Notification:Close() end)
    task.defer(function()
        task.wait()
        local scale = holder:FindFirstChildOfClass("UIScale")
        Tween(wrap, 0.3, {Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y / (scale and scale.Scale or 1))})
        Tween(card, 0.55, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back)
        Tween(fill, duration, {Size = UDim2.fromScale(0, 1)}, Enum.EasingStyle.Linear)
        local endsAt = os.clock() + duration
        while not closed and os.clock() < endsAt do
            timer.Text = math.ceil(endsAt - os.clock()) .. "s"
            task.wait(0.2)
        end
        Notification:Close()
    end)
    return Notification
end

local Elements = {}

local function RegisterElement(owner, element, config)
    element.Window = owner.Window
    element.Tab = owner.Tab
    element.Section = owner ~= owner.Tab and owner or nil
    table.insert(owner.Window.Elements, element)
    if owner.Tab and element.Title and element.Title ~= "" then table.insert(owner.Tab.Keywords, element.Title) end
    if config.Flag then
        element.Flag = config.Flag
        DX.Flags[config.Flag] = element
    end
    if element.Card then element.Card.Name = "[" .. (element.Type or "Element") .. "] " .. tostring(element.Title or "") end
    if config.Locked then element:Lock() end
end

local function BaseElement(owner, config, options)
    options = options or {}
    local Element = {Title = config.Title or config.Name or "", Desc = config.Desc or config.Description, Locked = false}
    local rightWidth = options.RightWidth or 0
    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = AutoY,
        Theme = {BackgroundColor3 = "Element"},
        LayoutOrder = NextOrder(),
        Parent = owner.Container,
    }, {Corner(10), Stroke("Stroke", 0.35)})
    Frost(card, 10, 0.96, false)
    local frame = New("Frame", {Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = card}, {List(0)})
    local header = New(options.Button and "TextButton" or "Frame", {Name = "Header", 
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = AutoY,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = frame,
    }, {Padding(14, 14, 12, 12)})
    if options.Button then
        header.Text = ""
        header.AutoButtonColor = false
    end
    local left = 0
    if config.Icon and DX:GetIcon(config.Icon) then
        Element.IconImage = Icon(config.Icon, 18, "Icon", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Parent = header})
        left = 30
    end
    local textBlock = New("Frame", {Name = "Text", 
        Position = UDim2.fromOffset(left, 0),
        Size = UDim2.new(1, -(left + rightWidth + (rightWidth > 0 and 14 or 0)), 0, 0),
        AutomaticSize = AutoY,
        BackgroundTransparency = 1,
        Parent = header,
    }, {List(3)})
    local title = Text({Name = "Title", Text = Element.Title, TextSize = 14, FontFace = GetFont(Weight.SemiBold), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LayoutOrder = 1, Parent = textBlock})
    local desc = Text({Name = "Desc", Text = Element.Desc or "", TextSize = 13, Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LayoutOrder = 2, Visible = Element.Desc ~= nil and Element.Desc ~= "", Parent = textBlock})
    local right = New("Frame", {Name = "Right", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(rightWidth, 30), BackgroundTransparency = 1, Parent = header})
    if options.Hover ~= false then
        card.MouseEnter:Connect(function()
            if not Element.Locked then Retheme(card, "BackgroundColor3", "ElementHover", 0.2) end
        end)
        card.MouseLeave:Connect(function() Retheme(card, "BackgroundColor3", "Element", 0.25) end)
    end
    local lockOverlay
    function Element:SetTitle(value)
        Element.Title = value
        title.Text = value
    end
    function Element:SetDesc(value)
        Element.Desc = value
        desc.Text = value or ""
        desc.Visible = value ~= nil and value ~= ""
    end
    function Element:Lock(reason)
        if lockOverlay then return end
        Element.Locked = true
        lockOverlay = New("TextButton", {Name = "Lock", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), Theme = {BackgroundColor3 = "Background"}, BackgroundTransparency = 1, ZIndex = 40, Parent = card}, {Corner(10)})
        if reason and reason ~= "" then
            local row = New("Frame", {Name = "Reason", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -28, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, ZIndex = 41, Parent = lockOverlay}, {List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)})
            Icon("lock", 14, "Text", {ImageTransparency = 1, ZIndex = 41, LayoutOrder = 1, Parent = row})
            Text({Text = reason, TextSize = 13, FontFace = GetFont(Weight.SemiBold), Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, TextTransparency = 1, ZIndex = 41, LayoutOrder = 2, Parent = row})
        else
            Icon("lock", 16, "SubText", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), ImageTransparency = 1, ZIndex = 41, Parent = lockOverlay})
        end
        Tween(lockOverlay, 0.25, {BackgroundTransparency = reason and 0.12 or 0.4})
        for _, child in ipairs(lockOverlay:GetDescendants()) do
            if child:IsA("ImageLabel") then Tween(child, 0.25, {ImageTransparency = 0}) end
            if child:IsA("TextLabel") then Tween(child, 0.25, {TextTransparency = 0}) end
        end
    end
    function Element:Unlock()
        if not lockOverlay then return end
        Element.Locked = false
        local overlay = lockOverlay
        lockOverlay = nil
        Tween(overlay, 0.2, {BackgroundTransparency = 1})
        for _, child in ipairs(overlay:GetDescendants()) do
            if child:IsA("ImageLabel") then Tween(child, 0.2, {ImageTransparency = 1}) end
            if child:IsA("TextLabel") then Tween(child, 0.2, {TextTransparency = 1}) end
        end
        task.delay(0.21, function() overlay:Destroy() end)
    end
    function Element:SetVisible(value) card.Visible = value end
    Element.SetVisiblity = Element.SetVisible
    Element.SetVisibility = Element.SetVisible
    Element.UpdateName = Element.SetTitle
    function Element:Destroy()
        if Element.Flag and DX.Flags[Element.Flag] == Element then DX.Flags[Element.Flag] = nil end
        card:Destroy()
    end
    function Element:Extra(paddingBottom)
        local holder = New("Frame", {Name = "Extra", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 2, Parent = frame})
        local inner = New("Frame", {Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = holder}, {Padding(14, 14, 0, paddingBottom or 14), List(6)})
        return holder, inner
    end
    Element.Card, Element.Frame, Element.Header, Element.Right, Element.TitleLabel, Element.DescLabel = card, frame, header, right, title, desc
    return Element
end

local function ExpandTo(holder, inner, open, time)
    Tween(holder, time or 0.3, {Size = UDim2.new(1, 0, 0, open and inner.AbsoluteSize.Y / ScaleOf(inner) or 0)})
end

function Elements:Section(config)
    config = config or {}
    local Section = setmetatable({Window = self.Window, Tab = self.Tab, Opened = config.Opened ~= false, Title = config.Title or "Section"}, {__index = Elements})
    local frame = New("Frame", {Name = "[Section] " .. Section.Title, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = self.Container}, {List(8)})
    local header = New("TextButton", {Name = "Header", Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame})
    local left = 0
    if config.Icon and DX:GetIcon(config.Icon) then
        Icon(config.Icon, 16, "Accent", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Parent = header})
        left = 24
    end
    local title = Text({Text = Section.Title, TextSize = config.TextSize or 15, FontFace = GetFont(Weight.SemiBold), Position = UDim2.fromOffset(left, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AutoX, Parent = header})
    local line = New("Frame", {Name = "Line", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -26, 0.5, 0), Size = UDim2.new(1, -200, 0, 1), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, Parent = header})
    local chevron = Icon("chevron-down", 16, "SubText", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Visible = false, Parent = header})
    if config.Box then
        frame.BackgroundTransparency = 1
        Corner(12).Parent = frame
        Stroke("Stroke").Parent = frame
        Padding(12, 12, 10, 12).Parent = frame
    end
    local function fitLine()
        line.Size = UDim2.new(1, -(left + title.TextBounds.X / ScaleOf(title) + 40), 0, 1)
    end
    title:GetPropertyChangedSignal("TextBounds"):Connect(fitLine)
    fitLine()
    local holder = New("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 2, Parent = frame})
    local inner = New("Frame", {Name = "Elements", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = holder}, {Padding(1, 1, 1, 1), List(8)})
    Section.Container = inner
    local hasContent = false
    inner.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") then
            hasContent = true
            if chevron then chevron.Visible = true end
        end
    end)
    local animating = false
    local function apply(animate)
        if animate then
            animating = true
            ExpandTo(holder, inner, Section.Opened, 0.35)
            task.delay(0.36, function() animating = false end)
        else
            holder.Size = UDim2.new(1, 0, 0, Section.Opened and inner.AbsoluteSize.Y / ScaleOf(inner) or 0)
        end
        if chevron then Tween(chevron, 0.3, {Rotation = Section.Opened and 0 or -90}) end
    end
    inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if not animating then apply(false) end
    end)
    header.Activated:Connect(function()
        if not hasContent then return end
        Section.Opened = not Section.Opened
        apply(true)
    end)
    function Section:Open() Section.Opened = true apply(true) end
    function Section:Close() Section.Opened = false apply(true) end
    function Section:SetTitle(value) Section.Title = value title.Text = value end
    function Section:Destroy() frame:Destroy() end
    apply(false)
    return Section
end

function Elements:Toggle(config)
    config = config or {}
    local checkbox = config.Type == "Checkbox"
    local Element = BaseElement(self, config, {RightWidth = checkbox and 24 or 46, Button = true})
    Element.Type = "Toggle"
    Element.Value = config.Value == true or config.Default == true
    local render
    if checkbox then
        local box = New("Frame", {Name = "Checkbox", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(24, 24), Theme = {BackgroundColor3 = "Field"}, Parent = Element.Right}, {Corner(7)})
        local boxStroke = Stroke("Stroke")
        boxStroke.Parent = box
        local boxFill = New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Parent = box}, {Corner(7)})
        AccentGradient(boxFill, 45)
        local check = Icon("check", 16, nil, {Name = "Check", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 1, ZIndex = 3, Parent = box})
        local checkScale = check and New("UIScale", {Scale = 0.5, Parent = check})
        render = function(animate)
            local time = animate and 0.3 or 0
            Tween(boxFill, time, {BackgroundTransparency = Element.Value and 0 or 1})
            Tween(boxStroke, time, {Transparency = Element.Value and 1 or 0})
            if check then
                Tween(check, time, {ImageTransparency = Element.Value and 0 or 1})
                Tween(checkScale, time + 0.1, {Scale = Element.Value and 1 or 0.5}, Enum.EasingStyle.Back)
            end
        end
    end
    local track = not checkbox and New("Frame", {Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(46, 24), Theme = {BackgroundColor3 = "Field"}, Parent = Element.Right}, {Corner(Round)})
    if track then
    local trackStroke = Stroke("Stroke")
    trackStroke.Parent = track
    local fill = New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Parent = track}, {Corner(Round)})
    AccentGradient(fill, 0)
    local knob = New("Frame", {Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = track}, {Corner(Round)})
    render = function(animate)
        local time = animate and 0.35 or 0
        local theme = CurrentTheme()
        Tween(fill, time * 0.8, {BackgroundTransparency = Element.Value and 0 or 1})
        Tween(trackStroke, time * 0.8, {Transparency = Element.Value and 1 or 0})
        Tween(knob, time, {Position = Element.Value and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0), BackgroundColor3 = Element.Value and Color3.new(1, 1, 1) or theme.SubText}, Enum.EasingStyle.Back)
        if animate then
            Tween(knob, 0.12, {Size = UDim2.fromOffset(22, 16)})
            task.delay(0.12, function() Tween(knob, 0.25, {Size = UDim2.fromOffset(16, 16)}, Enum.EasingStyle.Back) end)
        end
    end
    end
    function Element:Set(value, silent)
        Element.Value = value and true or false
        render(true)
        if not silent then SafeCall(config.Callback, Element.Value) end
    end
    function Element:Get() return Element.Value end
    Element.UpdateState = Element.Set
    Element.GetState = Element.Get
    Element.Header.Activated:Connect(function()
        if Element.Locked then return end
        Element:Set(not Element.Value)
    end)
    OnTheme(function() render(false) end)
    RegisterElement(self, Element, config)
    if Element.Value then SafeCall(config.Callback, true) end
    return Element
end

function Elements:Button(config)
    config = config or {}
    local Element = BaseElement(self, config, {RightWidth = 20, Button = true})
    Element.Type = "Button"
    local arrow = Icon(config.ButtonIcon or "mouse-pointer-click", 16, "SubText", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = Element.Right})
    Element.Header.Activated:Connect(function()
        if Element.Locked then return end
        if arrow then
            Tween(arrow, 0.12, {Position = UDim2.new(1, 3, 0.5, 0)})
            task.delay(0.15, function()
                Tween(arrow, 0.35, {Position = UDim2.new(1, 0, 0.5, 0)}, Enum.EasingStyle.Back)
            end)
        end
        SafeCall(config.Callback)
    end)
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Slider(config)
    config = config or {}
    local range = config.Value or {}
    local min = range.Min or config.Min or config.Minimum or 0
    local max = range.Max or config.Max or config.Maximum or 100
    local step = config.Step or 1
    local suffix = config.Suffix or ""
    local Element = BaseElement(self, config, {RightWidth = 72})
    Element.Type = "Slider"
    local box = New("TextBox", {Name = "Value", 
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(72, 28),
        Theme = {BackgroundColor3 = "Field", TextColor3 = "Text"},
        FontFace = GetFont(Weight.Medium),
        TextSize = 13,
        Text = "",
        ClearTextOnFocus = false,
        Parent = Element.Right,
    }, {Corner(7)})
    local boxStroke = Stroke("Stroke")
    boxStroke.Parent = box
    local holder = New("Frame", {Name = "Slider", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 2, Parent = Element.Frame}, {Padding(14, 14, 0, 8)})
    local hit = New("TextButton", {Name = "SliderHit", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder})
    local track = New("Frame", {Name = "Track", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -28, 0, 8), Theme = {BackgroundColor3 = "Field"}, Parent = hit}, {Corner(Round)})
    local fill = New("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track}, {Corner(Round)})
    AccentGradient(fill, 0)
    local knob = New("Frame", {Name = "Thumb", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(28, 18), BackgroundColor3 = Color3.fromRGB(250, 251, 255), ZIndex = 3, Parent = track}, {Corner(Round), Stroke("Stroke", 0.38)})
    New("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(218, 225, 237)), Parent = knob})
    local decimals = tostring(step):match("%.(%d+)")
    local function format(value)
        if decimals then return string.format("%." .. #decimals .. "f", value) end
        return tostring(math.floor(value + 0.5))
    end
    local function snap(value)
        value = math.clamp(value, min, max)
        value = min + math.floor((value - min) / step + 0.5) * step
        return math.clamp(tonumber(format(value)) or value, min, max)
    end
    function Element:Set(value, silent, instant)
        value = snap(tonumber(value) or min)
        local changed = value ~= Element.Value
        Element.Value = value
        local alpha = max > min and (value - min) / (max - min) or 0
        Tween(fill, instant and 0 or 0.2, {Size = UDim2.fromScale(alpha, 1)})
        Tween(knob, instant and 0 or 0.2, {Position = UDim2.fromScale(alpha, 0.5)})
        if not box:IsFocused() then box.Text = format(value) .. suffix end
        if changed and not silent then SafeCall(config.Callback, value) end
    end
    function Element:Get() return Element.Value end
    function Element:SetMin(value) min = value Element:Set(Element.Value, true, true) end
    function Element:SetMax(value) max = value Element:Set(Element.Value, true, true) end
    Element.UpdateValue = Element.Set
    Element.GetValue = Element.Get
    local dragInput
    local function update(input)
        local position = PointerPosition(input)
        local alpha = math.clamp((position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        Element:Set(min + alpha * (max - min), false, true)
    end
    hit.InputBegan:Connect(function(input)
        if dragInput or Element.Locked or not IsPress(input) then return end
        dragInput = input
        Tween(knob, 0.14, {Size = UDim2.fromOffset(30, 20)})
        update(input)
    end)
    table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if MovesPointer(dragInput, input) then
            update(input)
        end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if EndsPointer(dragInput, input) then
            dragInput = nil
            Tween(knob, 0.16, {Size = UDim2.fromOffset(28, 18)})
            SafeCall(config.OnInputComplete or config.onInputComplete, Element.Value)
        end
    end))
    box.Focused:Connect(function()
        box.Text = format(Element.Value)
        Retheme(boxStroke, "Color", "Accent", 0.2)
    end)
    box.FocusLost:Connect(function()
        Retheme(boxStroke, "Color", "Stroke", 0.2)
        local number = tonumber((box.Text:gsub("[^%d%.%-]", "")))
        Element:Set(number or Element.Value)
        box.Text = format(Element.Value) .. suffix
    end)
    Element:Set(range.Default or config.Default or min, true, true)
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Input(config)
    config = config or {}
    local textarea = config.Type == "Textarea"
    local width = config.InputWidth or 170
    local Element = BaseElement(self, config, {RightWidth = textarea and 0 or width})
    Element.Type = "Input"
    Element.Value = tostring(config.Value or config.Default or "")
    local parent = Element.Right
    if textarea then
        local holder = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = 2, Parent = Element.Frame}, {Padding(14, 14, 0, 12)})
        parent = holder
    end
    local field = New("Frame", {Name = "Field", 
        AnchorPoint = textarea and Vector2.zero or Vector2.new(1, 0.5),
        Position = textarea and UDim2.new() or UDim2.new(1, 0, 0.5, 0),
        Size = textarea and UDim2.new(1, 0, 0, 84) or UDim2.fromOffset(width, 30),
        Theme = {BackgroundColor3 = "Field"},
        Parent = parent,
    }, {Corner(8)})
    local fieldStroke = Stroke("Stroke")
    fieldStroke.Parent = field
    local offset = 10
    if config.InputIcon and DX:GetIcon(config.InputIcon) then
        Icon(config.InputIcon, 14, "SubText", {AnchorPoint = Vector2.new(0, textarea and 0 or 0.5), Position = textarea and UDim2.fromOffset(10, 9) or UDim2.new(0, 10, 0.5, 0), Parent = field})
        offset = 30
    end
    local box = New("TextBox", {
        Position = UDim2.fromOffset(offset, textarea and 8 or 0),
        Size = textarea and UDim2.new(1, -(offset + 10), 1, -16) or UDim2.new(1, -(offset + 10), 1, 0),
        BackgroundTransparency = 1,
        Text = Element.Value,
        PlaceholderText = config.Placeholder or config.PlaceholderText or "Enter text...",
        Theme = {TextColor3 = "Text", PlaceholderColor3 = "SubText"},
        FontFace = GetFont(),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = textarea and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        ClearTextOnFocus = config.ClearTextOnFocus == true,
        MultiLine = textarea,
        TextWrapped = textarea,
        TextTruncate = textarea and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
        ClipsDescendants = true,
        Parent = field,
    })
    local filter = config.AcceptedCharacters or (config.Numeric and "Numeric")
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if filter == "Numeric" then
            local clean = box.Text:gsub("[^%d%.%-]", "")
            if clean ~= box.Text then box.Text = clean end
        elseif type(filter) == "function" then
            local ok, clean = pcall(filter, box.Text)
            if ok and type(clean) == "string" and clean ~= box.Text then box.Text = clean end
        end
        SafeCall(config.OnChanged or config.onChanged, box.Text)
    end)
    box.Focused:Connect(function() Retheme(fieldStroke, "Color", "Accent", 0.2) end)
    box.FocusLost:Connect(function(enterPressed)
        Retheme(fieldStroke, "Color", "Stroke", 0.25)
        Element.Value = box.Text
        SafeCall(config.Callback, box.Text, enterPressed)
    end)
    function Element:Set(value, silent)
        Element.Value = tostring(value or "")
        box.Text = Element.Value
        if not silent then SafeCall(config.Callback, Element.Value) end
    end
    function Element:Get() return Element.Value end
    function Element:SetPlaceholder(value) box.PlaceholderText = value end
    Element.UpdateText = Element.Set
    Element.GetInput = Element.Get
    Element.UpdatePlaceholder = Element.SetPlaceholder
    Element.TextBox = box
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Dropdown(config)
    config = config or {}
    local width = config.DropdownWidth or (DX.IsMobile and 132 or 170)
    local Element = BaseElement(self, config, {RightWidth = width, Button = true, Hover = false})
    Element.Type = "Dropdown"
    Element.Multi = config.Multi == true
    Element.Values = config.Values or config.Options or {}
    Element.Opened = false
    local allowNone = config.AllowNone ~= false and config.Required ~= true
    local selector = New("Frame", {Name = "Selector", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(width, 30), Theme = {BackgroundColor3 = "Field"}, Parent = Element.Right}, {Corner(8)})
    local selectorStroke = Stroke("Stroke")
    selectorStroke.Parent = selector
    local selected = Text({Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -36, 1, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = selector})
    local chevron = Icon("chevron-down", 15, "SubText", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Parent = selector})
    local holder, inner = Element:Extra(12)
    local search
    if config.Search or #Element.Values > 8 then
        local searchField = New("Frame", {Size = UDim2.new(1, 0, 0, 30), Theme = {BackgroundColor3 = "Field"}, LayoutOrder = 0, Parent = inner}, {Corner(8), Stroke("Stroke")})
        Icon("search", 14, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Parent = searchField})
        search = New("TextBox", {Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search...", Theme = {TextColor3 = "Text", PlaceholderColor3 = "SubText"}, FontFace = GetFont(), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = searchField})
    end
    local scroll = New("ScrollingFrame", {Name = "Options", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, Theme = {ScrollBarImageColor3 = "Stroke"}, AutomaticCanvasSize = AutoY, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, LayoutOrder = 1, Parent = inner}, {List(5), Padding(0, 4, 0, 0)})
    local rows = {}
    local function isSelected(value)
        if Element.Multi then return table.find(Element.Value, value) ~= nil end
        return Element.Value == value
    end
    local function display()
        if Element.Multi then
            selected.Text = #Element.Value > 0 and table.concat(Element.Value, ", ") or "None"
        else
            selected.Text = Element.Value ~= nil and tostring(Element.Value) or "Select..."
        end
    end
    local function paint(animate)
        for value, row in pairs(rows) do
            local on = isSelected(value)
            Retheme(row.Label, "TextColor3", on and "Text" or "SubText", animate and 0.2 or 0)
            Tween(row.Frame, animate and 0.15 or 0, {BackgroundTransparency = on and (row.Hovered and 0.54 or 0.67) or (row.Hovered and 0.83 or 1)})
            if row.Check then Tween(row.Check, animate and 0.18 or 0, {ImageTransparency = on and 0 or 1}) end
        end
        display()
    end
    local function resize()
        local count = 0
        for _, row in pairs(rows) do if row.Frame.Visible then count += 1 end end
        scroll.Size = UDim2.new(1, 0, 0, math.min(math.max(count * 35 - 5, 0), config.MaxHeight or 200))
        if Element.Opened then ExpandTo(holder, inner, true, 0.25) end
    end
    local function commit(silent)
        paint(true)
        if not silent then SafeCall(config.Callback, Element.Value) end
    end
    local function choose(value)
        if Element.Locked then return end
        if Element.Multi then
            local index = table.find(Element.Value, value)
            if index then
                if #Element.Value > 1 or allowNone then table.remove(Element.Value, index) end
            else
                table.insert(Element.Value, value)
            end
            commit()
        else
            if Element.Value == value and allowNone then
                Element.Value = nil
            else
                Element.Value = value
            end
            commit()
            Element:Close()
        end
    end
    local function build()
        for _, row in pairs(rows) do row.Frame:Destroy() end
        rows = {}
        for index, option in ipairs(Element.Values) do
            local value = type(option) == "table" and (option.Title or option.Name) or option
            local row = New("TextButton", {Name = tostring(value), Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30), Theme = {BackgroundColor3 = "Accent"}, BackgroundTransparency = 1, LayoutOrder = index, Parent = scroll}, {Corner(7)})
            if index > 1 then
                New("Frame", {Name = "Separator", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -2), Size = UDim2.new(1, -16, 0, 1), Theme = {BackgroundColor3 = "Stroke"}, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = row})
            end
            local offset = 10
            if type(option) == "table" and option.Icon and DX:GetIcon(option.Icon) then
                Icon(option.Icon, 15, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Parent = row})
                offset = 32
            end
            local label = Text({Text = tostring(value), Position = UDim2.fromOffset(offset, 0), Size = UDim2.new(1, -(offset + 30), 1, 0), TextSize = 13, Theme = {TextColor3 = "SubText"}, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
            local check = Icon("check", 15, "Accent", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -16, 0.5, 0), ImageTransparency = 1, Parent = row})
            local optionRow = {Frame = row, Label = label, Check = check, Hovered = false}
            rows[value] = optionRow
            row.MouseEnter:Connect(function()
                optionRow.Hovered = true
                Tween(row, 0.13, {BackgroundTransparency = isSelected(value) and 0.54 or 0.83})
            end)
            row.MouseLeave:Connect(function()
                optionRow.Hovered = false
                Tween(row, 0.15, {BackgroundTransparency = isSelected(value) and 0.67 or 1})
            end)
            row.Activated:Connect(function() choose(value) end)
        end
        paint(false)
        resize()
    end
    function Element:Open()
        if Element.Opened or Element.Locked then return end
        Element.Opened = true
        Retheme(selectorStroke, "Color", "Accent", 0.2)
        if chevron then Tween(chevron, 0.3, {Rotation = 180}) end
        ExpandTo(holder, inner, true, 0.22)
    end
    function Element:Close()
        if not Element.Opened then return end
        Element.Opened = false
        Retheme(selectorStroke, "Color", "Stroke", 0.2)
        if chevron then Tween(chevron, 0.3, {Rotation = 0}) end
        ExpandTo(holder, inner, false, 0.3)
    end
    function Element:Select(value, silent)
        if Element.Multi then
            Element.Value = {}
            for _, item in ipairs(type(value) == "table" and value or {value}) do table.insert(Element.Value, item) end
        elseif type(value) == "number" and Element.Values[value] ~= nil then
            local option = Element.Values[value]
            Element.Value = type(option) == "table" and (option.Title or option.Name) or option
        else
            Element.Value = value
        end
        commit(silent)
    end
    function Element:Refresh(values, keep)
        Element.Values = values or {}
        if not keep then
            if Element.Multi then
                local kept = {}
                for _, item in ipairs(Element.Value) do
                    for _, option in ipairs(Element.Values) do
                        if (type(option) == "table" and (option.Title or option.Name) or option) == item then table.insert(kept, item) end
                    end
                end
                Element.Value = kept
            end
        end
        build()
    end
    function Element:Get() return Element.Value end
    Element.Set = Element.Select
    Element.UpdateSelection = Element.Select
    Element.InsertOptions = function(_, values)
        for _, value in ipairs(values) do table.insert(Element.Values, value) end
        build()
    end
    Element.ClearOptions = function() Element:Refresh({}) end
    Element.Header.Activated:Connect(function()
        if Element.Opened then Element:Close() else Element:Open() end
    end)
    if search then
        search:GetPropertyChangedSignal("Text"):Connect(function()
            local query = search.Text:lower()
            for value, row in pairs(rows) do
                row.Frame.Visible = query == "" or tostring(value):lower():find(query, 1, true) ~= nil
            end
            resize()
        end)
    end
    local initial = config.Value or config.Default
    if Element.Multi then
        Element.Value = {}
        for _, item in ipairs(type(initial) == "table" and initial or {}) do table.insert(Element.Value, item) end
    elseif type(initial) == "number" and Element.Values[initial] ~= nil then
        local option = Element.Values[initial]
        Element.Value = type(option) == "table" and (option.Title or option.Name) or option
    else
        Element.Value = initial
    end
    build()
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Keybind(config)
    config = config or {}
    local Element = BaseElement(self, config, {RightWidth = 96})
    Element.Type = "Keybind"
    local function keyName(value)
        if typeof(value) == "EnumItem" then return value.Name end
        if value == nil or value == "" then return "None" end
        return tostring(value)
    end
    Element.Value = keyName(config.Value or config.Default)
    local box = New("TextButton", {Name = "Key", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, Theme = {BackgroundColor3 = "Field"}, Parent = Element.Right}, {Corner(7), Padding(12, 12, 0, 0)})
    local boxStroke = Stroke("Stroke")
    boxStroke.Parent = box
    local label = Text({Text = Element.Value, Size = UDim2.fromOffset(0, 28), AutomaticSize = AutoX, TextSize = 13, FontFace = GetFont(Weight.SemiBold), Parent = box})
    local listening = false
    local pulse
    local function stopListening()
        listening = false
        if self.Window.Rebinding == Element then self.Window.Rebinding = nil end
        if pulse then pulse:Cancel() pulse = nil end
        Retheme(boxStroke, "Color", "Stroke", 0.2)
        boxStroke.Transparency = 0
        label.Text = Element.Value
    end
    function Element:Set(value, silent)
        Element.Value = keyName(value)
        label.Text = Element.Value
        if not silent then SafeCall(config.Callback, Element.Value) end
    end
    function Element:Get() return Element.Value end
    function Element:GetKeyCode() return Enum.KeyCode[Element.Value] end
    Element.Bind = Element.Set
    Element.GetBind = Element.Get
    function Element:Unbind() Element:Set("None") end
    Element.Card.Destroying:Once(function()
        if self.Window.Rebinding == Element then self.Window.Rebinding = nil end
        if pulse then pulse:Cancel() end
    end)
    box.Activated:Connect(function()
        if Element.Locked or self.Window.Rebinding then return end
        self.Window.Rebinding = Element
        listening = true
        label.Text = "..."
        Retheme(boxStroke, "Color", "Accent", 0.2)
        pulse = TweenService:Create(boxStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.7})
        pulse:Play()
    end)
    table.insert(self.Window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                stopListening()
                if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Backspace then
                    Element:Set("None")
                else
                    Element:Set(key.Name)
                    SafeCall(config.OnBinded or config.onBinded, key)
                end
            end
            return
        end
        if processed or Element.Value == "None" then return end
        if input.KeyCode.Name == Element.Value then
            Tween(box, 0.1, {BackgroundColor3 = CurrentTheme().Accent})
            task.delay(0.12, function() Retheme(box, "BackgroundColor3", "Field", 0.3) end)
            SafeCall(config.Pressed or config.OnPress, Element.Value)
        end
    end))
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Colorpicker(config)
    config = config or {}
    local Element = BaseElement(self, config, {RightWidth = 46, Button = true})
    Element.Type = "Colorpicker"
    Element.Value = config.Default or config.Value or Color3.fromRGB(59, 130, 246)
    Element.Transparency = config.Transparency or config.Alpha
    Element.Opened = false
    local hue, sat, val = Element.Value:ToHSV()
    local swatch = New("Frame", {Name = "Swatch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(46, 24), BackgroundColor3 = Element.Value, Parent = Element.Right}, {Corner(7)})
    Stroke("Stroke").Parent = swatch
    local holder, inner = Element:Extra(14)
    local area = New("Frame", {Name = "Picker", Size = UDim2.new(1, 0, 0, 132), BackgroundTransparency = 1, LayoutOrder = 1, Parent = inner})
    local sv = New("TextButton", {Name = "Saturation", Text = "", AutoButtonColor = false, Size = UDim2.new(1, -28, 1, 0), BackgroundColor3 = Color3.fromHSV(hue, 1, 1), Parent = area}, {Corner(8)})
    New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv}, {Corner(8), New("UIGradient", {Transparency = NumberSequence.new(0, 1)})})
    New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv}, {Corner(8), New("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)})})
    local svCursor = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Element.Value, ZIndex = 5, Parent = sv}, {Corner(Round), New("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2})})
    local hueKeys = {}
    for index = 0, 6 do table.insert(hueKeys, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1))) end
    local hueBar = New("TextButton", {Name = "Hue", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 16, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = area}, {Corner(8), New("UIGradient", {Rotation = 90, Color = ColorSequence.new(hueKeys)})})
    local hueCursor = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, 6, 0, 6), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5, Parent = hueBar}, {Corner(Round), New("UIStroke", {Color = Color3.new(0, 0, 0), Transparency = 0.6})})
    local bottom = New("Frame", {Name = "Info", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 2, Parent = inner}, {List(8, Horizontal, nil, Enum.VerticalAlignment.Center)})
    local preview = New("Frame", {Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Element.Value, LayoutOrder = 1, Parent = bottom}, {Corner(8), Stroke("Stroke")})
    local hexField = New("Frame", {Size = UDim2.fromOffset(110, 30), Theme = {BackgroundColor3 = "Field"}, LayoutOrder = 2, Parent = bottom}, {Corner(8), Stroke("Stroke")})
    local hexBox = New("TextBox", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = "", Theme = {TextColor3 = "Text"}, FontFace = GetFont(Weight.Medium), TextSize = 13, ClearTextOnFocus = false, Parent = hexField})
    local rgbLabel = Text({Size = UDim2.new(1, -160, 1, 0), TextSize = 12, Theme = {TextColor3 = "SubText"}, LayoutOrder = 3, Parent = bottom})
    local function refresh(silent)
        Element.Value = Color3.fromHSV(hue, sat, val)
        sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svCursor.Position = UDim2.fromScale(sat, 1 - val)
        svCursor.BackgroundColor3 = Element.Value
        hueCursor.Position = UDim2.fromScale(0.5, hue)
        Tween(swatch, 0.15, {BackgroundColor3 = Element.Value})
        preview.BackgroundColor3 = Element.Value
        if not hexBox:IsFocused() then hexBox.Text = "#" .. Element.Value:ToHex():upper() end
        rgbLabel.Text = string.format("RGB  %d, %d, %d", math.floor(Element.Value.R * 255 + 0.5), math.floor(Element.Value.G * 255 + 0.5), math.floor(Element.Value.B * 255 + 0.5))
        if not silent then SafeCall(config.Callback, Element.Value, Element.Transparency) end
    end
    local dragTarget
    local function drag(input)
        local position = PointerPosition(input)
        if dragTarget == sv then
            sat = math.clamp((position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
            val = 1 - math.clamp((position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        elseif dragTarget == hueBar then
            hue = math.clamp((position.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 0.999)
        end
        refresh()
    end
    for _, target in ipairs({sv, hueBar}) do
        target.InputBegan:Connect(function(input)
            if Element.Locked or not IsPress(input) then return end
            dragTarget = target
            Tween(target == sv and svCursor or hueCursor, 0.2, {Size = target == sv and UDim2.fromOffset(18, 18) or UDim2.new(1, 8, 0, 8)}, Enum.EasingStyle.Back)
            drag(input)
        end)
    end
    table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragTarget and IsMove(input) then drag(input) end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if dragTarget and IsPress(input) then
            Tween(svCursor, 0.2, {Size = UDim2.fromOffset(14, 14)})
            Tween(hueCursor, 0.2, {Size = UDim2.new(1, 6, 0, 6)})
            dragTarget = nil
        end
    end))
    hexBox.FocusLost:Connect(function()
        local ok, color = pcall(Color3.fromHex, (hexBox.Text:gsub("#", "")))
        if ok and color then
            hue, sat, val = color:ToHSV()
        end
        refresh()
    end)
    function Element:Set(color, transparency, silent)
        if typeof(color) ~= "Color3" then return end
        if transparency ~= nil then Element.Transparency = transparency end
        hue, sat, val = color:ToHSV()
        refresh(silent)
    end
    function Element:Get() return Element.Value, Element.Transparency end
    Element.Update = Element.Set
    Element.SetColor = Element.Set
    function Element:SetAlpha(value) Element.Transparency = value refresh() end
    function Element:Open()
        Element.Opened = true
        ExpandTo(holder, inner, true, 0.35)
    end
    function Element:Close()
        Element.Opened = false
        ExpandTo(holder, inner, false, 0.3)
    end
    Element.Header.Activated:Connect(function()
        if Element.Locked then return end
        if Element.Opened then Element:Close() else Element:Open() end
    end)
    refresh(true)
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Paragraph(config)
    config = config or {}
    if config.Image and not config.Icon then config.Icon = config.Image end
    local Element = BaseElement(self, config, {})
    Element.Type = "Paragraph"
    Element.TitleLabel.FontFace = GetFont(Weight.Bold)
    local thumbnail
    if config.Thumbnail and config.Thumbnail ~= "" then
        local thumbHolder = New("Frame", {Name = "Thumbnail", Size = UDim2.new(1, 0, 0, (config.ThumbnailSize or 80) + 12), BackgroundTransparency = 1, LayoutOrder = 2, Parent = Element.Frame}, {Padding(14, 14, 0, 12)})
        thumbnail = New("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, Image = DX:GetIcon(config.Thumbnail) or config.Thumbnail, Parent = thumbHolder}, {Corner(8)})
    end
    function Element:SetImage(value)
        if Element.IconImage then Element.IconImage.Image = DX:GetIcon(value) or value end
    end
    function Element:SetThumbnail(value)
        if thumbnail then thumbnail.Image = DX:GetIcon(value) or value end
    end
    if config.Color then
        local bar = New("Frame", {Name = "Bar", Size = UDim2.new(0, 3, 1, -20), Position = UDim2.fromOffset(0, 10), BorderSizePixel = 0, ZIndex = 2, Parent = Element.Card}, {Corner(Round)})
        if typeof(config.Color) == "Color3" then bar.BackgroundColor3 = config.Color else Bind(bar, "BackgroundColor3", CurrentTheme()[config.Color] and config.Color or "Accent") end
    end
    if config.Buttons and #config.Buttons > 0 then
        local row = New("Frame", {Name = "Buttons", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 3, Parent = Element.Frame}, {Padding(14, 14, 0, 12), List(8, Horizontal)})
        for index, buttonConfig in ipairs(config.Buttons) do
            local button = ActionButton(row, buttonConfig)
            button.LayoutOrder = index
        end
    end
    Element.SetContent = Element.SetDesc
    Element.UpdateHeader = Element.SetTitle
    Element.UpdateBody = Element.SetDesc
    RegisterElement(self, Element, config)
    return Element
end

function Elements:Label(config)
    if type(config) == "string" then config = {Title = config} end
    config = config or {}
    local holder = New("Frame", {Name = "[Label]", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = self.Container}, {Padding(4, 4, 2, 2)})
    local label = Text({Text = config.Title or config.Text or "", TextSize = config.TextSize or 13, Theme = {TextColor3 = config.Sub and "SubText" or "Text"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, Parent = holder})
    local Element = {Type = "Label"}
    function Element:Set(value) label.Text = value end
    Element.SetTitle = Element.Set
    Element.UpdateName = Element.Set
    function Element:SetVisible(value) holder.Visible = value end
    function Element:Destroy() holder:Destroy() end
    return Element
end

function Elements:SubLabel(config)
    if type(config) == "string" then config = {Title = config} end
    config = config or {}
    config.Sub = true
    config.TextSize = config.TextSize or 12
    return self:Label(config)
end

function Elements:Divider()
    local line = New("Frame", {Name = "[Divider]", Size = UDim2.new(1, 0, 0, 1), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = self.Container})
    return {Destroy = function() line:Destroy() end, Remove = function() line:Destroy() end, SetVisible = function(_, value) line.Visible = value end}
end

function Elements:Space(height)
    if type(height) == "table" then height = height.Size or height.Height end
    local space = New("Frame", {Name = "[Space]", Size = UDim2.new(1, 0, 0, height or 6), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = self.Container})
    return {Destroy = function() space:Destroy() end, Remove = function() space:Destroy() end}
end
Elements.Spacer = Elements.Space

function Elements:Code(config)
    config = config or {}
    local frame = New("Frame", {Name = "[Code]", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Theme = {BackgroundColor3 = "Field"}, LayoutOrder = NextOrder(), Parent = self.Container}, {Corner(10), Stroke("Stroke"), Padding(14, 14, 10, 12), List(8)})
    local head = New("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame})
    Text({Text = config.Title or "Code", TextSize = 13, FontFace = GetFont(Weight.SemiBold), Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, -30, 1, 0), Parent = head})
    local copy = New("ImageButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Image = DX:GetIcon("copy") or "", ImageColor3 = Color3.new(1, 1, 1), Parent = head})
    local code = New("TextLabel", {Text = config.Code or "", TextSize = 13, FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"), Theme = {TextColor3 = "Text"}, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, LayoutOrder = 2, Parent = frame})
    local Element = {Title = config.Title or "Code", CopyCallbacks = {config.OnCopy}}
    copy.Activated:Connect(function()
        pcall(function() (setclipboard or toclipboard)(code.Text) end)
        copy.Image = DX:GetIcon("check") or copy.Image
        task.delay(1.2, function() copy.Image = DX:GetIcon("copy") or copy.Image end)
        for _, callback in pairs(Element.CopyCallbacks) do SafeCall(callback) end
    end)
    function Element:SetCode(value) code.Text = tostring(value or "") end
    Element.Set = Element.SetCode
    function Element:OnCopy(callback) table.insert(Element.CopyCallbacks, callback) end
    function Element:Destroy() frame:Destroy() end
    return Element
end

local function Serialize(element)
    if element.Type == "Colorpicker" then
        return {Type = element.Type, Value = element.Value:ToHex(), Transparency = element.Transparency}
    end
    return {Type = element.Type, Value = element.Value}
end

local function Deserialize(element, data)
    if element.Type == "Colorpicker" then
        local ok, color = pcall(Color3.fromHex, data.Value)
        if ok then element:Set(color, data.Transparency) end
    elseif element.Type == "Dropdown" then
        element:Select(data.Value)
    elseif element.Set then
        element:Set(data.Value)
    end
end

local function CreateConfigManager(Window)
    local Manager = {Folder = Window.Folder .. "/configs"}
    local function ensure()
        if not (isfolder and makefolder) then return false end
        local path = ""
        for part in Manager.Folder:gmatch("[^/]+") do
            path = path == "" and part or path .. "/" .. part
            if not isfolder(path) then makefolder(path) end
        end
        return true
    end
    function Manager:Path(name)
        return Manager.Folder .. "/" .. name .. ".json"
    end
    function Manager:CreateConfig(name)
        local Config = {Name = name}
        function Config:Save()
            if not ensure() or not writefile then return false end
            local data = {}
            for flag, element in pairs(DX.Flags) do
                if element.Window == Window and element.Type and element.IgnoreConfig ~= true then data[flag] = Serialize(element) end
            end
            writefile(Manager:Path(name), HttpService:JSONEncode(data))
            return true
        end
        function Config:Load()
            if not (isfile and readfile) or not isfile(Manager:Path(name)) then return false end
            local ok, data = pcall(function() return HttpService:JSONDecode(readfile(Manager:Path(name))) end)
            if not ok or type(data) ~= "table" then return false end
            for flag, value in pairs(data) do
                local element = DX.Flags[flag]
                if element and element.Window == Window and element.IgnoreConfig ~= true then pcall(Deserialize, element, value) end
            end
            return true
        end
        function Config:Register(flag, element)
            if type(element) == "table" then
                element.Flag = flag
                element.Window = element.Window or Window
                DX.Flags[flag] = element
            end
            return Config
        end
        function Config:Delete()
            if isfile and delfile and isfile(Manager:Path(name)) then delfile(Manager:Path(name)) end
        end
        return Config
    end
    function Manager:AllConfigs()
        local list = {}
        if not (ensure() and listfiles) then return list end
        for _, file in ipairs(listfiles(Manager.Folder)) do
            local name = tostring(file):match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
        table.sort(list)
        return list
    end
    function Manager:SetAutoLoad(name)
        if ensure() and writefile then writefile(Manager.Folder .. "/autoload.txt", name or "") end
    end
    function Manager:LoadAutoLoad()
        if not (isfile and readfile) or not isfile(Manager.Folder .. "/autoload.txt") then return false end
        local name = readfile(Manager.Folder .. "/autoload.txt")
        if name == "" then return false end
        return Manager:CreateConfig(name):Load()
    end
    return Manager
end

function DX:CreateWindow(config)
    config = config or {}
    if config.Theme and DX.Themes[config.Theme] then DX.Theme = config.Theme end
    local Window = {
        Title = config.Title or "DX-SR Hub",
        Folder = config.Folder or "DX-UI",
        ToggleKey = Enum.KeyCode.RightShift,
        Tabs = {},
        Groups = {},
        Elements = {},
        Connections = {},
        Events = {Open = {}, Close = {}, Destroy = {}, ToggleKeyChanged = {}},
        Opened = false,
    }
    Window.Window = Window
    Window.ConfigManager = CreateConfigManager(Window)
    table.insert(DX.Windows, Window)

    local glass = config.Glass
    if glass == nil then glass = config.Transparent end
    if glass ~= nil then DX.Glass = glass == true end
    SyncGlassBlur()
    local minSize = config.MinSize or Vector2.new(520, 340)
    local maxSize = config.MaxSize or Vector2.new(960, 680)
    local size = config.Size or UDim2.fromOffset(660, 460)

    local function FitScale(current)
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        return math.max(0.20, math.min(config.Scale or 1, (view.X - 24) / current.X.Offset, (view.Y - inset.Y - 40) / current.Y.Offset))
    end
    Window.Scale = FitScale(size)
    local sideWidth = config.SideBarWidth or 200
    if DX.IsMobile then
        sideWidth = math.min(sideWidth, math.clamp(math.floor(size.X.Offset * 0.29), 96, 138))
    end
    local topHeight = 54

    local gui = ScreenGui("DX-UI", 1000)
    Window.Gui = gui

    local holder = New("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, GuiService:GetGuiInset().Y / 2), Size = size, BackgroundTransparency = 1, Visible = false, Parent = gui})
    local scale = New("UIScale", {Scale = Window.Scale, Parent = holder})
    local motion = New("Frame", {
        Name = "Fader",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = holder,
    })
    local canvas = not DX.IsMobile and New("CanvasGroup", {Name = "Fade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Parent = motion})
    local main = New("Frame", {Name = "Main", Size = UDim2.fromScale(1, 1), Theme = {BackgroundColor3 = "Background"}, Parent = motion}, {Corner(14), Stroke("Stroke")})
    local sheen = New("UIGradient", {Rotation = 35, Transparency = NumberSequence.new(0, 0.35), Parent = main})
    OnGlass(function(state) sheen.Enabled = state end, sheen)
    Frost(main, 14, 0.92)
    local backdrop = New("ImageLabel", {Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, Image = "", ImageTransparency = 1, Visible = false, ZIndex = 0, Parent = main}, {Corner(14)})
    local backdropTransparency = config.BackgroundImageTransparency or 0.5

    local origin = New("Frame", {Name = "Origin", Size = UDim2.new(), BackgroundTransparency = 1, Parent = gui})
    local blurPart = New("Part", {Name = "DXAcrylic", Material = Enum.Material.Glass, Color = Color3.new(0, 0, 0), Transparency = 0.98, Size = Vector3.new(1, 1, 0), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false})
    local blurMesh = New("SpecialMesh", {MeshType = Enum.MeshType.Brick, Offset = Vector3.new(0, 0, -0.000001), Parent = blurPart})
    local blurBind = "DXAcrylic" .. HttpService:GenerateGUID(false)
    local function viewPoint(camera, point)
        local ray = camera:ViewportPointToRay(point.X, point.Y)
        return ray.Origin + ray.Direction * 0.001
    end
    RunService:BindToRenderStep(blurBind, Enum.RenderPriority.Camera.Value + 1, function()
        local camera = workspace.CurrentCamera
        if not (camera and AcrylicEffect and AcrylicEffect.Parent and Window.Opened and holder.Visible) then
            blurPart.Parent = nil
            return
        end
        local inset = 5 * scale.Scale
        local position = main.AbsolutePosition - origin.AbsolutePosition + Vector2.new(inset, inset)
        local extent = main.AbsoluteSize - Vector2.new(inset * 2, inset * 2)
        local topLeft = viewPoint(camera, position)
        local topRight = viewPoint(camera, position + Vector2.new(extent.X, 0))
        local bottomRight = viewPoint(camera, position + extent)
        local view = camera.CFrame
        blurPart.CFrame = CFrame.fromMatrix((topLeft + bottomRight) / 2, view.XVector, view.YVector, view.ZVector)
        blurMesh.Scale = Vector3.new((topRight - topLeft).Magnitude, (topRight - bottomRight).Magnitude, 0)
        blurPart.Parent = camera
    end)
    table.insert(Window.Connections, {Disconnect = function()
        pcall(function() RunService:UnbindFromRenderStep(blurBind) end)
        blurPart:Destroy()
    end})

    local topbar = New("Frame", {Name = "Topbar", Size = UDim2.new(1, 0, 0, topHeight), BackgroundTransparency = 1, ClipsDescendants = true, Parent = main})
    New("Frame", {Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, Parent = topbar})
    local glow = New("Frame", {Name = "Glow", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, -160, 1, 0), Size = UDim2.new(0, 160, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = topbar})
    local glowGradient = New("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = glow})
    OnTheme(function(theme) glowGradient.Color = ColorSequence.new(theme.Accent, theme.Accent2) end)
    if not DX.IsMobile then
        TweenService:Create(glow, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(1, 0, 1, 0)}):Play()
    end

    local titleRow = New("Frame", {Name = "TitleRow", Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -150, 1, 0), BackgroundTransparency = 1, Parent = topbar}, {List(12, Horizontal, nil, Enum.VerticalAlignment.Center)})
    if config.Icon and DX:GetIcon(config.Icon) then
        local iconHolder = New("Frame", {Name = "Logo", Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, LayoutOrder = 1, Parent = titleRow})
        Icon(config.Icon, config.IconSize or 30, "Accent", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = iconHolder})
    end
    local titleBlock = New("Frame", {Name = "TitleBlock", Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, LayoutOrder = 2, Parent = titleRow}, {List(1)})
    local titleLabel = Text({Name = "Title", Text = Window.Title, TextSize = 16, FontFace = GetFont(Weight.Bold), Size = UDim2.fromOffset(0, 19), AutomaticSize = AutoX, LayoutOrder = 1, Parent = titleBlock})
    local titleShine = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.45, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.55, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
        }),
        Offset = Vector2.new(-1, 0),
        Parent = titleLabel,
    })
    OnTheme(function(theme)
        local keys = titleShine.Color.Keypoints
        titleShine.Color = ColorSequence.new({keys[1], keys[2], ColorSequenceKeypoint.new(0.5, theme.Accent:Lerp(Color3.new(1, 1, 1), 0.45)), keys[4], keys[5]})
    end)
    if not DX.IsMobile then
        TweenService:Create(titleShine, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 2.5), {Offset = Vector2.new(1, 0)}):Play()
    end
    local authorLabel = Text({Name = "Author", Text = config.Author or "", TextSize = 12, Theme = {TextColor3 = "SubText"}, Size = UDim2.fromOffset(0, 15), AutomaticSize = AutoX, LayoutOrder = 2, Visible = (config.Author or "") ~= "", Parent = titleBlock})
    local tags = New("Frame", {Name = "Tags", Size = UDim2.fromOffset(0, 24), AutomaticSize = AutoX, BackgroundTransparency = 1, LayoutOrder = 3, Parent = titleRow}, {List(6, Horizontal, nil, Enum.VerticalAlignment.Center)})

    local controls = New("Frame", {Name = "Controls", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(0, 30), AutomaticSize = AutoX, BackgroundTransparency = 1, Parent = topbar}, {List(6, Horizontal, nil, Enum.VerticalAlignment.Center)})
    local function controlButton(iconName, order, hoverKey)
        local stroke = Stroke("Stroke")
        local button = New("TextButton", {Name = iconName, Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(30, 30), Theme = {BackgroundColor3 = "Element"}, LayoutOrder = order, Parent = controls}, {Corner(8), stroke})
        local image = Icon(iconName, 15, "SubText", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = button})
        button.MouseEnter:Connect(function()
            Retheme(button, "BackgroundColor3", hoverKey or "ElementHover", 0.2)
            Retheme(stroke, "Color", hoverKey or "Accent", 0.2)
        end)
        button.MouseLeave:Connect(function()
            Retheme(button, "BackgroundColor3", "Element", 0.2)
            Retheme(stroke, "Color", "Stroke", 0.2)
        end)
        return button, image
    end
    local minimizeButton = controlButton("minus", 1)
    local closeButton = controlButton("x", 2, "Error")

    local body = New("Frame", {Name = "Body", Position = UDim2.fromOffset(0, topHeight), Size = UDim2.new(1, 0, 1, -topHeight), BackgroundTransparency = 1, Parent = main})
    local sidebar = New("Frame", {Name = "Sidebar", Size = UDim2.new(0, sideWidth, 1, 0), BackgroundTransparency = 1, Parent = body})
    New("Frame", {Name = "Line", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, Parent = sidebar})

    local listTop = 10
    local searchButton
    if not config.HideSearchBar then
        searchButton = New("TextButton", {
            Name = "Search",
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -24, 0, 34),
            Theme = {BackgroundColor3 = "Field"},
            Parent = sidebar,
        }, {Corner(9), Stroke("Stroke", 0.35)})
        Icon("search", 15, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Parent = searchButton})
        Text({Text = "Search", TextSize = 13, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -44, 1, 0), Theme = {TextColor3 = "SubText"}, Parent = searchButton})
        listTop = 56
    end

    local showUser = config.User ~= false and not (type(config.User) == "table" and config.User.Enabled == false)
    local userHeight = showUser and 62 or 0
    local tabList = New("ScrollingFrame", {Name = "Tabs", 
        Position = UDim2.fromOffset(0, listTop),
        Size = UDim2.new(1, 0, 1, -(listTop + userHeight)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = AutoY,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar,
    }, {Padding(12, 12, 5, 12), List(4)})

    function Window:SetUserBlur() end
    if showUser then
        local userConfig = type(config.User) == "table" and config.User or {}
        local card = New("TextButton", {Name = "User", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 44), Theme = {BackgroundColor3 = "Element"}, Parent = sidebar}, {Corner(10), Stroke("Stroke", 0.4)})
        local anonymous = userConfig.Anonymous == true
        local private = not anonymous
        local textWidth = private and -76 or -54
        local avatar = New("ImageLabel", {Name = "Avatar", Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(30, 30), Theme = {BackgroundColor3 = "Field"}, Image = anonymous and "" or ("rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"), Parent = card}, {Corner(Round)})
        local avatarStroke = Stroke("Accent", 0.3, 1.5)
        avatarStroke.Parent = avatar
        local nameLabel = Text({Name = "DisplayName", Text = anonymous and "Anonymous" or LocalPlayer.DisplayName, TextSize = 13, FontFace = GetFont(Weight.SemiBold), Position = UDim2.fromOffset(46, 6), Size = UDim2.new(1, textWidth, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
        local userLabel = Text({Name = "Username", Text = anonymous and "@hidden" or ("@" .. LocalPlayer.Name), TextSize = 11, Theme = {TextColor3 = "SubText"}, Position = UDim2.fromOffset(46, 23), Size = UDim2.new(1, textWidth, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
        local frost
        card.MouseEnter:Connect(function()
            Retheme(card, "BackgroundColor3", "ElementHover", 0.2)
            if frost then Retheme(frost, "BackgroundColor3", "ElementHover", 0.2) end
        end)
        card.MouseLeave:Connect(function()
            Retheme(card, "BackgroundColor3", "Element", 0.2)
            if frost then Retheme(frost, "BackgroundColor3", "Element", 0.2) end
        end)
        if private then
            frost = New("Frame", {Name = "Frost", Size = UDim2.fromScale(1, 1), Theme = {BackgroundColor3 = "Element"}, BackgroundTransparency = 1, ZIndex = 3, Parent = card}, {Corner(10)})
            New("UIGradient", {Rotation = 20, Transparency = NumberSequence.new(0, 0.3), Parent = frost})
            local eye = Icon("eye-off", 14, "SubText", {Name = "Privacy", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), ZIndex = 4, Parent = card})
            local ghosts = {}
            local function scramble(value)
                return (value:gsub("[%w_]", function() return string.char(96 + math.random(1, 26)) end))
            end
            local function addGhosts(source, kind)
                local own = {}
                source:GetPropertyChangedSignal("Size"):Connect(function()
                    for _, ghost in ipairs(own) do ghost.Size = source.Size end
                end)
                for ring = 1, 2 do
                    for index = 0, 7 do
                        local angle = index * math.pi / 4 + ring * 0.4
                        local ghost
                        if kind == "Image" then
                            ghost = New("ImageLabel", {Name = "Ghost", Image = source.Image, BackgroundTransparency = 1, Size = source.Size, Position = source.Position, ImageTransparency = 1, Parent = card}, {Corner(Round)})
                        else
                            ghost = Text({Name = "Ghost", Text = scramble(source.Text), TextSize = source.TextSize, FontFace = source.FontFace, Theme = {TextColor3 = kind}, Size = source.Size, Position = source.Position, TextTruncate = Enum.TextTruncate.AtEnd, TextTransparency = 1, Parent = card})
                        end
                        table.insert(own, ghost)
                        table.insert(ghosts, {ghost, source.Position, Vector2.new(math.cos(angle), math.sin(angle)) * 3.5 * ring, kind == "Image" and "ImageTransparency" or "TextTransparency"})
                    end
                end
            end
            addGhosts(avatar, "Image")
            addGhosts(nameLabel, "Text")
            addGhosts(userLabel, "SubText")
            function Window:SetUserBlur(state, instant)
                Window.UserBlurred = state ~= false
                local on = Window.UserBlurred
                local time = instant and 0 or 0.35
                for _, ghost in ipairs(ghosts) do
                    local spread = on and ghost[3] or ghost[3] * 0.3
                    Tween(ghost[1], time, {[ghost[4]] = on and 0.86 or 1, Position = ghost[2] + UDim2.fromOffset(spread.X, spread.Y)})
                end
                Tween(nameLabel, time, {TextTransparency = on and 1 or 0})
                Tween(userLabel, time, {TextTransparency = on and 1 or 0})
                Tween(avatar, time, {ImageTransparency = on and 1 or 0})
                Tween(avatarStroke, time, {Transparency = on and 1 or 0.3})
                Tween(frost, time, {BackgroundTransparency = on and 0.3 or 1})
                if eye then eye.Image = DX:GetIcon(on and "eye-off" or "eye") or eye.Image end
            end
            Window:SetUserBlur(userConfig.Blur ~= false, true)
        end
        card.Activated:Connect(function()
            if private then Window:SetUserBlur(not Window.UserBlurred) end
            SafeCall(userConfig.Callback, Window.UserBlurred)
        end)
    end

    local content = New("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(sideWidth + 6, 6),
        Size = UDim2.new(1, -(sideWidth + 12), 1, -12),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = body,
    })
    Frost(content, 13, 0.86)
    local pageFader = not DX.IsMobile and New("CanvasGroup", {Name = "PageFader", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = content})

    local function setTabVisual(tab, active, animate)
        local time = animate and 0.25 or 0
        Tween(tab.TabButton, time, {BackgroundTransparency = active and (DX.Glass and 0.37 or 0) or (DX.Glass and 0.84 or 1)})
        Tween(tab.Indicator, animate and 0.22 or 0, {Size = UDim2.fromOffset(3, active and 18 or 0)})
        Retheme(tab.TitleLabel, "TextColor3", active and "Text" or "SubText", time)
    end

    function Window:SelectTab(tab)
        if type(tab) == "number" then tab = Window.Tabs[tab] end
        if not tab or Window.Selected == tab then return end
        local previous = Window.Selected
        Window.Selected = tab
        if previous then
            setTabVisual(previous, false, true)
            previous.Page.Visible = false
        end
        setTabVisual(tab, true, previous ~= nil)
        tab.Page.Visible = true
        if not previous or not Window.Opened then return end
        local direction = tab.TabButton.LayoutOrder > previous.TabButton.LayoutOrder and 1 or -1
        if pageFader then
            pageFader.GroupTransparency = 1
            FadeThrough(pageFader, tab.Page, content, 0.28, 0, UDim2.fromOffset(direction * 14, 0))
        else
            tab.Page.Position = UDim2.fromOffset(direction * 8, 0)
            Tween(tab.Page, 0.18, {Position = UDim2.fromOffset(0, 0)})
        end
    end

    local function createTab(tabConfig, container, group)
        tabConfig = tabConfig or {}
        local Tab = setmetatable({Title = tabConfig.Title or tabConfig.Name or "Tab", Window = Window, Group = group, Keywords = {}}, {__index = Elements})
        Tab.Tab = Tab
        Tab.IconName = tabConfig.Icon or tabConfig.Image
        Tab.Locked = tabConfig.Locked == true
        local button = New("TextButton", {Name = Tab.Title, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36), Theme = {BackgroundColor3 = "Element"}, BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = container}, {Corner(9)})
        local indicator = New("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = button}, {Corner(Round)})
        Bind(indicator, "BackgroundColor3", "Accent")
        local icon = Icon(tabConfig.Icon or tabConfig.Image, 17, "SubText", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 22, 0.5, 0), Parent = button})
        local labelX = 39
        local label = Text({Text = Tab.Title, TextSize = 14, FontFace = GetFont(Weight.Medium), Theme = {TextColor3 = "SubText"}, Position = UDim2.fromOffset(labelX, 0), Size = UDim2.new(1, -(labelX + 8), 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = button})
        local lockIcon = Icon("lock", 14, "SubText", {Name = "Lock", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Visible = Tab.Locked, Parent = button})
        local function applyLock()
            if lockIcon then lockIcon.Visible = Tab.Locked end
            label.TextTransparency = Tab.Locked and 0.5 or 0
            if icon then icon.ImageTransparency = Tab.Locked and 0.5 or 0 end
        end
        applyLock()
        local page = New("Frame", {Name = "[Tab] " .. Tab.Title, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content})
        Frost(button, 9, 0.94)
        local scroll = New("ScrollingFrame", {Name = "Container", 
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = config.ScrollBarEnabled == true and 3 or 0,
            Theme = {ScrollBarImageColor3 = "Stroke"},
            AutomaticCanvasSize = AutoY,
            CanvasSize = UDim2.new(),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = page,
        }, {Padding(18, 18, 16, 18), List(10)})
        if tabConfig.ShowTitle ~= false then
            local head = New("Frame", {Name = "Heading", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = 0, Parent = scroll}, {List(2), Padding(2, 0, 0, 6)})
            Text({Text = Tab.Title, TextSize = 22, FontFace = GetFont(Weight.Bold), Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1, Parent = head})
            if tabConfig.Desc then
                Text({Text = tabConfig.Desc, TextSize = 13, Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, LayoutOrder = 2, Parent = head})
            end
        end
        Tab.TabButton, Tab.Indicator, Tab.IconImage, Tab.TitleLabel, Tab.Page, Tab.Container = button, indicator, icon, label, page, scroll
        OnGlass(function()
            setTabVisual(Tab, Window.Selected == Tab, false)
        end, button)
        button.MouseEnter:Connect(function()
            if Window.Selected ~= Tab then Tween(button, 0.15, {BackgroundTransparency = DX.Glass and 0.63 or 0.5}) end
        end)
        button.MouseLeave:Connect(function()
            if Window.Selected ~= Tab then Tween(button, 0.15, {BackgroundTransparency = DX.Glass and 0.84 or 1}) end
        end)
        button.Activated:Connect(function()
            if Tab.Locked then return end
            Window:SelectTab(Tab)
        end)
        function Tab:Select() if not Tab.Locked then Window:SelectTab(Tab) end end
        function Tab:Lock() Tab.Locked = true applyLock() end
        function Tab:Unlock() Tab.Locked = false applyLock() end
        function Tab:SetTitle(value) Tab.Title = value label.Text = value end
        function Tab:Destroy()
            button:Destroy()
            page:Destroy()
            local index = table.find(Window.Tabs, Tab)
            if index then table.remove(Window.Tabs, index) end
        end
        table.insert(Window.Tabs, Tab)
        if group then table.insert(group.Tabs, Tab) end
        if not Window.Selected and not Tab.Locked then Window:SelectTab(Tab) end
        return Tab
    end

    function Window:Tab(tabConfig)
        return createTab(tabConfig, tabList, nil)
    end

    function Window:Divider()
        local line = New("Frame", {Name = "[Divider]", Size = UDim2.new(1, -12, 0, 1), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = tabList})
        return {Destroy = function() line:Destroy() end}
    end

    function Window:Space(height)
        if type(height) == "table" then height = height.Size or height.Height end
        local space = New("Frame", {Name = "[Space]", Size = UDim2.new(1, 0, 0, height or 8), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = tabList})
        return {Destroy = function() space:Destroy() end}
    end

    function Window:Section(sectionConfig)
        sectionConfig = sectionConfig or {}
        local Group = {Title = sectionConfig.Title or "Section", Opened = sectionConfig.Opened ~= false, Tabs = {}, Forced = false}
        local frame = New("Frame", {Name = "[Group] " .. Group.Title, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = tabList}, {List(2)})
        local header = New("TextButton", {Name = "Header", Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame})
        local left = 6
        if sectionConfig.Icon and DX:GetIcon(sectionConfig.Icon) then
            Icon(sectionConfig.Icon, 14, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Parent = header})
            left = 28
        end
        Text({Text = Group.Title:upper(), TextSize = 11, FontFace = GetFont(Weight.Bold), Theme = {TextColor3 = "SubText"}, Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -(left + 24), 1, 0), Parent = header})
        local chevron = Icon("chevron-down", 14, "SubText", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Parent = header})
        New("Frame", {Name = "SectionLine", Position = UDim2.new(0, 6, 1, -2), Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = Color3.fromRGB(244, 248, 255), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = header})
        local groupHolder = New("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 2, Parent = frame})
        local inner = New("Frame", {Name = "Tabs", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = groupHolder}, {List(4), Padding(1, 1, 2, 2)})
        local animating = false
        local function apply(animate)
            local open = Group.Opened or Group.Forced
            if animate then
                animating = true
                ExpandTo(groupHolder, inner, open, 0.35)
                task.delay(0.36, function() animating = false end)
            else
                groupHolder.Size = UDim2.new(1, 0, 0, open and inner.AbsoluteSize.Y / ScaleOf(inner) or 0)
            end
            if chevron then Tween(chevron, 0.3, {Rotation = open and 0 or -90}) end
        end
        Group.Apply = apply
        inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if not animating then apply(false) end
        end)
        header.Activated:Connect(function()
            Group.Opened = not Group.Opened
            apply(true)
        end)
        function Group:Tab(tabConfig)
            return createTab(tabConfig, inner, Group)
        end
        function Group:Open() Group.Opened = true apply(true) end
        function Group:Close() Group.Opened = false apply(true) end
        apply(false)
        table.insert(Window.Groups, Group)
        return Group
    end
    Window.TabGroup = Window.Section

    local searchOverlay, searchBox, moveSearchSelection
    if searchButton then
        searchOverlay = New("Frame", {Name = "SearchOverlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60, Visible = false, Parent = gui})
        local scrim = New("TextButton", {Name = "Dismiss", Text = "", AutoButtonColor = false, Modal = true, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.44, Parent = searchOverlay})
        local panel = New("Frame", {
            Name = "SearchPanel",
            Active = true,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0.92, 0, 0.67, 0),
            Theme = {BackgroundColor3 = "Background"},
            Parent = searchOverlay,
        }, {Corner(18), Stroke("Stroke", 0.25), New("UISizeConstraint", {MaxSize = Vector2.new(440, 360)})})
        GlassTargets[panel] = {0, 0.10}
        panel.BackgroundTransparency = DX.Glass and 0.10 or 0
        Frost(panel, 18, 0.88)
        local field = New("Frame", {Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 42), Theme = {BackgroundColor3 = "Field"}, Parent = panel}, {Corner(12), Stroke("Stroke", 0.35)})
        Icon("search", 17, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Parent = field})
        searchBox = New("TextBox", {Name = "Query", Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -76, 1, 0), Text = "", PlaceholderText = "Search tabs and controls", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextSize = 14, FontFace = GetFont(), Theme = {TextColor3 = "Text", PlaceholderColor3 = "SubText"}, Parent = field})
        local dismiss = New("TextButton", {Name = "CloseSearch", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, Parent = field})
        Icon("x", 16, "SubText", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = dismiss})
        local results = New("ScrollingFrame", {Name = "SearchResults", Position = UDim2.fromOffset(12, 62), Size = UDim2.new(1, -24, 1, -74), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, Theme = {ScrollBarImageColor3 = "Stroke"}, CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = panel}, {List(4)})
        local rows = {}
        local selected = 0
        local function selectRow(index, reveal)
            if #rows == 0 then return end
            selected = math.clamp(index, 1, #rows)
            for i, row in ipairs(rows) do
                row.Button.BackgroundTransparency = i == selected and 0.25 or 1
            end
            if reveal then
                local row = rows[selected].Button
                local offset = row.AbsolutePosition.Y - results.AbsolutePosition.Y
                if offset < 0 or offset + row.AbsoluteSize.Y > results.AbsoluteSize.Y then
                    results.CanvasPosition = Vector2.new(0, math.max(0, results.CanvasPosition.Y + offset))
                end
            end
        end
        moveSearchSelection = function(delta) selectRow(selected + delta, true) end
        local function choose(tab, element)
            if tab.Locked or not tab.Page.Parent then return end
            Window:CloseSearch()
            if tab.Group then tab.Group:Open() end
            if element and element.Section then element.Section:Open() end
            tab:Select()
            if element then
                task.delay(0.43, function()
                    if Window.Destroyed or Window.Selected ~= tab or not element.Card.Parent then return end
                    local list = tab.Container
                    local offset = (element.Card.AbsolutePosition.Y - list.AbsolutePosition.Y) / ScaleOf(list)
                    local limit = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
                    list.CanvasPosition = Vector2.new(0, math.clamp(list.CanvasPosition.Y + offset - 10, 0, limit))
                    FlashActivation(element.Card)
                end)
            end
        end
        local function refresh()
            for _, child in ipairs(results:GetChildren()) do
                if child:IsA("GuiObject") then child:Destroy() end
            end
            table.clear(rows)
            selected = 0
            results.CanvasPosition = Vector2.zero
            local query = searchBox.Text:lower():match("^%s*(.-)%s*$")
            local function match(value)
                return tostring(value or ""):lower():find(query, 1, true) ~= nil
            end
            local function add(tab, element)
                if #rows >= 60 then return end
                local index = #rows + 1
                local row = New("TextButton", {Name = "Result", Text = "", AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 40), Theme = {BackgroundColor3 = "ElementHover"}, BackgroundTransparency = 1, LayoutOrder = index, Parent = results}, {Corner(9)})
                Icon(element and "sliders-horizontal" or tab.IconName or "layers", 16, "Accent", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 19, 0.5, 0), Parent = row})
                local label = element and (element.Title .. "  ·  " .. tab.Title) or tab.Title
                Text({Text = label, TextSize = 13, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -47, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
                rows[index] = {Button = row, Choose = function() choose(tab, element) end}
                row.MouseEnter:Connect(function() selectRow(index, false) end)
                row.Activated:Connect(rows[index].Choose)
            end
            for _, tab in ipairs(Window.Tabs) do
                if not tab.Locked and match(tab.Title) then add(tab) end
            end
            if query ~= "" then
                for _, element in ipairs(Window.Elements) do
                    local tab = element.Tab
                    if tab and tab.Page.Parent and not tab.Locked and element.Card and element.Card.Parent and element.Card.Visible
                        and (match(element.Title) or match(element.Desc) or match(element.Type)) then
                        add(tab, element)
                    end
                end
            end
            if #rows == 0 then
                Text({Text = "No results", TextSize = 13, Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, Theme = {TextColor3 = "SubText"}, Parent = results})
            else
                selectRow(1, false)
            end
        end
        function Window:CloseSearch()
            searchOverlay.Visible = false
            searchBox:ReleaseFocus()
        end
        function Window:OpenSearch(query)
            if self.Destroyed or not self.Opened then return end
            local topbarHeight = GuiService:GetGuiInset().Y
            scrim.Position = UDim2.fromOffset(0, topbarHeight)
            scrim.Size = UDim2.new(1, 0, 1, -topbarHeight)
            searchOverlay.Visible = true
            searchBox.Text = type(query) == "string" and query or ""
            refresh()
            searchBox:CaptureFocus()
        end
        searchButton.Activated:Connect(function() Window:OpenSearch() end)
        scrim.Activated:Connect(function() Window:CloseSearch() end)
        dismiss.Activated:Connect(function() Window:CloseSearch() end)
        searchBox:GetPropertyChangedSignal("Text"):Connect(refresh)
        searchBox.FocusLost:Connect(function(enter)
            if enter and searchOverlay.Visible and rows[selected] then rows[selected].Choose() end
        end)
    end

    function Window:Tag(tagConfig)
        tagConfig = tagConfig or {}
        local color = tagConfig.Color or CurrentTheme().Accent
        local tag = New("Frame", {Name = "[Tag] " .. tostring(tagConfig.Title or "Tag"), Size = UDim2.fromOffset(0, 22), AutomaticSize = AutoX, BackgroundColor3 = color, BackgroundTransparency = 0.82, LayoutOrder = NextOrder(), Parent = tags}, {
            Corner(tagConfig.Radius or 11),
            Padding(9, 9, 0, 0),
            List(5, Horizontal, nil, Enum.VerticalAlignment.Center),
            New("UIStroke", {Color = color, Transparency = 0.55}),
        })
        local tagIcon = Icon(tagConfig.Icon, 12, nil, {LayoutOrder = 1, Parent = tag})
        local label = Text({Text = tagConfig.Title or "Tag", TextSize = 12, FontFace = GetFont(Weight.SemiBold), Theme = {}, TextColor3 = color, Size = UDim2.fromOffset(0, 22), AutomaticSize = AutoX, LayoutOrder = 2, Parent = tag})
        local scaleIn = New("UIScale", {Scale = 0.6, Parent = tag})
        Tween(scaleIn, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
        local Tag = {}
        function Tag:SetTitle(value) label.Text = value end
        function Tag:SetColor(value)
            tag.BackgroundColor3 = value
            label.TextColor3 = value
        end
        function Tag:Destroy() tag:Destroy() end
        return Tag
    end

    function Window:SetTitle(value) Window.Title = value titleLabel.Text = value end
    function Window:SetAuthor(value) authorLabel.Text = value authorLabel.Visible = value ~= "" end
    Window.UpdateTitle = Window.SetTitle
    Window.UpdateSubtitle = Window.SetAuthor

    function Window:SetBackground(image, transparency)
        if transparency then backdropTransparency = transparency end
        local resolved = image and image ~= "" and DX:GetIcon(image) or nil
        backdrop.Visible = resolved ~= nil
        backdrop.Image = resolved or ""
        backdrop.ImageTransparency = 1
        if resolved then Tween(backdrop, 0.5, {ImageTransparency = backdropTransparency}) end
    end
    function Window:SetBackgroundTransparency(value)
        backdropTransparency = value
        if backdrop.Visible then Tween(backdrop, 0.25, {ImageTransparency = value}) end
    end
    if config.Background then Window:SetBackground(config.Background) end

    local openGui = ScreenGui("DX-UI-Open", 2147483647)
    local openY = 14
    local openButton = New("TextButton", {Name = "OpenButton", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -70), Size = UDim2.fromOffset(0, 42), AutomaticSize = AutoX, Theme = {BackgroundColor3 = "Background"}, Visible = false, Parent = openGui}, {
        Corner(Round),
        Padding(10, 18, 0, 0),
        List(10, Horizontal, nil, Enum.VerticalAlignment.Center),
    })
    local openStroke = New("UIStroke", {Thickness = 1.5, Color = Color3.new(1, 1, 1), Parent = openButton})
    TweenService:Create(AccentGradient(openStroke, 0), TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    local openIconHolder = New("Frame", {Name = "Icon", Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, LayoutOrder = 1, Parent = openButton})
    local openIcon = Icon(config.OpenIcon or 118992150433803, 24, nil, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = openIconHolder})
    local openTitle = Text({Text = config.OpenTitle or Window.Title, TextSize = 14, FontFace = GetFont(Weight.SemiBold), Size = UDim2.fromOffset(0, 42), AutomaticSize = AutoX, LayoutOrder = 2, Parent = openButton})
    local openPointer, openStart, openOrigin, openDragged
    openButton.InputBegan:Connect(function(input)
        if not IsPress(input) then return end
        openPointer, openStart, openOrigin, openDragged = input, PointerPosition(input), openButton.Position, false
    end)
    table.insert(Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if not MovesPointer(openPointer, input) then return end
        local delta = PointerPosition(input) - openStart
        if not openDragged and delta.Magnitude < 6 then return end
        openDragged = true
        openButton.Position = UDim2.new(openOrigin.X.Scale, openOrigin.X.Offset + delta.X, 0, openOrigin.Y.Offset + delta.Y)
        openY = openButton.Position.Y.Offset
    end))
    table.insert(Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if not EndsPointer(openPointer, input) then return end
        openPointer = nil
        if not openDragged then Window:Open() end
    end))

    local function fire(list, ...)
        for _, callback in ipairs(list) do SafeCall(callback, ...) end
    end

    local slideTween
    local slideDistance = DX.IsMobile and 10 or 20
    function Window:Open()
        if Window.Opened or Window.Destroyed then return end
        if slideTween then slideTween:Cancel() end
        Window.Opened = true
        if not holder.Visible then motion.Position = UDim2.fromOffset(0, slideDistance) end
        holder.Visible = true
        local duration = DX.IsMobile and 0.20 or 0.32
        slideTween = Tween(motion, duration, {Position = UDim2.fromOffset(0, 0)})
        if canvas then FadeThrough(canvas, main, motion, duration, 0) end
        openButton.Visible = false
        SyncGlassBlur()
        fire(Window.Events.Open)
    end

    function Window:Close()
        if not Window.Opened then return end
        if slideTween then slideTween:Cancel() end
        Window.Opened = false
        if Window.CloseSearch then Window:CloseSearch() end
        local duration = DX.IsMobile and 0.17 or 0.23
        local closing = Tween(motion, duration, {Position = UDim2.fromOffset(0, slideDistance)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        slideTween = closing
        if canvas then FadeThrough(canvas, main, motion, duration, 1) end
        closing.Completed:Once(function(state)
            if state == Enum.PlaybackState.Completed and slideTween == closing and not Window.Opened then
                holder.Visible = false
            end
        end)
        if not Window.Destroyed and Window.OpenButtonEnabled ~= false then
            openButton.Position = UDim2.new(openButton.Position.X.Scale, openButton.Position.X.Offset, 0, -70)
            openButton.Visible = true
            Tween(openButton, 0.45, {Position = UDim2.new(openButton.Position.X.Scale, openButton.Position.X.Offset, 0, openY)}, Enum.EasingStyle.Back)
        end
        SyncGlassBlur()
        fire(Window.Events.Close)
    end

    function Window:Toggle()
        if Window.Opened then Window:Close() else Window:Open() end
    end
    Window.SetState = function(_, state) if state then Window:Open() else Window:Close() end end
    Window.GetState = function() return Window.Opened end

    function Window:OnOpen(callback) table.insert(Window.Events.Open, callback) end
    function Window:OnClose(callback) table.insert(Window.Events.Close, callback) end
    function Window:OnDestroy(callback) table.insert(Window.Events.Destroy, callback) end
    Window.onUnloaded = Window.OnDestroy

    function Window:SetToggleKey(key)
        if key == nil or key == false or key == "None" then
            key = nil
        elseif type(key) == "string" then
            local ok, value = pcall(function() return Enum.KeyCode[key] end)
            if not ok or not value then return false end
            key = value
        end
        if key and (typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode or key == Enum.KeyCode.Unknown) then
            return false
        end
        if self.ToggleKey ~= key then
            self.ToggleKey = key
            fire(self.Events.ToggleKeyChanged, key)
        end
        return true
    end
    function Window:GetToggleKey() return self.ToggleKey end
    function Window:OnToggleKeyChanged(callback) table.insert(self.Events.ToggleKeyChanged, callback) end
    Window.SetKeybind = Window.SetToggleKey
    Window.GetKeybind = Window.GetToggleKey


    function Window:Destroy()
        if Window.Destroyed then return end
        Window.Destroyed = true
        Window:Close()
        openGui:Destroy()
        for _, connection in ipairs(Window.Connections) do pcall(function() connection:Disconnect() end) end
        if Window.CursorCleanup then Window.CursorCleanup() end
        for flag, element in pairs(DX.Flags) do
            if element.Window == Window then DX.Flags[flag] = nil end
        end
        local index = table.find(DX.Windows, Window)
        if index then table.remove(DX.Windows, index) end
        SyncGlassBlur()
        fire(Window.Events.Destroy)
        task.delay(0.3, function() gui:Destroy() end)
    end
    Window.Unload = Window.Destroy

    function Window:Dialog(dialogConfig)
        return CreateDialog(gui, dialogConfig)
    end

    function Window:Notify(notifyConfig)
        return DX:Notify(notifyConfig)
    end

    function Window:LockAll() for _, element in ipairs(Window.Elements) do if element.Lock then element:Lock() end end end
    function Window:UnlockAll() for _, element in ipairs(Window.Elements) do if element.Unlock then element:Unlock() end end end

    minimizeButton.Activated:Connect(function() Window:Close() end)
    closeButton.Activated:Connect(function()
        Window:Dialog({
            Title = "Close " .. Window.Title,
            Icon = "triangle-alert",
            Content = "Are you sure you want to close the interface? You will need to execute the script again to open it.",
            Buttons = {
                {Title = "Cancel", Variant = "Secondary"},
                {Title = "Close", Variant = "Primary", Icon = "x", Callback = function() Window:Destroy() end},
            },
        })
    end)

    local bottomHandle = New("TextButton", {
        Name = "BottomDragHandle",
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(176, DX.IsMobile and 24 or 16),
        PressFeedback = false,
        BackgroundTransparency = 1,
        ZIndex = 24,
        Parent = motion,
    })
    local dragLine = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 6),
        Size = UDim2.fromOffset(160, 4),
        BackgroundTransparency = 0.64,
        Theme = {BackgroundColor3 = "Text"},
        ZIndex = 24,
        Parent = bottomHandle,
    }, {Corner(Round)})
    bottomHandle.MouseEnter:Connect(function() Tween(dragLine, 0.13, {BackgroundTransparency = 0.35}) end)
    bottomHandle.MouseLeave:Connect(function() Tween(dragLine, 0.16, {BackgroundTransparency = 0.64}) end)
    Draggable({topbar, bottomHandle}, holder, Window, function(handle, dragging)
        if handle == bottomHandle or not dragging then
            Tween(dragLine, 0.15, {BackgroundTransparency = dragging and 0.20 or 0.64})
        end
    end)

    if config.Resizable ~= false then
        local hitSize = DX.IsMobile and 42 or 32
        local grip = New("TextButton", {
            Name = "ResizeBottomRight",
            Text = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(hitSize, hitSize),
            BackgroundTransparency = 1,
            PressFeedback = false,
            Active = true,
            ZIndex = 23,
            Parent = motion,
        })
        local curve = New("ImageLabel", {
            Name = "OutsideCurve",
            Image = "rbxassetid://120997033468887",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, -16, 0.5, -16),
            Size = UDim2.fromOffset(96, 96),
            BackgroundTransparency = 1,
            ImageTransparency = 0.76,
            ZIndex = 23,
            Parent = grip,
        })
        local pointer, startPointer, startSize, startScale, limit, motion
        grip.MouseEnter:Connect(function() Tween(curve, 0.12, {ImageTransparency = 0.42}) end)
        grip.MouseLeave:Connect(function()
            if not pointer then Tween(curve, 0.16, {ImageTransparency = 0.76}) end
        end)
        grip.InputBegan:Connect(function(input)
            if Window.WindowPointer or not Window.Opened or not IsPress(input) then return end
            if motion then motion:Cancel() end
            pointer = input
            Window.WindowPointer = input
            startPointer = PointerPosition(input)
            startSize = Vector2.new(holder.Size.X.Offset, holder.Size.Y.Offset)
            startScale = scale.Scale
            local center = holder.AbsolutePosition + holder.AbsoluteSize / 2
            local bounds = gui.AbsoluteSize
            limit = Vector2.new(
                math.max(startSize.X, math.min(maxSize.X, 2 * math.min(center.X - 12, bounds.X - center.X - 16) / startScale)),
                math.max(startSize.Y, math.min(maxSize.Y, 2 * math.min(center.Y - 12, bounds.Y - center.Y - 26) / startScale))
            )
            Tween(curve, 0.1, {ImageTransparency = 0.24})
        end)
        table.insert(Window.Connections, UserInputService.InputChanged:Connect(function(input)
            if not Window.Opened or not MovesPointer(pointer, input) then return end
            local delta = (PointerPosition(input) - startPointer) * 2 / startScale
            local width = math.clamp(startSize.X + delta.X, math.min(minSize.X, limit.X), limit.X)
            local height = math.clamp(startSize.Y + delta.Y, math.min(minSize.Y, limit.Y), limit.Y)
            motion = Tween(holder, 0.08, {Size = UDim2.fromOffset(width, height)}, Enum.EasingStyle.Quad)
        end))
        table.insert(Window.Connections, UserInputService.InputEnded:Connect(function(input)
            if not EndsPointer(pointer, input) then return end
            pointer = nil
            Window.WindowPointer = nil
            Tween(curve, 0.16, {ImageTransparency = 0.76})
        end))
    end

    table.insert(Window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if Window.Destroyed then return end
        if searchOverlay and searchOverlay.Visible then
            if input.KeyCode == Enum.KeyCode.Escape then Window:CloseSearch() end
            if input.KeyCode == Enum.KeyCode.Up then moveSearchSelection(-1) end
            if input.KeyCode == Enum.KeyCode.Down then moveSearchSelection(1) end
            return
        end
        if processed or Window.Rebinding or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Window.ToggleKey then Window:Toggle() end
    end))

    function Window:SetScale(value)
        config.Scale = value
        Window.Scale = FitScale(holder.Size)
        if Window.Opened then Tween(scale, 0.3, {Scale = Window.Scale}) end
    end
    function Window:SetGlass(state) DX:SetGlass(state) end

    function Window:EditOpenButton(options)
        options = options or {}
        if options.Title then openTitle.Text = options.Title end
        if options.Icon then
            local image = DX:GetIcon(options.Icon)
            if image and openIcon then openIcon.Image = image end
        end
        if options.Enabled ~= nil then
            Window.OpenButtonEnabled = options.Enabled ~= false
            if not Window.OpenButtonEnabled then openButton.Visible = false end
        end
    end

    if config.Cursor ~= false and not DX.IsMobile then
        local cursorGui = ScreenGui("DX-UI-Cursor", 2000)
        local shadow = Icon("mouse-pointer-2", 22, nil, {Name = "Shadow", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.4, Visible = false, ZIndex = 1, Parent = cursorGui})
        local pointer = Icon("mouse-pointer-2", 22, nil, {Name = "Pointer", ImageColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 2, Parent = cursorGui})
        local savedIcon
        local function inside(object, point)
            if not object.Visible then return false end
            local position, extent = object.AbsolutePosition, object.AbsoluteSize
            return point.X >= position.X and point.Y >= position.Y and point.X <= position.X + extent.X and point.Y <= position.Y + extent.Y
        end
        local bindName = "DXCursor" .. HttpService:GenerateGUID(false)
        RunService:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value + 2, function()
            local mouse = UserInputService:GetMouseLocation()
            local point = mouse - GuiService:GetGuiInset()
            local hovering = UserInputService.MouseEnabled and (inside(holder, point) or inside(bottomHandle, point) or (searchOverlay and searchOverlay.Visible) or gui:FindFirstChild("Dialog") ~= nil)
            Window.Hovering = hovering
            if hovering then
                if savedIcon == nil then savedIcon = UserInputService.MouseIconEnabled end
                UserInputService.MouseIconEnabled = false
                if pointer then pointer.Position = UDim2.fromOffset(mouse.X - 4, mouse.Y - 4) end
                if shadow then shadow.Position = UDim2.fromOffset(mouse.X - 2.5, mouse.Y - 2.5) end
            elseif savedIcon ~= nil then
                UserInputService.MouseIconEnabled = savedIcon
                savedIcon = nil
            end
            if pointer then pointer.Visible = hovering end
            if shadow then shadow.Visible = hovering end
        end)
        Window.CursorCleanup = function()
            pcall(function() RunService:UnbindFromRenderStep(bindName) end)
            if savedIcon ~= nil then UserInputService.MouseIconEnabled = savedIcon end
            Window.Hovering = false
            cursorGui:Destroy()
        end
    end

    local camera = workspace.CurrentCamera
    if camera then
        table.insert(Window.Connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Window.Scale = FitScale(holder.Size)
            if Window.Opened then Tween(scale, 0.3, {Scale = Window.Scale}) end
        end))
    end

    task.defer(function() Window:Open() end)
    return Window
end

return DX
