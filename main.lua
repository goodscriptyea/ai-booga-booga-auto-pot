print("-----------------------------------------")

local Library = loadstring(game:HttpGetAsync("https://github.com/1dontgiveaf/Fluent-Renewed/releases/download/v1.0/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/1dontgiveaf/Fluent-Renewed/refs/heads/main/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/1dontgiveaf/Fluent-Renewed/refs/heads/main/Addons/InterfaceManager.luau"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

--// Все вариации котлов
local potNames = {
    Gold = {
        "Gold Pot",
        "Big Gold Pot", 
        "Mega Gold Pot",
        "Omega Gold Pot",
        "Giant Gold Pot",
        "Super Gold Pot"
    },
    Golden = {
        "Golden Gold Pot",
        "Big Golden Gold Pot",
        "Mega Golden Gold Pot", 
        "Omega Golden Gold Pot",
        "Giant Golden Gold Pot",
        "Super Golden Gold Pot"
    }
}

--// Settings
local settings = {
    selectedType = "Gold",
    selectedSize = "All",
    tweenSpeed = 50,
    maxFarmTime = 10,
    autoFarm = false,
    autoHit = false,
    clickDelay = 0.01,
    hitDistance = 15,
    notifyFound = true
}

local currentTarget = nil
local lastTarget = nil
local currentTween = nil
local farmStartTime = 0

--// Получение списка имен для поиска
local function getTargetNames()
    local names = {}
    local baseNames = settings.selectedType == "Gold" and potNames.Gold or potNames.Golden
    
    if settings.selectedSize == "All" then
        return baseNames
    else
        for _, name in ipairs(baseNames) do
            if settings.selectedSize == "Normal" and name == baseNames[1] then
                table.insert(names, name)
            elseif settings.selectedSize == "Big" and name:find("Big") then
                table.insert(names, name)
            elseif settings.selectedSize == "Mega" and name:find("Mega") then
                table.insert(names, name)
            elseif settings.selectedSize == "Omega" and name:find("Omega") then
                table.insert(names, name)
            end
        end
    end
    return names
end

--// Поиск ближайшего котла
local function findNearestPot()
    local targets = getTargetNames()
    local nearest = nil
    local minDist = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Parent then
            for _, name in ipairs(targets) do
                if obj.Name == name then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part and part:IsDescendantOf(Workspace) then
                        local dist = (rootPart.Position - part.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nearest = obj
                        end
                    end
                end
            end
        end
    end
    return nearest, minDist
end

--// Tween движение к цели
local function tweenToTarget(target)
    if not target then return false end
    
    local targetPart = target:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return false end
    
    -- Останавливаем предыдущий tween
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    
    local distance = (rootPart.Position - targetPart.Position).Magnitude
    local duration = distance / settings.tweenSpeed
    duration = math.min(duration, 10)
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    -- Целевая позиция (рядом с котлом, не внутри)
    local targetPos = targetPart.Position + Vector3.new(0, 0, 6)
    local goal = {CFrame = CFrame.new(targetPos)}
    currentTween = TweenService:Create(rootPart, tweenInfo, goal)
    
    currentTween:Play()
    
    -- Ждем завершения или отмены
    local completed = false
    currentTween.Completed:Connect(function() completed = true end)
    
    while not completed and settings.autoFarm and currentTarget == target do
        task.wait(0.1)
        if tick() - farmStartTime > settings.maxFarmTime then
            if currentTween then currentTween:Cancel() end
            return false
        end
    end
    
    return completed
end

--// Создание окна (как в твоем примере)
local Window = Library:CreateWindow{
    Title = "Pot Farmer Pro",
    SubTitle = "by Sirius Style",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
}

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "menu" }),
    Farming = Window:AddTab({ Title = "Farming", Icon = "sprout" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "axe" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

--// MAIN TAB
Tabs.Main:AddParagraph({
    Title = "Pot Selection",
    Content = "Choose type and size of pots to farm"
})

Tabs.Main:AddDropdown("PotType", {
    Title = "Pot Type",
    Values = {"Gold", "Golden"},
    Multi = false,
    Default = "Gold",
    Callback = function(Value)
        settings.selectedType = Value
    end
})

Tabs.Main:AddDropdown("PotSize", {
    Title = "Size Filter",
    Description = "Select specific size or all",
    Values = {"All", "Normal", "Big", "Mega", "Omega"},
    Multi = false,
    Default = "All",
    Callback = function(Value)
        settings.selectedSize = Value
    end
})

--// FARMING TAB
Tabs.Farming:AddParagraph({
    Title = "Auto Farm Settings",
    Content = "Configure movement and timing"
})

Tabs.Farming:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Description = "Studs per second (10-200)",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        settings.tweenSpeed = Value
    end
})

Tabs.Farming:AddSlider("MaxTime", {
    Title = "Max Farm Time",
    Description = "Seconds per pot before switching",
    Default = 10,
    Min = 3,
    Max = 60,
    Rounding = 0,
    Callback = function(Value)
        settings.maxFarmTime = Value
    end
})

local farmToggle = Tabs.Farming:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Description = "Automatically tween to nearest pot",
    Default = false,
    Callback = function(Value)
        settings.autoFarm = Value
        
        if Value then
            task.spawn(function()
                while settings.autoFarm do
                    -- Проверяем активный tween
                    if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
                        task.wait(0.1)
                        continue
                    end
                    
                    -- Проверяем время на текущем котле
                    if currentTarget and (tick() - farmStartTime) < settings.maxFarmTime then
                        -- Проверяем не убежали ли далеко
                        local part = currentTarget:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local dist = (rootPart.Position - part.Position).Magnitude
                            if dist > 12 then
                                tweenToTarget(currentTarget)
                            end
                        end
                        task.wait(0.2)
                        continue
                    end
                    
                    -- Ищем новую цель
                    local newTarget, distance = findNearestPot()
                    
                    -- Уведомление если нашли новый котел
                    if newTarget and newTarget ~= lastTarget and settings.notifyFound then
                        local sizeText = ""
                        for _, name in ipairs(getTargetNames()) do
                            if newTarget.Name == name then
                                sizeText = name
                                break
                            end
                        end
                        
                        Library:Notify({
                            Title = "New Pot Found!",
                            Content = sizeText .. " | Distance: " .. math.floor(distance) .. " studs",
                            Duration = 3
                        })
                        
                        lastTarget = newTarget
                    end
                    
                    currentTarget = newTarget
                    
                    if currentTarget then
                        farmStartTime = tick()
                        tweenToTarget(currentTarget)
                        
                        -- Стоим рядом пока жив или не истекло время
                        while currentTarget 
                              and currentTarget.Parent 
                              and settings.autoFarm 
                              and (tick() - farmStartTime) < settings.maxFarmTime do
                            
                            local part = currentTarget:FindFirstChildWhichIsA("BasePart")
                            if part then
                                local dist = (rootPart.Position - part.Position).Magnitude
                                if dist > 10 then
                                    tweenToTarget(currentTarget)
                                end
                            end
                            
                            task.wait(0.2)
                        end
                    else
                        if settings.notifyFound then
                            Library:Notify({
                                Title = "No Pots Found",
                                Content = "Searching for " .. settings.selectedType .. " pots...",
                                Duration = 2
                            })
                        end
                        task.wait(1)
                    end
                end
            end)
        else
            if currentTween then currentTween:Cancel() end
            currentTarget = nil
        end
    end
})

Tabs.Farming:AddToggle("NotifyFound", {
    Title = "Notify On Found",
    Description = "Show notification when new pot detected",
    Default = true,
    Callback = function(Value)
        settings.notifyFound = Value
    end
})

--// COMBAT TAB
Tabs.Combat:AddParagraph({
    Title = "Auto Clicker",
    Content = "Spam attack while farming"
})

Tabs.Combat:AddSlider("ClickSpeed", {
    Title = "Click Speed (ms)",
    Description = "Lower = faster attacks",
    Default = 10,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        settings.clickDelay = Value / 1000
    end
})

Tabs.Combat:AddToggle("AutoHit", {
    Title = "Auto Clicker",
    Description = "Spam tool activation and virtual clicks",
    Default = false,
    Callback = function(Value)
        settings.autoHit = Value
        
        if Value then
            task.spawn(function()
                while settings.autoHit do
                    -- Инструмент
                    local tool = character:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function() tool:Activate() end)
                    end
                    
                    -- Виртуальный клик (обход защит)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    
                    -- Proximity prompt если рядом с целью
                    if currentTarget then
                        local part = currentTarget:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local dist = (rootPart.Position - part.Position).Magnitude
                            if dist <= settings.hitDistance then
                                local prompt = currentTarget:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt and fireproximityprompt then
                                    pcall(function() fireproximityprompt(prompt) end)
                                end
                            end
                        end
                    end
                    
                    task.wait(settings.clickDelay)
                end
            end)
        end
    end
})

Tabs.Combat:AddSlider("HitDistance", {
    Title = "Hit Distance",
    Description = "Range for proximity prompts",
    Default = 15,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        settings.hitDistance = Value
    end
})

--// SETTINGS TAB
Tabs.Settings:AddButton({
    Title = "Emergency Stop",
    Description = "Stop all farming and combat",
    Callback = function()
        settings.autoFarm = false
        settings.autoHit = false
        if currentTween then currentTween:Cancel() end
        currentTarget = nil
        farmToggle:SetValue(false)
        
        Library:Notify({
            Title = "Emergency Stop",
            Content = "All functions disabled!",
            Duration = 3
        })
    end
})

--// Character respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    if settings.autoFarm then
        task.wait(1)
        Library:Notify({
            Title = "Character Respawned",
            Content = "Restarting auto farm...",
            Duration = 3
        })
        farmToggle:SetValue(true)
    end
end)

--// Save Manager
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("PotFarmer")
SaveManager:SetFolder("PotFarmer/settings")

SaveManager:BuildConfigSection(Tabs.Settings)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

Library:Notify({
    Title = "Pot Farmer Pro",
    Content = "Script loaded successfully! | Tween movement enabled",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
