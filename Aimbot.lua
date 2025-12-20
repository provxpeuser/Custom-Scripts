--// ================= GUI (UPSIDE RECTANGLE, OVER EVERYTHING) =================

local function makeGui()
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "melrah_aimbot"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- Important: over everything
    mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame", mainGui)
    panel.Size = UDim2.new(0, 520, 0, 80)
    panel.Position = UDim2.new(0.5, -260, 0, 20)
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.BackgroundColor3 = BLACK
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)
    panel.ZIndex = 999 -- Make sure panel is on top

    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = PURPLE
    stroke.Thickness = 2
    stroke.ZIndex = 1000

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "💜 MELRAH AIMBOT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.TextColor3 = PURPLE
    title.ZIndex = 1001

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
        b.ZIndex = 1002
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
