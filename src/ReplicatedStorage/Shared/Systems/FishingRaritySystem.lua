--[[
	FishingRaritySystem (ModuleScript)
	FISH!TUNE — Game Balance Specification v1.0
	
	Sistem Sentral Balancing Matematis:
	1. Formula XP Non-linear: XP Required(level) = floor(100 * level^1.65)
	2. Effective Luck Diminishing Returns: 0 - 100 Luck (Max 1.50x Multiplier)
	3. Non-Uniform Skewed Weight Distribution (Pangkat 1.8)
	4. Economy Value & XP Scaled by Weight & Rhythm Performance
	5. Soft Pity Scaling & Hierarchical Reset
	6. Weighted Rarity Base Table (Common 80%, Rare 15%, Super Rare 4.5%, Legendary 0.45%, Mythic 0.049%, Special 0.001%)
	7. Built-in Simulation Function untuk Validasi Balancing
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishDefinitions = require(Shared:WaitForChild("Config"):WaitForChild("FishDefinitions"))
local LuckFormula = require(Shared:WaitForChild("Systems"):WaitForChild("LuckFormula"))
local PitySystem = require(Shared:WaitForChild("Systems"):WaitForChild("PitySystem"))
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))

local FishingRaritySystem = {}

-- ============ CONFIG BALANCING CENTRAL v1.0 ============
FishingRaritySystem.CONFIG = {
	LUCK = {
		MIN = 0,
		MAX = 100,
		PERFORMANCE_COEFF = 0.25, -- Performance Score (0-100) * 0.25 -> Max +25 Luck
	},
	XP = XPProgressionSystem.CONFIG,
	ECONOMY = {
		BASE_COINS = {
			COMMON = 15,
			RARE = 45,
			SUPER_RARE = 120,
			LEGENDARY = 350,
			MYTHIC = 1100,
			SPECIAL = 3500,
		},
		WEIGHT_POW = 1.8, -- Skew berat ikan condong ke ukuran wajar
	},
	RARITY_BASE_WEIGHTS = {
		COMMON = 8000,     -- ~80.00%
		RARE = 1500,       -- ~15.00%
		SUPER_RARE = 450,  -- ~4.50%
		LEGENDARY = 45,    -- ~0.45%
		MYTHIC = 4.9,      -- ~0.049%
		SPECIAL = 0.1,     -- ~0.001%
	},
	PITY = {
		LEGENDARY = { start = 50, rate = 0.04, hard = 120 },
		MYTHIC = { start = 250, rate = 0.02, hard = 500 },
		SPECIAL = { start = 500, rate = 0.01, hard = 1000 },
	}
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

-- Database Ikan dengan Rentang Bobot Spesifik
FishingRaritySystem.FISH_DATABASE = {
	SPECIAL = {
		{ name = "Dewi Samudra Poseidon", minWeight = 25.0, maxWeight = 100.0 },
		{ name = "Naga Bintang Kosmik", minWeight = 30.0, maxWeight = 120.0 },
		{ name = "Leviathan Abyss", minWeight = 40.0, maxWeight = 150.0 },
		{ name = "Kraken Kuno Abadi", minWeight = 35.0, maxWeight = 130.0 }
	},
	MYTHIC = {
		{ name = "Hiu Megalodon Merah", minWeight = 15.0, maxWeight = 50.0 },
		{ name = "Naga Laut Api", minWeight = 12.0, maxWeight = 45.0 },
		{ name = "Kraken Laut Dalam", minWeight = 18.0, maxWeight = 60.0 },
		{ name = "Pari Raksasa Nebula", minWeight = 14.0, maxWeight = 40.0 }
	},
	LEGENDARY = {
		{ name = "Naga Laut Mistis", minWeight = 8.0, maxWeight = 25.0 },
		{ name = "Hiu Emas Murni", minWeight = 10.0, maxWeight = 28.0 },
		{ name = "Ikan Mas Raja", minWeight = 7.0, maxWeight = 20.0 },
		{ name = "Belida Emas Suci", minWeight = 8.5, maxWeight = 22.0 }
	},
	SUPER_RARE = {
		{ name = "Arapaima Raksasa", minWeight = 3.0, maxWeight = 10.0 },
		{ name = "Pari Listrik Laut", minWeight = 2.5, maxWeight = 8.5 },
		{ name = "Lele Monster Raksasa", minWeight = 3.5, maxWeight = 11.0 },
		{ name = "Toman Raja Hitam", minWeight = 2.8, maxWeight = 9.0 }
	},
	RARE = {
		{ name = "Gurame Super", minWeight = 1.5, maxWeight = 5.0 },
		{ name = "Ikan Salmon Perak", minWeight = 1.8, maxWeight = 5.5 },
		{ name = "Bawal Emas", minWeight = 1.2, maxWeight = 4.2 },
		{ name = "Kakap Merah Segar", minWeight = 2.0, maxWeight = 6.0 }
	},
	COMMON = {
		{ name = "Ikan Mas Kecil", minWeight = 0.5, maxWeight = 2.0 },
		{ name = "Lele Lokal", minWeight = 0.4, maxWeight = 1.8 },
		{ name = "Mujair Sungai", minWeight = 0.5, maxWeight = 1.9 },
		{ name = "Ikan Nila Segar", minWeight = 0.6, maxWeight = 2.2 },
		{ name = "Ikan Cupang Liar", minWeight = 0.1, maxWeight = 0.5 }
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

-- ============ 1. FORMULA PROGRESSION LEVEL & XP (DELEGATED TO XPProgressionSystem) ============
function FishingRaritySystem.GetExpRequiredForLevel(level)
	return XPProgressionSystem.GetExpRequiredForLevel(level)
end

function FishingRaritySystem.GetTotalExpForLevel(level)
	return XPProgressionSystem.GetTotalExpForLevel(level)
end

function FishingRaritySystem.GetLevelFromTotalExp(totalExp)
	local prog = XPProgressionSystem.DeriveProgression(totalExp)
	return prog.level, prog.currentLevelExp, prog.nextLevelExp, prog.progressPercent
end

function FishingRaritySystem.DeriveProgression(totalExp)
	return XPProgressionSystem.DeriveProgression(totalExp)
end

-- ============ 2. FORMULA EFFECTIVE LUCK & DIMINISHING RETURNS (FISH-019) ============
function FishingRaritySystem.CalculateEffectiveLuck(baseLuck, castLuck, perfLuck, instLuck)
	local raw = (tonumber(baseLuck) or 0) + (tonumber(castLuck) or 0) + (tonumber(perfLuck) or 0) + (tonumber(instLuck) or 0)
	return LuckFormula.CalculateEffectiveLuck(raw)
end

function FishingRaritySystem.GetLuckMultiplier(effectiveLuck)
	return LuckFormula.GetLuckMultiplier(effectiveLuck)
end

-- ============ 3. SOFT LEVEL GATING MULTIPLIER ============
function FishingRaritySystem.GetLevelMultiplier(level, rarity)
	level = math.max(1, tonumber(level) or 1)
	rarity = tostring(rarity):upper()

	if rarity == "SPECIAL" or rarity == "EX" then
		if level < 15 then return 0.05 end
		if level < 25 then return 0.35 end
		return 1.00
	elseif rarity == "MYTHIC" or rarity == "UR" then
		if level < 10 then return 0.10 end
		if level < 20 then return 0.50 end
		return 1.00
	elseif rarity == "LEGENDARY" or rarity == "SSR" then
		if level < 5 then return 0.20 end
		if level < 10 then return 0.50 end
		if level < 20 then return 0.80 end
		return 1.00
	elseif rarity == "SUPER_RARE" or rarity == "SR" then
		if level < 3 then return 0.60 end
		return 1.00
	end

	return 1.00
end

-- ============ 4. HITUNG DISTRIBUSI PELUANG NYATA ============
-- ============ 4. HITUNG DISTRIBUSI PELUANG NYATA (DENGAN SOFT PITY) ============
function FishingRaritySystem.GetRarityChances(luck, level, pityState)
	local effLuck = LuckFormula.CalculateEffectiveLuck(luck)
	level = math.max(1, tonumber(level) or 1)
	pityState = pityState or {}

	local luckMult = LuckFormula.GetLuckMultiplier(effLuck)
	local baseW = FishingRaritySystem.CONFIG.RARITY_BASE_WEIGHTS

	-- Multiplier Soft Pity dari PitySystem (FISH-020)
	local spePityMult = PitySystem.GetPityMultiplier(pityState, "SPECIAL")
	local mytPityMult = PitySystem.GetPityMultiplier(pityState, "MYTHIC")
	local legPityMult = PitySystem.GetPityMultiplier(pityState, "LEGENDARY")

	local weights = {
		SPECIAL = baseW.SPECIAL * (luckMult ^ 3.2) * FishingRaritySystem.GetLevelMultiplier(level, "SPECIAL") * spePityMult,
		MYTHIC = baseW.MYTHIC * (luckMult ^ 2.4) * FishingRaritySystem.GetLevelMultiplier(level, "MYTHIC") * mytPityMult,
		LEGENDARY = baseW.LEGENDARY * (luckMult ^ 1.8) * FishingRaritySystem.GetLevelMultiplier(level, "LEGENDARY") * legPityMult,
		SUPER_RARE = baseW.SUPER_RARE * (luckMult ^ 1.3) * FishingRaritySystem.GetLevelMultiplier(level, "SUPER_RARE"),
		RARE = baseW.RARE * (luckMult ^ 0.85),
		COMMON = baseW.COMMON * math.max(0.2, 2.0 - (luckMult ^ 1.1)),
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

-- ============ 5. ROLL RNG & PITY EVALUATION (FISH-020) ============
function FishingRaritySystem.RollRarity(luck, level, pityState)
	local _, weights, totalWeight = FishingRaritySystem.GetRarityChances(luck, level, pityState)
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

function FishingRaritySystem.EvaluateWithPity(luck, level, pityState)
	return PitySystem.Evaluate(luck, level, pityState, FishingRaritySystem.RollRarity)
end

function FishingRaritySystem.UpdatePityOnCatch(pityState, obtainedRarity)
	return PitySystem.UpdatePityOnCatch(pityState, obtainedRarity)
end

-- ============ 6. GENERATOR IKAN DENGAN STATS LENGKAP & MUTASI (FISH-019) ============
function FishingRaritySystem.GenerateFish(rarity, playerLevel, performanceScore, zoneId, effectiveLuck)
	local tierKey = tostring(rarity or "COMMON"):upper():gsub("%s+", "_")
	local template = FishDefinitions.GetRandomFish(tierKey, zoneId)
	local tierData = FishingRaritySystem.GetTierData(tierKey)

	playerLevel = math.max(1, tonumber(playerLevel) or 1)
	performanceScore = math.clamp(tonumber(performanceScore) or 80, 0, 100)
	effectiveLuck = math.max(0, tonumber(effectiveLuck) or 0)

	-- 1. Bobot Skewed (Pangkat 1.8) dengan sedikit dorongan dari Luck
	local minW = template.minWeight or 0.5
	local maxW = template.maxWeight or 2.0
	local luckWeightBonus = math.clamp(effectiveLuck / 400, 0, 0.25)
	local normWeight = math.clamp(((math.random()) ^ FishingRaritySystem.CONFIG.ECONOMY.WEIGHT_POW) + luckWeightBonus, 0, 1)
	local weight = minW + (normWeight * (maxW - minW))
	weight = math.floor(weight * 10) / 10

	-- 2. Nilai Koin berdasarkan Bobot & Rarity
	local avgWeight = (minW + maxW) / 2
	local weightFactor = math.clamp(0.80 + 0.40 * (weight / math.max(0.1, avgWeight)), 0.80, 1.40)
	local baseCoins = template.baseCoins or (FishingRaritySystem.CONFIG.ECONOMY.BASE_COINS[tierKey] or 15)
	local coins = math.floor(baseCoins * weightFactor)

	-- 3. EXP berdasarkan Rarity, Bobot & Performance Rhythm
	local baseExp = template.baseExp or (FishingRaritySystem.CONFIG.XP.BASE_XP[tierKey] or 10)
	local perfMult = 1.0
	for _, entry in ipairs(FishingRaritySystem.CONFIG.XP.PERF_MULTIPLIERS) do
		if performanceScore <= entry.maxScore then
			perfMult = entry.mult
			break
		end
	end

	local weightExpMult = 0.85 + (0.30 * normWeight)
	local exp = math.floor(baseExp * weightExpMult * perfMult)

	-- 4. Roll Mutasi Ikan Berdasarkan Stat Luck (FISH-019)
	local mutation = LuckFormula.RollMutation(effectiveLuck)
	local fishName = template.name
	local scale = template.scale or 1.0
	local color = template.color or tierData.color

	if mutation.isMutated then
		fishName = mutation.prefix .. " " .. template.name
		coins = math.floor(coins * mutation.coinMultiplier)
		exp = math.floor(exp * mutation.expMultiplier)
		weight = math.floor(weight * mutation.weightMultiplier * 10) / 10
		scale = scale * mutation.scaleMultiplier
		if mutation.color then
			color = mutation.color
		end
	end

	return {
		id = template.id or ("FISH_" .. string.gsub(template.name:upper(), "%s+", "_")),
		name = fishName,
		baseName = template.name,
		description = template.description or "Ikan air tawar/laut yang eksotis.",
		rarity = tierKey,
		displayName = tierData.displayName,
		stars = tierData.stars,
		color = color,
		badgeColor = tierData.badgeColor,
		targetNotes = tierData.targetNotes,
		weight = weight,
		coins = coins,
		exp = exp,
		scale = scale,
		favoriteZone = template.favoriteZone,
		normWeight = normWeight,
		performanceMultiplier = perfMult,
		isMutated = mutation.isMutated,
		mutationType = mutation.mutationType,
		mutationName = mutation.name,
		mutationPrefix = mutation.prefix,
		mutationGlow = mutation.glow,
	}
end

function FishingRaritySystem.GetRandomFishName(rarity, zoneId)
	local fish = FishingRaritySystem.GenerateFish(rarity, 1, 80, zoneId)
	return fish.name
end

function FishingRaritySystem.GetTierData(tierName)
	local key = tostring(tierName or "COMMON"):upper():gsub("%s+", "_")
	return FishingRaritySystem.TIERS[key] or FishingRaritySystem.TIERS.COMMON
end

-- ============ 7. SIMULATOR BALANCING (UNTUK TESTING / QA) ============
function FishingRaritySystem.SimulateCatches(luck, level, numCatches)
	numCatches = numCatches or 10000
	local counts = { COMMON = 0, RARE = 0, SUPER_RARE = 0, LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 }
	local totalCoins = 0
	local totalExp = 0
	local mockPity = { LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 }

	for i = 1, numCatches do
		local r = FishingRaritySystem.EvaluateWithPity(luck, level, mockPity)
		counts[r] = (counts[r] or 0) + 1
		mockPity = FishingRaritySystem.UpdatePityOnCatch(mockPity, r)

		local fish = FishingRaritySystem.GenerateFish(r, level, 85)
		totalCoins += fish.coins
		totalExp += fish.exp
	end

	local report = {}
	for _, r in ipairs(FishingRaritySystem.RARITY_ORDER) do
		report[r] = string.format("%.4f%% (%d)", (counts[r] / numCatches) * 100, counts[r])
	end
	report.AvgCoinsPerCatch = math.floor(totalCoins / numCatches)
	report.AvgExpPerCatch = math.floor(totalExp / numCatches)
	report.EstimatedCoinsPerMinute = math.floor((totalCoins / numCatches) * 3.5) -- 3.5 catches/min

	return report
end

return FishingRaritySystem
