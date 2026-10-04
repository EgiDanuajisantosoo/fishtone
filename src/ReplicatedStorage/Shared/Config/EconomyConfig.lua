--[[
	EconomyConfig (ModuleScript)
	FISH!TUNE — Central Economy, Rods, Baits, Bag Upgrades & Valuation Config (FISH-024)

	Satu sumber kebenaran (Single Source of Truth) untuk seluruh sistem ekonomi game:
	1. Katalog Joran Pancing (Rods Catalog) dengan Stat Luck, Power, Reel Speed, Level Req, & Harga Koin.
	2. Katalog Umpan Pancing (Baits Catalog) dengan Konsumsi, Bonus Luck, Rarity Skew, & Harga Satuan/Paket.
	3. Sistem Peningkatan Kapasitas Tas Inventaris (Bag Upgrades).
	4. Formula Valuasi Penjualan Dinamis (Base Price, Weight Scaling, Mutation Multiplier, Rhythm Grade Multiplier).
]]

local EconomyConfig = {}

-- ============ 1. KATALOG JORAN PANCING (RODS) ============
EconomyConfig.RODS = {
	{
		id = "StarterRod",
		name = "Joran Bambu Pemula",
		levelReq = 1,
		price = 0,
		luckBonus = 5,
		castPowerMultiplier = 1.0,
		reelSpeedMultiplier = 1.0,
		description = "Joran pancing sederhana terbuat dari bambu pantai. Cocok untuk pemancing pemula di Teluk Melodi.",
		color = Color3.fromRGB(180, 140, 90),
		handleColor = Color3.fromRGB(110, 80, 50),
		accentColor = Color3.fromRGB(220, 200, 170),
		material = Enum.Material.Wood,
		scale = 1.0,
		tier = "COMMON",
		badge = "⭐ PEMULA",
	},
	{
		id = "BambooRod",
		name = "Joran Bambu Tempaan",
		levelReq = 2,
		price = 250,
		luckBonus = 14,
		castPowerMultiplier = 1.08,
		reelSpeedMultiplier = 1.05,
		description = "Bambu kuning pilihan yang diperkuat lilitan rotan laut. Menambah kelenturan dan jangkauan lemparan.",
		color = Color3.fromRGB(210, 180, 80),
		handleColor = Color3.fromRGB(130, 90, 40),
		accentColor = Color3.fromRGB(74, 222, 128),
		material = Enum.Material.WoodPlanks,
		scale = 1.02,
		tier = "RARE",
		badge = "🌿 ALAMI",
	},
	{
		id = "CarbonFiberRod",
		name = "Joran Karbon Presisi",
		levelReq = 5,
		price = 850,
		luckBonus = 30,
		castPowerMultiplier = 1.18,
		reelSpeedMultiplier = 1.12,
		description = "Dibuat dari serat karbon sintetis ringan dengan sensor getaran nada yang sensitif terhadap sambaran ikan langka.",
		color = Color3.fromRGB(45, 55, 72),
		handleColor = Color3.fromRGB(26, 32, 44),
		accentColor = Color3.fromRGB(56, 189, 248),
		material = Enum.Material.DiamondPlate,
		scale = 1.05,
		tier = "SUPER_RARE",
		badge = "⚡ MODERN",
	},
	{
		id = "HarmonicTuningRod",
		name = "Joran Resonansi Harmoni",
		levelReq = 10,
		price = 2400,
		luckBonus = 58,
		castPowerMultiplier = 1.30,
		reelSpeedMultiplier = 1.22,
		description = "Joran berukir garputala akustik kuno. Berdenting lembut saat kail dilempar dan memperluas ketukan perfect rhythm.",
		color = Color3.fromRGB(0, 210, 255),
		handleColor = Color3.fromRGB(15, 30, 60),
		accentColor = Color3.fromRGB(255, 230, 100),
		material = Enum.Material.Neon,
		scale = 1.08,
		tier = "SUPER_RARE",
		badge = "🎵 HARMONI",
	},
	{
		id = "AbyssalTridentRod",
		name = "Trisula Palung Abyssal",
		levelReq = 18,
		price = 7500,
		luckBonus = 105,
		castPowerMultiplier = 1.45,
		reelSpeedMultiplier = 1.35,
		description = "Pusaka kuno bertatahkan kristal obsidian dan karang laut dalam. Mampu menembus kedalaman palung tergelap.",
		color = Color3.fromRGB(168, 85, 247),
		handleColor = Color3.fromRGB(30, 15, 50),
		accentColor = Color3.fromRGB(236, 72, 153),
		material = Enum.Material.ForceField,
		scale = 1.12,
		tier = "LEGENDARY",
		badge = "🔱 PALUNG",
	},
	{
		id = "CelestialMelodyRod",
		name = "Joran Melodi Bintang Kosmik",
		levelReq = 30,
		price = 25000,
		luckBonus = 200,
		castPowerMultiplier = 1.65,
		reelSpeedMultiplier = 1.50,
		description = "Mahakarya para dewa samudra berlapis serpihan meteorit emas. Memancarkan aura kosmik dan menarik spesies mistis samudra.",
		color = Color3.fromRGB(251, 191, 36),
		handleColor = Color3.fromRGB(70, 40, 10),
		accentColor = Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		scale = 1.18,
		tier = "MYTHIC",
		badge = "👑 KOSMIK",
	},
}

-- Map lookup ID joran
EconomyConfig.RODS_BY_ID = {}
for _, rod in ipairs(EconomyConfig.RODS) do
	EconomyConfig.RODS_BY_ID[rod.id] = rod
end

-- ============ 2. KATALOG UMPAN (BAITS) ============
EconomyConfig.BAITS = {
	{
		id = "StandardWorm",
		name = "Cacing Pasir Segar",
		icon = "🪱",
		priceSingle = 15,
		packQuantity = 10,
		pricePack = 120, -- Diskon 20%
		luckBonus = 4,
		description = "Umpan cacing pasir standar yang disukai oleh sebagian besar ikan pesisir pantai.",
		tier = "COMMON",
		badge = "🪱 DASAR",
		color = Color3.fromRGB(200, 130, 100),
	},
	{
		id = "GlowShrimp",
		name = "Udang Fosfor Bercahaya",
		icon = "🦐",
		priceSingle = 45,
		packQuantity = 10,
		pricePack = 380, -- Diskon ~15%
		luckBonus = 14,
		rareWeightMultiplier = 1.25,
		description = "Udang karang yang memancarkan pendaran hijau fosfor di air gelap, menarik ikan langka lebih cepat.",
		tier = "RARE",
		badge = "✨ GLOW",
		color = Color3.fromRGB(74, 222, 128),
	},
	{
		id = "SirenChorusLure",
		name = "Umpan Kidung Siren",
		icon = "🐚",
		priceSingle = 130,
		packQuantity = 5,
		pricePack = 550, -- Diskon ~15%
		luckBonus = 32,
		rhythmToleranceBonus = 0.12,
		description = "Kerang berukir yang mengeluarkan getaran sonik musikal di bawah air, memperbesar toleransi ketukan rhythm.",
		tier = "SUPER_RARE",
		badge = "🎶 SIREN",
		color = Color3.fromRGB(56, 189, 248),
	},
	{
		id = "AbyssalNightshadeBait",
		name = "Ekstrak Rumput Abyssal",
		icon = "🌿",
		priceSingle = 380,
		packQuantity = 5,
		pricePack = 1600,
		luckBonus = 75,
		deepSeaBonus = 1.35,
		description = "Konsentrat lumut bercahaya dari palung terdalam. Aromanya sangat memikat ikan berkategori Legendary.",
		tier = "LEGENDARY",
		badge = "🌌 ABYSSAL",
		color = Color3.fromRGB(192, 132, 252),
	},
	{
		id = "GoldenSquidBait",
		name = "Cumi Emas Samudra Mulia",
		icon = "🦑",
		priceSingle = 1200,
		packQuantity = 3,
		pricePack = 3200,
		luckBonus = 160,
		mythicSpecialBonus = 1.50,
		description = "Umpan mewah bertatahkan minyak emas alami. Jaminan penarik predator purba dan spesies mitos.",
		tier = "MYTHIC",
		badge = "👑 MULIA",
		color = Color3.fromRGB(251, 191, 36),
	},
}

-- Map lookup ID umpan
EconomyConfig.BAITS_BY_ID = {}
for _, bait in ipairs(EconomyConfig.BAITS) do
	EconomyConfig.BAITS_BY_ID[bait.id] = bait
end

-- ============ 3. PENINGKATAN KAPASITAS TAS (BAG UPGRADES) ============
EconomyConfig.BAG_UPGRADES = {
	{
		tier = 1,
		name = "Tas Nelayan Kanvas",
		levelReq = 3,
		price = 350,
		extraSlots = 5,
		totalSlots = 40,
		description = "Tas kanvas tahan air dengan kompartemen ekstra +5 Slot.",
		badge = "🎒 TIER 1",
	},
	{
		tier = 2,
		name = "Ransel Kulit Kedap Air",
		levelReq = 7,
		price = 950,
		extraSlots = 5,
		totalSlots = 45,
		description = "Ransel kulit dilapisi getah damar untuk menambah +5 Slot penyimpanan.",
		badge = "🎒 TIER 2",
	},
	{
		tier = 3,
		name = "Kotak Pancing Karbon Ringan",
		levelReq = 12,
		price = 2500,
		extraSlots = 10,
		totalSlots = 55,
		description = "Tackle box modular berkekuatan tinggi dengan ekspansi +10 Slot.",
		badge = "🎒 TIER 3",
	},
	{
		tier = 4,
		name = "Koper Samudra Berpendingin",
		levelReq = 20,
		price = 6500,
		extraSlots = 10,
		totalSlots = 65,
		description = "Koper titanium bersensor pendingin es kering untuk menjaga kesegaran +10 Slot ikan.",
		badge = "🎒 TIER 4",
	},
	{
		tier = 5,
		name = "Peti Dimensi Mistis Samudra",
		levelReq = 30,
		price = 18000,
		extraSlots = 15,
		totalSlots = 80,
		description = "Artefak kantong ajaib ruang lipat samudra. Memberikan ekspansi maksimal +15 Slot (Total 80 Slot).",
		badge = "🎒 TIER 5 (MAX)",
	},
}

-- ============ 4. VALUASI HARGA JUAL & PENGGANDA (VALUATION FORMULAS) ============
EconomyConfig.VALUATION = {
	-- Pengganda Nilai Berdasarkan Akurasi / Grade Rhythm Minigame
	GRADE_MULTIPLIERS = {
		SS = 1.30, -- +30% Nilai Koin
		S  = 1.20, -- +20% Nilai Koin
		A  = 1.10, -- +10% Nilai Koin
		B  = 1.00, -- Standar
		C  = 0.90, -- -10% Nilai Koin
		D  = 0.80, -- -20% Nilai Koin
	},

	-- Pengganda Mutasi Langka
	MUTATION_MULTIPLIERS = {
		COSMIC  = 4.00,
		GOLDEN  = 2.80,
		SHINY   = 1.60,
		NONE    = 1.00,
	},

	-- Base Multiplier Bobot (Spesimen jumbo bernilai lebih tinggi)
	WEIGHT_SCALING_EXP = 0.25,
}

-- ============ 5. HELPER METHODS ============

function EconomyConfig.GetRod(rodId)
	return EconomyConfig.RODS_BY_ID[rodId] or EconomyConfig.RODS[1]
end

function EconomyConfig.GetBait(baitId)
	return EconomyConfig.BAITS_BY_ID[baitId]
end

function EconomyConfig.GetBagUpgrade(tier)
	return EconomyConfig.BAG_UPGRADES[tier]
end

function EconomyConfig.GetNextBagUpgrade(currentTier)
	currentTier = tonumber(currentTier) or 0
	local nextTier = currentTier + 1
	return EconomyConfig.BAG_UPGRADES[nextTier]
end

-- Menghitung total nilai jual ikan berdasarkan seluruh metadata
function EconomyConfig.CalculateSellValue(itemAttributes)
	if typeof(itemAttributes) ~= "table" then return 15 end

	local baseCoins = tonumber(itemAttributes.Coins) or tonumber(itemAttributes.baseCoins) or 15
	local grade = tostring(itemAttributes.Grade or "B"):upper()
	local gradeMult = EconomyConfig.VALUATION.GRADE_MULTIPLIERS[grade] or 1.0

	local mutType = tostring(itemAttributes.MutationType or "NONE"):upper()
	local mutMult = EconomyConfig.VALUATION.MUTATION_MULTIPLIERS[mutType] or 1.0

	-- Weight Scaling Bonus
	local weight = tonumber(itemAttributes.Weight) or 1.0
	local minWeight = tonumber(itemAttributes.minWeight) or 0.5
	local weightRatio = math.max(1.0, weight / math.max(0.1, minWeight))
	local weightMult = math.clamp(weightRatio ^ EconomyConfig.VALUATION.WEIGHT_SCALING_EXP, 1.0, 2.5)

	local finalCoins = math.floor(baseCoins * gradeMult * mutMult * weightMult)
	return math.max(1, finalCoins)
end

return EconomyConfig
