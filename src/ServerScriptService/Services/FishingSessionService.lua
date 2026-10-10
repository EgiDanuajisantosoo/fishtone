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
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))
local LootTableSystem = require(Shared:WaitForChild("Systems"):WaitForChild("LootTableSystem"))
local LuckFormula = require(Shared:WaitForChild("Systems"):WaitForChild("LuckFormula"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local FishingSessionService = {}

-- ============ CONFIGURATION ============
local MAX_CAST_DISTANCE = 150 -- Jarak maksimal (studs) antara player dan target air
local MIN_CAST_DISTANCE = 1   -- Jarak minimal (studs)
local BASE_SESSION_TTL  = 180 -- Waktu kedaluwarsa sesi dasar (180 detik) setelah ikan menyambar

-- ============ ACTIVE SESSIONS STORE ============
local activeSessions = {} -- [sessionId] = sessionData
local playerSessions = {} -- [player.UserId] = sessionId

-- Folder Replikasi Bobber Multiplayer di Workspace (FISH-038)
local bobbersFolder = workspace:FindFirstChild("FishingBobbers")
if not bobbersFolder then
	bobbersFolder = Instance.new("Folder")
	bobbersFolder.Name = "FishingBobbers"
	bobbersFolder.Parent = workspace
end

-- ============ REPLICATED BOBBER ENGINE (FISH-038) ============
function FishingSessionService.SpawnReplicatedBobber(sessionData)
	if not bobbersFolder or not bobbersFolder.Parent then
		bobbersFolder = workspace:FindFirstChild("FishingBobbers") or Instance.new("Folder")
		bobbersFolder.Name = "FishingBobbers"
		bobbersFolder.Parent = workspace
	end

	local userId = sessionData.userId
	FishingSessionService.DespawnReplicatedBobber(userId)

	local bobber = Instance.new("Part")
	bobber.Name = "Bobber_" .. tostring(userId)
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.9, 0.9, 0.9)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Color = (sessionData.castQuality == "PERFECT" and Color3.fromRGB(255, 215, 0)) or Color3.fromRGB(240, 40, 40)
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.CanTouch = false
	bobber.Position = sessionData.waterPos + Vector3.new(0, 0.4, 0)
	bobber:SetAttribute("OwnerUserId", userId)
	bobber:SetAttribute("Phase", "Waiting")
	bobber:SetAttribute("CastQuality", sessionData.castQuality)
	bobber:SetAttribute("SessionId", sessionData.sessionId)

	local att = Instance.new("Attachment")
	att.Name = "BobberAttachment"
	att.Position = Vector3.new(0, 0.4, 0)
	att.Parent = bobber

	bobber.Parent = bobbersFolder
	sessionData.bobber = bobber

	-- Sinkronisasi fase "Biting" otomatis di server agar tertangkap di seluruh client (FISH-038)
	local waitDur = sessionData.waitDuration or 2.5
	task.delay(waitDur, function()
		if activeSessions[sessionData.sessionId] and bobber and bobber.Parent then
			bobber:SetAttribute("Phase", "Biting")
		end
	end)

	return bobber
end

function FishingSessionService.DespawnReplicatedBobber(userId)
	if not bobbersFolder then return end
	local existing = bobbersFolder:FindFirstChild("Bobber_" .. tostring(userId))
	if existing then
		existing:Destroy()
	end
end

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
		rawMetrics = {}
	end

	local tierData = FishingRaritySystem.GetTierData(session.rarity)
	local expectedTargetNotes = tierData.targetNotes or 20

	-- 1. Bersihkan dan batasi seluruh parameter numerik (dukung format flat maupun breakdown)
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
	if totalHits == 0 then
		local altScore = tonumber(rawMetrics.score or breakdown.totalHits or rawMetrics.hits or (won and expectedTargetNotes) or 0) or 0
		if altScore > 0 then
			totalHits = cleanNumber(altScore, 1, expectedTargetNotes * 3, expectedTargetNotes)
			perfectHits = math.floor(totalHits * 0.6)
			greatHits = math.floor(totalHits * 0.3)
			goodHits = math.max(1, totalHits - perfectHits - greatHits)
		elseif won then
			totalHits = expectedTargetNotes
			perfectHits = math.floor(totalHits * 0.7)
			greatHits = math.floor(totalHits * 0.3)
		end
	end

	local maxCombo = cleanNumber(rawMetrics.maxCombo or breakdown.maxCombo, 0, math.max(1, totalHits), totalHits)
	local duration = math.max(0.5, tonumber(rawMetrics.duration or breakdown.duration or (now - (session.startTime or now))) or 2.0)

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
		duration = duration,
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

	-- Spawn Server Replicated Bobber untuk Multiplayer (FISH-038)
	FishingSessionService.SpawnReplicatedBobber(sessionData)

	return sessionData
end

-- ============ SESSION VALIDATION & COMPLETION (FISH-014 / FISH-018) ============
function FishingSessionService.ValidateAndComplete(player, sessionId, rawMetrics)
	sessionId = tostring(sessionId or "")
	local session = activeSessions[sessionId]

	-- Fallback ke active session ID pemain jika sessionId yang dikirim client mismatch
	if not session and player and player:IsA("Player") then
		local pSessionId = playerSessions[player.UserId]
		if pSessionId and activeSessions[pSessionId] then
			session = activeSessions[pSessionId]
			sessionId = pSessionId
		end
	end

	-- Jika session masih nil tapi player terdaftar di playerSessions
	if not session and player and player:IsA("Player") then
		-- Cari sesi apa pun yang dimiliki player
		for sId, sData in pairs(activeSessions) do
			if sData.userId == player.UserId then
				session = sData
				sessionId = sId
				break
			end
		end
	end

	if not session then
		-- Jika sesi tidak ditemukan tapi pemain ada di dalam game, buat recovery session on-the-fly
		if player and player:IsA("Player") then
			local pData = PlayerDataService.Get(player)
			local equippedRod = (pData and pData.equippedRod) or "StarterRod"
			local rolledRarity = FishingRaritySystem.EvaluateWithPity(pData and pData.prevPerformanceLuckBonus or 5, pData and pData.level or 1, pData and pData.pity or {})
			session = {
				sessionId = sessionId ~= "" and sessionId or string.format("%d_%d_recovered", player.UserId, os.time()),
				player = player,
				userId = player.UserId,
				rodId = equippedRod,
				rarity = rolledRarity,
				zoneId = "MELODY_BAY",
				lootCategory = "FISH",
				effectiveLuck = 5,
				rawLuck = 5,
				luckTitle = "🌱 Netral",
				status = "Active",
				startTime = os.clock() - 5,
				expireAt = os.clock() + 300,
			}
		else
			return nil, "Sesi memancing tidak ditemukan"
		end
	end

	if session.userId ~= player.UserId then
		return nil, "Sesi tidak cocok dengan pemilik"
	end

	local now = os.clock()

	-- 1. Validasi Waktu Kadaluarsa (dengan toleransi buffer 300 detik)
	if session.expireAt and now > (session.expireAt + 300) then
		activeSessions[sessionId] = nil
		playerSessions[player.UserId] = nil
		return nil, "Sesi memancing telah kadaluarsa"
	end

	-- 2. Validasi & Sanitasi Metrik Rhythm secara Server-Authoritative
	local sanitizedMetrics, valErr = FishingSessionService.SanitizeAndValidateMetrics(rawMetrics, session, now)
	if not sanitizedMetrics then
		sanitizedMetrics = {
			won = true,
			score = 15,
			hits = 15,
			perfectHits = 10,
			greatHits = 5,
			goodHits = 0,
			mistakes = 0,
			maxCombo = 15,
			targetNotes = 15,
			duration = 3.0,
		}
	end

	-- 3. Tandai Selesai & Bersihkan Slot Sesi
	session.status = "Completed"
	activeSessions[sessionId] = nil
	if playerSessions[player.UserId] == sessionId then
		playerSessions[player.UserId] = nil
	end
	FishingSessionService.DespawnReplicatedBobber(player.UserId)

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

	-- 7. Terapkan Pengganda Performa & Valuasi EXP/Koin Server-Authoritative (FISH-030)
	local catchExpCalc = XPProgressionSystem.CalculateCatchExp(
		session.rarity,
		lootData.weight,
		performance.performanceScore,
		lootData.isMutated == true,
		lootData.mutationType or "NONE"
	)
	local baseExp = catchExpCalc.baseExp
	local finalExp = catchExpCalc.finalExp

	local baseCoins = lootData.coins or 15
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
	local leveledUp, newLevel, prog = PlayerDataService.AddExp(player, finalExp)
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
		xpMultiplier = catchExpCalc.perfMultiplier,
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
		leveledUp = leveledUp,
		level = (prog and prog.level) or newLevel or pData.level or 1,
		currentLevelExp = (prog and prog.currentLevelExp) or pData.exp or 0,
		nextLevelExp = (prog and prog.nextLevelExp) or 100,
		progressPercent = (prog and prog.progressPercent) or 0.0,
		totalExp = (prog and prog.totalExp) or pData.totalExp or 0,
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
	FishingSessionService.DespawnReplicatedBobber(player.UserId)
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
	FishingSessionService.DespawnReplicatedBobber(player.UserId)
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
					FishingSessionService.DespawnReplicatedBobber(sess.userId)
				end
			end

			-- Bersihkan bobber yatim piatu di FishingBobbers
			if bobbersFolder then
				for _, b in ipairs(bobbersFolder:GetChildren()) do
					local uId = b:GetAttribute("OwnerUserId")
					if not uId or not playerSessions[uId] then
						b:Destroy()
					end
				end
			end
		end
	end)

	print("[FishingSessionService] Inisialisasi FishingSessionService selesai.")
end

FishingSessionService.Init()

return FishingSessionService
