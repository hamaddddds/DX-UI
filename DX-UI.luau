local DX = {
    Version = "0.0.0.2",
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
local LocalPlayer = Players.LocalPlayer

DX.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
DX.Glass = false

local FONT_FAMILY = "rbxasset://fonts/families/GothamSSm.json"
local Weight = Enum.FontWeight
local AutoX = Enum.AutomaticSize.X
local AutoY = Enum.AutomaticSize.Y
local Horizontal = Enum.FillDirection.Horizontal
local Round = UDim.new(1, 0)

local function GetFont(weight)
    return Font.new(FONT_FAMILY, weight or Weight.Regular)
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
    SubText = Color3.fromHex("#8193BD"),
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
    Stroke = Color3.fromHex("#2C2350"), SubText = Color3.fromHex("#9A8CC4"), Icon = Color3.fromHex("#B6A9DE"),
})
DX.Themes.Emerald = Variant({
    Accent = Color3.fromHex("#10B981"), Accent2 = Color3.fromHex("#A3E635"),
    Background = Color3.fromHex("#08130F"),
    Element = Color3.fromHex("#0F231B"), ElementHover = Color3.fromHex("#142D23"), Field = Color3.fromHex("#081510"),
    Stroke = Color3.fromHex("#1C3D30"), SubText = Color3.fromHex("#86B5A2"), Icon = Color3.fromHex("#A5D4C0"),
})
DX.Themes.Crimson = Variant({
    Accent = Color3.fromHex("#F43F5E"), Accent2 = Color3.fromHex("#FB923C"),
    Background = Color3.fromHex("#140A0D"),
    Element = Color3.fromHex("#221117"), ElementHover = Color3.fromHex("#2B161D"), Field = Color3.fromHex("#12080B"),
    Stroke = Color3.fromHex("#40202A"), SubText = Color3.fromHex("#C08F9A"), Icon = Color3.fromHex("#DDB0BA"),
})

local Themed = setmetatable({}, {__mode = "k"})
local ThemeHooks = {}

local function CurrentTheme()
    return DX.Themes[DX.Theme] or BaseTheme
end

local function Tween(object, time, properties, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function Bind(object, property, key)
    Themed[object] = Themed[object] or {}
    Themed[object][property] = key
    object[property] = CurrentTheme()[key]
end

local function Retheme(object, property, key, time)
    Themed[object] = Themed[object] or {}
    Themed[object][property] = key
    Tween(object, time or 0.25, {[property] = CurrentTheme()[key]})
end

local function OnTheme(hook)
    table.insert(ThemeHooks, hook)
    hook(CurrentTheme())
end

local GlassLevels = {Background = 0.22, Element = 0.5, Field = 0.4}
local GlassTargets = setmetatable({}, {__mode = "k"})
local GlassHooks = {}

local function OnGlass(hook)
    table.insert(GlassHooks, hook)
    hook(DX.Glass)
end

function DX:SetGlass(state)
    DX.Glass = state and true or false
    for object, levels in pairs(GlassTargets) do
        pcall(Tween, object, 0.35, {BackgroundTransparency = DX.Glass and levels[2] or levels[1]})
    end
    for _, hook in ipairs(GlassHooks) do pcall(hook, DX.Glass) end
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

local function New(className, properties, children)
    local object = Instance.new(className)
    if properties then
        for key, value in pairs(properties) do
            if key == "Theme" then
                for property, themeKey in pairs(value) do Bind(object, property, themeKey) end
            elseif key ~= "Parent" then
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
    if themeKey and IsTintable(name) then properties.Theme = {ImageColor3 = themeKey} end
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

local function IsAutoSized(object)
    if object:IsA("ScrollingFrame") and object.AutomaticCanvasSize ~= Enum.AutomaticSize.None then return true end
    return object.AutomaticSize ~= Enum.AutomaticSize.None
end

local function Ripple(target, radius)
    local host
    local parent = target.Parent
    while parent and parent:IsA("GuiObject") do
        if IsAutoSized(parent) then
            host = nil
        elseif not host and not parent:FindFirstChildWhichIsA("UIGridStyleLayout") and not parent:FindFirstChildWhichIsA("UIPadding") then
            host = parent
        end
        parent = parent.Parent
    end
    if not host then return end
    local ratio = ScaleOf(host)
    local position = PointerPosition()
    local origin = target.AbsolutePosition
    local size = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) * 2.2 / ratio
    local layer = New("CanvasGroup", {
        Name = "Ripple",
        Position = UDim2.fromOffset((origin.X - host.AbsolutePosition.X) / ratio, (origin.Y - host.AbsolutePosition.Y) / ratio),
        Size = UDim2.fromOffset(target.AbsoluteSize.X / ratio, target.AbsoluteSize.Y / ratio),
        BackgroundTransparency = 1,
        ZIndex = 30,
        Parent = host,
    }, {Corner(radius or 10)})
    local circle = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset((position.X - origin.X) / ratio, (position.Y - origin.Y) / ratio),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        Parent = layer,
    }, {Corner(Round)})
    Tween(circle, 0.55, {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
    task.delay(0.6, function() layer:Destroy() end)
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
        if FadeTokens[fader] ~= token or target ~= 0 then return end
        object.Parent = home
        fader.Visible = false
    end)
end

local function Draggable(handle, target, connections, onClick)
    local state = {Dragging = false, Moved = false}
    local startPointer, startPosition
    handle.InputBegan:Connect(function(input)
        if not IsPress(input) then return end
        state.Dragging = true
        state.Moved = false
        startPointer = PointerPosition(input)
        startPosition = target.Position
    end)
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not state.Dragging or not IsMove(input) then return end
        local delta = PointerPosition(input) - startPointer
        if delta.Magnitude > 4 then state.Moved = true end
        if state.Moved then
            Tween(target, 0.14, {Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)}, Enum.EasingStyle.Quad)
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if not state.Dragging or not IsPress(input) then return end
        state.Dragging = false
        if not state.Moved and onClick then onClick() end
    end))
    return state
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
    button.MouseButton1Click:Connect(function()
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

local NotifyHolder
local NotifyTypes = {
    Info = {"info", "Accent"},
    Success = {"circle-check", "Success"},
    Warning = {"triangle-alert", "Warning"},
    Error = {"circle-x", "Error"},
}

local function GetNotifyHolder()
    if NotifyHolder and NotifyHolder.Parent then return NotifyHolder end
    local gui = ScreenGui("DX-UI-Notifications", 1200)
    NotifyHolder = New("Frame", {Name = "Notifications", 
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.new(0, 320, 1, -36),
        BackgroundTransparency = 1,
        Parent = gui,
    }, {List(10, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)})
    return NotifyHolder
end

function DX:Notify(config)
    config = config or {}
    local Notification = {}
    local holder = GetNotifyHolder()
    local kind = NotifyTypes[config.Type or "Info"] or NotifyTypes.Info
    local accent = kind[2]
    local duration = config.Duration or config.Lifetime or 5
    local wrap = New("Frame", {Name = "Notification", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = holder})
    local card = New("Frame", {Name = "Card", 
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = AutoY,
        Position = UDim2.fromOffset(360, 0),
        Theme = {BackgroundColor3 = "Background"},
        Parent = wrap,
    }, {Corner(12), Stroke("Stroke"), Padding(14, 14, 12, 12), List(8)})
    local head = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
    local box = New("Frame", {Size = UDim2.fromOffset(32, 32), Theme = {BackgroundColor3 = accent}, BackgroundTransparency = 0.85, Parent = head}, {Corner(8)})
    Icon(config.Icon or kind[1], 17, accent, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = box})
    local title = Text({Text = config.Title or "DX-SR Hub", TextSize = 15, FontFace = GetFont(Weight.SemiBold), Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -72, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
    local close = New("ImageButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Image = DX:GetIcon("x") or "", Theme = {ImageColor3 = "SubText"}, Parent = head})
    local content = Text({Text = config.Content or config.Description or "", TextSize = 13, Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LayoutOrder = 2, Parent = card})
    content.Visible = content.Text ~= ""
    local track = New("Frame", {Size = UDim2.new(1, 0, 0, 3), Theme = {BackgroundColor3 = "Field"}, LayoutOrder = 3, Parent = card}, {Corner(Round)})
    local fill = New("Frame", {Size = UDim2.fromScale(1, 1), Theme = {BackgroundColor3 = accent}, Parent = track}, {Corner(Round)})
    local closed = false
    function Notification:Close()
        if closed then return end
        closed = true
        Tween(card, 0.35, {Position = UDim2.fromOffset(360, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.3, function()
            Tween(wrap, 0.25, {Size = UDim2.new(1, 0, 0, 0)})
            task.delay(0.26, function() wrap:Destroy() end)
        end)
    end
    Notification.Cancel = Notification.Close
    function Notification:SetTitle(value) title.Text = value end
    function Notification:SetContent(value) content.Text = value content.Visible = value ~= "" end
    Notification.UpdateTitle = Notification.SetTitle
    Notification.UpdateDescription = Notification.SetContent
    close.MouseButton1Click:Connect(function() Notification:Close() end)
    task.defer(function()
        task.wait()
        Tween(wrap, 0.3, {Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y)})
        Tween(card, 0.55, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back)
        Tween(fill, duration, {Size = UDim2.fromScale(0, 1)}, Enum.EasingStyle.Linear)
        task.delay(duration, function() Notification:Close() end)
    end)
    return Notification
end

local Elements = {}

local function RegisterElement(owner, element, config)
    element.Window = owner.Window
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
        Element.IconImage = Icon(config.Icon, 18, "Icon", {Position = UDim2.fromOffset(0, 0), Parent = header})
        left = 30
    end
    local textBlock = New("Frame", {Name = "Text", 
        Position = UDim2.fromOffset(left, 0),
        Size = UDim2.new(1, -(left + rightWidth + (rightWidth > 0 and 14 or 0)), 0, 0),
        AutomaticSize = AutoY,
        BackgroundTransparency = 1,
        Parent = header,
    }, {List(3)})
    local title = Text({Name = "Title", Text = Element.Title, TextSize = 14, FontFace = GetFont(Weight.Medium), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LayoutOrder = 1, Parent = textBlock})
    local desc = Text({Name = "Desc", Text = Element.Desc or "", TextSize = 12, Theme = {TextColor3 = "SubText"}, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, RichText = true, LayoutOrder = 2, Visible = Element.Desc ~= nil and Element.Desc ~= "", Parent = textBlock})
    local right = New("Frame", {Name = "Right", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(rightWidth, 30), BackgroundTransparency = 1, Parent = header})
    card.MouseEnter:Connect(function()
        if not Element.Locked then Retheme(card, "BackgroundColor3", "ElementHover", 0.2) end
    end)
    card.MouseLeave:Connect(function() Retheme(card, "BackgroundColor3", "Element", 0.25) end)
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
    function Element:Lock()
        if lockOverlay then return end
        Element.Locked = true
        lockOverlay = New("TextButton", {Name = "Lock", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), Theme = {BackgroundColor3 = "Background"}, BackgroundTransparency = 1, ZIndex = 40, Parent = card}, {Corner(10)})
        local lockIcon = Icon("lock", 16, "SubText", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), ImageTransparency = 1, ZIndex = 41, Parent = lockOverlay})
        Tween(lockOverlay, 0.25, {BackgroundTransparency = 0.4})
        if lockIcon then Tween(lockIcon, 0.25, {ImageTransparency = 0}) end
    end
    function Element:Unlock()
        if not lockOverlay then return end
        Element.Locked = false
        local overlay = lockOverlay
        lockOverlay = nil
        Tween(overlay, 0.2, {BackgroundTransparency = 1})
        for _, child in ipairs(overlay:GetChildren()) do
            if child:IsA("ImageLabel") then Tween(child, 0.2, {ImageTransparency = 1}) end
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
    header.MouseButton1Click:Connect(function()
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
    Element.Header.MouseButton1Click:Connect(function()
        if Element.Locked then return end
        Ripple(Element.Card)
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
    Element.Header.MouseButton1Click:Connect(function()
        if Element.Locked then return end
        Ripple(Element.Card)
        if arrow then
            Retheme(arrow, "ImageColor3", "Accent", 0.1)
            Tween(arrow, 0.12, {Position = UDim2.new(1, 3, 0.5, 0)})
            task.delay(0.15, function()
                Retheme(arrow, "ImageColor3", "SubText", 0.4)
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
    local holder = New("Frame", {Name = "Slider", Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 2, Parent = Element.Frame}, {Padding(14, 14, 2, 12)})
    local track = New("TextButton", {Name = "Track", Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 6), Theme = {BackgroundColor3 = "Field"}, Parent = holder}, {Corner(Round)})
    local fill = New("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track}, {Corner(Round)})
    AccentGradient(fill, 0)
    local knob = New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = track}, {Corner(Round)})
    local knobStroke = Stroke("Accent", 0, 2)
    knobStroke.Parent = knob
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
    local dragging = false
    local function update(input)
        local position = PointerPosition(input)
        local alpha = math.clamp((position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        Element:Set(min + alpha * (max - min), false, true)
    end
    track.InputBegan:Connect(function(input)
        if Element.Locked or not IsPress(input) then return end
        dragging = true
        Tween(knob, 0.2, {Size = UDim2.fromOffset(20, 20)}, Enum.EasingStyle.Back)
        update(input)
    end)
    table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and IsMove(input) then update(input) end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if dragging and IsPress(input) then
            dragging = false
            Tween(knob, 0.25, {Size = UDim2.fromOffset(14, 14)}, Enum.EasingStyle.Back)
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
    local width = config.DropdownWidth or 170
    local Element = BaseElement(self, config, {RightWidth = width, Button = true})
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
            Tween(row.Frame, animate and 0.2 or 0, {BackgroundTransparency = on and 0.0 or 1})
            if row.Check then Tween(row.Check, animate and 0.25 or 0, {ImageTransparency = on and 0 or 1, Size = on and UDim2.fromOffset(15, 15) or UDim2.fromOffset(8, 8)}, Enum.EasingStyle.Back) end
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
            local row = New("TextButton", {Name = tostring(value), Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 30), Theme = {BackgroundColor3 = "ElementHover"}, BackgroundTransparency = 1, LayoutOrder = index, Parent = scroll}, {Corner(7)})
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
            row.MouseEnter:Connect(function() if not isSelected(value) then Tween(row, 0.15, {BackgroundTransparency = 0.5}) end end)
            row.MouseLeave:Connect(function() if not isSelected(value) then Tween(row, 0.2, {BackgroundTransparency = 1}) end end)
            row.MouseButton1Click:Connect(function() choose(value) end)
            rows[value] = {Frame = row, Label = label, Check = check, BaseX = offset}
        end
        paint(false)
        resize()
    end
    function Element:Open()
        if Element.Opened or Element.Locked then return end
        Element.Opened = true
        Retheme(selectorStroke, "Color", "Accent", 0.2)
        if chevron then Tween(chevron, 0.3, {Rotation = 180}) end
        ExpandTo(holder, inner, true, 0.35)
        local order = 0
        for _, row in pairs(rows) do
            if row.Frame.Visible then
                order += 1
                row.Label.TextTransparency = 1
                row.Label.Position = UDim2.fromOffset(row.BaseX + 10, 0)
                task.delay(math.min(order, 10) * 0.025, function()
                    Tween(row.Label, 0.3, {TextTransparency = 0, Position = UDim2.fromOffset(row.BaseX, 0)})
                end)
            end
        end
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
    Element.Header.MouseButton1Click:Connect(function()
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
    box.MouseButton1Click:Connect(function()
        if Element.Locked or listening then return end
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
    Element.Header.MouseButton1Click:Connect(function()
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
    local copy = New("ImageButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Image = DX:GetIcon("copy") or "", Theme = {ImageColor3 = "SubText"}, Parent = head})
    local code = New("TextLabel", {Text = config.Code or "", TextSize = 13, FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"), Theme = {TextColor3 = "Text"}, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, LayoutOrder = 2, Parent = frame})
    local Element = {Title = config.Title or "Code", CopyCallbacks = {config.OnCopy}}
    copy.MouseButton1Click:Connect(function()
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
        ToggleKey = config.ToggleKey or config.Keybind or Enum.KeyCode.RightShift,
        Tabs = {},
        Groups = {},
        Elements = {},
        Connections = {},
        Events = {Open = {}, Close = {}, Destroy = {}},
        Opened = false,
    }
    Window.Window = Window
    Window.ConfigManager = CreateConfigManager(Window)
    table.insert(DX.Windows, Window)

    local glass = config.Glass
    if glass == nil then glass = config.Transparent end
    if glass ~= nil then DX.Glass = glass == true end
    local minSize = config.MinSize or Vector2.new(520, 340)
    local maxSize = config.MaxSize or Vector2.new(960, 680)
    local size = config.Size or UDim2.fromOffset(660, 460)

    local function FitScale(current)
        if config.Scale then return config.Scale end
        local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        return math.clamp(math.min((view.X - 24) / current.X.Offset, (view.Y - inset.Y - 20) / current.Y.Offset), 0.45, 1)
    end
    Window.Scale = FitScale(size)
    local sideWidth = config.SideBarWidth or 200
    local topHeight = 54

    local gui = ScreenGui("DX-UI", 1000)
    Window.Gui = gui

    local holder = New("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, GuiService:GetGuiInset().Y / 2), Size = size, BackgroundTransparency = 1, Visible = false, Parent = gui})
    local scale = New("UIScale", {Scale = Window.Scale * 0.9, Parent = holder})
    local canvas = New("CanvasGroup", {Name = "Fader", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Parent = holder})
    local main = New("Frame", {Name = "Main", Size = UDim2.fromScale(1, 1), Theme = {BackgroundColor3 = "Background"}, Parent = canvas}, {Corner(14), Stroke("Stroke")})
    local sheen = New("UIGradient", {Rotation = 35, Transparency = NumberSequence.new(0, 0.35), Parent = main})
    OnGlass(function(state) sheen.Enabled = state end)

    local topbar = New("Frame", {Name = "Topbar", Size = UDim2.new(1, 0, 0, topHeight), BackgroundTransparency = 1, ClipsDescendants = true, Parent = main})
    New("Frame", {Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, Parent = topbar})
    local glow = New("Frame", {Name = "Glow", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, -160, 1, 0), Size = UDim2.new(0, 160, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = topbar})
    local glowGradient = New("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = glow})
    OnTheme(function(theme) glowGradient.Color = ColorSequence.new(theme.Accent, theme.Accent2) end)
    TweenService:Create(glow, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(1, 0, 1, 0)}):Play()

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
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 200, 255)),
            ColorSequenceKeypoint.new(0.55, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
        }),
        Offset = Vector2.new(-1, 0),
        Parent = titleLabel,
    })
    TweenService:Create(titleShine, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 2.5), {Offset = Vector2.new(1, 0)}):Play()
    local authorLabel = Text({Name = "Author", Text = config.Author or "", TextSize = 12, Theme = {TextColor3 = "SubText"}, Size = UDim2.fromOffset(0, 15), AutomaticSize = AutoX, LayoutOrder = 2, Visible = (config.Author or "") ~= "", Parent = titleBlock})
    local tags = New("Frame", {Name = "Tags", Size = UDim2.fromOffset(0, 24), AutomaticSize = AutoX, BackgroundTransparency = 1, LayoutOrder = 3, Parent = titleRow}, {List(6, Horizontal, nil, Enum.VerticalAlignment.Center)})

    local controls = New("Frame", {Name = "Controls", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(0, 32), AutomaticSize = AutoX, BackgroundTransparency = 1, Parent = topbar}, {List(4, Horizontal, nil, Enum.VerticalAlignment.Center)})
    local function controlButton(iconName, order, hoverKey)
        local button = New("TextButton", {Name = iconName, Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(32, 32), Theme = {BackgroundColor3 = hoverKey or "ElementHover"}, BackgroundTransparency = 1, LayoutOrder = order, Parent = controls}, {Corner(8)})
        local image = Icon(iconName, 16, "SubText", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = button})
        button.MouseEnter:Connect(function()
            Tween(button, 0.2, {BackgroundTransparency = hoverKey and 0.75 or 0})
            if image then Retheme(image, "ImageColor3", hoverKey or "Text", 0.2) end
        end)
        button.MouseLeave:Connect(function()
            Tween(button, 0.2, {BackgroundTransparency = 1})
            if image then Retheme(image, "ImageColor3", "SubText", 0.2) end
        end)
        return button, image
    end
    local minimizeButton = controlButton("minus", 1)
    local maximizeButton, maximizeIcon = controlButton("maximize-2", 2)
    local closeButton = controlButton("x", 3, "Error")

    local body = New("Frame", {Name = "Body", Position = UDim2.fromOffset(0, topHeight), Size = UDim2.new(1, 0, 1, -topHeight), BackgroundTransparency = 1, Parent = main})
    local sidebar = New("Frame", {Name = "Sidebar", Size = UDim2.new(0, sideWidth, 1, 0), BackgroundTransparency = 1, Parent = body})
    New("Frame", {Name = "Line", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), Theme = {BackgroundColor3 = "Stroke"}, BorderSizePixel = 0, Parent = sidebar})

    local listTop = 10
    local searchBox
    if not config.HideSearchBar then
        local searchField = New("Frame", {Name = "Search", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 34), Theme = {BackgroundColor3 = "Field"}, Parent = sidebar}, {Corner(9)})
        local searchStroke = Stroke("Stroke")
        searchStroke.Parent = searchField
        Icon("search", 15, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Parent = searchField})
        searchBox = New("TextBox", {Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search", Theme = {TextColor3 = "Text", PlaceholderColor3 = "SubText"}, FontFace = GetFont(), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = searchField})
        searchBox.Focused:Connect(function() Retheme(searchStroke, "Color", "Accent", 0.2) end)
        searchBox.FocusLost:Connect(function() Retheme(searchStroke, "Color", "Stroke", 0.2) end)
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
    }, {Padding(10, 10, 4, 10), List(4)})

    if showUser then
        local userConfig = type(config.User) == "table" and config.User or {}
        local card = New("TextButton", {Name = "User", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 44), Theme = {BackgroundColor3 = "Element"}, Parent = sidebar}, {Corner(10), Stroke("Stroke", 0.4)})
        local anonymous = userConfig.Anonymous == true
        local avatar = New("ImageLabel", {Name = "Avatar", Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(30, 30), Theme = {BackgroundColor3 = "Field"}, Image = anonymous and "" or ("rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"), Parent = card}, {Corner(Round)})
        Stroke("Accent", 0.3, 1.5).Parent = avatar
        Text({Text = anonymous and "Anonymous" or LocalPlayer.DisplayName, TextSize = 13, FontFace = GetFont(Weight.SemiBold), Position = UDim2.fromOffset(46, 6), Size = UDim2.new(1, -54, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
        Text({Text = anonymous and "@hidden" or ("@" .. LocalPlayer.Name), TextSize = 11, Theme = {TextColor3 = "SubText"}, Position = UDim2.fromOffset(46, 23), Size = UDim2.new(1, -54, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
        card.MouseEnter:Connect(function() Retheme(card, "BackgroundColor3", "ElementHover", 0.2) end)
        card.MouseLeave:Connect(function() Retheme(card, "BackgroundColor3", "Element", 0.2) end)
        card.MouseButton1Click:Connect(function() SafeCall(userConfig.Callback) end)
    end

    local content = New("Frame", {Name = "Content", Position = UDim2.fromOffset(sideWidth, 0), Size = UDim2.new(1, -sideWidth, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = body})
    local pageFader = New("CanvasGroup", {Name = "PageFader", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = content})

    local function setTabVisual(tab, active, animate)
        local time = animate and 0.25 or 0
        Tween(tab.TabButton, time, {BackgroundTransparency = active and 0 or 1})
        Tween(tab.Indicator, animate and 0.35 or 0, {Size = UDim2.fromOffset(3, active and 18 or 0)}, Enum.EasingStyle.Back)
        Retheme(tab.TitleLabel, "TextColor3", active and "Text" or "SubText", time)
        if tab.IconImage then Retheme(tab.IconImage, "ImageColor3", active and "Accent" or "SubText", time) end
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
        pageFader.GroupTransparency = 1
        FadeThrough(pageFader, tab.Page, content, 0.4, 0, UDim2.fromOffset(0, 16))
    end

    local function createTab(tabConfig, container, group)
        tabConfig = tabConfig or {}
        local Tab = setmetatable({Title = tabConfig.Title or tabConfig.Name or "Tab", Window = Window, Group = group, Keywords = {}}, {__index = Elements})
        Tab.Tab = Tab
        Tab.Locked = tabConfig.Locked == true
        local button = New("TextButton", {Name = Tab.Title, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36), Theme = {BackgroundColor3 = "Element"}, BackgroundTransparency = 1, LayoutOrder = NextOrder(), Parent = container}, {Corner(9)})
        local indicator = New("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = button}, {Corner(Round)})
        AccentGradient(indicator, 90)
        local icon = Icon(tabConfig.Icon or tabConfig.Image, 16, "SubText", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 13, 0.5, 0), Parent = button})
        local labelX = icon and 38 or 15
        local label = Text({Text = Tab.Title, TextSize = 14, FontFace = GetFont(Weight.Medium), Theme = {TextColor3 = "SubText"}, Position = UDim2.fromOffset(labelX, 0), Size = UDim2.new(1, -(labelX + 8), 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = button})
        local lockIcon = Icon("lock", 14, "SubText", {Name = "Lock", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Visible = Tab.Locked, Parent = button})
        local function applyLock()
            if lockIcon then lockIcon.Visible = Tab.Locked end
            label.TextTransparency = Tab.Locked and 0.5 or 0
            if icon then icon.ImageTransparency = Tab.Locked and 0.5 or 0 end
        end
        applyLock()
        local page = New("Frame", {Name = "[Tab] " .. Tab.Title, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content})
        local scroll = New("ScrollingFrame", {Name = "Container", 
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = config.ScrollBarEnabled == false and 0 or 3,
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
        button.MouseEnter:Connect(function()
            if Window.Selected ~= Tab then Tween(button, 0.2, {BackgroundTransparency = 0.5}) end
        end)
        button.MouseLeave:Connect(function()
            if Window.Selected ~= Tab then Tween(button, 0.2, {BackgroundTransparency = 1}) end
        end)
        button.MouseButton1Click:Connect(function()
            if Tab.Locked then return end
            Ripple(button, 9)
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
        local groupHolder = New("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 2, Parent = frame})
        local inner = New("Frame", {Name = "Tabs", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = groupHolder}, {List(4)})
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
        header.MouseButton1Click:Connect(function()
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

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = searchBox.Text:lower()
            for _, tab in ipairs(Window.Tabs) do
                local match = query == "" or tab.Title:lower():find(query, 1, true) ~= nil
                if not match then
                    for _, keyword in ipairs(tab.Keywords) do
                        if tostring(keyword):lower():find(query, 1, true) then match = true break end
                    end
                end
                tab.TabButton.Visible = match
            end
            for _, group in ipairs(Window.Groups) do
                group.Forced = query ~= ""
                group.Apply(true)
            end
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
        if tagIcon then tagIcon.ImageColor3 = color end
        local label = Text({Text = tagConfig.Title or "Tag", TextSize = 12, FontFace = GetFont(Weight.SemiBold), Theme = {}, TextColor3 = color, Size = UDim2.fromOffset(0, 22), AutomaticSize = AutoX, LayoutOrder = 2, Parent = tag})
        local scaleIn = New("UIScale", {Scale = 0.6, Parent = tag})
        Tween(scaleIn, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
        local Tag = {}
        function Tag:SetTitle(value) label.Text = value end
        function Tag:SetColor(value)
            tag.BackgroundColor3 = value
            label.TextColor3 = value
            if tagIcon then tagIcon.ImageColor3 = value end
        end
        function Tag:Destroy() tag:Destroy() end
        return Tag
    end

    function Window:SetTitle(value) Window.Title = value titleLabel.Text = value end
    function Window:SetAuthor(value) authorLabel.Text = value authorLabel.Visible = value ~= "" end
    Window.UpdateTitle = Window.SetTitle
    Window.UpdateSubtitle = Window.SetAuthor

    local openButton = New("TextButton", {Name = "OpenButton", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -70), Size = UDim2.fromOffset(0, 42), AutomaticSize = AutoX, Theme = {BackgroundColor3 = "Background"}, Visible = false, ZIndex = 50, Parent = gui}, {
        Corner(Round),
        Padding(10, 18, 0, 0),
        List(10, Horizontal, nil, Enum.VerticalAlignment.Center),
    })
    local openStroke = New("UIStroke", {Thickness = 1.5, Color = Color3.new(1, 1, 1), Parent = openButton})
    local openStrokeGradient = AccentGradient(openStroke, 0)
    TweenService:Create(openStrokeGradient, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    local openIconHolder = New("Frame", {Name = "Icon", Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, LayoutOrder = 1, Parent = openButton})
    local openIcon = Icon(config.Icon or "layout-dashboard", 24, "Accent", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = openIconHolder})
    local openTitle = Text({Text = Window.Title, TextSize = 14, FontFace = GetFont(Weight.SemiBold), Size = UDim2.fromOffset(0, 42), AutomaticSize = AutoX, LayoutOrder = 2, Parent = openButton})

    local function fire(list)
        for _, callback in ipairs(list) do SafeCall(callback) end
    end

    function Window:Open()
        if Window.Opened or Window.Destroyed then return end
        Window.Opened = true
        holder.Visible = true
        Tween(scale, 0.5, {Scale = Window.Scale}, Enum.EasingStyle.Back)
        FadeThrough(canvas, main, holder, 0.35, 0)
        Tween(openButton, 0.3, {Position = UDim2.new(openButton.Position.X.Scale, openButton.Position.X.Offset, 0, -70)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.3, function() if Window.Opened then openButton.Visible = false end end)
        fire(Window.Events.Open)
    end

    function Window:Close()
        if not Window.Opened then return end
        Window.Opened = false
        Tween(scale, 0.25, {Scale = Window.Scale * 0.92}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        FadeThrough(canvas, main, holder, 0.25, 1)
        task.delay(0.25, function() if not Window.Opened then holder.Visible = false end end)
        if not Window.Destroyed and Window.OpenButtonEnabled ~= false then
            openButton.Visible = true
            Tween(openButton, 0.5, {Position = UDim2.new(openButton.Position.X.Scale, openButton.Position.X.Offset, 0, 14)}, Enum.EasingStyle.Back)
        end
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
        if type(key) == "string" then key = Enum.KeyCode[key] end
        Window.ToggleKey = key
    end
    Window.SetKeybind = Window.SetToggleKey

    function Window:Destroy()
        if Window.Destroyed then return end
        Window.Destroyed = true
        fire(Window.Events.Destroy)
        Window:Close()
        openButton.Visible = false
        for _, connection in ipairs(Window.Connections) do pcall(function() connection:Disconnect() end) end
        if Window.CursorCleanup then Window.CursorCleanup() end
        for flag, element in pairs(DX.Flags) do
            if element.Window == Window then DX.Flags[flag] = nil end
        end
        local index = table.find(DX.Windows, Window)
        if index then table.remove(DX.Windows, index) end
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

    local normalSize = size
    local maximized = false
    maximizeButton.MouseButton1Click:Connect(function()
        maximized = not maximized
        local view = workspace.CurrentCamera.ViewportSize
        if maximized then
            normalSize = holder.Size
            Tween(holder, 0.45, {Size = UDim2.fromOffset((view.X - 60) / Window.Scale, (view.Y - 60) / Window.Scale), Position = UDim2.fromScale(0.5, 0.5)})
        else
            Tween(holder, 0.45, {Size = normalSize})
        end
        if maximizeIcon then maximizeIcon.Image = DX:GetIcon(maximized and "minimize-2" or "maximize-2") or maximizeIcon.Image end
    end)
    minimizeButton.MouseButton1Click:Connect(function() Window:Close() end)
    closeButton.MouseButton1Click:Connect(function()
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

    Draggable(topbar, holder, Window.Connections)
    Draggable(openButton, openButton, Window.Connections, function() Window:Open() end)

    if config.Resizable ~= false then
        local resizer = New("TextButton", {Name = "Resize", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, ZIndex = 20, Parent = main})
        Icon("move-diagonal-2", 12, "SubText", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = 0.4, ZIndex = 21, Parent = resizer})
        local resizing, startPointer, startSize, startPosition = false
        resizer.InputBegan:Connect(function(input)
            if not IsPress(input) then return end
            resizing = true
            startPointer = PointerPosition(input)
            startSize = Vector2.new(holder.Size.X.Offset, holder.Size.Y.Offset)
            startPosition = holder.Position
        end)
        table.insert(Window.Connections, UserInputService.InputChanged:Connect(function(input)
            if not resizing or not IsMove(input) then return end
            local delta = (PointerPosition(input) - startPointer) / Window.Scale
            local width = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
            local height = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
            holder.Size = UDim2.fromOffset(width, height)
            holder.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + (width - startSize.X) * Window.Scale / 2, startPosition.Y.Scale, startPosition.Y.Offset + (height - startSize.Y) * Window.Scale / 2)
        end))
        table.insert(Window.Connections, UserInputService.InputEnded:Connect(function(input)
            if IsPress(input) then resizing = false end
        end))
    end

    table.insert(Window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or Window.Destroyed then return end
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
        if options.Icon and openIcon then openIcon.Image = DX:GetIcon(options.Icon) or openIcon.Image end
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
            local hovering = UserInputService.MouseEnabled and (inside(holder, point) or inside(openButton, point) or gui:FindFirstChild("Dialog") ~= nil)
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
