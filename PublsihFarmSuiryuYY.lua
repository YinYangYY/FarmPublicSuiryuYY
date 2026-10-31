--[[
    "Testing" + "Testing 2" Script
    Testing: Teleport behind 1 random player, weld + smoothly follow.
    Testing 2: Cycle 5 players, then teleport -70 studs DOWN for 5 seconds.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local weldedTarget = nil
local followConnection = nil
local cycleToken = 0

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("TestingGui")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestingGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function makeButton(name, text, yOffset, accentColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 160, 0, 50)
    btn.Position = UDim2.new(0, 20, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = true
    btn.BorderSizePixel = 0
    btn.Parent = screenGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = accentColor
    s.Thickness = 2
    s.Parent = btn

    return btn
end

local button1 = makeButton("TestingButton", "Testing", 20, Color3.fromRGB(200, 0, 0))
local button2 = makeButton("Testing2Button", "Testing 2", 80, Color3.fromRGB(0, 100, 255))

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function getRandomOtherPlayer()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, plr)
        end
    end
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function getHRP(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild("HumanoidRootPart")
end

local function teleportBehind(targetPlr)
    local targetHRP = getHRP(targetPlr)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP or not myHRP then return end
    
    -- Teleport exactly 2 studs behind and face them
    local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 2)
    myHRP.CFrame = CFrame.lookAt(behindPos.Position, targetHRP.Position)
end

local function unweld()
    weldedTarget = nil
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
end

local function startFollow(targetPlr)
    unweld()
    weldedTarget = targetPlr

    followConnection = RunService.Heartbeat:Connect(function(dt)
        if not enabled or weldedTarget ~= targetPlr then return end

        local targetHRP = getHRP(targetPlr)
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end

        local desiredPos = targetHRP.CFrame * CFrame.new(0, 0, 2)
        
        local currentPos = myHRP.Position
        local newPos = currentPos:Lerp(desiredPos.Position, 0.5)
        myHRP.CFrame = CFrame.lookAt(newPos, targetHRP.Position)
    end)
end

----------------------------------------------------------------
-- Reset Button Visuals
----------------------------------------------------------------
local function resetButtons()
    button1.Text = "Testing"
    button1.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button2.Text = "Testing 2"
    button2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end

local function disableAll()
    enabled = false
    cycleToken = cycleToken + 1
    resetButtons()
    unweld()
end

----------------------------------------------------------------
-- Testing 1
----------------------------------------------------------------
local function enableSingle()
    enabled = true
    cycleToken = cycleToken + 1

    resetButtons()
    button1.Text = "Testing [ON]"
    button1.BackgroundColor3 = Color3.fromRGB(0, 150, 0)

    local target = getRandomOtherPlayer()
    if target then
        teleportBehind(target)
        startFollow(target)
    end
end

----------------------------------------------------------------
-- Testing 2 (Cycle 5 -> -70 Down for 5s -> Return)
----------------------------------------------------------------
local function getNOtherPlayers(n)
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, plr)
        end
    end
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    local out = {}
    for i = 1, math.min(n, #list) do out[i] = list[i] end
    return out
end

local function enableCycle()
    enabled = true
    cycleToken = cycleToken + 1
    local myToken = cycleToken

    resetButtons()
    button2.Text = "Testing 2 [ON]"
    button2.BackgroundColor3 = Color3.fromRGB(0, 100, 220)

    task.spawn(function()
        local targets = getNOtherPlayers(5)
        if #targets == 0 then
            if myToken == cycleToken then disableAll() end
            return
        end

        -- 1. Cycle 5 players
        for i, target in ipairs(targets) do
            if myToken ~= cycleToken or not enabled then return end
            local hrp = getHRP(target)
            if hrp then
                teleportBehind(target)
                startFollow(target)
                task.wait(0.5)
            end
        end

        -- 2. Drop -70 studs for 5 seconds
        if myToken == cycleToken and enabled then
            local last = targets[#targets]
            if last and getHRP(last) then
                teleportBehind(last)
                startFollow(last)
            end

            task.wait(0.2)
            
            local char = LocalPlayer.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if myHRP and hum then
                unweld() -- Stop following
                
                local safePos = myHRP.CFrame
                
                -- Freeze and Anchor to stop the snap-back
                hum.PlatformStand = true
                myHRP.Anchored = true
                
                -- Teleport 70 studs down
                myHRP.CFrame = safePos * CFrame.new(0, -70, 0)
                
                -- Wait 5 seconds
                task.wait(5.0)
                
                -- Teleport back and unfreeze
                myHRP.CFrame = safePos
                myHRP.Anchored = false
                hum.PlatformStand = false
            end
        end
    end)
end

----------------------------------------------------------------
-- Connections
----------------------------------------------------------------
button1.MouseButton1Click:Connect(function()
    if enabled and button1.Text == "Testing [ON]" then 
        disableAll() 
    else 
        disableAll()
        enableSingle() 
    end
end)

button2.MouseButton1Click:Connect(function()
    if enabled and button2.Text == "Testing 2 [ON]" then 
        disableAll() 
    else 
        disableAll()
        enableCycle() 
    end
end)

RunService.Heartbeat:Connect(function()
    if not enabled then return end
    if not weldedTarget then return end
    local hrp = getHRP(weldedTarget)
    if not hrp then
        local newTarget = getRandomOtherPlayer()
        if newTarget then
            teleportBehind(newTarget)
            startFollow(newTarget)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if enabled then
        unweld()
        task.wait(0.5)
    end
end)
