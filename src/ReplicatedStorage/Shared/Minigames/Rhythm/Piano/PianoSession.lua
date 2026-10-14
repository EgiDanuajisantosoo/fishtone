--[[
    PianoSession (ModuleScript)
    FISH!TUNE — Chart-Driven Piano Tiles Session Engine (FISH-045)

    Mekanisme Otoritatif Piano Tiles Berbasis Chart:
    1. Sinkronisasi Penuh dengan SongChartCatalog (FISH-043) & RhythmService (FISH-044).
    2. Spawning Not Berbasis BPM dengan Anti-Collision Guard (Tile Tidak Pernah Bertumpuk).
    3. Pergerakan Not Frame-Independent (Matematika Presisi Tanpa Temporal Drift).
    4. Input 100% Selaras dengan UI Studio: Kolom 1 = A, Kolom 2 = W, Kolom 3 = S, Kolom 4 = D.
    5. Playback Audio Real-time dengan Semitone Pitch Asli dari Not Melodi.
    6. Mematuhi Aturan Preservasi UI Studio & Rule 7 (Cast Quality Progress).
]]

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("PianoConfig"))
local InstrumentConfig = require(Shared:WaitForChild("Config"):WaitForChild("InstrumentConfig"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))
local SongChartCatalog = require(Shared:WaitForChild("Definitions"):WaitForChild("SongChartCatalog"))
local PianoUI = require(script.Parent:WaitForChild("PianoUI"))
local KeybindSystem = require(Shared:WaitForChild("Systems"):WaitForChild("KeybindSystem"))

local PianoSession = {}
PianoSession.__index = PianoSession

-- ============ AUDIO HELPERS ============
local function playPianoNote(semitone)
	semitone = semitone or 0
	local sound = Instance.new("Sound")
	sound.SoundId = Config.SOUND_ID
	sound.Volume = Config.VOLUME
	sound.PlaybackSpeed = Config.BASE_PITCH * (2 ^ (semitone / 12))
	sound.Parent = SoundService
	sound:Play()

	task.delay(1.2, function()
		if sound then sound:Destroy() end
	end)
end

local function playMissSound()
	local sound = Instance.new("Sound")
	sound.SoundId = Config.MISS_SOUND_ID
	sound.Volume = 0.8
	sound.PlaybackSpeed = 0.65
	sound.Parent = SoundService
	sound:Play()

	task.delay(1.0, function()
		if sound then sound:Destroy() end
	end)
end

-- ============ INPUT KEY MAPPING (SELARAS 100% DENGAN GUI STUDIO) ============
-- Kolom 1 = A, Kolom 2 = W, Kolom 3 = S, Kolom 4 = D (Sesuai ReceptorPad visual Studio)
local KEY_BIND_MAP = {
	-- Kolom 1 (Kiri Luar) -> Tombol A (sesuai UI Studio), 1, Keypad 1, Panah Kiri
	[Enum.KeyCode.A] = 1,
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.Left] = 1,

	-- Kolom 2 (Kiri Tengah) -> Tombol W (sesuai UI Studio), 2, Keypad 2, Panah Atas
	[Enum.KeyCode.W] = 2,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.Up] = 2,

	-- Kolom 3 (Kanan Tengah) -> Tombol S (sesuai UI Studio), 3, Keypad 3, Panah Bawah
	[Enum.KeyCode.S] = 3,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.Down] = 3,

	-- Kolom 4 (Kanan Luar) -> Tombol D (sesuai UI Studio), 4, Keypad 4, Panah Kanan
	[Enum.KeyCode.D] = 4,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.Right] = 4,
}

-- ============ CONSTRUCTOR ============
function PianoSession.new(options)
	options = options or {}
	local self = setmetatable({}, PianoSession)

	local castKey = tostring(options.castQuality or "GOOD"):upper()
	local tierKey = tostring(options.tier or "COMMON"):upper()
	local islandMod = InstrumentConfig.GetIslandModifier(options.island or options.zoneId)

	self.Tier = FishingRaritySystem.GetTierData(tierKey) or {}
	self.CastBonus = Config.CAST_BONUSES[castKey] or Config.CAST_BONUSES.GOOD

	-- 1. Pemilihan Lagu & Chart Otoritatif via SongChartCatalog (FISH-043 / FISH-044)
	local selectedSong = options.song or (options.songId and SongChartCatalog.GetSong(options.songId))
	if not selectedSong then
		local selected = SongChartCatalog.SelectSongForSession({
			instrumentType = "PIANO",
			zoneId = options.zoneId or options.island,
			rarity = tierKey,
			seed = options.seed,
		})
		self.SongData = selected.song
		self.Melody = selected.chart or Config.MELODIES[1]
		self.SongDisplayName = SongChartCatalog.FormatSongDisplay(selected.song, "PIANO", selected.bpm, selected.starRating)
	else
		self.SongData = selectedSong
		local chart = selectedSong.charts and selectedSong.charts["PIANO"]
		self.Melody = chart or Config.MELODIES[1]
		self.SongDisplayName = SongChartCatalog.FormatSongDisplay(selectedSong, "PIANO", self.Melody.bpm or selectedSong.bpm, selectedSong.starRating)
	end

	self.Bpm = self.Melody.bpm or (self.SongData and self.SongData.bpm) or 120

	-- 2. Target Notes & Starting Progress (Rule 7)
	local baseTarget = self.Tier.targetNotes or 30
	self.TargetNotes = options.targetNotes or (baseTarget + (islandMod.targetNotesBonus or 0))

	local startRatio = self.CastBonus.startRatio or 0.10
	self.CurrentNotes = math.max(1, math.floor(startRatio * self.TargetNotes))
	self.Progress = startRatio

	local basePenalty = self.Tier.basePenaltyNotes or 3
	self.PenaltyNotes = options.basePenaltyNotes or math.max(1, math.floor(basePenalty * (self.CastBonus.penaltyMult or 1.0) * (islandMod.penaltyMultiplier or 1.0)))

	local rawSpeed = options.speed or self.Tier.speed or self.Melody.baseSpeed or 0.38
	self.Speed = math.clamp(rawSpeed * (islandMod.speedMultiplier or 1.0), 0.2, 1.4)

	-- 3. Inisialisasi State & Statistik
	self.State = "IDLE"
	self.Score = 0
	self.Combo = 0
	self.MaxCombo = 0
	self.Mistakes = 0
	self.PerfectHits = 0
	self.GreatHits = 0
	self.GoodHits = 0

	self.ActiveTiles = {}
	self.Tiles = self.ActiveTiles -- Referensi kompatibilitas balik
	self.ChartEvents = {}
	self.NextEventIndex = 1

	self.LastColPressTime = { 0, 0, 0, 0 }
	self.HeldColumns = { [1] = false, [2] = false, [3] = false, [4] = false }
	self.ActiveHolds = {} -- [column] = { event, pressTime, holdDuration, tailLength, frame, note, column }
	self.RecentChordHits = {}
	self.ActivePointers = {}
	self.HoldHits = 0
	self.ChordHits = 0
	self.HoldDrops = 0

	self.StartTime = 0
	self.ElapsedTime = 0
	self.Connections = {}
	self.OnWin = nil
	self.OnLose = nil

	-- 4. Kompilasi Aliran Not Berbasis Chart (FISH-045)
	self:_compileChartEvents()

	return self
end

-- ============ CHART COMPILER (FISH-045) ============
--[[
    Mengompilasi notasi nada, tempo BPM, jalur tuts, dan durasi beat menjadi
    antrean event waktu deterministik yang independen dari frame rate.
    Mendukung event: TAP, HOLD, CHORD, serta kombinasi simultan TAP + HOLD!
]]
function PianoSession:_compileChartEvents()
	local normalized = SongChartCatalog.NormalizeChart(self.Melody)
	local normEvents = normalized.events or {}
	local eventCount = math.max(1, #normEvents)

	local secondsPerBeat = 60.0 / math.max(40, self.Bpm)
	local travelDist = Config.HIT_LINE - (-Config.TILE_HEIGHT)
	local travelDuration = travelDist / self.Speed
	local leadInSeconds = math.max(1.8, travelDuration * 0.95)

	local minGlobalTimeGap = math.max(0.40, (Config.TILE_HEIGHT + 0.06) / self.Speed)
	local minSameLaneTimeGap = math.max(0.85, (Config.TILE_HEIGHT * 2.2) / self.Speed)

	local events = {}
	local currentHitTime = leadInSeconds
	local totalEventsNeeded = math.max(80, (self.TargetNotes or 30) * 3)

	local lastLane = -1
	local lastLaneHitTime = { [1] = -999, [2] = -999, [3] = -999, [4] = -999 }

	local evCounter = 0
	local loopIndex = 0

	while evCounter < totalEventsNeeded do
		loopIndex = loopIndex + 1
		local idx = ((loopIndex - 1) % eventCount) + 1
		local baseEv = normEvents[idx]

		if baseEv.type == "CHORD" then
			-- CHORD: Beberapa tuts ditekan pada hitTime yang sama persis
			local chordId = "chord_" .. loopIndex
			local chordLanes = baseEv.lanes or { 1, 3 }
			local chordNotes = baseEv.notes or { 0, 4 }

			for _, l in ipairs(chordLanes) do
				if (currentHitTime - (lastLaneHitTime[l] or -999)) < minSameLaneTimeGap then
					currentHitTime = (lastLaneHitTime[l] or currentHitTime) + minSameLaneTimeGap
				end
			end

			local spawnTime = currentHitTime - travelDuration
			for cIdx, l in ipairs(chordLanes) do
				evCounter = evCounter + 1
				lastLaneHitTime[l] = currentHitTime
				table.insert(events, {
					id = evCounter,
					type = "CHORD",
					chordId = chordId,
					chordTotal = #chordLanes,
					column = l,
					note = chordNotes[cIdx] or chordNotes[1] or 0,
					hitTime = currentHitTime,
					spawnTime = spawnTime,
					status = "PENDING",
					spawned = false,
					hit = false,
					frame = nil,
					y = -Config.TILE_HEIGHT,
				})
			end
			lastLane = chordLanes[#chordLanes]

			local durBeats = baseEv.durationBeats or 1.0
			currentHitTime = currentHitTime + math.max(minGlobalTimeGap, durBeats * secondsPerBeat)

		elseif baseEv.type == "HOLD" then
			-- HOLD NOTE: Tekan dan tahan melintasi durasi
			local lane = baseEv.lane or 1
			if (currentHitTime - (lastLaneHitTime[lane] or -999)) < minSameLaneTimeGap then
				currentHitTime = (lastLaneHitTime[lane] or currentHitTime) + minSameLaneTimeGap
			end

			local durBeats = math.max(1.2, baseEv.durationBeats or 2.0)
			local holdDuration = durBeats * secondsPerBeat
			local tailLength = math.max(0.20, holdDuration * self.Speed)
			local spawnTime = currentHitTime - travelDuration

			evCounter = evCounter + 1
			lastLane = lane
			lastLaneHitTime[lane] = currentHitTime + holdDuration

			table.insert(events, {
				id = evCounter,
				type = "HOLD",
				column = lane,
				note = baseEv.note or 0,
				hitTime = currentHitTime,
				holdDuration = holdDuration,
				tailLength = tailLength,
				spawnTime = spawnTime,
				status = "PENDING",
				spawned = false,
				hit = false,
				frame = nil,
				y = -Config.TILE_HEIGHT,
			})

			-- Memungkinkan TAP + HOLD overlap pada kolom berbeda
			local timeIncrement = math.max(minGlobalTimeGap, math.min(holdDuration * 0.75, 1.2 * secondsPerBeat))
			currentHitTime = currentHitTime + timeIncrement

		else -- "TAP"
			local lane = baseEv.lane or 1
			if lane == lastLane then
				lane = (lane % 4) + 1
			end

			if (currentHitTime - (lastLaneHitTime[lane] or -999)) < minSameLaneTimeGap then
				local bestCol, oldestTime = 1, math.huge
				for c = 1, 4 do
					if c ~= lastLane then
						local t = lastLaneHitTime[c] or -999
						if t < oldestTime then
							oldestTime = t
							bestCol = c
						end
					end
				end
				lane = bestCol
			end

			evCounter = evCounter + 1
			lastLane = lane
			lastLaneHitTime[lane] = currentHitTime

			local durBeats = baseEv.durationBeats or 1.0
			local spawnTime = currentHitTime - travelDuration

			table.insert(events, {
				id = evCounter,
				type = "TAP",
				column = lane,
				note = baseEv.note or 0,
				hitTime = currentHitTime,
				spawnTime = spawnTime,
				status = "PENDING",
				spawned = false,
				hit = false,
				frame = nil,
				y = -Config.TILE_HEIGHT,
			})

			currentHitTime = currentHitTime + math.max(minGlobalTimeGap, durBeats * secondsPerBeat)
		end
	end

	table.sort(events, function(a, b)
		if a.hitTime == b.hitTime then
			return a.id < b.id
		end
		return a.hitTime < b.hitTime
	end)

	self.ChartEvents = events
	self.NextEventIndex = 1
	self.ActiveTiles = {}
	self.Tiles = self.ActiveTiles
	self.ActiveHolds = {}
	self.HeldColumns = { [1] = false, [2] = false, [3] = false, [4] = false }
	self.RecentChordHits = {}
end

function PianoSession:IsActive()
	return self.State == "PLAYING"
end

-- ============ METRICS EVALUATION ============
function PianoSession:GetMetrics(won)
	local duration = os.clock() - (self.StartTime > 0 and self.StartTime or os.clock())
	local raw = {
		won = won,
		score = self.Score,
		hits = self.Score,
		perfectHits = self.PerfectHits,
		greatHits = self.GreatHits,
		goodHits = self.GoodHits,
		mistakes = self.Mistakes,
		maxCombo = self.MaxCombo,
		targetNotes = self.TargetNotes,
		duration = duration,
	}
	local performance = PerformanceCalculator.Calculate(raw)
	performance.score = self.Score
	performance.hits = self.Score
	performance.perfectHits = self.PerfectHits
	performance.greatHits = self.GreatHits
	performance.goodHits = self.GoodHits
	performance.mistakes = self.Mistakes
	performance.maxCombo = self.MaxCombo
	performance.targetNotes = self.TargetNotes
	performance.holdHits = self.HoldHits
	performance.chordHits = self.ChordHits
	performance.holdDrops = self.HoldDrops
	performance.songId = (self.SongData and self.SongData.id) or (self.Melody and self.Melody.songId) or "CANON_IN_D"
	return performance
end

-- ============ LIFECYCLE API ============
function PianoSession:Start(onWin, onLose)
	if self.State ~= "IDLE" then return false end
	if not PianoUI.Create() then return false end

	self.OnWin = onWin
	self.OnLose = onLose
	self.State = "PLAYING"
	self.StartTime = os.clock()
	self.ElapsedTime = 0

	PianoUI.UpdateHeader(self.CastBonus.label, self.CastBonus.color, self.SongDisplayName or self.Melody.name)
	PianoUI.HideResult()
	PianoUI.SetEnabled(true)
	PianoUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	-- Kompilasi ulang timeline agar sinkron dengan waktu mulai os.clock()
	self:_compileChartEvents()
	self:_bindInput()
	return true
end


function PianoSession:EndSession(won, message)
	if self.State ~= "PLAYING" then return end
	self.State = "RESULT"

	self:_unbindInput()
	self:_clearTiles()

	local metrics = self:GetMetrics(won)

	if won then
		-- Langsung sembunyikan seluruh GUI saat menang.
		PianoUI.ShowResult(true, message, metrics)
		PianoUI.SetEnabled(false)
	else
		-- Kalau kalah, result overlay tetap tampil.
		PianoUI.ShowResult(false, message, metrics)
		playMissSound()
	end

	local callback = won and self.OnWin or self.OnLose
	self.OnWin = nil
	self.OnLose = nil

	if callback then
		task.spawn(callback, metrics)
	end

	if not won then
		task.delay(1.8, function()
			PianoUI.HideResult()
			PianoUI.SetEnabled(false)
			self.State = "IDLE"
		end)
	else
		-- Tidak perlu menunggu 1,8 detik setelah menang.
		self.State = "IDLE"
	end
end


function PianoSession:Cancel()
	if self.State == "PLAYING" then
		self.State = "CANCELLED"
		self:_unbindInput()
		self:_clearTiles()
		PianoUI.HideResult()
		PianoUI.SetEnabled(false)
	end
end

function PianoSession:_clearTiles()
	for _, ev in ipairs(self.ActiveTiles) do
		if ev.frame then PianoUI.DestroyTile(ev.frame) end
	end
	table.clear(self.ActiveTiles)

	for col = 1, 4 do
		local hold = self.ActiveHolds[col]
		if hold and hold.frame then
			PianoUI.DestroyTile(hold.frame)
		end
		PianoUI.TriggerHoldActive(col, false)
	end
	table.clear(self.ActiveHolds)
	table.clear(self.HeldColumns)
	table.clear(self.ActivePointers)
	table.clear(self.RecentChordHits)
end

-- ============ GAMEPLAY & HIT DETECTION (FISH-045) ============
function PianoSession:_registerHit(entry, y)
	if self.State ~= "PLAYING" or entry.hit then return end
	entry.hit = true
	entry.status = "HIT"

	-- Mainkan audio semitone nada yang otentik sesuai melodi lagu
	playPianoNote(entry.note)

	self.Score += 1
	self.Combo += 1
	if self.Combo > self.MaxCombo then self.MaxCombo = self.Combo end

	local delta = math.abs(y - Config.HIT_LINE)
	local perfectWindow = (Config.HIT_RATINGS and Config.HIT_RATINGS.PERFECT and Config.HIT_RATINGS.PERFECT.window) or 0.05
	local greatWindow = (Config.HIT_RATINGS and Config.HIT_RATINGS.GREAT and Config.HIT_RATINGS.GREAT.window) or 0.09

	local ratingKey = "GOOD"
	if delta <= perfectWindow then
		ratingKey = "PERFECT"
		self.PerfectHits += 1
	elseif delta <= greatWindow then
		ratingKey = "GREAT"
		self.GreatHits += 1
	else
		ratingKey = "GOOD"
		self.GoodHits += 1
	end

	PianoUI.PlayHitEffect(entry.frame, y, ratingKey, entry.column)

	self.CurrentNotes = math.clamp(self.CurrentNotes + 1, 0, self.TargetNotes)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)
	PianoUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	if self.CurrentNotes >= self.TargetNotes then
		self:EndSession(true, "BERHASIL DITANGKAP!")
	end
end

function PianoSession:_registerHoldComplete(hold)
	if self.State ~= "PLAYING" then return end
	if hold.completed then return end
	hold.completed = true
	hold.event.hit = true
	hold.event.status = "COMPLETED"

	self.Score += 1
	self.Combo += 1
	self.HoldHits += 1
	if self.Combo > self.MaxCombo then self.MaxCombo = self.Combo end
	self.PerfectHits += 1

	PianoUI.PlayHoldComplete(hold.frame, hold.column)

	self.CurrentNotes = math.clamp(self.CurrentNotes + 1, 0, self.TargetNotes)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)
	PianoUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	if self.CurrentNotes >= self.TargetNotes then
		self:EndSession(true, "BERHASIL DITANGKAP!")
	end
end

function PianoSession:_registerHoldDrop(hold)
	if self.State ~= "PLAYING" then return end
	if hold.completed then return end
	hold.completed = true
	hold.event.hit = true
	hold.event.status = "FAILED"

	self.Combo = 0
	self.Mistakes += 1
	self.HoldDrops += 1
	playMissSound()

	PianoUI.PlayHoldDrop(hold.frame, hold.column)

	local penalty = self.PenaltyNotes or 1
	self.CurrentNotes = math.max(0, self.CurrentNotes - penalty)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)
	PianoUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	if self.CurrentNotes <= 0 then
		self:EndSession(false, "IKAN TERLEPAS!")
	end
end

function PianoSession:_registerMistake(column)
	if self.State ~= "PLAYING" then return end

	self.Combo = 0
	self.Mistakes += 1
	playMissSound()

	local penalty = self.PenaltyNotes or 1
	self.CurrentNotes = math.max(0, self.CurrentNotes - penalty)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)

	PianoUI.ShowHitRating("MISS", column, Config.HIT_LINE)
	if column then
		PianoUI.TriggerReceptorPress(column, "MISS")
		PianoUI.FlashColumn(column, "MISS")
	end
	PianoUI.ShakeArena()
	PianoUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	if self.CurrentNotes <= 0 then
		self:EndSession(false, "IKAN TERLEPAS!")
	end
end

-- ============ INPUT PROCESSING (TAP, HOLD, CHORD, TAP+HOLD) ============
function PianoSession:HandleColumnPress(column)
	if self.State ~= "PLAYING" then return end
	column = math.clamp(column or 1, 1, 4)
	self.HeldColumns[column] = true

	local now = os.clock()
	if now - (self.LastColPressTime[column] or 0) < 0.03 then return end
	self.LastColPressTime[column] = now

	-- Cari tile aktif terdekat di kolom ini yang statusnya masih PENDING
	local bestEv, bestDist = nil, math.huge
	for _, ev in ipairs(self.ActiveTiles) do
		if ev.column == column and (ev.status == "PENDING" or not ev.status) and not ev.hit and ev.frame then
			local dist = math.abs(ev.y - Config.HIT_LINE)
			if dist < bestDist then
				bestDist = dist
				bestEv = ev
			end
		end
	end

	local hitThreshold = (Config.HIT_RATINGS and Config.HIT_RATINGS.GOOD and Config.HIT_RATINGS.GOOD.window) or 0.18

	if bestEv and bestDist <= hitThreshold then
		if bestEv.type == "HOLD" then
			-- HOLD NOTE: Mulai tahan!
			bestEv.status = "HOLDING"
			self.ActiveHolds[column] = {
				event = bestEv,
				pressTime = now,
				holdDuration = bestEv.holdDuration,
				tailLength = bestEv.tailLength,
				frame = bestEv.frame,
				note = bestEv.note,
				column = column,
				completed = false,
			}
			playPianoNote(bestEv.note)
			PianoUI.TriggerHoldActive(column, true)

		elseif bestEv.type == "CHORD" then
			-- CHORD NOTE: Daftarkan hit dan verifikasi keselarasan input chord
			self:_registerHit(bestEv, bestEv.y)
			local cId = bestEv.chordId
			if cId then
				self.RecentChordHits[cId] = (self.RecentChordHits[cId] or 0) + 1
				if self.RecentChordHits[cId] >= (bestEv.chordTotal or 2) then
					self.ChordHits = self.ChordHits + 1
					PianoUI.ShowHitRating("CHORD_SYNC", column, Config.HIT_LINE)
				end
			end

		else -- "TAP"
			self:_registerHit(bestEv, bestEv.y)
		end
	else
		-- Input di luar timing window atau tidak ada not
		self:_registerMistake(column)
	end
end

function PianoSession:HandleColumnRelease(column)
	if self.State ~= "PLAYING" then return end
	column = math.clamp(column or 1, 1, 4)
	self.HeldColumns[column] = false
	PianoUI.TriggerHoldActive(column, false)

	local hold = self.ActiveHolds[column]
	if hold and not hold.completed then
		local now = os.clock()
		local elapsedHeld = now - hold.pressTime
		local minRatio = Config.HOLD_MIN_RATIO or 0.80
		local heldRatio = elapsedHeld / hold.holdDuration

		if heldRatio >= minRatio then
			self:_registerHoldComplete(hold)
		else
			self:_registerHoldDrop(hold)
		end

		self.ActiveHolds[column] = nil
	end
end

function PianoSession:HandleColumnInput(column)
	-- Backward compatibility wrapper
	self:HandleColumnPress(column)
end

-- ============ FRAME UPDATE ENGINE (ZERO-DRIFT) ============
function PianoSession:_update(dt)
	if self.State ~= "PLAYING" then return end

	local now = os.clock()
	local elapsed = now - self.StartTime
	self.ElapsedTime = elapsed

	-- 1. Spawning Tiles dari Chart Event Stream
	while self.NextEventIndex <= #self.ChartEvents do
		local ev = self.ChartEvents[self.NextEventIndex]
		if elapsed >= ev.spawnTime then
			local frame
			if ev.type == "HOLD" then
				frame = PianoUI.CreateHoldTile(ev.column, -Config.TILE_HEIGHT, ev.tailLength)
			elseif ev.type == "CHORD" then
				frame = PianoUI.CreateTile(ev.column, -Config.TILE_HEIGHT, true)
			else
				frame = PianoUI.CreateTile(ev.column, -Config.TILE_HEIGHT, false)
			end

			if frame then
				ev.frame = frame
				ev.spawned = true
				table.insert(self.ActiveTiles, ev)
			end
			self.NextEventIndex += 1
		else
			break
		end
	end

	-- 2. Update Active Holds (sedang ditahan pemain)
	for col = 1, 4 do
		local hold = self.ActiveHolds[col]
		if hold and not hold.completed then
			local elapsedHeld = now - hold.pressTime
			local remainingRatio = math.clamp(1.0 - (elapsedHeld / hold.holdDuration), 0, 1.0)

			PianoUI.UpdateHoldTile(hold.frame, Config.HIT_LINE, hold.tailLength, true, remainingRatio)

			-- Jika pemain berhasil mempertahankan sampai durasi penuh selesai
			if elapsedHeld >= hold.holdDuration then
				self:_registerHoldComplete(hold)
				self.ActiveHolds[col] = nil
			end
		end
	end

	-- 3. Update Posisi Tile yang Jatuh
	local i = 1
	while i <= #self.ActiveTiles do
		local ev = self.ActiveTiles[i]
		if ev.hit or ev.status == "COMPLETED" or ev.status == "FAILED" then
			table.remove(self.ActiveTiles, i)
		elseif ev.status == "HOLDING" then
			-- Sedang diproses di blok ActiveHolds
			i += 1
		else
			local timeUntilHit = ev.hitTime - elapsed
			local y = Config.HIT_LINE - (timeUntilHit * self.Speed)
			ev.y = y

			if y > Config.MISS_LINE then
				-- Tile terlewat melewati batas miss line!
				if ev.frame then PianoUI.DestroyTile(ev.frame) end
				table.remove(self.ActiveTiles, i)
				self:_registerMistake(ev.column)
			else
				if ev.type == "HOLD" then
					PianoUI.UpdateHoldTile(ev.frame, y, ev.tailLength, false, 1.0)
				else
					PianoUI.MoveTile(ev.frame, y)
				end
				i += 1
			end
		end
	end
end

-- ============ INPUT BINDING (PC KEYBOARD / MOUSE / TOUCH) ============
function PianoSession:_bindInput()
	self:_unbindInput()

	-- 1. ContextActionService untuk Keyboard Dinamis (KeybindSystem) + Fallback
	local bindableKeys = KeybindSystem.GetAllBindableKeys()
	ContextActionService:BindActionAtPriority(
		Config.ACTION_INPUT,
		function(actionName, inputState, inputObj)
			local targetCol = KeybindSystem.GetColumnForKey(inputObj.KeyCode) or KEY_BIND_MAP[inputObj.KeyCode]
			if targetCol then
				if inputState == Enum.UserInputState.Begin then
					self:HandleColumnPress(targetCol)
					return Enum.ContextActionResult.Sink
				elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
					self:HandleColumnRelease(targetCol)
					return Enum.ContextActionResult.Sink
				end
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value + 5000,
		table.unpack(bindableKeys)
	)

	-- Dengarkan perubahan keybind secara realtime jika pemain mengubah tombol saat minigame
	table.insert(self.Connections, KeybindSystem.OnKeybindsChanged:Connect(function()
		if self:IsActive() then
			ContextActionService:UnbindAction(Config.ACTION_INPUT)
			local newKeys = KeybindSystem.GetAllBindableKeys()
			ContextActionService:BindActionAtPriority(
				Config.ACTION_INPUT,
				function(actionName, inputState, inputObj)
					local targetCol = KeybindSystem.GetColumnForKey(inputObj.KeyCode) or KEY_BIND_MAP[inputObj.KeyCode]
					if targetCol then
						if inputState == Enum.UserInputState.Begin then
							self:HandleColumnPress(targetCol)
							return Enum.ContextActionResult.Sink
						elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
							self:HandleColumnRelease(targetCol)
							return Enum.ContextActionResult.Sink
						end
					end
					return Enum.ContextActionResult.Pass
				end,
				false,
				Enum.ContextActionPriority.High.Value + 5000,
				table.unpack(newKeys)
			)
		end
	end))

	-- 2. Loop RenderStepped untuk pergerakan halus frame-independent
	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))

	-- 3. Deteksi Klik Mouse & Sentuhan Layar HP/Tablet Multi-Touch di atas ArenaFrame
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local arena = PianoUI.GetArenaFrame()
			if not arena then return end
			local mousePos = input.Position
			local absPos = arena.AbsolutePosition
			local absSize = arena.AbsoluteSize
			if mousePos.X >= (absPos.X - 10) and mousePos.X <= (absPos.X + absSize.X + 10)
				and mousePos.Y >= (absPos.Y - 20) and mousePos.Y <= (absPos.Y + absSize.Y + 80) then
				local colWidth = absSize.X / Config.COLUMN_COUNT
				local col = math.clamp(math.floor((mousePos.X - absPos.X) / colWidth) + 1, 1, Config.COLUMN_COUNT)
				self.ActivePointers[input] = col
				self:HandleColumnPress(col)
			end
		end
	end))

	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local col = self.ActivePointers[input]
			if col then
				self.ActivePointers[input] = nil
				self:HandleColumnRelease(col)
			end
		end
	end))
end

function PianoSession:_unbindInput()
	pcall(function()
		ContextActionService:UnbindAction(Config.ACTION_INPUT)
	end)
	for _, conn in ipairs(self.Connections) do conn:Disconnect() end
	table.clear(self.Connections)

	-- Bersihkan active holds jika sesi di-cancel
	for col = 1, 4 do
		if self.ActiveHolds[col] then
			PianoUI.TriggerHoldActive(col, false)
		end
	end
	table.clear(self.ActiveHolds)
	table.clear(self.HeldColumns)
	table.clear(self.ActivePointers)
	table.clear(self.RecentChordHits)
end

return PianoSession
