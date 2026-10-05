--[[
	PianoTilesGame (ModuleScript)
	FISH!TUNE — Backward-Compatible Rhythm Minigame Facade

	Mendelegasikan panggilan langsung ke RhythmController terpusat.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RhythmController = require(Shared:WaitForChild("Minigames"):WaitForChild("Rhythm"):WaitForChild("RhythmController"))

local PianoTilesGame = {}

function PianoTilesGame.IsPlaying()
	return RhythmController.IsPlaying()
end

function PianoTilesGame.Start(config, onWin, onLose)
	return RhythmController.Start(config, onWin, onLose)
end

function PianoTilesGame.Cancel()
	RhythmController.Cancel()
end

function PianoTilesGame.GetActiveSession()
	local activeCtrl = RhythmController.GetActiveController()
	if activeCtrl and activeCtrl.GetActiveSession then
		return activeCtrl.GetActiveSession()
	end
	return nil
end

return PianoTilesGame

