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

-- Drum Grooves & Rhythms
Config.GROOVES = {
	{
		name = "Celestial Beat Kick Groove",
		notes = { -12, 0, -12, 0, 7, -12, 0, -12, 7, 0, -12, 0, 12, 7, 0, -12 },
		bpm = 128,
		baseSpeed = 0.42,
	},
	{
		name = "Thunder Heavy Rock Beat",
		notes = { -12, -12, 0, -12, 0, 7, -12, 0, -12, -12, 0, 7, 12, 0, -12, 0 },
		bpm = 140,
		baseSpeed = 0.45,
	},
	{
		name = "Tropical Island Bongo Tempo",
		notes = { 0, 4, 7, 0, 4, 7, 12, 7, 4, 0, 7, 4, 0, 4, 7, 12 },
		bpm = 115,
		baseSpeed = 0.38,
	},
}

return Config
