--[[
	PlayerDataService (ModuleScript)
	FISH!TUNE — Player Data & DataStore Service (FISH-004)

	Layanan Sentral Manajemen Data & Persistensi Pemain:
	1. DataStore persistence dengan key berbasis UserId.
	2. Fallback in-memory yang aman jika DataStore dinonaktifkan di Studio.
	3. Schema default & versioning (level, exp, coins, totalFish, pity state, equippedRod).
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

local DEFAULT_PROFILE = {
	version = 1,
	level = 1,
	exp = 0,
	coins = 0,
	totalFish = 0,
	pity = {
		LEGENDARY = 0,
		MYTHIC = 0,
		SPECIAL = 0,
	},
	equippedRod = "DefaultRod",
	lastSaved = 0,
}

local function deepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if typeof(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- ============ PROFILE GETTERS ============
function PlayerDataService.Get(player)
	if not player or not player:IsA("Player") then return nil end
	local userId = player.UserId
	if not profiles[userId] then
		profiles[userId] = deepCopy(DEFAULT_PROFILE)
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

function PlayerDataService.GetPity(player)
	local pData = PlayerDataService.Get(player)
	if not pData then return deepCopy(DEFAULT_PROFILE.pity) end
	if not pData.pity then
		pData.pity = deepCopy(DEFAULT_PROFILE.pity)
	end
	return pData.pity
end

function PlayerDataService.UpdatePity(player, rolledRarity)
	local pData = PlayerDataService.Get(player)
	if not pData then return end
	pData.pity = FishingRaritySystem.UpdatePityOnCatch(pData.pity or DEFAULT_PROFILE.pity, rolledRarity)
	return pData.pity
end

-- ============ DATA PERSISTENCE ============
function PlayerDataService.LoadData(player)
	local userId = player.UserId
	local key = "Player_" .. tostring(userId)

	local profile = deepCopy(DEFAULT_PROFILE)

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
			profile.level = loadedData.level or loadedData.Level or profile.level
			profile.exp = loadedData.exp or loadedData.Exp or profile.exp
			profile.coins = loadedData.coins or loadedData.Coins or profile.coins
			profile.totalFish = loadedData.totalFish or loadedData.TotalFish or profile.totalFish
			profile.equippedRod = loadedData.equippedRod or profile.equippedRod

			local loadedPity = loadedData.pity or loadedData.Pity
			if loadedPity and typeof(loadedPity) == "table" then
				profile.pity.LEGENDARY = loadedPity.LEGENDARY or 0
				profile.pity.MYTHIC = loadedPity.MYTHIC or 0
				profile.pity.SPECIAL = loadedPity.SPECIAL or 0
			end
			print(string.format("[PlayerDataService] Data termuat untuk %s (Level %d, Koin: %d)", player.Name, profile.level, profile.coins))
		else
			print(string.format("[PlayerDataService] Data baru dibuat untuk %s", player.Name))
		end
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
