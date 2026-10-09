-- Round HUD (timer, scores, health), kill feed, announcements and shot tracers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShotFx = Remotes:WaitForChild("ShotFx") :: RemoteEvent
local KillFeed = Remotes:WaitForChild("KillFeed") :: RemoteEvent
local Announce = Remotes:WaitForChild("Announce") :: RemoteEvent

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "RoundHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent: Instance, size: UDim2, pos: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize
	l.TextStrokeTransparency = 0.5
	l.Parent = parent
	return l
end

------------------------------------------------------------------ top panel
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(150, 58)
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 4)
panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
panel.BackgroundTransparency = 0.3
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local timerLabel = label(panel, UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 3), 22)
local scoreLabel = label(panel, UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 27), 13)
scoreLabel.TextColor3 = Color3.fromRGB(220, 225, 235)

local healthBack = Instance.new("Frame")
healthBack.Size = UDim2.new(1, -20, 0, 6)
healthBack.Position = UDim2.new(0, 10, 0, 46)
healthBack.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
healthBack.BorderSizePixel = 0
healthBack.Parent = panel
Instance.new("UICorner", healthBack).CornerRadius = UDim.new(1, 0)
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(90, 220, 110)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
Instance.new("UICorner", healthFill).CornerRadius = UDim.new(1, 0)

local function kills(p: Player): number
	local stats = p:FindFirstChild("leaderstats")
	local k = stats and stats:FindFirstChild("Kills")
	return if k and k:IsA("IntValue") then k.Value else 0
end

RunService.Heartbeat:Connect(function()
	local roundEnd = ReplicatedStorage:GetAttribute("RoundEnd")
	local left = if typeof(roundEnd) == "number" then math.max(0, math.ceil(roundEnd - workspace:GetServerTimeNow())) else 0
	local playing = ReplicatedStorage:GetAttribute("State") == "Playing"
	timerLabel.Text = if playing then string.format("%d:%02d", left // 60, left % 60) else `Next round {left}`
	timerLabel.TextColor3 = if playing and left <= 10 then Color3.fromRGB(255, 110, 90) else Color3.new(1, 1, 1)

	local best = 0
	for _, p in Players:GetPlayers() do
		best = math.max(best, kills(p))
	end
	scoreLabel.Text = `You {kills(player)}  ·  Best {best}/{Config.KillsToWin}`

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local frac = if humanoid and humanoid.MaxHealth > 0 then math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) else 0
	healthFill.Size = UDim2.fromScale(frac, 1)
	healthFill.BackgroundColor3 = if frac > 0.5 then Color3.fromRGB(90, 220, 110) else Color3.fromRGB(240, 90, 70)
end)

------------------------------------------------------------------ kill feed (top-left)
local feed = Instance.new("Frame")
feed.Size = UDim2.new(0.5, -90, 0, 80)
feed.Position = UDim2.fromOffset(6, 4)
feed.BackgroundTransparency = 1
feed.Parent = gui
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 2)
list.Parent = feed

local feedOrder = 0
KillFeed.OnClientEvent:Connect(function(killer: string, victim: string, headshot: boolean, victimPlayer: Player?)
	feedOrder += 1
	local row = label(feed, UDim2.new(1, 0, 0, 16), UDim2.new(), 12)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextTruncate = Enum.TextTruncate.AtEnd
	row.LayoutOrder = feedOrder
	row.Text = `{killer} {if headshot then "[HS]" else ">"} {victim}`
	if killer == player.DisplayName then
		row.TextColor3 = Color3.fromRGB(255, 215, 90)
	elseif victimPlayer == player then
		row.TextColor3 = Color3.fromRGB(255, 120, 100)
	end
	local rows: { TextLabel } = {}
	for _, child in feed:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(rows, child)
		end
	end
	if #rows > 4 then
		table.sort(rows, function(a: TextLabel, b: TextLabel): boolean
			return a.LayoutOrder < b.LayoutOrder
		end)
		rows[1]:Destroy()
	end
	Debris:AddItem(row, 6)

	if victimPlayer == player then
		local banner = label(gui, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0.42, 0), 20)
		banner.Text = `Sniped by {killer}{if headshot then " (headshot)" else ""}`
		banner.TextColor3 = Color3.fromRGB(255, 120, 100)
		Debris:AddItem(banner, 3)
	elseif killer == player.DisplayName and headshot then
		local banner = label(gui, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0.3, 0), 22)
		banner.Text = "HEADSHOT!"
		banner.TextColor3 = Color3.fromRGB(255, 215, 90)
		Debris:AddItem(banner, 1.2)
	end
end)

------------------------------------------------------------------ announcements
local announce = label(gui, UDim2.new(1, -20, 0, 34), UDim2.new(0, 10, 0.2, 0), 22)
announce.TextWrapped = true
announce.Visible = false
local announceId = 0
Announce.OnClientEvent:Connect(function(text: string)
	announceId += 1
	local id = announceId
	announce.Text = text
	announce.Visible = true
	announce.TextTransparency = 0
	task.delay(3.5, function()
		if announceId == id then
			announce.Visible = false
		end
	end)
	local sound = Instance.new("Sound")
	sound.SoundId = if string.find(text, "wins") then "blox://sound/win" else "blox://sound/countdown_go"
	game:GetService("SoundService"):PlayLocalSound(sound)
end)

------------------------------------------------------------------ shot tracers
local function fade(part: BasePart, duration: number)
	TweenService:Create(part, TweenInfo.new(duration), { Transparency = 1 }):Play()
	Debris:AddItem(part, duration + 0.1)
end

ShotFx.OnClientEvent:Connect(function(shooter: Player, hitPos: Vector3, hitCharacter: boolean)
	local start: Vector3
	if shooter == player then
		start = (camera.CFrame * CFrame.new(0.7, -0.6, -2)).Position
	else
		local character = shooter.Character
		local tool = character and character:FindFirstChild("Sniper")
		local handle = tool and tool:FindFirstChild("Handle")
		local head = character and character:FindFirstChild("Head")
		local from = if handle and handle:IsA("BasePart") then handle elseif head and head:IsA("BasePart") then head else nil
		if not from then
			return
		end
		start = from.Position
	end

	local length = (hitPos - start).Magnitude
	if length > 0.5 then
		local tracer = Instance.new("Part")
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.CanTouch = false
		tracer.Material = Enum.Material.Neon
		tracer.Color = if shooter == player then Color3.fromRGB(255, 230, 120) else Color3.fromRGB(255, 90, 70)
		tracer.Size = Vector3.new(0.12, 0.12, length)
		tracer.CFrame = CFrame.lookAt((start + hitPos) / 2, hitPos)
		tracer.Transparency = 0.1
		tracer.Parent = workspace
		fade(tracer, 0.4)
	end

	local impact = Instance.new("Part")
	impact.Shape = Enum.PartType.Ball
	impact.Anchored = true
	impact.CanCollide = false
	impact.CanQuery = false
	impact.CanTouch = false
	impact.Material = Enum.Material.Neon
	impact.Color = if hitCharacter then Color3.fromRGB(255, 60, 50) else Color3.fromRGB(255, 220, 160)
	impact.Size = Vector3.new(0.8, 0.8, 0.8)
	impact.Position = hitPos
	impact.Parent = workspace
	TweenService:Create(impact, TweenInfo.new(0.3), { Size = Vector3.new(2, 2, 2) }):Play()
	fade(impact, 0.3)

	-- Gunshot, positioned at the shooter
	local emitter = Instance.new("Part")
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Transparency = 1
	emitter.Position = start
	emitter.Parent = workspace
	local sound = Instance.new("Sound")
	sound.SoundId = "blox://sound/laser"
	sound.Volume = if shooter == player then 0.8 else 0.5
	sound.RollOffMaxDistance = 400
	sound.Parent = emitter
	sound:Play()
	Debris:AddItem(emitter, 2)
end)
