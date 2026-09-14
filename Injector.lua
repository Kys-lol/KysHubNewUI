local CoreGui = game:GetService("CoreGui")

local Injector = {}
local PREFIX = "[Roblox Studio Injector]"

local function log(...)
    print(PREFIX, ...)
end

local function warnx(...)
    warn(PREFIX, ...)
end

local function findRecursive(parent, name, className)
    if not parent then
        return nil
    end

    local direct = parent:FindFirstChild(name)

    if direct and (not className or direct:IsA(className)) then
        return direct
    end

    for _, object in ipairs(parent:GetDescendants()) do
        if object.Name == name and (not className or object:IsA(className)) then
            return object
        end
    end

    return nil
end

function Injector:GetRobloxGui()
    return CoreGui:FindFirstChild("RobloxGui")
end

function Injector:GetHelpContainer()
    local RobloxGui = self:GetRobloxGui()

    if not RobloxGui then
        return nil
    end

    local shield = RobloxGui:FindFirstChild("SettingsClippingShield", true)

    if shield then
        local settingsShield = shield:FindFirstChild("SettingsShield")
        local menuContainer = settingsShield and settingsShield:FindFirstChild("MenuContainer")
        local page = menuContainer and menuContainer:FindFirstChild("Page")
        local clipper = page and page:FindFirstChild("PageViewClipper")
        local pageView = clipper and clipper:FindFirstChild("PageView")
        local inner = pageView and pageView:FindFirstChild("PageViewInnerFrame")
        local help = inner and inner:FindFirstChild("Help")
        local container = help and help:FindFirstChild("HelpPageContainer")

        if container then
            return container
        end
    end

    return findRecursive(RobloxGui, "HelpPageContainer", "Frame")
        or findRecursive(RobloxGui, "HelpPage", "Frame")
        or findRecursive(RobloxGui, "HelpTabContainer", "Frame")
end

function Injector:GetContentBounds(container)
    if not container then
        return nil
    end

    local containerPosition = container.AbsolutePosition
    local containerSize = container.AbsoluteSize
    local top = containerSize.Y

    local candidates = {
        "Leave",
        "Respawn",
        "Resume",
    }

    local found = {}

    for _, object in ipairs(container:GetDescendants()) do
        if object:IsA("TextButton") then
            local text = string.lower(tostring(object.Text or ""))
            local name = string.lower(object.Name)

            for _, candidate in ipairs(candidates) do
                local target = string.lower(candidate)
                if text == target or name == target then
                    found[target] = object
                    break
                end
            end
        end
    end

    local robloxGui = self:GetRobloxGui()

    if robloxGui then
        for _, object in ipairs(robloxGui:GetDescendants()) do
            if object:IsA("GuiButton") then
                local text = string.lower(tostring(object.Text or ""))
                local name = string.lower(object.Name)

                for _, candidate in ipairs(candidates) do
                    local target = string.lower(candidate)
                    if not found[target] and (text == target or name == target) then
                        found[target] = object
                        break
                    end
                end
            end
        end
    end

    local matchedTop = nil

    for _, object in pairs(found) do
        if object and object.Visible then
            local y = object.AbsolutePosition.Y - containerPosition.Y
            if y >= 0 and y < containerSize.Y then
                if matchedTop == nil or y < matchedTop then
                    matchedTop = y
                end
            end
        end
    end

    if matchedTop then
        top = math.max(0, math.floor(matchedTop))
    end

    return {
        X = containerSize.X,
        Y = top,
    }
end

function Injector:PrepareContainer(container, contentName)
    if not container then
        return false
    end

    contentName = contentName or "RobloxStudioContent"

    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= contentName then
            local lower = string.lower(child.Name)
            local isBackground = string.find(lower, "background", 1, true)
                or string.find(lower, "blur", 1, true)
                or string.find(lower, "backdrop", 1, true)

            if not isBackground then
                child.Visible = false
            end
        end
    end

    return true
end

function Injector:SetMenuName(name)
    local RobloxGui = self:GetRobloxGui()

    if not RobloxGui then
        return false
    end

    local hubBar = findRecursive(RobloxGui, "HubBarContainer")

    if not hubBar then
        return false
    end

    local helpTab = hubBar:FindFirstChild("HelpTab")
        or findRecursive(hubBar, "HelpTab", "GuiObject")

    if not helpTab then
        return false
    end

    local tabLabel = findRecursive(helpTab, "TabLabel", "GuiObject")
    local title = tabLabel and findRecursive(tabLabel, "Title")

    if title and (
        title:IsA("TextLabel")
        or title:IsA("TextButton")
        or title:IsA("TextBox")
    ) then
        title.Text = tostring(name or "[Roblox Studio]")
        return true
    end

    return false
end

function Injector:Inject(library)
    if not library or type(library.Mount) ~= "function" then
        warnx("Invalid library passed to Inject().")
        return false
    end

    local container = self:GetHelpContainer()

    if not container then
        warnx("HelpPageContainer not found.")
        return false
    end

    self:PrepareContainer(container, "RobloxStudioContent")

    local ok, result = pcall(function()
        return library:Mount(container)
    end)

    if not ok or result == false then
        warnx("Library mount failed:", result)
        return false
    end

    log("Library mounted into native Help container.")
    return true
end

return Injector
