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

--// Config (ВСЕ ВЫКЛЮЧЕНО по умолчанию!)
local SETTINGS = {
    TargetTypes = {
        WaterPot = {
            Names = {"WaterPot", "Water Pot", "waterpot", "water_pot"},
            Enabled = false -- ВЫКЛЮЧЕНО
        },
        GoldPot = {
            Names = {"GoldPot", "Gold Pot", "goldpot", "gold_pot", "GoldenPot", "Golden Pot", "goldenpot", "GoldenGoldPot", "Golden Gold Pot", "goldengoldpot", "Goldengoldpot"},
            Enabled = false -- ВЫКЛЮЧЕНО
        }
    },
    SizeFilters = {
        Small = false, -- ВЫКЛЮЧЕНО (нет таких)
        Big = false,   -- ВЫКЛЮЧЕНО
        Mega = false,  -- ВЫКЛЮЧЕНО
        Omega = false  -- ВЫКЛЮЧЕНО
    },
    CurrentSpeed = 5,
    IsFarming = false,
    IsAura = false,
    CurrentTween = nil,
    FarmConnection = nil,
    AuraConnection = nil,
    BreakDistance = 8
}

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 Pot Farmer Pro",
    LoadingTitle = "Pot Farmer Pro",
    LoadingSubtitle = "by Rayfield",
    ConfigurationSaving = {
        Enabled = false, -- Отключаем сохранение чтобы не было конфликтов
        FolderName = "PotFarmerPro",
        FileName = "Settings"
    },
    KeySystem = false
})

--// Tabs
local FarmTab = Window:CreateTab("🎯 Farm", "target")
local AuraTab = Window:CreateTab("⚡ Aura", "zap")
local DebugTab = Window:CreateTab("🐛 Debug", "bug")

--// FARM TAB
FarmTab:CreateSection("Target Types")

local WaterToggle = FarmTab:CreateToggle({
    Name = "💧 Water Pot",
    CurrentValue = false, -- ВЫКЛЮЧЕНО
    Flag = "WaterPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.WaterPot.Enabled = Value
    end
})

local GoldToggle = FarmTab:CreateToggle({
    Name = "🏆 Gold Pot (Golden + GoldenGold)",
    CurrentValue = false, -- ВЫКЛЮЧЕНО
    Flag = "GoldPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.GoldPot.Enabled = Value
    end
})

FarmTab:CreateSection("Size Filter")

local SmallToggle = FarmTab:CreateToggle({
    Name = "Small",
    CurrentValue = false, -- ВЫКЛЮЧЕНО
    Flag = "Small",
    Callback = function(Value)
        SETTINGS.SizeFilters.Small = Value
    end
})

local BigToggle = FarmTab:CreateToggle({
    Name = "Big",
    CurrentValue = false, -- ВЫКЛЮЧЕНО
    Flag = "Big",
    Callback = function(Value)
        SETTINGS.SizeFilters.Big = Value
    end
})

local MegaToggle = FarmTab:CreateToggle({
    Name = "Mega",
    CurrentValue = false, -- ВЫКЛЮЧЕНО
    Flag = "Mega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Mega = Value
    end
})

local OmegaToggle = FarmTab:CreateToggle({
    Name = "Omega",
    CurrentValue = false, -- ВЫКЛЮЧЕНО
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

-- Переменные для кнопок (объявляем заранее)
local FarmButton
local AuraButton

-- Функция для создания/обновления кнопки фарма
local function updateFarmButton()
    if FarmButton then
        FarmButton:Destroy()
    end
    
    FarmButton = FarmTab:CreateButton({
        Name = SETTINGS.IsFarming and "⏹ STOP FARMING" or "▶ START FARMING",
        Callback = function()
            SETTINGS.IsFarming = not SETTINGS.IsFarming
            
            if SETTINGS.IsFarming then
                StatusLabel:Set("Status: STARTING...")
                startFarming()
            else
                StatusLabel:Set("Status: STOPPED")
                stopFarming()
            end
            
            -- Обновляем кнопку
            task.delay(0.1, updateFarmButton)
        end
    })
end

--// AURA TAB
AuraTab:CreateSection("⚡ Auto Break Aura")

AuraTab:CreateParagraph({
    Title = "Что делает Аура?",
    Content = "Автоматически ломает ВСЕ подходящие поты в радиусе. Просто включи и бегай рядом с потами!"
})

local AuraStatusLabel = AuraTab:CreateLabel("Aura: OFF")

-- Функция для создания/обновления кнопки ауры
local function updateAuraButton()
    if AuraButton then
        AuraButton:Destroy()
    end
    
    AuraButton = AuraTab:CreateButton({
        Name = SETTINGS.IsAura and "⏹ STOP AURA" or "▶ START AURA",
        Callback = function()
            SETTINGS.IsAura = not SETTINGS.IsAura
            
            if SETTINGS.IsAura then
                AuraStatusLabel:Set("Aura: ON 🔥")
                startAura()
            else
                AuraStatusLabel:Set("Aura: OFF")
                stopAura()
            end
            
            -- Обновляем кнопку
            task.delay(0.1, updateAuraButton)
        end
    })
end

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

--// DEBUG TAB (для поиска проблем)
DebugTab:CreateSection("Debug Info")

local DebugLabel = DebugTab:CreateLabel("Checking...")

DebugTab:CreateButton({
    Name = "🔍 Scan Deployables",
    Callback = function()
        scanDeployables()
    end
})

DebugTab:CreateButton({
    Name = "📋 Print All Pots",
    Callback = function()
        printAllPots()
    end
})

DebugTab:CreateParagraph({
    Title = "Инструкция",
    Content = [[
1. Нажми "Scan Deployables" чтобы найти папку
2. Нажми "Print All Pots" чтобы увидеть все поты
3. Включи нужные типы (Water/Gold)
4. Включи размеры которые есть в игре
5. Нажми START FARMING или START AURA
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
    elseif ws:FindFirstChild("Workspace") and ws.Workspace:FindFirstChild("Deployables") then
        return ws.Workspace.Deployables
    end
    
    -- Поиск по всему Workspace
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("deploy") then
                return obj
            end
        end
    end
    
    return nil
end

local function scanDeployables()
    local folder = getDeployablesFolder()
    if folder then
        DebugLabel:Set("Found: " .. folder.Name .. " (" .. folder.ClassName .. ")")
        Rayfield:Notify({
            Title = "Found!",
            Content = "Deployables: " .. folder:GetFullName(),
            Duration = 3
        })
    else
        DebugLabel:Set("Not found! Check workspace")
        Rayfield:Notify({
            Title = "Error",
            Content = "Deployables folder not found!",
            Duration = 3
        })
    end
end

local function printAllPots()
    local folder = getDeployablesFolder()
    if not folder then
        DebugLabel:Set("No Deployables folder!")
        return
    end
    
    local pots = {}
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("pot") or name:find("water") or name:find("gold") then
                table.insert(pots, obj.Name .. " (" .. obj.ClassName .. ")")
            end
        end
    end
    
    print("=== ALL POTS ===")
    for i, pot in ipairs(pots) do
        print(i, pot)
    end
    
    DebugLabel:Set("Found " .. #pots .. " pots (check console F9)")
    Rayfield:Notify({
        Title = "Scan Complete",
        Content = "Found " .. #pots .. " pots. Check console (F9)",
        Duration = 3
    })
end

local function isValidTarget(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    
    local objName = obj.Name:lower()
    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
    local fullName = objName .. " " .. parentName
    
    -- Проверка активности хотя бы одного размера
    local anySizeEnabled = false
    for _, active in pairs(SETTINGS.SizeFilters) do
        if active then
            anySizeEnabled = true
            break
        end
    end
    
    if not anySizeEnabled then return false end
    
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
    if not deployables then 
        StatusLabel:Set("Status: No Deployables folder!")
        return nil 
    end
    
    local nearest = nil
    local nearestDist = math.huge
    local hrpPos = humanoidRootPart.Position
    
    for _, obj in ipairs(deployables:GetDescendants()) do
        if isValidTarget(obj) then
            local dist = (hrpPos - obj.Position).Magnitude
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
        if isValidTarget(obj) then
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
    
    -- Метод 1: firetouchinterest
    pcall(function()
        firetouchinterest(pot, humanoidRootPart, 0)
        task.wait(0.01)
        firetouchinterest(pot, humanoidRootPart, 1)
    end)
    
    -- Метод 2: ClickDetector
    pcall(function()
        local clickDetector = pot:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
        end
    end)
    
    -- Метод 3: ProximityPrompt
    pcall(function()
        local prompt = pot:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
    end)
end

local function tweenToTarget(target)
    if not target or not target.Parent then return end
    
    local distance = (humanoidRootPart.Position - target.Position).Magnitude
    
    local tweenTime
    if SETTINGS.CurrentSpeed <= 0 then
        tweenTime = 0.01
    else
        tweenTime = distance / (SETTINGS.CurrentSpeed * 8)
    end
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local targetPos = target.Position + Vector3.new(0, 4, 0)
    local targetCFrame = CFrame.new(targetPos)
    
    SETTINGS.CurrentTween = TweenService:Create(humanoidRootPart, tweenInfo, {
        CFrame = targetCFrame
    })
    
    -- Ломание во время полета
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not target.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        local dist = (humanoidRootPart.Position - target.Position).Magnitude
        if dist < SETTINGS.BreakDistance then
            breakPot(target)
        end
    end)
    
    SETTINGS.CurrentTween:Play()
    SETTINGS.CurrentTween.Completed:Wait()
    
    if connection then connection:Disconnect() end
    breakPot(target)
end

--// FARMING LOOP
function startFarming()
    task.spawn(function()
        while SETTINGS.IsFarming do
            if not SETTINGS.CurrentTween or SETTINGS.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                local target, dist = findNearestTarget()
                
                if target then
                    StatusLabel:Set("Flying to: " .. target.Name .. " (" .. math.floor(dist) .. "st)")
                    tweenToTarget(target)
                else
                    StatusLabel:Set("No targets! Check filters.")
                    task.wait(0.5)
                end
            end
            task.wait(0.1)
        end
    end)
end

function stopFarming()
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
            AuraStatusLabel:Set("Aura: ON | Breaking " .. #targets .. " pots")
            
            for _, target in ipairs(targets) do
                if target and target.Parent then
                    breakPot(target)
                end
            end
        else
            AuraStatusLabel:Set("Aura: ON | No pots nearby")
        end
    end)
end

function stopAura()
    if SETTINGS.AuraConnection then
        SETTINGS.AuraConnection:Disconnect()
        SETTINGS.AuraConnection = nil
    end
end

--// EVENTS
humanoid.Died:Connect(function()
    SETTINGS.IsFarming = false
    SETTINGS.IsAura = false
    stopFarming()
    stopAura()
    updateFarmButton()
    updateAuraButton()
    StatusLabel:Set("Status: DEAD")
    AuraStatusLabel:Set("Aura: OFF")
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        SETTINGS.IsFarming = false
        SETTINGS.IsAura = false
        stopFarming()
        stopAura()
        updateFarmButton()
        updateAuraButton()
    end)
end)

--// Initialize Buttons
updateFarmButton()
updateAuraButton()

--// Notify
Rayfield:Notify({
    Title = "✅ Loaded!",
    Content = "All features OFF by default. Use Debug tab to scan!",
    Duration = 5
})

print("✅ Pot Farmer Pro loaded!")
print("Use Debug tab -> Scan Deployables first!")
