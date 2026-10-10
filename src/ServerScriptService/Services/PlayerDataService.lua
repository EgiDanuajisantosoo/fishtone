--[[
	PlayerDataService (ModuleScript)
	FISH!TUNE — Player Data & DataStore Service (FISH-004 / FISH-005)

	Layanan Sentral Manajemen Data & Persistensi Pemain:
	1. DataStore persistence dengan key berbasis UserId.
	2. Fallback in-memory yang aman jika DataStore dinonaktifkan di Studio.
	3. Integrasi penuh dengan PlayerDataSchema (Reconciliation, Migration & Invariant Validation).
	4. Auto-save berkala dan graceful shutdown (game:BindToClose).
	5. Integrasi mulus dengan Leaderstats dan RemoteContract.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local PlayerDataSchema = require(Shared:WaitForChild("Config"):WaitForChild("PlayerDataSchema"))

-- Lazy-load InventoryService untuk mencegah circular dependency
local InventoryService = nil
local function getInventoryService()
	if not InventoryService then
		local ok, mod = pcall(function()
			return require(script.Parent:WaitForChild("InventoryService"))
		end)
		if ok and mod then
			InventoryService = mod
		end
	end
	return InventoryService
end

local PlayerDataService = {}

-- ============ CONFIGURATION ============
local DATASTORE_NAME = "FishTunePlayerData_v1"
local AUTOSAVE_INTERVAL = 180 -- Auto-save setiap 3 menit
local MAX_RETRIES = 3

local dataStore = nil
local dataStoreAvailable = false

local ok, ds = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)

if ok and ds then
	dataStore = ds
	dataStoreAvailable = true
else
	warn("[PlayerDataService] DataStore tidak tersedia / nonaktif di Studio. Menggunakan in-memory cache.")
end

-- ============ IN-MEMORY CACHE ============
local profiles = {} -- [player.UserId] = profileTable
local isSaving = {} -- [player.UserId] = boolean

-- ============ PROFILE GETTERS ============
function PlayerDataService.Get(player)
	if not player or not player:IsA("Player") then return nil end
	local userId = player.UserId
	if not profiles[userId] then
		profiles[userId] = PlayerDataSchema.CreateDefault()
	end
	return profiles[userId]
end

function PlayerDataService.GetByUserId(userId)
	return profiles[userId]
end

-- ============ LEADERSTATS SYNC ============
function PlayerDataService.SyncLeaderstats(player)
	local pData = PlayerDataService.Get(player)
	if not pData then return end

	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"

		local lvlVal = Instance.new("IntValue")
		lvlVal.Name = "Level"
		lvlVal.Value = pData.level or 1
		lvlVal.Parent = stats

		local coinVal = Instance.new("IntValue")
		coinVal.Name = "Koin"
		coinVal.Value = pData.coins or 0
		coinVal.Parent = stats

		local fishVal = Instance.new("IntValue")
		fishVal.Name = "Ikan"
		fishVal.Value = pData.totalFish or 0
		fishVal.Parent = stats

		local expVal = Instance.new("IntValue")
		expVal.Name = "Exp"
		expVal.Value = pData.exp or 0
		expVal.Parent = stats

		stats.Parent = player
	else
		local lvlVal = stats:FindFirstChild("Level")
		if lvlVal then lvlVal.Value = pData.level or 1 end

		local coinVal = stats:FindFirstChild("Koin")
		if coinVal then coinVal.Value = pData.coins or 0 end

		local fishVal = stats:FindFirstChild("Ikan")
		if fishVal then fishVal.Value = pData.totalFish or 0 end

		local expVal = stats:FindFirstChild("Exp")
		if expVal then expVal.Value = pData.exp or 0 end
	end
end

-- ============ DATA MUTATORS ============
function PlayerDataService.AddCoins(player, amount)
	local pData = PlayerDataService.Get(player)
	if not pData then return end
	pData.coins = math.max(0, (pData.coins or 0) + amount)
	if pData.stats then
		pData.stats.totalCoinsEarned = (pData.stats.totalCoinsEarned or 0) + math.max(0, amount)
	end
	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
end

function PlayerDataService.AddFish(player, amount)
	local pData = PlayerDataService.Get(player)
	if not pData then return end
	pData.totalFish = (pData.totalFish or 0) + (amount or 1)
	PlayerDataService.SyncLeaderstats(player)
end

function PlayerDataService.UnlockInstrument(player, instrumentType)
	local pData = PlayerDataService.Get(player)
	if not pData then return false end
	if not InstrumentDefinitions.IsValidInstrumentType(instrumentType) then return false end

	pData.unlockedInstruments = pData.unlockedInstruments or { "PIANO" }
	if not table.find(pData.unlockedInstruments, instrumentType) then
		table.insert(pData.unlockedInstruments, instrumentType)
		local instData = InstrumentDefinitions.GetInstrumentData(instrumentType)
		RemoteContract.Server.InstrumentUnlocked(player, instrumentType, instData)
		RemoteContract.Server.Notify(player, string.format("🎉 %s TERBUKA! Kamu sekarang dapat memainkan minigame %s!", instData.badge or instrumentType, instData.name or instrumentType))
		RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
		return true
	end
	return false
end

function PlayerDataService.IsInstrumentUnlocked(player, instrumentType)
	local pData = PlayerDataService.Get(player)
	if not pData then return instrumentType == "PIANO" end
	pData.unlockedInstruments = pData.unlockedInstruments or { "PIANO" }
	return table.find(pData.unlockedInstruments, instrumentType) ~= nil
end

-- ============ TUTORIAL MUTATORS (FISH-033) ============
function PlayerDataService.CompleteTutorialStep(player, step)
	local pData = PlayerDataService.Get(player)
	if not pData then return end
	local targetStep = tonumber(step) or 0
	if (pData.tutorialStep or 0) < targetStep then
		pData.tutorialStep = targetStep
		RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
	end
end

function PlayerDataService.FinishTutorial(player)
	local pData = PlayerDataService.Get(player)
	if not pData then return end

	if not pData.tutorialCompleted then
		pData.tutorialCompleted = true
		pData.tutorialStep = 5

		-- Hadiah penyelesaian tutorial: 100 Koin + 5 Umpan Cacing Starter
		local rewardCoins = 100
		pData.coins = (pData.coins or 0) + rewardCoins

		pData.baits = pData.baits or {}
		pData.baits.StandardWorm = (pData.baits.StandardWorm or 0) + 5

		PlayerDataService.SyncLeaderstats(player)
		RemoteContract.Server.TutorialCompleted(player, {
			coins = rewardCoins,
			baitName = "StandardWorm",
			baitCount = 5,
		})
		RemoteContract.Server.Notify(player, "🎉 Selamat! Kamu telah menyelesaikan Tutorial Dasar FISH!TUNE (+100 Koin & +5 Umpan)!")
		RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
		return true
	end
	return false
end

function PlayerDataService.SkipTutorial(player)
	local pData = PlayerDataService.Get(player)
	if not pData then return end

	pData.tutorialCompleted = true
	pData.tutorialStep = 5
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
	RemoteContract.Server.Notify(player, "ℹ️ Tutorial dilewati. Buka tombol [❓ PANDUAN] di HUD kapan saja untuk melihat panduan bermain!")
end

function PlayerDataService.AddExp(player, amount)
	local pData = PlayerDataService.Get(player)
	if not pData then return false, 1 end
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount <= 0 then return false, pData.level or 1 end

	local oldLevel = pData.level or 1
	pData.totalExp = math.max(0, (pData.totalExp or 0) + amount)

	local prog = XPProgressionSystem.DeriveProgression(pData.totalExp)
	pData.level = prog.level
	pData.exp = prog.currentLevelExp

	local leveledUp = prog.level > oldLevel
	PlayerDataService.SyncLeaderstats(player)

	-- Cek pembukaan instrumen milestone berdasarkan level baru (FISH-031)
	if pData.level >= 2 and not PlayerDataService.IsInstrumentUnlocked(player, "GUITAR") then
		PlayerDataService.UnlockInstrument(player, "GUITAR")
	end
	if pData.level >= 4 and not PlayerDataService.IsInstrumentUnlocked(player, "DRUM") then
		PlayerDataService.UnlockInstrument(player, "DRUM")
	end

	if leveledUp then
		RemoteContract.Server.LevelUp(player, pData.level)
	end
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
	return leveledUp, pData.level, prog
end

function PlayerDataService.SetLevel(player, targetLevel)
	local pData = PlayerDataService.Get(player)
	if not pData then return 1 end
	local oldLevel = pData.level or 1
	targetLevel = math.max(1, math.floor(tonumber(targetLevel) or 1))
	pData.totalExp = XPProgressionSystem.GetTotalExpForLevel(targetLevel)

	local prog = XPProgressionSystem.DeriveProgression(pData.totalExp)
	pData.level = prog.level
	pData.exp = prog.currentLevelExp

	PlayerDataService.SyncLeaderstats(player)

	-- Cek pembukaan instrumen milestone berdasarkan level baru (FISH-031)
	if pData.level >= 2 and not PlayerDataService.IsInstrumentUnlocked(player, "GUITAR") then
		PlayerDataService.UnlockInstrument(player, "GUITAR")
	end
	if pData.level >= 4 and not PlayerDataService.IsInstrumentUnlocked(player, "DRUM") then
		PlayerDataService.UnlockInstrument(player, "DRUM")
	end

	if pData.level ~= oldLevel then
		RemoteContract.Server.LevelUp(player, pData.level)
	end
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
	return pData.level, prog
end

function PlayerDataService.GetProgression(player)
	local pData = PlayerDataService.Get(player)
	if not pData then
		return XPProgressionSystem.DeriveProgression(0)
	end
	return XPProgressionSystem.DeriveProgression(pData.totalExp or 0)
end

function PlayerDataService.GetPity(player)
	local pData = PlayerDataService.Get(player)
	if not pData then return PlayerDataSchema.DeepCopy(PlayerDataSchema.DEFAULT_DATA.pity) end
	if not pData.pity then
		pData.pity = PlayerDataSchema.DeepCopy(PlayerDataSchema.DEFAULT_DATA.pity)
	end
	return pData.pity
end

function PlayerDataService.UpdatePity(player, rolledRarity)
	local pData = PlayerDataService.Get(player)
	if not pData then return end
	pData.pity = FishingRaritySystem.UpdatePityOnCatch(pData.pity or PlayerDataSchema.DEFAULT_DATA.pity, rolledRarity)
	return pData.pity
end

function PlayerDataService.RecordJournal(player, fishData, weight, extraData)
	local pData = PlayerDataService.Get(player)
	if not pData then return end
	if not pData.journal then
		pData.journal = {}
	end

	local fishName = (typeof(fishData) == "table" and (fishData.name or fishData.id)) or tostring(fishData or "Ikan")
	local fishId = (typeof(fishData) == "table" and (fishData.id or fishData.name)) or fishName
	local actualWeight = tonumber(weight) or (typeof(fishData) == "table" and tonumber(fishData.weight)) or 1.0

	local entry = pData.journal[fishId] or pData.journal[fishName]
	if not entry then
		entry = {
			id = fishId,
			name = (typeof(fishData) == "table" and fishData.name) or fishName,
			rarity = (typeof(fishData) == "table" and fishData.rarity) or "COMMON",
			count = 1,
			maxWeight = actualWeight,
			firstCaught = os.time(),
			mutations = {},
		}
		pData.journal[fishId] = entry
	else
		entry.count = (entry.count or 0) + 1
		if actualWeight > (entry.maxWeight or 0) then
			entry.maxWeight = actualWeight
		end
	end

	if typeof(fishData) == "table" and fishData.isMutated and fishData.mutationType then
		entry.mutations = entry.mutations or {}
		entry.mutations[fishData.mutationType] = true
	end

	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
end

-- ============ DATA PERSISTENCE ============
function PlayerDataService.LoadData(player)
	if not player or not player:IsA("Player") then return nil end
	local userId = player.UserId
	local key = "Player_" .. tostring(userId)

	local profile = PlayerDataSchema.CreateDefault()
	profile.activeSessionToken = HttpService:GenerateGUID(false)

	if dataStoreAvailable then
		local loadedData = nil
		local fetchSuccess = false
		local apiError = false

		for attempt = 1, MAX_RETRIES do
			local success, res = pcall(function()
				return dataStore:GetAsync(key)
			end)
			if success then
				loadedData = res
				fetchSuccess = true
				break
			else
				local errStr = tostring(res)
				if errStr:find("Studio access to APIs is not allowed") or errStr:find("Error code: 7") then
					dataStoreAvailable = false
					warn("[PlayerDataService] Studio API Access nonaktif di Game Settings Roblox Studio. Menggunakan in-memory cache.")
					break
				end
				apiError = true
				warn(string.format("[PlayerDataService] Gagal load data %s (percobaan %d/%d): %s", player.Name, attempt, MAX_RETRIES, errStr))
				task.wait(math.pow(2, attempt - 1) * 0.5) -- exponential backoff (0.5s, 1.0s, 2.0s)
			end
		end

		if fetchSuccess then
			if loadedData and typeof(loadedData) == "table" then
				profile = PlayerDataSchema.Migrate(loadedData)
				local valid, err = PlayerDataSchema.Validate(profile)
				if not valid then
					warn(string.format("[PlayerDataService] Data %s tidak valid (%s), merekonsiliasi ulang...", player.Name, tostring(err)))
					profile = PlayerDataSchema.Reconcile(profile)
				end
				profile.activeSessionToken = HttpService:GenerateGUID(false)
				print(string.format("[PlayerDataService] Data termuat dari DataStore untuk %s (v%d, Level %d, Koin: %d)", player.Name, profile.version or 1, profile.level, profile.coins))
			else
				print(string.format("[PlayerDataService] Data baru dibuat untuk %s", player.Name))
			end
		elseif apiError then
			-- Tandai gagal load agar save TIDAK menimpa DataStore dengan data kosong (Data Loss Protection)
			profile._failedLoad = true
			warn(string.format("[PlayerDataService] ⚠️ PERINGATAN: Gagal memuat data dari cloud untuk %s. Mode proteksi aktif (Save ditangguhkan).", player.Name))
			RemoteContract.Server.Notify(player, "⚠️ Gangguan jaringan cloud: Progres sesi ini tidak akan menimpa data lama.")
		end
	end

	-- Studio Testing Helper: Berikan saldo koin & joran HANYA jika profil baru di Studio
	if RunService:IsStudio() and (profile.totalExp or 0) == 0 and (profile.coins or 0) == 0 then
		profile.coins = 50000
		profile.totalExp = XPProgressionSystem.GetTotalExpForLevel(profile.level or 1)
		local prog = XPProgressionSystem.DeriveProgression(profile.totalExp)
		profile.level = prog.level
		profile.exp = prog.currentLevelExp
		profile.unlockedRods = {
			-- Piano Rods
			"StarterRod",
			"HarmonicTuningRod",
			"CrystalSonataRod",
			-- Guitar Rods
			"BambooRod",
			"CarbonFiberRod",
			"AbyssalTridentRod",
			-- Drum Rods
			"TribalPercussionRod",
			"SynthwaveDrumRod",
			"CelestialMelodyRod",
		}
		profile.unlockedInstruments = { "PIANO", "GUITAR", "DRUM" }
		profile.baits = profile.baits or {}
		profile.baits.StandardWorm = 20
		profile.baits.GoldenLarva = 20
		profile.baits.MagnetShrimp = 20
		profile.baits.MelodyJelly = 20
	end

	profiles[userId] = profile
	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, profile, profile.pity)

	-- Pulihkan inventaris tangkapan dari DataStore ke Backpack pemain (FISH-040)
	local invService = getInventoryService()
	if invService and invService.RestorePlayerInventory then
		task.defer(function()
			invService.RestorePlayerInventory(player)
		end)
	end

	return profile
end

function PlayerDataService.SaveData(player)
	if not player or not player:IsA("Player") then return false, "Player tidak valid" end
	local userId = player.UserId
	local profile = profiles[userId]
	if not profile then return false, "Profile tidak ditemukan" end

	-- 1. Proteksi Anti-Wipe: Jangan pernah simpan profil jika gagal dimuat saat login!
	if profile._failedLoad == true then
		warn(string.format("[PlayerDataService] 🛑 PEMBATALAN SAVE: Data %s ditolak disimpan karena gagal dimuat saat login (mencegah data wipe).", player.Name))
		return false, "Aborted: Failed load protection"
	end

	if isSaving[userId] then return false, "Already saving" end
	isSaving[userId] = true

	-- 2. Sinkronkan item Backpack pemain ke profile.inventory sebelum disimpan (FISH-040)
	local invService = getInventoryService()
	if invService and invService.SyncPlayerInventoryData then
		invService.SyncPlayerInventoryData(player)
	end

	-- 3. Validasi & Rekonsiliasi sebelum disimpan
	local valid, valErr = PlayerDataSchema.Validate(profile)
	if not valid then
		warn(string.format("[PlayerDataService] Data %s tidak valid sebelum disimpan (%s). Menyelaraskan...", player.Name, tostring(valErr)))
		profile = PlayerDataSchema.Reconcile(profile)
	end

	profile.lastSaved = os.time()

	-- 4. Simpan ke DataStore menggunakan UpdateAsync (Atomic & Concurrency-Safe) (FISH-040)
	local saveSuccess = false
	local saveErr = nil

	if dataStoreAvailable then
		local key = "Player_" .. tostring(userId)

		for attempt = 1, MAX_RETRIES do
			local success, res = pcall(function()
				return dataStore:UpdateAsync(key, function(oldData)
					if oldData and typeof(oldData) == "table" then
						-- Rollback Protection: Pertahankan totalExp & coins tertinggi jika oldData lebih baru
						if (oldData.totalExp or 0) > (profile.totalExp or 0) then
							profile.totalExp = oldData.totalExp
							local prog = XPProgressionSystem.DeriveProgression(profile.totalExp)
							profile.level = prog.level
							profile.exp = prog.currentLevelExp
						end

						if (oldData.coins or 0) > (profile.coins or 0) then
							profile.coins = oldData.coins
						end

						-- Merge unlocked rods
						if typeof(oldData.unlockedRods) == "table" then
							for _, rod in ipairs(oldData.unlockedRods) do
								if not table.find(profile.unlockedRods, rod) then
									table.insert(profile.unlockedRods, rod)
								end
							end
						end

						-- Merge unlocked instruments
						if typeof(oldData.unlockedInstruments) == "table" then
							for _, inst in ipairs(oldData.unlockedInstruments) do
								if not table.find(profile.unlockedInstruments, inst) then
									table.insert(profile.unlockedInstruments, inst)
								end
							end
						end
					end

					profile.lastSaved = os.time()
					return profile
				end)
			end)

			if success then
				saveSuccess = true
				break
			else
				saveErr = res
				warn(string.format("[PlayerDataService] Gagal menyimpan data %s (percobaan %d/%d): %s", player.Name, attempt, MAX_RETRIES, tostring(res)))
				task.wait(math.pow(2, attempt - 1) * 0.5) -- exponential backoff (0.5s, 1.0s, 2.0s)
			end
		end

		if saveSuccess then
			print(string.format("[PlayerDataService] ✅ Data berhasil disimpan via UpdateAsync untuk %s (Level %d, Koin: %d)", player.Name, profile.level, profile.coins))
		end
	else
		-- In-memory cache mode
		saveSuccess = true
	end

	isSaving[userId] = nil
	return saveSuccess, saveErr
end

function PlayerDataService.SaveAll()
	print("[PlayerDataService] Menyimpan data seluruh pemain...")
	local currentPlayers = Players:GetPlayers()
	local pending = #currentPlayers
	if pending == 0 then return end

	for _, player in ipairs(currentPlayers) do
		task.spawn(function()
			PlayerDataService.SaveData(player)
			pending = pending - 1
		end)
	end

	local startTime = os.clock()
	while pending > 0 and (os.clock() - startTime) < 20 do
		task.wait(0.2)
	end
	print("[PlayerDataService] Selesai menyimpan data seluruh pemain.")
end

-- ============ INIT & LIFECYCLE ============
local initialized = false
function PlayerDataService.Init()
	if initialized then return end
	initialized = true

	local function setupPlayer(player)
		PlayerDataService.LoadData(player)

		player.CharacterAdded:Connect(function()
			local invService = getInventoryService()
			if invService and invService.RestorePlayerInventory then
				task.defer(function()
					task.wait(0.2)
					invService.RestorePlayerInventory(player)
				end)
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			setupPlayer(p)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.SaveData(player)
		profiles[player.UserId] = nil
		isSaving[player.UserId] = nil
	end)

	game:BindToClose(function()
		PlayerDataService.SaveAll()
	end)

	-- Auto-save loop berkala
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				PlayerDataService.SaveData(player)
				task.wait(1)
			end
		end
	end)

	print("[PlayerDataService] Inisialisasi PlayerDataService selesai (FISH-040 Production Persistence).")
end

PlayerDataService.Init()

return PlayerDataService
