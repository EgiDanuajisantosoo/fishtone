--[[
    PianoConfig (ModuleScript)
    FISH!TUNE — Configuration for Piano Tiles Minigame (Precision Multi-Lane)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local InstrumentConfig = require(Shared:WaitForChild("Config"):WaitForChild("InstrumentConfig"))

local Config = {}

-- Layout & Input
Config.ACTION_INPUT = "PianoRhythmInputSink"
Config.KEYS = {
	Enum.KeyCode.D,
	Enum.KeyCode.F,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
}
Config.KEY_LABELS = { "D", "F", "J", "K" }
Config.COLUMN_COUNT = 4

Config.TILE_HEIGHT = 0.16
Config.HIT_LINE = 0.72
Config.MISS_LINE = 0.86

-- Tile Assets
Config.TILE_IMAGES = {
	[1] = "rbxassetid://81497165860027",
	[2] = "rbxassetid://114443002786033",
	[3] = "rbxassetid://97763159477340",
	[4] = "rbxassetid://107689147771762",
}

-- Audio & Visual Theme
Config.SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
Config.MISS_SOUND_ID = "rbxasset://sounds/splat.wav"
Config.BASE_PITCH = 0.85
Config.VOLUME = 0.88
Config.PRIMARY_COLOR = Color3.fromRGB(0, 210, 255)
Config.ACCENT_COLOR = Color3.fromRGB(180, 245, 255)

-- Inherited ratings
Config.HIT_RATINGS = InstrumentConfig.HIT_RATINGS
Config.CAST_BONUSES = InstrumentConfig.CAST_BONUSES

-- Melodies (Synced with SongChartCatalog FISH-043)
local SongChartCatalog = require(Shared:WaitForChild("Definitions"):WaitForChild("SongChartCatalog"))

Config.MELODIES = {
	{
		name = "Canon in D (Piano Classic)",
		notes = { 2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7, 9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14 },
		baseSpeed = 0.38,
		bpm = 120,
		songId = "CANON_IN_D",
	},
	{
		name = "Für Elise (Harmonic Piano)",
		notes = { 7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0, 2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0 },
		baseSpeed = 0.40,
		bpm = 130,
		songId = "FUR_ELISE",
	},
	{
		name = "River Flows in You",
		notes = { 9, 11, 12, 11, 9, 7, 4, 2, 0, 4, 7, 9, 12, 14, 16, 14, 12, 9, 7, 4, 2, 0 },
		baseSpeed = 0.36,
		bpm = 110,
		songId = "RIVER_FLOWS_IN_YOU",
	},
	{
		name = "Moonlight Sonata (Adagio)",
		notes = { 0, 3, 7, 0, 3, 7, 0, 3, 7, -2, 3, 7, -2, 3, 7, -4, 2, 5, -5, 0, 3, 0, 3, 7 },
		baseSpeed = 0.34,
		bpm = 105,
		songId = "MOONLIGHT_SONATA",
	},
	{
		name = "Clair de Lune (Ethereal)",
		notes = { 1, 8, 5, 8, 5, 8, 1, 6, 5, 6, 5, 6, 8, 10, 13, 15, 13, 10, 8, 5, 1, 5, 8 },
		baseSpeed = 0.35,
		bpm = 98,
		songId = "CLAIR_DE_LUNE",
	},
	{
		name = "Flight of the Bumblebee (Rapid)",
		notes = { 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 11, 10, 9, 8, 7 },
		baseSpeed = 0.46,
		bpm = 160,
		songId = "FLIGHT_OF_THE_BUMBLEBEE",
	},
	{
		name = "Spanish Romance (Piano Melody)",
		notes = { 7, 7, 7, 7, 5, 3, 3, 2, 0, 0, 3, 7, 12, 12, 12, 12, 10, 8, 8, 7, 5, 5, 7, 8, 7, 8, 7, 7, 5, 3, 2, 0 },
		baseSpeed = 0.37,
		bpm = 115,
		songId = "SPANISH_ROMANCE",
	},
	{
		name = "Cosmic Astral Synth",
		notes = { 4, 7, 11, 16, 14, 11, 7, 4, 6, 9, 13, 18, 16, 13, 9, 6, 7, 11, 14, 19, 18, 14, 11, 7, 12, 16, 19, 24 },
		baseSpeed = 0.42,
		bpm = 135,
		songId = "COSMIC_ASTRAL_MELODY",
	},
}

return Config
