-- Player setup: leaderstats, the sniper rifle, ammo state and death counting.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local function buildFallbackRifle(): Tool
	local tool = Instance.new("Tool")
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.6, 4.5)
	handle.Color = Color3.fromRGB(40, 42, 48)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool
	tool.Grip = CFrame.new(0, -0.1, 1.4)
	return tool
end

local function loadRifle(): Tool
	local ok, container = pcall(function()
		return (InsertService :: any):LoadAsset("blox://gear/sniper_blaster")
	end)
	local tool: Tool? = nil
	if ok and container then
		tool = container:FindFirstChildWhichIsA("Tool", true)
	end
	if not tool then
		warn("Sniper asset missing, using fallback rifle")
		tool = buildFallbackRifle()
	end
	local rifle = tool :: Tool
	rifle.Name = "Sniper"
	rifle.ManualActivationOnly = true
	rifle.CanBeDropped = false
	rifle.ToolTip = "Sniper"
	rifle.Parent = ServerStorage
	return rifle
end

local rifleTemplate = loadRifle()

local function giveRifle(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local backpack = player:WaitForChild("Backpack") :: Backpack
	local rifle = rifleTemplate:Clone() :: Tool
	rifle.Parent = backpack
	humanoid:EquipTool(rifle)
	-- Keep the rifle in hand: re-equip if it gets put away.
	rifle.Unequipped:Connect(function()
		task.defer(function()
			if humanoid.Health > 0 and rifle.Parent == (backpack :: Instance) and player.Character == character then
				humanoid:EquipTool(rifle)
			end
		end)
	end)
end

local function setupPlayer(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = stats
	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Parent = stats
	stats.Parent = player

	local function onCharacter(character: Model)
		player:SetAttribute("Ammo", Config.MagSize)
		player:SetAttribute("Reloading", false)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			deaths.Value += 1
		end)
		giveRifle(player, character)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end
