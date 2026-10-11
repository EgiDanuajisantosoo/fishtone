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
	self.TargetNotes = baseTarget + (islandMod.targetNotesBonus or 0)

	local startRatio = self.CastBonus.startRatio or 0.10
	self.CurrentNotes = math.max(1, math.floor(startRatio * self.TargetNotes))
	self.Progress = startRatio

	local basePenalty = self.Tier.basePenaltyNotes or 3
	self.PenaltyNotes = math.max(1, math.floor(basePenalty * (self.CastBonus.penaltyMult or 1.0) * (islandMod.penaltyMultiplier or 1.0)))

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
    Dilengkapi Anti-Collision Guard agar tile TIDAK PERNAH bertumpuk secara visual!
]]
function PianoSession:_compileChartEvents()
	local notes = (self.Melody and self.Melody.notes) or { 0, 2, 4, 5, 7, 9, 11, 12 }
	local explicitLanes = self.Melody and self.Melody.lanes
	local explicitDurations = self.Melody and self.Melody.durations

	local notesCount = math.max(1, #notes)
	local secondsPerBeat = 60.0 / math.max(40, self.Bpm)

	-- Jarak tempuh tile dari spawn (-TILE_HEIGHT) sampai garis target (HIT_LINE)
	local travelDist = Config.HIT_LINE - (-Config.TILE_HEIGHT)
	local travelDuration = travelDist / self.Speed
	local leadInSeconds = math.max(1.8, travelDuration * 0.95)

	-- Jarak vertikal minimum agar tile TIDAK PERNAH bertumpuk (overlap)
	-- TILE_HEIGHT = 0.16. Gap minimal 0.08 antar tile -> Delta Y >= 0.24
	local minGlobalTimeGap = math.max(0.48, (Config.TILE_HEIGHT + 0.08) / self.Speed)
	-- Gap untuk kolom yang SAMA harus longgar agar tidak menumpuk di lane yang sama
	local minSameLaneTimeGap = math.max(1.10, (Config.TILE_HEIGHT * 2.8) / self.Speed)

	-- Analisis rentang semitone nada untuk auto-charting jika lanes tidak eksplisit
	local minPitch, maxPitch = math.huge, -math.huge
	for _, p in ipairs(notes) do
		if p < minPitch then minPitch = p end
		if p > maxPitch then maxPitch = p end
	end
	if minPitch == maxPitch then
		minPitch = minPitch - 1
		maxPitch = maxPitch + 1
	end

	local events = {}
	local currentHitTime = leadInSeconds
	local totalEventsNeeded = math.max(80, (self.TargetNotes or 30) * 3)

	local lastLane = -1
	local lastLaneHitTime = { [1] = -999, [2] = -999, [3] = -999, [4] = -999 }

	for i = 1, totalEventsNeeded do
		local idx = ((i - 1) % notesCount) + 1
		local pitch = notes[idx] or 0

		-- 1. Tentukan jalur tuts (kolom 1..4)
		local lane = nil
		if explicitLanes and explicitLanes[idx] then
			lane = math.clamp(explicitLanes[idx], 1, Config.COLUMN_COUNT)
		else
			local norm = math.clamp((pitch - minPitch) / (maxPitch - minPitch), 0, 1)
			lane = math.clamp(math.floor(norm * 3.99) + 1, 1, 4)
		end

		-- STRICT ANTI-COLLISION: Not berturut-turut TIDAK BOLEH berada di kolom yang sama!
		if lane == lastLane then
			lane = (lane % 4) + 1
		end

		-- Pastikan kolom yang dipilih tidak memiliki tile yang masih terlalu dekat di atasnya
		if (currentHitTime - (lastLaneHitTime[lane] or -999)) < minSameLaneTimeGap then
			local bestCol, oldestTime = 1, math.huge
			for c = 1, Config.COLUMN_COUNT do
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

		lastLane = lane
		lastLaneHitTime[lane] = currentHitTime

		-- 2. Tentukan durasi beat dari chart & pastikan interval waktu memenuhi batas visual
		local dur = 1.0
		if explicitDurations and explicitDurations[idx] then
			dur = math.max(0.5, tonumber(explicitDurations[idx]) or 1.0)
		end

		local timeIncrement = math.max(minGlobalTimeGap, dur * secondsPerBeat)
		local spawnTime = currentHitTime - travelDuration

		table.insert(events, {
			id = i,
			chartIndex = idx,
			note = pitch,
			column = lane,
			beat = (currentHitTime - leadInSeconds) / secondsPerBeat,
			duration = dur,
			hitTime = currentHitTime,
			spawnTime = spawnTime,
			spawned = false,
			hit = false,
			frame = nil,
			y = -Config.TILE_HEIGHT,
		})

		currentHitTime = currentHitTime + timeIncrement
	end

	self.ChartEvents = events
	self.NextEventIndex = 1
	self.ActiveTiles = {}
	self.Tiles = self.ActiveTiles
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
	PianoUI.ShowResult(won, message, metrics)
	if not won then playMissSound() end

	local callback = won and self.OnWin or self.OnLose
	self.OnWin = nil
	self.OnLose = nil

	if callback then task.spawn(callback, metrics) end

	task.delay(1.8, function()
		PianoUI.HideResult()
		PianoUI.SetEnabled(false)
		self.State = "IDLE"
	end)
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
end

-- ============ GAMEPLAY & HIT DETECTION ============
function PianoSession:_registerHit(entry, y)
	if self.State ~= "PLAYING" or entry.hit then return end
	entry.hit = true

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

function PianoSession:HandleColumnInput(column)
	if self.State ~= "PLAYING" then return end
	local now = os.clock()
	if now - (self.LastColPressTime[column] or 0) < 0.04 then return end
	self.LastColPressTime[column] = now

	-- Cari tile aktif terdekat di kolom ini yang belum di-hit
	local bestEv, bestDist = nil, math.huge
	for _, ev in ipairs(self.ActiveTiles) do
		if ev.column == column and not ev.hit and ev.frame then
			local dist = math.abs(ev.y - Config.HIT_LINE)
			if dist < bestDist then
				bestDist = dist
				bestEv = ev
			end
		end
	end

	local hitThreshold = (Config.HIT_RATINGS and Config.HIT_RATINGS.GOOD and Config.HIT_RATINGS.GOOD.window) or 0.18
	if bestEv and bestDist <= hitThreshold then
		self:_registerHit(bestEv, bestEv.y)
	else
		self:_registerMistake(column)
	end
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
			local frame = PianoUI.CreateTile(ev.column, -Config.TILE_HEIGHT)
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

	-- 2. Update Posisi Tile dengan Matematika Presisi Waktu (Zero Drift)
	local i = 1
	while i <= #self.ActiveTiles do
		local ev = self.ActiveTiles[i]
		if ev.hit then
			-- Jika sudah kena hit, frame sudah dianimasikan di PlayHitEffect
			table.remove(self.ActiveTiles, i)
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
				PianoUI.MoveTile(ev.frame, y)
				i += 1
			end
		end
	end
end

-- ============ INPUT BINDING (PC KEYBOARD / MOUSE / TOUCH) ============
function PianoSession:_bindInput()
	self:_unbindInput()

	-- Bind Action untuk Keyboard: A, W, S, D, angka 1-4, keypad, dan tombol panah
	ContextActionService:BindActionAtPriority(
		Config.ACTION_INPUT,
		function(actionName, inputState, inputObj)
			if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
			local targetCol = KEY_BIND_MAP[inputObj.KeyCode]
			if targetCol then
				self:HandleColumnInput(targetCol)
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value + 5000,
		Enum.KeyCode.A,
		Enum.KeyCode.W,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.KeypadOne,
		Enum.KeyCode.KeypadTwo,
		Enum.KeyCode.KeypadThree,
		Enum.KeyCode.KeypadFour,
		Enum.KeyCode.Left,
		Enum.KeyCode.Up,
		Enum.KeyCode.Down,
		Enum.KeyCode.Right
	)

	-- Loop RenderStepped untuk pergerakan halus frame-independent
	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))

	-- Deteksi Klik Mouse & Sentuhan Layar HP/Tablet di atas ArenaFrame
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
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
				self:HandleColumnInput(col)
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
end

return PianoSession
