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

--// Config (ВСЕ ВЫКЛЮЧЕНО)
local SETTINGS = {
    TargetTypes = {
        WaterPot = {
            Names = {"WaterPot", "Water Pot", "waterpot", "water_pot"},
            Enabled = false
        },
        GoldPot = {
            Names = {"GoldPot", "Gold Pot", "goldpot", "gold_pot", "GoldenPot", "Golden Pot", "goldenpot", "GoldenGoldPot", "Golden Gold Pot", "goldengoldpot"},
            Enabled = false
        }
    },
    SizeFilters = {
        Small = false,
        Big = false,
        Mega = false,
        Omega = false
    },
    CurrentSpeed = 5,
    IsFarming = false,
    IsAura = false,
    BreakDistance = 8
}

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 Pot Farmer",
    LoadingTitle = "Pot Farmer",
    LoadingSubtitle = "Fixed",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "PotFarmer",
        FileName = "Settings"
    },
    KeySystem = false
})

--// Tabs
local FarmTab = Window:CreateTab("🎯 Farm", "target")
local AuraTab = Window:CreateTab("⚡ Aura", "zap")

--// FARM TAB
FarmTab:CreateSection("Target Types")

FarmTab:CreateToggle({
    Name = "💧 Water Pot",
    CurrentValue = false,
    Flag = "WaterPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.WaterPot.Enabled = Value
    end
})

FarmTab:CreateToggle({
    Name = "🏆 Gold Pot",
    CurrentValue = false,
    Flag = "GoldPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.GoldPot.Enabled = Value
    end
})

FarmTab:CreateSection("Size Filter")

FarmTab:CreateToggle({
    Name = "Small",
    CurrentValue = false,
    Flag = "Small",
    Callback = function(Value)
        SETTINGS.SizeFilters.Small = Value
    end
})

FarmTab:CreateToggle({
    Name = "Big",
    CurrentValue = false,
    Flag = "Big",
    Callback = function(Value)
        SETTINGS.SizeFilters.Big = Value
    end
})

FarmTab:CreateToggle({
    Name = "Mega",
    CurrentValue = false,
    Flag = "Mega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Mega = Value
    end
})

FarmTab:CreateToggle({
    Name = "Omega",
    CurrentValue = false,
    Flag = "Omega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Omega = Value
    end
})

FarmTab:CreateSection("Speed")

FarmTab:CreateSlider({
    Name = "Speed (0-22)",
    Range = {0, 22},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "Speed",
    Callback = function(Value)
        SETTINGS.CurrentSpeed = Value
    end
})

local FarmStatus = FarmTab:CreateLabel("Status: IDLE")

--// AURA TAB
AuraTab:CreateSection("Auto Break Aura")

local AuraStatus = AuraTab:CreateLabel("Aura: OFF")

AuraTab:CreateSlider({
    Name = "Break Distance",
    Range = {3, 20},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 8,
    Flag = "BreakDist",
    Callback = function(Value)
        SETTINGS.BreakDistance = Value
    end
})

--// CORE FUNCTIONS

local function getDeployablesFolder()
    local ws = game:GetService("Workspace")
    
    if ws:FindFirstChild("Deployables") then
        return ws.Deployables
    elseif ws:FindFirstChild("deployables") then
        return ws.deployables
    end
    
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name:lower():find("deploy") then
            return obj
        end
    end
    
    return nil
end

local function isValidTarget(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    
    local objName = obj.Name:lower()
    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
    local fullName = objName .. " " .. parentName
    
    local anySize = false
    for _, active in pairs(SETTINGS.SizeFilters) do
        if active then anySize = true break end
    end
    if not anySize then return false end
    
    if SETTINGS.TargetTypes.WaterPot.Enabled then
        for _, name in ipairs(SETTINGS.TargetTypes.WaterPot.Names) do
            if fullName:find(name:lower()) then
                for size, active in pairs(SETTINGS.SizeFilters) do
                    if active and fullName:find(size:lower()) then
                        return true
                    end
                end
            end
        end
    end
    
    if SETTINGS.TargetTypes.GoldPot.Enabled then
        for _, name in ipairs(SETTINGS.TargetTypes.GoldPot.Names) do
            if fullName:find(name:lower()) then
                for size, active in pairs(SETTINGS.SizeFilters) do
                    if active and fullName:find(size:lower()) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

local function getAllTargets()
    local deployables = getDeployablesFolder()
    if not deployables then return {} end
    
    local targets = {}
    for _, obj in ipairs(deployables:GetDescendants()) do
        if isValidTarget(obj) then
            table.insert(targets, obj)
        end
    end
    
    return targets
end

local function findNearestTarget()
    local targets = getAllTargets()
    if #targets == 0 then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    local hrpPos = humanoidRootPart.Position
    
    for _, obj in ipairs(targets) do
        if obj and obj.Parent then
            local dist = (hrpPos - obj.Position).Magnitude
            if dist < nearestDist and dist > 3 then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    
    return nearest, nearestDist
end

--// BREAK FUNCTION (РАБОЧАЯ!)
local function breakPot(pot)
    if not pot or not pot.Parent then return end
    
    -- Сохраняем позицию
    local oldCFrame = humanoidRootPart.CFrame
    
    -- ТЕЛЕПОРТ НА ПОТ (для ауры - это нормально)
    humanoidRootPart.CFrame = CFrame.new(pot.Position + Vector3.new(0, 2, 0))
    
    -- Fire touch
    pcall(function()
        firetouchinterest(pot, humanoidRootPart, 0)
        task.wait(0.05)
        firetouchinterest(pot, humanoidRootPart, 1)
    end)
    
    -- Click detector
    pcall(function()
        local click = pot:FindFirstChildOfClass("ClickDetector")
        if click then fireclickdetector(click) end
    end)
    
    -- Proximity prompt
    pcall(function()
        local prompt = pot:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
    end)
    
    -- Возврат (опционально, для ауры можно не возвращать)
    -- task.wait(0.05)
    -- humanoidRootPart.CFrame = oldCFrame
end

--// TWEEN (для фарма)
local currentTween = nil

local function flyToTarget(target)
    if not target or not target.Parent then return end
    
    local distance = (humanoidRootPart.Position - target.Position).Magnitude
    
    local tweenTime = 0.01
    if SETTINGS.CurrentSpeed > 0 then
        tweenTime = distance / (SETTINGS.CurrentSpeed * 10)
    end
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local targetCFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
    
    if currentTween then
        currentTween:Cancel()
    end
    
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {
        CFrame = targetCFrame
    })
    
    currentTween:Play()
    currentTween.Completed:Wait()
    
    -- Ломание после прилета
    breakPot(target)
end

--// LOOPS
local farmRunning = false
local auraRunning = false

local function startFarm()
    if farmRunning then return end
    farmRunning = true
    SETTINGS.IsFarming = true
    FarmStatus:Set("Status: RUNNING")
    
    task.spawn(function()
        while farmRunning do
            local target, dist = findNearestTarget()
            
            if target then
                FarmStatus:Set("Flying to: " .. target.Name:sub(1, 15))
                flyToTarget(target)
            else
                FarmStatus:Set("No targets found")
            end
            
            task.wait(0.3)
        end
        
        FarmStatus:Set("Status: STOPPED")
        SETTINGS.IsFarming = false
    end)
end

local function stopFarm()
    farmRunning = false
    if currentTween then
        currentTween:Cancel()
    end
end

local function startAura()
    if auraRunning then return end
    auraRunning = true
    SETTINGS.IsAura = true
    
    task.spawn(function()
        while auraRunning do
            local targets = getAllTargets()
            local hrpPos = humanoidRootPart.Position
            local nearby = {}
            
            -- Находим ближайшие
            for _, pot in ipairs(targets) do
                if pot and pot.Parent then
                    local dist = (hrpPos - pot.Position).Magnitude
                    if dist <= SETTINGS.BreakDistance then
                        table.insert(nearby, pot)
                    end
                end
            end
            
            -- БЬЕМ КАЖДЫЙ!
            if #nearby > 0 then
                AuraStatus:Set("Breaking " .. #nearby .. " pots...")
                for _, pot in ipairs(nearby) do
                    if pot and pot.Parent then
                        breakPot(pot)
                        task.wait(0.1) -- Маленькая задержка между ударами
                    end
                end
            else
                AuraStatus:Set("No pots nearby")
            end
            
            task.wait(0.5) -- Проверка раз в 0.5 сек
        end
        
        AuraStatus:Set("Aura: OFF")
        SETTINGS.IsAura = false
    end)
end

local function stopAura()
    auraRunning = false
end

--// BUTTONS
FarmTab:CreateButton({
    Name = "Toggle Farm",
    Callback = function()
        if SETTINGS.IsFarming then
            stopFarm()
        else
            startFarm()
        end
    end
})

AuraTab:CreateButton({
    Name = "Toggle Aura",
    Callback = function()
        if SETTINGS.IsAura then
            stopAura()
        else
            startAura()
        end
    end
})

--// DEATH HANDLER
humanoid.Died:Connect(function()
    stopFarm()
    stopAura()
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        stopFarm()
        stopAura()
    end)
end)

--// Notify
Rayfield:Notify({
    Title = "Loaded",
    Content = "Aura now PHYSICALLY touches pots!",
    Duration = 3
})
