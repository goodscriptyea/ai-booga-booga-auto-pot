--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Player Setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

--// Config
local SETTINGS = {
    TargetTypes = {
        WaterPot = {
            Names = {"WaterPot", "Water Pot", "waterpot", "water_pot"},
            Enabled = true
        },
        GoldPot = {
            Names = {"GoldPot", "Gold Pot", "goldpot", "gold_pot", "GoldenPot", "Golden Pot", "goldenpot", "GoldenGoldPot", "Golden Gold Pot", "goldengoldpot"},
            Enabled = true
        }
    },
    SizeFilters = {
        "Small",
        "Big", 
        "Mega",
        "Omega"
    },
    CurrentSpeed = 5, -- Default tween speed (0-22)
    IsRunning = false,
    CurrentTween = nil,
    Connection = nil
}

--// Create UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PotFarmerUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    title.Text = "⚡ Pot Farmer"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title
    
    --// Water Pot Toggle
    local waterFrame = Instance.new("Frame")
    waterFrame.Name = "WaterFrame"
    waterFrame.Size = UDim2.new(1, -20, 0, 40)
    waterFrame.Position = UDim2.new(0, 10, 0, 60)
    waterFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    waterFrame.Parent = mainFrame
    
    local waterCorner = Instance.new("UICorner")
    waterCorner.CornerRadius = UDim.new(0, 8)
    waterCorner.Parent = waterFrame
    
    local waterLabel = Instance.new("TextLabel")
    waterLabel.Size = UDim2.new(0.6, 0, 1, 0)
    waterLabel.BackgroundTransparency = 1
    waterLabel.Text = "💧 Water Pot"
    waterLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    waterLabel.TextSize = 16
    waterLabel.Font = Enum.Font.Gotham
    waterLabel.Parent = waterFrame
    
    local waterToggle = Instance.new("TextButton")
    waterToggle.Name = "WaterToggle"
    waterToggle.Size = UDim2.new(0.3, -10, 0.7, 0)
    waterToggle.Position = UDim2.new(0.65, 0, 0.15, 0)
    waterToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    waterToggle.Text = "ON"
    waterToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    waterToggle.TextSize = 14
    waterToggle.Font = Enum.Font.GothamBold
    waterToggle.Parent = waterFrame
    
    local waterToggleCorner = Instance.new("UICorner")
    waterToggleCorner.CornerRadius = UDim.new(0, 6)
    waterToggleCorner.Parent = waterToggle
    
    --// Gold Pot Toggle
    local goldFrame = Instance.new("Frame")
    goldFrame.Name = "GoldFrame"
    goldFrame.Size = UDim2.new(1, -20, 0, 40)
    goldFrame.Position = UDim2.new(0, 10, 0, 110)
    goldFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    goldFrame.Parent = mainFrame
    
    local goldCorner = Instance.new("UICorner")
    goldCorner.CornerRadius = UDim.new(0, 8)
    goldCorner.Parent = goldFrame
    
    local goldLabel = Instance.new("TextLabel")
    goldLabel.Size = UDim2.new(0.6, 0, 1, 0)
    goldLabel.BackgroundTransparency = 1
    goldLabel.Text = "🏆 Gold Pot"
    goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    goldLabel.TextSize = 16
    goldLabel.Font = Enum.Font.Gotham
    goldLabel.Parent = goldFrame
    
    local goldToggle = Instance.new("TextButton")
    goldToggle.Name = "GoldToggle"
    goldToggle.Size = UDim2.new(0.3, -10, 0.7, 0)
    goldToggle.Position = UDim2.new(0.65, 0, 0.15, 0)
    goldToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    goldToggle.Text = "ON"
    goldToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    goldToggle.TextSize = 14
    goldToggle.Font = Enum.Font.GothamBold
    goldToggle.Parent = goldFrame
    
    local goldToggleCorner = Instance.new("UICorner")
    goldToggleCorner.CornerRadius = UDim.new(0, 6)
    goldToggleCorner.Parent = goldToggle
    
    --// Size Selection Label
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(1, -20, 0, 25)
    sizeLabel.Position = UDim2.new(0, 10, 0, 160)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = "📏 Size Filter (Small/Big/Mega/Omega)"
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.TextSize = 14
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.Parent = mainFrame
    
    --// Size Toggles Container
    local sizeContainer = Instance.new("Frame")
    sizeContainer.Name = "SizeContainer"
    sizeContainer.Size = UDim2.new(1, -20, 0, 80)
    sizeContainer.Position = UDim2.new(0, 10, 0, 190)
    sizeContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    sizeContainer.Parent = mainFrame
    
    local sizeContainerCorner = Instance.new("UICorner")
    sizeContainerCorner.CornerRadius = UDim.new(0, 8)
    sizeContainerCorner.Parent = sizeContainer
    
    local sizeLayout = Instance.new("UIGridLayout")
    sizeLayout.CellSize = UDim2.new(0.22, -5, 0, 35)
    sizeLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    sizeLayout.Parent = sizeContainer
    
    local sizeButtons = {}
    for i, sizeName in ipairs(SETTINGS.SizeFilters) do
        local btn = Instance.new("TextButton")
        btn.Name = sizeName .. "Btn"
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        btn.Text = sizeName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.Parent = sizeContainer
        sizeButtons[sizeName] = btn
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
    end
    
    --// Speed Slider Label
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, -20, 0, 25)
    speedLabel.Position = UDim2.new(0, 10, 0, 280)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "⚡ Tween Speed: 5"
    speedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    speedLabel.TextSize = 16
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.Parent = mainFrame
    
    --// Speed Slider
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "SliderFrame"
    sliderFrame.Size = UDim2.new(1, -20, 0, 30)
    sliderFrame.Position = UDim2.new(0, 10, 0, 310)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    sliderFrame.Parent = mainFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 15)
    sliderCorner.Parent = sliderFrame
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Size = UDim2.new(SETTINGS.CurrentSpeed / 22, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderFrame
    
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 15)
    sliderFillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "SliderButton"
    sliderButton.Size = UDim2.new(1, 0, 1, 0)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.Parent = sliderFrame
    
    --// Main Toggle Button
    local mainToggle = Instance.new("TextButton")
    mainToggle.Name = "MainToggle"
    mainToggle.Size = UDim2.new(1, -20, 0, 45)
    mainToggle.Position = UDim2.new(0, 10, 0, 350)
    mainToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    mainToggle.Text = "▶ START FARMING"
    mainToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainToggle.TextSize = 18
    mainToggle.Font = Enum.Font.GothamBold
    mainToggle.Parent = mainFrame
    
    local mainToggleCorner = Instance.new("UICorner")
    mainToggleCorner.CornerRadius = UDim.new(0, 10)
    mainToggleCorner.Parent = mainToggle
    
    --// Dragging
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return {
        WaterToggle = waterToggle,
        GoldToggle = goldToggle,
        SizeButtons = sizeButtons,
        SpeedLabel = speedLabel,
        SliderFill = sliderFill,
        SliderButton = sliderButton,
        MainToggle = mainToggle
    }
end

--// UI Logic
local ui = createUI()

-- Water Toggle
ui.WaterToggle.MouseButton1Click:Connect(function()
    SETTINGS.TargetTypes.WaterPot.Enabled = not SETTINGS.TargetTypes.WaterPot.Enabled
    if SETTINGS.TargetTypes.WaterPot.Enabled then
        ui.WaterToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        ui.WaterToggle.Text = "ON"
    else
        ui.WaterToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ui.WaterToggle.Text = "OFF"
    end
end)

-- Gold Toggle
ui.GoldToggle.MouseButton1Click:Connect(function()
    SETTINGS.TargetTypes.GoldPot.Enabled = not SETTINGS.TargetTypes.GoldPot.Enabled
    if SETTINGS.TargetTypes.GoldPot.Enabled then
        ui.GoldToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        ui.GoldToggle.Text = "ON"
    else
        ui.GoldToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ui.GoldToggle.Text = "OFF"
    end
end)

-- Size Toggles
local activeSizes = {Small = true, Big = true, Mega = true, Omega = true}
for sizeName, btn in pairs(ui.SizeButtons) do
    btn.MouseButton1Click:Connect(function()
        activeSizes[sizeName] = not activeSizes[sizeName]
        if activeSizes[sizeName] then
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end
    end)
end

-- Speed Slider
local sliderDragging = false

ui.SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local sliderFrame = ui.SliderButton.Parent
        local relativeX = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        SETTINGS.CurrentSpeed = math.floor(relativeX * 22)
        ui.SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        ui.SpeedLabel.Text = "⚡ Tween Speed: " .. SETTINGS.CurrentSpeed
        
        -- Color change based on speed
        if SETTINGS.CurrentSpeed < 7 then
            ui.SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            ui.SpeedLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        elseif SETTINGS.CurrentSpeed < 15 then
            ui.SliderFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
            ui.SpeedLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            ui.SliderFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            ui.SpeedLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end
end)

--// Core Functions
local function getDeployablesFolder()
    local workspace = game:GetService("Workspace")
    -- Try different possible paths
    local paths = {
        workspace:FindFirstChild("Deployables"),
        workspace:FindFirstChild("deployables"),
        workspace:FindFirstChild("Workspace"):FindFirstChild("Deployables"),
        workspace:FindFirstChild("Game"):FindFirstChild("Deployables"),
        workspace:FindFirstChild("Map"):FindFirstChild("Deployables")
    }
    
    for _, folder in ipairs(paths) do
        if folder then return folder end
    end
    
    -- Search in workspace
    for _, child in ipairs(workspace:GetDescendants()) do
        if child:IsA("Folder") and (child.Name:lower():match("deploy") or child.Name:lower():match("pot")) then
            return child
        end
    end
    
    return nil
end

local function isValidTarget(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    
    local objName = obj.Name:lower()
    local objParentName = obj.Parent and obj.Parent.Name:lower() or ""
    
    -- Check Water Pot
    if SETTINGS.TargetTypes.WaterPot.Enabled then
        for _, name in ipairs(SETTINGS.TargetTypes.WaterPot.Names) do
            if objName:find(name:lower()) or objParentName:find(name:lower()) then
                -- Check size filter
                for sizeName, active in pairs(activeSizes) do
                    if active and (objName:find(sizeName:lower()) or objParentName:find(sizeName:lower())) then
                        return true, "WaterPot", sizeName
                    end
                end
            end
        end
    end
    
    -- Check Gold Pot (includes Golden and GoldenGoldPot)
    if SETTINGS.TargetTypes.GoldPot.Enabled then
        for _, name in ipairs(SETTINGS.TargetTypes.GoldPot.Names) do
            if objName:find(name:lower()) or objParentName:find(name:lower()) then
                -- Check size filter
                for sizeName, active in pairs(activeSizes) do
                    if active and (objName:find(sizeName:lower()) or objParentName:find(sizeName:lower())) then
                        return true, "GoldPot", sizeName
                    end
                end
            end
        end
    end
    
    return false
end

local function findNearestTarget()
    local deployables = getDeployablesFolder()
    if not deployables then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(deployables:GetDescendants()) do
        local valid, potType, sizeType = isValidTarget(obj)
        if valid and obj:IsA("BasePart") then
            local dist = (humanoidRootPart.Position - obj.Position).Magnitude
            if dist < nearestDist and dist > 5 then -- Don't target if too close
                nearestDist = dist
                nearest = obj
            end
        end
    end
    
    return nearest
end

local function tweenToTarget(target)
    if not target or not target.Parent then return end
    
    -- Calculate distance for tween time
    local distance = (humanoidRootPart.Position - target.Position).Magnitude
    
    -- Speed 0 = instant, 22 = very fast
    local speed = math.max(0.1, SETTINGS.CurrentSpeed)
    local tweenTime = distance / (speed * 10) -- Adjust multiplier as needed
    
    if SETTINGS.CurrentSpeed == 0 then
        tweenTime = 0.05 -- Minimum time for instant-like feel
    end
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local targetCFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0)) -- Hover above
    
    SETTINGS.CurrentTween = TweenService:Create(humanoidRootPart, tweenInfo, {
        CFrame = targetCFrame
    })
    
    SETTINGS.CurrentTween:Play()
    
    -- Wait for completion or interruption
    local completed = false
    SETTINGS.CurrentTween.Completed:Connect(function()
        completed = true
    end)
    
    -- Damage/Interact with target when close
    spawn(function()
        while not completed and SETTINGS.IsRunning do
            if target and target.Parent then
                local dist = (humanoidRootPart.Position - target.Position).Magnitude
                if dist < 10 then
                    -- Fire touch interest or damage event
                    fireTouchInterest(target)
                end
            end
            task.wait(0.1)
        end
    end)
    
    SETTINGS.CurrentTween.Completed:Wait()
end

local function fireTouchInterest(part)
    -- Simulate touch for damage
    if part and part.Parent then
        -- Try to find humanoid to damage or trigger event
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Some games use touch detection
            local touchPart = part:FindFirstChildWhichIsA("TouchTransmitter") or part
            
            -- Fire remote if available (game specific)
            -- This is a generic approach
        end
    end
end

--// Main Loop
local function startFarming()
    SETTINGS.IsRunning = true
    ui.MainToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ui.MainToggle.Text = "⏹ STOP FARMING"
    
    SETTINGS.Connection = RunService.Heartbeat:Connect(function()
        if not SETTINGS.IsRunning then return end
        
        if not SETTINGS.CurrentTween or not SETTINGS.CurrentTween.PlaybackState == Enum.PlaybackState.Playing then
            local target = findNearestTarget()
            if target then
                tweenToTarget(target)
            else
                task.wait(0.5) -- Wait if no targets found
            end
        end
    end)
end

local function stopFarming()
    SETTINGS.IsRunning = false
    ui.MainToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    ui.MainToggle.Text = "▶ START FARMING"
    
    if SETTINGS.CurrentTween then
        SETTINGS.CurrentTween:Pause()
        SETTINGS.CurrentTween = nil
    end
    
    if SETTINGS.Connection then
        SETTINGS.Connection:Disconnect()
        SETTINGS.Connection = nil
    end
end

-- Main Toggle
ui.MainToggle.MouseButton1Click:Connect(function()
    if SETTINGS.IsRunning then
        stopFarming()
    else
        startFarming()
    end
end)

-- Cleanup on death
character.Humanoid.Died:Connect(function()
    stopFarming()
end)

-- Reconnect on respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    character.Humanoid.Died:Connect(function()
        stopFarming()
    end)
end)

print("✅ Pot Farmer loaded! UI created with Water/Gold/Golden Pot support")
