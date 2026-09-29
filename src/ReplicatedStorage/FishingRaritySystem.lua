--[[
	FishingRaritySystem (ModuleScript)
	Sistem Rarity Dinamis Berbasis Total Luck (1 - 100) & Hierarchical Pity System
	dengan 6 Tingkatan Rarity & Jumlah Nada Target Sesuai Desain:
	
	1. COMMON     -> 30 Nada  (Abu-abu)
	2. RARE       -> 60 Nada  (Biru)
	3. SUPER RARE -> 100 Nada (Ungu)
	4. LEGENDARY  -> 150 Nada (Emas)
	5. MYTHIC     -> 200 Nada (Merah)
	6. SPECIAL    -> 300 Nada (Pelangi / Special)
	
	Hierarchical Pity Limits:
	- LEGENDARY : 100 attempt
	- MYTHIC    : 500 attempt
	- SPECIAL   : 1000 attempt
]]

local FishingRaritySystem = {}

FishingRaritySystem.MIN_LUCK = 1
FishingRaritySystem.MAX_LUCK = 100

FishingRaritySystem.PITY_LIMITS = {
	LEGENDARY = 100,
	MYTHIC = 500,
	SPECIAL = 1000,
	-- Aliases
	SSR = 100,
	UR = 500,
	EX = 1000,
}

-- Definisi 6 Tier Rarity & Visual & Jumlah Nada Target
FishingRaritySystem.TIERS = {
	SPECIAL = {
		name = "SPECIAL",
		displayName = "SPECIAL",
		targetNotes = 300,       -- 300 Nada
		stars = "⭐⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(255, 60, 200),
		badgeColor = Color3.fromRGB(255, 120, 30),
		order = 6,
		baseStart = 0.15,        -- Start 15% (45 nada awal)
		basePenaltyNotes = 45,   -- Penalti miss 45 nada (~15%)
		speed = 0.54,
	},
	MYTHIC = {
		name = "MYTHIC",
		displayName = "MYTHIC",
		targetNotes = 200,       -- 200 Nada
		stars = "⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(235, 45, 45),
		badgeColor = Color3.fromRGB(195, 25, 25),
		order = 5,
		baseStart = 0.20,        -- Start 20% (40 nada awal)
		basePenaltyNotes = 30,   -- Penalti miss 30 nada (~15%)
		speed = 0.49,
	},
	LEGENDARY = {
		name = "LEGENDARY",
		displayName = "LEGENDARY",
		targetNotes = 150,       -- 150 Nada
		stars = "⭐⭐⭐⭐",
		color = Color3.fromRGB(240, 185, 20),
		badgeColor = Color3.fromRGB(210, 160, 10),
		order = 4,
		baseStart = 0.25,        -- Start 25% (38 nada awal)
		basePenaltyNotes = 20,   -- Penalti miss 20 nada (~13%)
		speed = 0.44,
	},
	SUPER_RARE = {
		name = "SUPER RARE",
		displayName = "SUPER RARE",
		targetNotes = 100,       -- 100 Nada
		stars = "⭐⭐⭐",
		color = Color3.fromRGB(170, 50, 240),
		badgeColor = Color3.fromRGB(140, 30, 210),
		order = 3,
		baseStart = 0.30,        -- Start 30% (30 nada awal)
		basePenaltyNotes = 12,   -- Penalti miss 12 nada (~12%)
		speed = 0.39,
	},
	RARE = {
		name = "RARE",
		displayName = "RARE",
		targetNotes = 60,        -- 60 Nada
		stars = "⭐⭐",
		color = Color3.fromRGB(0, 140, 255),
		badgeColor = Color3.fromRGB(0, 110, 220),
		order = 2,
		baseStart = 0.35,        -- Start 35% (21 nada awal)
		basePenaltyNotes = 6,    -- Penalti miss 6 nada (~10%)
		speed = 0.34,
	},
	COMMON = {
		name = "COMMON",
		displayName = "COMMON",
		targetNotes = 30,        -- 30 Nada
		stars = "⭐",
		color = Color3.fromRGB(150, 155, 165),
		badgeColor = Color3.fromRGB(120, 125, 135),
		order = 1,
		baseStart = 0.40,        -- Start 40% (12 nada awal)
		basePenaltyNotes = 3,    -- Penalti miss 3 nada (~10%)
		speed = 0.30,
	},
}

-- Mapping alias
FishingRaritySystem.TIERS.EX = FishingRaritySystem.TIERS.SPECIAL
FishingRaritySystem.TIERS.UR = FishingRaritySystem.TIERS.MYTHIC
FishingRaritySystem.TIERS.SSR = FishingRaritySystem.TIERS.LEGENDARY
FishingRaritySystem.TIERS.SUPERRARE = FishingRaritySystem.TIERS.SUPER_RARE
FishingRaritySystem.TIERS.SR = FishingRaritySystem.TIERS.SUPER_RARE
FishingRaritySystem.TIERS.SuperRare = FishingRaritySystem.TIERS.SUPER_RARE
FishingRaritySystem.TIERS.Rare = FishingRaritySystem.TIERS.RARE
FishingRaritySystem.TIERS.Common = FishingRaritySystem.TIERS.COMMON

-- Database Nama Ikan per Rarity Tier
FishingRaritySystem.FISH_DATABASE = {
	SPECIAL = {
		"Dewi Samudra Poseidon",
		"Naga Bintang Kosmik",
		"Leviathan Abyss",
		"Kraken Kuno Abadi"
	},
	MYTHIC = {
		"Hiu Megalodon Merah",
		"Naga Laut Api",
		"Kraken Laut Dalam",
		"Pari Raksasa Nebula"
	},
	LEGENDARY = {
		"Naga Laut Mistis",
		"Hiu Emas Murni",
		"Ikan Mas Raja",
		"Belida Emas Suci"
	},
	SUPER_RARE = {
		"Arapaima Raksasa",
		"Pari Listrik Laut",
		"Lele Monster Raksasa",
		"Toman Raja Hitam"
	},
	RARE = {
		"Gurame Super",
		"Ikan Salmon Perak",
		"Bawal Emas",
		"Kakap Merah Segar"
	},
	COMMON = {
		"Ikan Mas Kecil",
		"Lele Lokal",
		"Mujair Sungai",
		"Ikan Nila Segar",
		"Ikan Cupang Liar"
	}
}

-- Aliases database
FishingRaritySystem.FISH_DATABASE.EX = FishingRaritySystem.FISH_DATABASE.SPECIAL
FishingRaritySystem.FISH_DATABASE.UR = FishingRaritySystem.FISH_DATABASE.MYTHIC
FishingRaritySystem.FISH_DATABASE.SSR = FishingRaritySystem.FISH_DATABASE.LEGENDARY
FishingRaritySystem.FISH_DATABASE.SUPERRARE = FishingRaritySystem.FISH_DATABASE.SUPER_RARE
FishingRaritySystem.FISH_DATABASE.SR = FishingRaritySystem.FISH_DATABASE.SUPER_RARE
FishingRaritySystem.FISH_DATABASE.SuperRare = FishingRaritySystem.FISH_DATABASE.SUPER_RARE
FishingRaritySystem.FISH_DATABASE.Rare = FishingRaritySystem.FISH_DATABASE.RARE
FishingRaritySystem.FISH_DATABASE.Common = FishingRaritySystem.FISH_DATABASE.COMMON

-- Urutan Pengecekan Probabilitas
FishingRaritySystem.RARITY_ORDER = {
	"COMMON",
	"RARE",
	"SUPER_RARE",
	"LEGENDARY",
	"MYTHIC",
	"SPECIAL"
}

-- 1. Hitung Distribusi Probabilitas Berdasarkan Nilai Luck (1 - 100)
function FishingRaritySystem.GetRarityChances(luck)
	luck = math.clamp(tonumber(luck) or 1, FishingRaritySystem.MIN_LUCK, FishingRaritySystem.MAX_LUCK)
	local t = (luck - FishingRaritySystem.MIN_LUCK) / (FishingRaritySystem.MAX_LUCK - FishingRaritySystem.MIN_LUCK)

	return {
		COMMON = 70 * (1 - t),
		RARE = 30 * (1 - t),
		SUPER_RARE = 40 * t,
		LEGENDARY = 48 * t,
		MYTHIC = 9 * t,
		SPECIAL = 3 * t,
		-- Aliases
		Common = 70 * (1 - t),
		Rare = 30 * (1 - t),
		SuperRare = 40 * t,
		SSR = 48 * t,
		UR = 9 * t,
		EX = 3 * t,
	}
end

-- 2. Roll RNG Berdasarkan Distribusi Peluang Luck
function FishingRaritySystem.RollRarity(luck)
	local chances = FishingRaritySystem.GetRarityChances(luck)
	local roll = math.random() * 100
	local cumulative = 0

	for _, rarity in ipairs(FishingRaritySystem.RARITY_ORDER) do
		cumulative += chances[rarity]
		if roll <= cumulative then
			return rarity
		end
	end

	return "COMMON"
end

-- 3. Evaluasi Pity System Hierarkis
function FishingRaritySystem.EvaluateWithPity(luck, pityState)
	pityState = pityState or { SPECIAL = 0, MYTHIC = 0, LEGENDARY = 0 }

	local pSpecial = pityState.SPECIAL or pityState.EX or 0
	local pMythic = pityState.MYTHIC or pityState.UR or 0
	local pLegendary = pityState.LEGENDARY or pityState.SSR or 0

	-- Cek Pity dari tingkat tertinggi
	if pSpecial >= FishingRaritySystem.PITY_LIMITS.SPECIAL then
		return "SPECIAL", true
	elseif pMythic >= FishingRaritySystem.PITY_LIMITS.MYTHIC then
		return "MYTHIC", true
	elseif pLegendary >= FishingRaritySystem.PITY_LIMITS.LEGENDARY then
		return "LEGENDARY", true
	end

	return FishingRaritySystem.RollRarity(luck), false
end

-- 4. Perbarui State Pity setelah Ikan Berhasil Ditangkap
function FishingRaritySystem.UpdatePityOnCatch(pityState, obtainedRarity)
	pityState = pityState or {}
	local r = tostring(obtainedRarity):upper()

	if r == "SPECIAL" or r == "EX" then
		pityState.SPECIAL = 0
		pityState.MYTHIC = 0
		pityState.LEGENDARY = 0
		pityState.EX = 0
		pityState.UR = 0
		pityState.SSR = 0
	elseif r == "MYTHIC" or r == "UR" then
		pityState.MYTHIC = 0
		pityState.LEGENDARY = 0
		pityState.UR = 0
		pityState.SSR = 0
		pityState.SPECIAL = (pityState.SPECIAL or pityState.EX or 0) + 1
		pityState.EX = pityState.SPECIAL
	elseif r == "LEGENDARY" or r == "SSR" then
		pityState.LEGENDARY = 0
		pityState.SSR = 0
		pityState.MYTHIC = (pityState.MYTHIC or pityState.UR or 0) + 1
		pityState.UR = pityState.MYTHIC
		pityState.SPECIAL = (pityState.SPECIAL or pityState.EX or 0) + 1
		pityState.EX = pityState.SPECIAL
	else
		-- COMMON, RARE, SUPER_RARE menaikkan semua pity counter
		pityState.LEGENDARY = (pityState.LEGENDARY or pityState.SSR or 0) + 1
		pityState.SSR = pityState.LEGENDARY
		pityState.MYTHIC = (pityState.MYTHIC or pityState.UR or 0) + 1
		pityState.UR = pityState.MYTHIC
		pityState.SPECIAL = (pityState.SPECIAL or pityState.EX or 0) + 1
		pityState.EX = pityState.SPECIAL
	end

	return pityState
end

-- 5. Ambil Ikan Acak dari Tier
function FishingRaritySystem.GetRandomFishName(rarity)
	local tierKey = tostring(rarity):upper()
	local list = FishingRaritySystem.FISH_DATABASE[tierKey] or FishingRaritySystem.FISH_DATABASE.COMMON
	return list[math.random(1, #list)]
end

-- 6. Helper Standarisasi Tier
function FishingRaritySystem.GetTierData(tierName)
	local key = tostring(tierName or "COMMON"):upper():gsub("%s+", "_")
	return FishingRaritySystem.TIERS[key] or FishingRaritySystem.TIERS.COMMON
end

return FishingRaritySystem
