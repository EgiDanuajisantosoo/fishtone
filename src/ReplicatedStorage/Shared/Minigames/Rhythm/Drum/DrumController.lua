--[[
    DrumController (ModuleScript)
    FISH!TUNE — Controller for Drum Rhythm & Beat Timing Minigame

    Mengimplementasikan Standard Lifecycle Contract:
    1. Start(config, onWin, onLose)
    2. IsPlaying()
    3. Cancel()
    4. GetActiveSession()
]]

local DrumSession = require(script.Parent:WaitForChild("DrumSession"))

local DrumController = {}
local activeSession = nil

function DrumController.IsPlaying()
	return activeSession ~= nil and activeSession:IsActive()
end

function DrumController.Start(config, onWin, onLose)
	if activeSession and activeSession:IsActive() then
		activeSession:Cancel()
		activeSession = nil
	end

	activeSession = DrumSession.new(config)
	local started = activeSession:Start(function(metrics)
		if onWin then onWin(metrics) end
		activeSession = nil
	end, function(metrics)
		if onLose then onLose(metrics) end
		activeSession = nil
	end)

	if not started then
		activeSession = nil
		return false
	end

	return true
end

function DrumController.Cancel()
	if activeSession then
		activeSession:Cancel()
		activeSession = nil
	end
end

function DrumController.GetActiveSession()
	return activeSession
end

return DrumController
