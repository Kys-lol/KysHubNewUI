Kys UI Library

Modern, flexible, mobile-friendly UI Library untuk Roblox Lua/Luau.

Kys UI Library dirancang untuk membuat interface Roblox yang modern tanpa harus membangun seluruh sistem GUI dari awal. Library menyediakan sistem Window, Tab, Section, berbagai UI element, configuration manager, search system, key system, icon system, custom GUI embedding, preset manager, dan beberapa helper untuk membuat interface yang lebih kompleks.

«Current Library: "Library-Kys.lua"»

---

✨ Features

- 🎨 Modern dark UI
- 📱 Mobile / Android friendly
- 🖥️ Desktop support
- 🗂️ Tab system
- 📦 Section system
- 🧩 Custom GUI di dalam Tab
- 🧱 Custom GUI di dalam Section
- 🔘 Button
- 🔀 Toggle
- 🎚️ Slider
- 🎨 Color Picker
- ⌨️ Input / TextBox
- 🎹 Keybind
- 📋 Dropdown
- 📝 Paragraph
- 📢 Banner
- 🃏 Card
- 🧩 Card Widget
- 📑 Config Manager
- 💾 Auto Save
- 🔄 Auto Load
- 📤 Config Export
- 📥 Config Import
- 🔎 Built-in Search
- 🔐 Key System
- 🔒 Lock / Unlock UI elements
- 🖼️ Icon system
- 🌐 Web image support
- 🎛️ HStack layout
- 📏 Spacer / Divider / SubSection
- 💡 Information Tab helper
- 🎯 Preset Manager
- 🖱️ Draggable interface
- 🔘 Floating logo button
- 📱 Touch input support

---

📦 Installation

Load library menggunakan "loadstring":

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kys-lol/KysHubNewUI/refs/heads/main/Library-Kys.lua"
))()

Setelah library berhasil dimuat, buat Window:

local Window = Library:Window({
    Title = "My Hub",
    Author = "Kys",
    Color = Color3.fromRGB(0, 170, 255)
})

---

🚀 Basic Example

Contoh paling sederhana:

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kys-lol/KysHubNewUI/refs/heads/main/Library-Kys.lua"
))()

local Window = Library:Window({
    Title = "My Hub",
    Author = "Kys",
    Color = Color3.fromRGB(0, 170, 255)
})

local Main = Window:AddTab({
    Name = "Main",
    Icon = "home"
})

local Section = Main:AddSection("Main Features")

Section:AddButton({
    Title = "Hello",
    Callback = function()
        print("Hello World!")
    end
})

Section:AddToggle({
    Title = "Example Toggle",
    Content = "Enable or disable the feature.",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end
})

---

🪟 Window

Window merupakan root utama dari seluruh UI.

Syntax

local Window = Library:Window({
    Title = "My Hub",
    Image = "98140353767645",
    Footer = "My Script Hub",
    Author = "Kys",
    Color = Color3.fromRGB(150, 150, 150),
    ["Tab Width"] = 120,
    Version = 1,
    LogoButtonSize = 50,
    Search = true,
    ShowInfo = false,
    Folder = "MyHub"
})

Window Options

Property| Type| Default| Description
"Title"| string| ""Kys""| Judul utama UI
"Image"| string/number| built-in| Asset ID logo
"Footer"| string| """"| Text footer
"Author"| string| """"| Nama author
"Color"| Color3| "RGB(150,150,150)"| Accent color
"Tab Width"| number| "120"| Lebar area tab
"Version"| number| "1"| Versi config/UI
"LogoButtonSize"| number| "50"| Ukuran floating logo
"Search"| boolean| "true"| Mengaktifkan search
"ShowInfo"| boolean| "false"| Menampilkan info pemain
"Folder"| string| game name| Folder penyimpanan config
"KeySystem"| table| nil| Konfigurasi key system

---

🎨 Accent Color

"Color" digunakan sebagai warna utama UI.

Color = Color3.fromRGB(0, 170, 255)

Contoh warna lain:

Color = Color3.fromRGB(255, 80, 80)

Color = Color3.fromRGB(170, 85, 255)

Color = Color3.fromRGB(0, 255, 150)

Accent color digunakan pada berbagai bagian UI seperti highlight, icon, search result, dan beberapa widget.

---

📑 Tabs

Tab dibuat menggunakan:

local Main = Window:AddTab({
    Name = "Main",
    Icon = "home"
})

Property:

Property| Type| Description
"Name"| string| Nama tab
"Icon"| string| Nama icon

Contoh:

local Main = Window:AddTab({
    Name = "Main",
    Icon = "house"
})

local Settings = Window:AddTab({
    Name = "Settings",
    Icon = "settings"
})

local Player = Window:AddTab({
    Name = "Player",
    Icon = "user"
})

Setiap "AddTab()" mengembalikan object Sections.

---

📂 Sections

Section digunakan untuk mengelompokkan element.

local MainSection = Main:AddSection("Main Features")

Secara default section dapat digunakan sebagai container untuk berbagai element.

Contoh:

local Section = Main:AddSection("Player")

Section:AddToggle({
    Title = "WalkSpeed",
    Default = false,
    Callback = function(value)
        print(value)
    end
})

---

🧩 Custom GUI

Salah satu fitur utama Kys UI adalah kemampuan memasukkan Roblox GuiObject biasa langsung ke dalam Tab atau Section.

Artinya Anda tidak terbatas pada element bawaan library.

Anda dapat membuat GUI sendiri menggunakan:

- "Frame"
- "TextLabel"
- "TextButton"
- "ImageLabel"
- "ImageButton"
- "ScrollingFrame"
- dan "GuiObject" lainnya.

Library akan memasukkannya ke layout Tab/Section dan membantu menyesuaikan ukuran scrolling.

---

Custom GUI di Tab

local CustomFrame = Instance.new("Frame")

CustomFrame.Size = UDim2.new(1, 0, 0, 150)
CustomFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

Main:AddCustomGUI(CustomFrame)

Anda juga dapat menggunakan:

Main.AddCustomGui = Main.AddCustomGUI

"AddCustomGui" merupakan alias dari "AddCustomGUI".

---

Custom GUI di Section

local CustomFrame = Instance.new("Frame")

CustomFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

Section:AddCustomGUI(CustomFrame, {
    Size = UDim2.new(1, 0, 0, 180)
})

Alias:

Section:AddCustomGui(CustomFrame)

---

Custom GUI Options

Section:AddCustomGUI(MyGui, {
    Size = UDim2.new(1, 0, 0, 200),
    Name = "MyCustomGUI",
    LayoutOrder = 10
})

Property:

Property| Type| Description
"Size"| UDim2| Ukuran GUI
"Width"| number/UDim| Lebar custom
"Height"| number/UDim| Tinggi custom
"Name"| string| Nama instance
"LayoutOrder"| number| Urutan dalam layout

Library akan mengatur "LayoutOrder" dan posisi root custom GUI agar dapat ditempatkan di dalam layout tab/section.

Contoh Custom Interface

local Custom = Instance.new("Frame")

Custom.Size = UDim2.new(1, 0, 0, 120)
Custom.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Custom GUI"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.Parent = Custom

Section:AddCustomGUI(Custom)

---

📝 Paragraph

Paragraph digunakan untuk menampilkan informasi atau deskripsi.

Section:AddParagraph({
    Title = "Information",
    Content = "This is an example paragraph."
})

Property:

Property| Type| Description
"Title"| string| Judul
"Content"| string| Isi

---

🔘 Button

Button digunakan untuk menjalankan callback ketika ditekan.

Section:AddButton({
    Title = "Execute",
    Callback = function()
        print("Button clicked")
    end
})

Sub Button

Button juga mendukung tombol kedua.

Section:AddButton({
    Title = "Main Action",
    Callback = function()
        print("Main")
    end,

    SubTitle = "Secondary",
    SubCallback = function()
        print("Secondary")
    end
})

Property:

Property| Type| Default
"Title"| string| ""Confirm""
"Callback"| function| empty
"SubTitle"| string/nil| nil
"SubCallback"| function| empty

---

🔀 Toggle

Toggle digunakan untuk state "true/false".

local Toggle = Section:AddToggle({
    Title = "Auto Farm",
    Content = "Automatically performs the selected feature.",
    Default = false,

    Callback = function(enabled)
        print("Enabled:", enabled)
    end
})

Toggle Properties

Property| Type| Description
"Title"| string| Nama toggle
"Title2"| string| Judul tambahan
"Content"| string| Deskripsi
"Default"| boolean| Nilai awal
"Save"| boolean| Simpan ke config
"Locked"| boolean| Mengunci element
"TextLock"| string| Text lock overlay
"Callback"| function| Dipanggil saat berubah

---

Mengubah Toggle melalui Script

Object hasil "AddToggle()" memiliki:

Toggle:Set(true)

atau:

Toggle:Set(false)

Nilai saat ini tersedia melalui:

print(Toggle.Value)

---

🔒 Lock / Unlock

Sebagian besar element mendukung sistem lock.

Contoh:

Toggle:Lock("Premium Feature")

Untuk membuka:

Toggle:Unlock()

Contoh:

local Toggle = Section:AddToggle({
    Title = "Premium Feature",
    Default = false
})

Toggle:Lock("Premium Only")

Element yang dikunci akan menerima overlay sehingga pengguna tidak dapat menggunakannya secara normal.

---

🎚️ Slider

Slider digunakan untuk memilih nilai numerik.

local Slider = Section:AddSlider({
    Title = "WalkSpeed",
    Content = "Select movement speed.",

    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,

    Callback = function(value)
        print("Value:", value)
    end
})

Property:

Property| Type| Description
"Title"| string| Nama slider
"Content"| string| Deskripsi
"Min"| number| Nilai minimum
"Max"| number| Nilai maksimum
"Default"| number| Nilai awal
"Increment"| number| Step
"Step"| number| Alias untuk Increment
"Save"| boolean| Simpan config
"Locked"| boolean| Lock slider
"TextLock"| string| Text lock
"Callback"| function| Callback

Mengubah nilai

Slider:Set(50)

Nilai:

print(Slider.Value)

Slider akan melakukan clamp antara "Min" dan "Max", serta membulatkan nilai berdasarkan "Increment".

---

🎨 Color Picker

Color picker menyediakan pemilihan warna.

local Color = Section:AddColorPicker({
    Title = "Theme Color",
    Content = "Choose your color.",

    Default = Color3.fromRGB(0, 170, 255),

    Callback = function(color)
        print(color)
    end
})

Property:

Property| Type
"Title"| string
"Content"| string
"Default"| Color3
"Colors"| table
"Save"| boolean
"Locked"| boolean
"TextLock"| string
"Callback"| function

"Colors" dapat digunakan untuk memberikan daftar warna pilihan.

Colors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 170, 255)
}

Color picker juga memiliki editor warna dengan HSV/RGB dan hexadecimal.

---

📝 Input / TextBox

Input digunakan untuk menerima text.

local Input = Section:AddInput({
    Title = "Username",
    Content = "Enter username.",
    Placeholder = "Username",

    Default = "",

    Callback = function(value)
        print("Input:", value)
    end
})

Property:

Property| Type
"Title"| string
"Content"| string
"Placeholder"| string
"Default"| string
"Save"| boolean
"Locked"| boolean
"TextLock"| string
"Callback"| function

Set value

Input:Set("Kys")

Get value

local value = Input:GetValue()

Input juga memiliki:

Input:GetInput()

untuk mendapatkan text yang sedang berada di TextBox.

Input disimpan ketika TextBox kehilangan focus.

---

🎹 Keybind

Keybind digunakan untuk keyboard shortcut.

local Keybind = Section:AddKeybind({
    Title = "Toggle Feature",
    Content = "Press a key to activate.",
    Default = Enum.KeyCode.F,

    Callback = function()
        print("Key pressed")
    end
})

Property:

Property| Type
"Title"| string
"Content"| string
"Default"| Enum.KeyCode
"Save"| boolean
"Callback"| function

Mobile

Pada perangkat mobile/Android, "AddKeybind()" sengaja tidak membuat keybind UI normal karena perangkat mobile tidak memiliki keyboard fisik.

Sebagai gantinya library mengembalikan dummy object sehingga script yang menggunakan API Keybind tetap dapat berjalan tanpa error.

---

📋 Dropdown

Dropdown digunakan untuk memilih satu atau beberapa pilihan.

Single Select

local Dropdown = Section:AddDropdown({
    Title = "Select Mode",
    Content = "Choose one mode.",

    Options = {
        "Normal",
        "Fast",
        "Extreme"
    },

    Default = "Normal",

    Multi = false,

    Callback = function(value)
        print("Selected:", value)
    end
})

---

Multi Select

local Dropdown = Section:AddDropdown({
    Title = "Features",

    Options = {
        "A",
        "B",
        "C"
    },

    Default = {},

    Multi = true,

    Callback = function(values)
        for _, value in ipairs(values) do
            print(value)
        end
    end
})

Property:

Property| Type| Description
"Title"| string| Judul
"Content"| string| Deskripsi
"Options"| table| Daftar pilihan
"Default"| string/table| Nilai awal
"Multi"| boolean| Multiple selection
"Save"| boolean| Config persistence
"Locked"| boolean| Lock dropdown
"TextLock"| string| Lock text
"Callback"| function| Callback

Dropdown memiliki search field untuk mempermudah pencarian option dalam daftar yang panjang.

Mengubah option

Dropdown:Set("Fast")

Untuk multi-select:

Dropdown:Set({
    "A",
    "C"
})

Mengganti daftar options

Dropdown juga menyediakan:

Dropdown:SetValues({
    "Option A",
    "Option B",
    "Option C"
})

---

📢 Banner

Banner digunakan untuk membuat tampilan header/banner pada section.

Section:AddBanner({
    Image = "rbxassetid://123456789",
    Version = "1.0.0",
    AspectRatio = 3
})

Property:

Property| Type
"Image"| string
"Version"| string
"AspectRatio"| number

---

🃏 Card

Card digunakan untuk membuat informasi berbentuk kartu.

Section:AddCard({
    Title = "Kys Hub",
    Description = "A modern Roblox interface.",
    Logo = "home"
})

Card dapat menggunakan icon/logo dan description dengan RichText.

---

Card dengan Button

Section:AddCard({
    Title = "Community",
    Description = "Join our community.",

    Logo = "users",

    Buttons = {
        {
            Name = "Join",
            Callback = function()
                print("Join clicked")
            end
        }
    }
})

Card juga dapat menggunakan "Link".

Section:AddCard({
    Title = "Website",
    Description = "Visit our website.",
    Link = "https://example.com"
})

Jika executor menyediakan "setclipboard", link akan disalin ke clipboard ketika card diklik.

---

🧩 Card Widget

Card Widget adalah versi card yang dapat digunakan untuk UI yang lebih interaktif.

Section:AddCardWidget({
    Title = "Example",
    Description = "Interactive widget."
})

Card Widget dapat digunakan dengan:

- Title
- Description
- Logo
- Callback
- Link
- Additional options

---

➖ Divider

Divider digunakan untuk memisahkan beberapa UI element.

Section:AddDivider()

---

🔹 SubSection

SubSection digunakan sebagai label kecil di dalam Section.

Section:AddSubSection("Player Settings")

Hasilnya akan menjadi pemisah visual dengan title.

---

⬜ Space

Menambahkan ruang kosong.

Section:AddSpace()

Atau custom:

Section:AddSpace({
    Width = 12,
    Height = 20
})

Property:

Property| Type| Default
"Width"| number| "12"
"Height"| number| "8"

---

↔️ HStack

"AddHStack()" digunakan untuk menempatkan beberapa GUI element secara horizontal.

local Stack = Section:AddHStack({
    Padding = 6,
    Height = 40
})

Property:

Property| Type| Default
"Padding"| number| "6"
"Height"| number/nil| auto
"Sizing"| string| ""Equal""
"HorizontalAlignment"| Enum| Left
"VerticalAlignment"| Enum| Center
"EqualHeight"| boolean| true

---

HStack Example

local Stack = Section:AddHStack({
    Padding = 8,
    Height = 40
})

local Button1 = Instance.new("TextButton")
Button1.Text = "One"
Button1.Size = UDim2.new(0, 100, 0, 40)
Button1.Parent = Stack

local Button2 = Instance.new("TextButton")
Button2.Text = "Two"
Button2.Size = UDim2.new(0, 100, 0, 40)
Button2.Parent = Stack

Jika "Sizing = "Equal"", library akan membagi lebar child secara otomatis. "EqualHeight = true" juga membuat child menggunakan tinggi yang sama berdasarkan child tertinggi.

---

🔎 Search System

Kys UI memiliki search system internal.

Ketika:

Search = true

library akan mendaftarkan:

- Tab
- Toggle
- Slider
- Input
- Dropdown
- Card
- Card Widget
- Preset Manager
- dan element lainnya

ke search registry.

Search menggunakan matching bertingkat sehingga exact match dan prefix match mendapatkan prioritas lebih tinggi.

Keyboard Shortcut

Pada desktop:

Ctrl + Shift + F

atau:

Ctrl + O

dapat digunakan untuk membuka/focus search.

Search shortcut tersebut hanya aktif jika "Search = true".

---

💾 Configuration System

Kys UI memiliki configuration system terintegrasi.

Config digunakan untuk menyimpan state element seperti:

- Toggle
- Slider
- Color Picker
- Input
- Keybind
- Dropdown
- Preset-related data

Config disimpan sebagai JSON.

Library membuat struktur folder:

Kys/
├── Config/
│   └── <Folder>.json
│
└── Configs/
    └── <GameName>/
        ├── Config1.json
        ├── Config2.json
        └── _autoload.json

Nama game secara otomatis digunakan sebagai scope default, dan dapat diganti melalui "Folder".

---

⚙️ Save

Untuk menyimpan config:

Window:SaveConfigAs("MyConfig")

Contoh:

Window:SaveConfigAs("Default")

---

📂 Load

Load config:

Window:LoadConfigByName("Default")

---

🗑️ Delete Config

Window:DeleteConfig("Default")

---

📋 Get Configs

Mendapatkan daftar config:

local configs = Window:GetConfigs()

for _, name in ipairs(configs) do
    print(name)
end

---

🔄 Auto Load

Set config tertentu sebagai auto-load:

Window:SetAutoLoad("Default")

Mengecek auto-load:

local name = Window:GetAutoLoad()

print(name)

Jika auto-load tersedia, library akan mencoba memuat config tersebut setelah UI selesai dibuat.

---

📤 Export Config

Export config menjadi JSON:

local json = Window:ExportConfig()

print(json)

Jika "setclipboard" tersedia, JSON juga akan otomatis disalin ke clipboard.

Format export memiliki metadata seperti:

{
    "Hub": "Kys",
    "Game": "...",
    "PlaceId": 123,
    "Version": 1,
    "ActiveConfig": "",
    "AutoLoad": "",
    "Data": {}
}

---

📥 Import Config

Import JSON:

Window:ImportConfig(jsonString)

Contoh:

local Config = [[
{
    "Data": {
        "Toggle_Auto Farm": true
    }
}
]]

Window:ImportConfig(Config)

Import system dapat membaca payload dengan data di:

Data
Config
Settings

sehingga format config tertentu dapat lebih fleksibel.

---

🔐 Key System

Window dapat menggunakan key system sebelum UI utama dibuat.

local Window = Library:Window({
    Title = "My Hub",

    KeySystem = {
        Title = "My Hub Key",
        Key = "ABC123"
    }
})

Key system dapat digunakan untuk melakukan validasi sebelum pengguna mendapatkan akses ke UI utama.

Jika key berhasil diverifikasi, window utama dibuat.

Jika gagal, callback "OnFail" dapat dipanggil.

«Gunakan key system hanya sebagai mekanisme access control sederhana. Jangan menganggap key yang disimpan langsung di client sebagai sistem keamanan yang benar-benar rahasia.»

---

🖼️ Icon System

Library menggunakan Footagesus Icons V2 sebagai backend icon.

Icon backend mendukung beberapa icon set, termasuk:

- Lucide
- Craft
- Geist
- Solar
- SF Symbols
- Gravity UI

Library menggunakan Lucide sebagai default icon type.

---

Basic Icon

Icon = "home"

Contoh:

Window:AddTab({
    Name = "Home",
    Icon = "home"
})

---

Explicit Icon Namespace

Library juga mendukung namespace:

Icon = "solar:Home2Bold"

Contoh:

Icon = "lucide:settings"

Icon = "solar:Home2Bold"

Icon = "sfsymbols:HouseFill"

Namespace yang didukung:

lucide
craft
geist
solar
sfsymbols
sf-symbols
gravity
gravity-ui

---

🖼️ Custom Image

Selain icon name, image juga dapat berupa:

rbxassetid://123456

atau asset ID numerik:

Image = "123456789"

Library akan mengubah asset ID numerik menjadi:

rbxassetid://123456789

URL HTTP/HTTPS juga dikenali oleh resolver image.

---

📱 Mobile Support

Library mendeteksi perangkat mobile menggunakan:

UserInputService.TouchEnabled

serta mengecek apakah keyboard dan mouse tersedia.

Pada mobile, ukuran UI disesuaikan secara otomatis.

Library juga membatasi scaling agar window tidak terlalu besar pada layar kecil.

---

🔘 Floating Logo Button

Window memiliki floating logo button yang dapat digunakan untuk membuka/menyembunyikan UI utama.

Ukuran dapat diatur:

LogoButtonSize = 50

Contoh:

local Window = Library:Window({
    Title = "My Hub",
    LogoButtonSize = 45
})

Floating button juga mendukung touch input dan dapat dipindahkan dengan drag pada perangkat yang kompatibel.

---

🧑 Player Information

Jika:

ShowInfo = true

library akan menampilkan informasi player pada area UI.

local Window = Library:Window({
    Title = "My Hub",
    ShowInfo = true
})

Library menggunakan "DisplayName" dan "Name" pemain lokal untuk informasi tersebut.

---

🎯 Preset Manager

Kys UI juga memiliki Preset Manager.

Preset berbeda dari configuration system utama.

Contoh:

local Preset = Section:AddPreset({
    Title = "My Presets",
    Default = "",
    Placeholder = "Enter value",

    Presets = {
        Default = "Example"
    },

    Callback = function(value)
        print(value)
    end
})

Preset dapat:

- membuat preset
- menyimpan preset
- memilih preset
- menghapus preset
- menyimpan data ke file JSON

Preset menggunakan file terpisah dari config utama.

---

ℹ️ Info Tab

Library menyediakan helper khusus:

Window:InfoTab({})

Contoh:

local InfoTab, InfoItems = Window:InfoTab({
    Name = "Information",
    Icon = "info",
    SectionTitle = "About",

    Banner = "rbxassetid://123456789",
    Version = "1.0.0",

    DiscordLink = "YOUR_INVITE",
    DiscordName = "Community",
    DiscordText = "Join our community.",
    DiscordDesc = "Updates and announcements."
})

"InfoTab()" dapat membuat:

- tab informasi
- section
- banner
- community card
- custom cards
- card widgets

Property utama:

Property| Type
"Name"| string
"Icon"| string
"SectionTitle"| string
"Banner"| string
"Version"| string
"BannerAspectRatio"| number
"DiscordLink"| string
"DiscordName"| string
"DiscordText"| string
"DiscordDesc"| string
"Cards"| table
"CardsWidget"| table

Implementasi "InfoTab()" menggunakan "AddBanner", "AddCard", dan "AddCardWidget" secara internal.

---

🧱 Complete Example

Berikut contoh penggunaan beberapa fitur sekaligus:

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kys-lol/KysHubNewUI/refs/heads/main/Library-Kys.lua"
))()

local Window = Library:Window({
    Title = "Example Hub",
    Author = "Kys",
    Footer = "Example",
    Color = Color3.fromRGB(0, 170, 255),

    Version = 1,
    Search = true,
    ShowInfo = true,

    Folder = "ExampleHub"
})

-- Main Tab
local Main = Window:AddTab({
    Name = "Main",
    Icon = "home"
})

local MainSection = Main:AddSection("Main Features")

MainSection:AddParagraph({
    Title = "Welcome",
    Content = "Welcome to the example hub."
})

local Enabled = MainSection:AddToggle({
    Title = "Enable Feature",
    Content = "Enable or disable the feature.",
    Default = false,

    Callback = function(value)
        print("Enabled:", value)
    end
})

local Speed = MainSection:AddSlider({
    Title = "Speed",
    Content = "Select speed.",

    Min = 1,
    Max = 100,
    Default = 25,
    Increment = 1,

    Callback = function(value)
        print("Speed:", value)
    end
})

MainSection:AddButton({
    Title = "Execute",
    Callback = function()
        print("Executed!")
    end
})

-- Player Tab
local Player = Window:AddTab({
    Name = "Player",
    Icon = "user"
})

local PlayerSection = Player:AddSection("Player")

PlayerSection:AddInput({
    Title = "Username",
    Content = "Enter a username.",
    Placeholder = "Username",

    Callback = function(value)
        print(value)
    end
})

PlayerSection:AddDropdown({
    Title = "Mode",
    Content = "Select a mode.",

    Options = {
        "Normal",
        "Fast",
        "Advanced"
    },

    Default = "Normal",

    Callback = function(value)
        print(value)
    end
})

PlayerSection:AddColorPicker({
    Title = "Color",
    Default = Color3.fromRGB(0, 170, 255),

    Callback = function(color)
        print(color)
    end
})

-- Settings
local Settings = Window:AddTab({
    Name = "Settings",
    Icon = "settings"
})

local ConfigSection = Settings:AddSection("Configuration")

ConfigSection:AddConfig()

---

🧩 Custom GUI Example

Jika Anda ingin membuat interface yang sepenuhnya custom:

local CustomTab = Window:AddTab({
    Name = "Custom",
    Icon = "layout"
})

local CustomSection = CustomTab:AddSection("Custom Interface")

local Frame = Instance.new("Frame")

Frame.Size = UDim2.new(1, 0, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Fully Custom GUI"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local Button = Instance.new("TextButton")

Button.Size = UDim2.new(1, -20, 0, 40)
Button.Position = UDim2.new(0, 10, 0, 60)
Button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Button.Text = "Click Me"
Button.TextColor3 = Color3.new(1, 1, 1)
Button.TextSize = 14
Button.Parent = Frame

Button.Activated:Connect(function()
    print("Custom button clicked")
end)

CustomSection:AddCustomGUI(Frame)

Dengan sistem ini, Anda dapat membuat GUI custom sendiri tanpa harus mengikuti tampilan Button/Toggle/Input bawaan Kys UI.

---

🔗 Custom GUI di Tab Tanpa Section

Custom GUI juga dapat langsung ditempatkan di tab:

local Tab = Window:AddTab({
    Name = "Custom",
    Icon = "layout"
})

local Frame = Instance.new("Frame")

Frame.Size = UDim2.new(1, 0, 0, 150)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

Tab:AddCustomGUI(Frame)

Library akan memasukkan "GuiObject" tersebut ke scrolling area tab dan layout akan menyesuaikan content size.

---

🔧 Returned Objects

Sebagian besar function element mengembalikan object/function table sehingga nilainya dapat dikontrol dari script.

Contoh:

local Toggle = Section:AddToggle({...})

Toggle:Set(true)

print(Toggle.Value)

Contoh slider:

local Slider = Section:AddSlider({...})

Slider:Set(50)

print(Slider.Value)

Contoh dropdown:

local Dropdown = Section:AddDropdown({...})

Dropdown:Set("Option 2")

---

🔒 Lock API

Element yang mendukung lock memiliki:

Element:Lock()

atau:

Element:Lock("Premium")

Untuk membuka:

Element:Unlock()

Contoh:

local Button = Section:AddButton({
    Title = "Premium Feature",
    Callback = function()
        print("Premium")
    end
})

Button:Lock("Premium")

---

🧠 Recommended Structure

Untuk project besar, struktur berikut direkomendasikan:

local Library = ...

local Window = Library:Window({...})

-- Tabs
local Main = Window:AddTab({...})
local Player = Window:AddTab({...})
local Visual = Window:AddTab({...})
local Settings = Window:AddTab({...})

-- Sections
local MainSection = Main:AddSection("Main")
local PlayerSection = Player:AddSection("Player")
local VisualSection = Visual:AddSection("Visual")
local SettingsSection = Settings:AddSection("Settings")

-- Elements
MainSection:AddToggle({...})
MainSection:AddButton({...})

PlayerSection:AddSlider({...})
PlayerSection:AddInput({...})

VisualSection:AddColorPicker({...})
VisualSection:AddDropdown({...})

SettingsSection:AddConfig()

Struktur ini membuat project lebih mudah dikembangkan dibanding memasukkan seluruh element ke satu Section.

---

📚 API Quick Reference

Library

Library:Window(config)

---

Window

Window:AddTab(config)

Window:InfoTab(config)

Window:SaveConfigAs(name)

Window:LoadConfigByName(name)

Window:DeleteConfig(name)

Window:GetConfigs()

Window:SetAutoLoad(name)

Window:GetAutoLoad()

Window:ExportConfig()

Window:ImportConfig(json)

---

Tab / Sections

Tab:AddSection(title)

Tab:AddCustomGUI(guiObject, config)

Tab:AddCustomGui(guiObject, config)

---

Section / Items

Section:AddParagraph(config)

Section:AddButton(config)

Section:AddToggle(config)

Section:AddSlider(config)

Section:AddColorPicker(config)

Section:AddInput(config)

Section:AddKeybind(config)

Section:AddDropdown(config)

Section:AddConfig(config)

Section:AddBanner(config)

Section:AddCard(config)

Section:AddCardWidget(config)

Section:AddDivider()

Section:AddSubSection(title)

Section:AddSpace(config)

Section:AddHStack(config)

Section:AddCustomGUI(guiObject, config)

Section:AddCustomGui(guiObject, config)

---

📊 Element Overview

Element| Callback| Save| Mobile| Customizable
Paragraph| —| —| ✅| ✅
Button| ✅| —| ✅| ✅
Toggle| ✅| ✅| ✅| ✅
Slider| ✅| ✅| ✅| ✅
Color Picker| ✅| ✅| ✅| ✅
Input| ✅| ✅| ✅| ✅
Keybind| ✅| ✅| ⚠️| ✅
Dropdown| ✅| ✅| ✅| ✅
Config| —| —| ✅| Limited
Banner| —| —| ✅| ✅
Card| ✅| —| ✅| ✅
Card Widget| ✅| —| ✅| ✅
Custom GUI| Custom| Custom| ✅| ⭐ Full

«"Keybind" tidak menampilkan sistem keyboard normal pada mobile karena library mendeteksi perangkat mobile dan menyediakan dummy object sebagai gantinya.»

---

⚠️ Environment Requirements

Library menggunakan beberapa fungsi yang biasanya tersedia pada environment/executor yang mendukung filesystem dan HTTP, seperti:

loadstring
game:HttpGet
isfile
writefile
readfile
isfolder
makefolder
listfiles
delfile
setclipboard
getAsset

Tidak semua fungsi tersebut merupakan API standar Roblox Studio.

Karena itu, fitur tertentu seperti:

- Config
- Export clipboard
- Import clipboard
- Web image caching
- Key persistence
- Preset persistence

bergantung pada environment yang menyediakan fungsi terkait.

Jika sebuah fungsi environment tidak tersedia, library memiliki beberapa fallback sehingga bagian tertentu tetap dapat digunakan.

---

🗂️ File & Cache System

Library menggunakan folder utama:

Kys/

dan configuration:

Kys/Config/

Configuration per-game berada di:

Kys/Configs/<GameName>/

Nama game dibersihkan terlebih dahulu agar aman digunakan sebagai nama file/folder.

Library juga memiliki caching untuk nama game dan web image sehingga request yang sama tidak harus selalu dilakukan kembali.

---

🌐 Web Image

Library memiliki sistem untuk memuat image dari URL dan menyimpannya pada cache lokal jika environment mendukung filesystem dan asset loading.

Image cache menggunakan URL sebagai basis identifier dan menyimpan hasilnya secara lokal.

Hal ini membantu mengurangi kebutuhan untuk mengambil image yang sama berulang kali.

---

🛠️ Tips Pengembangan

1. Gunakan Section

Daripada:

Tab:AddToggle(...)
Tab:AddButton(...)
Tab:AddSlider(...)

gunakan:

local Section = Tab:AddSection("Features")

Section:AddToggle(...)
Section:AddButton(...)
Section:AddSlider(...)

Ini membuat layout lebih terorganisir.

---

2. Gunakan "Save = false" untuk data sementara

Contoh:

Section:AddInput({
    Title = "Temporary Input",
    Save = false
})

Ini berguna untuk input yang tidak perlu disimpan ke config.

---

3. Gunakan Custom GUI untuk interface kompleks

Jika element bawaan library tidak cukup:

Section:AddCustomGUI(MyFrame)

Tidak perlu memodifikasi source library hanya untuk membuat UI khusus.

Anda dapat membuat "Frame" sendiri dan memasukkannya ke library.

---

4. Gunakan HStack untuk layout horizontal

local Stack = Section:AddHStack({
    Padding = 8,
    Height = 40
})

Kemudian masukkan GUI custom ke dalam stack.

---

🧪 Debugging

Jika sebuah callback menghasilkan error, sebaiknya gunakan:

Callback = function(value)
    local success, err = pcall(function()
        -- code
    end)

    if not success then
        warn(err)
    end
end

Contoh:

Section:AddToggle({
    Title = "Example",

    Callback = function(value)
        local success, err = pcall(function()
            print(value)
        end)

        if not success then
            warn("[Example]", err)
        end
    end
})

---

📱 Mobile UI Guidelines

Karena library mendukung mobile, gunakan ukuran yang relatif fleksibel.

Direkomendasikan:

UDim2.new(1, -20, 0, 40)

daripada ukuran horizontal yang terlalu fixed.

Untuk custom GUI:

Frame.Size = UDim2.new(1, 0, 0, 150)

lebih fleksibel daripada:

Frame.Size = UDim2.new(0, 500, 0, 150)

---

🧩 Custom GUI Best Practices

Root custom GUI sebaiknya:

Frame.Size = UDim2.new(1, 0, 0, HEIGHT)

Kemudian gunakan child GUI untuk desain internal.

Contoh:

CustomFrame
├── Title
├── Description
├── Button
├── Image
└── Controls

Dengan cara ini custom GUI dapat mengikuti lebar Section secara otomatis.

---

📌 Full API Flow

Struktur API Kys UI:

Library
└── Window
    ├── Tab
    │   ├── Section
    │   │   ├── Paragraph
    │   │   ├── Button
    │   │   ├── Toggle
    │   │   ├── Slider
    │   │   ├── ColorPicker
    │   │   ├── Input
    │   │   ├── Keybind
    │   │   ├── Dropdown
    │   │   ├── Config
    │   │   ├── Banner
    │   │   ├── Card
    │   │   ├── CardWidget
    │   │   ├── Divider
    │   │   ├── SubSection
    │   │   ├── Space
    │   │   ├── HStack
    │   │   └── CustomGUI
    │   │
    │   └── CustomGUI
    │
    └── InfoTab

---

📜 License / Usage

Kys UI Library merupakan library UI untuk project Roblox yang menggunakan struktur API milik Kys UI.

Jika Anda menggunakan library ini dalam project Anda, disarankan untuk tetap memberikan credit kepada repository asli.

Repository:

KysHubNewUI

Library:

"Library-Kys.lua"

---

🔗 Repository

Source code:

https://github.com/Kys-lol/KysHubNewUI

Raw library:

https://raw.githubusercontent.com/Kys-lol/KysHubNewUI/refs/heads/main/Library-Kys.lua

---

❤️ Credits

Kys UI Library

Made and maintained by Kys.

Powered by the following integrated components/features:

- Roblox GUI API
- Footagesus Icons V2
- Lucide icon backend
- Roblox "UserInputService"
- Roblox "TweenService"
- Roblox "HttpService"
- Local filesystem APIs when available

---

⭐ Support

Jika library ini berguna untuk project Anda, berikan ⭐ pada repository GitHub.

Jika menemukan bug, sertakan:

1. Versi library
2. Executor/environment
3. Device
4. Script yang digunakan
5. Error yang muncul
6. Screenshot jika berkaitan dengan UI

Contoh laporan:

Kys UI Bug Report

Library:
Library-Kys.lua

Device:
Android

Environment:
[environment]

Feature:
Dropdown

Problem:
Dropdown tidak menampilkan option tertentu.

Error:
[error]

Reproduction:
1. Create Window
2. Add Tab
3. Add Section
4. Add Dropdown
5. Open dropdown

---

🚀 Minimal Template

Jika Anda hanya membutuhkan template awal:

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Kys-lol/KysHubNewUI/refs/heads/main/Library-Kys.lua"
))()

local Window = Library:Window({
    Title = "Kys Hub",
    Author = "Kys",
    Color = Color3.fromRGB(0, 170, 255),
    Search = true
})

local Main = Window:AddTab({
    Name = "Main",
    Icon = "home"
})

local Section = Main:AddSection("Features")

Section:AddToggle({
    Title = "Example",
    Default = false,

    Callback = function(value)
        print(value)
    end
})

Section:AddButton({
    Title = "Button",

    Callback = function()
        print("Clicked")
    end
})

---

🎯 Summary

Kys UI Library menyediakan dua pendekatan pembuatan UI:

Built-in UI

Gunakan:

AddButton()
AddToggle()
AddSlider()
AddDropdown()
AddInput()
AddColorPicker()

untuk membuat UI dengan cepat.

Fully Custom UI

Gunakan:

AddCustomGUI()

untuk memasukkan GUI Roblox buatan sendiri ke dalam Tab atau Section.

Dengan kombinasi keduanya, sebuah project dapat menggunakan element bawaan Kys UI untuk kebutuhan umum sekaligus membuat interface custom sepenuhnya ketika diperlukan.

Kys UI dirancang agar developer dapat membangun UI sederhana maupun interface kompleks tanpa harus dibatasi oleh element bawaan library.
