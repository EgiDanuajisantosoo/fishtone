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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local PlayerDataSchema = require(Shared:WaitForChild("Config"):WaitForChild("PlayerDataSchema"))

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

function PlayerDataService.AddExp(player, amount)
	local pData = PlayerDataService.Get(player)
	if not pData then return false end

	pData.exp = (pData.exp or 0) + amount
	pData.level = pData.level or 1
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

	PlayerDataService.SyncLeaderstats(player)
	if leveledUp then
		RemoteContract.Server.LevelUp(player, pData.level)
	end
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
	return leveledUp
end

function PlayerDataService.SetLevel(player, targetLevel)
	local pData = PlayerDataService.Get(player)
	if not pData then return 1 end
	pData.level = math.max(1, math.floor(tonumber(targetLevel) or 1))
	pData.exp = 0
	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.LevelUp(player, pData.level)
	RemoteContract.Server.PlayerDataUpdate(player, pData, pData.pity)
	return pData.level
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
	local userId = player.UserId
	local key = "Player_" .. tostring(userId)

	local profile = PlayerDataSchema.CreateDefault()

	if dataStoreAvailable then
		local loadedData = nil
		local fetchSuccess = false

		for attempt = 1, MAX_RETRIES do
			local success, res = pcall(function()
				return dataStore:GetAsync(key)
			end)
			if success then
				loadedData = res
				fetchSuccess = true
				break
			else
				warn(string.format("[PlayerDataService] Gagal load data %s (percobaan %d/%d): %s", player.Name, attempt, MAX_RETRIES, tostring(res)))
				task.wait(1)
			end
		end

		if fetchSuccess and loadedData and typeof(loadedData) == "table" then
			profile = PlayerDataSchema.Migrate(loadedData)
			local valid, err = PlayerDataSchema.Validate(profile)
			if not valid then
				warn(string.format("[PlayerDataService] Data %s tidak valid (%s), merekonsiliasi ulang...", player.Name, tostring(err)))
				profile = PlayerDataSchema.Reconcile(profile)
			end
			print(string.format("[PlayerDataService] Data termuat untuk %s (v%d, Level %d, Koin: %d)", player.Name, profile.version or 1, profile.level, profile.coins))
		else
			print(string.format("[PlayerDataService] Data baru dibuat untuk %s", player.Name))
		end
	-- Studio Testing Helper: Berikan saldo koin & joran jika sedang testing di Studio
	if RunService:IsStudio() then
		profile.coins = math.max(profile.coins or 0, 50000)
		profile.level = math.max(profile.level or 1, 20)
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
		profile.baits = profile.baits or {}
		profile.baits.StandardWorm = math.max(profile.baits.StandardWorm or 0, 20)
		profile.baits.GoldenLarva = math.max(profile.baits.GoldenLarva or 0, 20)
		profile.baits.MagnetShrimp = math.max(profile.baits.MagnetShrimp or 0, 20)
		profile.baits.MelodyJelly = math.max(profile.baits.MelodyJelly or 0, 20)
	end

	profiles[userId] = profile
	PlayerDataService.SyncLeaderstats(player)
	RemoteContract.Server.PlayerDataUpdate(player, profile, profile.pity)
	return profile
end

function PlayerDataService.SaveData(player)
	if not player or not player:IsA("Player") then return end
	local userId = player.UserId
	local profile = profiles[userId]
	if not profile then return end

	if isSaving[userId] then return end
	isSaving[userId] = true

	local valid, valErr = PlayerDataSchema.Validate(profile)
	if not valid then
		warn(string.format("[PlayerDataService] Data %s tidak valid sebelum disimpan (%s). Menyelaraskan...", player.Name, tostring(valErr)))
		profile = PlayerDataSchema.Reconcile(profile)
	end

	profile.lastSaved = os.time()

	if dataStoreAvailable then
		local key = "Player_" .. tostring(userId)
		local saveSuccess = false

		for attempt = 1, MAX_RETRIES do
			local success, err = pcall(function()
				dataStore:SetAsync(key, profile)
			end)
			if success then
				saveSuccess = true
				break
			else
				warn(string.format("[PlayerDataService] Gagal menyimpan data %s (percobaan %d/%d): %s", player.Name, attempt, MAX_RETRIES, tostring(err)))
				task.wait(1)
			end
		end

		if saveSuccess then
			print(string.format("[PlayerDataService] Data berhasil disimpan untuk %s (Level %d, Koin: %d)", player.Name, profile.level, profile.coins))
		end
	end

	isSaving[userId] = nil
end

function PlayerDataService.SaveAll()
	print("[PlayerDataService] Menyimpan data seluruh pemain...")
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerDataService.SaveData(player)
		end)
	end
end

-- ============ INIT & LIFECYCLE ============
local initialized = false
function PlayerDataService.Init()
	if initialized then return end
	initialized = true

	Players.PlayerAdded:Connect(function(player)
		PlayerDataService.LoadData(player)
	end)

	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerDataService.LoadData(p)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.SaveData(player)
		profiles[player.UserId] = nil
		isSaving[player.UserId] = nil
	end)

	game:BindToClose(function()
		PlayerDataService.SaveAll()
		task.wait(2)
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

	print("[PlayerDataService] Inisialisasi PlayerDataService selesai.")
end

PlayerDataService.Init()

return PlayerDataService
