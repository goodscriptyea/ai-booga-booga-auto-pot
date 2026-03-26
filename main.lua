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
    -- Farm targets
    FarmWater = false,
    FarmGold = false,
    FarmSizes = {Small = false, Big = false, Mega = false, Omega = false},
    
    -- Aura targets (отдельные!)
    AuraWater = false,
    AuraGold = false,
    AuraSizes = {Small = false, Big = false, Mega = false, Omega = false},
    
    Speed = 5,
    IsFarming = false,
    IsAura = false,
    BreakDistance = 8,
    AuraDelay = 0.5 -- Задержка ауры
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

FarmTab:CreateToggle({
    Name = "💧 Water Pot",
    CurrentValue = false,
    Callback = function(V) SETTINGS.FarmWater = V end
})

FarmTab:CreateToggle({
    Name = "🏆 Gold Pot",
    CurrentValue = false,
    Callback = function(V) SETTINGS.FarmGold = V end
})

FarmTab:CreateSection("Farm Sizes")

FarmTab:CreateToggle({Name = "Small", CurrentValue = false, Callback = function(V) SETTINGS.FarmSizes.Small = V end})
FarmTab:CreateToggle({Name = "Big", CurrentValue = false, Callback = function(V) SETTINGS.FarmSizes.Big = V end})
FarmTab:CreateToggle({Name = "Mega", CurrentValue = false, Callback = function(V) SETTINGS.FarmSizes.Mega = V end})
FarmTab:CreateToggle({Name = "Omega", CurrentValue = false, Callback = function(V) SETTINGS.FarmSizes.Omega = V end})

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
AuraTab:CreateSection("⚡ Aura Targets (выбор что ломать)")

AuraTab:CreateToggle({
    Name = "💧 Water Pot",
    CurrentValue = false,
    Callback = function(V) SETTINGS.AuraWater = V end
})

AuraTab:CreateToggle({
    Name = "🏆 Gold Pot",
    CurrentValue = false,
    Callback = function(V) SETTINGS.AuraGold = V end
})

AuraTab:CreateSection("Aura Sizes")

AuraTab:CreateToggle({Name = "Small", CurrentValue = false, Callback = function(V) SETTINGS.AuraSizes.Small = V end})
AuraTab:CreateToggle({Name = "Big", CurrentValue = false, Callback = function(V) SETTINGS.AuraSizes.Big = V end})
AuraTab:CreateToggle({Name = "Mega", CurrentValue = false, Callback = function(V) SETTINGS.AuraSizes.Mega = V end})
AuraTab:CreateToggle({Name = "Omega", CurrentValue = false, Callback = function(V) SETTINGS.AuraSizes.Omega = V end})

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
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name:lower():find("deploy") then return obj end
    end
    return nil
end

local function matchesFilter(obj, waterEnabled, goldEnabled, sizes)
    if not obj or not obj:IsA("BasePart") then return false end
    
    local name = (obj.Name .. " " .. (obj.Parent and obj.Parent.Name or "")):lower()
    
    local anySize = false
    for _, active in pairs(sizes) do if active then anySize = true break end end
    if not anySize then return false end
    
    local isWater = name:find("water")
    local isGold = name:find("gold") or name:find("golden")
    
    if waterEnabled and isGold then return false end -- Gold содержит "old", исключаем если ищем Water
    if goldEnabled and isWater then return false end
    
    local typeMatch = (waterEnabled and isWater) or (goldEnabled and isGold)
    if not typeMatch then return false end
    
    for size, active in pairs(sizes) do
        if active and name:find(size:lower()) then return true end
    end
    
    return false
end

local function getTargets(water, gold, sizes)
    local deployables = getDeployables()
    if not deployables then return {} end
    
    local targets = {}
    for _, obj in ipairs(deployables:GetDescendants()) do
        if matchesFilter(obj, water, gold, sizes) then
            table.insert(targets, obj)
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

--// TWEEN (медленнее)
local currentTween = nil

local function flyTo(target)
    if not target or not target.Parent then return end
    
    local dist = (humanoidRootPart.Position - target.Position).Magnitude
    local time = 0.01
    if SETTINGS.Speed > 0 then
        time = dist / (SETTINGS.Speed * 4) -- Медленнее (было *10)
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
            local targets = getTargets(SETTINGS.FarmWater, SETTINGS.FarmGold, SETTINGS.FarmSizes)
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
                FarmStatus:Set("To: " .. nearest.Name:sub(1, 12))
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

local lastAuraTargets = {}

local function startAura()
    if auraRun then return end
    auraRun = true
    SETTINGS.IsAura = true
    
    task.spawn(function()
        while auraRun do
            local targets = getTargets(SETTINGS.AuraWater, SETTINGS.AuraGold, SETTINGS.AuraSizes)
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
                AuraStatus:Set("Breaking " .. #toBreak .. "...")
                
                -- Бьем по очереди без лагов
                for i, pot in ipairs(toBreak) do
                    if not auraRun then break end
                    if pot and pot.Parent then
                        breakPot(pot)
                        AuraStatus:Set("Broke " .. i .. "/" .. #toBreak)
                        task.wait(0.15) -- Задержка между ударами
                    end
                end
            else
                AuraStatus:Set("No pots nearby")
            end
            
            task.wait(SETTINGS.AuraDelay)
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

Rayfield:Notify({Title = "Loaded", Content = "Farm and Aura have separate settings!", Duration = 3})
