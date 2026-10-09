--[[
	EconomyService (ModuleScript)
	FISH!TUNE — Central Server-Authoritative Economy & Shop Service (FISH-024)

	Layanan Sentral Transaksi Ekonomi, Toko Alat Pancing, Manajemen Umpan & Ekspansi Tas:
	1. Manajemen Dompet Aman (Wallet, Coins, Pearls, Mutasi Saldo & Anti-Negative Balance).
	2. Toko Joran Pancing (Pembelian, Validasi Level, Kepemilikan, dan Auto-Equip 3D Tool).
	3. Toko & Manajemen Umpan (Pembelian Satuan/Paket, Konsumsi Umpan Tiap Strike & Bonus Luck).
	4. Peningkatan Kapasitas Tas (Bag Upgrade Tiers, Validasi Persyaratan & Sinkronisasi Slot).
	5. Valuasi Penjualan Ikan Server-Authoritative (Integrasi Grade Rhythm, Bobot & Mutasi).
	6. Integrasi Penuh dengan PlayerDataService, RemoteContract & ProximityPrompt Map.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local PlayerDataService = require(script.Parent.PlayerDataService)

local EconomyService = {}

-- ============ 1. MANAJEMEN DOMPET & SALDO (WALLET) ============

function EconomyService.GetBalance(player)
	local pData = PlayerDataService.Get(player)
	if not pData then
		return { coins = 0, pearls = 0, totalEarned = 0, totalSpent = 0 }
	end

	return {
		coins = pData.coins or 0,
		pearls = pData.pearls or 0,
		totalEarned = (pData.stats and pData.stats.totalCoinsEarned) or 0,
		totalSpent = (pData.stats and pData.stats.totalCoinsSpent) or 0,
	}
end

function EconomyService.CanAfford(player, cost, currencyType)
	cost = math.max(0, tonumber(cost) or 0)
	currencyType = currencyType or "COINS"

	local pData = PlayerDataService.Get(player)
	if not pData then return false end

	if currencyType == "PEARLS" then
		return (pData.pearls or 0) >= cost
	else
		return (pData.coins or 0) >= cost
	end
end

function EconomyService.AddCoins(player, amount, reason)
	amount = math.max(0, tonumber(amount) or 0)
	if amount <= 0 then return false, 0 end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, 0 end

	PlayerDataService.AddCoins(player, amount)
	print(string.format("[EconomyService] +%d Koin untuk %s (Alasan: %s). Total: %d", amount, player.Name, tostring(reason or "Unknown"), pData.coins))
	return true, pData.coins
end

function EconomyService.DeductCoins(player, amount, reason)
	amount = math.max(0, tonumber(amount) or 0)
	if amount <= 0 then return true, 0 end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, 0 end

	if (pData.coins or 0) < amount then
		return false, pData.coins
	end

	pData.coins = pData.coins - amount
	if pData.stats then
		pData.stats.totalCoinsSpent = (pData.stats.totalCoinsSpent or 0) + amount
		pData.stats.totalPurchases = (pData.stats.totalPurchases or 0) + 1
	end

	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)

	print(string.format("[EconomyService] -%d Koin dari %s (Alasan: %s). Sisa: %d", amount, player.Name, tostring(reason or "Purchase"), pData.coins))
	return true, pData.coins
end

-- ============ 2. MANAJEMEN & GENERATOR JORAN PANCING (RODS) ============

function EconomyService.CreateRodTool(rodData)
	rodData = rodData or EconomyConfig.RODS[1]

	local tool = Instance.new("Tool")
	tool.Name = "FishingRod"
	tool.ToolTip = string.format("%s (%s | Luck: +%d | Power: %.2fx | Reel: %.2fx)", rodData.name, rodData.badge or "JORAN", rodData.luckBonus or 5, rodData.castPowerMultiplier or 1.0, rodData.reelSpeedMultiplier or 1.0)
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local rodMapping = InstrumentDefinitions.GetRodMapping(rodData.id)
	local instType = rodData.instrumentType or rodMapping.instrumentType or "PIANO"
	local instVariant = rodMapping.instrumentVariant or "DEFAULT"

	-- Attributes
	tool:SetAttribute("IsRod", true)
	tool:SetAttribute("RodId", rodData.id)
	tool:SetAttribute("RodName", rodData.name)
	tool:SetAttribute("InstrumentType", instType)
	tool:SetAttribute("InstrumentVariant", instVariant)
	tool:SetAttribute("Luck", rodData.luckBonus or 5)
	tool:SetAttribute("CastPower", rodData.castPowerMultiplier or 1.0)
	tool:SetAttribute("ReelSpeed", rodData.reelSpeedMultiplier or 1.0)
	tool:SetAttribute("Tier", rodData.tier or "COMMON")
	tool:SetAttribute("Description", rodData.description or "")

	local scale = rodData.scale or 1.0

	-- Gagang Utama (Handle)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(1.8 * scale, 0.22 * scale, 0.22 * scale)
	handle.CFrame = CFrame.Angles(0, 0, math.rad(90))
	handle.Color = rodData.handleColor or Color3.fromRGB(110, 80, 50)
	handle.Material = rodData.material or Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = tool

	-- Batang Joran (Shaft)
	local shaft = Instance.new("Part")
	shaft.Name = "RodShaft"
	shaft.Shape = Enum.PartType.Cylinder
	shaft.Size = Vector3.new(4.2 * scale, 0.14 * scale, 0.14 * scale)
	shaft.Color = rodData.color or Color3.fromRGB(180, 140, 90)
	shaft.Material = rodData.material or Enum.Material.Wood
	shaft.CanCollide = false
	shaft.CFrame = handle.CFrame * CFrame.new(0, 2.5 * scale, 0)
	shaft.Parent = tool

	local wcShaft = Instance.new("WeldConstraint")
	wcShaft.Part0 = handle
	wcShaft.Part1 = shaft
	wcShaft.Parent = handle

	-- Ujung Joran (Tip & Accent Ring)
	local tip = Instance.new("Part")
	tip.Name = "RodTip"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.new(0.32 * scale, 0.32 * scale, 0.32 * scale)
	tip.Color = rodData.accentColor or Color3.fromRGB(255, 230, 100)
	tip.Material = (rodData.tier == "MYTHIC" or rodData.tier == "LEGENDARY" or rodData.tier == "SUPER_RARE") and Enum.Material.Neon or Enum.Material.SmoothPlastic
	tip.CanCollide = false
	tip.CFrame = shaft.CFrame * CFrame.new(0, 2.1 * scale, 0)
	tip.Parent = tool

	local wcTip = Instance.new("WeldConstraint")
	wcTip.Part0 = handle
	wcTip.Part1 = tip
	wcTip.Parent = handle

	-- Reel / Gulungan Senar Musikal
	local reel = Instance.new("Part")
	reel.Name = "RodReel"
	reel.Shape = Enum.PartType.Cylinder
	reel.Size = Vector3.new(0.4 * scale, 0.45 * scale, 0.45 * scale)
	reel.Color = rodData.accentColor or Color3.fromRGB(200, 200, 210)
	reel.Material = Enum.Material.Metal
	reel.CanCollide = false
	reel.CFrame = handle.CFrame * CFrame.new(0.22 * scale, -0.2 * scale, 0) * CFrame.Angles(0, math.rad(90), 0)
	reel.Parent = tool

	local wcReel = Instance.new("WeldConstraint")
	wcReel.Part0 = handle
	wcReel.Part1 = reel
	wcReel.Parent = handle

	-- Ornamen Tematik Khusus Berdasarkan Jenis Instrumen (Piano / Guitar / Drum)
	if instType == "PIANO" then
		-- Keyboard Accent Block (Tuts Piano Gading & Hitam)
		local pianoKeys = Instance.new("Part")
		pianoKeys.Name = "PianoAccent"
		pianoKeys.Shape = Enum.PartType.Block
		pianoKeys.Size = Vector3.new(0.3 * scale, 0.7 * scale, 0.26 * scale)
		pianoKeys.Color = (rodData.tier == "LEGENDARY") and Color3.fromRGB(220, 240, 255) or Color3.fromRGB(245, 245, 250)
		pianoKeys.Material = Enum.Material.SmoothPlastic
		pianoKeys.CanCollide = false
		pianoKeys.CFrame = handle.CFrame * CFrame.new(0, 0.4 * scale, 0.1 * scale)
		pianoKeys.Parent = tool

		local wcKeys = Instance.new("WeldConstraint")
		wcKeys.Part0 = handle
		wcKeys.Part1 = pianoKeys
		wcKeys.Parent = handle

	elseif instType == "GUITAR" then
		-- Fretboard Plate & Headstock Bridge (Gitar Petikan)
		local fretPlate = Instance.new("Part")
		fretPlate.Name = "GuitarFretPlate"
		fretPlate.Shape = Enum.PartType.Block
		fretPlate.Size = Vector3.new(0.22 * scale, 1.2 * scale, 0.12 * scale)
		fretPlate.Color = rodData.accentColor or Color3.fromRGB(245, 158, 11)
		fretPlate.Material = (rodData.tier == "SUPER_RARE" or rodData.tier == "LEGENDARY") and Enum.Material.Neon or Enum.Material.Metal
		fretPlate.CanCollide = false
		fretPlate.CFrame = shaft.CFrame * CFrame.new(0, -0.8 * scale, 0.08 * scale)
		fretPlate.Parent = tool

		local wcFret = Instance.new("WeldConstraint")
		wcFret.Part0 = handle
		wcFret.Part1 = fretPlate
		wcFret.Parent = handle

	elseif instType == "DRUM" then
		-- Drum Cymbal / Ring Pad Perkusi
		local drumRing = Instance.new("Part")
		drumRing.Name = "DrumRingPad"
		drumRing.Shape = Enum.PartType.Cylinder
		drumRing.Size = Vector3.new(0.12 * scale, 0.75 * scale, 0.75 * scale)
		drumRing.Color = rodData.accentColor or Color3.fromRGB(239, 68, 68)
		drumRing.Material = (rodData.tier == "SUPER_RARE" or rodData.tier == "MYTHIC") and Enum.Material.Neon or Enum.Material.Metal
		drumRing.CanCollide = false
		drumRing.CFrame = shaft.CFrame * CFrame.new(0, 0.5 * scale, 0) * CFrame.Angles(0, 0, math.rad(90))
		drumRing.Parent = tool

		local wcDrum = Instance.new("WeldConstraint")
		wcDrum.Part0 = handle
		wcDrum.Part1 = drumRing
		wcDrum.Parent = handle
	end

	-- Efek Partikel Glow untuk Joran Rarity Tinggi (SUPER_RARE, LEGENDARY, MYTHIC)
	if rodData.tier == "MYTHIC" or rodData.tier == "LEGENDARY" or rodData.tier == "SUPER_RARE" then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "RodAura"
		pe.Texture = "rbxassetid://243098098"
		pe.Color = ColorSequence.new(rodData.color, rodData.accentColor)
		pe.LightEmission = (rodData.tier == "MYTHIC") and 1.0 or 0.75
		pe.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25 * scale),
			NumberSequenceKeypoint.new(1, 0.05 * scale),
		})
		pe.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		pe.Lifetime = NumberRange.new(0.4, 0.9)
		pe.Rate = (rodData.tier == "MYTHIC") and 20 or 12
		pe.Speed = NumberRange.new(0.5, 1.8)
		pe.Parent = tip
	end

	return tool
end

-- Menghapus tool joran lama yang ada di Character / Backpack
local function removeExistingRods(player)
	local char = player.Character
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsRod") == true or item.Name:lower():find("rod") or item.Name:lower():find("pancing")) then
				item:Destroy()
			end
		end
	end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsRod") == true or item.Name:lower():find("rod") or item.Name:lower():find("pancing")) then
				item:Destroy()
			end
		end
	end
end

function EconomyService.SpawnEquippedRod(player)
	if not player or not player:IsA("Player") then return nil end

	local pData = PlayerDataService.Get(player)
	local equippedRodId = (pData and pData.equippedRod) or "StarterRod"
	local rodData = EconomyConfig.GetRod(equippedRodId)

	if pData then
		pData.equippedInstrument = rodData.instrumentType or InstrumentDefinitions.GetInstrumentTypeForRod(equippedRodId)
	end

	removeExistingRods(player)

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return nil end

	local tool = EconomyService.CreateRodTool(rodData)
	tool.Parent = backpack

	return tool
end

function EconomyService.BuyRod(player, rodId)
	if not player then return false, "Player tidak valid" end

	local rodData = EconomyConfig.RODS_BY_ID[rodId]
	if not rodData then
		RemoteContract.Server.ShopTransactionFailed(player, "Joran tidak ditemukan di katalog!")
		return false, "Joran tidak ditemukan"
	end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, "Data tidak ditemukan" end

	-- 1. Cek kepemilikan
	pData.unlockedRods = pData.unlockedRods or { "StarterRod" }
	if table.find(pData.unlockedRods, rodId) then
		RemoteContract.Server.ShopTransactionFailed(player, "Kamu sudah memiliki joran ini!")
		return false, "Sudah dimiliki"
	end

	-- 2. Cek Level Requirement
	local playerLevel = pData.level or 1
	if playerLevel < rodData.levelReq then
		local msg = string.format("Level kamu (%d) belum mencukupi! Butuh Level %d.", playerLevel, rodData.levelReq)
		RemoteContract.Server.ShopTransactionFailed(player, msg)
		RemoteContract.Server.Notify(player, "⚠️ " .. msg)
		return false, "Level kurang"
	end

	-- 3. Cek Koin & Deduksi
	local price = rodData.price or 0
	if price > 0 then
		local success, newCoins = EconomyService.DeductCoins(player, price, "Beli Joran: " .. rodData.name)
		if not success then
			local msg = string.format("Koin kamu tidak cukup (%d / %d Koin)!", pData.coins or 0, price)
			RemoteContract.Server.ShopTransactionFailed(player, msg)
			RemoteContract.Server.Notify(player, "⚠️ " .. msg)
			return false, "Koin tidak cukup"
		end
	end

	-- 4. Tambahkan ke Unlocked Rods & Auto-Equip
	table.insert(pData.unlockedRods, rodId)
	pData.equippedRod = rodId
	pData.equippedInstrument = rodData.instrumentType or InstrumentDefinitions.GetInstrumentTypeForRod(rodId)

	EconomyService.SpawnEquippedRod(player)

	RemoteContract.Server.ShopTransactionSuccess(player, "ROD", rodId, rodData.name, pData.coins)
	RemoteContract.Server.RodEquipped(player, rodId, rodData)
	RemoteContract.Server.Notify(player, string.format("🎉 Selamat! Kamu berhasil membeli & menggunakan %s (%s)!", rodData.name, rodData.badge or "JORAN"))

	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)

	return true, rodData
end

function EconomyService.EquipRod(player, rodId)
	if not player then return false, "Player tidak valid" end

	local rodData = EconomyConfig.RODS_BY_ID[rodId]
	if not rodData then
		return false, "Joran tidak ditemukan"
	end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, "Data tidak ditemukan" end

	pData.unlockedRods = pData.unlockedRods or { "StarterRod" }
	if not table.find(pData.unlockedRods, rodId) then
		RemoteContract.Server.Notify(player, "⚠️ Kamu belum memiliki joran ini!")
		return false, "Belum dimiliki"
	end

	pData.equippedRod = rodId
	pData.equippedInstrument = rodData.instrumentType or InstrumentDefinitions.GetInstrumentTypeForRod(rodId)

	EconomyService.SpawnEquippedRod(player)

	RemoteContract.Server.RodEquipped(player, rodId, rodData)
	RemoteContract.Server.Notify(player, string.format("🎣 Berhasil memasang %s (%s | +%d Luck)!", rodData.name, rodData.badge or "JORAN", rodData.luckBonus))
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)

	return true, rodData
end

-- ============ 3. MANAJEMEN & TOKO UMPAN (BAITS) ============

function EconomyService.BuyBait(player, baitId, isPack)
	if not player then return false, "Player tidak valid" end

	local baitData = EconomyConfig.BAITS_BY_ID[baitId]
	if not baitData then
		RemoteContract.Server.ShopTransactionFailed(player, "Umpan tidak ditemukan di katalog!")
		return false, "Umpan tidak ditemukan"
	end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, "Data tidak ditemukan" end

	local quantity = isPack and (baitData.packQuantity or 10) or 1
	local cost = isPack and (baitData.pricePack or 100) or (baitData.priceSingle or 15)

	local success, newCoins = EconomyService.DeductCoins(player, cost, string.format("Beli Umpan %s x%d", baitData.name, quantity))
	if not success then
		local msg = string.format("Koin tidak mencukupi untuk membeli %s (%d / %d Koin)!", baitData.name, pData.coins or 0, cost)
		RemoteContract.Server.ShopTransactionFailed(player, msg)
		RemoteContract.Server.Notify(player, "⚠️ " .. msg)
		return false, "Koin tidak cukup"
	end

	pData.baits = pData.baits or {}
	pData.baits[baitId] = (pData.baits[baitId] or 0) + quantity

	-- Jika belum ada umpan terpasang, pasang umpan ini secara otomatis
	if not pData.equippedBait or (pData.baits[pData.equippedBait] or 0) <= 0 then
		pData.equippedBait = baitId
	end

	RemoteContract.Server.ShopTransactionSuccess(player, "BAIT", baitId, string.format("+%d %s", quantity, baitData.name), pData.coins)
	RemoteContract.Server.BaitUpdated(player, pData.equippedBait, pData.baits)
	RemoteContract.Server.Notify(player, string.format("🪱 Berhasil membeli %s x%d!", baitData.name, quantity))

	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)

	return true, pData.baits[baitId]
end

function EconomyService.EquipBait(player, baitId)
	if not player then return false, "Player tidak valid" end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, "Data tidak ditemukan" end

	pData.baits = pData.baits or {}

	if not baitId or baitId == "NONE" or baitId == "" then
		pData.equippedBait = nil
		RemoteContract.Server.BaitUpdated(player, nil, pData.baits)
		RemoteContract.Server.Notify(player, "🎣 Melepas umpan yang terpasang.")
		return true, nil
	end

	local count = pData.baits[baitId] or 0
	if count <= 0 then
		RemoteContract.Server.Notify(player, "⚠️ Kamu tidak memiliki stok umpan ini!")
		return false, "Stok habis"
	end

	local baitData = EconomyConfig.BAITS_BY_ID[baitId]
	pData.equippedBait = baitId

	RemoteContract.Server.BaitUpdated(player, pData.equippedBait, pData.baits)
	RemoteContract.Server.Notify(player, string.format("🪱 Memasang %s (+%d Luck | Sisa: %d)!", baitData and baitData.name or baitId, baitData and baitData.luckBonus or 0, count))
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)

	return true, baitData
end

function EconomyService.ConsumeEquippedBait(player)
	if not player then return nil end

	local pData = PlayerDataService.Get(player)
	if not pData or not pData.equippedBait then return nil end

	local baitId = pData.equippedBait
	pData.baits = pData.baits or {}
	local count = pData.baits[baitId] or 0

	if count <= 0 then
		pData.equippedBait = nil
		RemoteContract.Server.BaitUpdated(player, nil, pData.baits)
		return nil
	end

	pData.baits[baitId] = count - 1
	local remaining = pData.baits[baitId]

	if remaining <= 0 then
		pData.equippedBait = nil
		RemoteContract.Server.Notify(player, string.format("⚠️ Stok umpan %s telah habis!", baitId))
	end

	RemoteContract.Server.BaitUpdated(player, pData.equippedBait, pData.baits)
	local baitData = EconomyConfig.BAITS_BY_ID[baitId]
	return baitData
end

-- ============ 4. PENINGKATAN KAPASITAS TAS (BAG UPGRADE) ============

function EconomyService.UpgradeBag(player)
	if not player then return false, "Player tidak valid" end

	local pData = PlayerDataService.Get(player)
	if not pData then return false, "Data tidak ditemukan" end

	local currentTier = pData.bagUpgradeTier or 0
	local nextUpgrade = EconomyConfig.GetNextBagUpgrade(currentTier)

	if not nextUpgrade then
		RemoteContract.Server.ShopTransactionFailed(player, "Kapasitas tas kamu sudah mencapai tingkat maksimum!")
		RemoteContract.Server.Notify(player, "🎒 Tas kamu sudah mencapai Tier Maksimal!")
		return false, "Sudah Max"
	end

	-- 1. Cek Level Requirement
	local playerLevel = pData.level or 1
	if playerLevel < nextUpgrade.levelReq then
		local msg = string.format("Level kamu (%d) belum mencukupi! Butuh Level %d untuk upgrade tas.", playerLevel, nextUpgrade.levelReq)
		RemoteContract.Server.ShopTransactionFailed(player, msg)
		RemoteContract.Server.Notify(player, "⚠️ " .. msg)
		return false, "Level kurang"
	end

	-- 2. Cek Koin & Deduksi
	local success, newCoins = EconomyService.DeductCoins(player, nextUpgrade.price, "Upgrade Tas: " .. nextUpgrade.name)
	if not success then
		local msg = string.format("Koin kamu tidak cukup (%d / %d Koin)!", pData.coins or 0, nextUpgrade.price)
		RemoteContract.Server.ShopTransactionFailed(player, msg)
		RemoteContract.Server.Notify(player, "⚠️ " .. msg)
		return false, "Koin tidak cukup"
	end

	pData.bagUpgradeTier = nextUpgrade.tier
	pData.maxInventorySlots = nextUpgrade.totalSlots

	RemoteContract.Server.ShopTransactionSuccess(player, "BAG", tostring(nextUpgrade.tier), nextUpgrade.name, pData.coins)
	RemoteContract.Server.BagUpgraded(player, nextUpgrade.tier, nextUpgrade.totalSlots, pData.coins)
	RemoteContract.Server.Notify(player, string.format("🎉 Berhasil memperluas tas! Sekarang kamu memiliki %d Slot Inventaris.", nextUpgrade.totalSlots))

	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)

	return true, nextUpgrade
end

-- ============ 5. SHOP CATALOG DISPATCHER ============

function EconomyService.GetShopCatalog(player)
	local pData = PlayerDataService.Get(player)
	local pLevel = pData and pData.level or 1
	local pCoins = pData and pData.coins or 0
	local unlockedRods = pData and pData.unlockedRods or { "StarterRod" }
	local equippedRod = pData and pData.equippedRod or "StarterRod"
	local equippedBait = pData and pData.equippedBait
	local baits = pData and pData.baits or {}
	local bagTier = pData and pData.bagUpgradeTier or 0
	local maxSlots = pData and pData.maxInventorySlots or 35

	-- Format data joran
	local rodsList = {}
	for _, rod in ipairs(EconomyConfig.RODS) do
		local isOwned = table.find(unlockedRods, rod.id) ~= nil
		local isEquipped = (equippedRod == rod.id)
		local canBuy = (not isOwned) and (pLevel >= rod.levelReq) and (pCoins >= rod.price)

		table.insert(rodsList, {
			id = rod.id,
			name = rod.name,
			levelReq = rod.levelReq,
			price = rod.price,
			luckBonus = rod.luckBonus,
			castPowerMultiplier = rod.castPowerMultiplier,
			reelSpeedMultiplier = rod.reelSpeedMultiplier,
			description = rod.description,
			tier = rod.tier,
			badge = rod.badge,
			isOwned = isOwned,
			isEquipped = isEquipped,
			canBuy = canBuy,
		})
	end

	-- Format data umpan
	local baitsList = {}
	for _, bait in ipairs(EconomyConfig.BAITS) do
		local currentStock = baits[bait.id] or 0
		local isEquipped = (equippedBait == bait.id)

		table.insert(baitsList, {
			id = bait.id,
			name = bait.name,
			icon = bait.icon,
			priceSingle = bait.priceSingle,
			packQuantity = bait.packQuantity,
			pricePack = bait.pricePack,
			luckBonus = bait.luckBonus,
			description = bait.description,
			tier = bait.tier,
			badge = bait.badge,
			stock = currentStock,
			isEquipped = isEquipped,
			canBuySingle = (pCoins >= bait.priceSingle),
			canBuyPack = (pCoins >= bait.pricePack),
		})
	end

	local nextBag = EconomyConfig.GetNextBagUpgrade(bagTier)

	return {
		coins = pCoins,
		level = pLevel,
		equippedRod = equippedRod,
		equippedBait = equippedBait,
		bagTier = bagTier,
		maxSlots = maxSlots,
		nextBagUpgrade = nextBag,
		canUpgradeBag = nextBag and (pLevel >= nextBag.levelReq) and (pCoins >= nextBag.price) or false,
		rods = rodsList,
		baits = baitsList,
	}
end

return EconomyService
