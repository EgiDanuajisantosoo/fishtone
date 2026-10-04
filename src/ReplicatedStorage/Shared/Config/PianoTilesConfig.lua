--[[
    PianoTilesConfig (ModuleScript)

    Satu sumber konfigurasi untuk Piano Tiles.
    Game dan UI sama-sama membaca nilai dari module ini.
]]

local Config = {}

-- ============ GAME / UI LAYOUT ============
Config.ACTION_PIANO_INPUT = "PianoTilesInputSink"
Config.KEYS = {
	Enum.KeyCode.A,
	Enum.KeyCode.W,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
}
Config.KEY_LABELS = { "A", "W", "S", "D" }
Config.COLUMN_COUNT = 4

-- Nilai ini dipakai sebagai ukuran/logical height tile untuk gameplay.
-- UI juga membaca nilai yang sama.
Config.TILE_HEIGHT = 0.16
Config.HIT_LINE = 0.78
Config.MISS_LINE = 0.80

-- ============ TILE IMAGES ============
Config.TILE_IMAGES = {
	[1] = "rbxassetid://81497165860027",
	[2] = "rbxassetid://114443002786033",
	[3] = "rbxassetid://97763159477340",
	[4] = "rbxassetid://107689147771762",
}

-- ============ HIT RATINGS & JUDGEMENT FEEDBACK ============
Config.HIT_RATINGS = {
	PERFECT = {
		text = "PERFECT",
		symbol = "★ PERFECT ★",
		color = Color3.fromRGB(255, 215, 0), -- Radiant Gold
		glowColor = Color3.fromRGB(255, 245, 160),
		flashColor = Color3.fromRGB(255, 220, 80),
		score = 300,
		scale = 1.25,
		window = 0.04,
	},
	GREAT = {
		text = "GREAT",
		symbol = "◆ GREAT ◆",
		color = Color3.fromRGB(0, 230, 255), -- Electric Cyan
		glowColor = Color3.fromRGB(160, 245, 255),
		flashColor = Color3.fromRGB(0, 210, 255),
		score = 180,
		scale = 1.10,
		window = 0.08,
	},
	GOOD = {
		text = "GOOD",
		symbol = "● GOOD ●",
		color = Color3.fromRGB(80, 235, 120), -- Emerald Green
		glowColor = Color3.fromRGB(180, 255, 200),
		flashColor = Color3.fromRGB(70, 220, 110),
		score = 80,
		scale = 0.95,
		window = 0.15,
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


-- ============ CAST BONUS ============
Config.CAST_BONUSES = {
	PERFECT = {
		startRatio = 0.35,
		gainBonus = 0.02,
		penaltyMult = 0.70,
		label = "PERFECT CAST",
		color = Color3.fromRGB(255, 255, 255),
	},

	GREAT = {
		startRatio = 0.20,
		gainBonus = 0.01,
		penaltyMult = 0.85,
		label = "GREAT CAST",
		color = Color3.fromRGB(255, 255, 255),
	},

	GOOD = {
		startRatio = 0.10,
		gainBonus = 0.00,
		penaltyMult = 1.00,
		label = "GOOD CAST",
		color = Color3.fromRGB(255, 255, 255),
	},
}

-- ============ MELODIES ============
Config.MELODIES = {
	{
		name = "Canon in D",
		notes = {
			2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7,
			9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14
		},
		baseSpeed = 0.38,
	},

	{
		name = "Ode to Joy",
		notes = {
			4, 4, 5, 7, 7, 5, 4, 2, 0, 0, 2, 4, 4,
			2, 2, 4, 4, 5, 7, 7, 5, 4, 2, 0, 0, 2, 4, 2, 0
		},
		baseSpeed = 0.36,
	},

	{
		name = "River Flow",
		notes = {
			0, 2, 4, 7, 9, 12, 14, 12, 9, 7, 4, 2,
			4, 7, 9, 12, 16, 14, 12, 9, 7, 4, 2, 0
		},
		baseSpeed = 0.35,
	},

	{
		name = "Für Elise",
		notes = {
			7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0,
			2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0
		},
		baseSpeed = 0.40,
	},
}

return Config
