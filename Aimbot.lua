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

--// STATE
local espEnabled = true
local aimbotEnabled = false
local aimbotActive = false
local triggerBotEnabled = false
local flyEnabled = false

local currentTarget
local cameraConn, flyConn
local tagMap = {}
local espReloadConn

--// GUI STATE
local mainGui
local uiVisible = true

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

    removeNametag(player)

    local gui = Instance.new("BillboardGui")
    gui.Name = "_MelrahESP"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 150, 0, 34)
    gui.StudsOffset = Vector3.new(0, 2.6, 0)
    gui.AlwaysOnTop = true

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = BLACK
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = PURPLE
    stroke.Thickness = 1.5

    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, -6, 1, -6)
    text.Position = UDim2.new(0, 3, 0, 3)
    text.BackgroundTransparency = 1
    text.Text = player.Name
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.TextColor3 = PURPLE
    text.TextStrokeTransparency = 0

    gui.Parent = head
    tagMap[player] = gui
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

local function startESPReload()
    if espReloadConn then espReloadConn:Disconnect() end
    espReloadConn = RunService.Heartbeat:Connect(function(dt)
        if tick() % 1 < dt and espEnabled then
            refreshESP()
        end
    end)
end

--// ================= AIMBOT =================

local function angleToCamera(pos)
    local dir = (pos - Camera.CFrame.Position).Unit
    return math.acos(Camera.CFrame.LookVector:Dot(dir))
end

local function findTarget()
    local best, bestScore = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local dist = (head.Position - Camera.CFrame.Position).Magnitude
                if dist <= MAX_LOCK_DIST then
                    local ang = angleToCamera(head.Position)
                    if ang <= math.rad(AIMBOT_FOV / 2) then
                        local score = ang + dist / 10000
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

local function startAimbot(target)
    if cameraConn then cameraConn:Disconnect() end
    cameraConn = RunService.RenderStepped:Connect(function()
        if not aimbotActive or not target.Character then return end
        local head = target.Character:FindFirstChild("Head")
        if not head then return end
        local goal = CFrame.new(Camera.CFrame.Position, head.Position)
        Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(1 - SMOOTHNESS / 200, 0.05, 0.9))
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
    mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame", mainGui)
    panel.Size = UDim2.new(0, 520, 0, 80)
    panel.Position = UDim2.new(0.5, -260, 0, 20)
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.BackgroundColor3 = BLACK
    panel.BorderSizePixel = 0
    panel.ZIndex = 999
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = PURPLE
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "💜 MELRAH AIMBOT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.TextColor3 = PURPLE
    title.ZIndex = 1000

    local function button(text, x)
        local b = Instance.new("TextButton", panel)
        b.Size = UDim2.new(0, 90, 0, 32)
        b.Position = UDim2.new(0, x, 1, 8)
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = DARK_PURPLE
        b.BorderSizePixel = 0
        b.ZIndex = 1001
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local espBtn = button("ESP : ON", 20)
    local aimBtn = button("AIM : OFF", 120)

    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        espBtn.Text = espEnabled and "ESP : ON" or "ESP : OFF"
        refreshESP()
    end)

    aimBtn.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimBtn.Text = aimbotEnabled and "AIM : ON (Q)" or "AIM : OFF"
        stopAimbot()
    end)
end

--// ================= INPUT =================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        mainGui.Enabled = uiVisible
    end

    if input.KeyCode == Enum.KeyCode.Q and aimbotEnabled then
        aimbotActive = true
        currentTarget = findTarget()
        if currentTarget then
            startAimbot(currentTarget)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        aimbotActive = false
        stopAimbot()
    end
end)

--// ================= INIT =================

makeGui()
refreshESP()
startESPReload()

Players.PlayerAdded:Connect(refreshESP)
Players.PlayerRemoving:Connect(removeNametag)

print("💜 melrah aimbot loaded | Q = Aim | RightControl = Toggle UI")
