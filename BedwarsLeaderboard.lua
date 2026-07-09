-- =============================================
--  BedWars Hypixel-Style Leaderboard Script
--  Mimics the Hypixel BedWars scoreboard UI
--  Works with Easy.gg Roblox BedWars
-- =============================================

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =============================================
-- CONFIG
-- =============================================
local CONFIG = {
    TITLE         = "BED WARS",
    WEBSITE       = "easy.gg",
    UPDATE_RATE   = 0.5,   -- seconds between updates
    WIDTH         = 210,   -- px width of the board
    BG_ALPHA      = 0.55,  -- background transparency
}

-- Team color map: team name -> RGB color for the letter prefix
local TEAM_COLORS = {
    Red      = Color3.fromRGB(255, 80,  80),
    Blue     = Color3.fromRGB(85,  150, 255),
    Green    = Color3.fromRGB(80,  220, 80),
    Yellow   = Color3.fromRGB(255, 255, 80),
    Aqua     = Color3.fromRGB(80,  255, 230),
    White    = Color3.fromRGB(240, 240, 240),
    Pink     = Color3.fromRGB(255, 120, 200),
    Gray     = Color3.fromRGB(160, 160, 160),
    Orange   = Color3.fromRGB(255, 165, 65),
    Purple   = Color3.fromRGB(180, 80,  255),
}

-- Team name -> single letter prefix (Hypixel style)
local TEAM_LETTERS = {
    Red = "R", Blue = "B", Green = "G", Yellow = "Y",
    Aqua = "A", White = "W", Pink = "P", Gray = "S",
    Orange = "O", Purple = "U",
}

-- =============================================
-- HELPERS
-- =============================================

local function getMapName()
    local sp = workspace:FindFirstChild("SpectatorPlatform")
    if sp then
        local label = sp:FindFirstChild("MapName", true)
        if label and label.ClassName == "TextLabel" then
            return label.Text
        end
    end
    return "Unknown"
end

local function getDiamondTimer()
    for _, part in pairs(workspace:GetChildren()) do
        if part.Name == "GeneratorAdornee" then
            local roact = part:FindFirstChild("RoactTree")
            if roact then
                local countdown = roact:FindFirstChild("Countdown", true)
                local tierLabel  = roact:FindFirstChild("GenTier", true)
                if countdown then
                    local secs = countdown.Text:match("%[(%d+)%]")
                    local tierText = tierLabel and tierLabel.Text or ""
                    if secs then
                        local s    = tonumber(secs) or 0
                        local mins = math.floor(s / 60)
                        local rem  = s % 60
                        return tierText, string.format("%d:%02d", mins, rem)
                    end
                end
            end
        end
    end
    return "TIER 1", "?"
end

local function isBedAlive(teamName)
    local colorKey = teamName:lower()
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "wool_" .. colorKey then
            return true
        end
    end
    local bedModels = workspace:FindFirstChild("BedModels")
    if bedModels then
        for _, v in pairs(bedModels:GetChildren()) do
            if v.Name:lower():find(colorKey) then
                return true
            end
        end
    end
    return false
end

local function isGameActive()
    for _, part in pairs(workspace:GetChildren()) do
        if part.Name == "GeneratorAdornee" then
            if part:FindFirstChild("RoactTree") then
                return true
            end
        end
    end
    return false
end

local function getPlayerCounts()
    return #Players:GetPlayers()
end

local function getMode()
    local maxPerTeam = 0
    for _, team in pairs(Teams:GetTeams()) do
        if team.Name ~= "Spectators" then
            local c = #team:GetPlayers()
            if c > maxPerTeam then maxPerTeam = c end
        end
    end
    if maxPerTeam <= 1 then return "Solo"
    elseif maxPerTeam == 2 then return "Doubles"
    elseif maxPerTeam == 3 then return "Trios"
    else return "4v4v4v4" end
end

local function getServerId()
    local jid = game.JobId
    if jid and #jid >= 4 then
        return "m" .. jid:sub(-4):upper():gsub("-", "")
    end
    return "mXXXX"
end

local function getDateString()
    local ok, result = pcall(function() return os.date("%m/%d/%y") end)
    if ok and result then return result end
    return "??/??/??"
end

-- =============================================
-- GUI CREATION
-- =============================================

local existing = PlayerGui:FindFirstChild("BWLeaderboard")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BWLeaderboard"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = CONFIG.BG_ALPHA
MainFrame.BorderSizePixel = 0
MainFrame.Size = UDim2.new(0, CONFIG.WIDTH, 0, 0)
MainFrame.AnchorPoint = Vector2.new(1, 0.5)
MainFrame.Position = UDim2.new(1, -6, 0.5, 0)
MainFrame.AutomaticSize = Enum.AutomaticSize.Y
MainFrame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = MainFrame

local scale = Instance.new("UIScale")
scale.Scale = 1.5
scale.Parent = MainFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop    = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 0)
padding.PaddingLeft   = UDim.new(0, 7)
padding.PaddingRight  = UDim.new(0, 7)
padding.Parent = MainFrame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 1)
layout.Parent = MainFrame

local function makeLabel(text, color, size, bold, order, parent)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, size or 13)
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Code
    lbl.TextSize = size or 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.RichText = true
    lbl.LayoutOrder = order or 0
    lbl.Parent = parent or MainFrame
    return lbl
end

local function makeSpacer(order, parent)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, 1)
    f.LayoutOrder = order or 0
    f.Parent = parent or MainFrame
    return f
end

local function makeDivider(order, parent)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    f.BackgroundTransparency = 0.7
    f.BorderSizePixel = 0
    f.Size = UDim2.new(1, 0, 0, 1)
    f.LayoutOrder = order or 0
    f.Parent = parent or MainFrame
    return f
end

-- Static labels
local titleLabel = makeLabel(CONFIG.TITLE, Color3.fromRGB(255, 220, 0), 14, true, 1)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Font = Enum.Font.GothamBold

local subLabel = makeLabel("", Color3.fromRGB(160, 160, 160), 10, false, 2)

makeDivider(3)
makeSpacer(4)

local dynamicFrame = Instance.new("Frame")
dynamicFrame.Name = "DynamicContent"
dynamicFrame.BackgroundTransparency = 1
dynamicFrame.Size = UDim2.new(1, 0, 0, 10)
dynamicFrame.AutomaticSize = Enum.AutomaticSize.Y
dynamicFrame.LayoutOrder = 6
dynamicFrame.Parent = MainFrame

local dynLayout = Instance.new("UIListLayout")
dynLayout.SortOrder = Enum.SortOrder.LayoutOrder
dynLayout.Padding = UDim.new(0, 1)
dynLayout.Parent = dynamicFrame

makeDivider(7)

local footerLabel = makeLabel(CONFIG.WEBSITE, Color3.fromRGB(255, 220, 0), 10, false, 9)
footerLabel.TextXAlignment = Enum.TextXAlignment.Center

-- =============================================
-- DYNAMIC CONTENT
-- =============================================

local lastMode = nil

local function clearDynamic()
    for _, v in pairs(dynamicFrame:GetChildren()) do
        if v:IsA("GuiObject") then v:Destroy() end
    end
end

local function buildLobbyView(mapName, playerCount, mode)
    clearDynamic()
    local o = 1
    makeLabel("<font color='#ffffff'>Map:</font>  <font color='#55ff55'>" .. mapName .. "</font>",
        Color3.fromRGB(255,255,255), 12, false, o, dynamicFrame); o += 1
    makeLabel("<font color='#ffffff'>Players:</font>  <font color='#55ff55'>" .. playerCount .. "/8</font>",
        Color3.fromRGB(255,255,255), 12, false, o, dynamicFrame); o += 1
    makeLabel("<font color='#aaaaaa'>Waiting...</font>",
        Color3.fromRGB(180,180,180), 12, false, o, dynamicFrame); o += 1
    makeLabel("<font color='#ffffff'>Mode:</font>  <font color='#55ff55'>" .. mode .. "</font>",
        Color3.fromRGB(255,255,255), 12, false, o, dynamicFrame); o += 1
    makeLabel("<font color='#ffffff'>Version:</font>  <font color='#aaaaaa'>v1.0.0</font>",
        Color3.fromRGB(255,255,255), 12, false, o, dynamicFrame); o += 1
end

local function buildGameView(tierText, timerText)
    clearDynamic()
    local o = 1

    local tierStr = tierText ~= "" and (tierText .. " in ") or "Diamond in "
    local timerLbl = makeLabel(
        "<font color='#55ddff'>" .. tierStr .. "</font><font color='#ffffff'>" .. timerText .. "</font>",
        Color3.fromRGB(255,255,255), 12, false, o, dynamicFrame)
    timerLbl.Name = "DiamondTimer"
    o += 1

    local teamList = {}
    for _, team in pairs(Teams:GetTeams()) do
        if team.Name ~= "Spectators" then
            table.insert(teamList, team)
        end
    end
    table.sort(teamList, function(a, b) return a.Name < b.Name end)

    for _, team in pairs(teamList) do
        local tName   = team.Name
        local letter  = TEAM_LETTERS[tName] or tName:sub(1,1):upper()
        local tColor  = TEAM_COLORS[tName] or Color3.fromRGB(255,255,255)
        local bedAlive = isBedAlive(tName)
        local isMyTeam = (LocalPlayer.Team == team)
        local eliminated = (not bedAlive) and (#team:GetPlayers() == 0)

        local row = Instance.new("Frame")
        row.Name = "Team_" .. tName
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 13)
        row.LayoutOrder = o
        row.Parent = dynamicFrame
        o += 1

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 3)
        rowLayout.Parent = row

        -- Letter (team color)
        local letterLbl = Instance.new("TextLabel")
        letterLbl.BackgroundTransparency = 1
        letterLbl.Size = UDim2.new(0, 12, 1, 0)
        letterLbl.Text = letter
        letterLbl.TextColor3 = tColor
        letterLbl.Font = Enum.Font.GothamBold
        letterLbl.TextSize = 12
        letterLbl.TextXAlignment = Enum.TextXAlignment.Left
        letterLbl.LayoutOrder = 1
        letterLbl.Parent = row

        -- Team name
        local nameColor = eliminated and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(255, 255, 255)
        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size = UDim2.new(0, 90, 1, 0)
        nameLbl.Text = tName .. ":"
        nameLbl.TextColor3 = nameColor
        nameLbl.Font = Enum.Font.Code
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Name = "NameLabel"
        nameLbl.LayoutOrder = 2
        nameLbl.Parent = row

        -- Checkmark/X
        local checkmark  = bedAlive and "✔" or "✘"
        local checkColor = bedAlive and "#55ff55" or "#ff5555"
        local checkLbl = Instance.new("TextLabel")
        checkLbl.BackgroundTransparency = 1
        checkLbl.Size = UDim2.new(0, 16, 1, 0)
        checkLbl.RichText = true
        checkLbl.Text = "<font color='" .. checkColor .. "'>" .. checkmark .. "</font>"
        checkLbl.TextColor3 = Color3.fromRGB(255,255,255)
        checkLbl.Font = Enum.Font.Code
        checkLbl.TextSize = 12
        checkLbl.TextXAlignment = Enum.TextXAlignment.Left
        checkLbl.Name = "CheckLabel"
        checkLbl.LayoutOrder = 3
        checkLbl.Parent = row

        -- YOU label
        if isMyTeam then
            local youLbl = Instance.new("TextLabel")
            youLbl.BackgroundTransparency = 1
            youLbl.Size = UDim2.new(0, 40, 1, 0)
            youLbl.Text = "YOU"
            youLbl.TextColor3 = Color3.fromRGB(255, 255, 80)
            youLbl.Font = Enum.Font.GothamBold
            youLbl.TextSize = 10
            youLbl.TextXAlignment = Enum.TextXAlignment.Left
            youLbl.LayoutOrder = 4
            youLbl.Parent = row
        end
    end
end

-- =============================================
-- UPDATE
-- =============================================

local function update()
    subLabel.Text = getDateString() .. "  " .. getServerId()

    if isGameActive() then
        local tierText, timerText = getDiamondTimer()

        if lastMode ~= "game" then
            buildGameView(tierText, timerText)
            lastMode = "game"
        else
            -- Update diamond timer
            local timerLbl = dynamicFrame:FindFirstChild("DiamondTimer")
            if timerLbl then
                local tierStr = tierText ~= "" and (tierText .. " in ") or "Diamond in "
                timerLbl.Text = "<font color='#55ddff'>" .. tierStr .. "</font><font color='#ffffff'>" .. timerText .. "</font>"
            end
            -- Update each team row
            for _, team in pairs(Teams:GetTeams()) do
                if team.Name ~= "Spectators" then
                    local row = dynamicFrame:FindFirstChild("Team_" .. team.Name)
                    if row then
                        local bedAlive   = isBedAlive(team.Name)
                        local eliminated = (not bedAlive) and (#team:GetPlayers() == 0)
                        local checkLbl   = row:FindFirstChild("CheckLabel")
                        local nameLbl    = row:FindFirstChild("NameLabel")
                        if checkLbl then
                            local checkmark  = bedAlive and "✔" or "✘"
                            local checkColor = bedAlive and "#55ff55" or "#ff5555"
                            checkLbl.Text = "<font color='" .. checkColor .. "'>" .. checkmark .. "</font>"
                        end
                        if nameLbl then
                            nameLbl.TextColor3 = eliminated
                                and Color3.fromRGB(120, 120, 120)
                                or  Color3.fromRGB(255, 255, 255)
                        end
                    end
                end
            end
        end
    else
        local mapName     = getMapName()
        local playerCount = getPlayerCounts()
        local mode        = getMode()

        if lastMode ~= "lobby" then
            buildLobbyView(mapName, playerCount, mode)
            lastMode = "lobby"
        else
            for _, lbl in pairs(dynamicFrame:GetChildren()) do
                if lbl:IsA("TextLabel") and lbl.Text:find("Players:") then
                    lbl.Text = "<font color='#ffffff'>Players:</font>  <font color='#55ff55'>" .. playerCount .. "/8</font>"
                end
            end
        end
    end
end

-- =============================================
-- START
-- =============================================

update()

local lastTick = 0
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastTick >= CONFIG.UPDATE_RATE then
        lastTick = now
        pcall(update)
    end
end)

print("[BW Leaderboard] Loaded successfully!")
