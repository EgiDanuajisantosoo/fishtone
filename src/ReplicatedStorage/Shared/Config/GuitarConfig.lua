--[[
    GuitarConfig (ModuleScript)
    FISH!TUNE — Configuration for Guitar Fretboard Minigame (Pattern / Sequence / Vibrating Strings)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local InstrumentConfig = require(Shared:WaitForChild("Config"):WaitForChild("InstrumentConfig"))

local Config = {}

-- Layout & Input
Config.ACTION_INPUT = "GuitarRhythmInputSink"
Config.KEYS = {
	Enum.KeyCode.D,
	Enum.KeyCode.F,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
}
Config.KEY_LABELS = { "D", "F", "J", "K" }
Config.STRING_NAMES = { "E", "A", "D", "G" }
Config.COLUMN_COUNT = 4

Config.TILE_HEIGHT = 0.16
Config.HIT_LINE = 0.72
Config.MISS_LINE = 0.86

-- Fretboard Aesthetics & Strings
Config.STRING_COLORS = {
	Color3.fromRGB(245, 158, 11),  -- Amber (Senar 1 - E)
	Color3.fromRGB(56, 189, 248),  -- Sky (Senar 2 - A)
	Color3.fromRGB(74, 222, 128),  -- Emerald (Senar 3 - D)
	Color3.fromRGB(244, 63, 94),   -- Rose (Senar 4 - G)
}

Config.STRING_GLOWS = {
	Color3.fromRGB(253, 230, 138),
	Color3.fromRGB(186, 230, 253),
	Color3.fromRGB(187, 247, 208),
	Color3.fromRGB(254, 205, 211),
}

Config.FRETBOARD_COLOR = Color3.fromRGB(18, 22, 32)
Config.FRET_WIRE_COLOR = Color3.fromRGB(180, 140, 90)
Config.PRIMARY_COLOR = Color3.fromRGB(245, 158, 11)

-- Sound Engine
Config.SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
Config.MISS_SOUND_ID = "rbxasset://sounds/splat.wav"
Config.BASE_PITCH = 1.05
Config.VOLUME = 0.92
Config.PLUCK_HARMONIC = true

-- Inherited ratings
Config.HIT_RATINGS = InstrumentConfig.HIT_RATINGS
Config.CAST_BONUSES = InstrumentConfig.CAST_BONUSES

-- Melodies & Guitar Patterns (Synced with SongChartCatalog FISH-043)
local SongChartCatalog = require(Shared:WaitForChild("Definitions"):WaitForChild("SongChartCatalog"))

Config.MELODIES = {
	{
		name = "Spanish Romance (Fingerstyle)",
		notes = { 7, 7, 7, 7, 5, 3, 3, 2, 0, 0, 3, 7, 12, 12, 12, 12, 10, 8, 8, 7, 5, 5, 7, 8, 7, 8, 7, 7, 5, 3, 2, 0 },
		patterns = { {1, 2, 3}, {4, 3, 2, 1}, {2, 3, 4}, {1, 3, 2, 4} },
		baseSpeed = 0.38,
		bpm = 115,
		songId = "SPANISH_ROMANCE",
	},
	{
		name = "Sunset Fingerstyle Lick",
		notes = { 0, 4, 7, 11, 12, 11, 7, 4, 2, 6, 9, 13, 14, 13, 9, 6, 0, 4, 7, 11, 12, 16, 14, 12, 11, 9, 7, 4, 2, 0 },
		patterns = { {1, 2, 4}, {2, 3, 1}, {4, 3, 2}, {1, 4, 2, 3} },
		baseSpeed = 0.40,
		bpm = 120,
		songId = "SUNSET_FINGERSTYLE",
	},
	{
		name = "Abyssal Rock Heavy Riff",
		notes = { -5, -5, -2, 0, -2, -5, 0, 3, 2, 0, -2, -5, -5, -5, -2, 0, 3, 5, 3, 0, -2, -5, 0, 2 },
		patterns = { {1, 1, 2}, {3, 2, 1}, {4, 4, 3}, {2, 1, 3, 4} },
		baseSpeed = 0.44,
		bpm = 140,
		songId = "ABYSSAL_ROCK_RIFF",
	},
	{
		name = "Cosmic Astral Melody",
		notes = { 4, 7, 11, 16, 14, 11, 7, 4, 6, 9, 13, 18, 16, 13, 9, 6, 7, 11, 14, 19, 18, 14, 11, 7, 12, 16, 19, 24 },
		patterns = { {1, 3, 4}, {2, 4, 1}, {3, 2, 4}, {4, 1, 3, 2} },
		baseSpeed = 0.42,
		bpm = 135,
		songId = "COSMIC_ASTRAL_MELODY",
	},
	{
		name = "Canon in D (Fingerstyle Acoustic)",
		notes = { 2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7, 9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14 },
		patterns = { {1, 2, 3}, {2, 3, 4}, {1, 3, 2}, {4, 3, 2, 1} },
		baseSpeed = 0.38,
		bpm = 120,
		songId = "CANON_IN_D",
	},
	{
		name = "Für Elise (Nylon Acoustic)",
		notes = { 7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0, 2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0 },
		patterns = { {2, 3, 4}, {1, 2, 3}, {4, 3, 1}, {2, 1, 3} },
		baseSpeed = 0.40,
		bpm = 130,
		songId = "FUR_ELISE",
	},
	{
		name = "River Flow (Acoustic Folk)",
		notes = { 0, 2, 4, 7, 9, 12, 14, 12, 9, 7, 4, 2, 4, 7, 9, 12, 16, 14, 12, 9, 7, 4, 2, 0 },
		patterns = { {1, 2, 3}, {3, 2, 1}, {2, 3, 4}, {1, 4, 3} },
		baseSpeed = 0.36,
		bpm = 110,
		songId = "RIVER_FLOWS_IN_YOU",
	},
	{
		name = "Moonlight Sonata (Arpeggio)",
		notes = { 0, 3, 7, 0, 3, 7, -2, 3, 7, -4, 2, 5, -5, 0, 3, 0, 3, 7, 12, 7, 3, 0 },
		patterns = { {1, 2, 3}, {1, 2, 3}, {2, 3, 4}, {1, 3, 4} },
		baseSpeed = 0.35,
		bpm = 105,
		songId = "MOONLIGHT_SONATA",
	},
	{
		name = "Bumblebee Shred (Electric)",
		notes = { 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
		patterns = { {4, 3, 2, 1}, {1, 2, 3, 4}, {4, 2, 3, 1}, {3, 1, 4, 2} },
		baseSpeed = 0.48,
		bpm = 160,
		songId = "FLIGHT_OF_THE_BUMBLEBEE",
	},
	{
		name = "Flamenco Fire Storm",
		notes = { 0, 1, 4, 5, 7, 8, 11, 12, 11, 8, 7, 5, 4, 1, 0, 4, 7, 12, 16, 17, 16, 12, 7, 4, 0 },
		patterns = { {1, 2, 3, 4}, {4, 3, 2, 1}, {1, 3, 2, 4}, {2, 4, 1, 3} },
		baseSpeed = 0.46,
		bpm = 155,
		songId = "FLAMENCO_FIRE_STORM",
	},
}

return Config
