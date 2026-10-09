-- Shared constants. Required from both server and client:
--   local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Config = {
	GameName = "Sniper Arena",

	-- Rounds
	RoundTime = 180, -- seconds
	KillsToWin = 15,
	Intermission = 8,

	-- Rifle
	BodyDamage = 55,
	HeadDamage = 100,
	Range = 700,
	FireCooldown = 1.1, -- bolt action
	MagSize = 5,
	ReloadTime = 2,
	MaxOriginOffset = 8, -- how far the client's shot origin may be from its head

	-- Camera
	NormalFov = 70,
	ScopeFov = 18,
}

return Config
