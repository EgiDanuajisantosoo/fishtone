--[[
	PlayerDataSchema (ModuleScript)
	FISH!TUNE — Central Player Data Schema & Migration Pipeline (FISH-005)

	Satu sumber kebenaran (Single Source of Truth) untuk struktur data pemain:
	1. Definisi Schema Lengkap (Level, EXP, Koin, Pity, Rods, Journal, Stats, Settings).
	2. Versioning & Migration Pipeline (Mendukung upgrade format data otomatis di masa depan).
	3. Deep Reconciler (Memastikan field baru otomatis terisi ke data pemain lama tanpa merusak data yang ada).
	4. Schema Invariant Validator (Mencegah data corrupt / nilai negatif / tipe data salah).
]]

local PlayerDataSchema = {}

-- ============ SCHEMA VERSION ============
PlayerDataSchema.SCHEMA_VERSION = 1

-- ============ DEFAULT DATA TEMPLATE ============
PlayerDataSchema.DEFAULT_DATA = {
	version = PlayerDataSchema.SCHEMA_VERSION,

	-- Progresi Karakter
	level = 1,
	exp = 0,
	coins = 0,
	pearls = 0,
	totalFish = 0,

	-- Sistem Gacha / Pity
	pity = {
		LEGENDARY = 0,
		MYTHIC = 0,
		SPECIAL = 0,
	},

	-- Alat, Umpan & Kapasitas Inventaris
	equippedRod = "StarterRod",
	unlockedRods = { "StarterRod" },
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
	},

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

	return true, nil
end

-- ============ SANITIZER ============
-- Membersihkan / membatasi data yang dikirim ke client jika diperlukan
function PlayerDataSchema.SanitizeForClient(data)
	if typeof(data) ~= "table" then return {} end
	return deepCopy(data)
end

return PlayerDataSchema
