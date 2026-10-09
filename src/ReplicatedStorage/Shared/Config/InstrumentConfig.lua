--[[
    InstrumentConfig (ModuleScript)
    FISH!TUNE — Global Instrument & Island Modifier Configuration

    Menetapkan:
    1. Island difficulty modifiers (Harmony Beach, Coral Reef, Volcano Island, Abyss Trench).
    2. Shared scoring & judgement windows.
]]

local InstrumentConfig = {}

-- ============ ISLAND / ZONE DIFFICULTY MODIFIERS ============
-- Pulau menentukan fish pool & memberikan modifier kecepatan/window
InstrumentConfig.ISLAND_MODIFIERS = {
	HARMONY_BEACH = {
		name = "Harmony Beach",
		speedMultiplier = 1.0,
		penaltyMultiplier = 1.0,
		targetNotesBonus = 0,
		description = "Ombak tenang dan irama dasar santai.",
	},
	CORAL_REEF = {
		name = "Coral Reef Sanctuary",
		speedMultiplier = 1.10,
		penaltyMultiplier = 1.05,
		targetNotesBonus = 3,
		description = "Arus dinamis dengan tempo melodi sedikit lebih cepat.",
	},
	VOLCANO_ISLAND = {
		name = "Volcano Caldera",
		speedMultiplier = 1.25,
		penaltyMultiplier = 1.15,
		targetNotesBonus = 6,
		description = "Panas magma membara dengan ritem intensif dan tempo agresif.",
	},
	ABYSS_TRENCH = {
		name = "Abyss Deep Trench",
		speedMultiplier = 1.40,
		penaltyMultiplier = 1.25,
		targetNotesBonus = 10,
		description = "Kedalaman palung tanpa batas dengan irama super cepat & presisi tinggi.",
	},
}

function InstrumentConfig.GetIslandModifier(zoneName)
	if not zoneName then return InstrumentConfig.ISLAND_MODIFIERS.HARMONY_BEACH end
	local zUpper = tostring(zoneName):upper()
	if zUpper:find("VOLCANO") or zUpper:find("MAGMA") then
		return InstrumentConfig.ISLAND_MODIFIERS.VOLCANO_ISLAND
	elseif zUpper:find("ABYSS") or zUpper:find("PALUNG") or zUpper:find("DEEP") then
		return InstrumentConfig.ISLAND_MODIFIERS.ABYSS_TRENCH
	elseif zUpper:find("CORAL") or zUpper:find("REEF") or zUpper:find("KARANG") then
		return InstrumentConfig.ISLAND_MODIFIERS.CORAL_REEF
	end
	return InstrumentConfig.ISLAND_MODIFIERS.HARMONY_BEACH
end

-- ============ HIT RATINGS & JUDGEMENT WINDOWS ============
InstrumentConfig.HIT_RATINGS = {
	PERFECT = {
		text = "PERFECT",
		symbol = "★ PERFECT ★",
		color = Color3.fromRGB(255, 215, 0), -- Radiant Gold
		glowColor = Color3.fromRGB(255, 245, 160),
		flashColor = Color3.fromRGB(255, 220, 80),
		score = 300,
		scale = 1.25,
		window = 0.05,
	},
	GREAT = {
		text = "GREAT",
		symbol = "◆ GREAT ◆",
		color = Color3.fromRGB(0, 230, 255), -- Electric Cyan
		glowColor = Color3.fromRGB(160, 245, 255),
		flashColor = Color3.fromRGB(0, 210, 255),
		score = 180,
		scale = 1.10,
		window = 0.09,
	},
	GOOD = {
		text = "GOOD",
		symbol = "● GOOD ●",
		color = Color3.fromRGB(80, 235, 120), -- Emerald Green
		glowColor = Color3.fromRGB(180, 255, 200),
		flashColor = Color3.fromRGB(70, 220, 110),
		score = 80,
		scale = 0.95,
		window = 0.18,
	},
	MISS = {
		text = "MISS",
		symbol = "✕ MISS ✕",
		color = Color3.fromRGB(255, 60, 60), -- Crimson Red
		glowColor = Color3.fromRGB(255, 150, 150),
		flashColor = Color3.fromRGB(255, 40, 40),
		score = 0,
		scale = 0.90,
		window = 999,
	},
}

-- ============ CAST BONUSES (STARTING NOTE PROGRESSION ONLY) ============
InstrumentConfig.CAST_BONUSES = {
	PERFECT = {
		startRatio = 0.35, -- 35% Minigame Starting Progress
		gainBonus = 0.02,
		penaltyMult = 0.70,
		label = "PERFECT CAST",
		color = Color3.fromRGB(255, 215, 0),
	},
	GREAT = {
		startRatio = 0.20, -- 20% Minigame Starting Progress
		gainBonus = 0.01,
		penaltyMult = 0.85,
		label = "GREAT CAST",
		color = Color3.fromRGB(0, 220, 255),
	},
	GOOD = {
		startRatio = 0.10, -- 10% Minigame Starting Progress
		gainBonus = 0.00,
		penaltyMult = 1.00,
		label = "GOOD CAST",
		color = Color3.fromRGB(230, 235, 255),
	},
}

return InstrumentConfig
