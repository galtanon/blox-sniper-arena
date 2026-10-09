-- Moving practice dummies so there is always something to shoot. They don't count toward round kills.
local RunService = game:GetService("RunService")

type Lane = { from: Vector3, to: Vector3, period: number }

-- Ground position (feet) at both ends of each lane
local LANES: { Lane } = {
	{ from = Vector3.new(0, 6, -8), to = Vector3.new(0, 6, 8), period = 5 },
	{ from = Vector3.new(44, 0, -14), to = Vector3.new(44, 0, 14), period = 6 },
	{ from = Vector3.new(-44, 0, 14), to = Vector3.new(-44, 0, -14), period = 6 },
	{ from = Vector3.new(-14, 0, 62), to = Vector3.new(14, 0, 62), period = 7 },
	{ from = Vector3.new(14, 0, -62), to = Vector3.new(-14, 0, -62), period = 7 },
}

local folder = Instance.new("Folder")
folder.Name = "Targets"
folder.Parent = workspace

local function addPart(model: Model, name: string, size: Vector3, offset: Vector3, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = CFrame.new(offset)
	p.Parent = model
	return p
end

local function makeDummy(): Model
	local model = Instance.new("Model")
	model.Name = "Target Dummy"
	local root = addPart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
	root.Transparency = 1
	root.CanCollide = false
	addPart(model, "Legs", Vector3.new(1.6, 2, 1), Vector3.new(0, 1, 0), Color3.fromRGB(60, 60, 70))
	addPart(model, "Torso", Vector3.new(2, 2.2, 1), Vector3.new(0, 3.1, 0), Color3.fromRGB(235, 120, 40))
	local head = addPart(model, "Head", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.9, 0), Color3.fromRGB(245, 205, 160))
	local bullseye = Instance.new("Decal")
	bullseye.Texture = "blox://decal/target"
	bullseye.Face = Enum.NormalId.Front
	bullseye.Parent = head
	model.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model
	return model
end

for i, lane in LANES do
	local phase = i * 1.3
	local function spawnDummy()
		local dummy = makeDummy()
		dummy.Parent = folder
		local humanoid = dummy:FindFirstChildOfClass("Humanoid") :: Humanoid
		local conn = RunService.Heartbeat:Connect(function()
			local t = (math.sin(os.clock() * 2 * math.pi / lane.period + phase) + 1) / 2
			local pos = lane.from:Lerp(lane.to, t) + Vector3.new(0, 3, 0)
			local facing = Vector3.new(-pos.X, 0, -pos.Z)
			local look = if facing.Magnitude > 1 then pos + facing.Unit else pos + Vector3.new(0, 0, 1)
			dummy:PivotTo(CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)))
		end)
		humanoid.Died:Connect(function()
			conn:Disconnect()
			task.delay(0.6, function()
				dummy:Destroy()
			end)
			task.delay(4, spawnDummy)
		end)
	end
	spawnDummy()
end
