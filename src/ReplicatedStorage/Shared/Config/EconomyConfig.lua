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
	-- ==================== 🎹 PIANO INSTRUMENT RODS ====================
	{
		id = "StarterRod",
		name = "Joran Bambu Pemula",
		instrumentType = "PIANO",
		levelReq = 1,
		price = 0,
		luckBonus = 5,
		castPowerMultiplier = 1.0,
		reelSpeedMultiplier = 1.0,
		description = "Joran bambu nada dasar untuk pemula di Teluk Melodi. Mengalunkan not tuts piano lembut saat mengait ikan.",
		color = Color3.fromRGB(180, 140, 90),
		handleColor = Color3.fromRGB(110, 80, 50),
		accentColor = Color3.fromRGB(220, 200, 170),
		material = Enum.Material.Wood,
		scale = 1.0,
		tier = "COMMON",
		badge = "⭐ PEMULA",
	},
	{
		id = "HarmonicTuningRod",
		name = "Joran Grand Piano Harmoni",
		instrumentType = "PIANO",
		levelReq = 6,
		price = 1400,
		luckBonus = 38,
		castPowerMultiplier = 1.22,
		reelSpeedMultiplier = 1.15,
		description = "Joran berukir tuts piano gading hitam-putih. Menghasilkan resonansi akor piano yang memperluas ketukan perfect.",
		color = Color3.fromRGB(24, 28, 38),
		handleColor = Color3.fromRGB(240, 240, 245),
		accentColor = Color3.fromRGB(0, 210, 255),
		material = Enum.Material.SmoothPlastic,
		scale = 1.06,
		tier = "SUPER_RARE",
		badge = "🎹 GRAND PIANO",
	},
	{
		id = "CrystalSonataRod",
		name = "Joran Sonata Kristal Resonansi",
		instrumentType = "PIANO",
		levelReq = 18,
		price = 8500,
		luckBonus = 115,
		castPowerMultiplier = 1.48,
		reelSpeedMultiplier = 1.38,
		description = "Ditempa dari kristal resonansi laut dalam yang memantulkan nada piano murni dan memikat ikan legendaris.",
		color = Color3.fromRGB(147, 197, 253),
		handleColor = Color3.fromRGB(30, 58, 138),
		accentColor = Color3.fromRGB(219, 234, 254),
		material = Enum.Material.Glass,
		scale = 1.12,
		tier = "LEGENDARY",
		badge = "🎹 SONATA KRISTAL",
	},

	-- ==================== 🎸 GUITAR INSTRUMENT RODS ====================
	{
		id = "BambooRod",
		name = "Joran Gitar Akustik Mahoni",
		instrumentType = "GUITAR",
		levelReq = 2,
		price = 280,
		luckBonus = 15,
		castPowerMultiplier = 1.10,
		reelSpeedMultiplier = 1.06,
		description = "Joran berbadan kayu mahoni dengan senar nilon akustik. Memainkan riff petikan senar klasik yang merdu.",
		color = Color3.fromRGB(180, 83, 9),
		handleColor = Color3.fromRGB(120, 53, 15),
		accentColor = Color3.fromRGB(245, 158, 11),
		material = Enum.Material.WoodPlanks,
		scale = 1.03,
		tier = "RARE",
		badge = "🎸 AKUSTIK",
	},
	{
		id = "CarbonFiberRod",
		name = "Joran Gitar Elektrik Overdrive",
		instrumentType = "GUITAR",
		levelReq = 10,
		price = 2800,
		luckBonus = 62,
		castPowerMultiplier = 1.32,
		reelSpeedMultiplier = 1.25,
		description = "Dibuat dari serat karbon sintetis ringan dan pickup elektrik. Menyalurkan riff solo distorsi bertenaga tinggi.",
		color = Color3.fromRGB(220, 38, 38),
		handleColor = Color3.fromRGB(23, 23, 23),
		accentColor = Color3.fromRGB(250, 204, 21),
		material = Enum.Material.DiamondPlate,
		scale = 1.08,
		tier = "SUPER_RARE",
		badge = "🎸 ELEKTRIK",
	},
	{
		id = "AbyssalTridentRod",
		name = "Joran Trisula Heavy Metal Palung",
		instrumentType = "GUITAR",
		levelReq = 22,
		price = 11500,
		luckBonus = 140,
		castPowerMultiplier = 1.55,
		reelSpeedMultiplier = 1.42,
		description = "Gitar trisula obsidian palung laut dalam dengan senar kawat baja tebal. Memuntahkan riff heavy metal ekstrem.",
		color = Color3.fromRGB(147, 51, 234),
		handleColor = Color3.fromRGB(30, 10, 45),
		accentColor = Color3.fromRGB(244, 63, 94),
		material = Enum.Material.ForceField,
		scale = 1.15,
		tier = "LEGENDARY",
		badge = "🎸 HEAVY METAL",
	},

	-- ==================== 🥁 DRUM INSTRUMENT RODS ====================
	{
		id = "TribalPercussionRod",
		name = "Joran Perkusi Ritme Rimba",
		instrumentType = "DRUM",
		levelReq = 4,
		price = 680,
		luckBonus = 26,
		castPowerMultiplier = 1.16,
		reelSpeedMultiplier = 1.12,
		description = "Joran berkepala stik drum perkusi kayu eboni. Memancarkan gelombang ketukan ritme rimba yang menghentak samudra.",
		color = Color3.fromRGB(202, 138, 4),
		handleColor = Color3.fromRGB(113, 63, 18),
		accentColor = Color3.fromRGB(234, 88, 12),
		material = Enum.Material.Wood,
		scale = 1.04,
		tier = "RARE",
		badge = "🥁 PERKUSI RIMBA",
	},
	{
		id = "SynthwaveDrumRod",
		name = "Joran Drum Pad Neon Elektronik",
		instrumentType = "DRUM",
		levelReq = 14,
		price = 5200,
		luckBonus = 90,
		castPowerMultiplier = 1.40,
		reelSpeedMultiplier = 1.30,
		description = "Joran drum pad digital 16-pad beriluminasi RGB synthwave. Menghasilkan dentuman bass elektro 80s yang menggetarkan ombak.",
		color = Color3.fromRGB(236, 72, 153),
		handleColor = Color3.fromRGB(15, 23, 42),
		accentColor = Color3.fromRGB(6, 182, 212),
		material = Enum.Material.Neon,
		scale = 1.10,
		tier = "SUPER_RARE",
		badge = "🥁 SYNTH DRUM",
	},
	{
		id = "CelestialMelodyRod",
		name = "Joran Melodi Bintang Kosmik",
		instrumentType = "DRUM",
		levelReq = 30,
		price = 25000,
		luckBonus = 200,
		castPowerMultiplier = 1.65,
		reelSpeedMultiplier = 1.50,
		description = "Mahakarya para dewa bertatahkan serpihan meteorit emas. Memancarkan aura ketukan kosmik semesta yang memikat spesies purba mitos.",
		color = Color3.fromRGB(251, 191, 36),
		handleColor = Color3.fromRGB(69, 26, 3),
		accentColor = Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		scale = 1.18,
		tier = "MYTHIC",
		badge = "👑 DRUM KOSMIK",
	},
}

-- Map lookup ID joran (Termasuk alias untuk kompatibilitas penuh)
EconomyConfig.RODS_BY_ID = {}
for _, rod in ipairs(EconomyConfig.RODS) do
	EconomyConfig.RODS_BY_ID[rod.id] = rod
end

-- Aliases untuk backward compatibility
if EconomyConfig.RODS_BY_ID["BambooRod"] then
	EconomyConfig.RODS_BY_ID["AcousticGuitarRod"] = EconomyConfig.RODS_BY_ID["BambooRod"]
end
if EconomyConfig.RODS_BY_ID["CarbonFiberRod"] then
	EconomyConfig.RODS_BY_ID["ElectricOverdriveRod"] = EconomyConfig.RODS_BY_ID["CarbonFiberRod"]
end
if EconomyConfig.RODS_BY_ID["AbyssalTridentRod"] then
	EconomyConfig.RODS_BY_ID["AbyssalMetalRod"] = EconomyConfig.RODS_BY_ID["AbyssalTridentRod"]
end
if EconomyConfig.RODS_BY_ID["HarmonicTuningRod"] then
	EconomyConfig.RODS_BY_ID["HarmonicGrandRod"] = EconomyConfig.RODS_BY_ID["HarmonicTuningRod"]
end
if EconomyConfig.RODS_BY_ID["CelestialMelodyRod"] then
	EconomyConfig.RODS_BY_ID["CelestialCosmicRod"] = EconomyConfig.RODS_BY_ID["CelestialMelodyRod"]
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
