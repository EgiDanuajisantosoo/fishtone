--[[
	PlayerDataSchema (ModuleScript)
	FISH!TUNE — Central Player Data Schema & Migration Pipeline (FISH-005 / FISH-029 / FISH-030 / FISH-031)

	Satu sumber kebenaran (Single Source of Truth) untuk struktur data pemain:
	1. Definisi Schema Lengkap (TotalXP, Level, EXP, Koin, Pity, Rods, Instruments, Journal, Stats, Settings).
	2. Versioning & Migration Pipeline (Mendukung upgrade format data otomatis di masa depan).
	3. Deep Reconciler (Memastikan field baru otomatis terisi ke data pemain lama tanpa merusak data yang ada).
	4. Schema Invariant Validator (Mencegah data corrupt / nilai negatif / tipe data salah).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))

local PlayerDataSchema = {}

-- ============ SCHEMA VERSION ============
PlayerDataSchema.SCHEMA_VERSION = 1

-- ============ DEFAULT DATA TEMPLATE ============
PlayerDataSchema.DEFAULT_DATA = {
	version = PlayerDataSchema.SCHEMA_VERSION,

	-- Progresi Karakter & TotalXP (Persistence Source of Truth)
	level = 1,
	exp = 0,
	totalExp = 0,
	coins = 0,
	pearls = 0,
	totalFish = 0,

	-- Sistem Gacha / Pity
	pity = {
		LEGENDARY = 0,
		MYTHIC = 0,
		SPECIAL = 0,
	},

	-- Alat, Instrumen, Umpan & Kapasitas Inventaris
	equippedRod = "StarterRod",
	equippedInstrument = "PIANO",
	unlockedRods = { "StarterRod" },
	unlockedInstruments = { "PIANO" },
	equippedBait = nil,
	baits = {}, -- [baitId] = count (e.g. { StandardWorm = 0 })
	maxInventorySlots = 35,
	bagUpgradeTier = 0,

	-- Jurnal / Ensiklopedia Ikan
	journal = {}, -- [fishName] = { count = 0, maxWeight = 0, firstCaught = 0 }

	-- Statistik Gameplay & Ekonomi
	stats = {
		totalCasts = 0,
		perfectCasts = 0,
		greatCasts = 0,
		totalCoinsEarned = 0,
		totalCoinsSpent = 0,
		totalItemsSold = 0,
		totalPurchases = 0,
		highestCombo = 0,
		highestScore = 0,
		totalCatches = 0,
		allPerfectCount = 0,
		fullComboCount = 0,
	},

	-- Tutorial & Onboarding (FISH-033)
	tutorialStep = 0,
	tutorialCompleted = false,

	-- Preferensi & Pengaturan Pemain
	settings = {
		bgmVolume = 1.0,
		sfxVolume = 1.0,
		rhythmKeybinds = { "A", "W", "S", "D" },
	},

	-- Metadata Waktu
	createdAt = 0,
	lastSaved = 0,
}

-- ============ DEEP COPY HELPER ============
local function deepCopy(tbl)
	if typeof(tbl) ~= "table" then return tbl end
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

PlayerDataSchema.DeepCopy = deepCopy

-- ============ FACTORY METHOD ============
function PlayerDataSchema.CreateDefault()
	local data = deepCopy(PlayerDataSchema.DEFAULT_DATA)
	local now = os.time()
	data.createdAt = now
	data.lastSaved = now
	return data
end

-- ============ RECONCILER ============
-- Menyelaraskan data yang dimuat dengan template schema default.
-- Jika ada field baru di versi game terbaru, field tersebut akan ditambahkan tanpa menimpa data yang sudah ada.
function PlayerDataSchema.Reconcile(target, template)
	template = template or PlayerDataSchema.DEFAULT_DATA
	if typeof(target) ~= "table" then
		return deepCopy(template)
	end

	for key, defaultValue in pairs(template) do
		if target[key] == nil then
			-- Field belum ada, isi dengan nilai default
			target[key] = deepCopy(defaultValue)
		elseif typeof(defaultValue) == "table" and typeof(target[key]) == "table" then
			-- Jika berupa sub-table (kecuali array murni seperti unlockedRods), lakukan rekonsiliasi rekursif
			local isArray = #defaultValue > 0
			if not isArray then
				PlayerDataSchema.Reconcile(target[key], defaultValue)
			end
		elseif typeof(target[key]) ~= typeof(defaultValue) then
			-- Tipe data tidak cocok, pulihkan ke default
			target[key] = deepCopy(defaultValue)
		end
	end

	-- 1. Rekonsiliasi TotalXP & Progresi Level (FISH-030)
	if target.totalExp == nil or typeof(target.totalExp) ~= "number" or target.totalExp < 0 or (target.totalExp == 0 and (target.level or 1) > 1) then
		target.totalExp = XPProgressionSystem.ReconcileToTotalExp(target.level or 1, target.exp or 0)
	end

	-- Pastikan level dan exp selalu selaras secara matematis dengan TotalXP
	local prog = XPProgressionSystem.DeriveProgression(target.totalExp)
	target.level = prog.level
	target.exp = prog.currentLevelExp

	-- 2. Rekonsiliasi Unlocked Instruments (FISH-031)
	if typeof(target.unlockedInstruments) ~= "table" then
		target.unlockedInstruments = { "PIANO" }
	end
	if not table.find(target.unlockedInstruments, "PIANO") then
		table.insert(target.unlockedInstruments, "PIANO")
	end

	-- Pastikan instrumen dari joran yang dimiliki otomatis terbuka
	if typeof(target.unlockedRods) == "table" then
		for _, rodId in ipairs(target.unlockedRods) do
			local inst = InstrumentDefinitions.GetInstrumentTypeForRod(rodId)
			if inst and not table.find(target.unlockedInstruments, inst) then
				table.insert(target.unlockedInstruments, inst)
			end
		end
	end

	-- Milestone level unlock (Level 2: Guitar, Level 4: Drum)
	if target.level >= 2 and not table.find(target.unlockedInstruments, "GUITAR") then
		table.insert(target.unlockedInstruments, "GUITAR")
	end
	if target.level >= 4 and not table.find(target.unlockedInstruments, "DRUM") then
		table.insert(target.unlockedInstruments, "DRUM")
	end

	-- 3. Pastikan equippedInstrument selalu sinkron dengan equippedRod
	if not target.equippedInstrument or not InstrumentDefinitions.IsValidInstrumentType(target.equippedInstrument) then
		target.equippedInstrument = InstrumentDefinitions.GetInstrumentTypeForRod(target.equippedRod or "StarterRod")
	end

	-- 4. Rekonsiliasi Tutorial (FISH-033)
	if target.tutorialStep == nil or typeof(target.tutorialStep) ~= "number" then
		target.tutorialStep = 0
	end
	if target.tutorialCompleted == nil or typeof(target.tutorialCompleted) ~= "boolean" then
		target.tutorialCompleted = false
	end

	return target
end

-- ============ MIGRATION PIPELINE ============
-- Menangani transformasi data dari versi schema lama ke versi terbaru
local Migrations = {
	-- [1] = function(data) return data end,
	-- [2] = function(data) ... migrasi ke v2 ... return data end,
}

function PlayerDataSchema.Migrate(data)
	if typeof(data) ~= "table" then
		return PlayerDataSchema.CreateDefault()
	end

	local currentVersion = tonumber(data.version) or 0

	while currentVersion < PlayerDataSchema.SCHEMA_VERSION do
		local nextVersion = currentVersion + 1
		local migrationFunc = Migrations[nextVersion]

		if migrationFunc then
			local success, migrated = pcall(migrationFunc, data)
			if success and typeof(migrated) == "table" then
				data = migrated
			else
				warn(string.format("[PlayerDataSchema] Gagal melakukan migrasi ke v%d: %s", nextVersion, tostring(migrated)))
			end
		end

		data.version = nextVersion
		currentVersion = nextVersion
	end

	-- Rekonsiliasi setelah migrasi selesai
	return PlayerDataSchema.Reconcile(data, PlayerDataSchema.DEFAULT_DATA)
end

-- ============ VALIDATOR ============
-- Memverifikasi keabsahan data sebelum disimpan atau digunakan
function PlayerDataSchema.Validate(data)
	if typeof(data) ~= "table" then
		return false, "Data bukan berupa table"
	end

	-- Validasi tipe numerik penting
	if typeof(data.level) ~= "number" or data.level < 1 then
		return false, "Level tidak valid"
	end
	if typeof(data.exp) ~= "number" or data.exp < 0 then
		return false, "EXP tidak valid"
	end
	if typeof(data.totalExp) ~= "number" or data.totalExp < 0 then
		return false, "TotalExp tidak valid"
	end
	if typeof(data.coins) ~= "number" or data.coins < 0 then
		return false, "Koin tidak valid (nilai negatif)"
	end
	if typeof(data.totalFish) ~= "number" or data.totalFish < 0 then
		return false, "Total Fish tidak valid"
	end

	-- Validasi table pity
	if typeof(data.pity) ~= "table" then
		return false, "Table pity tidak ditemukan"
	end

	-- Validasi joran & instrumen
	if typeof(data.equippedRod) ~= "string" or #data.equippedRod == 0 then
		return false, "Equipped rod tidak valid"
	end
	if typeof(data.unlockedRods) ~= "table" then
		return false, "Unlocked rods harus berupa table"
	end
	if typeof(data.unlockedInstruments) ~= "table" then
		return false, "Unlocked instruments harus berupa table"
	end

	return true, nil
end

-- ============ SANITIZER ============
-- Membersihkan / membatasi data yang dikirim ke client jika diperlukan
function PlayerDataSchema.SanitizeForClient(data)
	if typeof(data) ~= "table" then return {} end
	return deepCopy(data)
end

return PlayerDataSchema
