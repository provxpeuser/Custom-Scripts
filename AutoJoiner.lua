-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- Settings
local autoHop = true -- Set to true to automatically hop again after teleport

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
Frame.BackgroundColor3 = Color3.fromRGB(15, 0, 30)
Frame.BorderSizePixel = 0
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Parent = ScreenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 15)
frameCorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(170, 85, 255)
UIStroke.Thickness = 2
UIStroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Server Hopper"
Title.TextColor3 = Color3.fromRGB(200, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.Parent = Frame

local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(0.8, 0, 0, 50)
HopButton.Position = UDim2.new(0.1, 0, 0.5, -25)
HopButton.BackgroundColor3 = Color3.fromRGB(120, 0, 255)
HopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HopButton.Font = Enum.Font.GothamBold
HopButton.TextScaled = true
HopButton.Text = "Join Another Server"
HopButton.Parent = Frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = HopButton

-- Server hop function
local function serverHop()
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)

    if success and servers and servers.data then
        for _, server in ipairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                -- Teleport and queue the script to run again in the next server
                if autoHop then
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                else
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                end
                return
            end
        end
    end
    warn("No available servers found!")
end

-- Button click
HopButton.MouseButton1Click:Connect(serverHop)

-- Optional: automatically run the script again after join
-- Using TeleportData to pass autoHop flag
if autoHop then
    TeleportService:Teleport(placeId, player, nil, {autoHop = true})
end
