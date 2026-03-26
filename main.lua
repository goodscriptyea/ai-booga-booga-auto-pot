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

--// ТОЧНЫЕ НАЗВАНИЯ
local POT_NAMES = {
    "Gold Pot",
    "Golden Gold Pot", 
    "Golden Mega Gold Pot",
    "Mega Gold Pot",
    "Water Pot",
    "Golden Omega Gold Pot",
    "Omega Gold Pot"
}

--// Config
local SETTINGS = {
    FarmTargets = {},
    AuraTargets = {},
    Speed = 5,
    IsFarming = false,
    IsAura = false,
    BreakDistance = 8
}

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 Pot Farmer",
    LoadingTitle = "Pot Farmer",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

--// TABS
local FarmTab = Window:CreateTab("🎯 Farm", "target")
local AuraTab = Window:CreateTab("⚡ Aura", "zap")

--// FARM TAB
FarmTab:CreateSection("Farm Targets")

for _, name in ipairs(POT_NAMES) do
    SETTINGS.FarmTargets[name] = false
    FarmTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(V) SETTINGS.FarmTargets[name] = V end
    })
end

FarmTab:CreateSlider({
    Name = "Speed (0-22)",
    Range = {0, 22},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(V) SETTINGS.Speed = V end
})

local FarmStatus = FarmTab:CreateLabel("Status: IDLE")

--// AURA TAB
AuraTab:CreateSection("⚡ Aura Targets")

for _, name in ipairs(POT_NAMES) do
    SETTINGS.AuraTargets[name] = false
    AuraTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(V) SETTINGS.AuraTargets[name] = V end
    })
end

AuraTab:CreateSlider({
    Name = "Break Distance",
    Range = {3, 20},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 8,
    Callback = function(V) SETTINGS.BreakDistance = V end
})

local AuraStatus = AuraTab:CreateLabel("Aura: OFF")

--// FUNCTIONS

local function getDeployables()
    local ws = game:GetService("Workspace")
    return ws:FindFirstChild("Deployables") or ws:FindFirstChild("deployables")
end

local function getPartFromObj(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function isTargetEnabled(obj, targetTable)
    if not obj then return false end
    return targetTable[obj.Name] == true
end

local function getEnabledTargets(targetTable)
    local deployables = getDeployables()
    if not deployables then return {} end
    
    local targets = {}
    for _, obj in ipairs(deployables:GetChildren()) do
        if isTargetEnabled(obj, targetTable) then
            local part = getPartFromObj(obj)
            if part then table.insert(targets, part) end
        end
    end
    return targets
end

--// РАБОЧЕЕ ЛОМАНИЕ (с касанием)
local function breakPot(pot)
    if not pot or not pot.Parent then return false end
    
    local success = false
    
    -- Способ 1: Телепорт ВНУТРЬ пота и касание
    pcall(function()
        -- Запоминаем старую позицию
        local oldCFrame = humanoidRootPart.CFrame
        
        -- Телепорт прямо в центр пота
        humanoidRootPart.CFrame = CFrame.new(pot.Position)
        
        -- Ждем один кадр чтобы физика обновилась
        task.wait(0.05)
        
        -- Fire touch (0 = начать касание)
        firetouchinterest(pot, humanoidRootPart, 0)
        task.wait(0.1)
        -- Fire touch (1 = закончить касание)
        firetouchinterest(pot, humanoidRootPart, 1)
        
        success = true
        
        -- Возврат на место (опционально)
        -- task.wait(0.05)
        -- humanoidRootPart.CFrame = oldCFrame
    end)
    
    -- Способ 2: ClickDetector
    pcall(function()
        local click = pot.Parent:FindFirstChildOfClass("ClickDetector") or pot:FindFirstChildOfClass("ClickDetector")
        if click then 
            fireclickdetector(click)
            success = true
        end
    end)
    
    -- Способ 3: ProximityPrompt
    pcall(function()
        local prompt = pot.Parent:FindFirstChildOfClass("ProximityPrompt") or pot:FindFirstChildOfClass("ProximityPrompt")
        if prompt then 
            fireproximityprompt(prompt)
            success = true
        end
    end)
    
    return success
end

--// TWEEN (для фарма)
local currentTween = nil

local function flyTo(target)
    if not target or not target.Parent then return end
    
    local dist = (humanoidRootPart.Position - target.Position).Magnitude
    local time = 0.01
    if SETTINGS.Speed > 0 then
        time = dist / (SETTINGS.Speed * 4)
    end
    
    local info = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local cf = CFrame.new(target.Position + Vector3.new(0, 4, 0))
    
    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(humanoidRootPart, info, {CFrame = cf})
    currentTween:Play()
    currentTween.Completed:Wait()
    
    -- Бьем несколько раз
    for i = 1, 3 do
        breakPot(target)
        task.wait(0.1)
    end
end

--// LOOPS
local farmRun = false
local auraRun = false

local function startFarm()
    if farmRun then return end
    farmRun = true
    SETTINGS.IsFarming = true
    FarmStatus:Set("Running...")
    
    task.spawn(function()
        while farmRun do
            local targets = getEnabledTargets(SETTINGS.FarmTargets)
            local nearest = nil
            local nearDist = math.huge
            local pos = humanoidRootPart.Position
            
            for _, t in ipairs(targets) do
                if t and t.Parent then
                    local d = (pos - t.Position).Magnitude
                    if d < nearDist and d > 2 then
                        nearDist = d
                        nearest = t
                    end
                end
            end
            
            if nearest then
                FarmStatus:Set("To: " .. nearest.Parent.Name)
                flyTo(nearest)
            else
                FarmStatus:Set("No targets")
            end
            
            task.wait(0.2)
        end
        FarmStatus:Set("Stopped")
        SETTINGS.IsFarming = false
    end)
end

local function stopFarm()
    farmRun = false
    if currentTween then currentTween:Cancel() end
end

--// AURA (рабочая!)
local function startAura()
    if auraRun then return end
    auraRun = true
    SETTINGS.IsAura = true
    
    task.spawn(function()
        while auraRun do
            local targets = getEnabledTargets(SETTINGS.AuraTargets)
            local pos = humanoidRootPart.Position
            local toBreak = {}
            
            -- Собираем ближайшие
            for _, pot in ipairs(targets) do
                if pot and pot.Parent then
                    local d = (pos - pot.Position).Magnitude
                    if d <= SETTINGS.BreakDistance then
                        table.insert(toBreak, pot)
                    end
                end
            end
            
            if #toBreak > 0 then
                AuraStatus:Set("Found " .. #toBreak .. " pots")
                
                -- Бьем каждый по очереди
                for i, pot in ipairs(toBreak) do
                    if not auraRun then break end
                    
                    AuraStatus:Set("Breaking " .. pot.Parent.Name .. " (" .. i .. "/" .. #toBreak .. ")")
                    
                    -- Телепорт и удар
                    local broken = breakPot(pot)
                    
                    if broken then
                        AuraStatus:Set("✓ Broke " .. pot.Parent.Name)
                    else
                        AuraStatus:Set("✗ Failed " .. pot.Parent.Name)
                    end
                    
                    -- Задержка между ударами
                    task.wait(0.2)
                end
            else
                AuraStatus:Set("No pots in range")
            end
            
            task.wait(0.3)
        end
        AuraStatus:Set("Aura: OFF")
        SETTINGS.IsAura = false
    end)
end

local function stopAura()
    auraRun = false
end

--// BUTTONS
FarmTab:CreateButton({
    Name = "Toggle Farm",
    Callback = function()
        if SETTINGS.IsFarming then stopFarm() else startFarm() end
    end
})

AuraTab:CreateButton({
    Name = "Toggle Aura",
    Callback = function()
        if SETTINGS.IsAura then stopAura() else startAura() end
    end
})

--// DEATH
humanoid.Died:Connect(function()
    stopFarm()
    stopAura()
end)

player.CharacterAdded:Connect(function(c)
    character = c
    humanoidRootPart = c:WaitForChild("HumanoidRootPart")
    humanoid = c:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        stopFarm()
        stopAura()
    end)
end)

Rayfield:Notify({Title = "Loaded", Content = "Aura now really breaks pots!", Duration = 3})
