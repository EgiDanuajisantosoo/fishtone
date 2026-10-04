--[[
	RemoteContract (ModuleScript)
	FISH!TUNE — Network Protocol & Remote Contract (FISH-003)

	Satu sumber kebenaran (Single Source of Truth) untuk komunikasi Client <-> Server:
	1. Definisi Enums & Action Names terpusat (mencegah typo/magic strings).
	2. Helper inisialisasi RemoteEvent aman (auto-create di Server, safe wait di Client).
	3. Typed Helper Methods untuk Client (FireServer wrappers) & Server (FireClient wrappers).
	4. Schema validator payload untuk keamanan server (anti-exploit).
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteContract = {}

-- ============ REMOTE CONSTANTS ============
RemoteContract.REMOTE_NAME = "FishingRemote"

-- ============ ACTION NAMES ============
-- Client -> Server Actions
RemoteContract.C2S = {
	START_FISHING    = "StartFishing",
	SUBMIT_CATCH     = "SubmitCatch",
	CANCEL_FISHING   = "CancelFishing",
	SELL_FISH        = "SellFish",
	SELL_ALL_FISH    = "SellAllFish",
	SELL_CATEGORY    = "SellCategory",
	TOGGLE_LOCK_ITEM = "ToggleLockItem",
	GET_PLAYER_DATA  = "GetPlayerData",
}

-- Server -> Client Actions
RemoteContract.S2C = {
	SESSION_STARTED    = "SessionStarted",
	CATCH_SUCCESS      = "CatchSuccess",
	FISH_SOLD          = "FishSold",
	ALL_FISH_SOLD      = "AllFishSold",
	LEVEL_UP           = "LevelUp",
	PLAYER_DATA_UPDATE = "PlayerDataUpdate",
	NOTIFICATION       = "Notification",
}

-- ============ REMOTE PROVIDER ============
local cachedRemote = nil

function RemoteContract.GetRemote()
	if cachedRemote and cachedRemote.Parent then
		return cachedRemote
	end

	if RunService:IsServer() then
		local remote = ReplicatedStorage:FindFirstChild(RemoteContract.REMOTE_NAME)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = RemoteContract.REMOTE_NAME
			remote.Parent = ReplicatedStorage
		end
		cachedRemote = remote
		return remote
	else
		local remote = ReplicatedStorage:WaitForChild(RemoteContract.REMOTE_NAME, 10)
		if not remote then
			warn("[RemoteContract] RemoteEvent '" .. RemoteContract.REMOTE_NAME .. "' tidak ditemukan di ReplicatedStorage!")
		end
		cachedRemote = remote
		return remote
	end
end

-- ============ SERVER DISPATCHERS (Server -> Client) ============
RemoteContract.Server = {}

function RemoteContract.Server.Notify(player, message)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(player, RemoteContract.S2C.NOTIFICATION, message)
	end
end

function RemoteContract.Server.SessionStarted(player, sessionId, waitDuration, castQuality, rarity)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(
			player,
			RemoteContract.S2C.SESSION_STARTED,
			sessionId,
			waitDuration,
			castQuality,
			rarity
		)
	end
end

function RemoteContract.Server.CatchSuccess(player, fishData, rewardInfo, pData, pityState)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(
			player,
			RemoteContract.S2C.CATCH_SUCCESS,
			fishData,
			rewardInfo,
			pData,
			pityState
		)
	end
end

function RemoteContract.Server.FishSold(player, fishName, coinsGained, currentCoins)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(
			player,
			RemoteContract.S2C.FISH_SOLD,
			fishName,
			coinsGained,
			currentCoins
		)
	end
end

function RemoteContract.Server.AllFishSold(player, count, totalCoins, currentCoins)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(
			player,
			RemoteContract.S2C.ALL_FISH_SOLD,
			count,
			totalCoins,
			currentCoins
		)
	end
end

function RemoteContract.Server.LevelUp(player, newLevel)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(
			player,
			RemoteContract.S2C.LEVEL_UP,
			newLevel
		)
	end
end

function RemoteContract.Server.PlayerDataUpdate(player, pData, pityState)
	local remote = RemoteContract.GetRemote()
	if remote and player then
		remote:FireClient(
			player,
			RemoteContract.S2C.PLAYER_DATA_UPDATE,
			pData,
			pityState
		)
	end
end

-- ============ CLIENT DISPATCHERS (Client -> Server) ============
RemoteContract.Client = {}

function RemoteContract.Client.StartFishing(waterPos, castQuality, finalPower)
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.START_FISHING, waterPos, castQuality, finalPower)
	end
end

function RemoteContract.Client.SubmitCatch(sessionId, metrics)
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.SUBMIT_CATCH, sessionId, metrics)
	end
end

function RemoteContract.Client.CancelFishing(sessionId)
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.CANCEL_FISHING, sessionId)
	end
end

function RemoteContract.Client.SellFish(tool)
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.SELL_FISH, tool)
	end
end

function RemoteContract.Client.SellAllFish()
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.SELL_ALL_FISH)
	end
end

function RemoteContract.Client.SellCategory(category)
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.SELL_CATEGORY, category)
	end
end

function RemoteContract.Client.ToggleLockItem(toolOrId)
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.TOGGLE_LOCK_ITEM, toolOrId)
	end
end

function RemoteContract.Client.GetPlayerData()
	local remote = RemoteContract.GetRemote()
	if remote then
		remote:FireServer(RemoteContract.C2S.GET_PLAYER_DATA)
	end
end

-- ============ VALIDATION HELPERS ============
RemoteContract.Validator = {}

function RemoteContract.Validator.IsValidVector3(val)
	return typeof(val) == "Vector3"
end

function RemoteContract.Validator.IsValidSessionId(val)
	return typeof(val) == "string" and #val > 0 and #val <= 128
end

function RemoteContract.Validator.IsValidCastQuality(val)
	return val == "PERFECT" or val == "GREAT" or val == "GOOD"
end

function RemoteContract.Validator.IsValidMetrics(val)
	if typeof(val) ~= "table" then return false end
	local score = tonumber(val.score or val.hits or (val.perfectHits and (val.perfectHits + (val.greatHits or 0) + (val.goodHits or 0))))
	if not score or score < 0 or score ~= score then
		return false
	end
	return true
end

return RemoteContract
