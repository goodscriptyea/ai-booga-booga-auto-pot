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
    BreakDistance = 8,
    CacheTime = 0.5 -- Кэширование целей
}

--// Cache
local targetCache = {}
local lastCacheUpdate = 0

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
        clearCache()
    end
})

FarmTab:CreateToggle({
    Name = "🏆 Gold Pot",
    CurrentValue = false,
    Flag = "GoldPot",
    Callback = function(Value)
        SETTINGS.TargetTypes.GoldPot.Enabled = Value
        clearCache()
    end
})

FarmTab:CreateSection("Size Filter")

FarmTab:CreateToggle({
    Name = "Small",
    CurrentValue = false,
    Flag = "Small",
    Callback = function(Value)
        SETTINGS.SizeFilters.Small = Value
        clearCache()
    end
})

FarmTab:CreateToggle({
    Name = "Big",
    CurrentValue = false,
    Flag = "Big",
    Callback = function(Value)
        SETTINGS.SizeFilters.Big = Value
        clearCache()
    end
})

FarmTab:CreateToggle({
    Name = "Mega",
    CurrentValue = false,
    Flag = "Mega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Mega = Value
        clearCache()
    end
})

FarmTab:CreateToggle({
    Name = "Omega",
    CurrentValue = false,
    Flag = "Omega",
    Callback = function(Value)
        SETTINGS.SizeFilters.Omega = Value
        clearCache()
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

local function clearCache()
    targetCache = {}
    lastCacheUpdate = 0
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

local function updateTargetCache()
    local now = tick()
    if now - lastCacheUpdate < SETTINGS.CacheTime then
        return targetCache
    end
    
    local deployables = getDeployablesFolder()
    if not deployables then
        targetCache = {}
        return targetCache
    end
    
    targetCache = {}
    for _, obj in ipairs(deployables:GetDescendants()) do
        if isValidTarget(obj) then
            table.insert(targetCache, obj)
        end
    end
    
    lastCacheUpdate = now
    return targetCache
end

local function findNearestTarget()
    local cache = updateTargetCache()
    if #cache == 0 then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    local hrpPos = humanoidRootPart.Position
    
    for _, obj in ipairs(cache) do
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

local function findTargetsInRadius(radius)
    local cache = updateTargetCache()
    local result = {}
    local hrpPos = humanoidRootPart.Position
    
    for _, obj in ipairs(cache) do
        if obj and obj.Parent then
            local dist = (hrpPos - obj.Position).Magnitude
            if dist <= radius then
                table.insert(result, obj)
            end
        end
    end
    
    return result
end

local function breakPot(pot)
    if not pot or not pot.Parent then return end
    
    pcall(function()
        firetouchinterest(pot, humanoidRootPart, 0)
        task.wait()
        firetouchinterest(pot, humanoidRootPart, 1)
    end)
    
    pcall(function()
        local click = pot:FindFirstChildOfClass("ClickDetector")
        if click then fireclickdetector(click) end
    end)
    
    pcall(function()
        local prompt = pot:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
    end)
end

--// TWEEN (НЕ ТЕЛЕПОРТ!)
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
    
    -- Ломание при приближении
    local startTime = tick()
    while currentTween and (currentTween.PlaybackState == Enum.PlaybackState.Playing) do
        if tick() - startTime > tweenTime + 1 then break end
        
        if target and target.Parent then
            local dist = (humanoidRootPart.Position - target.Position).Magnitude
            if dist < SETTINGS.BreakDistance then
                breakPot(target)
            end
        end
        
        task.wait(0.1)
    end
    
    breakPot(target)
end

--// LOOPS
local farmLoop = nil
local auraLoop = nil

local function startFarm()
    if farmLoop then return end
    
    SETTINGS.IsFarming = true
    FarmStatus:Set("Status: RUNNING")
    
    farmLoop = task.spawn(function()
        while SETTINGS.IsFarming do
            local target, dist = findNearestTarget()
            
            if target then
                FarmStatus:Set("Flying to: " .. target.Name:sub(1, 15))
                flyToTarget(target)
            else
                FarmStatus:Set("No targets found")
                task.wait(0.5)
            end
            
            task.wait(0.2)
        end
    end)
end

local function stopFarm()
    SETTINGS.IsFarming = false
    FarmStatus:Set("Status: STOPPED")
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    farmLoop = nil
end

local function startAura()
    if auraLoop then return end
    
    SETTINGS.IsAura = true
    
    auraLoop = task.spawn(function()
        while SETTINGS.IsAura do
            local targets = findTargetsInRadius(SETTINGS.BreakDistance)
            
            AuraStatus:Set("Breaking " .. #targets .. " pots")
            
            for _, target in ipairs(targets) do
                if target and target.Parent then
                    breakPot(target)
                end
            end
            
            task.wait(0.2) -- Задержка чтобы не лагало
        end
    end)
end

local function stopAura()
    SETTINGS.IsAura = false
    AuraStatus:Set("Aura: OFF")
    auraLoop = nil
end

--// BUTTONS (Простые, без пересоздания)
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
    Content = "All OFF by default. Enable types and sizes first!",
    Duration = 3
})
