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
	Enum.KeyCode.A,
	Enum.KeyCode.W,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
}
Config.KEY_LABELS = { "A", "W", "S", "D" }
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

-- Melodies
Config.MELODIES = {
	{
		name = "Canon in D (Piano Classic)",
		notes = { 2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7, 9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14 },
		baseSpeed = 0.38,
	},
	{
		name = "Für Elise (Harmonic Piano)",
		notes = { 7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0, 2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0 },
		baseSpeed = 0.40,
	},
	{
		name = "River Flows in You",
		notes = { 9, 11, 12, 11, 9, 7, 4, 2, 0, 4, 7, 9, 12, 14, 16, 14, 12, 9, 7, 4, 2, 0 },
		baseSpeed = 0.36,
	},
	{
		name = "Moonlight Sonata (Adagio)",
		notes = { 0, 3, 7, 0, 3, 7, 0, 3, 7, -2, 3, 7, -2, 3, 7, -4, 2, 5, -5, 0, 3, 0, 3, 7 },
		baseSpeed = 0.34,
	},
}

return Config
