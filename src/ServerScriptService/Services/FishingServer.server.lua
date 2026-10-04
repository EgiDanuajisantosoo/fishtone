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
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local FishingSessionService = require(script.Parent.FishingSessionService)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)
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

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end)
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerAdded(p)
	end)
end

-- Handler Komunikasi Client-Server
if remote then
	remote.OnServerEvent:Connect(function(player, action, arg1, arg2, arg3)
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

			local fishData, rewardInfo, updatedData = FishingSessionService.ValidateAndComplete(player, sessionId, metrics)
			if not fishData then
				RemoteContract.Server.Notify(player, "❌ " .. tostring(rewardInfo or "Sesi memancing tidak valid."))
				return
			end

			-- Tambahkan Item 3D ke Inventory Player via InventoryService
			InventoryService.AddItem(player, fishData)

			RemoteContract.Server.CatchSuccess(player, fishData, rewardInfo, updatedData, updatedData.pity)
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
			InventoryService.SellAll(player, arg1)
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
		InventoryService.SellAll(player)
	elseif pName:find("shop") or pName:find("toko") or pAction:find("beli") or pAction:find("shop") then
		local catalog = EconomyService.GetShopCatalog(player)
		RemoteContract.Server.ShopCatalogData(player, catalog)
	end
end)

