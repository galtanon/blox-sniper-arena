-- Round loop: timed free-for-all, first to Config.KillsToWin kills (or most kills at time-up) wins.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Announce = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Announce") :: RemoteEvent

local function statOf(player: Player, name: string): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name) :: IntValue?
end

local function topPlayer(): (Player?, number)
	local best: Player? = nil
	local bestKills = 0
	for _, player in Players:GetPlayers() do
		local kills = statOf(player, "Kills")
		if kills and kills.Value > bestKills then
			best, bestKills = player, kills.Value
		end
	end
	return best, bestKills
end

while true do
	-- Fresh round
	for _, player in Players:GetPlayers() do
		local kills, deaths = statOf(player, "Kills"), statOf(player, "Deaths")
		if kills then
			kills.Value = 0
		end
		if deaths then
			deaths.Value = 0
		end
	end
	ReplicatedStorage:SetAttribute("State", "Playing")
	ReplicatedStorage:SetAttribute("RoundEnd", workspace:GetServerTimeNow() + Config.RoundTime)
	Announce:FireAllClients(`Round start! First to {Config.KillsToWin} kills`)

	while true do
		task.wait(0.25)
		local _, kills = topPlayer()
		if kills >= Config.KillsToWin or workspace:GetServerTimeNow() >= ReplicatedStorage:GetAttribute("RoundEnd") then
			break
		end
	end

	local winner, kills = topPlayer()
	ReplicatedStorage:SetAttribute("State", "Intermission")
	ReplicatedStorage:SetAttribute("RoundEnd", workspace:GetServerTimeNow() + Config.Intermission)
	if winner then
		Announce:FireAllClients(`{winner.DisplayName} wins with {kills} kills!`)
	else
		Announce:FireAllClients("Time's up! No winner this round")
	end
	task.wait(Config.Intermission)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
	task.wait(0.5)
end
