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
Config.HIT_LINE = 0.72
Config.MISS_LINE = 0.86

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


-- ============ INSTRUMENT SOUND & FRETBOARD ENGINES (FISH-027) ============
Config.INSTRUMENTS = {
	ACOUSTIC_GUITAR = {
		id = "ACOUSTIC_GUITAR",
		name = "Gitar Akustik Fingerstyle",
		badge = "🎸 AKUSTIK",
		icon = "🎸",
		basePitch = 0.95,
		volume = 0.9,
		keyLabels = { "A", "W", "S", "D" },
		stringNames = { "E", "A", "D", "G" },
		stringColors = {
			Color3.fromRGB(245, 158, 11),  -- Amber
			Color3.fromRGB(56, 189, 248),  -- Sky
			Color3.fromRGB(74, 222, 128),  -- Emerald
			Color3.fromRGB(244, 63, 94),   -- Rose
		},
		stringGlows = {
			Color3.fromRGB(253, 230, 138),
			Color3.fromRGB(186, 230, 253),
			Color3.fromRGB(187, 247, 208),
			Color3.fromRGB(254, 205, 211),
		},
		fretboardColor = Color3.fromRGB(18, 22, 32),
		fretWireColor = Color3.fromRGB(180, 140, 90),
		soundId = "rbxasset://sounds/electronicpingshort.wav",
		missSound = "rbxasset://sounds/splat.wav",
		pluckVibration = true,
		headerColor = Color3.fromRGB(245, 158, 11),
	},
	ELECTRIC_GUITAR = {
		id = "ELECTRIC_GUITAR",
		name = "Gitar Elektrik Resonansi",
		badge = "⚡ ELEKTRIK",
		icon = "⚡",
		basePitch = 1.15,
		volume = 0.92,
		keyLabels = { "A", "W", "S", "D" },
		stringNames = { "1", "2", "3", "4" },
		stringColors = {
			Color3.fromRGB(168, 85, 247),  -- Purple
			Color3.fromRGB(56, 189, 248),  -- Cyan
			Color3.fromRGB(250, 204, 21),  -- Yellow
			Color3.fromRGB(239, 68, 68),   -- Red
		},
		stringGlows = {
			Color3.fromRGB(233, 213, 255),
			Color3.fromRGB(186, 230, 253),
			Color3.fromRGB(254, 240, 138),
			Color3.fromRGB(254, 202, 202),
		},
		fretboardColor = Color3.fromRGB(14, 18, 28),
		fretWireColor = Color3.fromRGB(56, 189, 248),
		soundId = "rbxasset://sounds/electronicpingshort.wav",
		missSound = "rbxasset://sounds/splat.wav",
		pluckVibration = true,
		headerColor = Color3.fromRGB(56, 189, 248),
	},
	ABYSSAL_METAL = {
		id = "ABYSSAL_METAL",
		name = "Gitar Palung Overdrive",
		badge = "🔱 METAL",
		icon = "🔱",
		basePitch = 0.78,
		volume = 0.95,
		keyLabels = { "A", "W", "S", "D" },
		stringNames = { "B", "E", "A", "D" },
		stringColors = {
			Color3.fromRGB(239, 68, 68),   -- Crimson
			Color3.fromRGB(168, 85, 247),  -- Violet
			Color3.fromRGB(59, 130, 246),  -- Blue
			Color3.fromRGB(234, 179, 8),   -- Gold
		},
		stringGlows = {
			Color3.fromRGB(254, 202, 202),
			Color3.fromRGB(233, 213, 255),
			Color3.fromRGB(191, 219, 254),
			Color3.fromRGB(254, 240, 138),
		},
		fretboardColor = Color3.fromRGB(10, 12, 20),
		fretWireColor = Color3.fromRGB(239, 68, 68),
		soundId = "rbxasset://sounds/electronicpingshort.wav",
		missSound = "rbxasset://sounds/splat.wav",
		pluckVibration = true,
		headerColor = Color3.fromRGB(239, 68, 68),
	},
	PIANO = {
		id = "PIANO",
		name = "Piano Klasik Harmoni",
		badge = "🎹 PIANO",
		icon = "🎹",
		basePitch = 0.85,
		volume = 0.85,
		keyLabels = { "A", "W", "S", "D" },
		stringNames = { "I", "II", "III", "IV" },
		stringColors = {
			Color3.fromRGB(0, 200, 255),
			Color3.fromRGB(0, 220, 255),
			Color3.fromRGB(0, 240, 255),
			Color3.fromRGB(0, 255, 255),
		},
		stringGlows = {
			Color3.fromRGB(180, 240, 255),
			Color3.fromRGB(190, 245, 255),
			Color3.fromRGB(200, 250, 255),
			Color3.fromRGB(220, 255, 255),
		},
		fretboardColor = Color3.fromRGB(10, 14, 24),
		fretWireColor = Color3.fromRGB(60, 120, 180),
		soundId = "rbxasset://sounds/electronicpingshort.wav",
		missSound = "rbxasset://sounds/splat.wav",
		pluckVibration = false,
		headerColor = Color3.fromRGB(0, 210, 255),
	},
}

-- ============ ROD TO INSTRUMENT MAPPER ============
function Config.GetInstrumentForRod(rodId)
	rodId = tostring(rodId or "StarterRod")
	if rodId == "StarterRod" or rodId == "BambooRod" then
		return Config.INSTRUMENTS.ACOUSTIC_GUITAR
	elseif rodId == "CarbonFiberRod" or rodId == "HarmonicTuningRod" then
		return Config.INSTRUMENTS.ELECTRIC_GUITAR
	elseif rodId == "AbyssalTridentRod" then
		return Config.INSTRUMENTS.ABYSSAL_METAL
	elseif rodId == "CelestialMelodyRod" then
		return Config.INSTRUMENTS.ELECTRIC_GUITAR
	end
	return Config.INSTRUMENTS.ACOUSTIC_GUITAR
end

function Config.GetInstrument(instrumentId)
	return (instrumentId and Config.INSTRUMENTS[instrumentId]) or Config.INSTRUMENTS.ACOUSTIC_GUITAR
end

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

-- ============ MELODIES & GUITAR REPERTOIRE ============
Config.MELODIES = {
	{
		name = "Spanish Romance (Gitar Klasik)",
		instrument = "ACOUSTIC_GUITAR",
		notes = {
			7, 7, 7, 7, 5, 3, 3, 2, 0, 0, 3, 7, 12, 12, 12,
			12, 10, 8, 8, 7, 5, 5, 7, 8, 7, 8, 7, 7, 5, 3, 2, 0
		},
		baseSpeed = 0.36,
	},

	{
		name = "Sunset Fingerstyle Lick",
		instrument = "ACOUSTIC_GUITAR",
		notes = {
			0, 4, 7, 11, 12, 11, 7, 4, 2, 6, 9, 13, 14, 13, 9, 6,
			0, 4, 7, 11, 12, 16, 14, 12, 11, 9, 7, 4, 2, 0
		},
		baseSpeed = 0.38,
	},

	{
		name = "Abyssal Electric Rock Riff",
		instrument = "ABYSSAL_METAL",
		notes = {
			-5, -5, -2, 0, -2, -5, 0, 3, 2, 0, -2, -5,
			-5, -5, -2, 0, 3, 5, 3, 0, -2, -5, 0, 2
		},
		baseSpeed = 0.42,
	},

	{
		name = "Canon in D (Guitar Fingerstyle)",
		instrument = "ACOUSTIC_GUITAR",
		notes = {
			2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7,
			9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14
		},
		baseSpeed = 0.38,
	},

	{
		name = "Cosmic Astral Melody",
		instrument = "ELECTRIC_GUITAR",
		notes = {
			4, 7, 11, 16, 14, 11, 7, 4, 6, 9, 13, 18, 16, 13, 9, 6,
			7, 11, 14, 19, 18, 14, 11, 7, 12, 16, 19, 24
		},
		baseSpeed = 0.40,
	},

	{
		name = "River Flow (Acoustic Folk)",
		instrument = "ACOUSTIC_GUITAR",
		notes = {
			0, 2, 4, 7, 9, 12, 14, 12, 9, 7, 4, 2,
			4, 7, 9, 12, 16, 14, 12, 9, 7, 4, 2, 0
		},
		baseSpeed = 0.35,
	},

	{
		name = "Für Elise (Acoustic Nylon)",
		instrument = "ACOUSTIC_GUITAR",
		notes = {
			7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0,
			2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0
		},
		baseSpeed = 0.40,
	},
}

return Config
