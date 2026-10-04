--[[
	PitySystem (ModuleScript)
	FISH!TUNE — Central Hierarchical Pity & Gacha Protection System (FISH-020)

	Sistem Sentral Manajemen Pity & Proteksi Drop Rate Terintegrasi:
	1. Hierarchical Soft & Hard Pity untuk 3 Tier Tertinggi:
	   - LEGENDARY: Soft Pity pada 50 tarikan (+4% per tarikan), Hard Pity pada 120 tarikan (Pasti Dapat).
	   - MYTHIC: Soft Pity pada 250 tarikan (+2% per tarikan), Hard Pity pada 500 tarikan (Pasti Dapat).
	   - SPECIAL: Soft Pity pada 500 tarikan (+1% per tarikan), Hard Pity pada 1000 tarikan (Pasti Dapat).
	2. Hierarchical Reset Rules:
	   - SPECIAL diperoleh -> Reset SPECIAL, MYTHIC, dan LEGENDARY ke 0.
	   - MYTHIC diperoleh -> Reset MYTHIC dan LEGENDARY ke 0, SPECIAL bertambah +1.
	   - LEGENDARY diperoleh -> Reset LEGENDARY ke 0, MYTHIC & SPECIAL bertambah +1.
	   - Tier lain diperoleh -> Seluruh counter (LEGENDARY, MYTHIC, SPECIAL) bertambah +1.
	3. Comprehensive Progress & Analytics API untuk HUD & UI Tracker.
	4. Deterministic Server-Authoritative Evaluation.
]]

local PitySystem = {}

-- ============ CONFIGURATION & CONSTANTS ============
PitySystem.TIERS = {
	SPECIAL = {
		id = "SPECIAL",
		displayName = "SPECIAL",
		title = "👑 Pusaka Dewa Laut",
		stars = "⭐⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(255, 60, 200),
		badgeColor = Color3.fromRGB(255, 120, 30),
		softPityStart = 500,
		softPityRate = 0.01,
		hardPity = 1000,
		order = 6,
	},
	MYTHIC = {
		id = "MYTHIC",
		displayName = "MYTHIC",
		title = "🔥 Mitos Palung Terdalam",
		stars = "⭐⭐⭐⭐⭐",
		color = Color3.fromRGB(235, 45, 45),
		badgeColor = Color3.fromRGB(195, 25, 25),
		softPityStart = 250,
		softPityRate = 0.02,
		hardPity = 500,
		order = 5,
	},
	LEGENDARY = {
		id = "LEGENDARY",
		displayName = "LEGENDARY",
		title = "🌟 Legenda Samudra",
		stars = "⭐⭐⭐⭐",
		color = Color3.fromRGB(240, 185, 20),
		badgeColor = Color3.fromRGB(210, 160, 10),
		softPityStart = 50,
		softPityRate = 0.04,
		hardPity = 120,
		order = 4,
	},
}

-- Pity Tier Priority Order (Tertinggi ke Terendah)
PitySystem.PRIORITY_ORDER = { "SPECIAL", "MYTHIC", "LEGENDARY" }

-- ============ 1. GET PITY COUNT HELPER ============
function PitySystem.GetPityCount(pityState, tierKey)
	if not pityState or typeof(pityState) ~= "table" then return 0 end
	tierKey = tostring(tierKey or ""):upper()

	if tierKey == "SPECIAL" or tierKey == "EX" then
		return math.max(0, tonumber(pityState.SPECIAL or pityState.EX) or 0)
	elseif tierKey == "MYTHIC" or tierKey == "UR" then
		return math.max(0, tonumber(pityState.MYTHIC or pityState.UR) or 0)
	elseif tierKey == "LEGENDARY" or tierKey == "SSR" then
		return math.max(0, tonumber(pityState.LEGENDARY or pityState.SSR) or 0)
	end

	return 0
end

-- ============ 2. GET SOFT PITY MULTIPLIER ============
function PitySystem.GetPityMultiplier(pityState, tierKey)
	local cfg = PitySystem.TIERS[tierKey]
	if not cfg then return 1.0 end

	local count = PitySystem.GetPityCount(pityState, tierKey)
	if count >= cfg.softPityStart then
		local excess = count - cfg.softPityStart
		return 1.0 + (excess * cfg.softPityRate)
	end

	return 1.0
end

-- ============ 3. CHECK HARD PITY GUARANTEE ============
function PitySystem.CheckHardPity(pityState)
	for _, tierKey in ipairs(PitySystem.PRIORITY_ORDER) do
		local cfg = PitySystem.TIERS[tierKey]
		local count = PitySystem.GetPityCount(pityState, tierKey)
		if count >= cfg.hardPity then
			return true, tierKey
		end
	end
	return false, nil
end

-- ============ 4. GET DETAILED PITY PROGRESS (FOR UI & HUD) ============
function PitySystem.GetPityProgress(pityState, tierKey)
	local cfg = PitySystem.TIERS[tierKey]
	if not cfg then return nil end

	local count = PitySystem.GetPityCount(pityState, tierKey)
	local softStart = cfg.softPityStart
	local hardCap = cfg.hardPity

	local pullsUntilSoft = math.max(0, softStart - count)
	local pullsUntilHard = math.max(0, hardCap - count)
	local percent = math.clamp((count / hardCap) * 100, 0, 100)
	local isSoftActive = count >= softStart
	local isHardGuaranteed = count >= hardCap
	local mult = PitySystem.GetPityMultiplier(pityState, tierKey)

	return {
		tier = tierKey,
		displayName = cfg.displayName,
		title = cfg.title,
		stars = cfg.stars,
		color = cfg.color,
		badgeColor = cfg.badgeColor,
		current = count,
		softPityStart = softStart,
		hardPity = hardCap,
		pullsUntilSoft = pullsUntilSoft,
		pullsUntilHard = pullsUntilHard,
		percent = math.floor(percent * 10) / 10,
		isSoftPityActive = isSoftActive,
		isHardPityGuaranteed = isHardGuaranteed,
		multiplier = math.floor(mult * 100) / 100,
	}
end

-- ============ 5. GET ALL PITY PROGRESS BUNDLE ============
function PitySystem.GetAllProgress(pityState)
	local result = {}
	for _, tierKey in ipairs(PitySystem.PRIORITY_ORDER) do
		result[tierKey] = PitySystem.GetPityProgress(pityState, tierKey)
	end
	return result
end

-- ============ 6. SERVER EVALUATION (HARD PITY & RNG) ============
function PitySystem.Evaluate(effectiveLuck, playerLevel, pityState, rollRarityFunc)
	pityState = pityState or {}

	-- 1. Cek Hard Pity Garansi
	local isHardPity, guaranteedTier = PitySystem.CheckHardPity(pityState)
	if isHardPity and guaranteedTier then
		return guaranteedTier, true, guaranteedTier
	end

	-- 2. Roll RNG Normal dengan Multiplier Soft Pity
	local rolledRarity = "COMMON"
	if typeof(rollRarityFunc) == "function" then
		rolledRarity = rollRarityFunc(effectiveLuck, playerLevel, pityState)
	end

	return rolledRarity, false, nil
end

-- ============ 7. HIERARCHICAL RESET & UPDATE RULES ============
function PitySystem.UpdatePityOnCatch(pityState, obtainedRarity)
	pityState = pityState or {}
	local r = tostring(obtainedRarity or "COMMON"):upper():gsub("%s+", "_")

	local specialCount = PitySystem.GetPityCount(pityState, "SPECIAL")
	local mythicCount = PitySystem.GetPityCount(pityState, "MYTHIC")
	local legendaryCount = PitySystem.GetPityCount(pityState, "LEGENDARY")

	if r == "SPECIAL" or r == "EX" then
		-- SPECIAL Reset Hierarkis Penuh
		specialCount = 0
		mythicCount = 0
		legendaryCount = 0
	elseif r == "MYTHIC" or r == "UR" then
		-- MYTHIC Reset Mythic & Legendary, Increment Special
		mythicCount = 0
		legendaryCount = 0
		specialCount += 1
	elseif r == "LEGENDARY" or r == "SSR" then
		-- LEGENDARY Reset Legendary, Increment Mythic & Special
		legendaryCount = 0
		mythicCount += 1
		specialCount += 1
	else
		-- Tier Bawah (SUPER_RARE, RARE, COMMON, JUNK, dll): Seluruh Pity Bertambah
		legendaryCount += 1
		mythicCount += 1
		specialCount += 1
	end

	local updated = {
		SPECIAL = specialCount,
		MYTHIC = mythicCount,
		LEGENDARY = legendaryCount,
		-- Aliases
		EX = specialCount,
		UR = mythicCount,
		SSR = legendaryCount,
	}

	return updated
end

-- ============ 8. FORMAT SUMMARY STRING (DEBUGGING & HUD) ============
function PitySystem.FormatPitySummary(pityState)
	local p = PitySystem.GetAllProgress(pityState)
	return string.format(
		"🌟 PITY: [LEGENDARY %d/%d] [MYTHIC %d/%d] [SPECIAL %d/%d]",
		p.LEGENDARY.current, p.LEGENDARY.hardPity,
		p.MYTHIC.current, p.MYTHIC.hardPity,
		p.SPECIAL.current, p.SPECIAL.hardPity
	)
end

return PitySystem
