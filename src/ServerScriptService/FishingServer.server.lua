--[[
	FishingServer (Universal Water Fishing System with Server-Authoritative Sessions, Fish Economy & Progression)
	FISH!TUNE — Game Balance Specification v1.0
	
	Fitur:
	1. Validasi Sesi Memancing Server-Authoritative (Anti-Exploit).
	2. Server-Side RNG, Soft Level Gating, dan Hierarchical Pity System.
	3. Sistem Ekonomi: Ikan harus dijual (Sell / Sell All) agar Koin bertambah.
	4. Sistem Level, EXP Non-linear, Koin, dan Leaderstats Lengkap.
	5. Generator Item Ikan 3D Tool dengan Metadata Lengkap & Visual Aura.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local FishingRaritySystem = require(ReplicatedStorage:WaitForChild("FishingRaritySystem"))
local remote = ReplicatedStorage:FindFirstChild("FishingRemote")

-- Penyimpanan Data Pemain dalam Memori Server
local playerData = {} -- [player.UserId] = { level = 1, exp = 0, coins = 0, totalFish = 0, pity = { LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 } }
local activeSessions = {} -- [sessionId] = { player, userId, waterPos, castQuality, castPower, startTime, waitDuration, status }
local playerSessions = {} -- [player.UserId] = sessionId

local function getPlayerData(player)
	if not playerData[player.UserId] then
		playerData[player.UserId] = {
			level = 1,
			exp = 0,
			coins = 0,
			totalFish = 0,
			pity = { LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 }
		}
	end
	return playerData[player.UserId]
end

local function syncLeaderstats(player)
	local pData = getPlayerData(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	local lvlVal = stats:FindFirstChild("Level")
	if lvlVal then lvlVal.Value = pData.level end

	local coinVal = stats:FindFirstChild("Koin")
	if coinVal then coinVal.Value = pData.coins end

	local fishVal = stats:FindFirstChild("Ikan")
	if fishVal then fishVal.Value = pData.totalFish end

	local expVal = stats:FindFirstChild("Exp")
	if expVal then expVal.Value = pData.exp end
end

local function addExp(player, amount)
	local pData = getPlayerData(player)
	pData.exp += amount
	local leveledUp = false

	while true do
		local reqExp = FishingRaritySystem.GetExpRequiredForLevel(pData.level)
		if pData.exp >= reqExp then
			pData.exp -= reqExp
			pData.level += 1
			leveledUp = true
		else
			break
		end
	end

	syncLeaderstats(player)
	if leveledUp and remote then
		remote:FireClient(player, "LevelUp", pData.level)
	end
	return leveledUp
end

-- Cek apakah player memiliki joran pancing
local function hasFishingRod(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local inBackpack = backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan"))
	local inChar = character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan"))
	return (inBackpack or inChar) ~= nil
end

local function getRodLuck(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local rod = (character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan")))
		or (backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan")))
	if rod and rod:IsA("Tool") then
		return rod:GetAttribute("Luck") or 5
	end
	return 5
end

-- Fungsi Membuat Item Ikan 3D Tool di Inventory
local function createFishTool(fishData)
	local r = fishData.rarity
	local color = fishData.color or Color3.fromRGB(150, 155, 165)

	local tool = Instance.new("Tool")
	tool.Name = fishData.name .. " [" .. fishData.displayName .. "]"
	tool.ToolTip = string.format("Tangkapan: %s (%s %s | %.1f Kg | Nilai: %d Koin)", fishData.name, fishData.displayName, fishData.stars, fishData.weight, fishData.coins)
	tool.RequiresHandle = true
	tool.CanBeDropped = true

	-- Metadata Ikan Lengkap
	tool:SetAttribute("IsFish", true)
	tool:SetAttribute("FishName", fishData.name)
	tool:SetAttribute("DisplayName", fishData.displayName)
	tool:SetAttribute("Rarity", r)
	tool:SetAttribute("Stars", fishData.stars)
	tool:SetAttribute("Weight", fishData.weight)
	tool:SetAttribute("Coins", fishData.coins)
	tool:SetAttribute("Exp", fishData.exp)

	-- Handle Utama (Badan Ikan)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(0.65, 0.5, 1.5)
	handle.Color = color
	handle.Material = (r == "SPECIAL" or r == "MYTHIC" or r == "LEGENDARY") and Enum.Material.Neon or Enum.Material.SmoothPlastic
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
	if r ~= "COMMON" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = handle

		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = (r == "SPECIAL" and 14) or (r == "MYTHIC" and 10) or (r == "LEGENDARY" and 8) or (r == "SUPER_RARE" and 6) or 5
		light.Brightness = (r == "SPECIAL" and 3.2) or (r == "MYTHIC" and 2.4) or (r == "LEGENDARY" and 1.8) or 1.2
		light.Parent = handle
	end

	-- Efek Aura Khusus SPECIAL & MYTHIC
	if r == "SPECIAL" then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 60, 200)
		fire.SecondaryColor = Color3.fromRGB(0, 255, 255)
		fire.Size = 3.5
		fire.Heat = 5
		fire.Parent = handle
	elseif r == "MYTHIC" then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(235, 45, 45)
		fire.SecondaryColor = Color3.fromRGB(255, 200, 50)
		fire.Size = 2.8
		fire.Heat = 4
		fire.Parent = handle
	end

	-- Suara Interaksi
	local equipSound = Instance.new("Sound")
	equipSound.Name = "EquipSound"
	equipSound.SoundId = "rbxasset://sounds/splat.wav"
	equipSound.Volume = 0.4
	equipSound.PlaybackSpeed = 1.4
	equipSound.Parent = handle

	local clickSound = Instance.new("Sound")
	clickSound.Name = "ClickSound"
	clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	clickSound.Volume = 0.6
	clickSound.PlaybackSpeed = 1.3
	clickSound.Parent = handle

	tool.Equipped:Connect(function()
		equipSound:Play()
	end)

	tool.Activated:Connect(function()
		clickSound:Play()
	end)

	return tool
end

-- Inisialisasi Player
local function onPlayerAdded(player)
	getPlayerData(player)

	if not player:FindFirstChild("leaderstats") then
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"

		local lvl = Instance.new("IntValue")
		lvl.Name = "Level"
		lvl.Value = 1
		lvl.Parent = stats

		local koin = Instance.new("IntValue")
		koin.Name = "Koin"
		koin.Value = 0
		koin.Parent = stats

		local fish = Instance.new("IntValue")
		fish.Name = "Ikan"
		fish.Value = 0
		fish.Parent = stats

		local exp = Instance.new("IntValue")
		exp.Name = "Exp"
		exp.Value = 0
		exp.Parent = stats

		stats.Parent = player
	end

	syncLeaderstats(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

Players.PlayerRemoving:Connect(function(player)
	local activeSess = playerSessions[player.UserId]
	if activeSess then
		activeSessions[activeSess] = nil
	end
	playerSessions[player.UserId] = nil
	playerData[player.UserId] = nil
end)

-- Handler Komunikasi Client-Server
if remote then
	remote.OnServerEvent:Connect(function(player, action, arg1, arg2, arg3)
		local pData = getPlayerData(player)

		-- 1. Permintaan Memulai Sesi Memancing (StartFishing)
		if action == "StartFishing" then
			if not hasFishingRod(player) then
				remote:FireClient(player, "Notification", "⚠️ Kamu membutuhkan Joran Pancing di inventory!")
				return
			end

			local oldSess = playerSessions[player.UserId]
			if oldSess then
				activeSessions[oldSess] = nil
			end

			local waterPos = arg1
			local castQuality = tostring(arg2 or "GOOD"):upper()
			local castPower = tonumber(arg3) or 0.5

			local waitDuration = math.random(28, 42) / 10
			if castQuality == "PERFECT" then
				waitDuration = math.random(12, 20) / 10
			elseif castQuality == "GREAT" then
				waitDuration = math.random(18, 28) / 10
			end

			local sessionId = tostring(player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
			local sessionData = {
				player = player,
				userId = player.UserId,
				waterPos = waterPos,
				castQuality = castQuality,
				castPower = castPower,
				startTime = os.clock(),
				waitDuration = waitDuration,
				status = "Active",
			}

			activeSessions[sessionId] = sessionData
			playerSessions[player.UserId] = sessionId

			remote:FireClient(player, "SessionStarted", sessionId, waitDuration, castQuality)
			return
		end

		-- 2. Pengiriman Hasil Tangkapan Rhythm (SubmitCatch) - SERVER AUTHORITATIVE
		if action == "SubmitCatch" then
			local sessionId = tostring(arg1 or "")
			local metrics = arg2 or {}
			local session = activeSessions[sessionId]

			if not session or session.userId ~= player.UserId or session.status ~= "Active" then
				remote:FireClient(player, "Notification", "❌ Sesi memancing tidak valid atau sudah kadaluarsa.")
				return
			end

			session.status = "Completed"
			activeSessions[sessionId] = nil
			playerSessions[player.UserId] = nil

			if not hasFishingRod(player) then
				remote:FireClient(player, "Notification", "⚠️ Kamu tidak memiliki Joran Pancing di inventory!")
				return
			end

			-- Hitung Effective Luck di Server (Specification v1.0)
			local rodLuck = getRodLuck(player)
			local baseLuck = math.clamp(math.floor(pData.level / 5), 0, 10)
			local castLuck = 0
			if session.castQuality == "PERFECT" then
				castLuck = 35
			elseif session.castQuality == "GREAT" then
				castLuck = 15
			end

			local accuracy = tonumber(metrics.accuracy) or 80
			local performanceScore = accuracy
			local performanceLuck = performanceScore * FishingRaritySystem.CONFIG.LUCK.PERFORMANCE_COEFF -- Max +25 Luck

			local effectiveLuck = FishingRaritySystem.CalculateEffectiveLuck(baseLuck + rodLuck, castLuck, performanceLuck, 0)

			-- Roll RNG & Pity di Server
			local rolledRarity, wasPity = FishingRaritySystem.EvaluateWithPity(effectiveLuck, pData.level, pData.pity)
			local fishData = FishingRaritySystem.GenerateFish(rolledRarity, pData.level, performanceScore)

			-- Update Pity State
			pData.pity = FishingRaritySystem.UpdatePityOnCatch(pData.pity, rolledRarity)

			-- Tambah EXP dan Total Ikan (Koin didapat saat ikan dijual!)
			pData.totalFish += 1
			addExp(player, fishData.exp)
			syncLeaderstats(player)

			-- Buat Tool Ikan 3D di Backpack Player
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local fishTool = createFishTool(fishData)
				fishTool.Parent = backpack
			end

			local rewardInfo = {
				coins = fishData.coins, -- Nilai estimasi koin saat dijual
				exp = fishData.exp,
				wasPity = wasPity,
				effectiveLuck = effectiveLuck,
			}

			remote:FireClient(player, "CatchSuccess", fishData, rewardInfo, pData, pData.pity)
			return
		end

		-- 3. Menjual Satu Ikan Tertentu (SellFish)
		if action == "SellFish" then
			local targetArg = arg1
			local foundTool = nil

			local backpack = player:FindFirstChild("Backpack")
			local char = player.Character

			if typeof(targetArg) == "Instance" and targetArg:IsA("Tool") then
				if (backpack and targetArg.Parent == backpack) or (char and targetArg.Parent == char) then
					foundTool = targetArg
				end
			elseif typeof(targetArg) == "string" then
				if backpack and backpack:FindFirstChild(targetArg) then
					foundTool = backpack:FindFirstChild(targetArg)
				elseif char and char:FindFirstChild(targetArg) then
					foundTool = char:FindFirstChild(targetArg)
				end
			end

			if foundTool and (foundTool:GetAttribute("IsFish") == true or (foundTool.Name ~= "FishingRod" and foundTool.Name ~= "Pancingan")) then
				local coins = foundTool:GetAttribute("Coins") or 15
				local fishName = foundTool:GetAttribute("FishName") or foundTool.Name
				foundTool:Destroy()

				pData.coins += coins
				syncLeaderstats(player)

				remote:FireClient(player, "FishSold", fishName, coins, pData.coins)
			else
				remote:FireClient(player, "Notification", "⚠️ Ikan tidak ditemukan atau sudah terjual!")
			end
			return
		end

		-- 4. Menjual Semua Ikan di Inventory (SellAllFish)
		if action == "SellAllFish" then
			local backpack = player:FindFirstChild("Backpack")
			local char = player.Character

			local totalGained = 0
			local count = 0
			local toolsToSell = {}

			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and (item:GetAttribute("IsFish") == true or (item.Name ~= "FishingRod" and item.Name ~= "Pancingan")) then
						table.insert(toolsToSell, item)
					end
				end
			end
			if char then
				for _, item in ipairs(char:GetChildren()) do
					if item:IsA("Tool") and (item:GetAttribute("IsFish") == true or (item.Name ~= "FishingRod" and item.Name ~= "Pancingan")) then
						table.insert(toolsToSell, item)
					end
				end
			end

			for _, tool in ipairs(toolsToSell) do
				local val = tool:GetAttribute("Coins") or 15
				totalGained += val
				count += 1
				tool:Destroy()
			end

			if count > 0 then
				pData.coins += totalGained
				syncLeaderstats(player)
				remote:FireClient(player, "AllFishSold", count, totalGained, pData.coins)
			else
				remote:FireClient(player, "Notification", "⚠️ Tidak ada ikan di inventory untuk dijual!")
			end
			return
		end

		-- 5. Pembatalan Sesi (CancelFishing)
		if action == "CancelFishing" then
			local sessionId = tostring(arg1 or "")
			if activeSessions[sessionId] and activeSessions[sessionId].userId == player.UserId then
				activeSessions[sessionId] = nil
			end
			if playerSessions[player.UserId] == sessionId then
				playerSessions[player.UserId] = nil
			end
			return
		end

		-- 6. Get Player Data
		if action == "GetPlayerData" then
			remote:FireClient(player, "PlayerDataUpdate", pData, pData.pity)
			return
		end
	end)
else
	warn("FishingServer: FishingRemote tidak ditemukan di ReplicatedStorage")
end
