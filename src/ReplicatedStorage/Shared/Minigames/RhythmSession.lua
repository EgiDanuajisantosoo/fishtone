--[[
	RhythmSession (ModuleScript)
	FISH!TUNE — Isolated Rhythm Minigame Session Engine (FISH-012)

	Class Berorientasi Objek untuk Mengelola Satu Sesi Permainan Rhythm Piano Tiles:
	1. State Enkapsulasi Mandiri (Bebas dari efek samping singleton / memory leak).
	2. Sistem Penilaian Multi-Tingkat (Perfect / Great / Good Hit Windows).
	3. Mesin Audio Harmonis & Melodi Semitone Progresif.
	4. Kalkulasi Metrik Kinerja Presisi (Akurasi, Combo Maksimal, Skor, Waktu Sesi).
	5. Pembersihan Resource Otomatis (Unbind, Disconnect, Clear Tiles).
]]

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("PianoTilesConfig"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))
local PianoTilesUI = require(script.Parent:WaitForChild("PianoTilesUI"))

local RhythmSession = {}
RhythmSession.__index = RhythmSession

-- ============ AUDIO SYNTHESIS ============
local function playPianoNote(semitone)
	semitone = semitone or 0
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.85
	sound.PlaybackSpeed = 0.85 * (2 ^ (semitone / 12))
	sound.Parent = SoundService
	sound:Play()

	task.delay(1.2, function()
		if sound then sound:Destroy() end
	end)
end

local function playMissSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/splat.wav"
	sound.Volume = 0.8
	sound.PlaybackSpeed = 0.65
	sound.Parent = SoundService
	sound:Play()

	task.delay(1.0, function()
		if sound then sound:Destroy() end
	end)
end

-- ============ CONSTRUCTOR ============
function RhythmSession.new(options)
	options = options or {}
	local self = setmetatable({}, RhythmSession)

	local castKey = tostring(options.castQuality or "GOOD"):upper()
	local tierKey = tostring(options.tier or "COMMON"):upper()

	self.Tier = FishingRaritySystem.GetTierData(tierKey)
	self.CastBonus = Config.CAST_BONUSES[castKey] or Config.CAST_BONUSES.GOOD
	self.Melody = Config.MELODIES[math.random(1, #Config.MELODIES)]

	self.TargetNotes = self.Tier.targetNotes or 30
	local startRatio = self.CastBonus.startRatio or 0.10
	self.CurrentNotes = math.max(1, math.floor(startRatio * self.TargetNotes))
	self.Progress = startRatio

	self.PenaltyNotes = math.max(1, math.floor((self.Tier.basePenaltyNotes or 3) * (self.CastBonus.penaltyMult or 1.0)))
	self.Speed = math.clamp(options.speed or self.Tier.speed or self.Melody.baseSpeed or 0.35, 0.2, 1.2)

	-- State
	self.State = "IDLE" -- IDLE | PLAYING | RESULT | CANCELLED
	self.Score = 0
	self.Combo = 0
	self.MaxCombo = 0
	self.Mistakes = 0
	self.PerfectHits = 0
	self.GreatHits = 0
	self.GoodHits = 0

	self.Tiles = {}
	self.SpawnAccum = 0
	self.MelodyIndex = 1
	self.SpawnedCount = 0
	self.LastColumn = -1
	self.LastColPressTime = { 0, 0, 0, 0 }

	self.StartTime = 0
	self.Connections = {}
	self.OnWin = nil
	self.OnLose = nil

	return self
end

-- ============ GAMEPLAY METHODS ============
function RhythmSession:IsActive()
	return self.State == "PLAYING"
end

function RhythmSession:GetMetrics(won)
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
	-- Passthrough backward compatibility properties
	performance.score = self.Score
	performance.hits = self.Score
	performance.mistakes = self.Mistakes
	performance.maxCombo = self.MaxCombo
	performance.targetNotes = self.TargetNotes

	return performance
end

function RhythmSession:Start(onWin, onLose)
	if self.State ~= "IDLE" then return false end

	if not PianoTilesUI.Create() then
		return false
	end

	self.OnWin = onWin
	self.OnLose = onLose
	self.State = "PLAYING"
	self.StartTime = os.clock()

	PianoTilesUI.UpdateHeader(self.CastBonus.label, self.CastBonus.color, self.Melody.name)
	PianoTilesUI.HideResult()
	PianoTilesUI.SetEnabled(true)
	PianoTilesUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	self:_bindInput()
	self:_spawnTile()

	return true
end

function RhythmSession:EndSession(won, message)
	if self.State ~= "PLAYING" then return end
	self.State = "RESULT"

	self:_unbindInput()
	self:_clearTiles()

	local metrics = self:GetMetrics(won)

	PianoTilesUI.ShowResult(won, message or (won and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!"), metrics)
	if not won then
		playMissSound()
	end

	local callback = won and self.OnWin or self.OnLose
	self.OnWin = nil
	self.OnLose = nil

	if callback then
		task.spawn(callback, metrics)
	end

	task.delay(1.8, function()
		PianoTilesUI.HideResult()
		PianoTilesUI.SetEnabled(false)
		self.State = "IDLE"
	end)
end

function RhythmSession:Cancel()
	if self.State == "PLAYING" then
		self.State = "CANCELLED"
		self:_unbindInput()
		self:_clearTiles()
		PianoTilesUI.HideResult()
		PianoTilesUI.SetEnabled(false)
	end
end

-- ============ INTERNAL TILE & INPUT LOGIC ============
function RhythmSession:_spawnTile()
	if self.State ~= "PLAYING" then return end

	local col
	local available = {}
	for i = 1, Config.COLUMN_COUNT do
		if i ~= self.LastColumn then
			table.insert(available, i)
		end
	end

	col = available[math.random(1, #available)]
	self.LastColumn = col

	local entry = {
		frame = nil,
		column = col,
		y = -Config.TILE_HEIGHT,
		noteIndex = self.MelodyIndex,
		hit = false,
	}

	entry.frame = PianoTilesUI.CreateTile(col, entry.y)
	if entry.frame then
		table.insert(self.Tiles, entry)
	end

	self.MelodyIndex = (self.MelodyIndex % #self.Melody.notes) + 1
	self.SpawnedCount += 1
end

function RhythmSession:_clearTiles()
	for _, entry in ipairs(self.Tiles) do
		if entry.frame then
			PianoTilesUI.DestroyTile(entry.frame)
		end
	end
	table.clear(self.Tiles)
end

function RhythmSession:GetLiveStats()
	local totalHits = self.PerfectHits + self.GreatHits + self.GoodHits
	local totalAttempts = totalHits + self.Mistakes
	local acc = 100
	if totalAttempts > 0 then
		local weighted = (self.PerfectHits * 1.0) + (self.GreatHits * 0.8) + (self.GoodHits * 0.5)
		acc = math.clamp((weighted / totalAttempts) * 100, 0, 100)
	end

	return {
		accuracy = math.floor(acc * 10) / 10,
		perfect = self.PerfectHits,
		great = self.GreatHits,
		good = self.GoodHits,
		miss = self.Mistakes,
		combo = self.Combo,
		maxCombo = self.MaxCombo,
	}
end

function RhythmSession:_registerHit(entry, y)
	if self.State ~= "PLAYING" or entry.hit then return end
	entry.hit = true

	local note = self.Melody.notes[entry.noteIndex] or 0
	playPianoNote(note)

	self.Score += 1
	self.Combo += 1
	if self.Combo > self.MaxCombo then
		self.MaxCombo = self.Combo
	end

	-- Precision Rating calculation
	local delta = math.abs(y - Config.HIT_LINE)
	local perfectWindow = (Config.HIT_RATINGS and Config.HIT_RATINGS.PERFECT and Config.HIT_RATINGS.PERFECT.window) or 0.04
	local greatWindow = (Config.HIT_RATINGS and Config.HIT_RATINGS.GREAT and Config.HIT_RATINGS.GREAT.window) or 0.08

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

	PianoTilesUI.PlayHitEffect(entry.frame, y, ratingKey, entry.column)

	self.CurrentNotes = math.clamp(self.CurrentNotes + 1, 0, self.TargetNotes)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)

	PianoTilesUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes, self:GetLiveStats())

	if self.CurrentNotes >= self.TargetNotes then
		self:EndSession(true, "BERHASIL DITANGKAP!")
	end
end

function RhythmSession:_registerMistake(column)
	if self.State ~= "PLAYING" then return end

	self.Combo = 0
	self.Mistakes += 1
	playMissSound()

	self.CurrentNotes = math.clamp(self.CurrentNotes - self.PenaltyNotes, 0, self.TargetNotes)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)

	PianoTilesUI.ShowHitRating("MISS", column, Config.HIT_LINE)
	if column then
		PianoTilesUI.TriggerReceptorPress(column, "MISS")
		PianoTilesUI.FlashColumn(column, "MISS")
	end
	PianoTilesUI.ShakeArena()
	PianoTilesUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes, self:GetLiveStats())

	if self.CurrentNotes <= 0 then
		self:EndSession(false, "IKAN TERLEPAS!")
	end
end

function RhythmSession:HandleColumnInput(column, origin)
	if self.State ~= "PLAYING" then return end

	local now = os.clock()
	if now - (self.LastColPressTime[column] or 0) < 0.06 then
		return
	end
	self.LastColPressTime[column] = now

	-- Cari tile aktif terdekat di kolom ini
	local bestEntry, bestDist = nil, math.huge
	for _, entry in ipairs(self.Tiles) do
		if entry.column == column and not entry.hit then
			local dist = math.abs(entry.y - Config.HIT_LINE)
			if dist < bestDist then
				bestDist = dist
				bestEntry = entry
			end
		end
	end

	if bestEntry and bestEntry.y >= (Config.HIT_LINE - 0.22) and bestEntry.y <= Config.MISS_LINE then
		self:_registerHit(bestEntry, bestEntry.y)
	else
		self:_registerMistake(column)
	end
end

function RhythmSession:_update(dt)
	if self.State ~= "PLAYING" then return end

	-- Spawn Timer
	self.SpawnAccum += dt
	local spawnInterval = math.clamp(0.42 / self.Speed, 0.28, 0.90)
	if self.SpawnAccum >= spawnInterval then
		self.SpawnAccum = 0
		self:_spawnTile()
	end

	-- Move & Cull Tiles
	local i = 1
	while i <= #self.Tiles do
		local entry = self.Tiles[i]
		entry.y += self.Speed * dt

		if not entry.hit then
			if entry.y > Config.MISS_LINE then
				PianoTilesUI.DestroyTile(entry.frame)
				table.remove(self.Tiles, i)
				self:_registerMistake(entry.column)
			else
				PianoTilesUI.MoveTile(entry.frame, entry.y)
				i += 1
			end
		else
			PianoTilesUI.DestroyTile(entry.frame)
			table.remove(self.Tiles, i)
		end
	end
end

function RhythmSession:_bindInput()
	self:_unbindInput()

	-- Action Binding
	ContextActionService:BindActionAtPriority(
		Config.ACTION_PIANO_INPUT,
		function(actionName, inputState, inputObj)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end

			for idx, key in ipairs(Config.KEYS) do
				if inputObj.KeyCode == key then
					self:HandleColumnInput(idx, "KEYBOARD")
					return Enum.ContextActionResult.Sink
				end
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 5000,
		Config.KEYS[1],
		Config.KEYS[2],
		Config.KEYS[3],
		Config.KEYS[4],
		Enum.KeyCode.Space
	)

	-- Render Loop
	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))

	-- Touch / Click Listener
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local arena = PianoTilesUI.GetArenaFrame()
			if not arena then return end

			local mousePos = input.Position
			local absPos = arena.AbsolutePosition
			local absSize = arena.AbsoluteSize

			if mousePos.X >= absPos.X and mousePos.X <= (absPos.X + absSize.X)
				and mousePos.Y >= absPos.Y and mousePos.Y <= (absPos.Y + absSize.Y) then
				local colWidth = absSize.X / Config.COLUMN_COUNT
				local col = math.clamp(math.floor((mousePos.X - absPos.X) / colWidth) + 1, 1, Config.COLUMN_COUNT)
				self:HandleColumnInput(col, "TOUCH_CLICK")
			end
		end
	end))
end

function RhythmSession:_unbindInput()
	pcall(function()
		ContextActionService:UnbindAction(Config.ACTION_PIANO_INPUT)
	end)
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)
end

return RhythmSession
