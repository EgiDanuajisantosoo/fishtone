--[[
	FishingServer (Universal Water Fishing System)
	Memvalidasi kepemilikan alat pancing di inventory,
	memvalidasi hasil memancing Piano Tiles di semua area air,
	mengevaluasi kualitas lemparan kail (PERFECT, GREAT, GOOD),
	dan MEMASUKKAN IKAN YANG DITANGKAP KE DALAM INVENTORY PLAYER sebagai item Tool 3D yang bisa dipegang.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local remote = ReplicatedStorage:FindFirstChild("FishingRemote")

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

local function getFish(tiles, castQuality)
	local bonus = (castQuality == "PERFECT" and 4) or (castQuality == "GREAT" and 2) or 0
	local effectiveTiles = tiles + bonus

	for _, tier in ipairs(TIERS) do
		if effectiveTiles >= tier.minTiles then
			local name = tier.names[math.random(#tier.names)]
			return name, tier.category
		end
	end
	return "Ikan Kecil", "BIASA"
end

-- Fungsi Membuat Item Ikan 3D sebagai Tool di Inventory
local function createFishTool(fishName, category)
	local tool = Instance.new("Tool")
	tool.Name = fishName .. " [" .. category .. "]"
	tool.ToolTip = "Tangkapan Segar: " .. fishName .. " (" .. category .. ")"
	tool.RequiresHandle = true
	tool.CanBeDropped = true

	local color = (category == "LEGENDARIS" and Color3.fromRGB(255, 215, 0))
		or (category == "LANGKA" and Color3.fromRGB(190, 70, 255))
		or (category == "SEDANG" and Color3.fromRGB(50, 215, 120))
		or Color3.fromRGB(255, 140, 30)

	-- Handle Utama (Badan Ikan)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(0.65, 0.5, 1.5)
	handle.Color = color
	handle.Material = (category == "LEGENDARIS" and Enum.Material.Neon) or Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool

	-- Ekor Ikan
	local tail = Instance.new("WedgePart")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.2, 0.65, 0.65)
	tail.Color = color
	tail.Material = handle.Material
	tail.CanCollide = false
	tail.CFrame = handle.CFrame * CFrame.new(0, 0, 0.8) * CFrame.Angles(0, math.pi, 0)
	tail.Parent = tool

	local wcTail = Instance.new("WeldConstraint")
	wcTail.Part0 = handle
	wcTail.Part1 = tail
	wcTail.Parent = handle

	-- Sirip Atas Ikan
	local fin = Instance.new("WedgePart")
	fin.Name = "Fin"
	fin.Size = Vector3.new(0.12, 0.35, 0.5)
	fin.Color = color
	fin.Material = handle.Material
	fin.CanCollide = false
	fin.CFrame = handle.CFrame * CFrame.new(0, 0.35, -0.1) * CFrame.Angles(0, math.pi, 0)
	fin.Parent = tool

	local wcFin = Instance.new("WeldConstraint")
	wcFin.Part0 = handle
	wcFin.Part1 = fin
	wcFin.Parent = handle

	-- Efek Visual Rarity (Kilau Emas/Ungu untuk Langka & Legendaris)
	if category == "LEGENDARIS" or category == "LANGKA" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = handle

		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 6
		light.Brightness = 1.5
		light.Parent = handle
	end

	-- Script Interaksi Ikan saat dipegang & diklik
	local localScript = Instance.new("LocalScript")
	localScript.Name = "FishInteraction"
	localScript.Source = [[
		local tool = script.Parent
		local player = game:GetService("Players").LocalPlayer

		tool.Equipped:Connect(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/splat.wav"
			s.Volume = 0.4
			s.PlaybackSpeed = 1.4
			s.Parent = workspace
			s:Play()
			game:GetService("Debris"):AddItem(s, 2)
		end)

		tool.Activated:Connect(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			s.Volume = 0.6
			s.PlaybackSpeed = 1.3
			s.Parent = workspace
			s:Play()
			game:GetService("Debris"):AddItem(s, 2)
		end)
	]]
	localScript.Parent = tool

	return tool
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
	remote.OnServerEvent:Connect(function(player, action, data, extra)
		if action == "CheckRod" then
			local hasRod = hasFishingRod(player)
			remote:FireClient(player, "CheckRodResult", hasRod)
			return
		end

		if action ~= "Catch" then return end

		-- 1. Validasi kepemilikan alat pancing di inventory
		if not hasFishingRod(player) then
			remote:FireClient(player, "Notification", "⚠️ Kamu tidak memiliki Joran Pancing di inventory!")
			return
		end

		-- 2. Anti-spam validasi
		local last = lastCatch[player.UserId] or 0
		if os.clock() - last < 2 then return end
		lastCatch[player.UserId] = os.clock()

		local tiles = tonumber(data) or 0
		if tiles < 1 or tiles > 50 then return end

		local castQuality = tostring(extra or "NORMAL")
		local fishName, category = getFish(math.floor(tiles), castQuality)
		
		-- 3. Masukkan Ikan ke dalam Inventory (Backpack) Player
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			local fishItem = createFishTool(fishName, category)
			fishItem.Parent = backpack
		end

		-- 4. Update skor ikan di leaderstats
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
