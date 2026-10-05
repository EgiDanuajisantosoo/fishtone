--[[
    RhythmController (ModuleScript)
    FISH!TUNE — Central Rhythm Minigame Router & Lifecycle Controller

    Menjadi Titik Masuk Tunggal (Single Entry Point) bagi Sistem Fishing:
    1. Membaca jenis instrumen dari Joran (Piano, Guitar, Drum) via InstrumentDefinitions.
    2. Me-route sesi minigame secara otomatis ke:
       - PianoController   (Piano Tiles / Precision Multi-Lane)
       - GuitarController  (Guitar Fretboard / Pattern Sequence / Vibrating Strings)
       - DrumController    (Drum Rhythm / Concentric Beat Timing)
    3. Mengisolasi Sistem Fishing dari detail teknis rendering minigame.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local PianoController = require(script.Parent:WaitForChild("Piano"):WaitForChild("PianoController"))
local GuitarController = require(script.Parent:WaitForChild("Guitar"):WaitForChild("GuitarController"))
local DrumController = require(script.Parent:WaitForChild("Drum"):WaitForChild("DrumController"))

local RhythmController = {}
local activeInstrumentType = nil
local activeController = nil

-- ============ CONTROLLER REGISTRY ============
local Controllers = {
	[InstrumentDefinitions.Types.PIANO] = PianoController,
	[InstrumentDefinitions.Types.GUITAR] = GuitarController,
	[InstrumentDefinitions.Types.DRUM] = DrumController,
}

-- ============ PUBLIC API ============
function RhythmController.IsPlaying()
	if activeController and activeController.IsPlaying then
		return activeController.IsPlaying()
	end
	return false
end

function RhythmController.Start(config, onWin, onLose)
	config = config or {}

	-- Batalkan sesi aktif sebelumnya jika masih berjalan
	if RhythmController.IsPlaying() then
		RhythmController.Cancel()
	end

	-- Tentukan jenis instrumen berdasarkan joran atau config eksplisit
	local instrumentType = config.instrumentType
	if not instrumentType or not Controllers[instrumentType] then
		instrumentType = InstrumentDefinitions.GetInstrumentTypeForRod(config.rodId)
	end

	local controller = Controllers[instrumentType] or PianoController
	activeInstrumentType = instrumentType
	activeController = controller

	local success = controller.Start(config, function(metrics)
		activeController = nil
		activeInstrumentType = nil
		if onWin then
			onWin(metrics)
		end
	end, function(metrics)
		activeController = nil
		activeInstrumentType = nil
		if onLose then
			onLose(metrics)
		end
	end)

	if not success then
		activeController = nil
		activeInstrumentType = nil
		return false
	end

	return true
end

function RhythmController.Cancel()
	if activeController and activeController.Cancel then
		activeController.Cancel()
	end
	activeController = nil
	activeInstrumentType = nil
end

function RhythmController.GetActiveController()
	return activeController
end

function RhythmController.GetActiveInstrumentType()
	return activeInstrumentType
end

return RhythmController
