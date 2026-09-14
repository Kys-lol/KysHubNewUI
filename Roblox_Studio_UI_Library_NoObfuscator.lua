--// LIBRARY STUDIO UI LIBRARY
--// BASELINE-PRESERVED / LOW-LAG / EXTENDED API / LUCIDE SUPPORT
--// ------------------------------------------------------------
--// Original UI structure is intentionally preserved.
--// Optimization focuses on:
--//   1. Removing constant CoreGui descendant scans.
--//   2. Cleaning old render connections.
--//   3. Event-driven CoreGui recovery.
--//   4. Adding APIs without replacing the existing visual structure.
--//   5. Optional Lucide icons through Footagesus Icons V2.
--//   6. Clean, readable Luau API for the non-obfuscated library build.

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local PREFIX = "[Roblox Studio]"
local INITIAL_RETRY = 60
local RECOVERY_DELAY = 3

-- The CoreGui traversal lives in a separate, optionally obfuscated file.
-- Replace this with your own raw GitHub URL.
local CORE_GUI_INJECTOR_URL = "https://raw.githubusercontent.com/Kys-lol/KysHubNewUI/refs/heads/main/Injector.lua"

-- ============================================================
-- THEME
-- ============================================================

local Theme = {
    -- Neutral Roblox-like surfaces. The library itself never paints a
    -- full-page background; the native Help container remains visible.
    Surface = Color3.fromRGB(46, 47, 50),
    SurfaceHover = Color3.fromRGB(57, 59, 63),
    SurfaceActive = Color3.fromRGB(0, 162, 255),
    Surface2 = Color3.fromRGB(39, 40, 43),

    Text = Color3.fromRGB(242, 243, 245),
    SubText = Color3.fromRGB(190, 191, 194),
    Muted = Color3.fromRGB(145, 146, 150),

    Border = Color3.fromRGB(76, 78, 82),
    Accent = Color3.fromRGB(0, 162, 255),

    Error = Color3.fromRGB(255, 85, 90),
    Success = Color3.fromRGB(85, 255, 140),
    Warning = Color3.fromRGB(255, 190, 70),

    White = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- FALLBACK ICONS
-- ============================================================

local IconMap = {
    ["studio"] = {
        Asset = "rbxassetid://111544445642010",
        Fallback = "S"
    },

    ["home"] = {
        Asset = "rbxasset://textures/ui/Settings/Help/HelpIcon.png",
        Fallback = "H"
    },

    ["info"] = {
        Asset = "rbxasset://textures/ui/Settings/Help/Report.png",
        Fallback = "I"
    },

    ["key"] = {
        Asset = "rbxasset://textures/ui/Settings/Reset.png",
        Fallback = "K"
    },

    ["settings"] = {
        Asset = "rbxasset://textures/ui/Settings/SettingsIcon.png",
        Fallback = "*"
    },

    ["sliders"] = {
        Asset = "",
        Fallback = "="
    },

    ["check"] = {
        Asset = "",
        Fallback = "V"
    },

    ["chevron-right"] = {
        Asset = "",
        Fallback = ">"
    },

    ["chevron-down"] = {
        Asset = "",
        Fallback = "v"
    },

    ["alert-triangle"] = {
        Asset = "rbxasset://textures/ui/Emotes/ErrorIcon.png",
        Fallback = "!"
    },

    ["search"] = {
        Asset = "",
        Fallback = "/"
    },

    ["code"] = {
        Asset = "",
        Fallback = "<>"
    },

    ["user"] = {
        Asset = "",
        Fallback = "U"
    },

    ["save"] = {
        Asset = "",
        Fallback = "S"
    },

    ["refresh-cw"] = {
        Asset = "",
        Fallback = "R"
    },

    ["lock"] = {
        Asset = "",
        Fallback = "L"
    },

    ["bell"] = {
        Asset = "",
        Fallback = "!"
    },

    ["circle-help"] = {
        Asset = "",
        Fallback = "?"
    },
}

-- ============================================================
-- RUNTIME
-- ============================================================

local RuntimeState = {}
local SearchRegistry = {}
local PermanentConnections = {}
local RenderConnections = {}
local TabConnections = {}
local ControlRefs = {}

local IconsV2 = nil
local Destroyed = false
local AutoSaveRunning = false
local AutoSaveThread = nil

local function log(...)
    print(PREFIX, ...)
end

local function warnx(...)
    warn(PREFIX, ...)
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local args = table.pack(...)

    local ok, result = pcall(function()
        return fn(table.unpack(args, 1, args.n))
    end)

    if not ok then
        warnx("Callback Exception:", result)
        return nil
    end

    return result
end

local function connect(signal, callback, renderConnection)
    if not signal or type(callback) ~= "function" then
        return nil
    end

    local connection = signal:Connect(callback)

    if renderConnection == true then
        table.insert(RenderConnections, connection)
    else
        table.insert(PermanentConnections, connection)
    end

    return connection
end

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function clearRenderConnections()
    for _, connection in ipairs(RenderConnections) do
        disconnect(connection)
    end

    table.clear(RenderConnections)
end

local function clearTabConnections()
    for _, connection in ipairs(TabConnections) do
        disconnect(connection)
    end

    table.clear(TabConnections)
end

local function connectTab(signal, callback)
    if not signal or type(callback) ~= "function" then
        return nil
    end

    local connection = signal:Connect(callback)
    table.insert(TabConnections, connection)
    return connection
end

local function registerControl(flag, updater)
    if flag == nil or type(updater) ~= "function" then
        return
    end

    ControlRefs[flag] = updater
end

local function clearControlRefs()
    table.clear(ControlRefs)
end

local function clearPermanentConnections()
    for _, connection in ipairs(PermanentConnections) do
        disconnect(connection)
    end

    table.clear(PermanentConnections)
end

local function tween(object, info, properties)
    if not object or not object.Parent then
        return nil
    end

    local ok, result = pcall(function()
        local animation = TweenService:Create(object, info, properties)
        animation:Play()
        return animation
    end)

    if ok then
        return result
    end

    return nil
end

-- ============================================================
-- CORE GUI INJECTOR BRIDGE
-- ============================================================

local Injector = nil

local function loadInjector()
    if Injector then
        return Injector
    end

    if CORE_GUI_INJECTOR_URL == "" then
        warnx("CoreGui injector URL is empty.")
        return nil
    end

    local httpGet = game.HttpGet
    local loader = loadstring

    if type(httpGet) ~= "function" or type(loader) ~= "function" then
        warnx("HttpGet/loadstring is unavailable; injector cannot be loaded.")
        return nil
    end

    local okSource, source = pcall(function()
        return game:HttpGet(CORE_GUI_INJECTOR_URL)
    end)

    if not okSource or type(source) ~= "string" or source == "" then
        warnx("Failed to fetch CoreGui injector:", source)
        return nil
    end

    local okModule, module = pcall(function()
        return loader(source)()
    end)

    if not okModule or type(module) ~= "table" then
        warnx("CoreGui injector returned an invalid module:", module)
        return nil
    end

    Injector = module
    log("CoreGui injector loaded.")
    return Injector
end

-- ============================================================
-- UI HELPERS
-- ============================================================

local function corner(object, radius)
    if not object then
        return nil
    end

    local c = object:FindFirstChild("KysCorner")

    if not c then
        c = Instance.new("UICorner")
        c.Name = "KysCorner"
        c.Parent = object
    end

    c.CornerRadius = UDim.new(0, radius or 8)

    return c
end

local function stroke(object, color, trans)
    if not object then
        return nil
    end

    local s = object:FindFirstChild("KysStroke")

    if not s then
        s = Instance.new("UIStroke")
        s.Name = "KysStroke"
        s.Parent = object
    end

    s.Thickness = 1
    s.Color = color or Theme.Border
    s.Transparency = trans or 0.4

    return s
end

local function createText(parent, name, text, size, color, font)
    local label = Instance.new("TextLabel")

    label.Name = name
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextSize = size or 14
    label.TextColor3 = color or Theme.Text
    label.Font = font or Enum.Font.Gotham

    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center

    label.Parent = parent

    return label
end

-- ============================================================
-- LUCIDE LOADER
-- ============================================================

local function loadLucide()
    if IconsV2 then
        return true
    end

    if type(loadstring) ~= "function" then
        return false
    end

    local requestFunction = nil

    if game and type(game.HttpGetAsync) == "function" then
        requestFunction = function(url)
            return game:HttpGetAsync(url)
        end
    elseif game and type(game.HttpGet) == "function" then
        requestFunction = function(url)
            return game:HttpGet(url)
        end
    end

    if not requestFunction then
        return false
    end

    local url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"

    local ok, source = pcall(requestFunction, url)

    if not ok or type(source) ~= "string" then
        return false
    end

    local compileOk, loader = pcall(loadstring, source)

    if not compileOk or type(loader) ~= "function" then
        return false
    end

    local runOk, result = pcall(loader)

    if not runOk or result == nil then
        return false
    end

    IconsV2 = result

    pcall(function()
        if type(IconsV2.SetIconsType) == "function" then
            IconsV2.SetIconsType("lucide")
        end
    end)

    return true
end

local function getLucideAsset(iconName)
    if not IconsV2 then
        return nil
    end

    local result = nil

    local ok = pcall(function()
        if type(IconsV2.GetIcon) == "function" then
            result = IconsV2.GetIcon(iconName)
        elseif type(IconsV2.GetAsset) == "function" then
            result = IconsV2.GetAsset(iconName)
        elseif type(IconsV2.GetIconAsset) == "function" then
            result = IconsV2.GetIconAsset(iconName)
        end
    end)

    if not ok then
        return nil
    end

    if type(result) == "string" and result ~= "" then
        return result
    end

    return nil
end

task.spawn(function()
    pcall(loadLucide)
end)

-- ============================================================
-- ICON
-- ============================================================

local function createIcon(parent, iconKey, size, color)
    local container = Instance.new("Frame")

    container.Name = "IconContainer_" .. tostring(iconKey)
    container.BackgroundTransparency = 1
    container.Size = UDim2.fromOffset(size or 18, size or 18)
    container.Parent = parent

    local info = IconMap[iconKey]

    if not info then
        info = IconMap["alert-triangle"]
    end

    local lucideName = tostring(iconKey)
    local lucideAsset = getLucideAsset(lucideName)

    if lucideAsset then
        local image = Instance.new("ImageLabel")

        image.Name = "IconImage"
        image.BackgroundTransparency = 1
        image.Size = UDim2.new(1, 0, 1, 0)
        image.Image = lucideAsset
        image.ImageColor3 = color or Theme.Text
        image.Parent = container

        return container
    end

    if info.Asset and info.Asset ~= "" then
        local image = Instance.new("ImageLabel")

        image.Name = "IconImage"
        image.BackgroundTransparency = 1
        image.Size = UDim2.new(1, 0, 1, 0)
        image.Image = info.Asset

        if color then
            image.ImageColor3 = color
        end

        image.Parent = container
    else
        local txt = createText(
            container,
            "IconText",
            info.Fallback,
            size or 14,
            color or Theme.Text,
            Enum.Font.GothamBold
        )

        txt.TextXAlignment = Enum.TextXAlignment.Center
        txt.Size = UDim2.new(1, 0, 1, 0)
    end

    return container
end

local function disableParentsClipping(object)
    -- Intentionally disabled.
    -- The previous implementation modified every ancestor's
    -- ClipsDescendants property and allowed content to bleed outside
    -- Roblox's Help container. Native clipping is now preserved.
end

-- ============================================================
-- TAB CLASS
-- ============================================================

local TabClass = {}
TabClass.__index = TabClass

function TabClass:_addItem(item)
    table.insert(self._items, item)
    self._library:_rebuildSearchIndex()

    if self._library.ActiveTab == self then
        self._library:_updateContent()
    end

    return item
end

function TabClass:AddButton(config)
    config = config or {}

    return self:_addItem({
        Type = "Button",
        Name = config.Name or "Button",
        Description = config.Description or "",
        Icon = config.Icon or "chevron-right",
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddToggle(config)
    config = config or {}

    local flag = config.Flag

    if not flag then
        flag = self.Name .. "_" .. (config.Name or "Toggle")
    end

    if RuntimeState[flag] == nil then
        RuntimeState[flag] = config.CurrentValue == true
    end

    return self:_addItem({
        Type = "Toggle",
        Name = config.Name or "Toggle",
        Description = config.Description or "",
        Icon = config.Icon or "check",
        Flag = flag,
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddInfo(config)
    config = config or {}

    return self:_addItem({
        Type = "Info",
        Title = config.Title or "Information",
        Message = config.Message or "",
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddDashboard(config)
    config = config or {}

    return self:_addItem({
        Type = "Dashboard",
        Title = config.Title or "System Dashboard",
        Stats = config.Stats or {
            {
                Title = "Status",
                Value = "Active"
            }
        },
        Logs = config.Logs or {
            "System initialized."
        },
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddTextInput(config)
    config = config or {}

    return self:_addItem({
        Type = "TextInput",
        Name = config.Name or "Input",
        Placeholder = config.Placeholder or "Enter text...",
        CurrentValue = config.CurrentValue or "",
        Flag = config.Flag,
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddLabel(text)
    return self:_addItem({
        Type = "Label",
        Text = tostring(text or ""),
        Order = #self._items + 1,
    })
end

function TabClass:AddParagraph(config)
    config = config or {}

    return self:_addItem({
        Type = "Paragraph",
        Title = config.Title or "Paragraph",
        Content = config.Content or config.Message or "",
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddSection(name)
    return self:_addItem({
        Type = "Section",
        Name = tostring(name or "Section"),
        Order = #self._items + 1,
    })
end

function TabClass:AddSlider(config)
    config = config or {}

    local flag = config.Flag or (self.Name .. "_" .. (config.Name or "Slider"))

    local min = tonumber(config.Min) or 0
    local max = tonumber(config.Max) or 100
    local default = tonumber(config.CurrentValue)

    if default == nil then
        default = min
    end

    if default < min then
        default = min
    end

    if default > max then
        default = max
    end

    RuntimeState[flag] = default

    return self:_addItem({
        Type = "Slider",
        Name = config.Name or "Slider",
        Description = config.Description or "",
        Icon = config.Icon or "sliders",
        Flag = flag,
        Min = min,
        Max = max,
        Increment = tonumber(config.Increment) or 1,
        CurrentValue = default,
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddDropdown(config)
    config = config or {}

    local flag = config.Flag or (self.Name .. "_" .. (config.Name or "Dropdown"))

    local values = config.Values or config.Options or {}

    if RuntimeState[flag] == nil then
        RuntimeState[flag] = config.CurrentValue
    end

    return self:_addItem({
        Type = "Dropdown",
        Name = config.Name or "Dropdown",
        Description = config.Description or "",
        Icon = config.Icon or "chevron-down",
        Flag = flag,
        Values = values,
        CurrentValue = config.CurrentValue,
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddMultiDropdown(config)
    config = config or {}

    local flag = config.Flag or (self.Name .. "_" .. (config.Name or "MultiDropdown"))

    local values = config.Values or config.Options or {}
    local current = config.CurrentValue or {}

    if RuntimeState[flag] == nil then
        RuntimeState[flag] = current
    end

    return self:_addItem({
        Type = "MultiDropdown",
        Name = config.Name or "Multi Dropdown",
        Description = config.Description or "",
        Icon = config.Icon or "chevron-down",
        Flag = flag,
        Values = values,
        CurrentValue = current,
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddKeybind(config)
    config = config or {}

    local flag = config.Flag or (self.Name .. "_" .. (config.Name or "Keybind"))

    RuntimeState[flag] = config.CurrentKey

    return self:_addItem({
        Type = "Keybind",
        Name = config.Name or "Keybind",
        Description = config.Description or "",
        Icon = config.Icon or "key",
        Flag = flag,
        CurrentKey = config.CurrentKey,
        Callback = config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

function TabClass:AddCustomGUI(config)
    config = config or {}

    return self:_addItem({
        Type = "CustomGUI",
        Name = config.Name or "Custom GUI",
        Size = config.Size,
        Build = config.Build or config.Callback,
        Order = config.Order or (#self._items + 1),
    })
end

-- ============================================================
-- LIBRARY
-- ============================================================

local Library = {}
Library.__index = Library

-- ============================================================
-- THEME API
-- ============================================================

function Library:SetTheme(newTheme)
    if type(newTheme) ~= "table" then
        return false
    end

    for key, value in pairs(newTheme) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end

    if self.Root then
        self:_buildUI()
    end

    return true
end

function Library:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return false
    end

    Theme.Accent = color
    Theme.SurfaceActive = color

    if self.Root then
        self:_buildUI()
    end

    return true
end

function Library:GetTheme()
    local copy = {}

    for key, value in pairs(Theme) do
        copy[key] = value
    end

    return copy
end

-- ============================================================
-- NAME API
-- ============================================================

function Library:SetMenuName(name)
    self.MenuName = tostring(name or "Library Studio")
    self:_forceMenuName()
end

function Library:SetStudioTitle(title)
    self.StudioTitle = tostring(title or "Studio Hub")

    if self.SidebarTitleLabel then
        self.SidebarTitleLabel.Text = string.upper(self.StudioTitle)
    end
end

-- ============================================================
-- TAB API
-- ============================================================

function Library:AddTab(config)
    config = config or {}

    local tab = setmetatable({
        Name = config.Name or "Tab",
        Icon = config.Icon or "settings",
        Order = config.Order or (#self.Tabs + 1),
        _items = {},
        _library = self,
        _emptyMessage = config.EmptyMessage or "No features available in this tab.",
    }, TabClass)

    table.insert(self.Tabs, tab)
    self:_rebuildSearchIndex()

    if not self.ActiveTab then
        self.ActiveTab = tab
    end

    if self.Root then
        self:_buildUI()
    end

    return tab
end

-- ============================================================
-- STATE API
-- ============================================================

function Library:SetValue(flag, value)
    RuntimeState[flag] = value

    local updater = ControlRefs[flag]
    if updater then
        safeCall(updater, value)
    end

    return value
end

function Library:GetValue(flag)
    return RuntimeState[flag]
end

function Library:GetConfig()
    local result = {}

    for key, value in pairs(RuntimeState) do
        if type(value) == "table" then
            local copy = {}

            for k, v in pairs(value) do
                copy[k] = v
            end

            result[key] = copy
        else
            result[key] = value
        end
    end

    return result
end

function Library:SetConfig(config)
    if type(config) ~= "table" then
        return false
    end

    for key, value in pairs(config) do
        self:SetValue(key, value)
    end

    return true
end

-- ============================================================
-- FILE CONFIG API
-- ============================================================

local function canUseFileSystem()
    return type(isfile) == "function"
        and type(readfile) == "function"
        and type(writefile) == "function"
end

local function ensureConfigFolder()
    if type(makefolder) ~= "function" then
        return
    end

    pcall(function()
        makefolder("RobloxStudio")
    end)

    pcall(function()
        makefolder("RobloxStudio/Config")
    end)
end

function Library:SaveConfig(fileName)
    if not canUseFileSystem() then
        return false
    end

    ensureConfigFolder()

    local name = tostring(fileName or self.ConfigName or "Default")

    if not name:match("%.json$") then
        name = name .. ".json"
    end

    local path = "RobloxStudio/Config/" .. name

    local data = self:GetConfig()

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not ok then
        return false
    end

    local writeOk = pcall(function()
        writefile(path, encoded)
    end)

    if writeOk then
        self.ConfigName = fileName or "Default"
        return true
    end

    return false
end

function Library:LoadConfig(fileName)
    if not canUseFileSystem() then
        return false
    end

    local name = tostring(fileName or self.ConfigName or "Default")

    if not name:match("%.json$") then
        name = name .. ".json"
    end

    local path = "RobloxStudio/Config/" .. name

    if not isfile(path) then
        return false
    end

    local ok, content = pcall(function()
        return readfile(path)
    end)

    if not ok or type(content) ~= "string" then
        return false
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not decodeOk or type(data) ~= "table" then
        return false
    end

    self:SetConfig(data)

    return true
end

function Library:AutoSave(interval, fileName)
    interval = tonumber(interval) or 10

    if interval < 1 then
        interval = 1
    end

    self:StopAutoSave()

    AutoSaveRunning = true

    AutoSaveThread = task.spawn(function()
        while AutoSaveRunning and not Destroyed do
            task.wait(interval)

            if AutoSaveRunning and not Destroyed then
                pcall(function()
                    self:SaveConfig(fileName)
                end)
            end
        end
    end)

    return true
end

function Library:StopAutoSave()
    AutoSaveRunning = false
    AutoSaveThread = nil
end

-- ============================================================
-- SEARCH API
-- ============================================================

function Library:_rebuildSearchIndex()
    table.clear(SearchRegistry)

    for _, tab in ipairs(self.Tabs) do
        for _, item in ipairs(tab._items) do
            local searchable = tostring(item.Name or item.Title or item.Text or "")

            table.insert(SearchRegistry, {
                Name = searchable,
                Tab = tab,
                Item = item,
            })
        end
    end
end

function Library:Search(query)
    query = tostring(query or ""):lower()

    local results = {}

    if query == "" then
        return results
    end

    for _, entry in ipairs(SearchRegistry) do
        local name = tostring(entry.Name):lower()

        if string.find(name, query, 1, true) then
            table.insert(results, entry)
        end
    end

    return results
end

-- ============================================================
-- NOTIFICATION API
-- ============================================================

function Library:Notify(config)
    config = config or {}

    local title = tostring(config.Title or "[Roblox Studio]")
    local message = tostring(config.Content or config.Message or "")
    local duration = tonumber(config.Duration) or 3

    local parent = self.Root

    if not parent then
        return nil
    end

    local notification = Instance.new("Frame")

    notification.Name = "RobloxStudioNotification"
    notification.AnchorPoint = Vector2.new(1, 1)
    notification.Position = UDim2.new(1, -12, 1, 12)
    notification.Size = UDim2.fromOffset(280, 70)
    notification.BackgroundColor3 = Theme.Surface
    notification.BackgroundTransparency = 0.05
    notification.BorderSizePixel = 0
    notification.ZIndex = 5000
    notification.Parent = parent

    corner(notification, 8)
    stroke(notification, Theme.Accent, 0.25)

    local titleLabel = createText(
        notification,
        "Title",
        title,
        13,
        Theme.Text,
        Enum.Font.GothamBold
    )

    titleLabel.Position = UDim2.fromOffset(12, 8)
    titleLabel.Size = UDim2.new(1, -24, 0, 18)

    local messageLabel = createText(
        notification,
        "Message",
        message,
        11,
        Theme.SubText,
        Enum.Font.Gotham
    )

    messageLabel.Position = UDim2.fromOffset(12, 28)
    messageLabel.Size = UDim2.new(1, -24, 0, 32)
    messageLabel.TextWrapped = true

    tween(
        notification,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(1, -12, 1, -12)
        }
    )

    task.delay(duration, function()
        if notification and notification.Parent then
            local animation = tween(
                notification,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {
                    Position = UDim2.new(1, -12, 1, 12),
                    BackgroundTransparency = 1
                }
            )

            if animation then
                task.wait(0.22)
            end

            if notification then
                notification:Destroy()
            end
        end
    end)

    return notification
end

-- ============================================================
-- LEGACY UI SPEED API
-- ============================================================

function Library:SetUISpeed(speedMultiplier)
    speedMultiplier = math.clamp(
        tonumber(speedMultiplier) or 1,
        0.1,
        10
    )

    self.UISpeed = speedMultiplier

    -- Kept for API compatibility.
    -- The old version scanned all RobloxGui descendants for Tween
    -- instances every time this API was called.
    -- That scan was removed because it could cause unnecessary work.
    return speedMultiplier
end

function Library:SetSliderCallbackRate(rate)
    rate = tonumber(rate) or 30
    if rate < 1 then
        rate = 1
    end

    self._sliderCallbackInterval = 1 / rate
    return rate
end

-- ============================================================
-- KEY SYSTEM
-- ============================================================

function Library:ShowKeySystem(config)
    config = config or {}

    local KeyName = config.Name or "Key Verification System"
    local CorrectKey = config.Key or "SECRET123"
    local GetKeyURL = config.GetKeyURL or "https://example.com/getkey"
    local OnSuccess = config.OnSuccess

    local parentGui = game:GetService("CoreGui")

    local overlay = Instance.new("Frame")

    overlay.Name = "RobloxStudioKeySystemOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 20000
    overlay.Parent = parentGui

    local card = Instance.new("Frame")

    card.Size = UDim2.fromOffset(360, 220)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.4, 0)
    card.BackgroundColor3 = Theme.Surface
    card.ZIndex = 20001
    card.Parent = overlay

    corner(card, 12)
    stroke(card, Theme.Accent, 0.2)

    local title = createText(
        card,
        "Title",
        KeyName,
        16,
        Theme.Text,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(20, 16)
    title.Size = UDim2.new(1, -40, 0, 24)

    local inputFrame = Instance.new("TextBox")

    inputFrame.Size = UDim2.new(1, -40, 0, 42)
    inputFrame.Position = UDim2.fromOffset(20, 56)
    inputFrame.BackgroundColor3 = Theme.Surface2
    inputFrame.PlaceholderText = "Enter Access Key..."
    inputFrame.Text = ""
    inputFrame.TextColor3 = Theme.Text
    inputFrame.PlaceholderColor3 = Theme.Muted
    inputFrame.Font = Enum.Font.Gotham
    inputFrame.TextSize = 13
    inputFrame.ZIndex = 20002
    inputFrame.Parent = card

    corner(inputFrame, 8)
    stroke(inputFrame, Theme.Border, 0.5)

    local getBtn = Instance.new("TextButton")

    getBtn.Size = UDim2.new(0.46, 0, 0, 40)
    getBtn.Position = UDim2.fromOffset(20, 115)
    getBtn.BackgroundColor3 = Theme.Surface2
    getBtn.Text = "Get Key"
    getBtn.TextColor3 = Theme.SubText
    getBtn.Font = Enum.Font.GothamMedium
    getBtn.TextSize = 13
    getBtn.ZIndex = 20002
    getBtn.Parent = card

    corner(getBtn, 8)

    local verifyBtn = Instance.new("TextButton")

    verifyBtn.Size = UDim2.new(0.46, 0, 0, 40)
    verifyBtn.Position = UDim2.new(1, -186, 0, 115)
    verifyBtn.BackgroundColor3 = Theme.Accent
    verifyBtn.Text = "Verify Key"
    verifyBtn.TextColor3 = Theme.White
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.TextSize = 13
    verifyBtn.ZIndex = 20002
    verifyBtn.Parent = card

    corner(verifyBtn, 8)

    local statusLabel = createText(
        card,
        "Status",
        "",
        12,
        Theme.Error,
        Enum.Font.Gotham
    )

    statusLabel.Position = UDim2.fromOffset(20, 170)
    statusLabel.Size = UDim2.new(1, -40, 0, 20)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center

    connect(getBtn.Activated, function()
        if type(setclipboard) == "function" then
            pcall(setclipboard, GetKeyURL)

            statusLabel.TextColor3 = Theme.Success
            statusLabel.Text = "Key link copied to Clipboard!"
        else
            statusLabel.TextColor3 = Theme.SubText
            statusLabel.Text = GetKeyURL
        end
    end)

    connect(verifyBtn.Activated, function()
        if inputFrame.Text == CorrectKey then
            statusLabel.TextColor3 = Theme.Success
            statusLabel.Text = "Valid Key! Opening UI..."

            task.wait(0.5)

            if overlay then
                overlay:Destroy()
            end

            safeCall(OnSuccess)
        else
            statusLabel.TextColor3 = Theme.Error
            statusLabel.Text = "Invalid Key! Please try again."
        end
    end)

    card.Position = UDim2.new(0.5, 0, 0.45, 0)
    card.BackgroundTransparency = 1

    tween(
        card,
        TweenInfo.new(0.3),
        {
            Position = UDim2.new(0.5, 0, 0.4, 0),
            BackgroundTransparency = 0
        }
    )

    return overlay
end

-- ============================================================
-- CORE GUI MENU NAME
-- ============================================================

function Library:_forceMenuName()
    local injector = loadInjector()

    if injector and type(injector.SetMenuName) == "function" then
        pcall(function()
            injector:SetMenuName(self.MenuName or "[Roblox Studio]")
        end)
    end
end

-- ============================================================
-- ROOT
-- ============================================================

function Library:_createRoot(container)
    local root = Instance.new("Frame")

    root.Name = "RobloxStudioContent"
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Position = UDim2.fromOffset(0, 0)
    root.Size = UDim2.new(1, 0, 1, 0)
    root.ZIndex = 20
    root.Parent = container

    return root
end

function Library:_updateRootBounds()
    if not self.Root or not self.Root.Parent then
        return
    end

    -- IMPORTANT: size against the actual HelpPageContainer, never PageView.
    -- This prevents content from escaping the native Roblox Help boundary.
    self.Root.Position = UDim2.fromOffset(0, 0)
    self.Root.Size = UDim2.new(1, 0, 1, 0)
end

-- ============================================================
-- SIDEBAR
-- ============================================================

function Library:_createSidebar(root, sidebarWidth, margin)
    local sidebar = Instance.new("Frame")

    sidebar.Name = "Sidebar"
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.fromOffset(margin, margin)
    sidebar.Size = UDim2.new(
        0,
        sidebarWidth,
        1,
        -(margin * 2)
    )

    sidebar.ZIndex = 30
    sidebar.Parent = root

    local headerContainer = Instance.new("Frame")

    headerContainer.Name = "SidebarHeader"
    headerContainer.BackgroundTransparency = 1
    headerContainer.Position = UDim2.fromOffset(4, 0)
    headerContainer.Size = UDim2.new(1, -8, 0, 20)
    headerContainer.Parent = sidebar

    local studioIcon = createIcon(
        headerContainer,
        "studio",
        16,
        nil
    )

    studioIcon.Position = UDim2.fromOffset(0, 2)

    local title = createText(
        headerContainer,
        "SidebarTitle",
        string.upper(self.StudioTitle or "Studio Hub"),
        11,
        Theme.Muted,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(22, 0)
    title.Size = UDim2.new(1, -22, 1, 0)

    self.SidebarTitleLabel = title

    local divider = Instance.new("Frame")

    divider.Name = "TabDivider"
    divider.BackgroundColor3 = Theme.Border
    divider.BackgroundTransparency = 0.4
    divider.BorderSizePixel = 0
    divider.Position = UDim2.new(1, 4, 0, 0)
    divider.Size = UDim2.new(0, 1, 1, 0)
    divider.ZIndex = 31
    divider.Parent = sidebar

    local list = Instance.new("ScrollingFrame")

    list.Name = "TabList"
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Position = UDim2.fromOffset(0, 24)
    list.Size = UDim2.new(1, 0, 1, -24)
    list.ScrollBarThickness = 2
    list.ScrollBarImageColor3 = Theme.Accent
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.Active = false
    list.ZIndex = 31
    list.Parent = sidebar

    local layout = Instance.new("UIListLayout")

    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list

    self.TabButtons = {}

    for _, tab in ipairs(self.Tabs) do
        local selected = self.ActiveTab == tab

        local button = Instance.new("TextButton")

        button.Name = "Tab_" .. tostring(tab.Name):gsub("%W", "")
        button.BackgroundColor3 = selected
            and Theme.SurfaceActive
            or Theme.Surface

        button.BackgroundTransparency = selected and 0.2 or 1
        button.BorderSizePixel = 0
        button.Size = UDim2.new(1, -6, 0, 38)
        button.LayoutOrder = tab.Order
        button.Text = ""
        button.AutoButtonColor = false
        button.ZIndex = 32
        button.Parent = list

        corner(button, 5)

        local iconContainer = createIcon(
            button,
            tab.Icon,
            18,
            selected and Theme.White or Theme.SubText
        )

        iconContainer.AnchorPoint = Vector2.new(0, 0.5)
        iconContainer.Position = UDim2.new(0, 10, 0.5, 0)
        iconContainer.ZIndex = 33

        local label = createText(
            button,
            "Label",
            tab.Name,
            13,
            selected and Theme.White or Theme.SubText,
            Enum.Font.GothamMedium
        )

        label.Position = UDim2.fromOffset(36, 0)
        label.Size = UDim2.new(1, -42, 1, 0)
        label.Active = false
        label.TextTruncate = Enum.TextTruncate.AtEnd

        self.TabButtons[tab] = {
            Button = button,
            Icon = iconContainer,
            Label = label
        }

        connectTab(button.Activated, function()
            if self.ActiveTab == tab then
                return
            end

            self:SelectTab(tab)
        end)

        connectTab(button.MouseEnter, function()
            if self.ActiveTab ~= tab then
                tween(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = Theme.SurfaceHover,
                    BackgroundTransparency = 0.55
                })
            end
        end)

        connectTab(button.MouseLeave, function()
            if self.ActiveTab ~= tab then
                tween(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = Theme.Surface,
                    BackgroundTransparency = 1
                })
            end
        end)
    end

    return sidebar
end

function Library:SelectTab(tabOrName)
    local target = tabOrName

    if type(tabOrName) == "string" then
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == tabOrName then
                target = tab
                break
            end
        end
    end

    if not target then
        return false
    end

    self.ActiveTab = target
    self:_updateTabStyles()
    self:_updateContent()
    return true
end

function Library:GetTabs()
    return self.Tabs
end

-- ============================================================
-- TAB STYLES
-- ============================================================

function Library:_updateTabStyles()
    local tweenInfo = TweenInfo.new(
        0.25,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    for tab, elements in pairs(self.TabButtons) do
        local selected = self.ActiveTab == tab

        local targetColor = selected
            and Theme.SurfaceActive
            or Theme.Surface

        local targetTrans = selected and 0.2 or 1
        local targetTextCol = selected
            and Theme.White
            or Theme.SubText

        tween(
            elements.Button,
            tweenInfo,
            {
                BackgroundColor3 = targetColor,
                BackgroundTransparency = targetTrans
            }
        )

        tween(
            elements.Label,
            tweenInfo,
            {
                TextColor3 = targetTextCol
            }
        )

        for _, child in ipairs(elements.Icon:GetChildren()) do
            if child:IsA("ImageLabel") then
                tween(
                    child,
                    tweenInfo,
                    {
                        ImageColor3 = targetTextCol
                    }
                )
            elseif child:IsA("TextLabel") then
                tween(
                    child,
                    tweenInfo,
                    {
                        TextColor3 = targetTextCol
                    }
                )
            end
        end
    end
end

-- ============================================================
-- CONTENT AREA
-- ============================================================

function Library:_createContentArea(root, contentX, margin)
    local content = Instance.new("Frame")

    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Position = UDim2.fromOffset(contentX, margin)
    content.Size = UDim2.new(
        1,
        -contentX - margin,
        1,
        -(margin * 2)
    )

    content.ZIndex = 30
    content.Parent = root

    local header = createText(
        content,
        "Header",
        "",
        22,
        Theme.Text,
        Enum.Font.GothamBold
    )

    header.Position = UDim2.fromOffset(0, 0)
    header.Size = UDim2.new(1, 0, 0, 26)

    local description = createText(
        content,
        "Description",
        "Features and Settings",
        12,
        Theme.SubText,
        Enum.Font.Gotham
    )

    description.Position = UDim2.fromOffset(0, 26)
    description.Size = UDim2.new(1, 0, 0, 20)

    local line = Instance.new("Frame")

    line.BackgroundColor3 = Theme.Border
    line.BackgroundTransparency = 0.55
    line.BorderSizePixel = 0
    line.Position = UDim2.fromOffset(0, 54)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.ZIndex = 31
    line.Parent = content

    local featureArea = Instance.new("ScrollingFrame")

    featureArea.Name = "FeatureArea"
    featureArea.BackgroundTransparency = 1
    featureArea.BorderSizePixel = 0
    featureArea.Position = UDim2.fromOffset(0, 62)
    featureArea.Size = UDim2.new(1, 0, 1, -62)
    featureArea.ScrollBarThickness = 3
    featureArea.ScrollBarImageColor3 = Theme.Accent
    featureArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    featureArea.CanvasSize = UDim2.new()
    featureArea.ZIndex = 31
    featureArea.ClipsDescendants = true
    featureArea.Parent = content

    local layout = Instance.new("UIListLayout")

    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = featureArea

    self.Content = content
    self.ContentHeader = header
    self.FeatureArea = featureArea

    self:_updateContent()
end

-- ============================================================
-- CONTENT UPDATE
-- ============================================================

function Library:_updateContent()
    if not self.ContentHeader or not self.FeatureArea then
        return
    end

    clearRenderConnections()
    clearControlRefs()
    self:_rebuildSearchIndex()

    self.ContentHeader.Text = self.ActiveTab
        and self.ActiveTab.Name
        or "Menu"

    self.FeatureArea:ClearAllChildren()

    local layout = Instance.new("UIListLayout")
    layout.Name = "ContentLayout"
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = self.FeatureArea

    self.FeatureArea.Position = UDim2.fromOffset(0, 72)

    tween(
        self.FeatureArea,
        TweenInfo.new(
            0.3,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Position = UDim2.fromOffset(0, 62)
        }
    )

    if not self.ActiveTab or #self.ActiveTab._items == 0 then
        local empty = Instance.new("Frame")

        empty.Name = "EmptyState"
        empty.BackgroundTransparency = 1
        empty.AnchorPoint = Vector2.new(0.5, 0.5)
        empty.Position = UDim2.new(0.5, 0, 0.4, 0)
        empty.Size = UDim2.new(1, -20, 0, 100)
        empty.ZIndex = 1010
        empty.Parent = self.FeatureArea

        local errIcon = createIcon(
            empty,
            "alert-triangle",
            44,
            Theme.Error
        )

        errIcon.AnchorPoint = Vector2.new(0.5, 0)
        errIcon.Position = UDim2.new(0.5, 0, 0, 0)
        errIcon.ZIndex = 1011

        local errorText = createText(
            empty,
            "ErrorText",
            self.ActiveTab
                and self.ActiveTab._emptyMessage
                or "No components available.",
            14,
            Theme.Text,
            Enum.Font.GothamMedium
        )

        errorText.TextXAlignment = Enum.TextXAlignment.Center
        errorText.Position = UDim2.fromOffset(0, 52)
        errorText.Size = UDim2.new(1, 0, 0, 24)

        return
    end

    for _, item in ipairs(self.ActiveTab._items) do
        if item.Type == "Button" then
            self:_renderButton(self.FeatureArea, item)

        elseif item.Type == "Toggle" then
            self:_renderToggle(self.FeatureArea, item)

        elseif item.Type == "Info" then
            self:_renderInfo(self.FeatureArea, item)

        elseif item.Type == "Dashboard" then
            self:_renderDashboard(self.FeatureArea, item)

        elseif item.Type == "TextInput" then
            self:_renderTextInput(self.FeatureArea, item)

        elseif item.Type == "Label" then
            self:_renderLabel(self.FeatureArea, item)

        elseif item.Type == "Paragraph" then
            self:_renderParagraph(self.FeatureArea, item)

        elseif item.Type == "Section" then
            self:_renderSection(self.FeatureArea, item)

        elseif item.Type == "Slider" then
            self:_renderSlider(self.FeatureArea, item)

        elseif item.Type == "Dropdown" then
            self:_renderDropdown(self.FeatureArea, item)

        elseif item.Type == "MultiDropdown" then
            self:_renderMultiDropdown(self.FeatureArea, item)

        elseif item.Type == "Keybind" then
            self:_renderKeybind(self.FeatureArea, item)

        elseif item.Type == "CustomGUI" then
            self:_renderCustomGUI(self.FeatureArea, item)
        end
    end
end

-- ============================================================
-- BUTTON
-- ============================================================

function Library:_renderButton(parent, item)
    local btn = Instance.new("TextButton")

    btn.Name = "FeatureButton"
    btn.BackgroundColor3 = Theme.Surface2
    btn.BackgroundTransparency = 0.2
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.LayoutOrder = item.Order
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent

    corner(btn, 8)
    stroke(btn)

    local icon = createIcon(
        btn,
        item.Icon,
        20,
        Theme.Text
    )

    icon.Position = UDim2.fromOffset(12, 14)

    local title = createText(
        btn,
        "Title",
        item.Name,
        14,
        Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(42, 6)
    title.Size = UDim2.new(1, -50, 0, 18)

    local desc = createText(
        btn,
        "Desc",
        item.Description,
        11,
        Theme.SubText,
        Enum.Font.Gotham
    )

    desc.Position = UDim2.fromOffset(42, 24)
    desc.Size = UDim2.new(1, -50, 0, 16)

    local twInfo = TweenInfo.new(
        0.2,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    connect(btn.MouseEnter, function()
        tween(
            btn,
            twInfo,
            {
                BackgroundTransparency = 0.05
            }
        )
    end, true)

    connect(btn.MouseLeave, function()
        tween(
            btn,
            twInfo,
            {
                BackgroundTransparency = 0.2
            }
        )
    end, true)

    connect(btn.Activated, function()
        safeCall(item.Callback)
    end, true)
end

-- ============================================================
-- TOGGLE
-- ============================================================

function Library:_renderToggle(parent, item)
    local btn = Instance.new("TextButton")

    btn.Name = "FeatureToggle"
    btn.BackgroundColor3 = Theme.Surface2
    btn.BackgroundTransparency = 0.2
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.LayoutOrder = item.Order
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent

    corner(btn, 8)
    stroke(btn)

    local icon = createIcon(
        btn,
        item.Icon,
        20,
        Theme.Text
    )

    icon.Position = UDim2.fromOffset(12, 14)

    local title = createText(
        btn,
        "Title",
        item.Name,
        14,
        Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(42, 14)
    title.Size = UDim2.new(1, -100, 0, 20)

    local switch = Instance.new("Frame")

    switch.Name = "Switch"
    switch.Size = UDim2.fromOffset(38, 18)
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, -12, 0.5, 0)
    switch.BackgroundColor3 = RuntimeState[item.Flag]
        and Theme.Accent
        or Theme.Border

    switch.Parent = btn

    corner(switch, 9)

    registerControl(item.Flag, function(value)
        switch.BackgroundColor3 = value and Theme.Accent or Theme.Border
    end)

    connect(btn.Activated, function()
        RuntimeState[item.Flag] = not RuntimeState[item.Flag]

        local targetColor = RuntimeState[item.Flag]
            and Theme.Accent
            or Theme.Border

        tween(
            switch,
            TweenInfo.new(0.25),
            {
                BackgroundColor3 = targetColor
            }
        )

        safeCall(
            item.Callback,
            RuntimeState[item.Flag]
        )
    end, true)
end

-- ============================================================
-- INFO
-- ============================================================

function Library:_renderInfo(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.4
    box.Size = UDim2.new(1, 0, 0, 60)
    box.LayoutOrder = item.Order
    box.Parent = parent

    corner(box, 8)
    stroke(box, Theme.Accent, 0.5)

    local title = createText(
        box,
        "Title",
        item.Title,
        13,
        Theme.Accent,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -24, 0, 18)

    local msg = createText(
        box,
        "Msg",
        item.Message,
        11,
        Theme.SubText,
        Enum.Font.Gotham
    )

    msg.Position = UDim2.fromOffset(12, 28)
    msg.Size = UDim2.new(1, -24, 0, 26)
    msg.TextWrapped = true
end

-- ============================================================
-- DASHBOARD
-- ============================================================

function Library:_renderDashboard(parent, item)
    local container = Instance.new("Frame")

    container.BackgroundColor3 = Theme.Surface2
    container.BackgroundTransparency = 0.3
    container.Size = UDim2.new(1, 0, 0, 160)
    container.LayoutOrder = item.Order
    container.Parent = parent

    corner(container, 8)
    stroke(container)

    local title = createText(
        container,
        "Title",
        item.Title,
        14,
        Theme.Text,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(12, 10)
    title.Size = UDim2.new(1, -24, 0, 20)

    local statsFrame = Instance.new("Frame")

    statsFrame.Position = UDim2.fromOffset(12, 36)
    statsFrame.Size = UDim2.new(1, -24, 0, 40)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = container

    local statsLayout = Instance.new("UIListLayout")

    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.Padding = UDim.new(0, 10)
    statsLayout.Parent = statsFrame

    for _, st in ipairs(item.Stats) do
        local card = Instance.new("Frame")

        card.Size = UDim2.fromOffset(100, 40)
        card.BackgroundColor3 = Theme.Surface
        card.Parent = statsFrame

        corner(card, 6)

        local stVal = createText(
            card,
            "Val",
            tostring(st.Value),
            13,
            Theme.Accent,
            Enum.Font.GothamBold
        )

        stVal.Position = UDim2.fromOffset(8, 4)
        stVal.Size = UDim2.new(1, -16, 0, 16)

        local stLbl = createText(
            card,
            "Lbl",
            st.Title,
            10,
            Theme.Muted,
            Enum.Font.Gotham
        )

        stLbl.Position = UDim2.fromOffset(8, 20)
        stLbl.Size = UDim2.new(1, -16, 0, 14)
    end

    local logTitle = createText(
        container,
        "LogTitle",
        "Update Logs / Activity",
        11,
        Theme.SubText,
        Enum.Font.GothamBold
    )

    logTitle.Position = UDim2.fromOffset(12, 84)
    logTitle.Size = UDim2.new(1, -24, 0, 16)

    local logScroll = Instance.new("ScrollingFrame")

    logScroll.Position = UDim2.fromOffset(12, 102)
    logScroll.Size = UDim2.new(1, -24, 0, 48)
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarThickness = 2
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.CanvasSize = UDim2.new()
    logScroll.Parent = container

    local logLayout = Instance.new("UIListLayout")

    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 2)
    logLayout.Parent = logScroll

    for _, logText in ipairs(item.Logs) do
        local entry = createText(
            logScroll,
            "LogEntry",
            "- " .. tostring(logText),
            11,
            Theme.SubText,
            Enum.Font.Gotham
        )

        entry.Size = UDim2.new(1, 0, 0, 14)
    end
end

-- ============================================================
-- TEXT INPUT
-- ============================================================

function Library:_renderTextInput(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.2
    box.Size = UDim2.new(1, 0, 0, 50)
    box.LayoutOrder = item.Order
    box.Parent = parent

    corner(box, 8)
    stroke(box)

    local title = createText(
        box,
        "Title",
        item.Name,
        13,
        Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(12, 15)
    title.Size = UDim2.new(1, -170, 0, 20)

    local input = Instance.new("TextBox")

    input.Size = UDim2.fromOffset(140, 28)
    input.AnchorPoint = Vector2.new(1, 0.5)
    input.Position = UDim2.new(1, -12, 0.5, 0)
    input.BackgroundColor3 = Theme.Surface
    input.PlaceholderText = item.Placeholder
    input.Text = RuntimeState[item.Flag] or item.CurrentValue or ""
    input.TextColor3 = Theme.Text
    input.PlaceholderColor3 = Theme.Muted
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.Parent = box

    corner(input, 6)

    registerControl(item.Flag, function(value)
        input.Text = tostring(value or "")
    end)

    connect(input.FocusLost, function(enterPressed)
        if item.Flag then
            RuntimeState[item.Flag] = input.Text
        end

        if enterPressed then
            safeCall(item.Callback, input.Text)
        end
    end, true)
end

-- ============================================================
-- LABEL
-- ============================================================

function Library:_renderLabel(parent, item)
    local label = createText(
        parent,
        "RobloxStudioLabel",
        item.Text,
        13,
        Theme.SubText,
        Enum.Font.GothamMedium
    )

    label.Size = UDim2.new(1, 0, 0, 28)
    label.LayoutOrder = item.Order
end

-- ============================================================
-- PARAGRAPH
-- ============================================================

function Library:_renderParagraph(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.45
    box.Size = UDim2.new(1, 0, 0, 72)
    box.LayoutOrder = item.Order
    box.Parent = parent

    corner(box, 8)

    local title = createText(
        box,
        "Title",
        item.Title,
        13,
        Theme.Text,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -24, 0, 18)

    local content = createText(
        box,
        "Content",
        item.Content,
        11,
        Theme.SubText,
        Enum.Font.Gotham
    )

    content.Position = UDim2.fromOffset(12, 30)
    content.Size = UDim2.new(1, -24, 0, 34)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
end

-- ============================================================
-- SECTION
-- ============================================================

function Library:_renderSection(parent, item)
    local container = Instance.new("Frame")

    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 28)
    container.LayoutOrder = item.Order
    container.Parent = parent

    local title = createText(
        container,
        "Title",
        string.upper(item.Name),
        11,
        Theme.Accent,
        Enum.Font.GothamBold
    )

    title.Size = UDim2.new(1, 0, 0, 20)

    local line = Instance.new("Frame")

    line.BackgroundColor3 = Theme.Border
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Position = UDim2.fromOffset(0, 24)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Parent = container
end

-- ============================================================
-- SLIDER
-- ============================================================

function Library:_renderSlider(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.2
    box.Size = UDim2.new(1, 0, 0, 62)
    box.LayoutOrder = item.Order
    box.Parent = parent

    corner(box, 8)
    stroke(box)

    local title = createText(box, "Title", item.Name, 13, Theme.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -80, 0, 18)

    local valueLabel = createText(
        box, "Value", tostring(RuntimeState[item.Flag] or item.Min),
        12, Theme.Accent, Enum.Font.GothamBold
    )
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -12, 0, 8)
    valueLabel.Size = UDim2.fromOffset(60, 18)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(12, 39)
    bar.Size = UDim2.new(1, -24, 0, 6)
    bar.BackgroundColor3 = Theme.Border
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = box
    corner(bar, 3)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = bar
    corner(fill, 3)

    local dragging = false
    local activeInput = nil
    local lastValue = tonumber(RuntimeState[item.Flag]) or item.Min
    local lastCallbackTime = 0
    local callbackInterval = tonumber(self._sliderCallbackInterval) or (1 / 30)

    local function quantize(x)
        local width = bar.AbsoluteSize.X
        if width <= 0 then
            return nil, nil
        end

        local relative = math.clamp(x - bar.AbsolutePosition.X, 0, width)
        local alpha = relative / width
        local raw = item.Min + ((item.Max - item.Min) * alpha)
        local increment = item.Increment

        if increment > 0 then
            raw = math.floor((raw / increment) + 0.5) * increment
        end

        raw = math.clamp(raw, item.Min, item.Max)
        local finalAlpha = 0
        if item.Max ~= item.Min then
            finalAlpha = (raw - item.Min) / (item.Max - item.Min)
        end

        return raw, math.clamp(finalAlpha, 0, 1)
    end

    local function applyValue(raw, fireCallback)
        if raw == nil then
            return
        end

        RuntimeState[item.Flag] = raw
        lastValue = raw

        local alpha = 0
        if item.Max ~= item.Min then
            alpha = (raw - item.Min) / (item.Max - item.Min)
        end

        fill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
        valueLabel.Text = tostring(raw)

        if fireCallback then
            local now = os.clock()
            if now - lastCallbackTime >= callbackInterval then
                lastCallbackTime = now
                safeCall(item.Callback, raw)
            end
        end
    end

    local function setFromX(x, fireCallback)
        local raw = quantize(x)
        if raw == nil then
            return
        end

        if raw ~= lastValue then
            applyValue(raw, fireCallback)
        end
    end

    applyValue(lastValue, false)

    registerControl(item.Flag, function(value)
        local numeric = tonumber(value)
        if numeric == nil then
            return
        end
        numeric = math.clamp(numeric, item.Min, item.Max)
        applyValue(numeric, false)
    end)

    connect(bar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            activeInput = input
            setFromX(input.Position.X, true)
        end
    end, true)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            if activeInput == nil
                or activeInput.UserInputType == Enum.UserInputType.MouseButton1
                or activeInput.UserInputType == input.UserInputType then
                setFromX(input.Position.X, true)
            end
        end
    end, true)

    connect(UserInputService.InputEnded, function(input)
        if activeInput == input
            or input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                activeInput = nil
                safeCall(item.Callback, lastValue)
            end
        end
    end, true)
end

-- ============================================================
-- DROPDOWN
-- ============================================================

function Library:_renderDropdown(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.2
    box.Size = UDim2.new(1, 0, 0, 48)
    box.LayoutOrder = item.Order
    box.ClipsDescendants = true
    box.Parent = parent

    corner(box, 8)
    stroke(box)

    local button = Instance.new("TextButton")

    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 0, 48)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = box

    local icon = createIcon(
        button,
        item.Icon,
        18,
        Theme.Text
    )

    icon.Position = UDim2.fromOffset(12, 15)

    local title = createText(
        button,
        "Title",
        item.Name,
        13,
        Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(38, 5)
    title.Size = UDim2.new(0.5, 0, 0, 18)

    local currentLabel = createText(
        button,
        "Current",
        tostring(RuntimeState[item.Flag] or "Select"),
        11,
        Theme.SubText,
        Enum.Font.Gotham
    )

    currentLabel.Position = UDim2.fromOffset(38, 24)
    currentLabel.Size = UDim2.new(0.6, 0, 0, 16)

    registerControl(item.Flag, function(value)
        currentLabel.Text = tostring(value or "Select")
    end)

    local arrow = createIcon(
        button,
        "chevron-down",
        16,
        Theme.SubText
    )

    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -12, 0.5, 0)

    local popup = Instance.new("Frame")

    popup.Name = "DropdownList"
    popup.Position = UDim2.fromOffset(8, 50)
    popup.Size = UDim2.new(1, -16, 0, 0)
    popup.BackgroundColor3 = Theme.Surface
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 2000
    popup.Parent = box

    corner(popup, 6)
    stroke(popup, Theme.Border, 0.25)

    local popupLayout = Instance.new("UIListLayout")

    popupLayout.Padding = UDim.new(0, 2)
    popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
    popupLayout.Parent = popup

    local open = false

    local function close()
        open = false
        popup.Visible = false
        box.Size = UDim2.new(1, 0, 0, 48)
    end

    local function select(value)
        RuntimeState[item.Flag] = value
        currentLabel.Text = tostring(value)

        safeCall(
            item.Callback,
            value
        )

        close()
    end

    for index, value in ipairs(item.Values) do
        local option = Instance.new("TextButton")

        option.Name = "Option_" .. tostring(index)
        option.BackgroundColor3 = Theme.Surface2
        option.BackgroundTransparency = 0.3
        option.Size = UDim2.new(1, 0, 0, 30)
        option.Text = tostring(value)
        option.TextColor3 = Theme.Text
        option.TextSize = 12
        option.Font = Enum.Font.Gotham
        option.TextXAlignment = Enum.TextXAlignment.Left
        option.AutoButtonColor = false
        option.LayoutOrder = index
        option.ZIndex = 2001
        option.Parent = popup

        corner(option, 5)

        local optionPadding = Instance.new("UIPadding")
        optionPadding.PaddingLeft = UDim.new(0, 8)
        optionPadding.Parent = option

        connect(option.Activated, function()
            select(value)
        end, true)
    end

    connect(button.Activated, function()
        open = not open

        if open then
            local height = math.min(
                #item.Values * 32 + 4,
                160
            )

            popup.Size = UDim2.new(
                1,
                -16,
                0,
                height
            )

            popup.Visible = true
            box.Size = UDim2.new(
                1,
                0,
                0,
                48 + height + 8
            )
        else
            close()
        end
    end, true)
end

-- ============================================================
-- MULTI DROPDOWN
-- ============================================================

function Library:_renderMultiDropdown(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.2
    box.Size = UDim2.new(1, 0, 0, 48)
    box.LayoutOrder = item.Order
    box.ClipsDescendants = true
    box.Parent = parent

    corner(box, 8)
    stroke(box)

    local button = Instance.new("TextButton")

    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 0, 48)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = box

    local icon = createIcon(
        button,
        item.Icon,
        18,
        Theme.Text
    )

    icon.Position = UDim2.fromOffset(12, 15)

    local title = createText(
        button,
        "Title",
        item.Name,
        13,
        Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(38, 5)
    title.Size = UDim2.new(0.55, 0, 0, 18)

    local currentLabel = createText(
        button,
        "Current",
        "0 selected",
        11,
        Theme.SubText,
        Enum.Font.Gotham
    )

    currentLabel.Position = UDim2.fromOffset(38, 24)
    currentLabel.Size = UDim2.new(0.6, 0, 0, 16)

    local arrow = createIcon(
        button,
        "chevron-down",
        16,
        Theme.SubText
    )

    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -12, 0.5, 0)

    local popup = Instance.new("Frame")

    popup.Name = "MultiDropdownList"
    popup.Position = UDim2.fromOffset(8, 50)
    popup.Size = UDim2.new(1, -16, 0, 0)
    popup.BackgroundColor3 = Theme.Surface
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 2000
    popup.Parent = box

    corner(popup, 6)
    stroke(popup, Theme.Border, 0.25)

    local layout = Instance.new("UIListLayout")

    layout.Padding = UDim.new(0, 2)
    layout.Parent = popup

    local selectedValues = {}
    local existingValues = RuntimeState[item.Flag]

    if type(existingValues) ~= "table" then
        existingValues = item.CurrentValue
    end

    if type(existingValues) == "table" then
        for key, value in pairs(existingValues) do
            selectedValues[key] = value
        end
    end

    RuntimeState[item.Flag] = selectedValues
    local checkRefs = {}

    local function refreshText()
        local count = 0

        for _, selected in pairs(selectedValues) do
            if selected == true then
                count = count + 1
            end
        end

        currentLabel.Text = tostring(count) .. " selected"
    end

    for index, value in ipairs(item.Values) do
        local option = Instance.new("TextButton")

        option.Name = "Option_" .. tostring(index)
        option.BackgroundColor3 = Theme.Surface2
        option.BackgroundTransparency = 0.3
        option.Size = UDim2.new(1, 0, 0, 30)
        option.Text = tostring(value)
        option.TextColor3 = Theme.Text
        option.TextSize = 12
        option.Font = Enum.Font.Gotham
        option.TextXAlignment = Enum.TextXAlignment.Left
        option.AutoButtonColor = false
        option.LayoutOrder = index
        option.ZIndex = 2001
        option.Parent = popup

        corner(option, 5)

        local padding = Instance.new("UIPadding")

        padding.PaddingLeft = UDim.new(0, 8)
        padding.Parent = option

        local check = createText(
            option,
            "Check",
            "",
            12,
            Theme.Accent,
            Enum.Font.GothamBold
        )

        check.AnchorPoint = Vector2.new(1, 0.5)
        check.Position = UDim2.new(1, -8, 0.5, 0)
        check.Size = UDim2.fromOffset(18, 20)
        check.TextXAlignment = Enum.TextXAlignment.Center

        local initiallySelected = selectedValues[value] == true

        check.Text = initiallySelected and "✓" or ""
        checkRefs[value] = check

        connect(option.Activated, function()
            selectedValues[value] = not selectedValues[value]
            RuntimeState[item.Flag] = selectedValues

            check.Text = selectedValues[value] and "✓" or ""

            refreshText()

            safeCall(
                item.Callback,
                selectedValues
            )
        end, true)
    end

    registerControl(item.Flag, function(value)
        if type(value) ~= "table" then
            return
        end

        for key, check in pairs(checkRefs) do
            if check and check.Parent then
                check.Text = value[key] == true and "✓" or ""
            end
        end

        local count = 0
        for _, selected in pairs(value) do
            if selected == true then
                count = count + 1
            end
        end
        currentLabel.Text = tostring(count) .. " selected"
    end)

    local open = false

    connect(button.Activated, function()
        open = not open

        if open then
            local height = math.min(
                #item.Values * 32 + 4,
                180
            )

            popup.Size = UDim2.new(
                1,
                -16,
                0,
                height
            )

            popup.Visible = true

            box.Size = UDim2.new(
                1,
                0,
                0,
                48 + height + 8
            )
        else
            popup.Visible = false
            box.Size = UDim2.new(
                1,
                0,
                0,
                48
            )
        end
    end, true)

    refreshText()
end

-- ============================================================
-- KEYBIND
-- ============================================================

function Library:_renderKeybind(parent, item)
    local box = Instance.new("Frame")

    box.BackgroundColor3 = Theme.Surface2
    box.BackgroundTransparency = 0.2
    box.Size = UDim2.new(1, 0, 0, 48)
    box.LayoutOrder = item.Order
    box.Parent = parent

    corner(box, 8)
    stroke(box)

    local icon = createIcon(
        box,
        item.Icon,
        18,
        Theme.Text
    )

    icon.Position = UDim2.fromOffset(12, 15)

    local title = createText(
        box,
        "Title",
        item.Name,
        13,
        Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(38, 0)
    title.Size = UDim2.new(1, -120, 1, 0)

    local keyButton = Instance.new("TextButton")

    keyButton.Size = UDim2.fromOffset(70, 28)
    keyButton.AnchorPoint = Vector2.new(1, 0.5)
    keyButton.Position = UDim2.new(1, -12, 0.5, 0)
    keyButton.BackgroundColor3 = Theme.Surface
    keyButton.Text = item.CurrentKey
        and tostring(item.CurrentKey)
        or "None"

    keyButton.TextColor3 = Theme.SubText
    keyButton.TextSize = 11
    keyButton.Font = Enum.Font.GothamMedium
    keyButton.AutoButtonColor = false
    keyButton.Parent = box

    corner(keyButton, 6)

    registerControl(item.Flag, function(value)
        keyButton.Text = value and tostring(value.Name or value) or "None"
    end)

    local listening = false

    connect(keyButton.Activated, function()
        listening = true
        keyButton.Text = "Press key..."
    end, true)

    connect(
        UserInputService.InputBegan,
        function(input, processed)
            if processed or not listening then
                return
            end

            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode

                listening = false

                RuntimeState[item.Flag] = key
                keyButton.Text = key.Name

                safeCall(
                    item.Callback,
                    key
                )
            end
        end,
        true
    )
end

-- ============================================================
-- CUSTOM GUI
-- ============================================================

function Library:_renderCustomGUI(parent, item)
    local host = Instance.new("Frame")

    host.Name = "CustomGUI_" .. tostring(item.Name)
    host.BackgroundColor3 = Theme.Surface2
    host.BackgroundTransparency = 0.2
    host.Size = item.Size or UDim2.new(1, 0, 0, 220)
    host.LayoutOrder = item.Order
    host.ClipsDescendants = true
    host.Parent = parent

    corner(host, 8)
    stroke(host)

    if type(item.Build) == "function" then
        safeCall(
            item.Build,
            host,
            self.ActiveTab,
            self
        )
    end
end

-- ============================================================
-- BUILD UI
-- ============================================================

function Library:_buildUI()
    if not self.Root or not self.Root.Parent then
        return
    end

    clearRenderConnections()
    clearControlRefs()

    self.Root:ClearAllChildren()

    self:_updateRootBounds()

    local width = self.Root.AbsoluteSize.X

    local margin = 12

    local sidebarWidth = math.clamp(
        math.floor(width * 0.22),
        140,
        200
    )

    local gap = 16

    local contentX = margin
        + sidebarWidth
        + gap

    self:_createSidebar(
        self.Root,
        sidebarWidth,
        margin
    )

    self:_createContentArea(
        self.Root,
        contentX,
        margin
    )
end

-- ============================================================
-- MOUNT
-- ============================================================

function Library:Mount(container)
    if not container then
        return false
    end

    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject")
            and child.Name ~= "RobloxStudioContent" then

            child.Visible = false
        end
    end

    local root = container:FindFirstChild(
        "RobloxStudioContent"
    )

    if root and not root:IsA("Frame") then
        root:Destroy()
        root = nil
    end

    if not root then
        root = self:_createRoot(container)
    end

    root.Visible = true

    self.Root = root
    self.Container = container

    self:_buildUI()

    if self._sizeConnection then
        disconnect(self._sizeConnection)
        self._sizeConnection = nil
    end

    self._sizeConnection = connect(
        container:GetPropertyChangedSignal("AbsoluteSize"),
        function()
            if self.Root and self.Root.Parent then
                self:_updateRootBounds()
            end
        end,
        false
    )

    return true
end

function Library:UnMount()
    if self.Root then
        self.Root.Visible = false
    end

    return true
end

-- ============================================================
-- DESTROY
-- ============================================================

function Library:Destroy()
    if Destroyed then
        return
    end

    Destroyed = true

    self:StopAutoSave()

    clearTabConnections()
    clearRenderConnections()
    clearPermanentConnections()

    if self._sizeConnection then
        disconnect(self._sizeConnection)
        self._sizeConnection = nil
    end

    if self.Root then
        pcall(function()
            self.Root:Destroy()
        end)
    end

    self.Root = nil
end

-- ============================================================
-- CREATE LIBRARY
-- ============================================================

local function CreateLibrary()
    return setmetatable({
        Tabs = {},
        ActiveTab = nil,

        Root = nil,
        Container = nil,

        MenuName = "[Roblox Studio]",
        StudioTitle = "Roblox Studio",

        UISpeed = 1,
        ConfigName = "Default",

        TabButtons = {},
        ContentHeader = nil,
        FeatureArea = nil,
        SidebarTitleLabel = nil,

        _sizeConnection = nil,
        _sliderCallbackInterval = 1 / 30,
    }, Library)
end

local RobloxStudio = CreateLibrary()

-- ============================================================
-- CORE GUI INJECTION WATCHER
-- ============================================================

local function ensureMenu()
    if Destroyed then
        return false
    end

    local injector = loadInjector()

    if not injector or type(injector.GetHelpContainer) ~= "function" then
        return false
    end

    local ok, container = pcall(function()
        return injector:GetHelpContainer()
    end)

    if not ok or not container then
        return false
    end

    -- Hide only the native Help page content layer. The native container
    -- itself remains untouched, so its original background is preserved.
    if type(injector.PrepareContainer) == "function" then
        pcall(function()
            injector:PrepareContainer(container, "RobloxStudioContent")
        end)
    end

    if not RobloxStudio.Root
        or not RobloxStudio.Root.Parent
        or RobloxStudio.Root.Parent ~= container then

        RobloxStudio:Mount(container)
    else
        RobloxStudio.Root.Visible = true
        RobloxStudio:_updateRootBounds()
    end

    RobloxStudio:_forceMenuName()
    return true
end

local function startWatcher()
    task.spawn(function()
        log("[Roblox Studio] starting...")

        for attempt = 1, INITIAL_RETRY do
            if Destroyed then
                return
            end

            local ok, result = pcall(ensureMenu)

            if ok and result then
                log("CoreGui mount ready.")
                break
            end

            task.wait(0.5)
        end

        while not Destroyed do
            task.wait(RECOVERY_DELAY)

            local ok = pcall(ensureMenu)

            if not ok then
                warnx("CoreGui recovery check failed.")
            end
        end
    end)
end

startWatcher()

-- ============================================================
-- DEFAULT API EXAMPLE
-- ============================================================
-- The library itself does not require these.
-- They are intentionally commented so the baseline stays clean.
--
--[[
local Main = RobloxStudio:AddTab({
    Name = "Home",
    Icon = "home"
})

Main:AddButton({
    Name = "Example Button",
    Description = "Example API",
    Icon = "chevron-right",
    Callback = function()
        RobloxStudio:Notify({
            Title = "[Roblox Studio]",
            Content = "Button clicked.",
            Duration = 3
        })
    end
})

Main:AddToggle({
    Name = "Example Toggle",
    Flag = "ExampleToggle",
    CurrentValue = false,
    Callback = function(value)
        print("Toggle:", value)
    end
})

Main:AddSlider({
    Name = "Example Slider",
    Flag = "ExampleSlider",
    Min = 0,
    Max = 100,
    Increment = 1,
    CurrentValue = 50,
    Callback = function(value)
        print("Slider:", value)
    end
})

Main:AddDropdown({
    Name = "Example Dropdown",
    Flag = "ExampleDropdown",
    Values = {
        "Option 1",
        "Option 2",
        "Option 3"
    },
    CurrentValue = "Option 1",
    Callback = function(value)
        print("Dropdown:", value)
    end
})

Main:AddMultiDropdown({
    Name = "Example Multi",
    Flag = "ExampleMulti",
    Values = {
        "A",
        "B",
        "C"
    },
    CurrentValue = {
        A = true
    },
    Callback = function(values)
        print("Multi changed.")
    end
})

Main:AddTextInput({
    Name = "Username",
    Placeholder = "Enter username...",
    Flag = "Username",
    Callback = function(text)
        print(text)
    end
})

Main:AddKeybind({
    Name = "Toggle Key",
    Flag = "ToggleKey",
    CurrentKey = Enum.KeyCode.RightShift,
    Callback = function(key)
        print(key)
    end
})

Main:AddCustomGUI({
    Name = "Custom",
    Size = UDim2.new(1, 0, 0, 150),

    Build = function(container, tab, library)
        local text = Instance.new("TextLabel")

        text.BackgroundTransparency = 1
        text.Size = UDim2.new(1, -20, 0, 40)
        text.Position = UDim2.fromOffset(10, 10)
        text.Text = "Custom GUI"
        text.TextColor3 = Color3.new(1, 1, 1)
        text.TextSize = 16
        text.Font = Enum.Font.GothamBold
        text.Parent = container
    end
})
]]

-- ============================================================
-- STABLE API ALIASES
-- ============================================================
-- The public API is exposed through explicit table methods only.
-- It does not depend on local variable names, debug/source inspection,
-- or caller environment details, making it safer for obfuscated callers.

-- ============================================================
-- RETURN
-- ============================================================

function RobloxStudio:SetCoreGuiInjectorURL(url)
    if type(url) ~= "string" or url == "" then
        return false
    end

    CORE_GUI_INJECTOR_URL = url
    Injector = nil
    return true
end

-- ============================================================
-- PUBLIC API ALIASES
-- ============================================================

RobloxStudio.Library = RobloxStudio
RobloxStudio.CreateTab = function(self, config)
    return self:AddTab(config)
end
RobloxStudio.Add = RobloxStudio.AddTab
RobloxStudio.Set = RobloxStudio.SetValue
RobloxStudio.Get = RobloxStudio.GetValue

return RobloxStudio
