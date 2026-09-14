Library Studio

A modern Roblox UI library inspired by the Roblox Help/Settings interface, designed for clean navigation, responsive layouts, low overhead, and flexible feature components.

Overview

Library Studio provides a complete interface system with:

- Roblox-style sidebar navigation
- Multiple tabs
- Buttons
- Toggles
- Sliders
- Dropdowns
- Multi-selection dropdowns
- Text inputs
- Keybinds
- Information panels
- Dashboards
- Labels
- Paragraphs
- Sections
- Custom GUI containers
- Notifications
- Search
- Runtime configuration
- JSON configuration saving/loading
- Auto-save
- Theme customization
- Accent customization
- Key verification system
- Responsive UI scaling
- CoreGui integration and recovery

The library is designed to keep the interface lightweight while providing an extended API for building complex in-game interfaces.

---

UI Structure

Library Studio
│
├── Sidebar
│   ├── Studio Header
│   └── Tab List
│
└── Content
    ├── Header
    ├── Description
    ├── Divider
    └── Feature Area
        ├── Button
        ├── Toggle
        ├── Slider
        ├── Dropdown
        ├── Multi Dropdown
        ├── Text Input
        ├── Keybind
        ├── Information
        ├── Dashboard
        ├── Label
        ├── Paragraph
        ├── Section
        └── Custom GUI

---

Getting Started

A basic Library Studio setup looks like this:

local Library = LibraryStudio

local MainTab = Library:AddTab({
    Name = "Home",
    Icon = "home",
    EmptyMessage = "No features available in this tab."
})

MainTab:AddButton({
    Name = "Execute",
    Description = "Execute the selected action.",
    Callback = function()
        print("Button activated")
    end
})

MainTab:AddToggle({
    Name = "Enabled",
    Description = "Enable or disable the feature.",
    Flag = "Enabled",
    CurrentValue = false,
    Callback = function(value)
        print("Enabled:", value)
    end
})

---

Tabs

AddTab

Creates a new tab in the sidebar.

Library:AddTab({
    Name = "Tab",
    Icon = "settings",
    Order = 1,
    EmptyMessage = "No features available in this tab."
})

Parameters

Parameter| Type| Default| Description
"Name"| string| ""Tab""| Tab display name
"Icon"| string| ""settings""| Tab icon
"Order"| number| Tab position| Sidebar order
"EmptyMessage"| string| ""No features available in this tab.""| Message shown when the tab has no content

Returns a Tab object.

The first created tab automatically becomes the active tab.

---

Components

Button

Creates a clickable button.

Tab:AddButton({
    Name = "Execute",
    Description = "Execute an action.",
    Icon = "chevron-right",
    Callback = function()
        print("Executed")
    end,
    Order = 1
})

Parameters

Parameter| Type| Default
"Name"| string| ""Button""
"Description"| string| """"
"Icon"| string| ""chevron-right""
"Callback"| function| Optional
"Order"| number| Automatic

The callback does not receive any parameters.

---

Toggle

Creates an on/off switch.

Tab:AddToggle({
    Name = "Enabled",
    Description = "Enable this feature.",
    Icon = "check",
    Flag = "FeatureEnabled",
    CurrentValue = false,

    Callback = function(value)
        print("Enabled:", value)
    end
})

The callback receives:

true

or

false

The current value is also stored using the specified "Flag".

---

Information

Creates an information panel.

Tab:AddInfo({
    Title = "Information",
    Message = "This is an information message."
})

Parameters

Parameter| Type| Default
"Title"| string| ""Information""
"Message"| string| """"
"Order"| number| Automatic

---

Dashboard

Creates a system-style dashboard.

Tab:AddDashboard({
    Title = "System Dashboard",

    Stats = {
        {
            Title = "Status",
            Value = "Active"
        },
        {
            Title = "Version",
            Value = "1.0"
        }
    },

    Logs = {
        "System initialized.",
        "Ready."
    }
})

Stats

Each statistic uses:

{
    Title = "Status",
    Value = "Active"
}

Logs

Logs are supplied as a table of strings:

Logs = {
    "System initialized.",
    "Loading configuration...",
    "Ready."
}

---

Text Input

Creates a text input field.

Tab:AddTextInput({
    Name = "Username",
    Placeholder = "Enter username...",
    CurrentValue = "",
    Flag = "Username",

    Callback = function(value)
        print("Username:", value)
    end
})

The callback is triggered when the input loses focus after the user confirms the input.

---

Label

Creates a simple text label.

Tab:AddLabel("Library Studio")

---

Paragraph

Creates a paragraph-style information block.

Tab:AddParagraph({
    Title = "About",
    Content = "This interface was created with Library Studio."
})

"Content" takes priority over "Message".

Example:

Tab:AddParagraph({
    Title = "About",
    Message = "Fallback content."
})

---

Section

Creates a section separator.

Tab:AddSection("Settings")

Section names are displayed in an uppercase section style.

---

Slider

Creates a value slider.

Tab:AddSlider({
    Name = "Volume",
    Description = "Adjust the volume.",
    Icon = "sliders",

    Flag = "Volume",

    Min = 0,
    Max = 100,
    Increment = 1,
    CurrentValue = 50,

    Callback = function(value)
        print("Volume:", value)
    end
})

Parameters

Parameter| Type| Default
"Name"| string| ""Slider""
"Description"| string| """"
"Icon"| string| ""sliders""
"Flag"| string| Automatic
"Min"| number| "0"
"Max"| number| "100"
"Increment"| number| "1"
"CurrentValue"| number| "Min"
"Callback"| function| Optional

Values are automatically clamped between "Min" and "Max" and adjusted according to "Increment".

The slider supports mouse and touch interaction.

---

Dropdown

Creates a single-selection dropdown.

Tab:AddDropdown({
    Name = "Mode",
    Description = "Select a mode.",
    Icon = "chevron-down",

    Flag = "Mode",

    Values = {
        "Normal",
        "Advanced",
        "Experimental"
    },

    CurrentValue = "Normal",

    Callback = function(value)
        print("Selected:", value)
    end
})

"Options" can also be used as an alias for "Values".

---

Multi Dropdown

Creates a multiple-selection dropdown.

Tab:AddMultiDropdown({
    Name = "Features",
    Description = "Select features.",
    Icon = "chevron-down",

    Flag = "Features",

    Values = {
        "A",
        "B",
        "C"
    },

    CurrentValue = {},

    Callback = function(values)
        print(values)
    end
})

The callback receives a table containing the selected values.

---

Keybind

Creates a keybind selector.

Tab:AddKeybind({
    Name = "Toggle Menu",
    Description = "Choose a keyboard shortcut.",
    Icon = "key",

    Flag = "ToggleKey",

    CurrentKey = Enum.KeyCode.RightShift,

    Callback = function(key)
        print("New key:", key)
    end
})

When the keybind is activated, the interface enters a:

Press key...

state and waits for keyboard input.

The selected key is then stored and passed to the callback.

---

Custom GUI

Library Studio allows custom Roblox GUI objects to be inserted into a component container.

Tab:AddCustomGUI({
    Name = "Custom GUI",

    Size = UDim2.new(1, 0, 0, 220),

    Build = function(container, tab, library)
        -- Create custom GUI here
    end
})

The "Build" callback receives:

container
tab
library

This allows developers to extend Library Studio with custom interface elements while keeping them inside the existing layout.

---

Runtime State

Library Studio maintains runtime values using flags.

SetValue

Library:SetValue("FeatureEnabled", true)

Returns the assigned value.

GetValue

local value = Library:GetValue("FeatureEnabled")

GetConfig

Returns a copy of the current runtime configuration.

local config = Library:GetConfig()

SetConfig

Applies a configuration table.

Library:SetConfig({
    FeatureEnabled = true,
    Volume = 50
})

Returns "true" when a valid table is provided.

---

Configuration Files

Library Studio supports JSON configuration files through the supported filesystem environment.

Configuration files are stored under:

Kys/Config/

SaveConfig

Library:SaveConfig("settings")

The ".json" extension is automatically added when necessary.

Example:

Library:SaveConfig("MySettings.json")

---

LoadConfig

Library:LoadConfig("settings")

The configuration is decoded and applied to the runtime state.

---

Auto Save

Library Studio includes automatic configuration saving.

Library:AutoSave(30, "settings")

This saves the current configuration every 30 seconds.

The interval is clamped to a minimum of one second.

Calling "AutoSave()" again replaces the previous auto-save process.

StopAutoSave

Library:StopAutoSave()

Stops the active automatic save process.

---

Search

Library Studio includes an interface search system.

local results = Library:Search("settings")

The result is an array containing:

{
    Name = "...",
    Tab = "...",
    Item = ...
}

Search is case-insensitive.

An empty query returns an empty result.

The search checks component names, titles, and text where applicable.

---

Notifications

Create a notification with:

Library:Notify({
    Title = "Library Studio",
    Content = "Operation completed.",
    Duration = 3
})

"Message" can also be supplied as an alternative content field.

Parameters

Parameter| Type| Default
"Title"| string| ""Kys UI""
"Content"| string| """"
"Message"| string| —
"Duration"| number| "3"

The notification system includes animated entrance and exit behavior.

---

Themes

Library Studio uses a centralized theme system.

The default theme contains:

Surface
SurfaceHover
SurfaceActive
Surface2
Text
SubText
Muted
Border
Accent
Error
Success
Warning
White

Default values include:

Surface = Color3.fromRGB(20, 24, 30)
SurfaceHover = Color3.fromRGB(30, 36, 46)
SurfaceActive = Color3.fromRGB(35, 125, 255)
Surface2 = Color3.fromRGB(25, 32, 42)

Text = Color3.fromRGB(245, 248, 252)
SubText = Color3.fromRGB(168, 181, 196)
Muted = Color3.fromRGB(120, 135, 150)

Border = Color3.fromRGB(60, 75, 90)
Accent = Color3.fromRGB(35, 125, 255)

Error = Color3.fromRGB(255, 85, 90)
Success = Color3.fromRGB(85, 255, 140)
Warning = Color3.fromRGB(255, 190, 70)

White = Color3.fromRGB(255, 255, 255)

---

SetTheme

Apply theme changes:

Library:SetTheme({
    Accent = Color3.fromRGB(255, 80, 80),
    Surface = Color3.fromRGB(20, 20, 20)
})

Only recognized theme keys are updated.

If the interface is currently mounted, the UI is rebuilt to apply the changes.

---

SetAccent

Quickly change the accent color:

Library:SetAccent(Color3.fromRGB(255, 80, 80))

The accent also updates "SurfaceActive".

Returns "true" when a valid "Color3" is supplied.

---

GetTheme

Retrieve the current theme:

local Theme = Library:GetTheme()

A copy of the theme is returned.

---

Menu Branding

Library Studio provides two menu-title APIs.

SetMenuName

Library:SetMenuName("My Executor")

The default menu name is:

Library Studio

SetStudioTitle

Library:SetStudioTitle("Studio Hub")

The studio title is displayed in the sidebar header.

The default title is:

Studio Hub

---

UI Speed

The library provides a UI speed compatibility API:

Library:SetUISpeed(1.5)

The supported range is:

0.1 - 10.0

The value is automatically clamped to this range.

The current implementation is primarily a compatibility API; it does not perform a global descendant tween-speed modification.

---

Key Verification System

Library Studio includes a key verification interface.

Library:ShowKeySystem({
    Name = "Key Verification System",

    Key = "SECRET123",

    GetKeyURL = "https://example.com/getkey",

    OnSuccess = function()
        print("Key verified")
    end
})

Parameters

Parameter| Type| Default
"Name"| string| ""Key Verification System""
"Key"| string| ""SECRET123""
"GetKeyURL"| string| ""https://example.com/getkey""
"OnSuccess"| function| Optional

If "setclipboard" is available, the key URL can be copied to the clipboard.

Otherwise, the URL is displayed inside the interface.

The current implementation performs a direct string comparison against the configured key.

---

Icons

Library Studio supports icon names such as:

studio
home
info
key
settings
sliders
check
chevron-right
chevron-down
alert-triangle
search
code
user
save
refresh-cw
lock
bell
circle-help

The library attempts to use the supported icon set when available and falls back to its internal icon/text representation when necessary.

---

Mounting

Mount the interface into a container:

Library:Mount(container)

The mount process:

1. Hides conflicting GUI elements.
2. Finds or creates the Library Studio content container.
3. Makes the root interface visible.
4. Builds the sidebar and content area.
5. Attaches responsive size handling.

---

UnMount

Temporarily hide the interface:

Library:UnMount()

This hides the root UI without destroying the library.

---

Destroy

Completely remove the interface:

Library:Destroy()

The destroy process:

- Stops AutoSave.
- Clears render connections.
- Clears permanent connections.
- Disconnects size listeners.
- Destroys the root UI.
- Clears the root reference.

---

Responsive Layout

Library Studio automatically adapts to the available interface size.

The sidebar width is dynamically calculated and constrained to approximately:

Minimum: 140 px
Maximum: 200 px

This allows the UI to remain usable across different screen sizes.

---

Performance

The library is designed with performance in mind.

Important optimization features include:

- Event-driven CoreGui recovery.
- Cleanup of render connections before rebuilding content.
- Avoidance of unnecessary constant CoreGui descendant scanning.
- Controlled connection management.
- Rebuilding only when required.
- Responsive sizing based on actual UI dimensions.

Callback execution is protected with "pcall" so errors inside user callbacks do not directly break the library.

Warnings generated by callback failures use the prefix:

[Library Studio]

---

CoreGui Integration

Library Studio can integrate with the Roblox settings/help interface structure.

The library searches for the relevant Help page containers and supports fallback discovery when the expected hierarchy changes.

The integration is based around structures such as:

RobloxGui
└── SettingsClippingShield
    └── SettingsShield
        └── MenuContainer
            └── Page
                └── PageViewClipper
                    └── PageView
                        └── PageViewInnerFrame
                            └── Help
                                └── HelpPageContainer

The library also includes event-driven recovery using "DescendantAdded".

---

Complete Example

local Library = LibraryStudio

Library:SetMenuName("My Studio")
Library:SetStudioTitle("Studio Hub")

local Home = Library:AddTab({
    Name = "Home",
    Icon = "home"
})

Home:AddSection("General")

Home:AddParagraph({
    Title = "Welcome",
    Content = "Welcome to Library Studio."
})

Home:AddButton({
    Name = "Execute",
    Description = "Execute the main action.",
    Icon = "chevron-right",

    Callback = function()
        Library:Notify({
            Title = "Library Studio",
            Content = "Action executed.",
            Duration = 3
        })
    end
})

Home:AddToggle({
    Name = "Enabled",
    Description = "Enable the feature.",
    Flag = "Enabled",
    CurrentValue = false,

    Callback = function(value)
        print("Enabled:", value)
    end
})

Home:AddSlider({
    Name = "Power",
    Description = "Adjust the power level.",
    Flag = "Power",

    Min = 0,
    Max = 100,
    Increment = 5,
    CurrentValue = 50,

    Callback = function(value)
        print("Power:", value)
    end
})

Home:AddDropdown({
    Name = "Mode",
    Description = "Select a mode.",

    Flag = "Mode",

    Values = {
        "Normal",
        "Advanced",
        "Experimental"
    },

    CurrentValue = "Normal",

    Callback = function(value)
        print("Mode:", value)
    end
})

Home:AddTextInput({
    Name = "Username",
    Placeholder = "Enter username...",
    Flag = "Username",

    Callback = function(value)
        print("Username:", value)
    end
})

Home:AddKeybind({
    Name = "Menu Key",
    Description = "Set the menu key.",
    Flag = "MenuKey",

    CurrentKey = Enum.KeyCode.RightShift,

    Callback = function(key)
        print("Menu key:", key)
    end
})

local Settings = Library:AddTab({
    Name = "Settings",
    Icon = "settings"
})

Settings:AddSection("Configuration")

Settings:AddButton({
    Name = "Save Configuration",

    Callback = function()
        Library:SaveConfig("settings")
    end
})

Settings:AddButton({
    Name = "Load Configuration",

    Callback = function()
        Library:LoadConfig("settings")
    end
})

Library:Mount()

---

API Reference

API| Purpose
"AddTab()"| Create a tab
"AddButton()"| Create a button
"AddToggle()"| Create a toggle
"AddInfo()"| Create an information panel
"AddDashboard()"| Create a dashboard
"AddTextInput()"| Create a text input
"AddLabel()"| Create a label
"AddParagraph()"| Create a paragraph
"AddSection()"| Create a section
"AddSlider()"| Create a slider
"AddDropdown()"| Create a dropdown
"AddMultiDropdown()"| Create a multi-selection dropdown
"AddKeybind()"| Create a keybind
"AddCustomGUI()"| Create a custom GUI container
"SetValue()"| Set runtime state
"GetValue()"| Get runtime state
"GetConfig()"| Get complete runtime configuration
"SetConfig()"| Apply runtime configuration
"SaveConfig()"| Save configuration
"LoadConfig()"| Load configuration
"AutoSave()"| Enable automatic saving
"StopAutoSave()"| Stop automatic saving
"Search()"| Search UI components
"Notify()"| Show notification
"SetTheme()"| Change theme
"SetAccent()"| Change accent color
"GetTheme()"| Get current theme
"SetMenuName()"| Change menu name
"SetStudioTitle()"| Change studio title
"SetUISpeed()"| Set UI speed compatibility value
"ShowKeySystem()"| Show key verification UI
"Mount()"| Mount the UI
"UnMount()"| Hide the UI
"Destroy()"| Destroy the UI

---

Design Philosophy

Library Studio is built around three main principles:

1. Familiar Interface

The interface follows the visual organization of Roblox's own Help/Settings experience, making navigation familiar to users.

2. Flexible Components

Developers can combine standard components or insert completely custom Roblox GUI elements when the built-in components are not enough.

3. Lightweight Runtime

The library focuses on avoiding unnecessary loops and connection buildup while maintaining responsive interaction and automatic UI recovery.

---

Library Studio

A Roblox-style UI framework for creating organized, responsive, and customizable in-game interfaces.

Build your interface.
Customize your experience.
Make it your Studio.
