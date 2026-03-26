--// Загрузка Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Player Setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

--// Config
local SETTINGS = {
    TargetTypes = {
        WaterPot = {
            Names = {"WaterPot", "Water Pot", "waterpot", "water_pot"},
            Enabled = true
        },
        GoldPot = {
            Names = {"GoldPot", "Gold Pot", "goldpot", "gold_pot", "GoldenPot", "Golden Pot", "goldenpot", "GoldenGoldPot", "Golden Gold Pot", "goldengoldpot", "Goldengoldpot"},
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
    IsFarming = false,
    IsAura = false,
    CurrentTween = nil,
    FarmConnection = nil,
    AuraConnection = nil,
    BreakDistance = 8 -- Дистанция для ломания
}

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 Pot Farmer Pro",
    LoadingTitle = "Pot Farmer Pro",
    LoadingSubtitle = "by Rayfield",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PotFarmerPro",
        FileName = "Settings"
    },
    KeySystem = false
})

--// Tabs
local FarmTab = Window:CreateTab("🎯 Farm", "target")
local AuraTab = Window:CreateTab("⚡ Aura", "zap")
local SettingsTab = Window:CreateTab("⚙️ Settings", "settings")

--// FARM TAB
FarmTab:CreateSection("Target Types")

FarmTab:CreateToggle({
    Name = "💧 Water Pot",
    CurrentValue = true,
    Flag = "WaterPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.WaterPot.Enabled = Value
    end
})

FarmTab:CreateToggle({
    Name = "🏆 Gold Pot (Golden + GoldenGold)",
    CurrentValue = true,
    Flag = "GoldPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.GoldPot.Enabled = Value
    end
})

FarmTab:CreateSection("Size Filter")

FarmTab:CreateToggle({
    Name = "Small",
    CurrentValue = true,
    Flag = "Small",
    Callback = function(Value)
        SETTINGS.SizeFilters.Small = Value
    end
})

FarmTab:CreateToggle({
    Name = "Big",
    CurrentValue = true,
    Flag = "Big",
    Callback = function(Value)
        SETTINGS.SizeFilters.Big = Value
    end
})

FarmTab:CreateToggle({
    Name = "Mega",
    CurrentValue = true,
    Flag = "Mega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Mega = Value
    end
})

FarmTab:CreateToggle({
    Name = "Omega",
    CurrentValue = true,
    Flag = "Omega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Omega = Value
    end
})

FarmTab:CreateSection("Speed & Control")

FarmTab:CreateSlider({
    Name = "Tween Speed (0-22)",
    Range = {0, 22},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "Speed",
    Callback = function(Value)
        SETTINGS.CurrentSpeed = Value
    end
})

local StatusLabel = FarmTab:CreateLabel("Status: IDLE")

local ToggleFarmBtn = FarmTab:CreateButton({
    Name = "▶ START FARMING",
    Callback = function()
        SETTINGS.IsFarming = not SETTINGS.IsFarming
        
        if SETTINGS.IsFarming then
            ToggleFarmBtn:Set("⏹ STOP FARMING")
            StatusLabel:Set("Status: FARMING")
            startFarming()
        else
            ToggleFarmBtn:Set("▶ START FARMING")
            StatusLabel:Set("Status: IDLE")
            stopFarming()
        end
    end
})

--// AURA TAB
AuraTab:CreateSection("⚡ Auto Break Aura")

AuraTab:CreateParagraph({
    Title = "Что делает Аура?",
    Content = "Автоматически ломает ВСЕ подходящие поты в радиусе, независимо от Tween. Просто стой на месте или бегай - поты будут ломаться сами!"
})

local AuraStatusLabel = AuraTab:CreateLabel("Aura: OFF")

local ToggleAuraBtn = AuraTab:CreateButton({
    Name = "▶ START AURA",
    Callback = function()
        SETTINGS.IsAura = not SETTINGS.IsAura
        
        if SETTINGS.IsAura then
            ToggleAuraBtn:Set("⏹ STOP AURA")
            AuraStatusLabel:Set("Aura: ON 🔥")
            startAura()
        else
            ToggleAuraBtn:Set("▶ START AURA")
            AuraStatusLabel:Set("Aura: OFF")
            stopAura()
        end
    end
})

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

--// SETTINGS TAB
SettingsTab:CreateSection("Info")

SettingsTab:CreateParagraph({
    Title = "Как использовать:",
    Content = [[
🎯 FARM - Авто-полет к ближайшему поту и ломание
⚡ AURA - Ломает все поты в радиусе без полета

💧 Water Pot - обычные водяные котлы
🏆 Gold Pot - золотые (вкл. Golden, GoldenGold)

Размеры: Small, Big, Mega, Omega

Скорость 0 = почти мгновенно
Скорость 22 = очень быстро
    ]]
})

--// CORE FUNCTIONS

local function getDeployablesFolder()
    local ws = game:GetService("Workspace")
    
    -- Прямые пути
    if ws:FindFirstChild("Deployables") then
        return ws.Deployables
    elseif ws:FindFirstChild("deployables") then
        return ws.deployables
    end
    
    -- Поиск по всему Workspace
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("deploy") and (name:find("pot") or obj:FindFirstChildWhichIsA("BasePart", true)) then
                return obj
            end
        end
    end
    
    return nil
end

local function isValidTarget(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    
    local objName = obj.Name:lower()
    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
    local fullName = objName .. " " .. parentName
    
    -- Check Water Pot
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
    
    -- Check Gold Pot
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

local function findNearestTarget()
    local deployables = getDeployablesFolder()
    if not deployables then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    local hrpPos = humanoidRootPart.Position
    
    for _, obj in ipairs(deployables:GetDescendants()) do
        if isValidTarget(obj) and obj:IsA("BasePart") then
            local dist = (hrpPos - obj.Position).Magnitude
            -- Не берем если уже очень близко (меньше 3 студов)
            if dist < nearestDist and dist > 3 then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    
    return nearest, nearestDist
end

local function findAllTargetsInRadius(radius)
    local deployables = getDeployablesFolder()
    if not deployables then return {} end
    
    local targets = {}
    local hrpPos = humanoidRootPart.Position
    
    for _, obj in ipairs(deployables:GetDescendants()) do
        if isValidTarget(obj) and obj:IsA("BasePart") then
            local dist = (hrpPos - obj.Position).Magnitude
            if dist <= radius then
                table.insert(targets, obj)
            end
        end
    end
    
    return targets
end

local function breakPot(pot)
    if not pot or not pot.Parent then return end
    
    -- Метод 1: firetouchinterest (основной)
    pcall(function()
        firetouchinterest(pot, humanoidRootPart, 0)
        task.wait(0.05)
        firetouchinterest(pot, humanoidRootPart, 1)
    end)
    
    -- Метод 2: Симуляция клика если есть ClickDetector
    pcall(function()
        local clickDetector = pot:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
        end
    end)
    
    -- Метод 3: Телепорт на место пота на 1 кадр (для сложных анти-читов)
    pcall(function()
        if (humanoidRootPart.Position - pot.Position).Magnitude < 10 then
            local oldCFrame = humanoidRootPart.CFrame
            humanoidRootPart.CFrame = CFrame.new(pot.Position + Vector3.new(0, 2, 0))
            task.wait(0.05)
            humanoidRootPart.CFrame = oldCFrame
        end
    end)
end

local function tweenToTarget(target)
    if not target or not target.Parent then return end
    
    local distance = (humanoidRootPart.Position - target.Position).Magnitude
    
    -- Расчет времени
    local tweenTime
    if SETTINGS.CurrentSpeed == 0 then
        tweenTime = 0.01
    else
        tweenTime = distance / (SETTINGS.CurrentSpeed * 8)
    end
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    -- Целевая позиция (немного выше пота)
    local targetPos = target.Position + Vector3.new(0, 4, 0)
    local targetCFrame = CFrame.new(targetPos, targetPos + (target.Position - humanoidRootPart.Position).Unit)
    
    SETTINGS.CurrentTween = TweenService:Create(humanoidRootPart, tweenInfo, {
        CFrame = targetCFrame
    })
    
    SETTINGS.CurrentTween:Play()
    
    -- Проверяем расстояние во время полета для раннего ломания
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not SETTINGS.IsFarming or not target.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        local dist = (humanoidRootPart.Position - target.Position).Magnitude
        if dist < SETTINGS.BreakDistance then
            breakPot(target)
            if connection then connection:Disconnect() end
        end
    end)
    
    SETTINGS.CurrentTween.Completed:Wait()
    if connection then connection:Disconnect() end
    
    -- Финальное ломание если не сломалось
    breakPot(target)
end

--// FARMING LOOP
function startFarming()
    SETTINGS.FarmConnection = task.spawn(function()
        while SETTINGS.IsFarming do
            if not SETTINGS.CurrentTween or SETTINGS.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                local target, dist = findNearestTarget()
                
                if target then
                    StatusLabel:Set("Status: Flying to " .. target.Name .. " (" .. math.floor(dist) .. " studs)")
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

function stopFarming()
    SETTINGS.IsFarming = false
    if SETTINGS.CurrentTween then
        SETTINGS.CurrentTween:Cancel()
        SETTINGS.CurrentTween = nil
    end
end

--// AURA LOOP
function startAura()
    SETTINGS.AuraConnection = RunService.Heartbeat:Connect(function()
        if not SETTINGS.IsAura then return end
        
        local targets = findAllTargetsInRadius(SETTINGS.BreakDistance)
        
        if #targets > 0 then
            AuraStatusLabel:Set("Aura: ON 🔥 (" .. #targets .. " pots)")
            
            for _, target in ipairs(targets) do
                if target and target.Parent then
                    breakPot(target)
                end
            end
        else
            AuraStatusLabel:Set("Aura: ON (searching...)")
        end
    end)
end

function stopAura()
    SETTINGS.IsAura = false
    if SETTINGS.AuraConnection then
        SETTINGS.AuraConnection:Disconnect()
        SETTINGS.AuraConnection = nil
    end
end

--// EVENTS
character.Humanoid.Died:Connect(function()
    stopFarming()
    stopAura()
    SETTINGS.IsFarming = false
    SETTINGS.IsAura = false
    ToggleFarmBtn:Set("▶ START FARMING")
    ToggleAuraBtn:Set("▶ START AURA")
    StatusLabel:Set("Status: DEAD")
    AuraStatusLabel:Set("Aura: OFF")
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        stopFarming()
        stopAura()
        SETTINGS.IsFarming = false
        SETTINGS.IsAura = false
        ToggleFarmBtn:Set("▶ START FARMING")
        ToggleAuraBtn:Set("▶ START AURA")
    end)
end)

--// Notify
Rayfield:Notify({
    Title = "✅ Loaded!",
    Content = "Pot Farmer Pro ready. Use FARM for auto-fly or AURA for auto-break!",
    Duration = 5
})

print("✅ Pot Farmer Pro loaded!")
print("Deployables folder:", getDeployablesFolder())
