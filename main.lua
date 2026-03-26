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
local humanoid = character:WaitForChild("Humanoid")

--// Config
local SETTINGS = {
    TargetTypes = {
        WaterPot = {Names = {"WaterPot", "Water Pot", "waterpot", "water_pot"}, Enabled = true},
        GoldPot = {Names = {"GoldPot", "Gold Pot", "goldpot", "gold_pot", "GoldenPot", "Golden Pot"}, Enabled = true}
    },
    SizeFilters = {Small = true, Big = true, Mega = true, Omega = true},
    CurrentSpeed = 5, IsFarming = false, IsAura = false, CurrentTween = nil, FarmConnection = nil, AuraConnection = nil, BreakDistance = 8
}

--// Оголошення UI змінних
local StatusLabel, ToggleFarmBtn, AuraStatusLabel, ToggleAuraBtn

--// CORE FUNCTIONS
local function getDeployablesFolder()
    local ws = game:GetService("Workspace")
    if ws:FindFirstChild("Deployables") then return ws.Deployables end
    if ws:FindFirstChild("deployables") then return ws.deployables end
    for _, obj in ipairs(ws:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and obj.Name:lower():find("deploy") then return obj end
    end
    return nil
end

local function isValidTarget(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local fullName = (obj.Name .. " " .. (obj.Parent and obj.Parent.Name or "")):lower()
    for _, typeData in pairs(SETTINGS.TargetTypes) do
        if typeData.Enabled then
            for _, name in ipairs(typeData.Names) do
                if fullName:find(name:lower()) then
                    for size, active in pairs(SETTINGS.SizeFilters) do
                        if active and fullName:find(size:lower()) then return true end
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
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(deployables:GetDescendants()) do
        if isValidTarget(obj) then
            local dist = (humanoidRootPart.Position - obj.Position).Magnitude
            if dist < nearestDist and dist > 3 then nearestDist = dist; nearest = obj end
        end
    end
    return nearest, nearestDist
end

local function breakPot(pot)
    if not pot or not pot.Parent then return end
    pcall(function() firetouchinterest(pot, humanoidRootPart, 0); task.wait(0.05); firetouchinterest(pot, humanoidRootPart, 1) end)
    pcall(function() local cd = pot:FindFirstChildOfClass("ClickDetector"); if cd then fireclickdetector(cd) end end)
end

local function tweenToTarget(target)
    if not target or not target.Parent then return end
    local dist = (humanoidRootPart.Position - target.Position).Magnitude
    local time = SETTINGS.CurrentSpeed == 0 and 0.01 or (dist / (SETTINGS.CurrentSpeed * 8))
    local tPos = target.Position + Vector3.new(0, 4, 0)
    
    SETTINGS.CurrentTween = TweenService:Create(humanoidRootPart, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(tPos, tPos + (target.Position - humanoidRootPart.Position).Unit)})
    SETTINGS.CurrentTween:Play()
    
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not SETTINGS.IsFarming or not target.Parent then conn:Disconnect() return end
        if (humanoidRootPart.Position - target.Position).Magnitude < SETTINGS.BreakDistance then breakPot(target); conn:Disconnect() end
    end)
    
    SETTINGS.CurrentTween.Completed:Wait()
    if conn then conn:Disconnect() end
    breakPot(target)
end

--// LOOPS
local function startFarming()
    SETTINGS.FarmConnection = task.spawn(function()
        while SETTINGS.IsFarming do
            if not SETTINGS.CurrentTween or SETTINGS.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                local target, dist = findNearestTarget()
                if target then 
                    StatusLabel:Set("Status: Flying to " .. target.Name)
                    tweenToTarget(target) 
                else 
                    StatusLabel:Set("Status: No targets found")
                    task.wait(0.5) 
                end
            end
            task.wait(0.1)
        end
    end)
end

local function stopFarming()
    SETTINGS.IsFarming = false
    if SETTINGS.CurrentTween then SETTINGS.CurrentTween:Cancel(); SETTINGS.CurrentTween = nil end
end

local function startAura()
    SETTINGS.AuraConnection = RunService.Heartbeat:Connect(function()
        if not SETTINGS.IsAura then return end
        local deployables = getDeployablesFolder()
        if not deployables then return end
        
        local count = 0
        for _, obj in ipairs(deployables:GetDescendants()) do
            if isValidTarget(obj) and (humanoidRootPart.Position - obj.Position).Magnitude <= SETTINGS.BreakDistance then
                breakPot(obj); count = count + 1
            end
        end
        AuraStatusLabel:Set(count > 0 and ("Aura: ON 🔥 (" .. count .. " pots)") or "Aura: ON (searching...)")
    end)
end

local function stopAura()
    SETTINGS.IsAura = false
    if SETTINGS.AuraConnection then SETTINGS.AuraConnection:Disconnect(); SETTINGS.AuraConnection = nil end
end

--// Create Window
local Window = Rayfield:CreateWindow({Name = "🔥 Pot Farmer Pro", LoadingTitle = "Pot Farmer Pro", ConfigurationSaving = {Enabled = false}, KeySystem = false})

--// FARM TAB
local FarmTab = Window:CreateTab("🎯 Farm", "target")
FarmTab:CreateToggle({Name = "💧 Water Pot", CurrentValue = true, Flag = "WP", Callback = function(V) SETTINGS.TargetTypes.WaterPot.Enabled = V end})
FarmTab:CreateToggle({Name = "🏆 Gold Pot", CurrentValue = true, Flag = "GP", Callback = function(V) SETTINGS.TargetTypes.GoldPot.Enabled = V end})

FarmTab:CreateSection("Speed & Control")
FarmTab:CreateSlider({Name = "Tween Speed", Range = {0, 22}, Increment = 1, CurrentValue = 5, Flag = "Spd", Callback = function(V) SETTINGS.CurrentSpeed = V end})

StatusLabel = FarmTab:CreateLabel("Status: IDLE")
ToggleFarmBtn = FarmTab:CreateButton({
    Name = "▶ START FARMING",
    Callback = function()
        SETTINGS.IsFarming = not SETTINGS.IsFarming
        if SETTINGS.IsFarming then
            ToggleFarmBtn:Set("⏹ STOP FARMING")
            startFarming()
        else
            ToggleFarmBtn:Set("▶ START FARMING")
            StatusLabel:Set("Status: IDLE")
            stopFarming()
        end
    end
})

--// AURA TAB
local AuraTab = Window:CreateTab("⚡ Aura", "zap")
AuraStatusLabel = AuraTab:CreateLabel("Aura: OFF")

ToggleAuraBtn = AuraTab:CreateButton({
    Name = "▶ START AURA",
    Callback = function()
        SETTINGS.IsAura = not SETTINGS.IsAura
        if SETTINGS.IsAura then
            ToggleAuraBtn:Set("⏹ STOP AURA")
            startAura()
        else
            ToggleAuraBtn:Set("▶ START AURA")
            AuraStatusLabel:Set("Aura: OFF")
            stopAura()
        end
    end
})

AuraTab:CreateSlider({Name = "Break Distance", Range = {3, 20}, Increment = 1, CurrentValue = 8, Flag = "BDist", Callback = function(V) SETTINGS.BreakDistance = V end})

--// EVENTS
local function resetState()
    stopFarming()
    stopAura()
    ToggleFarmBtn:Set("▶ START FARMING")
    ToggleAuraBtn:Set("▶ START AURA")
    StatusLabel:Set("Status: DEAD")
    AuraStatusLabel:Set("Aura: OFF")
end

humanoid.Died:Connect(resetState)
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(resetState)
end)

Rayfield:Notify({Title = "✅ Loaded!", Content = "Pot Farmer Pro ready.", Duration = 3})
