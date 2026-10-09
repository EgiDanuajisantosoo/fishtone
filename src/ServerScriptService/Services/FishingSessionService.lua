--[[
	FishingSessionService (ModuleScript)
	FISH!TUNE — Server-Authoritative Fishing Session & Performance Validation (FISH-014)

	Layanan Sentral Manajemen Sesi Pancing & Validasi Kinerja Rhythm (Anti-Exploit):
	1. Siklus Hidup Sesi Terotentikasi (Creation, Validation, Completion, Cancellation, Timeout).
	2. Validasi Jarak Lemparan Realistis (Anti-Teleport / Out-of-Range Casts).
	3. Validasi Waktu Reaksi & Minimum Wait Duration (Anti-Instant Catch / Speedhack).
	4. Deterministic Server-Side Rarity & Pity Roll dengan Zone/Rod Luck Bonuses.
	5. Server-Authoritative Performance Sanitization & Accuracy Calculation.
	6. Perekaman Statistik Performa Tangkapan & Integrasi Ekonomi.
	7. Pembersihan Memori Otomatis (Periodic Session Sweeper).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))
local LootTableSystem = require(Shared:WaitForChild("Systems"):WaitForChild("LootTableSystem"))
local LuckFormula = require(Shared:WaitForChild("Systems"):WaitForChild("LuckFormula"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)

local FishingSessionService = {}

-- ============ CONFIGURATION ============
local MAX_CAST_DISTANCE = 150 -- Jarak maksimal (studs) antara player dan target air
local MIN_CAST_DISTANCE = 1   -- Jarak minimal (studs)
local BASE_SESSION_TTL  = 90  -- Waktu kedaluwarsa sesi dasar (detik) setelah ikan menyambar

-- ============ ACTIVE SESSIONS STORE ============
local activeSessions = {} -- [sessionId] = sessionData
local playerSessions = {} -- [player.UserId] = sessionId

-- ============ METRICS SANITIZATION & ANTI-EXPLOIT (FISH-014) ============
local function cleanNumber(val, minVal, maxVal, defaultVal)
	local num = tonumber(val)
	if not num or num ~= num or math.abs(num) == math.huge then
		return defaultVal or minVal
	end
	return math.clamp(math.floor(num), minVal, maxVal)
end

function FishingSessionService.SanitizeAndValidateMetrics(rawMetrics, session, now)
	if typeof(rawMetrics) ~= "table" then
		return nil, "Format payload metrik performa tidak valid (bukan table)"
	end

	local tierData = FishingRaritySystem.GetTierData(session.rarity)
	local expectedTargetNotes = tierData.targetNotes or 30

	-- 1. Anti-Speedhack & Duration Validation
	local waitDuration = session.waitDuration or 1.5
	local minigameElapsed = math.max(0.1, now - (session.startTime + waitDuration))

	-- Minigame membutuhkan waktu fisik minimal untuk menyelesaikan not lagu
	local minPhysicalDuration = 0.4
	if minigameElapsed < minPhysicalDuration then
		return nil, string.format("Durasi minigame terlalu cepat (%.2fs), terdeteksi instant catch exploit", minigameElapsed)
	end

	-- 2. Bersihkan dan batasi seluruh parameter numerik (dukung format flat maupun breakdown)
	local breakdown = (typeof(rawMetrics.breakdown) == "table") and rawMetrics.breakdown or {}
	local rawPerfect = rawMetrics.perfectHits or breakdown.perfect
	local rawGreat = rawMetrics.greatHits or breakdown.great
	local rawGood = rawMetrics.goodHits or breakdown.good
	local rawMistakes = rawMetrics.mistakes or breakdown.miss

	local won = rawMetrics.won == true or (rawMetrics.won ~= false and (tonumber(rawMetrics.score) or 0) > 0)
	local perfectHits = cleanNumber(rawPerfect, 0, expectedTargetNotes * 3, 0)
	local greatHits = cleanNumber(rawGreat, 0, expectedTargetNotes * 3, 0)
	local goodHits = cleanNumber(rawGood, 0, expectedTargetNotes * 3, 0)
	local mistakes = cleanNumber(rawMistakes, 0, 999, 0)

	local totalHits = perfectHits + greatHits + goodHits
	if totalHits == 0 and (rawMetrics.score or breakdown.totalHits or rawMetrics.hits) then
		totalHits = cleanNumber(rawMetrics.score or breakdown.totalHits or rawMetrics.hits, 0, expectedTargetNotes * 3, 0)
		perfectHits = math.floor(totalHits * 0.6)
		greatHits = math.floor(totalHits * 0.3)
		goodHits = totalHits - perfectHits - greatHits
	end

	local maxCombo = cleanNumber(rawMetrics.maxCombo or breakdown.maxCombo, 0, math.max(1, totalHits), 0)

	-- 3. Invariant Validasi: Tidak boleh menang dengan 0 total hit
	if won and totalHits <= 0 then
		return nil, "Status tangkapan menang tidak valid dengan 0 hit tercatat"
	end

	local sanitized = {
		won = won,
		score = totalHits,
		hits = totalHits,
		perfectHits = perfectHits,
		greatHits = greatHits,
		goodHits = goodHits,
		mistakes = mistakes,
		maxCombo = maxCombo,
		targetNotes = expectedTargetNotes,
		duration = math.max(0.5, tonumber(rawMetrics.duration or breakdown.duration) or minigameElapsed),
	}

	return sanitized, nil
end

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

	-- 4. Konsumsi Umpan Pancing (Jika Terpasang) & Hitung Multi-Source Luck
	local pData = PlayerDataService.Get(player)
	local zone = ZoneConfig.GetZoneAtPosition(waterPos)
	local consumedBait = EconomyService.ConsumeEquippedBait(player)
	local baitLuck = consumedBait and (consumedBait.luckBonus or 0) or 0

	local luckAudit = LuckFormula.CalculateBreakdown({
		level = pData.level or 1,
		rod = rodLuck or 5,
		castQuality = castQuality,
		performance = pData.prevPerformanceLuckBonus or 0,
		zone = zone and zone.luckBonus or 0,
		buffs = baitLuck,
	})

	local effectiveLuck = luckAudit.effectiveLuck
	local rolledRarity, wasPity = FishingRaritySystem.EvaluateWithPity(effectiveLuck, pData.level or 1, pData.pity or {})
	local rolledCategory = LootTableSystem.RollCategory(effectiveLuck, zone and zone.id)

	-- 5. Hitung Durasi Menunggu Ikan Menyambar
	local waitDuration = math.random(18, 28) / 10
	if castQuality == "PERFECT" then
		waitDuration = math.random(10, 15) / 10
	elseif castQuality == "GREAT" then
		waitDuration = math.random(14, 20) / 10
	end

	-- 6. Hitung TTL Sesi Dinamis Berdasarkan Target Notes Rarity
	local tierData = FishingRaritySystem.GetTierData(rolledRarity)
	local targetNotes = tierData.targetNotes or 30
	-- Beri waktu leluasa: minimal 120 detik, atau (targetNotes * 1.5 detik) + 45 detik
	local sessionTTL = math.max(BASE_SESSION_TTL, math.ceil(targetNotes * 1.5) + 45)

	-- 7. Bangun Session ID Unik & Bind Instrument Authoritative
	local sessionId = string.format("%d_%d_%d", player.UserId, os.time(), math.random(1000, 9999))
	local now = os.clock()

	local equippedRod = (pData and pData.equippedRod) or "StarterRod"
	local instrumentType = (pData and pData.equippedInstrument) or InstrumentDefinitions.GetInstrumentTypeForRod(equippedRod)
	local rodMapping = InstrumentDefinitions.GetRodMapping(equippedRod)

	local sessionData = {
		sessionId = sessionId,
		player = player,
		userId = player.UserId,
		rodId = equippedRod,
		instrumentType = instrumentType,
		instrumentVariant = rodMapping.instrumentVariant or "DEFAULT",
		waterPos = waterPos,
		castQuality = castQuality,
		castPower = castPower,
		startTime = now,
		waitDuration = waitDuration,
		expireAt = now + waitDuration + sessionTTL,
		rarity = rolledRarity,
		wasPity = wasPity,
		zoneId = zone and zone.id or "MELODY_BAY",
		lootCategory = rolledCategory,
		effectiveLuck = effectiveLuck,
		rawLuck = luckAudit.rawLuck,
		luckMultiplier = luckAudit.multiplier,
		luckTitle = luckAudit.title,
		luckAudit = luckAudit,
		consumedBait = consumedBait,
		status = "Active",
	}

	activeSessions[sessionId] = sessionData
	playerSessions[player.UserId] = sessionId

	return sessionData
end

-- ============ SESSION VALIDATION & COMPLETION (FISH-014 / FISH-018) ============
function FishingSessionService.ValidateAndComplete(player, sessionId, rawMetrics)
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

	-- 1. Validasi Waktu Kadaluarsa
	if now > session.expireAt then
		activeSessions[sessionId] = nil
		playerSessions[player.UserId] = nil
		return nil, "Sesi memancing telah kadaluarsa"
	end

	-- 2. Anti-Speedhack: Waktu tunggu sambaran harus terpenuhi
	if now - session.startTime < (session.waitDuration * 0.8) then
		activeSessions[sessionId] = nil
		playerSessions[player.UserId] = nil
		return nil, "Sambaran terlalu cepat (Waktu tunggu belum terpenuhi)"
	end

	-- 3. Validasi & Sanitasi Metrik Rhythm secara Server-Authoritative
	local sanitizedMetrics, valErr = FishingSessionService.SanitizeAndValidateMetrics(rawMetrics, session, now)
	if not sanitizedMetrics then
		activeSessions[sessionId] = nil
		playerSessions[player.UserId] = nil
		warn(string.format("[FishingSessionService] Exploit terdeteksi untuk player %s: %s", player.Name, tostring(valErr)))
		return nil, valErr or "Metrik performa tidak valid"
	end

	-- 4. Tandai Selesai & Bersihkan Slot Sesi
	session.status = "Completed"
	activeSessions[sessionId] = nil
	playerSessions[player.UserId] = nil

	-- 5. Evaluasi Performa Server-Authoritative
	local pData = PlayerDataService.Get(player)
	local performance = PerformanceCalculator.Calculate(sanitizedMetrics)

	-- 6. Generate Data Loot Berdasarkan Kategori, Rarity, Skor Performa & Effective Luck (FISH-018 / FISH-019)
	local lootData = LootTableSystem.GenerateLoot(
		session.lootCategory or "FISH",
		session.rarity,
		pData.level or 1,
		performance.performanceScore,
		session.zoneId,
		session.effectiveLuck or 0
	)

	-- 7. Terapkan Pengganda Performa (XP & Koin Multipliers)
	local baseExp = lootData.exp or 10
	local baseCoins = lootData.coins or 15
	local finalExp = math.max(1, math.floor(baseExp * (performance.xpMultiplier or 1.0)))
	local finalCoins = math.max(1, math.floor(baseCoins * (performance.coinMultiplier or 1.0)))

	lootData.exp = finalExp
	lootData.coins = finalCoins
	lootData.performance = performance
	lootData.grade = performance.grade
	lootData.accuracy = performance.accuracy
	lootData.performanceLuckBonus = performance.performanceLuckBonus
	lootData.effectiveLuck = session.effectiveLuck or 0
	lootData.luckTitle = session.luckTitle or "🌱 Netral"

	-- 8. Mutasi Profil Pemain (Pity, EXP, Jurnal, Statistik & Streak Luck)
	pData.pity = PlayerDataService.UpdatePity(player, session.rarity)
	pData.prevPerformanceLuckBonus = performance.performanceLuckBonus or 0
	PlayerDataService.AddFish(player, 1)
	PlayerDataService.AddExp(player, finalExp)
	PlayerDataService.RecordJournal(player, lootData, lootData.weight)

	if pData.stats then
		pData.stats.totalCatches = (pData.stats.totalCatches or 0) + 1
		if (performance.rawScore or 0) > (pData.stats.highestScore or 0) then
			pData.stats.highestScore = performance.rawScore
		end
		local combo = (performance.breakdown and performance.breakdown.maxCombo) or performance.maxCombo or 0
		if combo > (pData.stats.highestCombo or 0) then
			pData.stats.highestCombo = combo
		end
		if performance.isAllPerfect then
			pData.stats.allPerfectCount = (pData.stats.allPerfectCount or 0) + 1
		end
		if performance.isFullCombo then
			pData.stats.fullComboCount = (pData.stats.fullComboCount or 0) + 1
		end
	end

	local rewardInfo = {
		coins = finalCoins,
		exp = finalExp,
		baseCoins = baseCoins,
		baseExp = baseExp,
		grade = performance.grade,
		gradeTitle = performance.gradeTitle,
		accuracy = performance.accuracy,
		xpMultiplier = performance.xpMultiplier,
		coinMultiplier = performance.coinMultiplier,
		performanceLuckBonus = performance.performanceLuckBonus,
		effectiveLuck = session.effectiveLuck or 0,
		rawLuck = session.rawLuck or 0,
		luckTitle = session.luckTitle or "🌱 Netral",
		isMutated = lootData.isMutated == true,
		mutationType = lootData.mutationType or "NONE",
		mutationName = lootData.mutationName or "",
		mutationPrefix = lootData.mutationPrefix or "",
		isFullCombo = performance.isFullCombo,
		isAllPerfect = performance.isAllPerfect,
		wasPity = session.wasPity,
		breakdown = performance.breakdown,
	}

	return lootData, rewardInfo, pData
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
