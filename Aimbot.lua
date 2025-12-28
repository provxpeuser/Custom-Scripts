--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// THEME
local PURPLE = Color3.fromRGB(170, 80, 255)
local DARK_PURPLE = Color3.fromRGB(90, 40, 140)
local BLACK = Color3.fromRGB(10, 10, 15)

--// SETTINGS
local MAX_LOCK_DIST = 1000
local AIMBOT_FOV = 70
local SMOOTHNESS = 30
local TARGET_COOLDOWN = 2

--// KEYBINDS
local AIMBOT_KEY = Enum.KeyCode.Q
local UI_TOGGLE_KEY = Enum.KeyCode.RightControl

--// STATE
local espEnabled = true
local aimbotEnabled = true
local aimbotActive = false
local ignoreTeam = true

local currentTarget = nil
local lastTargetTime = {}
local cameraConn
local tagMap = {}
local uiVisible = true
local listeningForKey = nil
local mainGui

--// ================= UTILS =================

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function onCooldown(player)
    local t = lastTargetTime[player]
    return t and (tick() - t < TARGET_COOLDOWN)
end

--// ================= ESP =================

local function removeNametag(player)
    if tagMap[player] then
        tagMap[player]:Destroy()
        tagMap[player] = nil
    end
end

local function createNametag(player)
    if not espEnabled then
        removeNametag(player)
        return
    end

    if player == LocalPlayer then return end
    if not player.Character or not isAlive(player.Character) then
        removeNametag(player)
        return
    end
    if ignoreTeam and player.Team == LocalPlayer.Team then
        removeNametag(player)
        return
    end

    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    removeNametag(player)

    local gui = Instance.new("BillboardGui")
    gui.Adornee = head
    gui.Size = UDim2.new(0,160,0,36)
    gui.StudsOffset = Vector3.new(0,2.7,0)
    gui.AlwaysOnTop = true

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.fromScale(1,1)
    frame.BackgroundColor3 = BLACK
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = PURPLE
    stroke.Thickness = 1.5

    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1,-8,1,-8)
    txt.Position = UDim2.new(0,4,0,4)
    txt.BackgroundTransparency = 1
    txt.TextScaled = true
    txt.Font = Enum.Font.GothamBold
    txt.TextColor3 = PURPLE
    txt.Text = player.DisplayName ~= "" and player.DisplayName or player.Name

    gui.Parent = head
    tagMap[player] = gui
end

local function refreshESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if espEnabled then
            createNametag(p)
        else
            removeNametag(p)
        end
    end
end

task.spawn(function()
    while true do
        refreshESP()
        task.wait(1)
    end
end)

--// ================= AIMBOT =================

local function findTarget()
    local best, bestScore = nil, math.huge

    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if ignoreTeam and p.Team == LocalPlayer.Team then continue end
            if not isAlive(p.Character) then continue end
            if onCooldown(p) then continue end

            local head = p.Character:FindFirstChild("Head")
            if head then
                local dir = (head.Position - Camera.CFrame.Position)
                local dist = dir.Magnitude
                if dist <= MAX_LOCK_DIST then
                    local angle = math.acos(Camera.CFrame.LookVector:Dot(dir.Unit))
                    if angle <= math.rad(AIMBOT_FOV/2) then
                        local score = angle + dist/10000
                        if score < bestScore then
                            bestScore = score
                            best = p
                        end
                    end
                end
            end
        end
    end
    return best
end

local function startAimbot()
    if cameraConn then cameraConn:Disconnect() end
    cameraConn = RunService.RenderStepped:Connect(function()
        if not aimbotActive then return end

        if not currentTarget
        or not currentTarget.Character
        or not isAlive(currentTarget.Character) then

            if currentTarget then
                lastTargetTime[currentTarget] = tick()
                currentTarget = nil
            end

            currentTarget = findTarget()
            return
        end

        local head = currentTarget.Character:FindFirstChild("Head")
        if not head then return end

        Camera.CFrame = Camera.CFrame:Lerp(
            CFrame.new(Camera.CFrame.Position, head.Position),
            math.clamp(1 - SMOOTHNESS/200, 0.05, 0.9)
        )
    end)
end

local function stopAimbot()
    if cameraConn then cameraConn:Disconnect() end
end

--// ================= GUI =================

local function makeGui()
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "melrah_aimbot"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    mainGui.DisplayOrder = 999999

    if syn and syn.protect_gui then
        syn.protect_gui(mainGui)
    end

    mainGui.Parent = CoreGui

    local panel = Instance.new("Frame", mainGui)
    panel.Size = UDim2.new(0,780,0,90)
    panel.Position = UDim2.new(0.5,-390,0,20)
    panel.AnchorPoint = Vector2.new(0.5,0)
    panel.BackgroundColor3 = BLACK
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0,20)

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1,0,0.5,0)
    title.BackgroundTransparency = 1
    title.Text = "💜 MELRAH AIMBOT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26
    title.TextColor3 = PURPLE

    local function btn(text,x)
        local b = Instance.new("TextButton", panel)
        b.Size = UDim2.new(0,130,0,32)
        b.Position = UDim2.new(0,x,0.6,0)
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = DARK_PURPLE
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        return b
    end

    local aimBtn  = btn("AIM : ON",20)
    local espBtn  = btn("ESP : ON",160)
    local teamBtn = btn("IGNORE TEAM : ON",300)
    local bindAim = btn("AIM KEY",460)
    local bindUI  = btn("UI KEY",610)

    aimBtn.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimBtn.Text = aimbotEnabled and "AIM : ON" or "AIM : OFF"
    end)

    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        espBtn.Text = espEnabled and "ESP : ON" or "ESP : OFF"
        refreshESP()
    end)

    teamBtn.MouseButton1Click:Connect(function()
        ignoreTeam = not ignoreTeam
        teamBtn.Text = ignoreTeam and "IGNORE TEAM : ON" or "IGNORE TEAM : OFF"
    end)

    bindAim.MouseButton1Click:Connect(function()
        bindAim.Text = "PRESS KEY..."
        listeningForKey = "AIM"
    end)

    bindUI.MouseButton1Click:Connect(function()
        bindUI.Text = "PRESS KEY..."
        listeningForKey = "UI"
    end)

    task.spawn(function()
        while task.wait(0.4) do
            bindAim.Text = "AIM KEY: "..AIMBOT_KEY.Name
            bindUI.Text = "UI KEY: "..UI_TOGGLE_KEY.Name
        end
    end)
end

--// ================= INPUT =================

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end

    if listeningForKey then
        if listeningForKey == "AIM" then AIMBOT_KEY = input.KeyCode end
        if listeningForKey == "UI" then UI_TOGGLE_KEY = input.KeyCode end
        listeningForKey = nil
        return
    end

    if input.KeyCode == UI_TOGGLE_KEY then
        uiVisible = not uiVisible
        mainGui.Enabled = uiVisible
    end

    if input.KeyCode == AIMBOT_KEY and aimbotEnabled then
        aimbotActive = true
        startAimbot()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AIMBOT_KEY then
        aimbotActive = false
        currentTarget = nil
        stopAimbot()
    end
end)

--// INIT
makeGui()
refreshESP()

print("💜 Melrah Aimbot loaded | ESP toggle added")
