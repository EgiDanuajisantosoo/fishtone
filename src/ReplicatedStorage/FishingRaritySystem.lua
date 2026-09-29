--[[
	FishingRaritySystem (ModuleScript)
	Sistem Rarity Dinamis Berbasis Total Luck (1 - 100) & Hierarchical Pity System.
	
	Rarity Tiers (6 Tingkat):
	1. Common (C)
	2. Rare (R)
	3. SuperRare (SR)
	4. SSR
	5. UR
	6. EX
	
	Formula Gradual Luck Interpolation:
	- MIN_LUCK = 1  -> C: 70%, R: 30%, SR: 0%, SSR: 0%, UR: 0%, EX: 0%
	- MAX_LUCK = 100 -> C: 0%,  R: 0%,  SR: 40%, SSR: 48%, UR: 9%, EX: 3%
	- t = (luck - 1) / 99
	
	Hierarchical Pity Limits:
	- SSR : 100 attempt
	- UR  : 500 attempt
	- EX  : 1000 attempt
]]

local FishingRaritySystem = {}

FishingRaritySystem.MIN_LUCK = 1
FishingRaritySystem.MAX_LUCK = 100

FishingRaritySystem.PITY_LIMITS = {
	SSR = 100,
	UR = 500,
	EX = 1000,
}

-- Definisi 6 Tier Rarity & Visual
FishingRaritySystem.TIERS = {
	EX = {
		name = "EX",
		displayName = "EX (Transcendental)",
		stars = "⭐⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(255, 30, 200),
		badgeColor = Color3.fromRGB(255, 0, 180),
		order = 6,
		-- Mini-game Piano Tiles parameter
		baseStart = 0.18,       -- Start 18%
		baseHitGain = 0.055,    -- Tambah 5.5% per hit
		comboHitGain = 0.085,   -- Tambah 8.5% saat combo
		baseMissPenalty = 0.24, -- Kurang 24% saat salah
		speed = 0.54,
	},
	UR = {
		name = "UR",
		displayName = "UR (Ultra Rare)",
		stars = "⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(255, 60, 60),
		badgeColor = Color3.fromRGB(230, 40, 40),
		order = 5,
		baseStart = 0.22,       -- Start 22%
		baseHitGain = 0.065,
		comboHitGain = 0.095,
		baseMissPenalty = 0.20,
		speed = 0.49,
	},
	SSR = {
		name = "SSR",
		displayName = "SSR (Super Super Rare)",
		stars = "⭐⭐⭐⭐",
		color = Color3.fromRGB(255, 215, 0),
		badgeColor = Color3.fromRGB(240, 195, 20),
		order = 4,
		baseStart = 0.26,       -- Start 26%
		baseHitGain = 0.075,
		comboHitGain = 0.11,
		baseMissPenalty = 0.17,
		speed = 0.44,
	},
	SuperRare = {
		name = "SuperRare",
		displayName = "Super Rare (SR)",
		stars = "⭐⭐⭐",
		color = Color3.fromRGB(190, 70, 255),
		badgeColor = Color3.fromRGB(170, 50, 240),
		order = 3,
		baseStart = 0.32,       -- Start 32%
		baseHitGain = 0.09,
		comboHitGain = 0.13,
		baseMissPenalty = 0.14,
		speed = 0.39,
	},
	Rare = {
		name = "Rare",
		displayName = "Rare (R)",
		stars = "⭐⭐",
		color = Color3.fromRGB(0, 185, 255),
		badgeColor = Color3.fromRGB(0, 160, 240),
		order = 2,
		baseStart = 0.38,       -- Start 38%
		baseHitGain = 0.11,
		comboHitGain = 0.15,
		baseMissPenalty = 0.11,
		speed = 0.34,
	},
	Common = {
		name = "Common",
		displayName = "Common (C)",
		stars = "⭐",
		color = Color3.fromRGB(170, 210, 240),
		badgeColor = Color3.fromRGB(150, 190, 220),
		order = 1,
		baseStart = 0.44,       -- Start 44%
		baseHitGain = 0.13,
		comboHitGain = 0.18,
		baseMissPenalty = 0.08,
		speed = 0.30,
	},
}

-- Database Nama Ikan per Rarity Tier
FishingRaritySystem.FISH_DATABASE = {
	EX = {
		"Leviathan Abyss",
		"Naga Bintang Kosmik",
		"Dewi Laut Poseidon",
		"Kraken Purba Kuno"
	},
	UR = {
		"Hiu Megalodon Merah",
		"Naga Laut Api",
		"Kraken Laut Dalam",
		"Pari Raksasa Nebula"
	},
	SSR = {
		"Naga Laut Mistis",
		"Hiu Emas Murni",
		"Ikan Mas Raja",
		"Belida Emas Suci"
	},
	SuperRare = {
		"Arapaima Raksasa",
		"Pari Listrik Laut",
		"Lele Monster Raksasa",
		"Toman Raja Hitam"
	},
	Rare = {
		"Gurame Super",
		"Ikan Salmon Perak",
		"Bawal Emas",
		"Kakap Merah Segar"
	},
	Common = {
		"Ikan Mas Kecil",
		"Lele Lokal",
		"Mujair Sungai",
		"Ikan Nila Segar",
		"Ikan Cupang Liar"
	}
}

-- Urutan Pengecekan Probabilitas
FishingRaritySystem.RARITY_ORDER = {
	"Common",
	"Rare",
	"SuperRare",
	"SSR",
	"UR",
	"EX"
}

-- 1. Hitung Distribusi Probabilitas Berdasarkan Nilai Luck (1 - 100)
function FishingRaritySystem.GetRarityChances(luck)
	luck = math.clamp(tonumber(luck) or 1, FishingRaritySystem.MIN_LUCK, FishingRaritySystem.MAX_LUCK)
	local t = (luck - FishingRaritySystem.MIN_LUCK) / (FishingRaritySystem.MAX_LUCK - FishingRaritySystem.MIN_LUCK)

	return {
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

	return "Common"
end

-- 3. Evaluasi Pity System Hierarkis
function FishingRaritySystem.EvaluateWithPity(luck, pityState)
	pityState = pityState or { SSR = 0, UR = 0, EX = 0 }

	-- Cek Pity dari tingkat tertinggi
	if (pityState.EX or 0) >= FishingRaritySystem.PITY_LIMITS.EX then
		return "EX", true
	elseif (pityState.UR or 0) >= FishingRaritySystem.PITY_LIMITS.UR then
		return "UR", true
	elseif (pityState.SSR or 0) >= FishingRaritySystem.PITY_LIMITS.SSR then
		return "SSR", true
	end

	-- Jika tidak kena pity, gunakan Roll RNG berbasis Luck
	return FishingRaritySystem.RollRarity(luck), false
end

-- 4. Perbarui State Pity setelah Ikan Berhasil Ditangkap
function FishingRaritySystem.UpdatePityOnCatch(pityState, obtainedRarity)
	pityState = pityState or { SSR = 0, UR = 0, EX = 0 }

	if obtainedRarity == "EX" then
		pityState.EX = 0
		pityState.UR = 0
		pityState.SSR = 0
	elseif obtainedRarity == "UR" then
		pityState.UR = 0
		pityState.SSR = 0
		pityState.EX = (pityState.EX or 0) + 1
	elseif obtainedRarity == "SSR" then
		pityState.SSR = 0
		pityState.UR = (pityState.UR or 0) + 1
		pityState.EX = (pityState.EX or 0) + 1
	else
		-- Common, Rare, SuperRare menaikkan semua pity counter
		pityState.SSR = (pityState.SSR or 0) + 1
		pityState.UR = (pityState.UR or 0) + 1
		pityState.EX = (pityState.EX or 0) + 1
	end

	return pityState
end

-- 5. Ambil Ikan Acak dari Tier
function FishingRaritySystem.GetRandomFishName(rarity)
	local list = FishingRaritySystem.FISH_DATABASE[rarity] or FishingRaritySystem.FISH_DATABASE.Common
	return list[math.random(1, #list)]
end

return FishingRaritySystem
