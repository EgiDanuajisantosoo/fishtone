--[[
	PianoTilesGame (ModuleScript)
	FISH!TUNE — Rhythm Minigame Facade & Session Controller (FISH-012)

	Layanan Sentral Permainan Rhythm Mini-Game Piano Tiles:
	1. Manajemen Sesi Rhythm Terisolasi berbasis RhythmSession.
	2. API Publik yang Bersih & Kompatibel Penuh (Start, IsPlaying, Cancel).
	3. Mencegah Kebocoran State Singleton / Race Condition saat Permainan Ulang.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RhythmSession = require(script.Parent:WaitForChild("RhythmSession"))

local PianoTilesGame = {}

local activeSession = nil

-- ============ PUBLIC API ============
function PianoTilesGame.IsPlaying()
	return activeSession ~= nil and activeSession:IsActive()
end

function PianoTilesGame.Start(config, onWin, onLose)
	-- Batalkan sesi aktif sebelumnya jika masih berjalan
	if activeSession and activeSession:IsActive() then
		activeSession:Cancel()
		activeSession = nil
	end

	activeSession = RhythmSession.new(config)
	local started = activeSession:Start(function(metrics)
		if onWin then
			onWin(metrics)
		end
		activeSession = nil
	end, function(metrics)
		if onLose then
			onLose(metrics)
		end
		activeSession = nil
	end)

	if not started then
		activeSession = nil
		return false
	end

	return true
end

function PianoTilesGame.Cancel()
	if activeSession then
		activeSession:Cancel()
		activeSession = nil
	end
end

function PianoTilesGame.GetActiveSession()
	return activeSession
end

return PianoTilesGame
