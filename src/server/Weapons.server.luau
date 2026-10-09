-- Server-authoritative sniper shots: validates every shot, raycasts, applies damage and credits kills.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Fire = Remotes:WaitForChild("Fire") :: RemoteEvent
local Reload = Remotes:WaitForChild("Reload") :: RemoteEvent
local ShotFx = Remotes:WaitForChild("ShotFx") :: RemoteEvent
local HitMarker = Remotes:WaitForChild("HitMarker") :: RemoteEvent
local KillFeed = Remotes:WaitForChild("KillFeed") :: RemoteEvent

local lastShot: { [Player]: number } = {}

local function isFiniteVector(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e6
end

local function reload(player: Player)
	if player:GetAttribute("Reloading") or (player:GetAttribute("Ammo") or 0) >= Config.MagSize then
		return
	end
	player:SetAttribute("Reloading", true)
	local character = player.Character
	task.delay(Config.ReloadTime, function()
		-- A respawn already refilled the magazine.
		if player.Parent and player.Character == character then
			player:SetAttribute("Ammo", Config.MagSize)
			player:SetAttribute("Reloading", false)
		end
	end)
end

local function aliveHumanoid(character: Model?): Humanoid?
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

Fire.OnServerEvent:Connect(function(player: Player, origin: unknown, direction: unknown)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	if not isFiniteVector(origin) or not isFiniteVector(direction) or direction.Magnitude < 0.01 then
		return
	end
	if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
		return
	end
	local character = player.Character
	local humanoid = aliveHumanoid(character)
	if not character or not humanoid then
		return
	end
	local head = character:FindFirstChild("Head") :: BasePart?
	local tool = character:FindFirstChild("Sniper")
	if not head or not tool or not tool:IsA("Tool") then
		return
	end
	local now = os.clock()
	if now - (lastShot[player] or 0) < Config.FireCooldown - 0.15 then
		return
	end
	local ammo = player:GetAttribute("Ammo") or 0
	if player:GetAttribute("Reloading") or ammo <= 0 then
		return
	end
	if (origin - head.Position).Magnitude > Config.MaxOriginOffset then
		return
	end

	lastShot[player] = now
	ammo -= 1
	player:SetAttribute("Ammo", ammo)

	-- Shooting ends spawn protection.
	local shield = character:FindFirstChildOfClass("ForceField")
	if shield then
		shield:Destroy()
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	-- Don't let a shot start on the other side of a wall.
	local start = origin
	local offset = origin - head.Position
	if offset.Magnitude > 0.1 and workspace:Raycast(head.Position, offset, params) then
		start = head.Position
	end

	local dir = direction.Unit
	local result = workspace:Raycast(start, dir * Config.Range, params)
	local hitPos = if result then result.Position else start + dir * Config.Range
	local hitCharacter = false

	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local victim = aliveHumanoid(model)
		if model and victim then
			hitCharacter = true
			local inst = result.Instance
			local headshot = inst.Name == "Head" or (inst.Parent ~= nil and inst.Parent:IsA("Accessory"))
			local protected = model:FindFirstChildOfClass("ForceField") ~= nil
			if not protected then
				victim:TakeDamage(if headshot then Config.HeadDamage else Config.BodyDamage)
				local killed = victim.Health <= 0
				HitMarker:FireClient(player, headshot, killed)
				if killed then
					local victimPlayer = Players:GetPlayerFromCharacter(model)
					if victimPlayer and victimPlayer ~= player then
						local stats = player:FindFirstChild("leaderstats")
						local kills = stats and stats:FindFirstChild("Kills") :: IntValue?
						if kills then
							kills.Value += 1
						end
					end
					local victimName = if victimPlayer then victimPlayer.DisplayName else model.Name
					KillFeed:FireAllClients(player.DisplayName, victimName, headshot, victimPlayer)
				end
			end
		end
	end

	ShotFx:FireAllClients(player, hitPos, hitCharacter)

	if ammo <= 0 then
		reload(player)
	end
end)

Reload.OnServerEvent:Connect(function(player: Player)
	if aliveHumanoid(player.Character) then
		reload(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastShot[player] = nil
end)
