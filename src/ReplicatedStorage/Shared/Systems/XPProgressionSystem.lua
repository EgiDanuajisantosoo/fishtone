--[[
	XPProgressionSystem (ModuleScript)
	FISH!TUNE — Central Player XP, Uncapped Level Progression & Curve Balancing (FISH-030)

	Satu sumber kebenaran (Single Source of Truth) untuk progresi level dan XP pemain:
	1. Formula XP Eksponensial: XP Diperlukan(level) = floor(100 * level^1.65).
	2. TotalXP sebagai Sumber Kebenaran Persistensi (Persistence Source of Truth).
	3. Derivasi Level $O(\log N)$ Berbasis Binary Search & Memoized Prefix Sums (Bebas Loop Linear Lambat).
	4. Progresi Tanpa Batas (Uncapped Leveling — Tidak ada MaxLevel buatan).
	5. Valuasi EXP Tangkapan Berbasis Rarity, Mutasi, Bobot & Skor Rhythm Mini-Game.
	6. Audit & Simulasi Progresi untuk Validasi Game Balance.
]]

local XPProgressionSystem = {}

-- ============ 1. CONFIGURATION & BALANCING CONSTANTS ============
XPProgressionSystem.CONFIG = {
	BASE_FORMULA = 100,
	EXPONENT = 1.65,

	-- Base XP per Rarity Tier
	BASE_XP = {
		COMMON     = 10,
		RARE       = 18,
		SUPER_RARE = 30,
		LEGENDARY  = 55,
		MYTHIC     = 100,
		SPECIAL    = 175,
	},

	-- Multiplier Berdasarkan Skor & Grade Performa Rhythm (0 - 100)
	PERFORMANCE_MULTIPLIERS = {
		{ minScore = 100, grade = "SSS", mult = 1.30, title = "All Perfect ⭐⭐⭐" },
		{ minScore = 95,  grade = "SS",  mult = 1.25, title = "Full Combo ⭐⭐" },
		{ minScore = 90,  grade = "S",   mult = 1.20, title = "Superb ⭐" },
		{ minScore = 80,  grade = "A",   mult = 1.10, title = "Great" },
		{ minScore = 70,  grade = "B",   mult = 1.00, title = "Good" },
		{ minScore = 55,  grade = "C",   mult = 0.90, title = "Fair" },
		{ minScore = 0,   grade = "D",   mult = 0.75, title = "Poor" },
	},

	-- Multiplier Berdasarkan Mutasi Ikan
	MUTATION_MULTIPLIERS = {
		COSMIC = 2.50,
		GOLDEN = 1.80,
		GIANT  = 1.50,
		SHINY  = 1.30,
		NONE   = 1.00,
	},

	-- Konfigurasi Cache Memoization Awal
	PRECOMPUTED_CACHE_SIZE = 500,
}

-- ============ 2. MEMOIZATION & PREFIX SUM CACHE ============
local reqExpCache = {}        -- [level] = requiredExp to reach level + 1
local cumulativeExpCache = {} -- [level] = total cumulative Exp to reach level (level 1 = 0)

-- Inisialisasi awal cache prefix sum untuk performa O(1)
local function computeRequiredExp(lvl)
	return math.floor(XPProgressionSystem.CONFIG.BASE_FORMULA * (lvl ^ XPProgressionSystem.CONFIG.EXPONENT))
end

local function ensureCacheUpTo(targetLevel)
	local currentCached = #cumulativeExpCache
	if targetLevel <= currentCached then return end

	if currentCached == 0 then
		reqExpCache[1] = computeRequiredExp(1)
		cumulativeExpCache[1] = 0
		currentCached = 1
	end

	for lvl = currentCached + 1, targetLevel + 50 do
		local prevReq = reqExpCache[lvl - 1]
		local prevCumul = cumulativeExpCache[lvl - 1]
		cumulativeExpCache[lvl] = prevCumul + prevReq
		reqExpCache[lvl] = computeRequiredExp(lvl)
	end
end

-- Pre-fill cache hingga level 500 saat modul dimuat
ensureCacheUpTo(XPProgressionSystem.CONFIG.PRECOMPUTED_CACHE_SIZE)

-- ============ 3. CORE MATHEMATICAL API ============

-- Mengembalikan jumlah XP yang dibutuhkan untuk naik dari `level` ke `level + 1`
function XPProgressionSystem.GetExpRequiredForLevel(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	if reqExpCache[level] then
		return reqExpCache[level]
	end
	return computeRequiredExp(level)
end

-- Mengembalikan total akumulasi XP yang dibutuhkan dari Level 1 untuk mencapai `level`
function XPProgressionSystem.GetTotalExpForLevel(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	if level == 1 then return 0 end

	ensureCacheUpTo(level)
	if cumulativeExpCache[level] then
		return cumulativeExpCache[level]
	end

	-- Fallback analytical approximation jika melebihi cache
	local approxIntegral = (XPProgressionSystem.CONFIG.BASE_FORMULA / (XPProgressionSystem.CONFIG.EXPONENT + 1)) * ((level - 1) ^ (XPProgressionSystem.CONFIG.EXPONENT + 1))
	return math.floor(approxIntegral)
end

-- ============ 4. EFFICIENT O(log N) PROGRESSION DERIVATION ============
-- Menderivasi level, XP sisa di level aktif, target XP level berikutnya, dan persentase progress dari TotalXP
function XPProgressionSystem.DeriveProgression(totalExp)
	totalExp = math.max(0, math.floor(tonumber(totalExp) or 0))

	if totalExp <= 0 then
		local nextExp = XPProgressionSystem.GetExpRequiredForLevel(1)
		return {
			level = 1,
			currentLevelExp = 0,
			nextLevelExp = nextExp,
			progressPercent = 0.0,
			totalExp = 0,
		}
	end

	-- 1. Tentukan batas pencarian biner (Binary Search Range)
	local low = 1
	local high = math.max(#cumulativeExpCache, 100)

	-- Perluas batas atas jika totalExp melebihi cache saat ini
	while true do
		ensureCacheUpTo(high)
		if cumulativeExpCache[high] and cumulativeExpCache[high] > totalExp then
			break
		end
		high = high * 2
	end

	-- 2. Binary Search untuk menemukan level terbesar L di mana cumulativeExpCache[L] <= totalExp
	local resultLevel = 1
	while low <= high do
		local mid = math.floor((low + high) / 2)
		ensureCacheUpTo(mid)
		local midCumul = cumulativeExpCache[mid] or 0

		if midCumul <= totalExp then
			resultLevel = mid
			low = mid + 1
		else
			high = mid - 1
		end
	end

	-- 3. Hitung rincian XP pada level tersebut
	local baseLevelCumul = cumulativeExpCache[resultLevel] or 0
	local currentLevelExp = totalExp - baseLevelCumul
	local nextLevelExp = XPProgressionSystem.GetExpRequiredForLevel(resultLevel)
	local progressPercent = math.clamp(currentLevelExp / math.max(1, nextLevelExp), 0, 1)

	return {
		level = resultLevel,
		currentLevelExp = currentLevelExp,
		nextLevelExp = nextLevelExp,
		progressPercent = progressPercent,
		totalExp = totalExp,
	}
end

-- ============ 5. RECONCILER DARI SCHEMA LAMA ============
-- Membantu migrasi dari format lama (level, exp terpotong) ke totalExp kanonikal
function XPProgressionSystem.ReconcileToTotalExp(level, currentExp)
	level = math.max(1, math.floor(tonumber(level) or 1))
	currentExp = math.max(0, math.floor(tonumber(currentExp) or 0))

	local baseCumul = XPProgressionSystem.GetTotalExpForLevel(level)
	return baseCumul + currentExp
end

-- ============ 6. CATCH EXP VALUATION & MULTIPLIERS ============
function XPProgressionSystem.GetPerformanceMultiplier(score)
	score = math.clamp(tonumber(score) or 0, 0, 100)
	for _, entry in ipairs(XPProgressionSystem.CONFIG.PERFORMANCE_MULTIPLIERS) do
		if score >= entry.minScore then
			return entry.mult, entry.grade, entry.title
		end
	end
	return 1.0, "B", "Good"
end

function XPProgressionSystem.GetMutationMultiplier(mutationType)
	mutationType = tostring(mutationType or "NONE"):upper()
	return XPProgressionSystem.CONFIG.MUTATION_MULTIPLIERS[mutationType] or 1.0
end

function XPProgressionSystem.CalculateCatchExp(rarity, weight, performanceScore, isMutated, mutationType)
	rarity = tostring(rarity or "COMMON"):upper()
	local baseExp = XPProgressionSystem.CONFIG.BASE_XP[rarity] or XPProgressionSystem.CONFIG.BASE_XP.COMMON

	-- 1. Pengganda Performa Rhythm
	local perfMult, grade, gradeTitle = XPProgressionSystem.GetPerformanceMultiplier(performanceScore)

	-- 2. Pengganda Mutasi
	local mutMult = 1.0
	if isMutated then
		mutMult = XPProgressionSystem.GetMutationMultiplier(mutationType)
	end

	-- 3. Pengganda Bobot Ikan (Bonus ringan untuk ikan berukuran raksasa)
	local weightNum = math.max(0.1, tonumber(weight) or 1.0)
	local weightMult = 1.0
	if weightNum > 10.0 then
		weightMult = 1.0 + math.min(0.35, math.log10(weightNum / 10.0) * 0.25)
	end

	local finalExp = math.max(1, math.floor(baseExp * perfMult * mutMult * weightMult))

	return {
		finalExp = finalExp,
		baseExp = baseExp,
		perfMultiplier = perfMult,
		grade = grade,
		gradeTitle = gradeTitle,
		mutationMultiplier = mutMult,
		weightMultiplier = weightMult,
	}
end

-- ============ 7. BALANCING AUDIT & SIMULATION ============
function XPProgressionSystem.Simulate(maxLevel)
	maxLevel = math.max(2, tonumber(maxLevel) or 50)
	local rows = {}

	for lvl = 1, maxLevel do
		local req = XPProgressionSystem.GetExpRequiredForLevel(lvl)
		local cumul = XPProgressionSystem.GetTotalExpForLevel(lvl)
		local avgCatchesCommon = math.ceil(req / XPProgressionSystem.CONFIG.BASE_XP.COMMON)
		local avgCatchesRare = math.ceil(req / XPProgressionSystem.CONFIG.BASE_XP.RARE)
		local avgCatchesSuperRare = math.ceil(req / XPProgressionSystem.CONFIG.BASE_XP.SUPER_RARE)

		table.insert(rows, {
			level = lvl,
			expRequired = req,
			totalExp = cumul,
			catchesCommon = avgCatchesCommon,
			catchesRare = avgCatchesRare,
			catchesSuperRare = avgCatchesSuperRare,
		})
	end

	return rows
end

return XPProgressionSystem
