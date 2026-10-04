--[[
	FishDefinitions (ModuleScript)
	FISH!TUNE — Central Fish Catalog & Species Definitions (FISH-017)

	Katalog Terpusat Seluruh Spesies Ikan di Game FISH!TUNE:
	1. Definisi Lengkap 6 Tingkat Rarity (COMMON, RARE, SUPER_RARE, LEGENDARY, MYTHIC, SPECIAL).
	2. Metadata Lengkap: ID Unik, Nama, Rarity, Rentang Bobot (Kg), Nilai Koin, EXP, Deskripsi Lore, Zona Habitat, Warna Aura 3D, dan Skala Model.
	3. Pengelompokan Cerdas (Index by ID, Rarity, dan Zone Pool).
	4. Fungsi Helper Query & Filter Habitat Perairan (Melody Bay, Twin Eye Lagoon, Summit Abyss).
]]

local FishDefinitions = {}

-- ============ KATALOG UTAMA SPESIES IKAN ============
FishDefinitions.CATALOG = {
	-- ==========================================
	-- TIER 1: COMMON (⭐ | Level 1+)
	-- ==========================================
	{
		id = "COMMON_GOLDFISH",
		name = "Ikan Mas Ceria",
		rarity = "COMMON",
		minWeight = 0.4,
		maxWeight = 1.8,
		baseCoins = 14,
		baseExp = 10,
		description = "Ikan air tawar lincah yang gemar berenang mengikuti alunan melodi lembut dermaga.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(255, 160, 60),
		scale = 0.9,
	},
	{
		id = "COMMON_CATFISH",
		name = "Lele Kumis Lokal",
		rarity = "COMMON",
		minWeight = 0.5,
		maxWeight = 2.2,
		baseCoins = 16,
		baseExp = 11,
		description = "Lele tangguh penjelajah dasar muara, sangat aktif mencari makan di malam hari.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(120, 115, 110),
		scale = 0.95,
	},
	{
		id = "COMMON_TILAPIA",
		name = "Mujair Sungai Belia",
		rarity = "COMMON",
		minWeight = 0.4,
		maxWeight = 1.9,
		baseCoins = 15,
		baseExp = 10,
		description = "Ikan bersisik perak dengan pola garis halus, mudah ditemukan di sekitar dermaga kayu.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(155, 165, 175),
		scale = 0.9,
	},
	{
		id = "COMMON_NILA",
		name = "Ikan Nila Harmoni",
		rarity = "COMMON",
		minWeight = 0.6,
		maxWeight = 2.4,
		baseCoins = 18,
		baseExp = 12,
		description = "Memiliki warna hijau kebiruan cerah dengan sirip yang bergetar seirama riak air laut.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(80, 190, 160),
		scale = 1.0,
	},
	{
		id = "COMMON_BETTA",
		name = "Ikan Cupang Liar",
		rarity = "COMMON",
		minWeight = 0.1,
		maxWeight = 0.6,
		baseCoins = 12,
		baseExp = 8,
		description = "Ikan mungil berekor kipas cerah yang sering menari di sela-sela bebatuan pantai.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(240, 70, 120),
		scale = 0.75,
	},
	{
		id = "COMMON_MACKEREL",
		name = "Ikan Kembung Ombak",
		rarity = "COMMON",
		minWeight = 0.5,
		maxWeight = 2.0,
		baseCoins = 15,
		baseExp = 11,
		description = "Perenang cepat yang gemar melompat ke permukaan air saat matahari terbit.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(100, 180, 220),
		scale = 0.95,
	},
	{
		id = "COMMON_ANCHOVY",
		name = "Bilis Biru Danau",
		rarity = "COMMON",
		minWeight = 0.1,
		maxWeight = 0.5,
		baseCoins = 11,
		baseExp = 8,
		description = "Ikan kecil yang berenang dalam formasi berkelompok menyerupai permata biru berkilau.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(70, 160, 240),
		scale = 0.7,
	},

	-- ==========================================
	-- TIER 2: RARE (⭐⭐ | Level 3+)
	-- ==========================================
	{
		id = "RARE_GOURAMI",
		name = "Gurame Bintang Perak",
		rarity = "RARE",
		minWeight = 1.5,
		maxWeight = 5.2,
		baseCoins = 46,
		baseExp = 20,
		description = "Gurame bertubuh pipih lebar dengan sisik berkilau layaknya taburan bintang di langit malam.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(180, 210, 240),
		scale = 1.1,
	},
	{
		id = "RARE_SALMON",
		name = "Salmon Arus Deras",
		rarity = "RARE",
		minWeight = 1.8,
		maxWeight = 6.0,
		baseCoins = 52,
		baseExp = 22,
		description = "Ikan pejuang yang gemar melompat menembus air terjun kembar dengan tenaga dorong mengagumkan.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(255, 130, 90),
		scale = 1.15,
	},
	{
		id = "RARE_POMFRET",
		name = "Bawal Emas Tropis",
		rarity = "RARE",
		minWeight = 1.2,
		maxWeight = 4.5,
		baseCoins = 44,
		baseExp = 18,
		description = "Memiliki tubuh pipih dengan kilau kuning emas dan sirip dada panjang yang anggun.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(240, 200, 60),
		scale = 1.05,
	},
	{
		id = "RARE_SNAPPER",
		name = "Kakap Merah Karang",
		rarity = "RARE",
		minWeight = 2.0,
		maxWeight = 6.5,
		baseCoins = 56,
		baseExp = 24,
		description = "Penguasa celah batu karang dalam dengan tarikan kuat yang menguji kesabaran pemancing.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(235, 75, 75),
		scale = 1.2,
	},
	{
		id = "RARE_CLOWNFISH",
		name = "Ikan Badut Coral",
		rarity = "RARE",
		minWeight = 0.6,
		maxWeight = 2.2,
		baseCoins = 40,
		baseExp = 16,
		description = "Ikan bermotif belang jingga-putih yang bersahabat dan menyukai irama nada ceria.",
		favoriteZone = "MELODY_BAY",
		color = Color3.fromRGB(255, 110, 40),
		scale = 0.9,
	},
	{
		id = "RARE_GROUPER",
		name = "Kerapu Macan Danau",
		rarity = "RARE",
		minWeight = 2.2,
		maxWeight = 7.0,
		baseCoins = 58,
		baseExp = 25,
		description = "Kerapu bercorak loreng macan tutul dengan rahang kokoh penyergap umpan kilat.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(160, 140, 90),
		scale = 1.25,
	},

	-- ==========================================
	-- TIER 3: SUPER RARE (⭐⭐⭐ | Level 5+)
	-- ==========================================
	{
		id = "SR_ARAPAIMA",
		name = "Arapaima Amazonia",
		rarity = "SUPER_RARE",
		minWeight = 4.0,
		maxWeight = 14.0,
		baseCoins = 125,
		baseExp = 35,
		description = "Ikan purba berlidah tulang raksasa dengan sisik merah tebal berpelindung baja alami.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(190, 45, 60),
		scale = 1.45,
	},
	{
		id = "SR_ELECTRIC_RAY",
		name = "Pari Listrik Voltaic",
		rarity = "SUPER_RARE",
		minWeight = 3.0,
		maxWeight = 10.5,
		baseCoins = 120,
		baseExp = 32,
		description = "Mampu memancarkan aliran sengatan listrik ritmik berfrekuensi tinggi saat ditarik ke permukaan.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(60, 220, 255),
		scale = 1.35,
	},
	{
		id = "SR_MONSTER_CATFISH",
		name = "Lele Monster Raksasa",
		rarity = "SUPER_RARE",
		minWeight = 4.5,
		maxWeight = 15.0,
		baseCoins = 135,
		baseExp = 38,
		description = "Predator raksasa dasar danau purba dengan kumis panjang perasa getaran pancing.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(90, 80, 110),
		scale = 1.5,
	},
	{
		id = "SR_BLACK_TOMAN",
		name = "Toman Raja Hitam",
		rarity = "SUPER_RARE",
		minWeight = 3.5,
		maxWeight = 12.0,
		baseCoins = 130,
		baseExp = 36,
		description = "Monster berkepala ular predator agresif dengan corak hitam pekat bermata merah menyala.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(45, 45, 55),
		scale = 1.4,
	},
	{
		id = "SR_SWORDFISH",
		name = "Ikan Pedang Safir",
		rarity = "SUPER_RARE",
		minWeight = 5.0,
		maxWeight = 16.0,
		baseCoins = 145,
		baseExp = 40,
		description = "Memiliki moncong pedang tajam berkilau biru safir yang mampu membelah gelombang badai.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(0, 150, 255),
		scale = 1.55,
	},
	{
		id = "SR_BARRACUDA",
		name = "Barakuda Petir Samudra",
		rarity = "SUPER_RARE",
		minWeight = 3.8,
		maxWeight = 13.0,
		baseCoins = 132,
		baseExp = 37,
		description = "Perenang secepat kilat dengan gigi tajam bergerigi penyambar umpan dalam sekejap mata.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(140, 160, 200),
		scale = 1.4,
	},

	-- ==========================================
	-- TIER 4: LEGENDARY (⭐⭐⭐⭐ | Level 10+)
	-- ==========================================
	{
		id = "LEG_SEA_DRAGON",
		name = "Naga Laut Mistis",
		rarity = "LEGENDARY",
		minWeight = 10.0,
		maxWeight = 28.0,
		baseCoins = 370,
		baseExp = 62,
		description = "Makhluk anggun bersayap air bercahaya emas yang hidup di pusaran arus terdalam.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(240, 185, 20),
		scale = 1.75,
	},
	{
		id = "LEG_GOLDEN_SHARK",
		name = "Hiu Emas Murni Aurum",
		rarity = "LEGENDARY",
		minWeight = 12.0,
		maxWeight = 32.0,
		baseCoins = 410,
		baseExp = 70,
		description = "Hiu megah dengan kulit berlapis emas murni 24 karat yang memancarkan aura kemewahan abadi.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 215, 0),
		scale = 1.85,
	},
	{
		id = "LEG_ROYAL_CARP",
		name = "Ikan Mas Kaisar Giok",
		rarity = "LEGENDARY",
		minWeight = 8.0,
		maxWeight = 24.0,
		baseCoins = 350,
		baseExp = 58,
		description = "Ikan pusaka kekaisaran kuno yang konon membawa keberuntungan dan kemakmuran abadi.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(245, 170, 30),
		scale = 1.65,
	},
	{
		id = "LEG_HOLY_BELIDA",
		name = "Belida Emas Suci",
		rarity = "LEGENDARY",
		minWeight = 9.5,
		maxWeight = 26.0,
		baseCoins = 380,
		baseExp = 64,
		description = "Spesies belida langka dengan punggung melengkung bercahaya suci penyejuk jiwa.",
		favoriteZone = "TWIN_EYE_LAGOON",
		color = Color3.fromRGB(230, 195, 50),
		scale = 1.7,
	},
	{
		id = "LEG_COELACANTH",
		name = "Coelacanth Purba Abadi",
		rarity = "LEGENDARY",
		minWeight = 11.0,
		maxWeight = 30.0,
		baseCoins = 390,
		baseExp = 66,
		description = "Fosil hidup berumur ratusan juta tahun dengan sirip berotot mirip tungkai purbakala.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(80, 110, 150),
		scale = 1.8,
	},
	{
		id = "LEG_CRYSTAL_HAMMERHEAD",
		name = "Hiu Martil Kristal",
		rarity = "LEGENDARY",
		minWeight = 14.0,
		maxWeight = 35.0,
		baseCoins = 430,
		baseExp = 75,
		description = "Hiu martil bertubuh kristal transparan berlian yang menyerap energi petir langit.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(160, 240, 255),
		scale = 1.9,
	},

	-- ==========================================
	-- TIER 5: MYTHIC (⭐⭐⭐⭐⭐ | Level 15+)
	-- ==========================================
	{
		id = "MYT_RED_MEGALODON",
		name = "Hiu Megalodon Merah Darah",
		rarity = "MYTHIC",
		minWeight = 20.0,
		maxWeight = 65.0,
		baseCoins = 1150,
		baseExp = 115,
		description = "Raksasa purba predator puncak lautan dengan gigi sebesar telapak tangan dan raungan membahana.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(235, 45, 45),
		scale = 2.2,
	},
	{
		id = "MYT_FIRE_SEADRAGON",
		name = "Naga Laut Api Infernal",
		rarity = "MYTHIC",
		minWeight = 18.0,
		maxWeight = 58.0,
		baseCoins = 1100,
		baseExp = 110,
		description = "Menyemburkan uap mendidih dari insangnya, tubuhnya membara bagai lahar cair dasar laut.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 80, 20),
		scale = 2.1,
	},
	{
		id = "MYT_DEEP_KRAKEN",
		name = "Kraken Laut Dalam Abyssal",
		rarity = "MYTHIC",
		minWeight = 25.0,
		maxWeight = 75.0,
		baseCoins = 1280,
		baseExp = 125,
		description = "Gurita raksasa bertentakel penghancur kapal yang bangkit dari kegelapan palung terdalam.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(150, 30, 80),
		scale = 2.3,
	},
	{
		id = "MYT_NEBULA_MANTA",
		name = "Pari Raksasa Nebula Galaksi",
		rarity = "MYTHIC",
		minWeight = 18.0,
		maxWeight = 55.0,
		baseCoins = 1120,
		baseExp = 112,
		description = "Sayap lebarnya memantulkan rasi bintang galaksi luar angkasa dengan pendar partikel kosmik.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(120, 50, 220),
		scale = 2.15,
	},
	{
		id = "MYT_GOLDEN_LEVIATHAN",
		name = "Leviathan Emas Primordial",
		rarity = "MYTHIC",
		minWeight = 28.0,
		maxWeight = 80.0,
		baseCoins = 1380,
		baseExp = 135,
		description = "Ular naga samudra kuno berkulit sisik emas keras tak tertembus senjata apapun.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 190, 20),
		scale = 2.4,
	},

	-- ==========================================
	-- TIER 6: SPECIAL (⭐⭐⭐⭐⭐⭐ | Level 20+)
	-- ==========================================
	{
		id = "SPE_POSEIDON_GODDESS",
		name = "Dewi Samudra Poseidon",
		rarity = "SPECIAL",
		minWeight = 35.0,
		maxWeight = 120.0,
		baseCoins = 3600,
		baseExp = 185,
		description = "Wujud personifikasi suci penguasa seluruh samudra raya bermahkotakan trisula cahaya mutiara.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(255, 60, 200),
		scale = 2.6,
	},
	{
		id = "SPE_COSMIC_STAR_DRAGON",
		name = "Naga Bintang Kosmik Astral",
		rarity = "SPECIAL",
		minWeight = 40.0,
		maxWeight = 140.0,
		baseCoins = 3900,
		baseExp = 200,
		description = "Makhluk surgawi penjaga poros semesta yang tercipta dari ledakan bintang supernova pertama.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(180, 80, 255),
		scale = 2.8,
	},
	{
		id = "SPE_ABYSS_LEVIATHAN",
		name = "Leviathan Abyss Kehancuran",
		rarity = "SPECIAL",
		minWeight = 50.0,
		maxWeight = 180.0,
		baseCoins = 4300,
		baseExp = 225,
		description = "Titik nol kegelapan absolut samudra, kehadirannya sanggup membelah lautan menjadi dua bagian.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(20, 20, 35),
		scale = 3.0,
	},
	{
		id = "SPE_ANCIENT_KRAKEN",
		name = "Kraken Kuno Abadi Titania",
		rarity = "SPECIAL",
		minWeight = 45.0,
		maxWeight = 160.0,
		baseCoins = 4100,
		baseExp = 215,
		description = "Penyangga dasar benua samudra yang telah tertidur lelap sejak zaman penciptaan dunia.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(200, 30, 110),
		scale = 2.9,
	},
	{
		id = "SPE_CELESTIAL_WHALE",
		name = "Dewa Paus Nebula Celestia",
		rarity = "SPECIAL",
		minWeight = 60.0,
		maxWeight = 200.0,
		baseCoins = 4600,
		baseExp = 250,
		description = "Paus raksasa pengembara dimensi kosmik yang melantunkan melodi harmoni abadi pencipta alam semesta.",
		favoriteZone = "SUMMIT_ABYSS",
		color = Color3.fromRGB(0, 255, 230),
		scale = 3.2,
	},
}

-- ============ INDEX TABLES ============
FishDefinitions.BY_ID = {}
FishDefinitions.BY_RARITY = {
	COMMON = {},
	RARE = {},
	SUPER_RARE = {},
	LEGENDARY = {},
	MYTHIC = {},
	SPECIAL = {},
}
FishDefinitions.BY_ZONE = {
	MELODY_BAY = {},
	TWIN_EYE_LAGOON = {},
	SUMMIT_ABYSS = {},
}

-- Bangun Indeks Otomatis
for _, fish in ipairs(FishDefinitions.CATALOG) do
	FishDefinitions.BY_ID[fish.id] = fish

	local rList = FishDefinitions.BY_RARITY[fish.rarity]
	if rList then
		table.insert(rList, fish)
	end

	local zList = FishDefinitions.BY_ZONE[fish.favoriteZone]
	if zList then
		table.insert(zList, fish)
	end
end

-- Aliases backward compatibility
FishDefinitions.BY_RARITY.EX = FishDefinitions.BY_RARITY.SPECIAL
FishDefinitions.BY_RARITY.UR = FishDefinitions.BY_RARITY.MYTHIC
FishDefinitions.BY_RARITY.SSR = FishDefinitions.BY_RARITY.LEGENDARY
FishDefinitions.BY_RARITY.SR = FishDefinitions.BY_RARITY.SUPER_RARE
FishDefinitions.BY_RARITY.SUPERRARE = FishDefinitions.BY_RARITY.SUPER_RARE

-- ============ PUBLIC QUERY METHODS ============
function FishDefinitions.GetFishById(id)
	return id and FishDefinitions.BY_ID[id] or nil
end

function FishDefinitions.GetFishByRarity(rarity, zoneId)
	rarity = tostring(rarity or "COMMON"):upper():gsub("%s+", "_")
	local list = FishDefinitions.BY_RARITY[rarity] or FishDefinitions.BY_RARITY.COMMON

	if not zoneId then
		return list
	end

	zoneId = tostring(zoneId):upper()
	local filtered = {}
	for _, fish in ipairs(list) do
		if fish.favoriteZone == zoneId or not fish.favoriteZone then
			table.insert(filtered, fish)
		end
	end

	-- Fallback ke seluruh list jika tidak ada spesifik di zona ini
	if #filtered == 0 then
		return list
	end

	return filtered
end

function FishDefinitions.GetRandomFish(rarity, zoneId)
	local candidates = FishDefinitions.GetFishByRarity(rarity, zoneId)
	if candidates and #candidates > 0 then
		return candidates[math.random(1, #candidates)]
	end
	return FishDefinitions.CATALOG[1]
end

function FishDefinitions.GetAllFish()
	return FishDefinitions.CATALOG
end

function FishDefinitions.GetFishCount()
	return #FishDefinitions.CATALOG
end

return FishDefinitions
