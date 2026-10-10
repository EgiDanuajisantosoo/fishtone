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
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local FishingSessionService = require(script.Parent:WaitForChild("FishingSessionService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local AntiExploitService = require(script.Parent:WaitForChild("AntiExploitService"))
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

-- ============ SPAWN EQUIPPED ROD OTOMATIS SAAT SPAWN ============
local function onCharacterAdded(character, player)
	task.defer(function()
		task.wait(0.2)
		if player and player.Parent and character and character.Parent then
			local rod = getRodTool(player)
			if not rod then
				EconomyService.SpawnEquippedRod(player)
			end
		end
	end)
end

-- ============ DEVELOPER / STUDIO TESTING CHAT COMMANDS ============
local function setupChatCommands(player)
	player.Chatted:Connect(function(msg)
		if not RunService:IsStudio() and player.UserId ~= game.CreatorId then return end
		local parts = string.split(string.lower(msg), " ")
		local cmd = parts[1]
		local arg1 = tonumber(parts[2])

		if cmd == "/setlevel" or cmd == "!setlevel" then
			local lvl = arg1 or 10
			PlayerDataService.SetLevel(player, lvl)
			RemoteContract.Server.Notify(player, string.format("⚡ [TESTING] Level diset ke Level %d!", lvl))
		elseif cmd == "/addlevel" or cmd == "!addlevel" then
			local add = arg1 or 1
			local pData = PlayerDataService.Get(player)
			local newLvl = (pData and pData.level or 1) + add
			PlayerDataService.SetLevel(player, newLvl)
			RemoteContract.Server.Notify(player, string.format("⚡ [TESTING] +%d Level! Sekarang Level %d", add, newLvl))
		elseif cmd == "/addexp" or cmd == "!addexp" then
			local exp = arg1 or 2000
			PlayerDataService.AddExp(player, exp)
			RemoteContract.Server.Notify(player, string.format("⚡ [TESTING] +%d EXP berhasil ditambahkan!", exp))
		elseif cmd == "/addcoins" or cmd == "!addcoins" then
			local coins = arg1 or 10000
			PlayerDataService.AddCoins(player, coins)
			RemoteContract.Server.Notify(player, string.format("⚡ [TESTING] +%d Koin berhasil ditambahkan!", coins))
		elseif cmd == "/unlockall" or cmd == "!unlockall" then
			local pData = PlayerDataService.Get(player)
			if pData then
				pData.unlockedRods = {
					"StarterRod", "HarmonicTuningRod", "CrystalSonataRod",
					"BambooRod", "CarbonFiberRod", "AbyssalTridentRod",
					"TribalPercussionRod", "SynthwaveDrumRod", "CelestialMelodyRod",
				}
				pData.unlockedInstruments = { "PIANO", "GUITAR", "DRUM" }
				RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
				RemoteContract.Server.Notify(player, "⚡ [TESTING] Semua joran Piano, Gitar & Drum telah terbuka!")
			end
		end
	end)
end

local function onPlayerAdded(player)
	setupChatCommands(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end)
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	AntiExploitService.ClearPlayer(player)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerAdded(p)
	end)
end

-- Handler Komunikasi Client-Server
if remote then
	remote.OnServerEvent:Connect(function(player, action, arg1, arg2, arg3)
		if not player or not player:IsA("Player") then return end

		-- Validasi Rate Limiting & Proteksi Flood Remote (FISH-039 Anti-Exploit)
		local allowed, retryAfter = AntiExploitService.CheckRateLimit(player, action)
		if not allowed then
			AntiExploitService.LogViolation(player, "RATE_LIMIT_EXCEEDED", string.format("Action '%s' throttled (Retry-After: %.2fs)", tostring(action), retryAfter or 0))
			RemoteContract.Server.Notify(player, "⚠️ Terlalu banyak permintaan! Harap tunggu sebentar.")
			return
		end

		local pData = PlayerDataService.Get(player)

		-- 1. Permintaan Memulai Sesi Memancing (StartFishing)
		if action == RemoteContract.C2S.START_FISHING then
			if not hasFishingRod(player) then
				EconomyService.SpawnEquippedRod(player)
			end

			local capInfo = InventoryService.GetCapacityInfo(player)
			if capInfo.isFull then
				RemoteContract.Server.Notify(player, string.format("🎒 Inventory kamu penuh (%d/%d slot)! Jual tangkapanmu ke pedagang atau tingkatkan kapasitas tas.", capInfo.current, capInfo.max))
				return
			end

			local waterPos = arg1
			local castQuality = arg2
			local castPower = arg3
			local rodLuck = getRodLuck(player)

			local session, err = FishingSessionService.CreateSession(player, waterPos, castQuality, castPower, rodLuck)
			if not session then
				warn("[FishingServer] Gagal membuat sesi memancing untuk", player.Name, ":", tostring(err))
				RemoteContract.Server.Notify(player, "❌ " .. tostring(err or "Gagal memulai sesi memancing"))
				return
			end

			print(string.format("[FishingServer] 🎣 Sesi Memancing Dimulai: %s | Player: %s | Quality: %s | Wait: %.1fs", session.sessionId, player.Name, session.castQuality, session.waitDuration))
			RemoteContract.Server.SessionStarted(
				player,
				session.sessionId,
				session.waitDuration,
				session.castQuality
			)
			return
		end

		-- 2. Pengiriman Hasil Tangkapan Rhythm (SubmitCatch) - SERVER AUTHORITATIVE
		if action == RemoteContract.C2S.SUBMIT_CATCH then
			local sessionId = arg1
			local metrics = arg2
			print(string.format("[FishingServer] 📥 Menerima SubmitCatch untuk Sesi: %s dari Player: %s", tostring(sessionId), player.Name))

			local fishData, rewardInfo, updatedData = FishingSessionService.ValidateAndComplete(player, sessionId, metrics)
			if not fishData then
				warn(string.format("[FishingServer] ❌ Validasi tangkapan gagal untuk %s: %s", player.Name, tostring(rewardInfo or "Invalid session")))
				RemoteContract.Server.Notify(player, "❌ " .. tostring(rewardInfo or "Sesi memancing tidak valid."))
				return
			end

			-- Tambahkan Item 3D ke Inventory Player via InventoryService
			local itemTool, itemErr = InventoryService.AddItem(player, fishData)
			if itemTool then
				print(string.format("[FishingServer] 🐟 Berhasil menambah item '%s' ke Backpack %s!", itemTool.Name, player.Name))
			else
				warn(string.format("[FishingServer] ⚠️ Gagal menambah item ke Backpack %s: %s", player.Name, tostring(itemErr)))
			end

			print(string.format("[FishingServer] ⭐ Catch Success! Ikan: %s (%s) | Koin: +%d | EXP: +%d | Player: %s", fishData.name, fishData.rarity, rewardInfo.coins or 0, rewardInfo.exp or 0, player.Name))
			RemoteContract.Server.CatchSuccess(player, fishData, rewardInfo, updatedData, updatedData.pity)

			-- Siarkan pengumuman server-wide jika tangkapan langka / mutasi (FISH-038)
			local r = tostring(fishData.rarity or "COMMON"):upper()
			if r == "LEGENDARY" or r == "MYTHIC" or r == "SPECIAL" or fishData.isMutated == true then
				RemoteContract.Server.BroadcastCatch(player, fishData)
			end
			return
		end

		-- 3. Menjual Satu Ikan/Item Tertentu (SellFish) - Terproteksi Item Lock
		if action == RemoteContract.C2S.SELL_FISH then
			InventoryService.SellItem(player, arg1)
			return
		end

		-- 4. Menjual Semua Ikan di Inventory (SellAllFish) - Melewati Item Terkunci
		if action == RemoteContract.C2S.SELL_ALL_FISH then
			InventoryService.SellAll(player)
			return
		end

		-- 5. Menjual Berdasarkan Kategori Tertentu (SellCategory)
		if action == RemoteContract.C2S.SELL_CATEGORY then
			InventoryService.SellCategory(player, arg1)
			return
		end

		-- 6. Mengunci / Membuka Kunci Item (ToggleLockItem)
		if action == RemoteContract.C2S.TOGGLE_LOCK_ITEM then
			InventoryService.ToggleLockItem(player, arg1)
			return
		end

		-- 7. Pembatalan Sesi (CancelFishing)
		if action == RemoteContract.C2S.CANCEL_FISHING then
			local sessionId = arg1
			FishingSessionService.CancelSession(player, sessionId)
			return
		end

		-- 8. Get Player Data
		if action == RemoteContract.C2S.GET_PLAYER_DATA then
			RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
			return
		end

		-- 9. Toko & Ekonomi: Pembelian Joran Pancing (BuyRod) (FISH-024)
		if action == RemoteContract.C2S.BUY_ROD then
			EconomyService.BuyRod(player, arg1)
			return
		end

		-- 10. Toko & Ekonomi: Memasang Joran Pancing (EquipRod) (FISH-024)
		if action == RemoteContract.C2S.EQUIP_ROD then
			EconomyService.EquipRod(player, arg1)
			return
		end

		-- 11. Toko & Ekonomi: Pembelian Umpan (BuyBait) (FISH-024)
		if action == RemoteContract.C2S.BUY_BAIT then
			EconomyService.BuyBait(player, arg1, arg2 == true)
			return
		end

		-- 12. Toko & Ekonomi: Memasang Umpan (EquipBait) (FISH-024)
		if action == RemoteContract.C2S.EQUIP_BAIT then
			EconomyService.EquipBait(player, arg1)
			return
		end

		-- 13. Toko & Ekonomi: Upgrade Kapasitas Tas (UpgradeBag) (FISH-024)
		if action == RemoteContract.C2S.UPGRADE_BAG then
			EconomyService.UpgradeBag(player)
			return
		end

		-- 14. Toko & Ekonomi: Request Katalog Toko (GetShopCatalog) (FISH-024)
		if action == RemoteContract.C2S.GET_SHOP_CATALOG then
			local catalog = EconomyService.GetShopCatalog(player)
			RemoteContract.Server.ShopCatalogData(player, catalog)
			return
		end

		-- 15. Tutorial Pemula: Selesaikan Langkah Tutorial (FISH-033)
		if action == RemoteContract.C2S.COMPLETE_TUTORIAL_STEP then
			PlayerDataService.CompleteTutorialStep(player, arg1)
			return
		end

		-- 16. Tutorial Pemula: Selesaikan Keseluruhan Tutorial & Klaim Reward (FISH-033)
		if action == RemoteContract.C2S.FINISH_TUTORIAL then
			PlayerDataService.FinishTutorial(player)
			return
		end

		-- 17. Tutorial Pemula: Lewati Tutorial (FISH-033)
		if action == RemoteContract.C2S.SKIP_TUTORIAL then
			PlayerDataService.SkipTutorial(player)
			return
		end
	end)
else
	warn("FishingServer: FishingRemote tidak ditemukan di ReplicatedStorage")
end

-- ============ PROXIMITY PROMPT GLOBAL HANDLER (STUDIO MAP INTEGRATION) ============
-- Mendengarkan secara universal interaksi ProximityPrompt yang dibuat manual di Roblox Studio:
-- 1. Jual Ikan: Nama prompt atau actionText mengandung "sell", "jual", "merchant", "pedagang"
-- 2. Toko/Shop: Nama prompt atau actionText mengandung "shop", "toko", "beli", "rod", "bait"
local ProximityPromptService = game:GetService("ProximityPromptService")

-- Fungsi otomatis untuk memindahkan ProximityPrompt dari Model ke BasePart agar muncul di layar
local function sanitizePrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end

	-- Jika ProximityPrompt ditaruh langsung sebagai anak Model, pindahkan ke BasePart (Torso/HumanoidRootPart/Head)
	if prompt.Parent and prompt.Parent:IsA("Model") then
		local model = prompt.Parent
		local targetPart = model.PrimaryPart 
			or model:FindFirstChild("HumanoidRootPart") 
			or model:FindFirstChild("Torso") 
			or model:FindFirstChild("UpperTorso") 
			or model:FindFirstChild("Head") 
			or model:FindFirstChildWhichIsA("BasePart")

		if targetPart then
			prompt.Parent = targetPart
		end
	end

	-- Optimasi visibilitas prompt (tidak terhalang dinding/stand toko)
	if prompt.MaxActivationDistance < 12 then
		prompt.MaxActivationDistance = 14
	end
	prompt.RequiresLineOfSight = false
end

-- Scan semua prompt yang sudah ada di workspace
for _, desc in ipairs(workspace:GetDescendants()) do
	if desc:IsA("ProximityPrompt") then
		sanitizePrompt(desc)
	end
end

-- Dengarkan prompt baru yang ditambahkan di runtime/Studio
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then
		task.defer(function()
			sanitizePrompt(desc)
		end)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local pName = prompt.Name:lower()
	local pAction = prompt.ActionText:lower()
	local pObject = prompt.ObjectText:lower()
	local parentName = (prompt.Parent and prompt.Parent.Name:lower()) or ""
	local modelName = (prompt.Parent and prompt.Parent:IsA("Model") and prompt.Parent.Name:lower())
		or (prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent:IsA("Model") and prompt.Parent.Parent.Name:lower())
		or ""

	local allText = string.format("%s %s %s %s %s", pName, pAction, pObject, parentName, modelName)

	-- A. Penjualan Ikan & Loot (Toko Ikan / Tukang Ikan / Merchant / Jual Ikan)
	if allText:find("sell") or allText:find("jual") or allText:find("merchant") or allText:find("pedagang")
		or allText:find("ikan") or allText:find("lapak") or allText:find("pasar") then
		local catalog = EconomyService.GetShopCatalog(player)
		catalog.openModal = true
		catalog.initialTab = "SELL"
		RemoteContract.Server.ShopCatalogData(player, catalog)

	-- B. Toko Peralatan Pancing (Toko Pancing / Shop / Beli Joran / Umpan)
	elseif allText:find("shop") or allText:find("toko") or allText:find("bait") or allText:find("rod")
		or allText:find("beli") or allText:find("buy") or allText:find("pancing") or allText:find("joran") then
		local catalog = EconomyService.GetShopCatalog(player)
		catalog.openModal = true
		catalog.initialTab = "RODS"
		RemoteContract.Server.ShopCatalogData(player, catalog)
	else
		-- Fallback general shop
		local catalog = EconomyService.GetShopCatalog(player)
		catalog.openModal = true
		catalog.initialTab = "RODS"
		RemoteContract.Server.ShopCatalogData(player, catalog)
	end
end)

