--[[
    PianoController (ModuleScript)
    FISH!TUNE — Controller for Piano Tiles Minigame

    Mengimplementasikan Standard Lifecycle Contract:
    1. Start(config, onWin, onLose)
    2. IsPlaying()
    3. Cancel()
    4. GetActiveSession()
]]

local PianoSession = require(script.Parent:WaitForChild("PianoSession"))

local PianoController = {}
local activeSession = nil

function PianoController.IsPlaying()
	return activeSession ~= nil and activeSession:IsActive()
end

function PianoController.Start(config, onWin, onLose)
	if activeSession and activeSession:IsActive() then
		activeSession:Cancel()
		activeSession = nil
	end

	activeSession = PianoSession.new(config)
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

function PianoController.Cancel()
	if activeSession then
		activeSession:Cancel()
		activeSession = nil
	end
end

function PianoController.GetActiveSession()
	return activeSession
end

return PianoController
