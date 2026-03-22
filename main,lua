local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

--// Таблицы с именами всех вариаций
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
    selectedType = "Gold", -- "Gold" или "Golden"
    selectedSize = "All",  -- "All", "Normal", "Big", "Mega", "Omega"
    speed = 50,
    autoFarm = false,
    autoHit = false,
    clickMode = "Tool", -- "Tool" (только инструмент) или "Screen" (клик по экрану)
    clickDelay = 0.01   -- задержка между кликами (меньше = быстрее)
}

local currentTarget = nil
local hitConnection = nil

--// Функция получения списка имен для поиска
local function getTargetNames()
    local names = {}
    local baseNames = settings.selectedType == "Gold" and potNames.Gold or potNames.Golden
    
    if settings.selectedSize == "All" then
        return baseNames
    else
        -- Ищем конкретный размер
        for _, name in ipairs(baseNames) do
            if settings.selectedSize == "Normal" and not name:find("Big") and not name:find("Mega") and not name:find("Omega") and not name:find("Giant") and not name:find("Super") then
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

--// UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PotFarmer"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then screenGui.Parent = player.PlayerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 450)
main.Position = UDim2.new(0.5, -160, 0.5, -225)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ POT FARMER PRO"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.Parent = header
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function()
    settings.autoFarm = false
    settings.autoHit = false
    if hitConnection then hitConnection:Disconnect() end
    screenGui:Destroy()
end)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 45)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.new(0, 0, 0, 500)
content.Parent = main

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.Parent = content

--// Хелперы UI
local function addSection(txt)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = content
end

local function createBtn(txt, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = color
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        callback()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 100)}):Play()
        wait(0.2)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    return btn
end

local function createToggle(txt, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 24)
    btn.Position = UDim2.new(1, -60, 0.5, -12)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local enabled = default
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        callback(enabled)
        btn.Text = enabled and "ON" or "OFF"
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    end)
end

local function createSlider(txt, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.Parent = frame
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -20, 0, 8)
    bg.Position = UDim2.new(0, 10, 0, 28)
    bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bg.BorderSizePixel = 0
    bg.Parent = frame
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function upd(input)
        local x = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * x)
        fill.Size = UDim2.new(x, 0, 1, 0)
        lbl.Text = txt .. ": " .. val
        callback(val)
    end
    
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true upd(i) end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

--// UI Элементы
addSection("ТИП КОТЛА")

createBtn("🥇 Gold Pot Series", Color3.fromRGB(255, 215, 0), function()
    settings.selectedType = "Gold"
end).TextColor3 = Color3.fromRGB(0,0,0)

createBtn("👑 Golden Pot Series", Color3.fromRGB(184, 134, 11), function()
    settings.selectedType = "Golden"
end)

addSection("РАЗМЕР (ВСЕ ВАРИАЦИИ)")

local sizes = {"All", "Normal", "Big", "Mega", "Omega"}
for i, size in ipairs(sizes) do
    createBtn(size, Color3.fromRGB(60, 60, 60), function()
        settings.selectedSize = size
    end)
end

addSection("НАСТРОЙКИ")

createSlider("Скорость движения", 16, 150, 50, function(v)
    settings.speed = v
    if humanoid then humanoid.WalkSpeed = v end
end)

createSlider("Скорость клика (мс)", 1, 100, 10, function(v)
    settings.clickDelay = v / 1000  -- конвертируем в секунды
end)

addSection("ФУНКЦИИ")

createToggle("🤖 Auto Farm (Идти)", false, function(v)
    settings.autoFarm = v
    if v then
        task.spawn(function()
            while settings.autoFarm do
                local targets = getTargetNames()
                local nearest = nil
                local minDist = math.huge
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") then
                        for _, name in ipairs(targets) do
                            if obj.Name == name then
                                local part = obj:FindFirstChildWhichIsA("BasePart")
                                if part then
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
                
                currentTarget = nearest
                
                if currentTarget then
                    local part = currentTarget:FindFirstChildWhichIsA("BasePart")
                    if part then
                        humanoid.WalkSpeed = settings.speed
                        local path = PathfindingService:CreatePath({
                            AgentRadius = 2,
                            AgentHeight = 5,
                            AgentCanJump = true
                        })
                        pcall(function() path:ComputeAsync(rootPart.Position, part.Position) end)
                        
                        if path.Status == Enum.PathStatus.Success then
                            for _, wp in ipairs(path:GetWaypoints()) do
                                if not settings.autoFarm then break end
                                humanoid:MoveTo(wp.Position)
                                humanoid.MoveToFinished:Wait()
                            end
                        else
                            humanoid:MoveTo(part.Position)
                            humanoid.MoveToFinished:Wait()
                        end
                        
                        while currentTarget and currentTarget.Parent and settings.autoFarm do
                            task.wait(0.1)
                        end
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    else
        currentTarget = nil
    end
end)

--// АВТО-КЛИКЕР (Работает всегда, не зависит от цели)
createToggle("⚔️ Auto Clicker (RAGE)", false, function(v)
    settings.autoHit = v
    if v then
        task.spawn(function()
            while settings.autoHit do
                -- Способ 1: Через инструмент
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function()
                        tool:Activate()
                        if tool.Grip then end -- триггер активности
                    end)
                end
                
                -- Способ 2: Виртуальный клик по центру экрана (обходит многие защиты)
                if settings.clickMode == "Screen" then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
                
                -- Способ 3: ProximityPrompt (если есть)
                if currentTarget then
                    local prompt = currentTarget:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                end
                
                task.wait(settings.clickDelay)
            end
        end)
    end
end)

createToggle("🖱️ Screen Click Mode", false, function(v)
    settings.clickMode = v and "Screen" or "Tool"
end)

createSlider("Дистанция видимости", 5, 50, 20, function(v)
    -- для информации, не используется в кликере
end)

--// Обновление персонажа
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
end)

print("Pot Farmer Pro Loaded!")
