--[[
	FishingSessionService (ModuleScript)
	FISH!TUNE — Server-Authoritative Fishing Session Service (FISH-009)

	Layanan Sentral Manajemen Sesi Pancing & Validasi Keamanan (Anti-Exploit):
	1. Siklus Hidup Sesi Terotentikasi (Creation, Validation, Completion, Cancellation, Timeout).
	2. Validasi Jarak Lemparan Realistis (Anti-Teleport / Out-of-Range Casts).
	3. Validasi Waktu Reaksi & Minimum Wait Duration (Anti-Instant Catch / Speedhack).
	4. Deterministic Server-Side Rarity & Pity Roll dengan Zone/Rod Luck Bonuses.
	5. Pembersihan Memori Otomatis (Periodic Session Sweeper).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)

local FishingSessionService = {}

-- ============ CONFIGURATION ============
local MAX_CAST_DISTANCE = 65 -- Jarak maksimal (studs) antara player dan target air
local MIN_CAST_DISTANCE = 5  -- Jarak minimal (studs)
local SESSION_TTL = 45       -- Waktu kedaluwarsa sesi (detik) setelah ikan menyambar

-- ============ ACTIVE SESSIONS STORE ============
local activeSessions = {} -- [sessionId] = sessionData
local playerSessions = {} -- [player.UserId] = sessionId

-- ============ SESSION CREATION ============
function FishingSessionService.CreateSession(player, waterPos, castQuality, castPower, rodLuck)
	if not player or not player:IsA("Player") then
		return nil, "Player tidak valid"
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil, "Karakter player belum dimuat"
	end

	-- 1. Validasi Jarak Lemparan (Anti-Exploit / Teleport)
	local distance = (hrp.Position - waterPos).Magnitude
	if distance > MAX_CAST_DISTANCE or distance < MIN_CAST_DISTANCE then
		return nil, string.format("Jarak lemparan tidak valid (%.1f studs)", distance)
	end

	-- 2. Format & Standarisasi Parameter
	castQuality = tostring(castQuality or "GOOD"):upper()
	if castQuality ~= "PERFECT" and castQuality ~= "GREAT" and castQuality ~= "GOOD" then
		castQuality = "GOOD"
	end
	castPower = math.clamp(tonumber(castPower) or 0.5, 0, 1)

	-- 3. Batalkan Sesi Lama Jika Masih Berjalan
	local oldSessionId = playerSessions[player.UserId]
	if oldSessionId and activeSessions[oldSessionId] then
		activeSessions[oldSessionId] = nil
	end

	-- 4. Hitung Effective Luck & Roll Rarity di Server
	local pData = PlayerDataService.Get(player)
	local baseLuck = math.clamp(math.floor((pData.level or 1) / 5), 0, 10)
	local castLuck = (castQuality == "PERFECT" and 35) or (castQuality == "GREAT" and 15) or 0
	
	local zone = ZoneConfig.GetZoneAtPosition(waterPos)
	local zoneLuck = zone and zone.luckBonus or 0

	local totalLuck = baseLuck + (rodLuck or 5) + zoneLuck
	local effectiveLuck = FishingRaritySystem.CalculateEffectiveLuck(totalLuck, castLuck, 0, 0)
	local rolledRarity, wasPity = FishingRaritySystem.EvaluateWithPity(effectiveLuck, pData.level or 1, pData.pity or {})

	-- 5. Hitung Durasi Menunggu Ikan Menyambar
	local waitDuration = math.random(28, 42) / 10
	if castQuality == "PERFECT" then
		waitDuration = math.random(12, 20) / 10
	elseif castQuality == "GREAT" then
		waitDuration = math.random(18, 28) / 10
	end

	-- 6. Bangun Session ID Unik
	local sessionId = string.format("%d_%d_%d", player.UserId, os.time(), math.random(1000, 9999))
	local now = os.clock()

	local sessionData = {
		sessionId = sessionId,
		player = player,
		userId = player.UserId,
		waterPos = waterPos,
		castQuality = castQuality,
		castPower = castPower,
		startTime = now,
		waitDuration = waitDuration,
		expireAt = now + waitDuration + SESSION_TTL,
		rarity = rolledRarity,
		wasPity = wasPity,
		zoneId = zone and zone.id or "MELODY_BAY",
		status = "Active",
	}

	activeSessions[sessionId] = sessionData
	playerSessions[player.UserId] = sessionId

	return sessionData
end

-- ============ SESSION VALIDATION & COMPLETION ============
function FishingSessionService.ValidateAndComplete(player, sessionId, metrics)
	sessionId = tostring(sessionId or "")
	local session = activeSessions[sessionId]

	if not session then
		return nil, "Sesi memancing tidak ditemukan"
	end
	if session.userId ~= player.UserId then
		return nil, "Sesi tidak cocok dengan pemilik"
	end
	if session.status ~= "Active" then
		return nil, "Sesi sudah tidak aktif"
	end

	local now = os.clock()

	-- Validasi Waktu Kadaluarsa
	if now > session.expireAt then
		activeSessions[sessionId] = nil
		playerSessions[player.UserId] = nil
		return nil, "Sesi memancing telah kadaluarsa"
	end

	-- Anti-Speedhack: Tidak boleh submit sebelum waktu menunggu sambaran tercapai
	if now - session.startTime < (session.waitDuration * 0.8) then
		activeSessions[sessionId] = nil
		playerSessions[player.UserId] = nil
		return nil, "Sambaran terlalu cepat (Waktu tunggu belum terpenuhi)"
	end

	-- Tandai Selesai & Bersihkan Slot Sesi
	session.status = "Completed"
	activeSessions[sessionId] = nil
	playerSessions[player.UserId] = nil

	-- Ambil Profil Pemain
	local pData = PlayerDataService.Get(player)
	metrics = metrics or {}
	local accuracy = tonumber(metrics.accuracy) or 80
	local performanceScore = math.clamp(accuracy, 0, 100)

	-- Generate Data Ikan Berdasarkan Rarity yang Telah Di-roll
	local fishData = FishingRaritySystem.GenerateFish(
		session.rarity,
		pData.level or 1,
		performanceScore
	)

	-- Update Pity State, EXP, Tangkapan, dan Jurnal
	pData.pity = PlayerDataService.UpdatePity(player, session.rarity)
	PlayerDataService.AddFish(player, 1)
	PlayerDataService.AddExp(player, fishData.exp)
	PlayerDataService.RecordJournal(player, fishData.name, fishData.weight)

	local rewardInfo = {
		coins = fishData.coins,
		exp = fishData.exp,
		wasPity = session.wasPity,
	}

	return fishData, rewardInfo, pData
end

-- ============ CANCEL SESSION ============
function FishingSessionService.CancelSession(player, sessionId)
	sessionId = tostring(sessionId or "")
	local session = activeSessions[sessionId]
	if session and session.userId == player.UserId then
		activeSessions[sessionId] = nil
	end
	if playerSessions[player.UserId] == sessionId then
		playerSessions[player.UserId] = nil
	end
end

-- ============ GETTERS ============
function FishingSessionService.GetSession(sessionId)
	return activeSessions[sessionId]
end

function FishingSessionService.GetPlayerSession(player)
	local sId = playerSessions[player.UserId]
	return sId and activeSessions[sId] or nil
end

function FishingSessionService.CleanupPlayer(player)
	local sId = playerSessions[player.UserId]
	if sId then
		activeSessions[sId] = nil
	end
	playerSessions[player.UserId] = nil
end

-- ============ INIT & SWEEPER ============
local initialized = false
function FishingSessionService.Init()
	if initialized then return end
	initialized = true

	Players.PlayerRemoving:Connect(function(player)
		FishingSessionService.CleanupPlayer(player)
	end)

	-- Background Sweeper Loop (Membersihkan sesi kadaluarsa setiap 30 detik)
	task.spawn(function()
		while true do
			task.wait(30)
			local now = os.clock()
			for sId, sess in pairs(activeSessions) do
				if now > sess.expireAt then
					activeSessions[sId] = nil
					if playerSessions[sess.userId] == sId then
						playerSessions[sess.userId] = nil
					end
				end
			end
		end
	end)

	print("[FishingSessionService] Inisialisasi FishingSessionService selesai.")
end

FishingSessionService.Init()

return FishingSessionService
