--[[
	InventoryService (ModuleScript)
	FISH!TUNE — Central Server-Authoritative Inventory & Economy Service (FISH-021)

	Layanan Sentral Manajemen Inventaris & Transaksi Penjualan Server-Side:
	1. Validasi Kapasitas Inventaris & Anti-Overflow.
	2. Pembuatan & Serialisasi Item 3D Tool Berstandar (Fish, Chest, Artifact, Junk).
	3. Sistem Penguncian Item (Item Locking / Favorite) untuk Mencegah Salah Jual.
	4. Penjualan Tunggal (Sell Single Item) & Penjualan Massal Terproteksi (Sell All Unlocked).
	5. Validasi Kepemilikan Server-Authoritative (Anti-Exploit / Duplication).
	6. Integrasi Penuh dengan PlayerDataService, RemoteContract & Merchant Prompt.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local InventoryService = {}

-- ============ CONFIGURATION ============
InventoryService.CONFIG = {
	DEFAULT_MAX_SLOTS = 35,
	SLOTS_PER_LEVEL = 0.25, -- +1 slot per 4 level
	MAX_UPGRADE_SLOTS = 100,
}

-- ============ 1. HELPER IDENTIFIKASI TOOL ============
function InventoryService.IsLootTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool:GetAttribute("IsFish") == true or tool:GetAttribute("IsLoot") == true then return true end
	if tool:GetAttribute("Coins") ~= nil and tool:GetAttribute("IsRod") ~= true then return true end

	local name = tool.Name:lower()
	if name:find("rod") or name:find("pancing") or name:find("joran") then return false end

	return false
end

-- ============ 2. KAPASITAS INVENTARIS ============
function InventoryService.GetMaxCapacity(player)
	local pData = PlayerDataService.Get(player)
	local lvl = pData and pData.level or 1
	local bonusSlots = math.floor(lvl * InventoryService.CONFIG.SLOTS_PER_LEVEL)
	local customSlots = pData and pData.maxInventorySlots or InventoryService.CONFIG.DEFAULT_MAX_SLOTS

	return math.clamp(customSlots + bonusSlots, InventoryService.CONFIG.DEFAULT_MAX_SLOTS, InventoryService.CONFIG.MAX_UPGRADE_SLOTS)
end

function InventoryService.GetCapacityInfo(player)
	local items = InventoryService.GetPlayerLootItems(player)
	local maxSlots = InventoryService.GetMaxCapacity(player)
	local currentCount = #items

	return {
		current = currentCount,
		max = maxSlots,
		isFull = (currentCount >= maxSlots),
		available = math.max(0, maxSlots - currentCount),
	}
end

-- ============ 3. GET PLAYER LOOT ITEMS ============
function InventoryService.GetPlayerLootItems(player, filterCategory)
	local lootList = {}
	if not player or not player:IsA("Player") then return lootList end

	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

	local function processContainer(container)
		if not container then return end
		for _, item in ipairs(container:GetChildren()) do
			if InventoryService.IsLootTool(item) then
				local itemType = item:GetAttribute("ItemType") or "FISH"
				if not filterCategory or filterCategory == "ALL" or itemType == filterCategory then
					table.insert(lootList, item)
				end
			end
		end
	end

	processContainer(backpack)
	processContainer(char)

	return lootList
end

-- ============ 4. CREATE 3D LOOT TOOL (CENTRAL GENERATOR) ============
function InventoryService.CreateLootTool(lootData)
	local r = lootData.rarity or "COMMON"
	local itemType = lootData.itemType or "FISH"
	local color = lootData.color or Color3.fromRGB(150, 155, 165)
	local badge = lootData.categoryBadge or "🐟 IKAN"
	local itemId = lootData.itemId or ("ITEM_" .. HttpService:GenerateGUID(false))

	local grade = (lootData.performance and lootData.performance.grade) or lootData.grade or "A"
	local acc = (lootData.performance and lootData.performance.accuracy) or lootData.accuracy or 100

	local tool = Instance.new("Tool")
	tool.Name = lootData.name .. " [" .. (lootData.displayName or r) .. "]"
	tool.ToolTip = string.format("%s: %s (%s %s | %.1f Kg | Grade: %s (%.0f%%) | Nilai: %d Koin)", badge, lootData.name, lootData.displayName or r, lootData.stars or "⭐", lootData.weight or 1.0, grade, acc, lootData.coins or 15)
	tool.RequiresHandle = true
	tool.CanBeDropped = true

	-- Metadata Tangkapan Lengkap
	tool:SetAttribute("IsFish", true) -- Kompatibilitas mundur
	tool:SetAttribute("IsLoot", true)
	tool:SetAttribute("ItemId", itemId)
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
	tool:SetAttribute("EffectiveLuck", lootData.effectiveLuck or 0)
	tool:SetAttribute("LuckTitle", lootData.luckTitle or "")
	tool:SetAttribute("FavoriteZone", lootData.favoriteZone or "")
	tool:SetAttribute("IsMutated", lootData.isMutated == true)
	tool:SetAttribute("MutationType", lootData.mutationType or "NONE")
	tool:SetAttribute("MutationName", lootData.mutationName or "")
	tool:SetAttribute("MutationPrefix", lootData.mutationPrefix or "")
	tool:SetAttribute("IsLocked", false)

	local scale = math.clamp(lootData.scale or 1.0, 0.6, 3.5)

	-- ============ GENERASI 3D MODEL BERDASARKAN KATEGORI ============
	if itemType == "TREASURE" then
		-- MODEL PETI HARTA KARUN
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(1.1 * scale, 0.7 * scale, 0.8 * scale)
		handle.Color = color
		handle.Material = (r == "SPECIAL" or r == "MYTHIC") and Enum.Material.Neon or Enum.Material.Wood
		handle.CanCollide = false
		handle.Parent = tool

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
		-- MODEL ARTEFAK & RELIK KUNO
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Ball
		handle.Size = Vector3.new(0.9 * scale, 1.2 * scale, 0.9 * scale)
		handle.Color = color
		handle.Material = Enum.Material.Neon
		handle.CanCollide = false
		handle.Parent = tool

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
		-- MODEL BENDA LAUT
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Block
		handle.Size = Vector3.new(0.7 * scale, 0.7 * scale, 1.1 * scale)
		handle.Color = color
		handle.Material = Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Parent = tool

	else
		-- MODEL IKAN SAMUDRA KLASIK
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Ball
		handle.Size = Vector3.new(0.65 * scale, 0.5 * scale, 1.5 * scale)
		handle.Color = color
		handle.Material = (r == "SPECIAL" or r == "MYTHIC" or r == "LEGENDARY") and Enum.Material.Neon or Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Parent = tool

		local tail = Instance.new("WedgePart")
		tail.Name = "Tail"
		tail.Size = Vector3.new(0.2 * scale, 0.65 * scale, 0.65 * scale)
		tail.Color = color
		tail.Material = handle.Material
		tail.CanCollide = false
		tail.CFrame = handle.CFrame * CFrame.new(0, 0.8 * scale, 0) * CFrame.Angles(0, math.pi, 0)
		tail.Parent = tool

		local wcTail = Instance.new("WeldConstraint")
		wcTail.Part0 = handle
		wcTail.Part1 = tail
		wcTail.Parent = handle

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
		if r ~= "COMMON" or itemType == "TREASURE" or itemType == "ARTIFACT" or lootData.isMutated then
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = color
			sparkles.Parent = handle

			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = (r == "SPECIAL" and 14) or (r == "MYTHIC" and 10) or (r == "LEGENDARY" and 8) or (r == "SUPER_RARE" and 6) or 5
			light.Brightness = (r == "SPECIAL" and 3.2) or (r == "MYTHIC" and 2.4) or (r == "LEGENDARY" and 1.8) or 1.2
			light.Parent = handle
		end

		if r == "SPECIAL" or lootData.mutationType == "COSMIC" then
			local fire = Instance.new("Fire")
			fire.Color = Color3.fromRGB(255, 60, 200)
			fire.SecondaryColor = Color3.fromRGB(0, 255, 255)
			fire.Size = 3.5
			fire.Heat = 5
			fire.Parent = handle
		elseif r == "MYTHIC" or lootData.mutationType == "GOLDEN" then
			local fire = Instance.new("Fire")
			fire.Color = Color3.fromRGB(235, 45, 45)
			fire.SecondaryColor = Color3.fromRGB(255, 200, 50)
			fire.Size = 2.8
			fire.Heat = 4
			fire.Parent = handle
		end

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

-- ============ 5. ADD ITEM TO BACKPACK ============
function InventoryService.AddItem(player, lootData)
	if not player or not player:IsA("Player") then return nil, "Player tidak valid" end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return nil, "Backpack pemain tidak ditemukan" end

	local tool = InventoryService.CreateLootTool(lootData)
	tool.Parent = backpack

	return tool, nil
end

-- ============ 6. TOGGLE LOCK / FAVORITE ============
function InventoryService.ToggleLockItem(player, targetArg)
	if not player then return false, "Player tidak valid" end

	local targetTool = nil
	local allItems = InventoryService.GetPlayerLootItems(player)

	for _, tool in ipairs(allItems) do
		if tool == targetArg or tool.Name == targetArg or tool:GetAttribute("ItemId") == targetArg then
			targetTool = tool
			break
		end
	end

	if not targetTool then
		return false, "Item tidak ditemukan"
	end

	local currentState = targetTool:GetAttribute("IsLocked") == true
	local newState = not currentState
	targetTool:SetAttribute("IsLocked", newState)

	local name = targetTool:GetAttribute("FishName") or targetTool.Name
	local msg = newState and string.format("🔒 %s telah dikunci (Aman dari Jual Massal)!", name)
		or string.format("🔓 %s telah dibuka kuncinya!", name)

	RemoteContract.Server.Notify(player, msg)
	return true, newState
end

-- ============ 7. SELL SINGLE ITEM ============
function InventoryService.SellItem(player, targetArg)
	if not player then return false, 0, "Player tidak valid" end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, 0, "Data player tidak ditemukan" end

	local foundTool = nil
	local allItems = InventoryService.GetPlayerLootItems(player)

	for _, tool in ipairs(allItems) do
		if tool == targetArg or tool.Name == targetArg or tool:GetAttribute("ItemId") == targetArg then
			foundTool = tool
			break
		end
	end

	if not foundTool then
		RemoteContract.Server.Notify(player, "⚠️ Item tidak ditemukan atau sudah terjual!")
		return false, 0, "Item tidak ditemukan"
	end

	if foundTool:GetAttribute("IsLocked") == true then
		RemoteContract.Server.Notify(player, "🔒 Item ini terkunci! Buka kunci terlebih dahulu untuk menjual.")
		return false, 0, "Item terkunci"
	end

	local rawCoins = tonumber(foundTool:GetAttribute("Coins"))
	local coins = rawCoins or EconomyConfig.CalculateSellValue(foundTool:GetAttributes())
	coins = math.max(1, coins)
	local itemName = foundTool:GetAttribute("FishName") or foundTool.Name
	foundTool:Destroy()

	if pData.stats then
		pData.stats.totalItemsSold = (pData.stats.totalItemsSold or 0) + 1
		pData.stats.totalCoinsEarned = (pData.stats.totalCoinsEarned or 0) + coins
	end

	PlayerDataService.AddCoins(player, coins)
	RemoteContract.Server.FishSold(player, itemName, coins, pData.coins)

	return true, coins, itemName
end

-- ============ 8. SELL ALL ITEMS (WITH LOCK PROTECTION) ============
function InventoryService.SellAll(player, filterCategory)
	if not player then return false, 0, 0, "Player tidak valid" end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, 0, 0, "Data player tidak ditemukan" end

	local allItems = InventoryService.GetPlayerLootItems(player, filterCategory)
	local totalGained = 0
	local countSold = 0
	local countLocked = 0

	for _, tool in ipairs(allItems) do
		if tool:GetAttribute("IsLocked") == true then
			countLocked += 1
		else
			local rawCoins = tonumber(tool:GetAttribute("Coins"))
			local val = rawCoins or EconomyConfig.CalculateSellValue(tool:GetAttributes())
			val = math.max(1, val)
			totalGained += val
			countSold += 1
			tool:Destroy()
		end
	end

	if countSold > 0 then
		if pData.stats then
			pData.stats.totalItemsSold = (pData.stats.totalItemsSold or 0) + countSold
			pData.stats.totalCoinsEarned = (pData.stats.totalCoinsEarned or 0) + totalGained
		end
		PlayerDataService.AddCoins(player, totalGained)
		RemoteContract.Server.AllFishSold(player, countSold, totalGained, pData.coins)
		if countLocked > 0 then
			RemoteContract.Server.Notify(player, string.format("🔒 %d item terkunci dilewati dan tetap aman di inventory.", countLocked))
		end
		return true, countSold, totalGained, countLocked
	else
		if countLocked > 0 then
			RemoteContract.Server.Notify(player, string.format("⚠️ Semua (%d) item di inventory sedang terkunci!", countLocked))
		else
			local categoryText = (filterCategory and filterCategory ~= "ALL") and ("kategori " .. filterCategory) or "inventory"
			RemoteContract.Server.Notify(player, string.format("⚠️ Tidak ada item di %s untuk dijual!", categoryText))
		end
		return false, 0, 0, countLocked
	end
end

-- ============ 9. SELL CATEGORY ============
function InventoryService.SellCategory(player, category)
	return InventoryService.SellAll(player, category)
end

return InventoryService
