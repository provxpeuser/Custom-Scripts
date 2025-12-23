--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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

--// KEYBINDS (CHANGEABLE)
local AIMBOT_KEY = Enum.KeyCode.Q
local UI_TOGGLE_KEY = Enum.KeyCode.RightControl

--// STATE
local espEnabled = true
local aimbotEnabled = false
local aimbotActive = false

local currentTarget
local cameraConn
local tagMap = {}
local mainGui
local uiVisible = true
local listeningForKey = nil

--// ================= ESP =================

local function removeNametag(player)
    if tagMap[player] then
        tagMap[player]:Destroy()
        tagMap[player] = nil
    end
end

local function createNametag(player)
    if player == LocalPlayer then return end
    if not player.Character then return end

    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    -- Always rebuild safely
    removeNametag(player)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "_MelrahESP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 160, 0, 36)
    billboard.StudsOffset = Vector3.new(0, 2.7, 0)
    billboard.AlwaysOnTop = true

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = BLACK
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = PURPLE
    stroke.Thickness = 1.5

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(1, -8, 1, -8)
    nameLabel.Position = UDim2.new(0, 4, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = PURPLE
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Text = player.DisplayName ~= "" and player.DisplayName or player.Name

    billboard.Parent = head
    tagMap[player] = billboard
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if espEnabled then
            createNametag(p)
        else
            removeNametag(p)
        end
    end
end

-- Reload ESP every 1 second
RunService.Heartbeat:Connect(function(dt)
    if tick() % 1 < dt and espEnabled then
        refreshESP()
    end
end)

--// ================= AIMBOT =================

local function findTarget()
    local best, score = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local dist = (head.Position - Camera.CFrame.Position).Magnitude
                if dist <= MAX_LOCK_DIST then
                    local ang = math.acos(Camera.CFrame.LookVector:Dot(
                        (head.Position - Camera.CFrame.Position).Unit
                    ))
                    if ang <= math.rad(AIMBOT_FOV / 2) then
                        local s = ang + dist / 10000
                        if s < score then
                            score = s
                            best = p
                        end
                    end
                end
            end
        end
    end
    return best
end

local function startAimbot(target)
    if cameraConn then cameraConn:Disconnect() end
    cameraConn = RunService.RenderStepped:Connect(function()
        if not aimbotActive or not target.Character then return end
        local head = target.Character:FindFirstChild("Head")
        if not head then return end
        Camera.CFrame = Camera.CFrame:Lerp(
            CFrame.new(Camera.CFrame.Position, head.Position),
            math.clamp(1 - SMOOTHNESS / 200, 0.05, 0.9)
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
    mainGui.Parent = LocalPlayer.PlayerGui

    local panel = Instance.new("Frame", mainGui)
    panel.Size = UDim2.new(0, 600, 0, 80)
    panel.Position = UDim2.new(0.5, -300, 0, 20)
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.BackgroundColor3 = BLACK
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "💜 MELRAH AIMBOT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.TextColor3 = PURPLE

    local function button(text, x)
        local b = Instance.new("TextButton", panel)
        b.Size = UDim2.new(0, 130, 0, 32)
        b.Position = UDim2.new(0, x, 1, 8)
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = DARK_PURPLE
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local aimBtn = button("AIM : OFF", 20)
    local bindAim = button("AIM KEY", 170)
    local bindUI = button("UI KEY", 330)

    aimBtn.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimBtn.Text = aimbotEnabled and "AIM : ON" or "AIM : OFF"
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
        while task.wait(0.5) do
            bindAim.Text = "AIM KEY: "..AIMBOT_KEY.Name
            bindUI.Text = "UI KEY: "..UI_TOGGLE_KEY.Name
        end
    end)
end

--// ================= INPUT =================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if listeningForKey then
        if listeningForKey == "AIM" then
            AIMBOT_KEY = input.KeyCode
        elseif listeningForKey == "UI" then
            UI_TOGGLE_KEY = input.KeyCode
        end
        listeningForKey = nil
        return
    end

    if input.KeyCode == UI_TOGGLE_KEY then
        uiVisible = not uiVisible
        mainGui.Enabled = uiVisible
    end

    if input.KeyCode == AIMBOT_KEY and aimbotEnabled then
        aimbotActive = true
        currentTarget = findTarget()
        if currentTarget then startAimbot(currentTarget) end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AIMBOT_KEY then
        aimbotActive = false
        stopAimbot()
    end
end)

--// INIT
makeGui()
refreshESP()

Players.PlayerAdded:Connect(refreshESP)
Players.PlayerRemoving:Connect(removeNametag)

print("💜 melrah aimbot loaded | name-fixed ESP")
