-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

-- PLAYER
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- SETTINGS
local HITBOX_SIZE = Vector3.new(12,12,12)
local NORMAL_SPEED = 16
local BOOSTED_SPEED = NORMAL_SPEED * 10
local PURPLE = Color3.fromRGB(170,120,255)

-- STATES
local hitboxEnabled = false
local speedEnabled = false
local infiniteJump = false
local expanded = {}
local connections = {}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MelrahUniversalGUI"
gui.Parent = player.PlayerGui
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(380, 330)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(15,15,22)
main.BorderSizePixel = 0
main.ZIndex = 10

Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

-- TITLE
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.fromOffset(10, 8)
title.Text = "Melrah Universal"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 11

-- BUTTON CREATOR
local function makeButton(text, y, danger)
	local btn = Instance.new("TextButton", main)
	btn.Size = UDim2.new(1, -40, 0, 46)
	btn.Position = UDim2.fromOffset(20, y)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 17
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = danger and Color3.fromRGB(120,30,30) or Color3.fromRGB(35,35,45)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.ZIndex = 11

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = 2
	stroke.Color = danger and Color3.fromRGB(200,60,60) or Color3.fromRGB(90,90,120)

	return btn, stroke
end

-- BUTTONS
local hitboxBtn, hitboxStroke = makeButton("Hitboxes: OFF", 60)
local speedBtn, speedStroke   = makeButton("Speed 10×: OFF", 115)
local jumpBtn, jumpStroke     = makeButton("Infinite Jump: OFF", 170)
local ejectBtn                = makeButton("UNINJECT", 235, true)

-- TOGGLE STYLE
local function setToggle(btn, stroke, on)
	btn.BackgroundColor3 = on and Color3.fromRGB(70,40,120) or Color3.fromRGB(35,35,45)
	stroke.Color = on and PURPLE or Color3.fromRGB(90,90,120)
end

-- NAME TAG
local function attachNameTag(character, name)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or hrp:FindFirstChild("MelrahTag") then return end

	local tag = Instance.new("BillboardGui")
	tag.Name = "MelrahTag"
	tag.Adornee = hrp
	tag.Size = UDim2.fromScale(6,1.2)
	tag.StudsOffset = Vector3.new(0,4,0)
	tag.AlwaysOnTop = true

	local txt = Instance.new("TextLabel", tag)
	txt.Size = UDim2.fromScale(1,1)
	txt.BackgroundTransparency = 1
	txt.Text = name
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true
	txt.TextColor3 = PURPLE
	txt.TextStrokeColor3 = Color3.new(0,0,0)
	txt.TextStrokeTransparency = 0

	tag.Parent = hrp
end

local function removeNameTags()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local tag = hrp:FindFirstChild("MelrahTag")
				if tag then tag:Destroy() end
			end
		end
	end
end

-- HITBOX APPLY / REMOVE
local function applyHitbox(plr)
	if plr == player or expanded[plr] or not plr.Character then return end
	local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	expanded[plr] = true
	hrp.Size = HITBOX_SIZE
	hrp.Material = Enum.Material.Neon
	hrp.Color = PURPLE
	hrp.Transparency = 0.35
	hrp.CanCollide = false

	attachNameTag(plr.Character, plr.Name)
end

local function removeHitbox(plr)
	expanded[plr] = nil
	if not plr.Character then return end
	local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Size = Vector3.new(2,2,1)
		hrp.Transparency = 1
		hrp.Material = Enum.Material.Plastic
	end
end

-- BUTTON LOGIC
hitboxBtn.MouseButton1Click:Connect(function()
	hitboxEnabled = not hitboxEnabled
	hitboxBtn.Text = hitboxEnabled and "Hitboxes: ON" or "Hitboxes: OFF"
	setToggle(hitboxBtn, hitboxStroke, hitboxEnabled)

	if hitboxEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			applyHitbox(p)
		end
	else
		for p in pairs(expanded) do
			removeHitbox(p)
		end
		removeNameTags()
	end
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	humanoid.WalkSpeed = speedEnabled and BOOSTED_SPEED or NORMAL_SPEED
	speedBtn.Text = speedEnabled and "Speed 10×: ON" or "Speed 10×: OFF"
	setToggle(speedBtn, speedStroke, speedEnabled)
end)

jumpBtn.MouseButton1Click:Connect(function()
	infiniteJump = not infiniteJump
	jumpBtn.Text = infiniteJump and "Infinite Jump: ON" or "Infinite Jump: OFF"
	setToggle(jumpBtn, jumpStroke, infiniteJump)
end)

-- INFINITE JUMP
connections.jump = UIS.JumpRequest:Connect(function()
	if infiniteJump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- NEW PLAYERS / RESPAWNS
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.3)
		if hitboxEnabled then applyHitbox(plr) end
	end)
end)

-- RIGHT SHIFT GUI TOGGLE + FREE CURSOR
connections.shift = UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
		UIS.MouseBehavior = main.Visible and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	end
end)

-- UNINJECT
ejectBtn.MouseButton1Click:Connect(function()
	hitboxEnabled = false
	speedEnabled = false
	infiniteJump = false

	humanoid.WalkSpeed = NORMAL_SPEED
	removeNameTags()
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter

	for _, c in pairs(connections) do
		if c then c:Disconnect() end
	end

	gui:Destroy()
end)
