--[[
	LootDefinitions (ModuleScript)
	FISH!TUNE — Central Loot Catalog & Category Definitions (FISH-018)

	Katalog Terpusat Seluruh Kategori Loot di Game FISH!TUNE:
	1. Kategori Loot: FISH (Ikan), TREASURE (Peti Harta Karun), ARTIFACT (Relik Kuno), JUNK (Benda Dasar Laut).
	2. Definisi Parameter: ID Unik, Nama, Rarity, Rentang Nilai Koin, EXP, Bobot, Deskripsi Lore, Warna 3D, dan Zona Habitat.
	3. Weighted Base Distribution Table dengan Skala Pengaruh Luck.
]]

local LootDefinitions = {}

-- ============ KATEGORI LOOT & BASE WEIGHTS ============
LootDefinitions.CATEGORIES = {
	FISH = {
		id = "FISH",
		name = "Ikan Samudra",
		badge = "🐟 IKAN",
		color = Color3.fromRGB(0, 200, 255),
		baseWeight = 8200, -- ~82.0%
	},
	TREASURE = {
		id = "TREASURE",
		name = "Peti Harta Karun",
		badge = "📦 HARTA KARUN",
		color = Color3.fromRGB(255, 215, 0),
		baseWeight = 900,  -- ~9.0%
	},
	ARTIFACT = {
		id = "ARTIFACT",
		name = "Relik & Artefak Kuno",
		badge = "✨ RELIK KUNO",
		color = Color3.fromRGB(200, 80, 255),
		baseWeight = 500,  -- ~5.0%
	},
	JUNK = {
		id = "JUNK",
		name = "Benda Dasar Laut",
		badge = "🗑️ BENDA LAUT",
		color = Color3.fromRGB(160, 150, 140),
		baseWeight = 400,  -- ~4.0%
	},
}

-- ============ KATALOG PETI HARTA KARUN (TREASURE CHESTS) ============
LootDefinitions.TREASURE_CHESTS = {
	{
		id = "TREASURE_WOODEN",
		name = "Peti Harta Karun Kayu",
		itemType = "TREASURE",
		rarity = "RARE",
		minCoins = 80,
		maxCoins = 160,
		baseExp = 35,
		weight = 4.5,
		description = "Peti kayu tua berlapis lumut yang berisi koin perak dan peninggalan pelaut kuno.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(140, 95, 60),
		scale = 1.1,
	},
	{
		id = "TREASURE_BRONZE",
		name = "Peti Perunggu Berukir",
		itemType = "TREASURE",
		rarity = "SUPER_RARE",
		minCoins = 260,
		maxCoins = 480,
		baseExp = 75,
		weight = 8.0,
		description = "Peti tembaga padat berukir tangga nada musik yang terkunci rapat di dasar danau kembar.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(205, 127, 50),
		scale = 1.25,
	},
	{
		id = "TREASURE_GOLDEN",
		name = "Peti Emas Samudra Mulia",
		itemType = "TREASURE",
		rarity = "LEGENDARY",
		minCoins = 850,
		maxCoins = 1600,
		baseExp = 180,
		weight = 15.0,
		description = "Peti berlapis emas murni 24 karat dengan segel kerajaan samudra yang memancarkan pendar kemewahan.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 215, 0),
		scale = 1.4,
	},
	{
		id = "TREASURE_ABYSSAL",
		name = "Peti Permata Abyssal",
		itemType = "TREASURE",
		rarity = "MYTHIC",
		minCoins = 2600,
		maxCoins = 4800,
		baseExp = 450,
		weight = 25.0,
		description = "Peti legendaris palung terdalam bertatahkan kristal safir, rubi, dan permata bintang kosmik.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(170, 40, 240),
		scale = 1.6,
	},
	{
		id = "TREASURE_CELESTIAL",
		name = "Peti Mahkota Dewa Laut",
		itemType = "TREASURE",
		rarity = "SPECIAL",
		minCoins = 6000,
		maxCoins = 10000,
		baseExp = 900,
		weight = 40.0,
		description = "Pusaka teragung samudra raya berisi kekayaan maharaja lautan dari zaman purbakala.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 60, 200),
		scale = 1.8,
	},
}

-- ============ KATALOG ARTEFAK & RELIK KUNO (ARTIFACTS) ============
LootDefinitions.ARTIFACTS = {
	{
		id = "ARTIFACT_BOTTLE_MESSAGE",
		name = "Botol Pesan Misterius",
		itemType = "ARTIFACT",
		rarity = "RARE",
		minCoins = 65,
		maxCoins = 120,
		baseExp = 28,
		weight = 0.8,
		description = "Secarik kertas di dalam botol kaca bertuliskan lembaran partitur nada rahasia dari pelaut zaman dulu.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(100, 220, 180),
		scale = 0.85,
	},
	{
		id = "ARTIFACT_BLACK_PEARL",
		name = "Mutiara Hitam Laut Selatan",
		itemType = "ARTIFACT",
		rarity = "SUPER_RARE",
		minCoins = 190,
		maxCoins = 320,
		baseExp = 55,
		weight = 1.2,
		description = "Mutiara langka berkilau pelangi gelap yang memancarkan aura ketenangan mistis bagi pemegangnya.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(50, 50, 70),
		scale = 0.9,
	},
	{
		id = "ARTIFACT_MUSIC_BOX",
		name = "Kotak Musik Kuno Melodia",
		itemType = "ARTIFACT",
		rarity = "LEGENDARY",
		minCoins = 520,
		maxCoins = 850,
		baseExp = 120,
		weight = 3.5,
		description = "Kotak musik mekanik berlapis perak yang masih memainkan denting melodi klasik saat dibuka.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(220, 190, 100),
		scale = 1.0,
	},
	{
		id = "ARTIFACT_SIREN_CRYSTAL",
		name = "Kristal Suara Siren",
		itemType = "ARTIFACT",
		rarity = "MYTHIC",
		minCoins = 1600,
		maxCoins = 2800,
		baseExp = 240,
		weight = 5.0,
		description = "Pecahan kristal laut bergetar yang mampu meningkatkan kepekaan pendengaran terhadap ketukan ritme.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(0, 240, 255),
		scale = 1.15,
	},
	{
		id = "ARTIFACT_POSEIDON_RELIC",
		name = "Pecahan Trisula Samudra",
		itemType = "ARTIFACT",
		rarity = "SPECIAL",
		minCoins = 4200,
		maxCoins = 7500,
		baseExp = 500,
		weight = 8.5,
		description = "Fragmen trisula purba berkekuatan magis yang mampu menenangkan badai dan mengundang ikan langka.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 120, 220),
		scale = 1.3,
	},
}

-- ============ KATALOG BENDA DASAR LAUT (JUNK / DEBRIS) ============
LootDefinitions.JUNK = {
	{
		id = "JUNK_OLD_BOOT",
		name = "Sepatu Bot Tua Berlumut",
		itemType = "JUNK",
		rarity = "COMMON",
		minCoins = 6,
		maxCoins = 12,
		baseExp = 3,
		weight = 1.5,
		description = "Sepatu bot kulit usang pelaut yang tersangkut di kail pancing. Masih bisa dijual ke pengepul barang bekas.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(100, 80, 60),
		scale = 0.85,
	},
	{
		id = "JUNK_RUSTY_CAN",
		name = "Kaleng Karatan Laut",
		itemType = "JUNK",
		rarity = "COMMON",
		minCoins = 4,
		maxCoins = 8,
		baseExp = 2,
		weight = 0.4,
		description = "Kaleng minuman besi yang telah terendam air laut bertahun-tahun hingga berkarat.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(150, 90, 60),
		scale = 0.7,
	},
	{
		id = "JUNK_DRIFTWOOD",
		name = "Kayu Apung Halus",
		itemType = "JUNK",
		rarity = "COMMON",
		minCoins = 9,
		maxCoins = 15,
		baseExp = 4,
		weight = 2.2,
		description = "Batang kayu keras yang telah terukir halus oleh deburan ombak dan air laut.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(160, 130, 95),
		scale = 0.95,
	},
	{
		id = "JUNK_MAGIC_SEAWEED",
		name = "Rumput Laut Kenyal",
		itemType = "JUNK",
		rarity = "COMMON",
		minCoins = 12,
		maxCoins = 18,
		baseExp = 5,
		weight = 0.6,
		description = "Seikat tanaman laut kenyal yang menempel pada ujung tali pancing.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(40, 140, 60),
		scale = 0.8,
	},
}

-- ============ INDEX TABLES ============
LootDefinitions.BY_ID = {}
LootDefinitions.BY_CATEGORY = {
	TREASURE = LootDefinitions.TREASURE_CHESTS,
	ARTIFACT = LootDefinitions.ARTIFACTS,
	JUNK = LootDefinitions.JUNK,
}

for _, catList in pairs(LootDefinitions.BY_CATEGORY) do
	for _, item in ipairs(catList) do
		LootDefinitions.BY_ID[item.id] = item
	end
end

-- ============ HELPER GETTERS ============
function LootDefinitions.GetLootById(id)
	return id and LootDefinitions.BY_ID[id] or nil
end

function LootDefinitions.GetLootByCategory(category, rarity, zoneId)
	category = tostring(category or "TREASURE"):upper()
	local list = LootDefinitions.BY_CATEGORY[category]
	if not list then return {} end

	local filtered = {}
	for _, item in ipairs(list) do
		local matchRarity = not rarity or item.rarity == rarity
		local matchZone = not zoneId or item.favoriteZone == zoneId or not item.favoriteZone
		if matchRarity and matchZone then
			table.insert(filtered, item)
		end
	end

	if #filtered == 0 then
		for _, item in ipairs(list) do
			if not rarity or item.rarity == rarity then
				table.insert(filtered, item)
			end
		end
	end

	if #filtered == 0 then
		return list
	end

	return filtered
end

return LootDefinitions
