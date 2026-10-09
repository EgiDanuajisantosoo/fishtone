--[[
	LuckFormula (ModuleScript)
	FISH!TUNE — Central Luck Formula, Diminishing Returns & Drop Multiplier System (FISH-019)

	Sistem Sentral Perhitungan Stat Luck Terintegrasi (Sesuai Aturan FISH!TUNE Section 7):
	1. Multi-Source Luck Aggregation:
	   - Equipment / Rod Luck (5 - 50+)
	   - Minigame Performance Streak Luck (0 - 25)
	   - Zone Affinity Luck (Melody Bay: 0, Twin Eye Lagoon: +10, Summit Abyss: +25)
	   - Active Baits / Potions / Temporary Buff Luck (0 - 30+)
	   - Catatan: Level dan Cast Quality TIDAK memberikan Luck langsung.
	     * Level adalah progresi murni (dari TotalXP).
	     * Cast Quality hanya menentukan starting note progress minigame (PERFECT=35%, GREAT=20%, GOOD=10%).
	2. Hyperbolic & Piecewise Diminishing Returns Curve [0 - 100].
	3. Universal Luck Multipliers untuk Rarity Tier Weights & Category Drops.
	4. Lucky Mutations (Shiny, Golden, Giant, Cosmic).
	5. Full Audit & Breakdown API untuk Debugging dan UI Feedback Transparan.
]]

local LuckFormula = {}

-- ============ CONFIGURATION & CONSTANTS ============
LuckFormula.CONFIG = {
	-- Batas Raw & Effective Luck (Dibatasi 0 - 100 untuk Prototipe)
	MIN_LUCK = 0,
	SOFT_CAP_1 = 40,    -- Mulai melandai ringan (efisiensi 70%)
	SOFT_CAP_2 = 75,    -- Mulai melandai tinggi (efisiensi 40%)
	HARD_CAP = 100,     -- Batas absolut stat Luck

	-- Multiplier Formula Constants: Multiplier = 1.0 + (Eff / (Eff + K)) * MAX_BONUS
	CURVE_K = 50,
	MAX_BONUS_MULT = 0.80, -- Multiplier maksimal: 1.00x - 1.53x pada 100 Luck

	-- Cast Quality Luck Values (Strictly 0; Cast Quality hanya menentukan start progress minigame)
	CAST_LUCK = {
		PERFECT = 0,
		GREAT = 0,
		GOOD = 0,
		MISS = 0,
	},

	-- Level Progression (Level adalah progresi murni, tidak memberikan bonus luck langsung)
	LEVEL_COEFF = 0,
	MAX_LEVEL_LUCK = 0,

	-- Minigame Performance Streak Luck (Maks +25 pada Skor 100)
	PERFORMANCE_COEFF = 0.25,
	MAX_PERF_LUCK = 25,

	-- Rarity Tier Luck Exponents (Sensitivitas setiap tier terhadap luck)
	TIER_EXPONENTS = {
		SPECIAL = 3.2,
		MYTHIC = 2.4,
		LEGENDARY = 1.8,
		SUPER_RARE = 1.3,
		RARE = 0.85,
		COMMON = -1.1, -- Ditekan saat luck tinggi
	},

	-- Mutasi Ikan Langka (Shiny / Golden / Giant / Cosmic)
	MUTATIONS = {
		COSMIC = {
			id = "COSMIC",
			name = "Kosmik Bintang",
			prefix = "🌌 Kosmik",
			baseChance = 0.05, -- 0.05%
			luckScale = 0.0035,
			maxChance = 2.0,   -- 2.0%
			coinMultiplier = 4.0,
			expMultiplier = 2.5,
			weightMultiplier = 1.3,
			scaleMultiplier = 1.35,
			color = Color3.fromRGB(200, 40, 255),
			glow = true,
		},
		GOLDEN = {
			id = "GOLDEN",
			name = "Emas Murni",
			prefix = "✨ Emas",
			baseChance = 0.25, -- 0.25%
			luckScale = 0.015,
			maxChance = 4.5,   -- 4.5%
			coinMultiplier = 2.8,
			expMultiplier = 1.8,
			weightMultiplier = 1.25,
			scaleMultiplier = 1.2,
			color = Color3.fromRGB(255, 215, 0),
			glow = true,
		},
		SHINY = {
			id = "SHINY",
			name = "Berkilau",
			prefix = "💎 Shiny",
			baseChance = 0.80, -- 0.80%
			luckScale = 0.035,
			maxChance = 8.0,   -- 8.0%
			coinMultiplier = 1.6,
			expMultiplier = 1.3,
			weightMultiplier = 1.15,
			scaleMultiplier = 1.1,
			color = Color3.fromRGB(0, 235, 255),
			glow = true,
		},
		GIANT = {
			id = "GIANT",
			name = "Raksasa Samudra",
			prefix = "🔱 Raksasa",
			baseChance = 0.50, -- 0.50%
			luckScale = 0.025,
			maxChance = 6.0,   -- 6.0%
			coinMultiplier = 2.0,
			expMultiplier = 1.5,
			weightMultiplier = 1.85,
			scaleMultiplier = 1.55,
			color = nil, -- Gunakan warna asli
			glow = false,
		},
	},
}

-- ============ 1. HITUNG RAW LUCK DARI SELURUH SUMBER ============
function LuckFormula.CalculateRawLuck(sources)
	sources = sources or {}

	local rodLuck = math.max(0, tonumber(sources.rod) or 5)
	local perfLuck = math.clamp(tonumber(sources.performance) or 0, 0, LuckFormula.CONFIG.MAX_PERF_LUCK)
	local zoneLuck = math.max(0, tonumber(sources.zone) or 0)
	local buffLuck = math.max(0, tonumber(sources.buffs) or 0)

	-- Cast Quality dan Level tidak memberikan direct luck (strictly 0)
	local castLuck = 0
	local levelLuck = 0

	local rawLuck = rodLuck + perfLuck + zoneLuck + buffLuck

	return math.clamp(rawLuck, LuckFormula.CONFIG.MIN_LUCK, LuckFormula.CONFIG.HARD_CAP), {
		rod = rodLuck,
		performance = perfLuck,
		zone = zoneLuck,
		buffs = buffLuck,
		cast = castLuck,
		level = levelLuck,
	}
end

-- ============ 2. PIECEWISE & HYPERBOLIC DIMINISHING RETURNS ============
function LuckFormula.CalculateEffectiveLuck(rawLuck)
	rawLuck = math.clamp(tonumber(rawLuck) or 0, LuckFormula.CONFIG.MIN_LUCK, LuckFormula.CONFIG.HARD_CAP)
	local cfg = LuckFormula.CONFIG

	if rawLuck <= cfg.SOFT_CAP_1 then
		-- Zona Linear (0 - 40 Luck -> 100% Efisiensi)
		return rawLuck
	elseif rawLuck <= cfg.SOFT_CAP_2 then
		-- Zona Melandai Ringan (40 - 75 Luck -> 70% Efisiensi)
		local excess = rawLuck - cfg.SOFT_CAP_1
		return cfg.SOFT_CAP_1 + (excess * 0.70)
	else
		-- Zona Melandai Tinggi (75 - 100 Luck -> 40% Efisiensi, Hard Capped at 100)
		local baseEff = cfg.SOFT_CAP_1 + ((cfg.SOFT_CAP_2 - cfg.SOFT_CAP_1) * 0.70)
		local excess = rawLuck - cfg.SOFT_CAP_2
		local eff = baseEff + (excess * 0.40)
		return math.clamp(eff, cfg.MIN_LUCK, cfg.HARD_CAP)
	end
end

-- ============ 3. UNIVERSAL LUCK MULTIPLIER ============
function LuckFormula.GetLuckMultiplier(effectiveLuck)
	effectiveLuck = math.clamp(tonumber(effectiveLuck) or 0, LuckFormula.CONFIG.MIN_LUCK, LuckFormula.CONFIG.HARD_CAP)
	local cfg = LuckFormula.CONFIG

	-- Multiplier = 1.0 + (Eff / (Eff + K)) * MAX_BONUS
	local bonus = (effectiveLuck / (effectiveLuck + cfg.CURVE_K)) * cfg.MAX_BONUS_MULT
	return 1.0 + bonus
end

-- ============ 4. MUTASI IKAN (SHINY / GOLDEN / GIANT / COSMIC) ============
function LuckFormula.RollMutation(effectiveLuck)
	effectiveLuck = math.clamp(tonumber(effectiveLuck) or 0, LuckFormula.CONFIG.MIN_LUCK, LuckFormula.CONFIG.HARD_CAP)
	local mutations = LuckFormula.CONFIG.MUTATIONS

	-- Roll urutan hierarki mutasi: COSMIC -> GOLDEN -> GIANT -> SHINY
	local order = { "COSMIC", "GOLDEN", "GIANT", "SHINY" }

	for _, key in ipairs(order) do
		local m = mutations[key]
		local chance = math.clamp(m.baseChance + (effectiveLuck * m.luckScale), 0, m.maxChance)
		local roll = math.random() * 100

		if roll <= chance then
			return {
				isMutated = true,
				mutationType = m.id,
				name = m.name,
				prefix = m.prefix,
				coinMultiplier = m.coinMultiplier,
				expMultiplier = m.expMultiplier,
				weightMultiplier = m.weightMultiplier,
				scaleMultiplier = m.scaleMultiplier,
				color = m.color,
				glow = m.glow,
				chance = chance,
			}
		end
	end

	return {
		isMutated = false,
		mutationType = "NONE",
		coinMultiplier = 1.0,
		expMultiplier = 1.0,
		weightMultiplier = 1.0,
		scaleMultiplier = 1.0,
		glow = false,
	}
end

-- ============ 5. LUCK TITLE / TIER BADGE ============
function LuckFormula.GetLuckTitle(effectiveLuck)
	effectiveLuck = tonumber(effectiveLuck) or 0

	if effectiveLuck >= 75 then
		return "👑 Keberuntungan Kosmik", Color3.fromRGB(255, 60, 200)
	elseif effectiveLuck >= 50 then
		return "✨ Keberuntungan Dewa Laut", Color3.fromRGB(255, 215, 0)
	elseif effectiveLuck >= 30 then
		return "🌟 Sangat Beruntung", Color3.fromRGB(0, 225, 255)
	elseif effectiveLuck >= 12 then
		return "🍀 Cukup Beruntung", Color3.fromRGB(80, 220, 120)
	else
		return "🌱 Netral", Color3.fromRGB(180, 190, 205)
	end
end

-- ============ 6. COMPREHENSIVE LUCK BREAKDOWN AUDIT ============
function LuckFormula.CalculateBreakdown(sources)
	local rawLuck, srcBreakdown = LuckFormula.CalculateRawLuck(sources)
	local effectiveLuck = LuckFormula.CalculateEffectiveLuck(rawLuck)
	local luckMultiplier = LuckFormula.GetLuckMultiplier(effectiveLuck)
	local luckTitle, titleColor = LuckFormula.GetLuckTitle(effectiveLuck)

	return {
		rawLuck = math.floor(rawLuck * 10) / 10,
		effectiveLuck = math.floor(effectiveLuck * 10) / 10,
		multiplier = math.floor(luckMultiplier * 100) / 100,
		title = luckTitle,
		titleColor = titleColor,
		sources = {
			rod = { name = "Joran Pancing", value = srcBreakdown.rod },
			performance = { name = "Bonus Performa Lalu", value = math.floor(srcBreakdown.performance * 10) / 10 },
			zone = { name = "Afinitas Wilayah", value = srcBreakdown.zone },
			buffs = { name = "Efek Umpan / Potion", value = srcBreakdown.buffs },
			cast = { name = "Akurasi Lemparan (Progress Only)", value = 0 },
			level = { name = "Level Karakter (Progression Only)", value = 0 },
		},
		mutationOdds = {
			cosmic = math.min(LuckFormula.CONFIG.MUTATIONS.COSMIC.maxChance, LuckFormula.CONFIG.MUTATIONS.COSMIC.baseChance + (effectiveLuck * LuckFormula.CONFIG.MUTATIONS.COSMIC.luckScale)),
			golden = math.min(LuckFormula.CONFIG.MUTATIONS.GOLDEN.maxChance, LuckFormula.CONFIG.MUTATIONS.GOLDEN.baseChance + (effectiveLuck * LuckFormula.CONFIG.MUTATIONS.GOLDEN.luckScale)),
			giant = math.min(LuckFormula.CONFIG.MUTATIONS.GIANT.maxChance, LuckFormula.CONFIG.MUTATIONS.GIANT.baseChance + (effectiveLuck * LuckFormula.CONFIG.MUTATIONS.GIANT.luckScale)),
			shiny = math.min(LuckFormula.CONFIG.MUTATIONS.SHINY.maxChance, LuckFormula.CONFIG.MUTATIONS.SHINY.baseChance + (effectiveLuck * LuckFormula.CONFIG.MUTATIONS.SHINY.luckScale)),
		}
	}
end

return LuckFormula
