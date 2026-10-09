-- First-person sniper controls: fire / scope / reload (touch buttons + mouse/keys), crosshair, scope overlay,
-- ammo counter, hit markers and damage flash.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Fire = Remotes:WaitForChild("Fire") :: RemoteEvent
local Reload = Remotes:WaitForChild("Reload") :: RemoteEvent
local HitMarker = Remotes:WaitForChild("HitMarker") :: RemoteEvent

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

player.CameraMode = Enum.CameraMode.LockFirstPerson
camera.FieldOfView = Config.NormalFov
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function playSound(id: string, volume: number?)
	local s = Instance.new("Sound")
	s.SoundId = `blox://sound/{id}`
	s.Volume = volume or 0.6
	SoundService:PlayLocalSound(s)
end

local function frame(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props do
		(f :: any)[k] = v
	end
	return f
end

------------------------------------------------------------------ center overlay (aligned with the viewport)
local center = Instance.new("ScreenGui")
center.Name = "SniperCenter"
center.IgnoreGuiInset = true
center.ResetOnSpawn = false
center.Parent = player:WaitForChild("PlayerGui")

-- Crosshair: four short ticks and a dot
local crosshair = frame({ Name = "Crosshair", Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = center })
for _, spec in { { 0.5, 0, 2, 8 }, { 0.5, 1, 2, 8 }, { 0, 0.5, 8, 2 }, { 1, 0.5, 8, 2 } } do
	frame({ Size = UDim2.fromOffset(spec[3], spec[4]), AnchorPoint = Vector2.new(spec[1], spec[2]), Position = UDim2.fromScale(spec[1], spec[2]), BackgroundColor3 = Color3.new(1, 1, 1), Parent = crosshair })
end
local dot = frame({ Size = UDim2.fromOffset(3, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 70, 60), Parent = crosshair })
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

-- Scope: black bars around a round lens with thin crosshairs
local scope = frame({ Name = "Scope", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = center })
local black = Color3.new(0, 0, 0)
local lens = frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 2, Parent = scope })
Instance.new("UICorner", lens).CornerRadius = UDim.new(0.5, 0)
local lensStroke = Instance.new("UIStroke")
lensStroke.Color = black
lensStroke.Parent = lens
local bars = {
	frame({ BackgroundColor3 = black, ZIndex = 2, Parent = scope }),
	frame({ BackgroundColor3 = black, ZIndex = 2, Parent = scope }),
	frame({ BackgroundColor3 = black, ZIndex = 2, Parent = scope }),
	frame({ BackgroundColor3 = black, ZIndex = 2, Parent = scope }),
}
frame({ Size = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = black, ZIndex = 3, Parent = lens })
frame({ Size = UDim2.new(0, 2, 1, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = black, ZIndex = 3, Parent = lens })
local scopeDot = frame({ Size = UDim2.fromOffset(5, 5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 50, 40), ZIndex = 4, Parent = lens })
Instance.new("UICorner", scopeDot).CornerRadius = UDim.new(1, 0)

local function layoutScope()
	local vp = camera.ViewportSize
	local side = math.floor(math.min(vp.X, vp.Y) * 0.96)
	local left = math.floor((vp.X - side) / 2)
	local top = math.floor((vp.Y - side) / 2)
	lens.Size = UDim2.fromOffset(side, side)
	lensStroke.Thickness = math.ceil(side * 0.22) -- covers the lens corners
	bars[1].Size, bars[1].Position = UDim2.new(0, left + 1, 1, 0), UDim2.fromOffset(0, 0)
	bars[2].Size, bars[2].Position = UDim2.new(0, left + 1, 1, 0), UDim2.new(1, -left - 1, 0, 0)
	bars[3].Size, bars[3].Position = UDim2.new(1, 0, 0, top + 1), UDim2.fromOffset(0, 0)
	bars[4].Size, bars[4].Position = UDim2.new(1, 0, 0, top + 1), UDim2.new(0, 0, 1, -top - 1)
end
layoutScope()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutScope)

-- Hit marker: four diagonal ticks around the center
local marker = frame({ Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = center })
local markerTicks: { Frame } = {}
for _, spec in { { 0.18, 0.18, 45 }, { 0.82, 0.82, 45 }, { 0.82, 0.18, -45 }, { 0.18, 0.82, -45 } } do
	table.insert(markerTicks, frame({ Size = UDim2.fromOffset(10, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(spec[1], spec[2]), Rotation = spec[3], BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5, Parent = marker }))
end

-- Red flash when hurt
local hurt = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(200, 0, 0), BackgroundTransparency = 1, ZIndex = 6, Parent = center })

------------------------------------------------------------------ buttons (below the top bar, clear of thumbstick/jump)
local hud = Instance.new("ScreenGui")
hud.Name = "SniperButtons"
hud.ResetOnSpawn = false
hud.Parent = player.PlayerGui

local function button(text: string, size: number, pos: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(size, size)
	b.AnchorPoint = Vector2.new(1, 1)
	b.Position = pos
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.15
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = if size >= 80 then 20 else 16
	b.AutoButtonColor = true
	b.Parent = hud
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.5
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	return b
end

local fireButton = button("FIRE", 86, UDim2.new(1, -14, 1, -160), Color3.fromRGB(210, 50, 45))
local scopeButton = button("SCOPE", 64, UDim2.new(1, -26, 1, -258), Color3.fromRGB(40, 45, 55))
local reloadButton = button("R", 48, UDim2.new(1, -112, 1, -270), Color3.fromRGB(40, 45, 55))

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.fromOffset(78, 30)
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -108, 1, -176)
ammoLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
ammoLabel.BackgroundTransparency = 0.35
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 18
ammoLabel.Parent = hud
Instance.new("UICorner", ammoLabel).CornerRadius = UDim.new(0, 8)

------------------------------------------------------------------ state
local scoped = false
local lastFire = 0

local function equippedRifle(): Tool?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local tool = character:FindFirstChild("Sniper")
	return if tool and tool:IsA("Tool") then tool else nil
end

local function setScoped(on: boolean)
	if on and not equippedRifle() then
		on = false
	end
	if on == scoped then
		return
	end
	scoped = on
	scope.Visible = on
	crosshair.Visible = not on
	scopeButton.Text = if on then "UNZOOM" else "SCOPE"
	scopeButton.TextSize = if on then 13 else 16
	TweenService:Create(camera, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { FieldOfView = if on then Config.ScopeFov else Config.NormalFov }):Play()
	if on then
		playSound("click", 0.4)
	end
end

local function updateAmmo()
	local ammo = player:GetAttribute("Ammo") or 0
	if player:GetAttribute("Reloading") then
		ammoLabel.Text = "RELOAD"
		ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	else
		ammoLabel.Text = `{ammo} / {Config.MagSize}`
		ammoLabel.TextColor3 = if ammo <= 1 then Color3.fromRGB(255, 120, 100) else Color3.new(1, 1, 1)
	end
end
player:GetAttributeChangedSignal("Ammo"):Connect(updateAmmo)
player:GetAttributeChangedSignal("Reloading"):Connect(function()
	updateAmmo()
	if player:GetAttribute("Reloading") then
		setScoped(false)
		playSound("snap", 0.5)
	end
end)
updateAmmo()

local function fire()
	if not equippedRifle() or ReplicatedStorage:GetAttribute("State") ~= "Playing" then
		return
	end
	if player:GetAttribute("Reloading") or (player:GetAttribute("Ammo") or 0) <= 0 then
		Reload:FireServer()
		return
	end
	if os.clock() - lastFire < Config.FireCooldown then
		return
	end
	local character = player.Character :: Model
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	lastFire = os.clock()

	-- Aim where the crosshair points; the shot itself starts at the head (server checks it).
	local vp = camera.ViewportSize
	local ray = camera:ViewportPointToRay(vp.X / 2, vp.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(ray.Origin, ray.Direction * Config.Range, params)
	local target = if result then result.Position else ray.Origin + ray.Direction * Config.Range
	local dir = target - head.Position
	if dir.Magnitude < 0.5 then
		dir = ray.Direction
	end
	Fire:FireServer(head.Position, dir)

	-- Recoil feel: a quick FOV punch, and the bolt cycles
	local fov = if scoped then Config.ScopeFov else Config.NormalFov
	camera.FieldOfView = fov + (if scoped then 4 else 6)
	TweenService:Create(camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
	fireButton.BackgroundTransparency = 0.6
	fireButton.Text = "..."
	task.delay(Config.FireCooldown, function()
		fireButton.BackgroundTransparency = 0.15
		fireButton.Text = "FIRE"
	end)
end

fireButton.Activated:Connect(fire)
scopeButton.Activated:Connect(function()
	setScoped(not scoped)
end)
reloadButton.Activated:Connect(function()
	Reload:FireServer()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		fire()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setScoped(true)
	elseif input.KeyCode == Enum.KeyCode.R then
		Reload:FireServer()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
		setScoped(not scoped)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setScoped(false)
	end
end)

------------------------------------------------------------------ feedback
HitMarker.OnClientEvent:Connect(function(headshot: boolean, killed: boolean)
	local color = if killed then Color3.fromRGB(255, 60, 50) elseif headshot then Color3.fromRGB(255, 210, 60) else Color3.new(1, 1, 1)
	for _, tick in markerTicks do
		tick.BackgroundColor3 = color
	end
	marker.Visible = true
	marker.Size = UDim2.fromOffset(46, 46)
	TweenService:Create(marker, TweenInfo.new(0.12), { Size = UDim2.fromOffset(34, 34) }):Play()
	task.delay(0.3, function()
		marker.Visible = false
	end)
	playSound(if killed then "level_up" elseif headshot then "ping" else "hit", 0.7)
end)

local function onCharacter(character: Model)
	setScoped(false)
	camera.FieldOfView = Config.NormalFov
	lastFire = 0
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth - 1 then
			hurt.BackgroundTransparency = 0.55
			TweenService:Create(hurt, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			playSound("hurt", 0.6)
		end
		lastHealth = health
	end)
	humanoid.Died:Connect(function()
		setScoped(false)
	end)
end
if player.Character then
	task.spawn(onCharacter, player.Character)
end
player.CharacterAdded:Connect(onCharacter)
