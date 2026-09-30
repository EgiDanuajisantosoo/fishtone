--[[
	FishingRaritySystem (ModuleScript)
	Sistem Rarity Server-Authoritative Berbasis Weighted Base Table,
	Soft Level Gating, Effective Luck Scaling, dan Hierarchical Pity System.
	
	6 Tingkatan Rarity & Target Nada:
	1. COMMON     -> 30 Nada  (Abu-abu)
	2. RARE       -> 60 Nada  (Biru)
	3. SUPER RARE -> 100 Nada (Ungu)
	4. LEGENDARY  -> 150 Nada (Emas)       - Pity: 100
	5. MYTHIC     -> 200 Nada (Merah)      - Pity: 500
	6. SPECIAL    -> 300 Nada (Pelangi)    - Pity: 1000
]]

local FishingRaritySystem = {}

FishingRaritySystem.MIN_LUCK = 1
FishingRaritySystem.MAX_LUCK = 150

FishingRaritySystem.PITY_LIMITS = {
	LEGENDARY = 100,
	MYTHIC = 500,
	SPECIAL = 1000,
	-- Aliases
	SSR = 100,
	UR = 500,
	EX = 1000,
}

-- Definisi 6 Tier Rarity & Visual & Target Nada
FishingRaritySystem.TIERS = {
	SPECIAL = {
		name = "SPECIAL",
		displayName = "SPECIAL",
		targetNotes = 300,
		stars = "⭐⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(255, 60, 200),
		badgeColor = Color3.fromRGB(255, 120, 30),
		order = 6,
		basePenaltyNotes = 45,
		speed = 0.54,
	},
	MYTHIC = {
		name = "MYTHIC",
		displayName = "MYTHIC",
		targetNotes = 200,
		stars = "⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(235, 45, 45),
		badgeColor = Color3.fromRGB(195, 25, 25),
		order = 5,
		basePenaltyNotes = 30,
		speed = 0.49,
	},
	LEGENDARY = {
		name = "LEGENDARY",
		displayName = "LEGENDARY",
		targetNotes = 150,
		stars = "⭐⭐⭐⭐",
		color = Color3.fromRGB(240, 185, 20),
		badgeColor = Color3.fromRGB(210, 160, 10),
		order = 4,
		basePenaltyNotes = 20,
		speed = 0.44,
	},
	SUPER_RARE = {
		name = "SUPER RARE",
		displayName = "SUPER RARE",
		targetNotes = 100,
		stars = "⭐⭐⭐",
		color = Color3.fromRGB(170, 50, 240),
		badgeColor = Color3.fromRGB(140, 30, 210),
		order = 3,
		basePenaltyNotes = 12,
		speed = 0.39,
	},
	RARE = {
		name = "RARE",
		displayName = "RARE",
		targetNotes = 60,
		stars = "⭐⭐",
		color = Color3.fromRGB(0, 140, 255),
		badgeColor = Color3.fromRGB(0, 110, 220),
		order = 2,
		basePenaltyNotes = 6,
		speed = 0.34,
	},
	COMMON = {
		name = "COMMON",
		displayName = "COMMON",
		targetNotes = 30,
		stars = "⭐",
		color = Color3.fromRGB(150, 155, 165),
		badgeColor = Color3.fromRGB(120, 125, 135),
		order = 1,
		basePenaltyNotes = 3,
		speed = 0.30,
	},
}

-- Aliases backward compatibility
FishingRaritySystem.TIERS.EX = FishingRaritySystem.TIERS.SPECIAL
FishingRaritySystem.TIERS.UR = FishingRaritySystem.TIERS.MYTHIC
FishingRaritySystem.TIERS.SSR = FishingRaritySystem.TIERS.LEGENDARY
FishingRaritySystem.TIERS.SUPERRARE = FishingRaritySystem.TIERS.SUPER_RARE
FishingRaritySystem.TIERS.SR = FishingRaritySystem.TIERS.SUPER_RARE
FishingRaritySystem.TIERS.SuperRare = FishingRaritySystem.TIERS.SUPER_RARE
FishingRaritySystem.TIERS.Rare = FishingRaritySystem.TIERS.RARE
FishingRaritySystem.TIERS.Common = FishingRaritySystem.TIERS.COMMON

-- Bobot Dasar Loot Table (Total Base Weight = 10,000)
local BASE_WEIGHTS = {
	COMMON = 7500,     -- ~75.0%
	RARE = 2000,       -- ~20.0%
	SUPER_RARE = 450,  -- ~4.5%
	LEGENDARY = 45,    -- ~0.45%
	MYTHIC = 4,        -- ~0.04%
	SPECIAL = 1,       -- ~0.01%
}

-- Database Ikan dengan Statistik Bobot (Kg), Nilai Koin, dan EXP
FishingRaritySystem.FISH_DATABASE = {
	SPECIAL = {
		{ name = "Dewi Samudra Poseidon", minWeight = 120.0, maxWeight = 350.0, baseCoins = 2500, baseExp = 1200 },
		{ name = "Naga Bintang Kosmik", minWeight = 150.0, maxWeight = 420.0, baseCoins = 3000, baseExp = 1500 },
		{ name = "Leviathan Abyss", minWeight = 200.0, maxWeight = 500.0, baseCoins = 3500, baseExp = 1800 },
		{ name = "Kraken Kuno Abadi", minWeight = 180.0, maxWeight = 450.0, baseCoins = 2800, baseExp = 1400 }
	},
	MYTHIC = {
		{ name = "Hiu Megalodon Merah", minWeight = 60.0, maxWeight = 140.0, baseCoins = 950, baseExp = 500 },
		{ name = "Naga Laut Api", minWeight = 50.0, maxWeight = 120.0, baseCoins = 850, baseExp = 450 },
		{ name = "Kraken Laut Dalam", minWeight = 70.0, maxWeight = 160.0, baseCoins = 1050, baseExp = 550 },
		{ name = "Pari Raksasa Nebula", minWeight = 45.0, maxWeight = 110.0, baseCoins = 800, baseExp = 420 }
	},
	LEGENDARY = {
		{ name = "Naga Laut Mistis", minWeight = 25.0, maxWeight = 55.0, baseCoins = 400, baseExp = 220 },
		{ name = "Hiu Emas Murni", minWeight = 30.0, maxWeight = 65.0, baseCoins = 450, baseExp = 250 },
		{ name = "Ikan Mas Raja", minWeight = 18.0, maxWeight = 40.0, baseCoins = 350, baseExp = 190 },
		{ name = "Belida Emas Suci", minWeight = 20.0, maxWeight = 45.0, baseCoins = 380, baseExp = 200 }
	},
	SUPER_RARE = {
		{ name = "Arapaima Raksasa", minWeight = 12.0, maxWeight = 25.0, baseCoins = 160, baseExp = 90 },
		{ name = "Pari Listrik Laut", minWeight = 10.0, maxWeight = 22.0, baseCoins = 140, baseExp = 80 },
		{ name = "Lele Monster Raksasa", minWeight = 14.0, maxWeight = 28.0, baseCoins = 175, baseExp = 95 },
		{ name = "Toman Raja Hitam", minWeight = 9.0, maxWeight = 20.0, baseCoins = 130, baseExp = 75 }
	},
	RARE = {
		{ name = "Gurame Super", minWeight = 3.5, maxWeight = 8.0, baseCoins = 60, baseExp = 35 },
		{ name = "Ikan Salmon Perak", minWeight = 4.0, maxWeight = 9.5, baseCoins = 75, baseExp = 40 },
		{ name = "Bawal Emas", minWeight = 3.0, maxWeight = 7.5, baseCoins = 55, baseExp = 30 },
		{ name = "Kakap Merah Segar", minWeight = 4.5, maxWeight = 10.0, baseCoins = 70, baseExp = 38 }
	},
	COMMON = {
		{ name = "Ikan Mas Kecil", minWeight = 0.8, maxWeight = 2.5, baseCoins = 15, baseExp = 10 },
		{ name = "Lele Lokal", minWeight = 0.5, maxWeight = 2.0, baseCoins = 12, baseExp = 8 },
		{ name = "Mujair Sungai", minWeight = 0.6, maxWeight = 2.2, baseCoins = 14, baseExp = 9 },
		{ name = "Ikan Nila Segar", minWeight = 0.7, maxWeight = 2.6, baseCoins = 16, baseExp = 11 },
		{ name = "Ikan Cupang Liar", minWeight = 0.1, maxWeight = 0.4, baseCoins = 10, baseExp = 6 }
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

FishingRaritySystem.RARITY_ORDER = {
	"COMMON",
	"RARE",
	"SUPER_RARE",
	"LEGENDARY",
	"MYTHIC",
	"SPECIAL"
}

-- 1. Soft Level Gating Multiplier (Mencegah Pemain Baru Dibanjiri Rarity Tinggi)
function FishingRaritySystem.GetLevelMultiplier(level, rarity)
	level = math.max(1, tonumber(level) or 1)
	rarity = tostring(rarity):upper()

	if rarity == "SPECIAL" or rarity == "EX" then
		if level < 15 then return 0.02 end
		if level < 25 then return 0.20 end
		return 1.00
	elseif rarity == "MYTHIC" or rarity == "UR" then
		if level < 10 then return 0.05 end
		if level < 20 then return 0.30 end
		return 1.00
	elseif rarity == "LEGENDARY" or rarity == "SSR" then
		if level < 5 then return 0.15 end
		if level < 10 then return 0.40 end
		if level < 20 then return 0.75 end
		return 1.00
	elseif rarity == "SUPER_RARE" or rarity == "SR" then
		if level < 3 then return 0.50 end
		return 1.00
	end

	return 1.00
end

-- 2. Hitung Distribusi Probabilitas Nyata Berdasarkan Effective Luck & Level Pemain
function FishingRaritySystem.GetRarityChances(luck, level)
	luck = math.clamp(tonumber(luck) or 1, FishingRaritySystem.MIN_LUCK, FishingRaritySystem.MAX_LUCK)
	level = math.max(1, tonumber(level) or 1)

	local luckFactor = (luck - 1) / 100

	local weights = {
		COMMON = BASE_WEIGHTS.COMMON * math.max(0.15, 1 - (0.75 * luckFactor)),
		RARE = BASE_WEIGHTS.RARE * (1 + 0.6 * luckFactor),
		SUPER_RARE = BASE_WEIGHTS.SUPER_RARE * (1 + 2.2 * luckFactor) * FishingRaritySystem.GetLevelMultiplier(level, "SUPER_RARE"),
		LEGENDARY = BASE_WEIGHTS.LEGENDARY * (1 + 4.5 * luckFactor) * FishingRaritySystem.GetLevelMultiplier(level, "LEGENDARY"),
		MYTHIC = BASE_WEIGHTS.MYTHIC * (1 + 7.0 * luckFactor) * FishingRaritySystem.GetLevelMultiplier(level, "MYTHIC"),
		SPECIAL = BASE_WEIGHTS.SPECIAL * (1 + 12.0 * luckFactor) * FishingRaritySystem.GetLevelMultiplier(level, "SPECIAL"),
	}

	local totalWeight = 0
	for _, r in ipairs(FishingRaritySystem.RARITY_ORDER) do
		totalWeight += weights[r]
	end

	local chances = {}
	for _, r in ipairs(FishingRaritySystem.RARITY_ORDER) do
		chances[r] = (weights[r] / totalWeight) * 100
	end

	return chances, weights, totalWeight
end

-- 3. Roll RNG Berdasarkan Weighted Distribution & Level
function FishingRaritySystem.RollRarity(luck, level)
	local _, weights, totalWeight = FishingRaritySystem.GetRarityChances(luck, level)
	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, rarity in ipairs(FishingRaritySystem.RARITY_ORDER) do
		cumulative += weights[rarity]
		if roll <= cumulative then
			return rarity
		end
	end

	return "COMMON"
end

-- 4. Evaluasi Pity System Hierarkis
function FishingRaritySystem.EvaluateWithPity(luck, level, pityState)
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

	return FishingRaritySystem.RollRarity(luck, level), false
end

-- 5. Perbarui State Pity setelah Ikan Berhasil Ditangkap
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

-- 6. Generate Data Ikan Lengkap (Nama, Bobot Kg, Koin, Exp)
function FishingRaritySystem.GenerateFish(rarity, playerLevel)
	local tierKey = tostring(rarity or "COMMON"):upper():gsub("%s+", "_")
	local list = FishingRaritySystem.FISH_DATABASE[tierKey] or FishingRaritySystem.FISH_DATABASE.COMMON
	local template = list[math.random(1, #list)]
	local tierData = FishingRaritySystem.GetTierData(tierKey)

	local weight = template.minWeight + (math.random() * (template.maxWeight - template.minWeight))
	weight = math.floor(weight * 10) / 10 -- 1 desimal (contoh: 14.5 Kg)

	local levelBonus = 1 + (math.max(1, tonumber(playerLevel) or 1) * 0.02)
	local coins = math.floor(template.baseCoins * levelBonus)
	local exp = math.floor(template.baseExp * levelBonus)

	return {
		name = template.name,
		rarity = tierKey,
		displayName = tierData.displayName,
		stars = tierData.stars,
		color = tierData.color,
		badgeColor = tierData.badgeColor,
		targetNotes = tierData.targetNotes,
		weight = weight,
		coins = coins,
		exp = exp,
	}
end

-- 7. Ambil Nama Ikan Acak
function FishingRaritySystem.GetRandomFishName(rarity)
	local fish = FishingRaritySystem.GenerateFish(rarity, 1)
	return fish.name
end

-- 8. Helper Standarisasi Data Tier
function FishingRaritySystem.GetTierData(tierName)
	local key = tostring(tierName or "COMMON"):upper():gsub("%s+", "_")
	return FishingRaritySystem.TIERS[key] or FishingRaritySystem.TIERS.COMMON
end

return FishingRaritySystem
