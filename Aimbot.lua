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

local currentTarget = nil
local cameraConn, flyConn
local tagMap = {}

--// GUI STATE
local mainGui
local uiVisible = true

--// ================= ESP (PURPLE + BLACK NAMETAG) =================

local function createNametag(player)
    if player == LocalPlayer then return end
    if not player.Character or tagMap[player] then return end

    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "_MelrahTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 140, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.AlwaysOnTop = true

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = BLACK
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = PURPLE
    stroke.Thickness = 1.5

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -6, 1, -6)
    label.Position = UDim2.new(0, 3, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = PURPLE
    label.TextStrokeTransparency = 0

    billboard.Parent = head
    tagMap[player] = billboard
end

local function removeNametag(player)
    if tagMap[player] then
        tagMap[player]:Destroy()
        tagMap[player] = nil
    end
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
        local alpha = math.clamp(1 - SMOOTHNESS / 200, 0.05, 0.9)
        Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)

        if triggerBotEnabled then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end)
end

local function stopAimbot()
    if cameraConn then cameraConn:Disconnect() end
end

--// ================= FLY =================

local function startFly()
    if flyConn then flyConn:Disconnect() end
    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true

    flyConn = RunService.RenderStepped:Connect(function()
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end

        if dir.Magnitude > 0 then
            root.AssemblyLinearVelocity = dir.Unit * 50
        end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

--// ================= GUI (UPSIDE RECTANGLE) =================

local function makeGui()
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "melrah_aimbot"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = LocalPlayer.PlayerGui

    local panel = Instance.new("Frame", mainGui)
    panel.Size = UDim2.new(0, 520, 0, 80)
    panel.Position = UDim2.new(0.5, -260, 0, 20)
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.BackgroundColor3 = BLACK
    panel.BorderSizePixel = 0
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

    local function button(text, x)
        local b = Instance.new("TextButton", panel)
        b.Size = UDim2.new(0, 90, 0, 32)
        b.Position = UDim2.new(0, x, 1, 8)
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = DARK_PURPLE
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local espBtn = button("ESP : ON", 20)
    local aimBtn = button("AIM : OFF", 120)
    local trigBtn = button("TRIGGER : OFF", 220)
    local flyBtn = button("FLY : OFF", 340)

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

    trigBtn.MouseButton1Click:Connect(function()
        triggerBotEnabled = not triggerBotEnabled
        trigBtn.Text = triggerBotEnabled and "TRIGGER : ON" or "TRIGGER : OFF"
    end)

    flyBtn.MouseButton1Click:Connect(function()
        flyEnabled = not flyEnabled
        flyBtn.Text = flyEnabled and "FLY : ON" or "FLY : OFF"
        if flyEnabled then startFly() else stopFly() end
    end)
end

--// ================= INPUT =================

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    -- Toggle UI
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        if mainGui then
            mainGui.Enabled = uiVisible
        end
    end

    -- Aimbot hold
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

Players.PlayerAdded:Connect(refreshESP)
Players.PlayerRemoving:Connect(removeNametag)

print("💜 melrah aimbot loaded | Q = Aim | RightControl = Toggle UI")
