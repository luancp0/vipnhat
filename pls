--[[ 
███████╗██╗      ██████╗  ██████╗ ██████╗  ██████╗ ██╗  ██╗
██╔════╝██║     ██╔═══██╗██╔════╝ ██╔══██╗██╔═══██╗╚██╗██╔╝
█████╗  ██║     ██║   ██║██║  ███╗██████╔╝██║   ██║ ╚███╔╝ 
██╔══╝  ██║     ██║   ██║██║   ██║██╔═══╝ ██║   ██║ ██╔██╗ 
██║     ███████╗╚██████╔╝╚██████╔╝██║     ╚██████╔╝██╔╝ ██╗
╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝
                                                           
Enhanced Script v2.0 - Password Protected
]]

-- Configuration
local KEY = "123456"
local ADMIN_PASSWORD = "987654321" -- Admin password for VIP features
local EXPIRATION_DATE = {
	Year = 2025,
	Month = 6,
	Day = 30,
	Hour = 0,
	Minute = 0,
	Second = 0
}

-- Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Local Player and References
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera

-- State Variables
local Authenticated = false
local AdminAuthenticated = false
local NoClipping = false
local AutoPlatform = false
local RunningAway = false
local FollowingTarget = false
local AutoNextTarget = false
local LookTarget = nil
local LookBodyPart = "Head"
local BodyParts = {"Head", "UpperTorso", "HumanoidRootPart", "LeftFoot", "RightFoot"}
local BodyPartIndex = 1
local DistanceBehind = 5
local DistanceAbove = 0
local DetectionRadius = 20
local SavedPosition = nil
local PlayerList = {}
local TargetPlayer = nil
local CurrentPanel = nil -- For tracking which settings panel is open

-- EXP Name Display Config
local DisplayFontSize = 14
local DisplayMode = "name" -- "name", "hp", "distance"
local DisplayColor = Color3.fromRGB(255,255,255)
local AllowWallDisplay = false
local ShowExpName = true
local ShowHP = true

-- Icon Settings
local IconSize = UDim2.new(0, 40, 0, 40)
local IconDraggable = false
local IconURL = "rbxassetid://7072719455" -- default

-- Settings Categories
local SettingsCategories = {
    "Display",
    "Targeting",
    "Movement",
    "Appearance",
    "Advanced"
}

-- Utility Functions
local function createTween(object, properties, duration, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration or 0.3,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    return tween
end

local function createRippleEffect(button)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    
    local corner = Instance.new("UICorner", ripple)
    corner.CornerRadius = UDim.new(1, 0)
    
    ripple.Parent = button
    
    local buttonSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.5
    local goal = UDim2.new(0, buttonSize, 0, buttonSize)
    
    local tween = createTween(ripple, {Size = goal, BackgroundTransparency = 1}, 0.5)
    tween:Play()
    
    tween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

local function isExpired()
    local now = os.time()
    local expire = os.time({
        year = EXPIRATION_DATE.Year,
        month = EXPIRATION_DATE.Month,
        day = EXPIRATION_DATE.Day,
        hour = EXPIRATION_DATE.Hour,
        min = EXPIRATION_DATE.Minute,
        sec = EXPIRATION_DATE.Second,
    })
    return now > expire
end

local function saveSettings()
    -- Create settings table
    local settings = {
        DisplayFontSize = DisplayFontSize,
        DisplayMode = DisplayMode,
        DisplayColor = {
            R = DisplayColor.R,
            G = DisplayColor.G,
            B = DisplayColor.B
        },
        AllowWallDisplay = AllowWallDisplay,
        ShowExpName = ShowExpName,
        ShowHP = ShowHP,
        IconSize = {
            X = IconSize.X.Scale,
            XOffset = IconSize.X.Offset,
            Y = IconSize.Y.Scale,
            YOffset = IconSize.Y.Offset
        },
        IconDraggable = IconDraggable,
        IconURL = IconURL,
        DistanceBehind = DistanceBehind,
        DistanceAbove = DistanceAbove,
        DetectionRadius = DetectionRadius
    }
    
    -- Convert to JSON and save to GlobalStorage
    local success, result = pcall(function()
        return HttpService:JSONEncode(settings)
    end)
    
    if success then
        -- In a real script, you would save this to a file or datastore
        -- For now, we'll just print it
        print("Settings saved: " .. result)
    end
end

local function loadSettings()
    -- In a real script, you would load from a file or datastore
    -- For this example, we'll just use the defaults
    -- This is where you would decode the JSON and apply the settings
    print("Settings loaded")
end

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "ExecutorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainUICorner = Instance.new("UICorner", MainFrame)
MainUICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

local TitleBarCorner = Instance.new("UICorner", TitleBar)
TitleBarCorner.CornerRadius = UDim.new(0, 10)

local TitleBarBottom = Instance.new("Frame", TitleBar)
TitleBarBottom.Size = UDim2.new(1, 0, 0.5, 0)
TitleBarBottom.Position = UDim2.new(0, 0, 0.5, 0)
TitleBarBottom.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TitleBarBottom.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "Roblox Executor Script v2.0"

local SettingsButton = Instance.new("TextButton", TitleBar)
SettingsButton.Size = UDim2.new(0, 30, 0, 30)
SettingsButton.Position = UDim2.new(1, -90, 0, 0)
SettingsButton.Text = "⚙️"
SettingsButton.Font = Enum.Font.SourceSansBold
SettingsButton.TextColor3 = Color3.fromRGB(255,255,255)
SettingsButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SettingsButton.BackgroundTransparency = 1
SettingsButton.TextSize = 16

local MinimizeButton = Instance.new("TextButton", TitleBar)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.TextSize = 20

local CloseButton = Instance.new("TextButton", TitleBar)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Text = "×"
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
CloseButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CloseButton.BackgroundTransparency = 1
CloseButton.TextSize = 20

-- Auth Frame
local AuthFrame = Instance.new("Frame", MainFrame)
AuthFrame.Size = UDim2.new(1, 0, 1, -30)
AuthFrame.Position = UDim2.new(0, 0, 0, 30)
AuthFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)

local AuthTitle = Instance.new("TextLabel", AuthFrame)
AuthTitle.Text = "Enter Access Key"
AuthTitle.Font = Enum.Font.SourceSansBold
AuthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
AuthTitle.TextSize = 18
AuthTitle.Position = UDim2.new(0.1, 0, 0.1, 0)
AuthTitle.Size = UDim2.new(0.8, 0, 0, 30)
AuthTitle.BackgroundTransparency = 1

local KeyInput = Instance.new("TextBox", AuthFrame)
KeyInput.PlaceholderText = "Enter Key..."
KeyInput.Text = ""
KeyInput.Font = Enum.Font.SourceSans
KeyInput.TextSize = 16
KeyInput.ClearTextOnFocus = false
KeyInput.BackgroundColor3 = Color3.fromRGB(45,45,45)
KeyInput.TextColor3 = Color3.fromRGB(255,255,255)
KeyInput.Position = UDim2.new(0.1, 0, 0.3, 0)
KeyInput.Size = UDim2.new(0.8, 0, 0, 35)

local KeyInputCorner = Instance.new("UICorner", KeyInput)
KeyInputCorner.CornerRadius = UDim.new(0, 5)

local SubmitKey = Instance.new("TextButton", AuthFrame)
SubmitKey.Text = "Submit"
SubmitKey.Font = Enum.Font.SourceSansBold
SubmitKey.TextSize = 16
SubmitKey.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SubmitKey.TextColor3 = Color3.fromRGB(255,255,255)
SubmitKey.Size = UDim2.new(0.6, 0, 0, 35)
SubmitKey.Position = UDim2.new(0.2, 0, 0.5, 0)

local SubmitKeyCorner = Instance.new("UICorner", SubmitKey)
SubmitKeyCorner.CornerRadius = UDim.new(0, 5)

-- Main Controls Frame
local MainControls = Instance.new("Frame", MainFrame)
MainControls.Size = UDim2.new(1, 0, 1, -30)
MainControls.Position = UDim2.new(0, 0, 0, 30)
MainControls.Visible = false
MainControls.BackgroundColor3 = Color3.fromRGB(32,32,32)
MainControls.ClipsDescendants = true

local ScrollingFrame = Instance.new("ScrollingFrame", MainControls)
ScrollingFrame.Size = UDim2.new(1, -10, 1, -10)
ScrollingFrame.Position = UDim2.new(0, 5, 0, 5)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 800) -- Will adjust based on content

local UIListLayout = Instance.new("UIListLayout", ScrollingFrame)
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Settings Frame
local SettingsFrame = Instance.new("Frame", MainFrame)
SettingsFrame.Size = UDim2.new(1, 0, 1, -30)
SettingsFrame.Position = UDim2.new(0, 0, 0, 30)
SettingsFrame.Visible = false
SettingsFrame.BackgroundColor3 = Color3.fromRGB(32,32,32)
SettingsFrame.ClipsDescendants = true

local SettingsTitle = Instance.new("TextLabel", SettingsFrame)
SettingsTitle.Text = "Settings"
SettingsTitle.Font = Enum.Font.SourceSansBold
SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsTitle.TextSize = 18
SettingsTitle.Position = UDim2.new(0, 0, 0, 5)
SettingsTitle.Size = UDim2.new(1, 0, 0, 30)
SettingsTitle.BackgroundTransparency = 1

local SettingsTabs = Instance.new("Frame", SettingsFrame)
SettingsTabs.Size = UDim2.new(1, 0, 0, 40)
SettingsTabs.Position = UDim2.new(0, 0, 0, 35)
SettingsTabs.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local TabsLayout = Instance.new("UIListLayout", SettingsTabs)
TabsLayout.FillDirection = Enum.FillDirection.Horizontal
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Padding = UDim.new(0, 2)

-- Create tab buttons
local SettingsPanels = {}
for i, category in ipairs(SettingsCategories) do
    local tabButton = Instance.new("TextButton", SettingsTabs)
    tabButton.Text = category
    tabButton.Font = Enum.Font.SourceSansSemibold
    tabButton.TextSize = 14
    tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.Size = UDim2.new(1/#SettingsCategories, -2, 1, 0)
    tabButton.Name = category .. "Tab"
    
    local panel = Instance.new("ScrollingFrame", SettingsFrame)
    panel.Size = UDim2.new(1, -20, 1, -85)
    panel.Position = UDim2.new(0, 10, 0, 85)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 4
    panel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    panel.CanvasSize = UDim2.new(0, 0, 0, 500)
    panel.Visible = i == 1 -- First panel visible by default
    panel.Name = category .. "Panel"
    
    local panelLayout = Instance.new("UIListLayout", panel)
    panelLayout.Padding = UDim.new(0, 10)
    panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    SettingsPanels[category] = panel
    
    if i == 1 then
        tabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CurrentPanel = category
    end
    
    tabButton.MouseButton1Click:Connect(function()
        -- Reset all tabs
        for _, cat in ipairs(SettingsCategories) do
            local tab = SettingsTabs:FindFirstChild(cat .. "Tab")
            local pnl = SettingsFrame:FindFirstChild(cat .. "Panel")
            if tab and pnl then
                tab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                tab.TextColor3 = Color3.fromRGB(200, 200, 200)
                pnl.Visible = false
            end
        end
        
        -- Activate selected tab
        tabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        panel.Visible = true
        CurrentPanel = category
        
        createRippleEffect(tabButton)
    end)
end

local BackButton = Instance.new("TextButton", SettingsFrame)
BackButton.Text = "Back to Main"
BackButton.Font = Enum.Font.SourceSansBold
BackButton.TextSize = 14
BackButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
BackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BackButton.Size = UDim2.new(0.4, 0, 0, 30)
BackButton.Position = UDim2.new(0.05, 0, 1, -40)

local BackButtonCorner = Instance.new("UICorner", BackButton)
BackButtonCorner.CornerRadius = UDim.new(0, 5)

local SaveButton = Instance.new("TextButton", SettingsFrame)
SaveButton.Text = "Save Settings"
SaveButton.Font = Enum.Font.SourceSansBold
SaveButton.TextSize = 14
SaveButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.Size = UDim2.new(0.4, 0, 0, 30)
SaveButton.Position = UDim2.new(0.55, 0, 1, -40)

local SaveButtonCorner = Instance.new("UICorner", SaveButton)
SaveButtonCorner.CornerRadius = UDim.new(0, 5)

-- Minimize Icon GUI
local IconFrame = Instance.new("ImageButton", ScreenGui)
IconFrame.Size = IconSize
IconFrame.Position = UDim2.new(0, 20, 0.5, -20)
IconFrame.BackgroundTransparency = 1
IconFrame.Image = IconURL
IconFrame.Visible = false
IconFrame.Draggable = IconDraggable

-- Create section headers and controls for each settings panel
local function createSettingSection(panel, title, layoutOrder)
    local section = Instance.new("Frame", panel)
    section.Size = UDim2.new(1, 0, 0, 30)
    section.BackgroundTransparency = 1
    section.LayoutOrder = layoutOrder
    
    local sectionTitle = Instance.new("TextLabel", section)
    sectionTitle.Text = title
    sectionTitle.Font = Enum.Font.SourceSansBold
    sectionTitle.TextSize = 16
    sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionTitle.Size = UDim2.new(1, 0, 1, 0)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    return section
end

local function createToggle(panel, text, initialState, callback, layoutOrder)
    local toggle = Instance.new("Frame", panel)
    toggle.Size = UDim2.new(1, 0, 0, 30)
    toggle.BackgroundTransparency = 1
    toggle.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel", toggle)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local button = Instance.new("TextButton", toggle)
    button.Text = initialState and "ON" or "OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Size = UDim2.new(0.25, 0, 1, 0)
    button.Position = UDim2.new(0.75, 0, 0, 0)
    
    local buttonCorner = Instance.new("UICorner", button)
    buttonCorner.CornerRadius = UDim.new(0, 5)
    
    local state = initialState
    
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        
        if callback then
            callback(state)
        end
        
        createRippleEffect(button)
    end)
    
    return toggle, button
end

local function createSlider(panel, text, min, max, initialValue, callback, layoutOrder)
    local sliderFrame = Instance.new("Frame", panel)
    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel", sliderFrame)
    label.Text = text .. ": " .. initialValue
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local sliderBg = Instance.new("Frame", sliderFrame)
    sliderBg.Size = UDim2.new(1, 0, 0, 10)
    sliderBg.Position = UDim2.new(0, 0, 0.6, 0)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    local sliderBgCorner = Instance.new("UICorner", sliderBg)
    sliderBgCorner.CornerRadius = UDim.new(0, 5)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new((initialValue - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    
    local sliderFillCorner = Instance.new("UICorner", sliderFill)
    sliderFillCorner.CornerRadius = UDim.new(0, 5)
    
    local sliderButton = Instance.new("TextButton", sliderBg)
    sliderButton.Text = ""
    sliderButton.Size = UDim2.new(1, 0, 1, 0)
    sliderButton.BackgroundTransparency = 1
    
    local value = initialValue
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local newValue = math.floor(min + (max - min) * pos)
        
        value = newValue
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. value
        
        if callback then
            callback(value)
        end
    end
    
    sliderButton.MouseButton1Down:Connect(function(x, y)
        local input = {Position = Vector2.new(x, y)}
        updateSlider(input)
        
        local connection
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end)
    end)
    
    return sliderFrame, value
end

local function createTextInput(panel, text, initialValue, callback, layoutOrder)
    local inputFrame = Instance.new("Frame", panel)
    inputFrame.Size = UDim2.new(1, 0, 0, 50)
    inputFrame.BackgroundTransparency = 1
    inputFrame.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel", inputFrame)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local input = Instance.new("TextBox", inputFrame)
    input.PlaceholderText = "Enter value..."
    input.Text = initialValue or ""
    input.Font = Enum.Font.SourceSans
    input.TextSize = 14
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    input.Size = UDim2.new(1, 0, 0, 30)
    input.Position = UDim2.new(0, 0, 0.4, 0)
    input.ClearTextOnFocus = false
    
    local inputCorner = Instance.new("UICorner", input)
    inputCorner.CornerRadius = UDim.new(0, 5)
    
    input.FocusLost:Connect(function(enterPressed)
        if callback then
            callback(input.Text, enterPressed)
        end
    end)
    
    return inputFrame, input
end

local function createColorPicker(panel, text, initialColor, callback, layoutOrder)
    local colorFrame = Instance.new("Frame", panel)
    colorFrame.Size = UDim2.new(1, 0, 0, 70)
    colorFrame.BackgroundTransparency = 1
    colorFrame.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel", colorFrame)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local colorDisplay = Instance.new("Frame", colorFrame)
    colorDisplay.Size = UDim2.new(0.2, 0, 0, 30)
    colorDisplay.Position = UDim2.new(0, 0, 0.4, 0)
    colorDisplay.BackgroundColor3 = initialColor or Color3.fromRGB(255, 255, 255)
    
    local colorDisplayCorner = Instance.new("UICorner", colorDisplay)
    colorDisplayCorner.CornerRadius = UDim.new(0, 5)
    
    local hexInput = Instance.new("TextBox", colorFrame)
    hexInput.PlaceholderText = "Hex: #RRGGBB"
    hexInput.Text = "#" .. string.format("%02X%02X%02X", 
        math.floor(initialColor.R * 255), 
        math.floor(initialColor.G * 255), 
        math.floor(initialColor.B * 255))
    hexInput.Font = Enum.Font.SourceSans
    hexInput.TextSize = 14
    hexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hexInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    hexInput.Size = UDim2.new(0.35, 0, 0, 30)
    hexInput.Position = UDim2.new(0.22, 0, 0.4, 0)
    hexInput.ClearTextOnFocus = false
    
    local hexInputCorner = Instance.new("UICorner", hexInput)
    hexInputCorner.CornerRadius = UDim.new(0, 5)
    
    local rgbInput = Instance.new("TextBox", colorFrame)
    rgbInput.PlaceholderText = "RGB: R,G,B"
    rgbInput.Text = string.format("%d,%d,%d", 
        math.floor(initialColor.R * 255), 
        math.floor(initialColor.G * 255), 
        math.floor(initialColor.B * 255))
    rgbInput.Font = Enum.Font.SourceSans
    rgbInput.TextSize = 14
    rgbInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    rgbInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    rgbInput.Size = UDim2.new(0.4, 0, 0, 30)
    rgbInput.Position = UDim2.new(0.6, 0, 0.4, 0)
    rgbInput.ClearTextOnFocus = false
    
    local rgbInputCorner = Instance.new("UICorner", rgbInput)
    rgbInputCorner.CornerRadius = UDim.new(0, 5)
    
    local currentColor = initialColor
    
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text
        if string.sub(hex, 1, 1) == "#" then
            hex = string.sub(hex, 2)
        end
        
        if string.len(hex) == 6 then
            local r = tonumber(string.sub(hex, 1, 2), 16) or 255
            local g = tonumber(string.sub(hex, 3, 4), 16) or 255
            local b = tonumber(string.sub(hex, 5, 6), 16) or 255
            
            currentColor = Color3.fromRGB(r, g, b)
            colorDisplay.BackgroundColor3 = currentColor
            rgbInput.Text = string.format("%d,%d,%d", r, g, b)
            
            if callback then
                callback(currentColor)
            end
        end
    end)
    
    rgbInput.FocusLost:Connect(function()
        local r, g, b = rgbInput.Text:match("(%d+),(%d+),(%d+)")
        
        if r and g and b then
            r, g, b = tonumber(r), tonumber(g), tonumber(b)
            if r <= 255 and g <= 255 and b <= 255 then
                currentColor = Color3.fromRGB(r, g, b)
                colorDisplay.BackgroundColor3 = currentColor
                hexInput.Text = "#" .. string.format("%02X%02X%02X", r, g, b)
                
                if callback then
                    callback(currentColor)
                end
            end
        end
    end)
    
    return colorFrame, currentColor
end

local function createDropdown(panel, text, options, initialOption, callback, layoutOrder)
    local dropdownFrame = Instance.new("Frame", panel)
    dropdownFrame.Size = UDim2.new(1, 0, 0, 60)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel", dropdownFrame)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local dropdownButton = Instance.new("TextButton", dropdownFrame)
    dropdownButton.Text = initialOption or options[1]
    dropdownButton.Font = Enum.Font.SourceSans
    dropdownButton.TextSize = 14
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdownButton.Size = UDim2.new(1, 0, 0, 30)
    dropdownButton.Position = UDim2.new(0, 0, 0.5, 0)
    
    local dropdownButtonCorner = Instance.new("UICorner", dropdownButton)
    dropdownButtonCorner.CornerRadius = UDim.new(0, 5)
    
    local dropdownMenu = Instance.new("Frame", dropdownFrame)
    dropdownMenu.Size = UDim2.new(1, 0, 0, #options * 30)
    dropdownMenu.Position = UDim2.new(0, 0, 1, 5)
    dropdownMenu.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    dropdownMenu.Visible = false
    dropdownMenu.ZIndex = 10
    
    local dropdownMenuCorner = Instance.new("UICorner", dropdownMenu)
    dropdownMenuCorner.CornerRadius = UDim.new(0, 5)
    
    local dropdownLayout = Instance.new("UIListLayout", dropdownMenu)
    dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton", dropdownMenu)
        optionButton.Text = option
        optionButton.Font = Enum.Font.SourceSans
        optionButton.TextSize = 14
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        optionButton.BackgroundTransparency = 0.5
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.ZIndex = 10
        
        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            dropdownMenu.Visible = false
            
            if callback then
                callback(option)
            end
            
            createRippleEffect(optionButton)
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        dropdownMenu.Visible = not dropdownMenu.Visible
        createRippleEffect(dropdownButton)
    end)
    
    return dropdownFrame, dropdownButton
end

local function createButton(panel, text, callback, color, layoutOrder)
    local buttonFrame = Instance.new("Frame", panel)
    buttonFrame.Size = UDim2.new(1, 0, 0, 40)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.LayoutOrder = layoutOrder
    
    local button = Instance.new("TextButton", buttonFrame)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = color or Color3.fromRGB(0, 120, 215)
    button.Size = UDim2.new(1, 0, 1, 0)
    
    local buttonCorner = Instance.new("UICorner", button)
    buttonCorner.CornerRadius = UDim.new(0, 5)
    
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
        
        createRippleEffect(button)
    end)
    
    return buttonFrame, button
end

-- Populate Display Settings Panel
local displayPanel = SettingsPanels["Display"]

createSettingSection(displayPanel, "Name Display Settings", 1)

createToggle(displayPanel, "Show Player Names", ShowExpName, function(state)
    ShowExpName = state
end, 2)

createToggle(displayPanel, "Show HP Values", ShowHP, function(state)
    ShowHP = state
end, 3)

createToggle(displayPanel, "X-Ray Vision (See Through Walls)", AllowWallDisplay, function(state)
    AllowWallDisplay = state
end, 4)

createSlider(displayPanel, "Font Size", 8, 24, DisplayFontSize, function(value)
    DisplayFontSize = value
end, 5)

createColorPicker(displayPanel, "Text Color", DisplayColor, function(color)
    DisplayColor = color
end, 6)

createDropdown(displayPanel, "Display Mode", {"name", "distance", "hp"}, DisplayMode, function(option)
    DisplayMode = option
end, 7)

-- Populate Targeting Settings Panel
local targetingPanel = SettingsPanels["Targeting"]

createSettingSection(targetingPanel, "Target Selection", 1)

createSlider(targetingPanel, "Detection Radius", 5, 100, DetectionRadius, function(value)
    DetectionRadius = value
end, 2)

createToggle(targetingPanel, "Auto-Next Target", AutoNextTarget, function(state)
    AutoNextTarget = state
    if AutoNextButton then
        AutoNextButton.Text = "Auto Next: " .. (state and "ON" or "OFF")
    end
end, 3)

createDropdown(targetingPanel, "Look At Body Part", BodyParts, LookBodyPart, function(option)
    LookBodyPart = option
    for i, part in ipairs(BodyParts) do
        if part == option then
            BodyPartIndex = i
            break
        end
    end
    if LookAtButton then
        LookAtButton.Text = "Look At (" .. option .. ")"
    end
end, 4)

-- Populate Movement Settings Panel
local movementPanel = SettingsPanels["Movement"]

createSettingSection(movementPanel, "Follow Settings", 1)

createToggle(movementPanel, "Follow Target", FollowingTarget, function(state)
    FollowingTarget = state
    if FollowButton then
        FollowButton.Text = "Follow: " .. (state and "ON" or "OFF")
    end
end, 2)

createSlider(movementPanel, "Distance Behind", 1, 20, DistanceBehind, function(value)
    DistanceBehind = value
end, 3)

createSlider(movementPanel, "Height Offset", -5, 10, DistanceAbove, function(value)
    DistanceAbove = value
end, 4)

-- Populate Appearance Settings Panel
local appearancePanel = SettingsPanels["Appearance"]

createSettingSection(appearancePanel, "Icon Settings", 1)

createTextInput(appearancePanel, "Icon URL", IconURL, function(value)
    IconURL = value
    IconFrame.Image = value
end, 2)

createToggle(appearancePanel, "Icon Draggable", IconDraggable, function(state)
    IconDraggable = state
    IconFrame.Draggable = state
    if DragToggle then
        DragToggle.Text = "Drag Icon: " .. (state and "ON" or "OFF")
    end
end, 3)

createTextInput(appearancePanel, "Icon Size X", tostring(IconSize.X.Offset), function(value)
    local size = tonumber(value)
    if size then
        IconSize = UDim2.new(0, size, 0, IconSize.Y.Offset)
        IconFrame.Size = IconSize
    end
end, 4)

createTextInput(appearancePanel, "Icon Size Y", tostring(IconSize.Y.Offset), function(value)
    local size = tonumber(value)
    if size then
        IconSize = UDim2.new(0, IconSize.X.Offset, 0, size)
        IconFrame.Size = IconSize
    end
end, 5)

-- Populate Advanced Settings Panel
local advancedPanel = SettingsPanels["Advanced"]

createSettingSection(advancedPanel, "Admin Settings", 1)

local adminPassInput, adminPassBox = createTextInput(advancedPanel, "Admin Password", "", function(value)
    if value == ADMIN_PASSWORD then
        AdminAuthenticated = true
        adminPassBox.Text = "Authenticated!"
        adminPassBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        AdminAuthenticated = false
        adminPassBox.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end, 2)

createButton(advancedPanel, "Apply VIP Icon", function()
    if AdminAuthenticated then
        IconURL = "https://i.postimg.cc/jqH5FgNg/1747049246632.webp"
        IconFrame.Image = IconURL
    end
end, Color3.fromRGB(255, 165, 0), 3)

createButton(advancedPanel, "Reset All Settings", function()
    if AdminAuthenticated then
        -- Reset to defaults
        DisplayFontSize = 14
        DisplayMode = "name"
        DisplayColor = Color3.fromRGB(255,255,255)
        AllowWallDisplay = false
        ShowExpName = true
        ShowHP = true
        IconSize = UDim2.new(0, 40, 0, 40)
        IconDraggable = false
        IconURL = "rbxassetid://7072719455"
        DistanceBehind = 5
        DistanceAbove = 0
        DetectionRadius = 20
        
        -- Update UI
        IconFrame.Size = IconSize
        IconFrame.Image = IconURL
        IconFrame.Draggable = IconDraggable
    end
end, Color3.fromRGB(200, 50, 50), 4)

-- Player List Section for Main Controls
local TargetSection = Instance.new("Frame", ScrollingFrame)
TargetSection.Size = UDim2.new(0.9, 0, 0, 150)
TargetSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TargetSection.LayoutOrder = 1

local TargetSectionCorner = Instance.new("UICorner", TargetSection)
TargetSectionCorner.CornerRadius = UDim.new(0, 8)

local TargetTitle = Instance.new("TextLabel", TargetSection)
TargetTitle.Text = "Target Selection"
TargetTitle.Font = Enum.Font.SourceSansBold
TargetTitle.TextSize = 16
TargetTitle.TextColor3 = Color3.fromRGB(255,255,255)
TargetTitle.Position = UDim2.new(0.05, 0, 0.03, 0)
TargetTitle.Size = UDim2.new(0.9, 0, 0, 25)
TargetTitle.BackgroundTransparency = 1

local TargetDropdown = Instance.new("TextButton", TargetSection)
TargetDropdown.Text = "Select Target"
TargetDropdown.Font = Enum.Font.SourceSans
TargetDropdown.TextSize = 14
TargetDropdown.BackgroundColor3 = Color3.fromRGB(55,55,55)
TargetDropdown.TextColor3 = Color3.fromRGB(255,255,255)
TargetDropdown.Position = UDim2.new(0.05, 0, 0.25, 0)
TargetDropdown.Size = UDim2.new(0.55, 0, 0, 30)

local TargetDropdownCorner = Instance.new("UICorner", TargetDropdown)
TargetDropdownCorner.CornerRadius = UDim.new(0, 5)

local ReloadButton = Instance.new("TextButton", TargetSection)
ReloadButton.Text = "Reload"
ReloadButton.Font = Enum.Font.SourceSans
ReloadButton.TextSize = 14
ReloadButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
ReloadButton.TextColor3 = Color3.fromRGB(255,255,255)
ReloadButton.Position = UDim2.new(0.63, 0, 0.25, 0)
ReloadButton.Size = UDim2.new(0.3, 0, 0, 30)

local ReloadButtonCorner = Instance.new("UICorner", ReloadButton)
ReloadButtonCorner.CornerRadius = UDim.new(0, 5)

local NearestButton = Instance.new("TextButton", TargetSection)
NearestButton.Text = "Select Nearest"
NearestButton.Font = Enum.Font.SourceSansBold
NearestButton.TextSize = 14
NearestButton.BackgroundColor3 = Color3.fromRGB(255,165,0)
NearestButton.TextColor3 = Color3.fromRGB(255,255,255)
NearestButton.Position = UDim2.new(0.05, 0, 0.5, 0)
NearestButton.Size = UDim2.new(0.9, 0, 0, 30)

local NearestButtonCorner = Instance.new("UICorner", NearestButton)
NearestButtonCorner.CornerRadius = UDim.new(0, 5)

-- Action Buttons Section
local ActionSection = Instance.new("Frame", ScrollingFrame)
ActionSection.Size = UDim2.new(0.9, 0, 0, 200)
ActionSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ActionSection.LayoutOrder = 2

local ActionSectionCorner = Instance.new("UICorner", ActionSection)
ActionSectionCorner.CornerRadius = UDim.new(0, 8)

local ActionTitle = Instance.new("TextLabel", ActionSection)
ActionTitle.Text = "Actions"
ActionTitle.Font = Enum.Font.SourceSansBold
ActionTitle.TextSize = 16
ActionTitle.TextColor3 = Color3.fromRGB(255,255,255)
ActionTitle.Position = UDim2.new(0.05, 0, 0.03, 0)
ActionTitle.Size = UDim2.new(0.9, 0, 0, 25)
ActionTitle.BackgroundTransparency = 1

-- Follow Button
local FollowButton = Instance.new("TextButton", ActionSection)
FollowButton.Text = "Follow: OFF"
FollowButton.Font = Enum.Font.SourceSansBold
FollowButton.TextSize = 14
FollowButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
FollowButton.TextColor3 = Color3.fromRGB(255,255,255)
FollowButton.Position = UDim2.new(0.05, 0, 0.2, 0)
FollowButton.Size = UDim2.new(0.9, 0, 0, 30)

local FollowButtonCorner = Instance.new("UICorner", FollowButton)
FollowButtonCorner.CornerRadius = UDim.new(0, 5)

-- Auto Next Toggle
local AutoNextButton = Instance.new("TextButton", ActionSection)
AutoNextButton.Text = "Auto Next: OFF"
AutoNextButton.Font = Enum.Font.SourceSansBold
AutoNextButton.TextSize = 14
AutoNextButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
AutoNextButton.TextColor3 = Color3.fromRGB(255,255,255)
AutoNextButton.Position = UDim2.new(0.05, 0, 0.35, 0)
AutoNextButton.Size = UDim2.new(0.9, 0, 0, 30)

local AutoNextButtonCorner = Instance.new("UICorner", AutoNextButton)
AutoNextButtonCorner.CornerRadius = UDim.new(0, 5)

-- Look At Button
local LookAtButton = Instance.new("TextButton", ActionSection)
LookAtButton.Text = "Look At (Head)"
LookAtButton.Font = Enum.Font.SourceSansBold
LookAtButton.TextSize = 14
LookAtButton.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
LookAtButton.TextColor3 = Color3.fromRGB(255,255,255)
LookAtButton.Position = UDim2.new(0.05, 0, 0.5, 0)
LookAtButton.Size = UDim2.new(0.9, 0, 0, 30)

local LookAtButtonCorner = Instance.new("UICorner", LookAtButton)
LookAtButtonCorner.CornerRadius = UDim.new(0, 5)

-- Teleport Behind
local TeleportButton = Instance.new("TextButton", ActionSection)
TeleportButton.Text = "Teleport Behind"
TeleportButton.Font = Enum.Font.SourceSansBold
TeleportButton.TextSize = 14
TeleportButton.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
TeleportButton.TextColor3 = Color3.fromRGB(255,255,255)
TeleportButton.Position = UDim2.new(0.05, 0, 0.65, 0)
TeleportButton.Size = UDim2.new(0.9, 0, 0, 30)

local TeleportButtonCorner = Instance.new("UICorner", TeleportButton)
TeleportButtonCorner.CornerRadius = UDim.new(0, 5)

-- Advanced Features Section
local AdvancedSection = Instance.new("Frame", ScrollingFrame)
AdvancedSection.Size = UDim2.new(0.9, 0, 0, 150)
AdvancedSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AdvancedSection.LayoutOrder = 3

local AdvancedSectionCorner = Instance.new("UICorner", AdvancedSection)
AdvancedSectionCorner.CornerRadius = UDim.new(0, 8)

local AdvancedTitle = Instance.new("TextLabel", AdvancedSection)
AdvancedTitle.Text = "Advanced Features"
AdvancedTitle.Font = Enum.Font.SourceSansBold
AdvancedTitle.TextSize = 16
AdvancedTitle.TextColor3 = Color3.fromRGB(255,255,255)
AdvancedTitle.Position = UDim2.new(0.05, 0, 0.03, 0)
AdvancedTitle.Size = UDim2.new(0.9, 0, 0, 25)
AdvancedTitle.BackgroundTransparency = 1

-- NoClip Button
local NoClipButton = Instance.new("TextButton", AdvancedSection)
NoClipButton.Text = "NoClip: OFF"
NoClipButton.Font = Enum.Font.SourceSansBold
NoClipButton.TextSize = 14
NoClipButton.BackgroundColor3 = Color3.fromRGB(150, 65, 200)
NoClipButton.TextColor3 = Color3.fromRGB(255,255,255)
NoClipButton.Position = UDim2.new(0.05, 0, 0.25, 0)
NoClipButton.Size = UDim2.new(0.9, 0, 0, 30)

local NoClipButtonCorner = Instance.new("UICorner", NoClipButton)
NoClipButtonCorner.CornerRadius = UDim.new(0, 5)

-- Auto Platform Button
local PlatformButton = Instance.new("TextButton", AdvancedSection)
PlatformButton.Text = "Auto Platform: OFF"
PlatformButton.Font = Enum.Font.SourceSansBold
PlatformButton.TextSize = 14
PlatformButton.BackgroundColor3 = Color3.fromRGB(200, 130, 0)
PlatformButton.TextColor3 = Color3.fromRGB(255,255,255)
PlatformButton.Position = UDim2.new(0.05, 0, 0.5, 0)
PlatformButton.Size = UDim2.new(0.9, 0, 0, 30)

local PlatformButtonCorner = Instance.new("UICorner", PlatformButton)
PlatformButtonCorner.CornerRadius = UDim.new(0, 5)

-- Run Away Button
local RunAwayButton = Instance.new("TextButton", AdvancedSection)
RunAwayButton.Text = "Run Away"
RunAwayButton.Font = Enum.Font.SourceSansBold
RunAwayButton.TextSize = 14
RunAwayButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RunAwayButton.TextColor3 = Color3.fromRGB(255,255,255)
RunAwayButton.Position = UDim2.new(0.05, 0, 0.75, 0)
RunAwayButton.Size = UDim2.new(0.9, 0, 0, 30)

local RunAwayButtonCorner = Instance.new("UICorner", RunAwayButton)
RunAwayButtonCorner.CornerRadius = UDim.new(0, 5)

-- Storage for Billboards
local nameBillboards = {}

-- Function Definitions
local function populatePlayerList()
    PlayerList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(PlayerList, p)
        end
    end
end

local function createBillboard(player)
    if nameBillboards[player] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ExpName"
    billboard.Adornee = player.Character and player.Character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = DisplayColor
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextSize = DisplayFontSize
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = ""
    textLabel.Name = "Label"
    
    billboard.Parent = player.Character:FindFirstChild("Head")
    nameBillboards[player] = billboard
end

local function createPlatform()
    if AutoPlatform then
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(6, 1, 6)
        platform.Anchored = true
        platform.Transparency = 0.5
        platform.BrickColor = BrickColor.new("Bright blue")
        platform.CanCollide = true
        platform.Name = "AutoPlatform"
        
        -- Position the platform below the player
        platform.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, -3.5, 0)
        platform.Parent = workspace
        
        -- Remove the platform after a short delay
        spawn(function()
            wait(1)
            platform:Destroy()
        end)
    end
end

-- Event Connections
SubmitKey.MouseButton1Click:Connect(function()
    if KeyInput.Text == KEY then
        if isExpired() then
            AuthTitle.Text = "Script expired!"
            SubmitKey.Text = "No access"
            return
        end
        
        Authenticated = true
        AuthFrame.Visible = false
        MainControls.Visible = true
        
        -- Initial population of player list
        populatePlayerList()
        
        -- Load saved settings if available
        loadSettings()
    else
        AuthTitle.Text = "Wrong key. Try again."
        createTween(AuthTitle, {TextColor3 = Color3.fromRGB(255, 50, 50)}, 0.3):Play()
        wait(0.5)
        createTween(AuthTitle, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.3):Play()
    end
    
    createRipple  {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.3):Play()
    end
    
    createRippleEffect(SubmitKey)
end)

ReloadButton.MouseButton1Click:Connect(function()
    populatePlayerList()
    createRippleEffect(ReloadButton)
end)

NearestButton.MouseButton1Click:Connect(function()
    local nearest = nil
    local shortest = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < shortest then
                nearest = p
                shortest = dist
            end
        end
    end
    if nearest then
        TargetPlayer = nearest
        LookTarget = nearest
        TargetDropdown.Text = nearest.Name
    end
    createRippleEffect(NearestButton)
end)

TargetDropdown.MouseButton1Click:Connect(function()
    populatePlayerList()
    
    -- Remove existing dropdown menu if it exists
    local existingMenu = MainControls:FindFirstChild("DropdownMenu")
    if existingMenu then
        existingMenu:Destroy()
    end
    
    local menu = Instance.new("Frame", MainControls)
    menu.Size = UDim2.new(0.55, 0, 0, math.min(#PlayerList * 30, 150))
    menu.Position = UDim2.new(0.05, 0, 0.17, 0)
    menu.BackgroundColor3 = Color3.fromRGB(45,45,45)
    menu.BorderSizePixel = 0
    menu.Name = "DropdownMenu"
    menu.ZIndex = 10
    menu.ClipsDescendants = true
    
    local menuCorner = Instance.new("UICorner", menu)
    menuCorner.CornerRadius = UDim.new(0, 5)
    
    local scrollFrame = Instance.new("ScrollingFrame", menu)
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #PlayerList * 30)
    scrollFrame.ZIndex = 10
    
    local layout = Instance.new("UIListLayout", scrollFrame)
    layout.Padding = UDim.new(0, 2)
    
    for _, p in pairs(PlayerList) do
        local btn = Instance.new("TextButton", scrollFrame)
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.Text = p.Name
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.ZIndex = 10
        
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            TargetPlayer = p
            LookTarget = p
            TargetDropdown.Text = p.Name
            menu:Destroy()
            createRippleEffect(btn)
        end)
    end
    
    createRippleEffect(TargetDropdown)
end)

FollowButton.MouseButton1Click:Connect(function()
    FollowingTarget = not FollowingTarget
    FollowButton.Text = "Follow: " .. (FollowingTarget and "ON" or "OFF")
    createRippleEffect(FollowButton)
end)

AutoNextButton.MouseButton1Click:Connect(function()
    AutoNextTarget = not AutoNextTarget
    AutoNextButton.Text = "Auto Next: " .. (AutoNextTarget and "ON" or "OFF")
    createRippleEffect(AutoNextButton)
end)

LookAtButton.MouseButton1Click:Connect(function()
    BodyPartIndex = BodyPartIndex % #BodyParts + 1
    LookBodyPart = BodyParts[BodyPartIndex]
    LookAtButton.Text = "Look At (" .. LookBodyPart .. ")"
    createRippleEffect(LookAtButton)
end)

TeleportButton.MouseButton1Click:Connect(function()
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPart = TargetPlayer.Character.HumanoidRootPart
        local backVec = -targetPart.CFrame.LookVector * DistanceBehind + Vector3.new(0, DistanceAbove, 0)
        HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + backVec, targetPart.Position)
    end
    createRippleEffect(TeleportButton)
end)

NoClipButton.MouseButton1Click:Connect(function()
    NoClipping = not NoClipping
    NoClipButton.Text = "NoClip: " .. (NoClipping and "ON" or "OFF")
    createRippleEffect(NoClipButton)
end)

PlatformButton.MouseButton1Click:Connect(function()
    AutoPlatform = not AutoPlatform
    PlatformButton.Text = "Auto Platform: " .. (AutoPlatform and "ON" or "OFF")
    createRippleEffect(PlatformButton)
end)

RunAwayButton.MouseButton1Click:Connect(function()
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = TargetPlayer.Character.HumanoidRootPart.Position
        local playerPos = HumanoidRootPart.Position
        local direction = (playerPos - targetPos).Unit
        local runPos = playerPos + direction * 50
        
        -- Teleport away from target
        HumanoidRootPart.CFrame = CFrame.new(runPos, targetPos)
    end
    createRippleEffect(RunAwayButton)
end)

SettingsButton.MouseButton1Click:Connect(function()
    MainControls.Visible = false
    SettingsFrame.Visible = true
    createRippleEffect(SettingsButton)
end)

BackButton.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = false
    MainControls.Visible = true
    createRippleEffect(BackButton)
end)

SaveButton.MouseButton1Click:Connect(function()
    saveSettings()
    createRippleEffect(SaveButton)
    
    -- Visual feedback
    SaveButton.Text = "Saved!"
    wait(1)
    SaveButton.Text = "Save Settings"
end)

MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    IconFrame.Visible = true
end)

IconFrame.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    IconFrame.Visible = false
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Continuous Update Functions
RunService.RenderStepped:Connect(function()
    -- Follow Logic
    if Authenticated and FollowingTarget and TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPart = TargetPlayer.Character.HumanoidRootPart
        local followPos = targetPart.Position - targetPart.CFrame.LookVector * DistanceBehind + Vector3.new(0, DistanceAbove, 0)
        HumanoidRootPart.CFrame = CFrame.new(followPos, targetPart.Position)
    end
    
    -- LookAt Logic
    if Authenticated and LookTarget and LookTarget.Character and LookTarget.Character:FindFirstChild(LookBodyPart) then
        local part = LookTarget.Character[LookBodyPart]
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    end
    
    -- NoClip Logic
    if Authenticated and NoClipping and Character and Character:FindFirstChild("Humanoid") then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Auto Platform Logic
    if Authenticated and AutoPlatform and Character and Character:FindFirstChild("Humanoid") then
        if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            createPlatform()
        end
    end
    
    -- Update Billboard content
    if Authenticated then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                if ShowExpName then
                    createBillboard(p)
                    local label = nameBillboards[p] and nameBillboards[p]:FindFirstChild("Label")
                    if label then
                        local text = ""
                        if DisplayMode == "name" then
                            text = p.Name
                        elseif DisplayMode == "distance" and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                            text = string.format("%.1f m", dist)
                        elseif DisplayMode == "hp" and p.Character:FindFirstChild("Humanoid") then
                            text = string.format("HP: %d", math.floor(p.Character.Humanoid.Health))
                        end
                        
                        if ShowHP and p.Character:FindFirstChild("Humanoid") and DisplayMode ~= "hp" then
                            text = text .. " | HP: " .. math.floor(p.Character.Humanoid.Health)
                        end
                        
                        label.Text = text
                        label.TextColor3 = DisplayColor
                        label.TextSize = DisplayFontSize
                        nameBillboards[p].Adornee = p.Character.Head
                        nameBillboards[p].AlwaysOnTop = AllowWallDisplay
                    end
                elseif nameBillboards[p] then
                    nameBillboards[p]:Destroy()
                    nameBillboards[p] = nil
                end
            end
        end
    end
})

-- Auto Next Target on death
RunService.Stepped:Connect(function()
    if Authenticated and AutoNextTarget and TargetPlayer then
        local hum = TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            local nextTarget = nil
            local minDist = math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p ~= TargetPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                    if p.Character.Humanoid.Health > 0 then
                        local dist = (HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nextTarget = p
                        end
                    end
                end
            end
            if nextTarget then
                TargetPlayer = nextTarget
                LookTarget = nextTarget
                TargetDropdown.Text = nextTarget.Name
            end
        end
    end
})

-- Rainbow border effect
local rainbowColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(255, 165, 0),
    Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(75, 0, 130),
    Color3.fromRGB(238, 130, 238)
}
local rainbowIndex = 1

spawn(function()
    while MainFrame and MainFrame.Parent do
        local nextColor = rainbowColors[rainbowIndex]
        local tween = TweenService:Create(UIStroke, TweenInfo.new(0.5), {Color = nextColor})
        tween:Play()
        rainbowIndex = (rainbowIndex % #rainbowColors) + 1
        wait(0.5)
    end
end)

-- Reset icon on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(1)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Load settings on startup
loadSettings()
