--[[
	LootTableSystem (ModuleScript)
	FISH!TUNE — Central Loot Table & Drop Rate System (FISH-018)

	Sistem Sentral Penentu Kategori Tangkapan & Generator Loot:
	1. Dynamic Category Roll (Ikan, Peti Harta Karun, Relik Artefak Kuno, Benda Laut).
	2. Skala Pengaruh Luck: Luck tinggi meningkatkan peluang Peti Emas & Relik serta menekan Sampah.
	3. Integrasi Lengkap dengan FishDefinitions & LootDefinitions.
	4. Kalkulasi Nilai Ekonomi & EXP berbasis Performa Rhythm Minigame.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local LootDefinitions = require(Shared:WaitForChild("Config"):WaitForChild("LootDefinitions"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local LuckFormula = require(Shared:WaitForChild("Systems"):WaitForChild("LuckFormula"))

local LootTableSystem = {}

-- ============ 1. HITUNG DISTRIBUSI KATEGORI LOOT (FISH-019) ============
function LootTableSystem.GetCategoryChances(luck, zoneId)
	local effLuck = LuckFormula.CalculateEffectiveLuck(luck)
	local cats = LootDefinitions.CATEGORIES

	-- Skalasi bobot dengan stat Effective Luck
	local fishWeight = cats.FISH.baseWeight
	local treasureWeight = cats.TREASURE.baseWeight * (1 + (effLuck / 30))
	local artifactWeight = cats.ARTIFACT.baseWeight * (1 + (effLuck / 40))
	local junkWeight = cats.JUNK.baseWeight * (1 / (1 + (effLuck / 18)))

	-- Penyesuaian zona
	if zoneId == "SUMMIT_ABYSS" then
		treasureWeight *= 1.35
		artifactWeight *= 1.40
		junkWeight *= 0.30
	elseif zoneId == "TWIN_EYE_LAGOON" then
		treasureWeight *= 1.15
		artifactWeight *= 1.10
		junkWeight *= 0.60
	end

	local totalWeight = fishWeight + treasureWeight + artifactWeight + junkWeight

	local weights = {
		FISH = fishWeight,
		TREASURE = treasureWeight,
		ARTIFACT = artifactWeight,
		JUNK = junkWeight,
	}

	local chances = {
		FISH = (fishWeight / totalWeight) * 100,
		TREASURE = (treasureWeight / totalWeight) * 100,
		ARTIFACT = (artifactWeight / totalWeight) * 100,
		JUNK = (junkWeight / totalWeight) * 100,
	}

	return chances, weights, totalWeight
end

-- ============ 2. ROLL KATEGORI LOOT (SERVER-AUTHORITATIVE) ============
function LootTableSystem.RollCategory(luck, zoneId)
	local _, weights, totalWeight = LootTableSystem.GetCategoryChances(luck, zoneId)
	local roll = math.random() * totalWeight
	local cumulative = 0

	local categories = { "FISH", "TREASURE", "ARTIFACT", "JUNK" }
	for _, cat in ipairs(categories) do
		cumulative += weights[cat]
		if roll <= cumulative then
			return cat
		end
	end

	return "FISH"
end

-- ============ 3. GENERATOR LOOT LENGKAP ============
function LootTableSystem.GenerateLoot(category, rarity, playerLevel, performanceScore, zoneId, effectiveLuck)
	category = tostring(category or "FISH"):upper()
	rarity = tostring(rarity or "COMMON"):upper():gsub("%s+", "_")
	playerLevel = math.max(1, tonumber(playerLevel) or 1)
	performanceScore = math.clamp(tonumber(performanceScore) or 80, 0, 100)
	effectiveLuck = math.max(0, tonumber(effectiveLuck) or 0)

	-- KATEGORI 1: IKAN (FISH)
	if category == "FISH" then
		local fishData = FishingRaritySystem.GenerateFish(rarity, playerLevel, performanceScore, zoneId, effectiveLuck)
		fishData.itemType = "FISH"
		fishData.categoryName = "Ikan Samudra"
		fishData.categoryBadge = "🐟 IKAN"
		return fishData
	end

	local tierData = FishingRaritySystem.GetTierData(rarity)
	local perfMult = 1.0
	for _, entry in ipairs(FishingRaritySystem.CONFIG.XP.PERF_MULTIPLIERS) do
		if performanceScore <= entry.maxScore then
			perfMult = entry.mult
			break
		end
	end

	-- KATEGORI 2: PETI HARTA KARUN (TREASURE CHEST)
	if category == "TREASURE" then
		local candidates = LootDefinitions.GetLootByCategory("TREASURE", rarity, zoneId)
		local template = candidates[math.random(1, #candidates)]
		if not template then
			template = LootDefinitions.TREASURE_CHESTS[1]
		end

		local minCoins = template.minCoins or 100
		local maxCoins = template.maxCoins or 250
		local baseCoins = math.random(minCoins, maxCoins)
		local coins = math.floor(baseCoins * (1 + (performanceScore / 200)))
		local baseExp = template.baseExp or 40
		local exp = math.floor(baseExp * perfMult)

		return {
			id = template.id,
			itemType = "TREASURE",
			categoryName = "Peti Harta Karun",
			categoryBadge = "📦 HARTA KARUN",
			name = template.name,
			displayName = tierData.displayName,
			rarity = rarity,
			stars = tierData.stars,
			description = template.description,
			color = template.color or Color3.fromRGB(255, 215, 0),
			badgeColor = tierData.badgeColor,
			weight = template.weight or 5.0,
			coins = coins,
			exp = exp,
			scale = template.scale or 1.2,
			favoriteZone = template.favoriteZone,
			targetNotes = tierData.targetNotes,
			performanceMultiplier = perfMult,
		}
	end

	-- KATEGORI 3: ARTIFACT & RELIK KUNO (ARTIFACT)
	if category == "ARTIFACT" then
		local candidates = LootDefinitions.GetLootByCategory("ARTIFACT", rarity, zoneId)
		local template = candidates[math.random(1, #candidates)]
		if not template then
			template = LootDefinitions.ARTIFACTS[1]
		end

		local minCoins = template.minCoins or 80
		local maxCoins = template.maxCoins or 150
		local baseCoins = math.random(minCoins, maxCoins)
		local coins = math.floor(baseCoins * (1 + (performanceScore / 250)))
		local baseExp = template.baseExp or 30
		local exp = math.floor(baseExp * perfMult)

		return {
			id = template.id,
			itemType = "ARTIFACT",
			categoryName = "Relik Kuno",
			categoryBadge = "✨ RELIK KUNO",
			name = template.name,
			displayName = tierData.displayName,
			rarity = rarity,
			stars = tierData.stars,
			description = template.description,
			color = template.color or Color3.fromRGB(200, 80, 255),
			badgeColor = tierData.badgeColor,
			weight = template.weight or 1.5,
			coins = coins,
			exp = exp,
			scale = template.scale or 1.0,
			favoriteZone = template.favoriteZone,
			targetNotes = tierData.targetNotes,
			performanceMultiplier = perfMult,
		}
	end

	-- KATEGORI 4: BENDA DASAR LAUT (JUNK / DEBRIS)
	if category == "JUNK" then
		local candidates = LootDefinitions.GetLootByCategory("JUNK", "COMMON", zoneId)
		local template = candidates[math.random(1, #candidates)]
		if not template then
			template = LootDefinitions.JUNK[1]
		end

		local minCoins = template.minCoins or 5
		local maxCoins = template.maxCoins or 10
		local coins = math.random(minCoins, maxCoins)
		local exp = template.baseExp or 2

		return {
			id = template.id,
			itemType = "JUNK",
			categoryName = "Benda Dasar Laut",
			categoryBadge = "🗑️ BENDA LAUT",
			name = template.name,
			displayName = "COMMON",
			rarity = "COMMON",
			stars = "⭐",
			description = template.description,
			color = template.color or Color3.fromRGB(150, 140, 130),
			badgeColor = Color3.fromRGB(120, 125, 135),
			weight = template.weight or 0.8,
			coins = coins,
			exp = exp,
			scale = template.scale or 0.8,
			favoriteZone = template.favoriteZone,
			targetNotes = 25,
			performanceMultiplier = 1.0,
		}
	end

	-- Fallback ke Ikan Standar
	return FishingRaritySystem.GenerateFish(rarity, playerLevel, performanceScore, zoneId)
end

return LootTableSystem
