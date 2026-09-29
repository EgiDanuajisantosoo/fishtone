--[[
	FishingServer (Universal Water Fishing System with 6 Rarity Tiers & Pity System)
	- Memvalidasi kepemilikan alat pancing di inventory
	- Mengelola Hierarchical Pity State (SSR 100, UR 500, EX 1000) per Player di Server
	- Membuat Item Ikan 3D Tool dengan Visual Particle / Lighting sesuai 6 Tier Rarity
	- Memperbarui leaderstats dan memberikan reward ke Backpack
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local FishingRaritySystem = require(ReplicatedStorage:WaitForChild("FishingRaritySystem"))
local remote = ReplicatedStorage:FindFirstChild("FishingRemote")

local playerPity = {} -- [player.UserId] = { SSR = 0, UR = 0, EX = 0 }
local lastCatch = {}

-- Inisialisasi Pity Counter Player
local function getPlayerPity(player)
	if not playerPity[player.UserId] then
		playerPity[player.UserId] = { SSR = 0, UR = 0, EX = 0 }
	end
	return playerPity[player.UserId]
end

-- Cek apakah player memiliki pancingan (di Backpack atau sedang dipegang di Character)
local function hasFishingRod(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local inBackpack = backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan"))
	local inChar = character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan"))
	return (inBackpack or inChar) ~= nil
end

-- Fungsi Membuat Item Ikan 3D sebagai Tool di Inventory
local function createFishTool(fishName, rarity)
	local tierData = FishingRaritySystem.TIERS[rarity] or FishingRaritySystem.TIERS.Common
	local color = tierData.color

	local tool = Instance.new("Tool")
	tool.Name = fishName .. " [" .. rarity .. "]"
	tool.ToolTip = "Tangkapan Segar: " .. fishName .. " (" .. tierData.displayName .. " " .. tierData.stars .. ")"
	tool.RequiresHandle = true
	tool.CanBeDropped = true

	-- Handle Utama (Badan Ikan)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(0.65, 0.5, 1.5)
	handle.Color = color
	handle.Material = (rarity == "EX" or rarity == "UR" or rarity == "SSR") and Enum.Material.Neon or Enum.Material.SmoothPlastic
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

	-- Efek Visual Rarity Eksklusif
	if rarity == "EX" or rarity == "UR" or rarity == "SSR" or rarity == "SuperRare" or rarity == "Rare" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = handle

		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = (rarity == "EX" and 12) or (rarity == "UR" and 9) or (rarity == "SSR" and 7) or 5
		light.Brightness = (rarity == "EX" and 3.0) or (rarity == "UR" and 2.2) or 1.5
		light.Parent = handle
	end

	-- Efek Aura Khusus EX / UR
	if rarity == "EX" then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 0, 200)
		fire.SecondaryColor = Color3.fromRGB(0, 255, 255)
		fire.Size = 3
		fire.Heat = 5
		fire.Parent = handle
	elseif rarity == "UR" then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 50, 50)
		fire.SecondaryColor = Color3.fromRGB(255, 200, 50)
		fire.Size = 2.5
		fire.Heat = 4
		fire.Parent = handle
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
	getPlayerPity(player)

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

Players.PlayerRemoving:Connect(function(player)
	playerPity[player.UserId] = nil
	lastCatch[player.UserId] = nil
end)

if remote then
	remote.OnServerEvent:Connect(function(player, action, data1, data2, data3)
		if action == "CheckRod" then
			local hasRod = hasFishingRod(player)
			remote:FireClient(player, "CheckRodResult", hasRod)
			return
		end

		if action == "GetPityState" then
			local currentPity = getPlayerPity(player)
			remote:FireClient(player, "PityStateUpdate", currentPity)
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
		if os.clock() - last < 1.5 then return end
		lastCatch[player.UserId] = os.clock()

		local rarity = tostring(data1 or "Common")
		if not FishingRaritySystem.TIERS[rarity] then
			rarity = "Common"
		end

		local castQuality = tostring(data2 or "GOOD")
		local fishName = tostring(data3 or "")
		if fishName == "" then
			fishName = FishingRaritySystem.GetRandomFishName(rarity)
		end

		-- 3. Update Pity Counter Player Secara Hierarkis setelah Ikan Berhasil Ditangkap
		local currentPity = getPlayerPity(player)
		FishingRaritySystem.UpdatePityOnCatch(currentPity, rarity)

		-- 4. Masukkan Ikan ke dalam Inventory (Backpack) Player
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			local fishItem = createFishTool(fishName, rarity)
			fishItem.Parent = backpack
		end

		-- 5. Update skor ikan di leaderstats
		local stats = player:FindFirstChild("leaderstats")
		local fishStat = stats and stats:FindFirstChild("Ikan")
		if fishStat then
			fishStat.Value += 1
		end

		remote:FireClient(player, "CatchSuccess", fishName, rarity, currentPity)
	end)
else
	warn("FishingServer: FishingRemote tidak ditemukan di ReplicatedStorage")
end
