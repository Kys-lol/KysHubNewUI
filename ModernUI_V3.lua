--[[
    ModernUI V3 - Mobile Fullscreen Library
    ------------------------------------------------------------
    Responsive Roblox UI library for touch + mouse.
    Features:
      * Fullscreen / responsive window mode
      * Floating side button to open/close
      * Drag support for the floating button
      * Dark / Light / Red themes
      * Buttons, toggles, labels, textboxes, sliders, dropdowns,
        keybinds, sections and custom GUI containers
      * Optional IconsV2 integration (Lucide / Craft / SF Symbols)
      * Falls back gracefully when IconsV2 cannot be loaded
      * Safe cleanup / Destroy methods

    This is a UI library only. It does not contain exploit,
    anti-detection, bypass, or game-automation functionality.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- COMPATIBILITY
-- ============================================================

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    if type(get_hidden_gui) == "function" then
        local ok, result = pcall(get_hidden_gui)
        if ok and result then
            return result
        end
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function httpGet(url)
    local methods = {
        function() return game:HttpGetAsync(url) end,
        function() return game:HttpGet(url) end,
    }

    for _, fn in ipairs(methods) do
        local ok, result = pcall(fn)
        if ok and type(result) == "string" and #result > 0 then
            return result
        end
    end

    return nil
end

local function safeLoad(source)
    if type(loadstring) ~= "function" or type(source) ~= "string" then
        return nil
    end

    local ok, fn = pcall(loadstring, source)
    if not ok or type(fn) ~= "function" then
        return nil
    end

    local ok2, result = pcall(fn)
    if ok2 then
        return result
    end

    return nil
end

local function safeThumbnail(userId)
    local ok, result = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size150x150
        )
    end)

    return ok and result or ""
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0.5
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function tween(object, info, properties)
    local ok, result = pcall(function()
        local t = TweenService:Create(object, info, properties)
        t:Play()
        return t
    end)
    return ok and result or nil
end

local Tweens = {
    Fast = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

-- ============================================================
-- CLEANUP
-- ============================================================

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_tasks = {}}, Maid)
end

function Maid:Add(item)
    if type(item) == "function" then
        table.insert(self._tasks, item)
        return item
    end

    if typeof(item) == "RBXScriptConnection" then
        table.insert(self._tasks, function()
            pcall(function() item:Disconnect() end)
        end)
        return item
    end

    if typeof(item) == "Instance" then
        table.insert(self._tasks, function()
            pcall(function()
                if item.Parent then
                    item:Destroy()
                end
            end)
        end)
        return item
    end

    return nil
end

function Maid:Destroy()
    for i = #self._tasks, 1, -1 do
        pcall(self._tasks[i])
    end
    table.clear(self._tasks)
end

-- ============================================================
-- ICON SYSTEM
-- ============================================================

local IconSystem = {
    Loaded = false,
    Loading = false,
    Icons = {},
    Module = nil,
    Type = "lucide",
}

-- IconsV2 is optional. The UI still works without it.
function IconSystem:Load()
    if self.Loaded then
        return self.Module
    end

    if self.Loading then
        while self.Loading do
            task.wait()
        end
        return self.Module
    end

    self.Loading = true

    local url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
    local source = httpGet(url)

    if source then
        local module = safeLoad(source)
        if type(module) == "table" then
            self.Module = module

            pcall(function()
                if module.SetIconsType then
                    module.SetIconsType(self.Type)
                end
            end)

            self.Loaded = true
        end
    end

    self.Loading = false
    return self.Module
end

function IconSystem:SetType(iconType)
    iconType = tostring(iconType or "lucide")
    self.Type = iconType

    if self.Module and self.Module.SetIconsType then
        pcall(function()
            self.Module.SetIconsType(iconType)
        end)
    end

    return self
end

function IconSystem:Get(icon)
    icon = tostring(icon or "")
    if icon == "" then
        return ""
    end

    -- Direct Roblox asset / image URL.
    if icon:match("^rbxassetid://")
        or icon:match("^rbxasset://")
        or icon:match("^https?://")
        or icon:match("^%d+$") then

        if icon:match("^%d+$") then
            return "rbxassetid://" .. icon
        end

        return icon
    end

    local module = self.Module or self:Load()

    if module and type(module.GetIcon) == "function" then
        local ok, result = pcall(function()
            return module.GetIcon(icon)
        end)

        if ok and type(result) == "string" then
            return result
        end
    end

    return ""
end

-- Try to load IconsV2 without blocking UI construction.
task.spawn(function()
    pcall(function()
        IconSystem:Load()
    end)
end)

-- ============================================================
-- THEMES
-- ============================================================

local Themes = {
    Dark = {
        Name = "Dark",
        Accent = Color3.fromRGB(78, 127, 252),
        AccentHover = Color3.fromRGB(99, 147, 255),
        Background = Color3.fromRGB(8, 8, 13),
        Sidebar = Color3.fromRGB(12, 12, 20),
        Surface = Color3.fromRGB(20, 22, 27),
        SurfaceHover = Color3.fromRGB(29, 31, 40),
        Stroke = Color3.fromRGB(45, 48, 58),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(140, 140, 155),
        ToggleOff = Color3.fromRGB(40, 40, 50),
        ScrollBar = Color3.fromRGB(60, 60, 75),
    },

    Light = {
        Name = "Light",
        Accent = Color3.fromRGB(0, 122, 255),
        AccentHover = Color3.fromRGB(20, 140, 255),
        Background = Color3.fromRGB(242, 242, 247),
        Sidebar = Color3.fromRGB(232, 232, 238),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceHover = Color3.fromRGB(245, 245, 250),
        Stroke = Color3.fromRGB(210, 210, 220),
        Text = Color3.fromRGB(20, 20, 30),
        TextMuted = Color3.fromRGB(100, 100, 115),
        ToggleOff = Color3.fromRGB(200, 200, 210),
        ScrollBar = Color3.fromRGB(175, 175, 190),
    },

    Red = {
        Name = "Red",
        Accent = Color3.fromRGB(255, 69, 58),
        AccentHover = Color3.fromRGB(255, 99, 89),
        Background = Color3.fromRGB(12, 12, 18),
        Sidebar = Color3.fromRGB(18, 18, 26),
        Surface = Color3.fromRGB(24, 24, 34),
        SurfaceHover = Color3.fromRGB(34, 31, 43),
        Stroke = Color3.fromRGB(50, 45, 58),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(145, 140, 155),
        ToggleOff = Color3.fromRGB(40, 38, 48),
        ScrollBar = Color3.fromRGB(60, 55, 70),
    },
}

-- ============================================================
-- DRAGGING
-- ============================================================

local function makeDraggable(frame, handle, clampToScreen)
    local dragging = false
    local startInput
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        startInput = input.Position
        startPosition = frame.Position
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    handle.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - startInput
        local position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )

        if clampToScreen then
            local camera = workspace.CurrentCamera
            if camera then
                local viewport = camera.ViewportSize
                local size = frame.AbsoluteSize
                local x = math.clamp(
                    position.X.Offset,
                    0,
                    math.max(0, viewport.X - size.X)
                )
                local y = math.clamp(
                    position.Y.Offset,
                    0,
                    math.max(0, viewport.Y - size.Y)
                )
                position = UDim2.fromOffset(x, y)
            end
        end

        frame.Position = position
    end)
end

-- ============================================================
-- CUSTOM GUI CONTAINER
-- ============================================================

local CustomGui = {}
CustomGui.__index = CustomGui

function CustomGui.new(parent, config, theme)
    local self = setmetatable({}, CustomGui)

    config = config or {}
    self.Theme = theme
    self.Destroyed = false
    self.AutoHeight = config.AutoHeight == true
    self.Height = tonumber(config.Height) or 200
    self.Maid = Maid.new()

    local root = Instance.new("Frame")
    root.Name = "CustomGui_" .. tostring(config.Name or "Custom")
    root.BackgroundColor3 = config.BackgroundColor or theme.Surface
    root.BackgroundTransparency = config.BackgroundTransparency or 0.1
    root.BorderSizePixel = 0
    root.Size = UDim2.new(1, -10, 0, self.Height)
    root.LayoutOrder = config.LayoutOrder or 0
    root.Visible = config.Visible ~= false
    root.Parent = parent

    corner(root, 8)
    self.Stroke = stroke(root, config.StrokeColor or theme.Stroke, 0.6, 1)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(6, 6)
    content.Size = UDim2.new(1, -12, 1, -12)
    content.Parent = root

    self.Root = root
    self.Content = content

    local function updateHeight()
        if not self.AutoHeight or self.Destroyed then
            return
        end

        task.defer(function()
            if self.Destroyed or not content.Parent then
                return
            end

            local maxY = 0
            local list = content:FindFirstChildOfClass("UIListLayout")
            local grid = content:FindFirstChildOfClass("UIGridLayout")

            if list then
                maxY = math.max(maxY, list.AbsoluteContentSize.Y)
            end

            if grid then
                maxY = math.max(maxY, grid.AbsoluteContentSize.Y)
            end

            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("GuiObject") then
                    local bottom = child.AbsolutePosition.Y
                        + child.AbsoluteSize.Y
                        - content.AbsolutePosition.Y
                    maxY = math.max(maxY, bottom)
                end
            end

            self.Height = math.max(50, maxY + 12)
            root.Size = UDim2.new(1, -10, 0, self.Height)
        end)
    end

    self.UpdateHeight = updateHeight

    self.Maid:Add(content.DescendantAdded:Connect(updateHeight))
    self.Maid:Add(content.DescendantRemoving:Connect(updateHeight))

    task.defer(updateHeight)

    return self
end

function CustomGui:GetContent()
    return self.Content
end

function CustomGui:GetRoot()
    return self.Root
end

function CustomGui:SetHeight(value)
    value = tonumber(value)
    if not value or self.Destroyed then
        return self
    end

    self.AutoHeight = false
    self.Height = value
    self.Root.Size = UDim2.new(1, -10, 0, value)
    return self
end

function CustomGui:SetAutoHeight(value)
    self.AutoHeight = value == true
    if self.AutoHeight then
        self.UpdateHeight()
    end
    return self
end

function CustomGui:SetVisible(value)
    self.Root.Visible = value == true
    return self
end

function CustomGui:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    self.Maid:Destroy()

    if self.Root.Parent then
        self.Root:Destroy()
    end
end

-- ============================================================
-- CONTROL BUILDERS
-- ============================================================

local Controls = {}

function Controls:AddButton(config, parent, theme)
    config = config or {}

    local button = Instance.new("TextButton")
    button.Name = "Button_" .. tostring(config.Name or "Button")
    button.BackgroundColor3 = theme.Surface
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Size = UDim2.new(1, -10, 0, 38)
    button.Font = Enum.Font.GothamMedium
    button.Text = tostring(config.Name or "Button")
    button.TextColor3 = theme.Text
    button.TextSize = 13
    button.LayoutOrder = config.LayoutOrder or 0
    button.Parent = parent

    corner(button, 7)
    stroke(button, theme.Stroke, 0.65, 1)

    local icon = config.Icon
    if icon then
        local image = Instance.new("ImageLabel")
        image.BackgroundTransparency = 1
        image.Size = UDim2.fromOffset(18, 18)
        image.Position = UDim2.new(0, 10, 0.5, -9)
        image.ScaleType = Enum.ScaleType.Fit
        image.ImageColor3 = theme.Accent
        image.Image = IconSystem:Get(icon)
        image.Parent = button

        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = "     " .. tostring(config.Name or "Button")
    end

    button.MouseEnter:Connect(function()
        tween(button, Tweens.Normal, {
            BackgroundColor3 = theme.SurfaceHover
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, Tweens.Normal, {
            BackgroundColor3 = theme.Surface
        })
    end)

    button.MouseButton1Click:Connect(function()
        pcall(config.Callback or function() end)
    end)

    return {
        Root = button,
        SetText = function(text)
            button.Text = tostring(text)
        end,
        SetEnabled = function(enabled)
            button.Active = enabled == true
            button.AutoButtonColor = enabled == true
            button.TextTransparency = enabled == true and 0 or 0.5
        end,
        Destroy = function()
            if button.Parent then button:Destroy() end
        end,
    }
end

function Controls:AddToggle(config, parent, theme)
    config = config or {}

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 38)
    frame.LayoutOrder = config.LayoutOrder or 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -58, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(config.Name or "Toggle")
    label.TextColor3 = theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.BackgroundColor3 = theme.ToggleOff
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.Size = UDim2.fromOffset(42, 22)
    button.Parent = frame
    corner(button, 11)

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.fromRGB(205, 205, 210)
    knob.BorderSizePixel = 0
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0.25, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(15, 15)
    knob.Parent = button
    corner(knob, 8)

    local state = config.Default == true

    local function update(callCallback)
        tween(button, Tweens.Normal, {
            BackgroundColor3 = state and theme.Accent or theme.ToggleOff
        })

        tween(knob, Tweens.Spring, {
            Position = UDim2.new(state and 0.75 or 0.25, 0, 0.5, 0),
            BackgroundColor3 = state
                and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(205, 205, 210)
        })

        if callCallback then
            pcall(config.Callback or function() end, state)
        end
    end

    update(false)

    button.MouseButton1Click:Connect(function()
        state = not state
        update(true)
    end)

    return {
        Root = frame,
        Get = function() return state end,
        Set = function(value)
            state = value == true
            update(true)
        end,
        Toggle = function()
            state = not state
            update(true)
        end,
        Destroy = function()
            if frame.Parent then frame:Destroy() end
        end,
    }
end

function Controls:AddLabel(text, parent, theme)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 0, 26)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(text or "")
    label.TextColor3 = theme.TextMuted
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    return {
        Root = label,
        SetText = function(value) label.Text = tostring(value) end,
        GetText = function() return label.Text end,
        Destroy = function()
            if label.Parent then label:Destroy() end
        end,
    }
end

function Controls:AddTextbox(config, parent, theme)
    config = config or {}

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 62)
    frame.LayoutOrder = config.LayoutOrder or 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(config.Name or "Textbox")
    label.TextColor3 = theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local boxFrame = Instance.new("Frame")
    boxFrame.BackgroundColor3 = theme.Surface
    boxFrame.BackgroundTransparency = 0.15
    boxFrame.BorderSizePixel = 0
    boxFrame.Position = UDim2.fromOffset(0, 28)
    boxFrame.Size = UDim2.new(1, 0, 0, 32)
    boxFrame.Parent = frame
    corner(boxFrame, 7)
    stroke(boxFrame, theme.Stroke, 0.65, 1)

    local box = Instance.new("TextBox")
    box.BackgroundTransparency = 1
    box.Position = UDim2.fromOffset(9, 0)
    box.Size = UDim2.new(1, -18, 1, 0)
    box.Font = Enum.Font.GothamMedium
    box.Text = tostring(config.Default or "")
    box.PlaceholderText = tostring(config.Placeholder or "Input...")
    box.TextColor3 = theme.Text
    box.PlaceholderColor3 = theme.TextMuted
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = boxFrame

    box.FocusLost:Connect(function()
        pcall(config.Callback or function() end, box.Text)
    end)

    return {
        Root = frame,
        GetValue = function() return box.Text end,
        SetValue = function(value) box.Text = tostring(value) end,
        Focus = function() box:CaptureFocus() end,
        SetPlaceholder = function(value) box.PlaceholderText = tostring(value) end,
        Destroy = function()
            if frame.Parent then frame:Destroy() end
        end,
    }
end

function Controls:AddSlider(config, parent, theme)
    config = config or {}

    local min = tonumber(config.Min) or 0
    local max = tonumber(config.Max) or 100
    if max <= min then max = min + 1 end

    local value = math.clamp(
        tonumber(config.Default) or min,
        min,
        max
    )

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 58)
    frame.LayoutOrder = config.LayoutOrder or 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -55, 0, 22)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(config.Name or "Slider")
    label.TextColor3 = theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.Size = UDim2.fromOffset(55, 22)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextColor3 = theme.Accent
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local track = Instance.new("TextButton")
    track.BackgroundColor3 = theme.Surface
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.Position = UDim2.fromOffset(0, 32)
    track.Size = UDim2.new(1, 0, 0, 7)
    track.Text = ""
    track.Parent = frame
    corner(track, 4)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(0, 1)
    fill.Parent = track
    corner(fill, 4)

    local function ratio()
        return math.clamp((value - min) / (max - min), 0, 1)
    end

    local function render()
        local r = ratio()
        tween(fill, Tweens.Fast, {Size = UDim2.fromScale(r, 1)})
        valueLabel.Text = tostring(value)
    end

    local function setFromInput(input)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end

        local x = input.Position.X - track.AbsolutePosition.X
        local r = math.clamp(x / width, 0, 1)

        local newValue = math.floor(min + (max - min) * r + 0.5)
        if newValue ~= value then
            value = newValue
            render()
            pcall(config.Callback or function() end, value)
        end
    end

    local dragging = false

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromInput(input)
        end
    end)

    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    track.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            setFromInput(input)
        end
    end)

    render()

    return {
        Root = frame,
        GetValue = function() return value end,
        SetValue = function(v)
            value = math.clamp(tonumber(v) or min, min, max)
            render()
            pcall(config.Callback or function() end, value)
        end,
        SetMin = function(v)
            min = tonumber(v) or min
            if max <= min then max = min + 1 end
            value = math.clamp(value, min, max)
            render()
        end,
        SetMax = function(v)
            max = tonumber(v) or max
            if max <= min then max = min + 1 end
            value = math.clamp(value, min, max)
            render()
        end,
        Destroy = function()
            if frame.Parent then frame:Destroy() end
        end,
    }
end

function Controls:AddDropdown(config, parent, theme, screenGui)
    config = config or {}

    local values = config.Values or {}
    local selected = config.Default
    if selected == nil then
        selected = values[1] or ""
    end

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 62)
    frame.LayoutOrder = config.LayoutOrder or 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(config.Name or "Dropdown")
    label.TextColor3 = theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.BackgroundColor3 = theme.Surface
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Position = UDim2.fromOffset(0, 28)
    button.Size = UDim2.new(1, 0, 0, 32)
    button.Text = ""
    button.Parent = frame
    corner(button, 7)
    stroke(button, theme.Stroke, 0.65, 1)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Position = UDim2.fromOffset(9, 0)
    text.Size = UDim2.new(1, -40, 1, 0)
    text.Font = Enum.Font.GothamMedium
    text.Text = tostring(selected)
    text.TextColor3 = theme.Text
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = button

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -8, 0.5, 0)
    arrow.Size = UDim2.fromOffset(20, 20)
    arrow.Font = Enum.Font.GothamBold
    arrow.Text = "▾"
    arrow.TextColor3 = theme.TextMuted
    arrow.TextSize = 14
    arrow.Parent = button

    local menu = Instance.new("Frame")
    menu.BackgroundColor3 = theme.Surface
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.ZIndex = 100
    menu.Parent = screenGui or parent
    corner(menu, 7)
    stroke(menu, theme.Stroke, 0.45, 1)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = menu

    local outsideConnection
    local open = false

    local function close()
        open = false
        menu.Visible = false

        if outsideConnection then
            outsideConnection:Disconnect()
            outsideConnection = nil
        end
    end

    local function position()
        local p = button.AbsolutePosition
        local s = button.AbsoluteSize
        local h = math.min(layout.AbsoluteContentSize.Y + 6, 210)

        menu.Size = UDim2.fromOffset(s.X, h)
        menu.Position = UDim2.fromOffset(p.X, p.Y + s.Y + 3)
    end

    local function rebuild()
        for _, child in ipairs(menu:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for i, value in ipairs(values) do
            local item = Instance.new("TextButton")
            item.BackgroundColor3 = theme.SurfaceHover
            item.BackgroundTransparency = 1
            item.BorderSizePixel = 0
            item.AutoButtonColor = false
            item.Size = UDim2.new(1, -6, 0, 29)
            item.Font = Enum.Font.GothamMedium
            item.Text = tostring(value)
            item.TextColor3 = theme.Text
            item.TextSize = 12
            item.LayoutOrder = i
            item.Parent = menu
            item.ZIndex = 101
            corner(item, 5)

            item.MouseEnter:Connect(function()
                tween(item, Tweens.Fast, {
                    BackgroundTransparency = 0.2,
                    BackgroundColor3 = theme.Accent,
                })
            end)

            item.MouseLeave:Connect(function()
                tween(item, Tweens.Fast, {
                    BackgroundTransparency = 1,
                })
            end)

            item.MouseButton1Click:Connect(function()
                selected = value
                text.Text = tostring(value)
                close()
                pcall(config.Callback or function() end, value)
            end)
        end
    end

    rebuild()

    button.MouseButton1Click:Connect(function()
        if open then
            close()
            return
        end

        position()
        menu.Visible = true
        open = true

        outsideConnection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                task.defer(function()
                    if open then close() end
                end)
            end
        end)
    end)

    return {
        Root = frame,
        GetValue = function() return selected end,
        SetValue = function(value)
            selected = value
            text.Text = tostring(value)
        end,
        SetValues = function(newValues)
            values = newValues or {}
            if not table.find(values, selected) then
                selected = values[1] or ""
                text.Text = tostring(selected)
            end
            rebuild()
        end,
        Destroy = function()
            close()
            if frame.Parent then frame:Destroy() end
            if menu.Parent then menu:Destroy() end
        end,
    }
end

function Controls:AddKeybind(config, parent, theme)
    config = config or {}

    local current = config.Default or Enum.KeyCode.RightControl
    local binding = false
    local bindConnection

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 38)
    frame.LayoutOrder = config.LayoutOrder or 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -68, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = tostring(config.Name or "Keybind")
    label.TextColor3 = theme.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.BackgroundColor3 = theme.Surface
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.Size = UDim2.fromOffset(62, 30)
    button.Font = Enum.Font.GothamMedium
    button.Text = tostring(current):gsub("Enum.KeyCode.", "")
    button.TextColor3 = theme.Text
    button.TextSize = 10
    button.Parent = frame
    corner(button, 7)
    stroke(button, theme.Stroke, 0.65, 1)

    button.MouseButton1Click:Connect(function()
        if binding then return end

        binding = true
        button.Text = "..."

        if bindConnection then
            bindConnection:Disconnect()
        end

        bindConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                return
            end

            current = input.KeyCode
            binding = false
            button.Text = tostring(current):gsub("Enum.KeyCode.", "")

            if bindConnection then
                bindConnection:Disconnect()
                bindConnection = nil
            end

            pcall(config.Callback or function() end, current)
        end)

        task.delay(5, function()
            if binding then
                binding = false
                button.Text = tostring(current):gsub("Enum.KeyCode.", "")
                if bindConnection then
                    bindConnection:Disconnect()
                    bindConnection = nil
                end
            end
        end)
    end)

    return {
        Root = frame,
        GetKey = function() return current end,
        SetKey = function(key)
            current = key
            button.Text = tostring(key):gsub("Enum.KeyCode.", "")
        end,
        Destroy = function()
            if bindConnection then bindConnection:Disconnect() end
            if frame.Parent then frame:Destroy() end
        end,
    }
end

function Controls:AddSection(title, parent, theme)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = tostring(title or "Section")
    label.TextColor3 = theme.Accent
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local line = Instance.new("Frame")
    line.BackgroundColor3 = theme.Stroke
    line.BackgroundTransparency = 0.45
    line.AnchorPoint = Vector2.new(0, 1)
    line.Position = UDim2.new(0, 0, 1, 0)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Parent = frame

    return {
        Root = frame,
        SetTitle = function(value) label.Text = tostring(value) end,
        Destroy = function()
            if frame.Parent then frame:Destroy() end
        end,
    }
end

-- ============================================================
-- WINDOW
-- ============================================================

local Window = {}
Window.__index = Window

local function getViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(800, 600)
end

function Window:_calculateSize(config)
    local viewport = getViewport()

    if config.Fullscreen == true then
        return UDim2.fromOffset(
            math.max(300, viewport.X - 8),
            math.max(300, viewport.Y - 8)
        )
    end

    if config.Size then
        return config.Size
    end

    local width = math.min(720, math.max(330, viewport.X - 20))
    local height = math.min(620, math.max(430, viewport.Y - 20))

    return UDim2.fromOffset(width, height)
end

function Window.new(library, config)
    local self = setmetatable({}, Window)

    config = config or {}

    self.Library = library
    self.Theme = library.Theme
    self.Maid = Maid.new()
    self.Tabs = {}
    self.ActiveTab = nil
    self.Destroyed = false
    self.Visible = config.Visible ~= false
    self.Fullscreen = config.Fullscreen == true

    self.Title = tostring(config.Title or "ModernUI")
    self.Subtitle = tostring(config.Subtitle or "Mobile UI")
    self.Icon = config.Icon or "house"
    self.Size = self:_calculateSize(config)

    local screen = Instance.new("ScreenGui")
    screen.Name = "ModernUI_" .. self.Title
    screen.IgnoreGuiInset = true
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screen.Parent = getGuiParent()

    self.ScreenGui = screen

    -- Main window
    local root = Instance.new("Frame")
    root.Name = "Window"
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.Size = self.Size
    root.BackgroundColor3 = self.Theme.Background
    root.BackgroundTransparency = 0.03
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = screen
    corner(root, 12)
    stroke(root, self.Theme.Stroke, 0.65, 1)

    self.Root = root

    self:_buildSidebar()
    self:_buildMain()
    self:_buildFloatingButton(config)

    self.Maid:Add(screen.AncestryChanged:Connect(function(_, parent)
        if not parent and not self.Destroyed then
            self:Destroy()
        end
    end))

    -- Update fullscreen size when device rotates / viewport changes.
    self.Maid:Add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if self.Fullscreen and not self.Destroyed then
            self:SetSize(self:_calculateSize({Fullscreen = true}))
        end
    end))

    self:SetVisible(self.Visible)

    return self
end

function Window:_buildSidebar()
    local sidebar = Instance.new("Frame")
    sidebar.BackgroundColor3 = self.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Size = UDim2.fromOffset(185, 9999)
    sidebar.Size = UDim2.new(0, 185, 1, 0)
    sidebar.Parent = self.Root

    self.Sidebar = sidebar

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 70)
    header.Parent = sidebar

    self.Header = header

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(10, 12)
    logo.Size = UDim2.fromOffset(42, 42)
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Image = IconSystem:Get(self.Icon)
    logo.ImageColor3 = self.Theme.Accent
    logo.Parent = header

    corner(9, logo)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(60, 10)
    title.Size = UDim2.new(1, -68, 0, 25)
    title.Font = Enum.Font.GothamBold
    title.Text = self.Title
    title.TextColor3 = self.Theme.Text
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(60, 35)
    subtitle.Size = UDim2.new(1, -68, 0, 18)
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.Text = self.Subtitle
    subtitle.TextColor3 = self.Theme.TextMuted
    subtitle.TextSize = 10
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    self.TitleLabel = title
    self.SubtitleLabel = subtitle
    self.Logo = logo

    local divider = Instance.new("Frame")
    divider.BackgroundColor3 = self.Theme.Stroke
    divider.BackgroundTransparency = 0.45
    divider.Position = UDim2.fromOffset(10, 69)
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Parent = sidebar

    local tabs = Instance.new("ScrollingFrame")
    tabs.BackgroundTransparency = 1
    tabs.BorderSizePixel = 0
    tabs.Position = UDim2.fromOffset(5, 78)
    tabs.Size = UDim2.new(1, -10, 1, -145)
    tabs.ScrollBarThickness = 3
    tabs.ScrollBarImageColor3 = self.Theme.ScrollBar
    tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabs.CanvasSize = UDim2.new()
    tabs.Parent = sidebar

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = tabs

    self.TabList = tabs

    local footer = Instance.new("Frame")
    footer.BackgroundTransparency = 1
    footer.AnchorPoint = Vector2.new(0, 1)
    footer.Position = UDim2.new(0, 0, 1, 0)
    footer.Size = UDim2.new(1, 0, 0, 62)
    footer.Parent = sidebar

    local footerLine = Instance.new("Frame")
    footerLine.BackgroundColor3 = self.Theme.Stroke
    footerLine.BackgroundTransparency = 0.45
    footerLine.Position = UDim2.fromOffset(10, 0)
    footerLine.Size = UDim2.new(1, -20, 0, 1)
    footerLine.Parent = footer

    local avatar = Instance.new("ImageLabel")
    avatar.BackgroundTransparency = 1
    avatar.Position = UDim2.fromOffset(10, 12)
    avatar.Size = UDim2.fromOffset(36, 36)
    avatar.Image = safeThumbnail(LocalPlayer.UserId)
    avatar.Parent = footer
    corner(18, avatar)

    local username = Instance.new("TextLabel")
    username.BackgroundTransparency = 1
    username.Position = UDim2.fromOffset(55, 12)
    username.Size = UDim2.new(1, -62, 0, 18)
    username.Font = Enum.Font.GothamBold
    username.Text = LocalPlayer.DisplayName
    username.TextColor3 = self.Theme.Text
    username.TextSize = 12
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.Parent = footer

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(55, 31)
    status.Size = UDim2.new(1, -62, 0, 16)
    status.Font = Enum.Font.GothamMedium
    status.Text = "Active"
    status.TextColor3 = Color3.fromRGB(90, 210, 125)
    status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = footer
end

function Window:_buildMain()
    local main = Instance.new("Frame")
    main.BackgroundColor3 = self.Theme.Background
    main.BackgroundTransparency = 0.03
    main.BorderSizePixel = 0
    main.Position = UDim2.fromOffset(185, 0)
    main.Size = UDim2.new(1, -185, 1, 0)
    main.Parent = self.Root

    self.Main = main

    local top = Instance.new("Frame")
    top.BackgroundTransparency = 1
    top.Size = UDim2.new(1, 0, 0, 48)
    top.Parent = main

    self.TopBar = top

    local close = Instance.new("TextButton")
    close.BackgroundColor3 = self.Theme.Surface
    close.BackgroundTransparency = 0.2
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -9, 0.5, 0)
    close.Size = UDim2.fromOffset(32, 32)
    close.Font = Enum.Font.GothamBold
    close.Text = "×"
    close.TextColor3 = self.Theme.TextMuted
    close.TextSize = 20
    close.Parent = top
    corner(8, close)
    stroke(close, self.Theme.Stroke, 0.6, 1)

    close.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)

    self.CloseButton = close

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(0, 48)
    content.Size = UDim2.new(1, 0, 1, -48)
    content.Parent = main

    self.TabContainer = content

    -- The header can be dragged on desktop, while the floating button
    -- is the preferred touch control on mobile.
    makeDraggable(self.Root, top, true)
end

function Window:_buildFloatingButton(config)
    local size = tonumber(config.ToggleButtonSize) or 48
    local button = Instance.new("TextButton")
    button.Name = "OpenCloseButton"
    button.AnchorPoint = Vector2.new(0, 0.5)
    button.Position = UDim2.new(
        0,
        tonumber(config.ToggleButtonX) or 10,
        0.5,
        tonumber(config.ToggleButtonY) or 0
    )
    button.Size = UDim2.fromOffset(size, size)
    button.BackgroundColor3 = config.ToggleButtonColor or self.Theme.Surface
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = 200
    button.Parent = self.ScreenGui
    corner(button, math.floor(size * 0.28))
    local buttonStroke = stroke(button, self.Theme.Accent, 0.2, 1.5)

    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.Position = UDim2.fromScale(0.5, 0.5)
    image.Size = UDim2.fromScale(0.58, 0.58)
    image.ScaleType = Enum.ScaleType.Fit
    image.ImageColor3 = self.Theme.Text
    image.Image = IconSystem:Get(config.ToggleIcon or "menu")
    image.Parent = button

    self.FloatingButton = button
    self.FloatingIcon = image
    self.FloatingStroke = buttonStroke
    self.ToggleButtonDraggable = config.ToggleButtonDraggable ~= false

    -- Tap/drag discrimination.
    local dragging = false
    local moved = false
    local dragStart
    local startPosition
    local threshold = 7

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = false
        moved = false
        dragStart = input.Position
        startPosition = button.Position

        local moveConnection
        local endConnection

        moveConnection = UserInputService.InputChanged:Connect(function(change)
            if change.UserInputType ~= Enum.UserInputType.MouseMovement
                and change.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local delta = change.Position - dragStart

            if self.ToggleButtonDraggable and delta.Magnitude > threshold then
                moved = true
                dragging = true

                local camera = workspace.CurrentCamera
                local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)

                local x = math.clamp(
                    startPosition.X.Offset + delta.X,
                    0,
                    math.max(0, viewport.X - size)
                )

                local yCenter = startPosition.Y.Scale * viewport.Y
                    + startPosition.Y.Offset
                    + delta.Y

                yCenter = math.clamp(
                    yCenter,
                    size / 2,
                    viewport.Y - size / 2
                )

                button.Position = UDim2.new(0, x, 0, yCenter)
            end
        end)

        endConnection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            if moveConnection then moveConnection:Disconnect() end
            if endConnection then endConnection:Disconnect() end

            if not moved and not dragging then
                self:Toggle()
            end
        end)
    end)
end

function Window:AddTab(config)
    if type(config) == "string" then
        config = {Name = config}
    end

    config = config or {}

    local tab = {
        Window = self,
        Name = tostring(config.Name or "Tab"),
        Icon = config.Icon or "",
        Controls = {},
        CustomGuis = {},
        Destroyed = false,
        Visible = false,
    }

    local button = Instance.new("TextButton")
    button.BackgroundColor3 = self.Theme.Surface
    button.BackgroundTransparency = 0.5
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Size = UDim2.new(1, 0, 0, 38)
    button.Text = ""
    button.LayoutOrder = config.LayoutOrder or 0
    button.Parent = self.TabList
    corner(button, 7)

    local icon = Instance.new("ImageLabel")
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.fromOffset(10, 8)
    icon.Size = UDim2.fromOffset(22, 22)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Image = IconSystem:Get(tab.Icon)
    icon.ImageColor3 = self.Theme.TextMuted
    icon.Parent = button

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(40, 0)
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = tab.Name
    label.TextColor3 = self.Theme.TextMuted
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Size = UDim2.fromScale(1, 1)
    content.Visible = false
    content.Parent = self.TabContainer

    local scroll = Instance.new("ScrollingFrame")
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(10, 10)
    scroll.Size = UDim2.new(1, -20, 1, -20)
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = self.Theme.ScrollBar
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    tab.Button = button
    tab.IconObject = icon
    tab.Label = label
    tab.Content = content
    tab.Scroll = scroll
    tab.Layout = layout

    function tab:Show()
        if self.Destroyed then return end

        self.Visible = true
        self.Content.Visible = true

        tween(self.Button, Tweens.Normal, {
            BackgroundColor3 = self.Window.Theme.SurfaceHover,
            BackgroundTransparency = 0,
        })

        tween(self.Label, Tweens.Normal, {
            TextColor3 = self.Window.Theme.Text,
        })

        tween(self.IconObject, Tweens.Normal, {
            ImageColor3 = self.Window.Theme.Accent,
        })
    end

    function tab:Hide()
        if self.Destroyed then return end

        self.Visible = false
        self.Content.Visible = false

        tween(self.Button, Tweens.Normal, {
            BackgroundColor3 = self.Window.Theme.Surface,
            BackgroundTransparency = 0.5,
        })

        tween(self.Label, Tweens.Normal, {
            TextColor3 = self.Window.Theme.TextMuted,
        })

        tween(self.IconObject, Tweens.Normal, {
            ImageColor3 = self.Window.Theme.TextMuted,
        })
    end

    function tab:AddButton(cfg)
        local control = Controls:AddButton(cfg, self.Scroll, self.Window.Theme)
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddToggle(cfg)
        local control = Controls:AddToggle(cfg, self.Scroll, self.Window.Theme)
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddLabel(text)
        local control = Controls:AddLabel(text, self.Scroll, self.Window.Theme)
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddTextbox(cfg)
        local control = Controls:AddTextbox(cfg, self.Scroll, self.Window.Theme)
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddSlider(cfg)
        local control = Controls:AddSlider(cfg, self.Scroll, self.Window.Theme)
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddDropdown(cfg)
        local control = Controls:AddDropdown(
            cfg,
            self.Scroll,
            self.Window.Theme,
            self.Window.ScreenGui
        )
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddKeybind(cfg)
        local control = Controls:AddKeybind(cfg, self.Scroll, self.Window.Theme)
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddSection(title)
        local control = Controls:AddSection(
            title,
            self.Scroll,
            self.Window.Theme
        )
        table.insert(self.Controls, control)
        return control
    end

    function tab:AddCustomGui(cfg)
        local custom = CustomGui.new(
            self.Scroll,
            cfg or {},
            self.Window.Theme
        )
        table.insert(self.CustomGuis, custom)
        return custom
    end

    function tab:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true

        for i = #self.CustomGuis, 1, -1 do
            pcall(function()
                self.CustomGuis[i]:Destroy()
            end)
        end
        table.clear(self.CustomGuis)

        for i = #self.Controls, 1, -1 do
            pcall(function()
                self.Controls[i].Destroy()
            end)
        end
        table.clear(self.Controls)

        if self.Button.Parent then self.Button:Destroy() end
        if self.Content.Parent then self.Content:Destroy() end

        for i = #self.Window.Tabs, 1, -1 do
            if self.Window.Tabs[i] == self then
                table.remove(self.Window.Tabs, i)
                break
            end
        end

        if self.Window.ActiveTab == self then
            self.Window.ActiveTab = nil
            if #self.Window.Tabs > 0 then
                self.Window:SelectTab(self.Window.Tabs[1])
            end
        end
    end

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    if self.Destroyed or not tab or tab.Destroyed then
        return
    end

    self.ActiveTab = tab

    for _, current in ipairs(self.Tabs) do
        if current == tab then
            current:Show()
        else
            current:Hide()
        end
    end
end

function Window:SetVisible(value)
    if self.Destroyed then return end

    self.Visible = value == true
    self.ScreenGui.Enabled = true

    if self.Visible then
        self.Root.Visible = true
        tween(self.Root, Tweens.Normal, {
            Size = self.Size
        })
    else
        tween(self.Root, Tweens.Normal, {
            Size = UDim2.fromOffset(0, 0)
        })

        task.delay(0.18, function()
            if not self.Destroyed and not self.Visible then
                self.Root.Visible = false
            end
        end)
    end
end

function Window:Show()
    self:SetVisible(true)
end

function Window:Hide()
    self:SetVisible(false)
end

function Window:Toggle()
    if self.Visible then
        self:Hide()
    else
        self:Show()
    end
end

function Window:IsVisible()
    return self.Visible
end

function Window:SetSize(size)
    self.Size = size

    if self.Visible and not self.Destroyed then
        tween(self.Root, Tweens.Normal, {Size = size})
    end
end

function Window:SetFullscreen(value)
    self.Fullscreen = value == true

    if self.Fullscreen then
        self:SetSize(self:_calculateSize({Fullscreen = true}))
    end

    return self
end

function Window:SetToggleButtonVisible(value)
    if self.FloatingButton then
        self.FloatingButton.Visible = value == true
    end
    return self
end

function Window:SetToggleButtonIcon(icon)
    if self.FloatingIcon then
        self.FloatingIcon.Image = IconSystem:Get(icon)
    end
    return self
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true

    for i = #self.Tabs, 1, -1 do
        pcall(function()
            self.Tabs[i]:Destroy()
        end)
    end
    table.clear(self.Tabs)

    self.Maid:Destroy()

    if self.ScreenGui and self.ScreenGui.Parent then
        self.ScreenGui:Destroy()
    end

    for i = #self.Library.Windows, 1, -1 do
        if self.Library.Windows[i] == self then
            table.remove(self.Library.Windows, i)
            break
        end
    end
end

-- ============================================================
-- LIBRARY
-- ============================================================

local Library = {
    Windows = {},
    ThemeName = "Dark",
    Theme = Themes.Dark,
    Icons = IconSystem,
    Themes = Themes,
}

function Library:Window(config)
    config = config or {}

    if config.Theme and Themes[config.Theme] then
        self:SetTheme(config.Theme)
    end

    local window = Window.new(self, config)
    table.insert(self.Windows, window)

    return window
end

function Library:SetTheme(themeName)
    if not Themes[themeName] then
        return false
    end

    self.ThemeName = themeName
    self.Theme = Themes[themeName]

    for _, window in ipairs(self.Windows) do
        if not window.Destroyed then
            window.Theme = self.Theme

            window.Root.BackgroundColor3 = self.Theme.Background
            window.Sidebar.BackgroundColor3 = self.Theme.Sidebar
            window.Main.BackgroundColor3 = self.Theme.Background

            window.TitleLabel.TextColor3 = self.Theme.Text
            window.SubtitleLabel.TextColor3 = self.Theme.TextMuted
            window.CloseButton.TextColor3 = self.Theme.TextMuted

            if window.FloatingButton then
                window.FloatingButton.BackgroundColor3 = self.Theme.Surface
            end

            if window.FloatingIcon then
                window.FloatingIcon.ImageColor3 = self.Theme.Text
            end

            if window.FloatingStroke then
                window.FloatingStroke.Color = self.Theme.Accent
            end
        end
    end

    return true
end

function Library:GetTheme()
    return self.ThemeName
end

function Library:GetThemeTable()
    return self.Theme
end

function Library:SetIconType(iconType)
    self.Icons:SetType(iconType)
    return self
end

function Library:GetIcon(name)
    return self.Icons:Get(name)
end

function Library:Destroy()
    for i = #self.Windows, 1, -1 do
        pcall(function()
            self.Windows[i]:Destroy()
        end)
    end

    table.clear(self.Windows)
end

-- ============================================================
-- EXPORT
-- ============================================================

return Library
