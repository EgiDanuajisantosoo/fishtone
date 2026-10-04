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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local FishingSessionService = require(script.Parent.FishingSessionService)
local remote = RemoteContract.GetRemote()



local function isRodTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool:GetAttribute("IsFish") == true then return false end
	local name = tool.Name:lower()
	return name:find("rod") ~= nil or name:find("pancing") ~= nil or name:find("joran") ~= nil or tool:GetAttribute("IsRod") == true or tool:GetAttribute("Luck") ~= nil
end

local function getRodTool(player)
	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if isRodTool(item) then return item end
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if isRodTool(item) then return item end
		end
	end
	return nil
end

-- Cek apakah player memiliki joran pancing
local function hasFishingRod(player)
	return getRodTool(player) ~= nil
end

local function getRodLuck(player)
	local rod = getRodTool(player)
	if rod then
		return rod:GetAttribute("Luck") or 5
	end
	return 5
end

-- Fungsi Membuat Item Tangkapan 3D Tool di Inventory (Ikan, Peti Harta Karun, Relik Artefak, Benda Laut)
local function createItemTool(lootData)
	local r = lootData.rarity or "COMMON"
	local itemType = lootData.itemType or "FISH"
	local color = lootData.color or Color3.fromRGB(150, 155, 165)
	local badge = lootData.categoryBadge or "🐟 IKAN"

	local grade = (lootData.performance and lootData.performance.grade) or lootData.grade or "A"
	local acc = (lootData.performance and lootData.performance.accuracy) or lootData.accuracy or 100

	local tool = Instance.new("Tool")
	tool.Name = lootData.name .. " [" .. (lootData.displayName or r) .. "]"
	tool.ToolTip = string.format("%s: %s (%s %s | %.1f Kg | Grade: %s (%.0f%%) | Nilai: %d Koin)", badge, lootData.name, lootData.displayName or r, lootData.stars or "⭐", lootData.weight or 1.0, grade, acc, lootData.coins or 15)
	tool.RequiresHandle = true
	tool.CanBeDropped = true

	-- Metadata Tangkapan Lengkap (Kompatibel dengan Sistem Inventory & Toko Jual)
	tool:SetAttribute("IsFish", true) -- Kompatibilitas mundur dengan handler inventory/merchant
	tool:SetAttribute("IsLoot", true)
	tool:SetAttribute("ItemType", itemType)
	tool:SetAttribute("CategoryBadge", badge)
	tool:SetAttribute("FishId", lootData.id or "")
	tool:SetAttribute("FishName", lootData.name)
	tool:SetAttribute("DisplayName", lootData.displayName or r)
	tool:SetAttribute("Description", lootData.description or "")
	tool:SetAttribute("Rarity", r)
	tool:SetAttribute("Stars", lootData.stars or "⭐")
	tool:SetAttribute("Weight", lootData.weight or 1.0)
	tool:SetAttribute("Coins", lootData.coins or 15)
	tool:SetAttribute("Exp", lootData.exp or 10)
	tool:SetAttribute("Grade", grade)
	tool:SetAttribute("Accuracy", acc)
	tool:SetAttribute("PerformanceLuck", (lootData.performance and lootData.performance.performanceLuckBonus) or lootData.performanceLuckBonus or 0)
	tool:SetAttribute("FavoriteZone", lootData.favoriteZone or "")

	local scale = math.clamp(lootData.scale or 1.0, 0.6, 3.0)

	-- ============ GENERASI 3D MODEL BERDASARKAN KATEGORI ============
	if itemType == "TREASURE" then
		-- MODEL PETI HARTA KARUN (Chest Box + Lid + Metal Hasp)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(1.1 * scale, 0.7 * scale, 0.8 * scale)
		handle.Color = color
		handle.Material = (r == "SPECIAL" or r == "MYTHIC") and Enum.Material.Neon or Enum.Material.Wood
		handle.CanCollide = false
		handle.Parent = tool

		-- Tutup Peti (Lid)
		local lid = Instance.new("Part")
		lid.Name = "ChestLid"
		lid.Shape = Enum.PartType.Block
		lid.Size = Vector3.new(1.15 * scale, 0.3 * scale, 0.85 * scale)
		lid.Color = color
		lid.Material = handle.Material
		lid.CanCollide = false
		lid.CFrame = handle.CFrame * CFrame.new(0, 0.45 * scale, 0)
		lid.Parent = tool

		local wcLid = Instance.new("WeldConstraint")
		wcLid.Part0 = handle
		wcLid.Part1 = lid
		wcLid.Parent = handle

		-- Gembok Emas Peti (Lock/Hasp)
		local lock = Instance.new("Part")
		lock.Name = "ChestLock"
		lock.Shape = Enum.PartType.Block
		lock.Size = Vector3.new(0.2 * scale, 0.25 * scale, 0.1 * scale)
		lock.Color = Color3.fromRGB(255, 215, 0)
		lock.Material = Enum.Material.Metal
		lock.CanCollide = false
		lock.CFrame = handle.CFrame * CFrame.new(0, 0.15 * scale, -0.42 * scale)
		lock.Parent = tool

		local wcLock = Instance.new("WeldConstraint")
		wcLock.Part0 = handle
		wcLock.Part1 = lock
		wcLock.Parent = handle

	elseif itemType == "ARTIFACT" then
		-- MODEL ARTEFAK & RELIK KUNO (Glowing Crystal / Ancient Artifact)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Ball
		handle.Size = Vector3.new(0.9 * scale, 1.2 * scale, 0.9 * scale)
		handle.Color = color
		handle.Material = Enum.Material.Neon
		handle.CanCollide = false
		handle.Parent = tool

		-- Cincin Energi Ornamen
		local ring = Instance.new("Part")
		ring.Name = "AuraRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.15 * scale, 1.3 * scale, 1.3 * scale)
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.4
		ring.CanCollide = false
		ring.CFrame = handle.CFrame * CFrame.Angles(math.pi / 2, 0, 0)
		ring.Parent = tool

		local wcRing = Instance.new("WeldConstraint")
		wcRing.Part0 = handle
		wcRing.Part1 = ring
		wcRing.Parent = handle

	elseif itemType == "JUNK" then
		-- MODEL BENDA LAUT / SAMPAH (Boot / Can / Driftwood)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(0.7 * scale, 0.7 * scale, 1.1 * scale)
		handle.Color = color
		handle.Material = Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Parent = tool

	else
		-- MODEL IKAN SAMUDRA KLASIK (Badan Ikan + Ekor + Sirip)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Ball
		handle.Size = Vector3.new(0.65 * scale, 0.5 * scale, 1.5 * scale)
		handle.Color = color
		handle.Material = (r == "SPECIAL" or r == "MYTHIC" or r == "LEGENDARY") and Enum.Material.Neon or Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Parent = tool

		-- Ekor Ikan
		local tail = Instance.new("WedgePart")
		tail.Name = "Tail"
		tail.Size = Vector3.new(0.2 * scale, 0.65 * scale, 0.65 * scale)
		tail.Color = color
		tail.Material = handle.Material
		tail.CanCollide = false
		tail.CFrame = handle.CFrame * CFrame.new(0, 0, 0.8 * scale) * CFrame.Angles(0, math.pi, 0)
		tail.Parent = tool

		local wcTail = Instance.new("WeldConstraint")
		wcTail.Part0 = handle
		wcTail.Part1 = tail
		wcTail.Parent = handle

		-- Sirip Atas Ikan
		local fin = Instance.new("WedgePart")
		fin.Name = "Fin"
		fin.Size = Vector3.new(0.12 * scale, 0.35 * scale, 0.5 * scale)
		fin.Color = color
		fin.Material = handle.Material
		fin.CanCollide = false
		fin.CFrame = handle.CFrame * CFrame.new(0, 0.35 * scale, -0.1 * scale) * CFrame.Angles(0, math.pi, 0)
		fin.Parent = tool

		local wcFin = Instance.new("WeldConstraint")
		wcFin.Part0 = handle
		wcFin.Part1 = fin
		wcFin.Parent = handle
	end

	local handle = tool:FindFirstChild("Handle")
	if handle then
		-- Efek Visual Rarity & Kategori Eksklusif
		if r ~= "COMMON" or itemType == "TREASURE" or itemType == "ARTIFACT" then
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
		equipSound.SoundId = (itemType == "TREASURE" or itemType == "ARTIFACT") and "rbxasset://sounds/electronicpingshort.wav" or "rbxasset://sounds/splat.wav"
		equipSound.Volume = 0.5
		equipSound.PlaybackSpeed = 1.3
		equipSound.Parent = handle

		local clickSound = Instance.new("Sound")
		clickSound.Name = "ClickSound"
		clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		clickSound.Volume = 0.6
		clickSound.PlaybackSpeed = 1.4
		clickSound.Parent = handle

		tool.Equipped:Connect(function()
			equipSound:Play()
		end)

		tool.Activated:Connect(function()
			clickSound:Play()
		end)
	end

	return tool
end
local createFishTool = createItemTool



-- Handler Komunikasi Client-Server
if remote then
	remote.OnServerEvent:Connect(function(player, action, arg1, arg2, arg3)
		local pData = PlayerDataService.Get(player)

		-- 1. Permintaan Memulai Sesi Memancing (StartFishing)
		if action == RemoteContract.C2S.START_FISHING then
			if not hasFishingRod(player) then
				RemoteContract.Server.Notify(player, "⚠️ Kamu membutuhkan Joran Pancing di inventory!")
				return
			end

			local waterPos = arg1
			local castQuality = arg2
			local castPower = arg3
			local rodLuck = getRodLuck(player)

			local session, err = FishingSessionService.CreateSession(player, waterPos, castQuality, castPower, rodLuck)
			if not session then
				RemoteContract.Server.Notify(player, "❌ " .. tostring(err or "Gagal memulai sesi memancing"))
				return
			end

			RemoteContract.Server.SessionStarted(
				player,
				session.sessionId,
				session.waitDuration,
				session.castQuality,
				session.rarity
			)
			return
		end

		-- 2. Pengiriman Hasil Tangkapan Rhythm (SubmitCatch) - SERVER AUTHORITATIVE
		if action == RemoteContract.C2S.SUBMIT_CATCH then
			local sessionId = arg1
			local metrics = arg2

			if not hasFishingRod(player) then
				RemoteContract.Server.Notify(player, "⚠️ Kamu tidak memiliki Joran Pancing di inventory!")
				return
			end

			local fishData, rewardInfo, updatedData = FishingSessionService.ValidateAndComplete(player, sessionId, metrics)
			if not fishData then
				RemoteContract.Server.Notify(player, "❌ " .. tostring(rewardInfo or "Sesi memancing tidak valid."))
				return
			end

			-- Buat Tool Ikan 3D di Backpack Player
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local fishTool = createFishTool(fishData)
				fishTool.Parent = backpack
			end

			RemoteContract.Server.CatchSuccess(player, fishData, rewardInfo, updatedData, updatedData.pity)
			return
		end

		-- 3. Menjual Satu Ikan Tertentu (SellFish)
		if action == RemoteContract.C2S.SELL_FISH then
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

				PlayerDataService.AddCoins(player, coins)
				RemoteContract.Server.FishSold(player, fishName, coins, pData.coins)
			else
				RemoteContract.Server.Notify(player, "⚠️ Ikan tidak ditemukan atau sudah terjual!")
			end
			return
		end

		-- 4. Menjual Semua Ikan di Inventory (SellAllFish)
		if action == RemoteContract.C2S.SELL_ALL_FISH then
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
				PlayerDataService.AddCoins(player, totalGained)
				RemoteContract.Server.AllFishSold(player, count, totalGained, pData.coins)
			else
				RemoteContract.Server.Notify(player, "⚠️ Tidak ada ikan di inventory untuk dijual!")
			end
			return
		end

		-- 5. Pembatalan Sesi (CancelFishing)
		if action == RemoteContract.C2S.CANCEL_FISHING then
			local sessionId = arg1
			FishingSessionService.CancelSession(player, sessionId)
			return
		end

		-- 6. Get Player Data
		if action == RemoteContract.C2S.GET_PLAYER_DATA then
			RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
			return
		end
	end)
else
	warn("FishingServer: FishingRemote tidak ditemukan di ReplicatedStorage")
end

-- ============ PROXIMITY PROMPT GLOBAL HANDLER (STUDIO MAP INTEGRATION) ============
local ProximityPromptService = game:GetService("ProximityPromptService")

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local pName = prompt.Name:lower()
	local pAction = prompt.ActionText:lower()

	if pName == "sellfishprompt" or pName == "sellfish" or pName == "merchantprompt" or pAction:find("jual") or pAction:find("sell") then
		local pData = PlayerDataService.Get(player)
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
			PlayerDataService.AddCoins(player, totalGained)
			RemoteContract.Server.AllFishSold(player, count, totalGained, pData.coins)
		else
			RemoteContract.Server.Notify(player, "⚠️ Kamu belum memiliki ikan di inventory untuk dijual!")
		end
	end
end)

