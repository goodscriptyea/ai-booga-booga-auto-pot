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

--// ТОЧНЫЕ НАЗВАНИЯ ИЗ workspace.Deployables
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
    -- Farm targets (точные названия)
    FarmTargets = {},
    
    -- Aura targets (отдельные!)
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
FarmTab:CreateSection("Farm Targets (выбери что лететь)")

-- Создаем тогглы для каждого пота
for _, name in ipairs(POT_NAMES) do
    SETTINGS.FarmTargets[name] = false
    FarmTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(V) 
            SETTINGS.FarmTargets[name] = V 
        end
    })
end

FarmTab:CreateSection("Speed (0-22)")

FarmTab:CreateSlider({
    Name = "Speed",
    Range = {0, 22},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(V) SETTINGS.Speed = V end
})

local FarmStatus = FarmTab:CreateLabel("Status: IDLE")

--// AURA TAB
AuraTab:CreateSection("⚡ Aura Targets (выбери что ломать)")

-- Создаем тогглы для ауры (отдельные!)
for _, name in ipairs(POT_NAMES) do
    SETTINGS.AuraTargets[name] = false
    AuraTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(V) 
            SETTINGS.AuraTargets[name] = V 
        end
    })
end

AuraTab:CreateSection("Settings")

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
    if ws:FindFirstChild("Deployables") then return ws.Deployables end
    if ws:FindFirstChild("deployables") then return ws.deployables end
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
    for _, obj in ipairs(deployables:GetChildren()) do -- Только прямые дети, не глубокий поиск
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if isTargetEnabled(obj, targetTable) then
                -- Если модель, берем PrimaryPart или первый BasePart
                if obj:IsA("Model") then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part then table.insert(targets, part) end
                else
                    table.insert(targets, obj)
                end
            end
        end
    end
    return targets
end

local function breakPot(pot)
    if not pot or not pot.Parent then return end
    
    -- Телепорт на пот
    humanoidRootPart.CFrame = CFrame.new(pot.Position + Vector3.new(0, 3, 0))
    
    -- Касание
    pcall(function()
        firetouchinterest(pot, humanoidRootPart, 0)
        task.wait(0.03)
        firetouchinterest(pot, humanoidRootPart, 1)
    end)
    
    -- Клик/промпт
    pcall(function()
        local click = pot:FindFirstChildOfClass("ClickDetector")
        if click then fireclickdetector(click) end
    end)
    pcall(function()
        local prompt = pot:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
    end)
end

--// TWEEN
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
    
    breakPot(target)
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
                FarmStatus:Set("To: " .. nearest.Parent and nearest.Parent.Name or nearest.Name)
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

local function startAura()
    if auraRun then return end
    auraRun = true
    SETTINGS.IsAura = true
    
    task.spawn(function()
        while auraRun do
            local targets = getEnabledTargets(SETTINGS.AuraTargets)
            local pos = humanoidRootPart.Position
            local toBreak = {}
            
            for _, pot in ipairs(targets) do
                if pot and pot.Parent then
                    local d = (pos - pot.Position).Magnitude
                    if d <= SETTINGS.BreakDistance then
                        table.insert(toBreak, pot)
                    end
                end
            end
            
            if #toBreak > 0 then
                AuraStatus:Set("Breaking " .. #toBreak .. "...")
                
                for i, pot in ipairs(toBreak) do
                    if not auraRun then break end
                    if pot and pot.Parent then
                        breakPot(pot)
                        AuraStatus:Set("Broke " .. i .. "/" .. #toBreak)
                        task.wait(0.15)
                    end
                end
            else
                AuraStatus:Set("No pots nearby")
            end
            
            task.wait(0.5)
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

Rayfield:Notify({Title = "Loaded", Content = "Exact names from Deployables!", Duration = 3})
