--[[
    DrumConfig (ModuleScript)
    FISH!TUNE — Configuration for Drum Rhythm Minigame (Reaction / Concentric Beat Timing)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local InstrumentConfig = require(Shared:WaitForChild("Config"):WaitForChild("InstrumentConfig"))

local Config = {}

-- Layout & Input
Config.ACTION_INPUT = "DrumRhythmInputSink"
Config.KEYS = {
	Enum.KeyCode.A,
	Enum.KeyCode.W,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
}
Config.KEY_LABELS = { "A", "W", "S", "D" }
Config.PAD_NAMES = { "SNARE", "CRASH", "KICK", "HI-HAT" }
Config.PAD_ICONS = { "🥁", "💥", "🔊", "✨" }
Config.COLUMN_COUNT = 4

Config.TILE_HEIGHT = 0.16
Config.HIT_LINE = 0.72
Config.MISS_LINE = 0.86

-- Drum Pad Colors
Config.PAD_COLORS = {
	Color3.fromRGB(245, 158, 11),  -- Snare (Amber)
	Color3.fromRGB(168, 85, 247),  -- Crash (Purple)
	Color3.fromRGB(239, 68, 68),   -- Bass Kick (Crimson)
	Color3.fromRGB(56, 189, 248),  -- Hi-Hat (Sky)
}

Config.PAD_GLOWS = {
	Color3.fromRGB(253, 230, 138),
	Color3.fromRGB(233, 213, 255),
	Color3.fromRGB(254, 202, 202),
	Color3.fromRGB(186, 230, 253),
}

Config.ARENA_COLOR = Color3.fromRGB(16, 12, 22)
Config.PRIMARY_COLOR = Color3.fromRGB(239, 68, 68)

-- Sound Engine (Percussion Beats)
Config.SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
Config.MISS_SOUND_ID = "rbxasset://sounds/splat.wav"
Config.BASE_PITCH = 0.75
Config.VOLUME = 0.95

-- Inherited ratings
Config.HIT_RATINGS = InstrumentConfig.HIT_RATINGS
Config.CAST_BONUSES = InstrumentConfig.CAST_BONUSES

-- Drum Grooves & Rhythms (Synced with SongChartCatalog FISH-043)
local SongChartCatalog = require(Shared:WaitForChild("Definitions"):WaitForChild("SongChartCatalog"))

Config.GROOVES = {
	{
		name = "Celestial Beat Kick Groove",
		notes = { -12, 0, -12, 0, 7, -12, 0, -12, 7, 0, -12, 0, 12, 7, 0, -12 },
		bpm = 128,
		baseSpeed = 0.42,
		songId = "CELESTIAL_BEAT_PULSE",
	},
	{
		name = "Thunder Heavy Rock Beat",
		notes = { -12, -12, 0, -12, 0, 7, -12, 0, -12, -12, 0, 7, 12, 0, -12, 0 },
		bpm = 140,
		baseSpeed = 0.45,
		songId = "THUNDER_ROCK_BEAT",
	},
	{
		name = "Tropical Island Bongo Tempo",
		notes = { 0, 4, 7, 0, 4, 7, 12, 7, 4, 0, 7, 4, 0, 4, 7, 12 },
		bpm = 115,
		baseSpeed = 0.38,
		songId = "TROPICAL_BONGO_PULSE",
	},
	{
		name = "Abyssal Metal Double Kick",
		notes = { -12, -12, 0, -12, 0, 7, -12, -12, 0, -12, 7, 12, -12, -12, 0, 7 },
		bpm = 140,
		baseSpeed = 0.44,
		songId = "ABYSSAL_ROCK_RIFF",
	},
	{
		name = "Kraken Deep Sea Pulse",
		notes = { -12, -12, -12, 0, 7, 0, -12, 12, -12, -12, 0, 7, 12, 7, 0, -12 },
		bpm = 150,
		baseSpeed = 0.47,
		songId = "KRAKEN_DEEP_PULSE",
	},
	{
		name = "Skull Summit Apex Overdrive",
		notes = { -12, -12, 0, -12, -12, 0, 7, -12, -12, 0, 12, 7, 0, -12, -12, 12 },
		bpm = 165,
		baseSpeed = 0.50,
		songId = "SKULL_SUMMIT_OVERDRIVE",
	},
}

return Config
