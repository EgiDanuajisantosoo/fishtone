--[[
    RhythmService (ModuleScript)
    FISH!TUNE — Server-Authoritative Rhythm Session & Chart Validation Service (FISH-044)

    Layanan Sentral Sisi Server Sesuai Target Arsitektur (Rule 9):
    1. Rhythm Session Binding: Mengikat chart lagu otoritatif dari SongChartCatalog ke setiap sesi memancing.
    2. Authoritative Target & Progress Derivation:
       - Menghitung targetNotes berbasis Tier & Modifiers.
       - Menghitung starting progress rasio berdasarkan Kualitas Lemparan (Rule 7: PERFECT 35%, GREAT 20%, GOOD 10%).
       - Menghitung batas minimum nada yang harus dicapai untuk menang secara matematis.
    3. Anti-Exploit Chart Session Validation (Rule 5 & Rule 6):
       - Mencegah Chart Spoofing (mencoba mengirimkan ID lagu yang lebih mudah dari yang ditentukan server).
       - Mencegah Impossible Win Claim (mengklaim menang dengan nada yang tidak mencukupi untuk mengisi meteran).
       - Mencegah Tempo Speedhack / Inhuman Hit Rate (frekuensi not melebihi batas fisik lagu & manusia).
       - Menolak Submission Duplikat / Replay Attack pada sesi yang sama.
    4. Evaluasi & Derivasi Independen Performa Server (Skor, Akurasi, Grade, Combo, & Luck Bonus).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local SongChartCatalog = require(Shared:WaitForChild("Definitions"):WaitForChild("SongChartCatalog"))
local InstrumentConfig = require(Shared:WaitForChild("Config"):WaitForChild("InstrumentConfig"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))

local RhythmService = {}

-- ============ 1. SESSION CHART BINDING ============

--[[
    Mengikat chart lagu otoritatif ke data sesi memancing server.
    Menghitung seluruh ekspektasi fisik dan batas matematis sebelum tantangan dimulai.
    @param session table Session data dari FishingSessionService
    @return table chartValidation
]]
function RhythmService.BindSessionChart(session)
	if not session or typeof(session) ~= "table" then
		return nil
	end

	local instrumentType = tostring(session.instrumentType or InstrumentDefinitions.Types.PIANO):upper()
	local zoneId = tostring(session.zoneId or "MELODY_BAY"):upper()
	local rarity = tostring(session.rarity or "COMMON"):upper()
	local castQuality = tostring(session.castQuality or "GOOD"):upper()

	-- 1. Ambil atau pilih lagu dari katalog otoritatif
	local song = nil
	if session.songId then
		song = SongChartCatalog.GetSong(session.songId)
	end
	if not song then
		local selected = SongChartCatalog.SelectSongForSession({
			instrumentType = instrumentType,
			zoneId = zoneId,
			rarity = rarity,
		})
		song = selected.song
	end

	-- Fallback darurat jika lagu tidak ditemukan
	if not song then
		song = SongChartCatalog.SONGS.CANON_IN_D
	end

	local chart = (song.charts and song.charts[instrumentType]) or song.charts[InstrumentDefinitions.Types.PIANO]
	local chartBpm = (chart and chart.bpm) or song.bpm or 120

	-- 2. Turunkan target notes dan modifier lingkungan
	local tierData = FishingRaritySystem.GetTierData(rarity) or {}
	local islandMod = InstrumentConfig.GetIslandModifier(zoneId) or {}
	local castBonus = InstrumentConfig.CAST_BONUSES[castQuality] or InstrumentConfig.CAST_BONUSES.GOOD

	local baseTarget = tierData.targetNotes or 30
	local targetNotes = baseTarget + (islandMod.targetNotesBonus or 0)

	-- 3. Hitung starting progress dari cast quality (Rule 7: PERFECT = 35%, GREAT = 20%, GOOD = 10%)
	local startRatio = castBonus.startRatio or 0.10
	local initialNotes = math.max(1, math.floor(startRatio * targetNotes))
	local notesNeededToWin = math.max(1, targetNotes - initialNotes)

	-- 4. Hitung batas penalti kesalahan
	local penaltyMult = castBonus.penaltyMult or 1.0
	local basePenaltyNotes = math.max(1, math.floor((tierData.basePenaltyNotes or 3) * penaltyMult * (islandMod.penaltyMultiplier or 1.0)))

	-- 5. Hitung batas durasi tantangan fisik minimal berdasarkan BPM lagu
	-- 1 beat = (60 / BPM) detik. Aliran nada tercepat wajar adalah subdivisi 1/8 atau 1/16
	local secondsPerBeat = 60.0 / math.max(60, chartBpm)
	local minSecondsPerNote = math.max(0.10, secondsPerBeat * 0.25) -- Subdivisi 16th note
	local minPhysicalChallengeTime = math.max(0.75, (notesNeededToWin * minSecondsPerNote) * 0.45)

	local chartValidation = {
		songId = song.id,
		songTitle = song.title,
		instrumentType = instrumentType,
		bpm = chartBpm,
		difficulty = song.difficulty or 2,
		starRating = song.starRating or "★★☆☆☆",
		targetNotes = targetNotes,
		startRatio = startRatio,
		initialNotes = initialNotes,
		notesNeededToWin = notesNeededToWin,
		basePenaltyNotes = basePenaltyNotes,
		minChallengeTime = minPhysicalChallengeTime,
		boundAt = os.clock(),
	}

	session.songId = song.id
	session.songTitle = song.title
	session.songBpm = chartBpm
	session.songDifficulty = song.difficulty or 2
	session.chartValidation = chartValidation

	return chartValidation
end

-- ============ 2. AUTHORITATIVE PERFORMANCE & SUBMISSION VALIDATION ============

--[[
    Memvalidasi hasil tangkapan ritme yang dikirimkan client secara menyeluruh.
    Mengevaluasi klaim kemenangan, integritas nada, waktu tantangan, dan menghitung performa otoritatif.
    @param session table
    @param rawMetrics table
    @param now number?
    @return table? validatedMetrics, table? performanceResult, string? errorMessage
]]
function RhythmService.ValidateSubmission(session, rawMetrics, now)
	now = now or os.clock()

	if not session or typeof(session) ~= "table" then
		return nil, nil, "Sesi memancing tidak valid"
	end

	-- Pastikan sesi aktif (mencegah double submission / replay attack)
	if session.status ~= "Active" then
		return nil, nil, "Sesi memancing sudah selesai atau tidak aktif"
	end

	-- Pastikan chart validation sudah terikat
	if not session.chartValidation then
		RhythmService.BindSessionChart(session)
	end
	local cv = session.chartValidation

	if typeof(rawMetrics) ~= "table" then
		rawMetrics = {}
	end

	-- 1. Anti-Spoofing Check: Verifikasi ID Lagu jika dikirim client
	if rawMetrics.songId and tostring(rawMetrics.songId) ~= "" and tostring(rawMetrics.songId):upper() ~= tostring(cv.songId):upper() then
		return nil, nil, string.format("Chart spoofing terdeteksi: lagu sesi adalah '%s', tetapi client mengirim '%s'", cv.songId, tostring(rawMetrics.songId))
	end

	-- 2. Validasi Durasi Tantangan Fisik Minigame
	local waitDuration = session.waitDuration or 1.5
	local challengeElapsed = now - ((session.startTime or now) + waitDuration)
	if challengeElapsed < cv.minChallengeTime then
		return nil, nil, string.format("Deteksi speedhack: durasi minigame terlalu singkat (berjalan: %.2fs, minimal: %.2fs)", challengeElapsed, cv.minChallengeTime)
	end

	-- 3. Ekstraksi & Sanitasi Notasi Mentah
	local breakdown = (typeof(rawMetrics.breakdown) == "table") and rawMetrics.breakdown or {}
	local rawPerfect = tonumber(rawMetrics.perfectHits or breakdown.perfect) or 0
	local rawGreat   = tonumber(rawMetrics.greatHits or breakdown.great) or 0
	local rawGood    = tonumber(rawMetrics.goodHits or breakdown.good) or 0
	local rawMistakes = tonumber(rawMetrics.mistakes or breakdown.miss) or 0

	local maxAllowedNotes = math.ceil(cv.targetNotes * 3.0)
	local perfectHits = math.clamp(math.floor(rawPerfect), 0, maxAllowedNotes)
	local greatHits   = math.clamp(math.floor(rawGreat), 0, maxAllowedNotes)
	local goodHits    = math.clamp(math.floor(rawGood), 0, maxAllowedNotes)
	local mistakes    = math.clamp(math.floor(rawMistakes), 0, 999)

	local totalHits = perfectHits + greatHits + goodHits

	-- Fallback jika format flat dikirim
	if totalHits == 0 then
		local altHits = tonumber(rawMetrics.hits or rawMetrics.score or breakdown.totalHits) or 0
		if altHits > 0 then
			totalHits = math.clamp(math.floor(altHits), 1, maxAllowedNotes)
			perfectHits = math.floor(totalHits * 0.6)
			greatHits = math.floor(totalHits * 0.3)
			goodHits = math.max(0, totalHits - perfectHits - greatHits)
		end
	end

	-- 4. Verifikasi Status Kemenangan (Win Feasibility Check)
	local clientWon = (rawMetrics.won == true) or (rawMetrics.won ~= false and totalHits >= cv.notesNeededToWin)

	-- Tolak jika mengklaim menang tanpa not (0 hits)
	if clientWon and totalHits <= 0 then
		return nil, nil, "Klaim kemenangan ditolak: jumlah nada yang ditekan adalah 0"
	end

	-- Cek apakah net nada yang didapat mencukupi progres untuk menang
	-- Net Nada = totalHits - (mistakes * basePenalty)
	local netNotesGained = totalHits - math.floor(mistakes * (cv.basePenaltyNotes * 0.5))
	-- Berikan toleransi margin 25% untuk rounding frame UI client
	local minReqNotesWithTolerance = math.max(1, math.floor(cv.notesNeededToWin * 0.75))

	if clientWon and netNotesGained < minReqNotesWithTolerance then
		return nil, nil, string.format("Klaim kemenangan tidak valid: nada yang dicapai (%d net) belum mencukupi target menang (%d nada diperlukan)", netNotesGained, cv.notesNeededToWin)
	end

	-- Jika client memang kalah
	if not clientWon then
		return nil, nil, "Tangkapan tidak berhasil (skor atau irama belum mencukupi)"
	end

	-- 5. Anti-Macro / Inhuman Click Rate Check
	local safeDuration = math.max(0.4, challengeElapsed)
	local hitRate = totalHits / safeDuration
	if hitRate > 28.0 then
		return nil, nil, string.format("Deteksi auto-clicker/macro: frekuensi input %.1f nada/detik melampaui batas wajar manusia", hitRate)
	end

	-- 6. Sanitasi Combo
	local maxCombo = math.clamp(tonumber(rawMetrics.maxCombo or breakdown.maxCombo) or totalHits, 0, totalHits)

	-- 7. Bentuk Validated Metrics
	local validatedMetrics = {
		won = true,
		songId = cv.songId,
		songTitle = cv.songTitle,
		bpm = cv.bpm,
		difficulty = cv.difficulty,
		score = totalHits,
		hits = totalHits,
		perfectHits = perfectHits,
		greatHits = greatHits,
		goodHits = goodHits,
		mistakes = mistakes,
		maxCombo = maxCombo,
		targetNotes = cv.targetNotes,
		startRatio = cv.startRatio,
		duration = safeDuration,
	}

	-- 8. Derivasi Performa Otoritatif Server (Akurasi, Grade, EXP/Koin/Luck Multipliers)
	local performance = PerformanceCalculator.Calculate(validatedMetrics)

	return validatedMetrics, performance, nil
end

return RhythmService
