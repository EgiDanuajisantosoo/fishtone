--[[
    GuitarController (ModuleScript)
    FISH!TUNE — Controller for Guitar Fretboard & Pattern Minigame

    Mengimplementasikan Standard Lifecycle Contract:
    1. Start(config, onWin, onLose)
    2. IsPlaying()
    3. Cancel()
    4. GetActiveSession()
]]

local GuitarSession = require(script.Parent:WaitForChild("GuitarSession"))

local GuitarController = {}
local activeSession = nil

function GuitarController.IsPlaying()
	return activeSession ~= nil and activeSession:IsActive()
end

function GuitarController.Start(config, onWin, onLose)
	if activeSession and activeSession:IsActive() then
		activeSession:Cancel()
		activeSession = nil
	end

	activeSession = GuitarSession.new(config)
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

function GuitarController.Cancel()
	if activeSession then
		activeSession:Cancel()
		activeSession = nil
	end
end

function GuitarController.GetActiveSession()
	return activeSession
end

return GuitarController
