--[[
	FishingServer
	Memvalidasi kepemilikan alat pancing di inventory,
	memvalidasi hasil memancing Piano Tiles, dan memberi hadiah ikan.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local remote = ReplicatedStorage:FindFirstChild("FishingRemote")
local spot = workspace:FindFirstChild("FishingSpot")

-- Tier ikan berdasarkan tingkat kesulitan Piano Tiles (jumlah tile)
local TIERS = {
	{ minTiles = 16, category = "LEGENDARIS", names = { "Naga Laut Mistis", "Hiu Emas", "Ikan Mas Raja" } },
	{ minTiles = 12, category = "LANGKA", names = { "Belida Emas", "Lele Raksasa", "Pari Sungai" } },
	{ minTiles = 9, category = "SEDANG", names = { "Gurame Super", "Nila Gemuk", "Bawal Besar" } },
	{ minTiles = 0, category = "BIASA", names = { "Ikan Kecil", "Lele", "Louhan Kecil", "Mujair" } },
}

local lastCatch = {}

-- Cek apakah player memiliki pancingan (di Backpack atau sedang dipegang di Character)
local function hasFishingRod(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local inBackpack = backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan"))
	local inChar = character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan"))
	return (inBackpack or inChar) ~= nil
end

local function getFish(tiles)
	for _, tier in ipairs(TIERS) do
		if tiles >= tier.minTiles then
			local name = tier.names[math.random(#tier.names)]
			return name, tier.category
		end
	end
	return "Ikan Kecil", "BIASA"
end

local function onPlayerAdded(player)
	if player:FindFirstChild("leaderstats") then return end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	
	local fish = Instance.new("IntValue")
	fish.Name = "Ikan"
	fish.Value = 0
	fish.Parent = stats
	
	stats.Parent = player
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

if remote then
	remote.OnServerEvent:Connect(function(player, action, data)
		if action == "CheckRod" then
			local hasRod = hasFishingRod(player)
			remote:FireClient(player, "CheckRodResult", hasRod)
			return
		end

		if action ~= "Catch" then return end
		if not (spot and spot.PrimaryPart) then return end

		-- 1. Validasi pancingan di inventory
		if not hasFishingRod(player) then
			remote:FireClient(player, "Notification", "⚠️ Kamu tidak memiliki Joran Pancing di inventory!")
			return
		end

		-- 2. Validasi jarak ke fishing spot
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if (hrp.Position - spot.PrimaryPart.Position).Magnitude > 35 then
			remote:FireClient(player, "Notification", "⚠️ Kamu terlalu jauh dari area memancing!")
			return
		end

		-- 3. Anti-spam validasi
		local last = lastCatch[player.UserId] or 0
		if os.clock() - last < 2 then return end
		lastCatch[player.UserId] = os.clock()

		local tiles = tonumber(data) or 0
		if tiles < 1 or tiles > 50 then return end

		local fishName, category = getFish(math.floor(tiles))
		
		-- Update leaderstats
		local stats = player:FindFirstChild("leaderstats")
		local fishStat = stats and stats:FindFirstChild("Ikan")
		if fishStat then
			fishStat.Value += 1
		end

		remote:FireClient(player, "CatchSuccess", fishName, category)
	end)
else
	warn("FishingServer: FishingRemote tidak ditemukan di ReplicatedStorage")
end
