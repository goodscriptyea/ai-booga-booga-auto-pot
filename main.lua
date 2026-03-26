--// Загрузка Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
        Small = true,
        Big = true,
        Mega = true,
        Omega = true
    },
    CurrentSpeed = 5,
    IsRunning = false,
    CurrentTween = nil,
    Connection = nil
}

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "Pot Farmer",
    LoadingTitle = "Pot Farmer Loading",
    LoadingSubtitle = "by Sirius",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PotFarmer",
        FileName = "Settings"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

--// Tabs
local MainTab = Window:CreateTab("Main", "target")
local SettingsTab = Window:CreateTab("Settings", "settings")

--// Main Tab - Toggles for Pot Types
MainTab:CreateSection("Target Selection")

MainTab:CreateToggle({
    Name = "💧 Water Pot",
    CurrentValue = true,
    Flag = "WaterPotToggle",
    Callback = function(Value)
        SETTINGS.TargetTypes.WaterPot.Enabled = Value
    end
})

MainTab:CreateToggle({
    Name = "🏆 Gold Pot (Golden + GoldenGold)",
    CurrentValue = true,
    Flag = "GoldPotToggle",
    Callback = function(Value)
        SETTINGS.TargetTypes.GoldPot.Enabled = Value
    end
})

--// Size Filters Section
MainTab:CreateSection("Size Filter")

MainTab:CreateToggle({
    Name = "Small",
    CurrentValue = true,
    Flag = "SmallToggle",
    Callback = function(Value)
        SETTINGS.SizeFilters.Small = Value
    end
})

MainTab:CreateToggle({
    Name = "Big",
    CurrentValue = true,
    Flag = "BigToggle",
    Callback = function(Value)
        SETTINGS.SizeFilters.Big = Value
    end
})

MainTab:CreateToggle({
    Name = "Mega",
    CurrentValue = true,
    Flag = "MegaToggle",
    Callback = function(Value)
        SETTINGS.SizeFilters.Mega = Value
    end
})

MainTab:CreateToggle({
    Name = "Omega",
    CurrentValue = true,
    Flag = "OmegaToggle",
    Callback = function(Value)
        SETTINGS.SizeFilters.Omega = Value
    end
})

--// Speed Slider
MainTab:CreateSection("Tween Speed")

MainTab:CreateSlider({
    Name = "Speed (0-22)",
    Range = {0, 22},
    Increment = 1,
    Suffix = "speed",
    CurrentValue = 5,
    Flag = "SpeedSlider",
    Callback = function(Value)
        SETTINGS.CurrentSpeed = Value
    end
})

--// Main Toggle Button
MainTab:CreateSection("Control")

local FarmButton = MainTab:CreateButton({
    Name = "▶ START FARMING",
    Callback = function()
        SETTINGS.IsRunning = not SETTINGS.IsRunning
        
        if SETTINGS.IsRunning then
            FarmButton:Set("⏹ STOP FARMING")
            startFarming()
        else
            FarmButton:Set("▶ START FARMING")
            stopFarming()
        end
    end
})

--// Settings Tab
SettingsTab:CreateSection("Info")

SettingsTab:CreateParagraph({
    Title = "How to use",
    Content = "1. Select target pot types\n2. Choose sizes to farm\n3. Set tween speed (0=instant, 22=fast)\n4. Click START FARMING\n\nScript will find nearest valid pot and tween to it automatically."
})

--// Core Functions
local function getDeployablesFolder()
    local workspace = game:GetService("Workspace")
    local paths = {
        workspace:FindFirstChild("Deployables"),
        workspace:FindFirstChild("deployables"),
        workspace:FindFirstChild("Workspace") and workspace:FindFirstChild("Workspace"):FindFirstChild("Deployables"),
        workspace:FindFirstChild("Game") and workspace:FindFirstChild("Game"):FindFirstChild("Deployables"),
        workspace:FindFirstChild("Map") and workspace:FindFirstChild("Map"):FindFirstChild("Deployables")
    }
    
    for _, folder in ipairs(paths) do
        if folder then return folder end
    end
    
    -- Deep search
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
                for sizeName, active in pairs(SETTINGS.SizeFilters) do
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
                for sizeName, active in pairs(SETTINGS.SizeFilters) do
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
    if not deployables then 
        Rayfield:Notify({
            Title = "Error",
            Content = "Deployables folder not found!",
            Duration = 3
        })
        return nil 
    end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(deployables:GetDescendants()) do
        local valid, potType, sizeType = isValidTarget(obj)
        if valid and obj:IsA("BasePart") then
            local dist = (humanoidRootPart.Position - obj.Position).Magnitude
            if dist < nearestDist and dist > 5 then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    
    return nearest
end

local function tweenToTarget(target)
    if not target or not target.Parent then return end
    
    local distance = (humanoidRootPart.Position - target.Position).Magnitude
    local speed = math.max(0.1, SETTINGS.CurrentSpeed)
    local tweenTime = distance / (speed * 10)
    
    if SETTINGS.CurrentSpeed == 0 then
        tweenTime = 0.05
    end
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local targetCFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
    
    SETTINGS.CurrentTween = TweenService:Create(humanoidRootPart, tweenInfo, {
        CFrame = targetCFrame
    })
    
    SETTINGS.CurrentTween:Play()
    SETTINGS.CurrentTween.Completed:Wait()
end

--// Main Loop
function startFarming()
    SETTINGS.Connection = RunService.Heartbeat:Connect(function()
        if not SETTINGS.IsRunning then return end
        
        if not SETTINGS.CurrentTween or SETTINGS.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
            local target = findNearestTarget()
            if target then
                tweenToTarget(target)
            else
                task.wait(0.5)
            end
        end
    end)
end

function stopFarming()
    if SETTINGS.CurrentTween then
        SETTINGS.CurrentTween:Pause()
        SETTINGS.CurrentTween = nil
    end
    
    if SETTINGS.Connection then
        SETTINGS.Connection:Disconnect()
        SETTINGS.Connection = nil
    end
end

--// Cleanup
character.Humanoid.Died:Connect(function()
    stopFarming()
    SETTINGS.IsRunning = false
    FarmButton:Set("▶ START FARMING")
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    character.Humanoid.Died:Connect(function()
        stopFarming()
        SETTINGS.IsRunning = false
        FarmButton:Set("▶ START FARMING")
    end)
end)

Rayfield:Notify({
    Title = "Loaded",
    Content = "Pot Farmer ready! Select targets and click START.",
    Duration = 5
})
