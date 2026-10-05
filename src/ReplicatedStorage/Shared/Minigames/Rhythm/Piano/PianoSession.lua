--[[
    PianoSession (ModuleScript)
    FISH!TUNE — Isolated Piano Tiles Session Engine
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
local PianoUI = require(script.Parent:WaitForChild("PianoUI"))

local PianoSession = {}
PianoSession.__index = PianoSession

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

function PianoSession.new(options)
	options = options or {}
	local self = setmetatable({}, PianoSession)

	local castKey = tostring(options.castQuality or "GOOD"):upper()
	local tierKey = tostring(options.tier or "COMMON"):upper()
	local islandMod = InstrumentConfig.GetIslandModifier(options.island)

	self.Tier = FishingRaritySystem.GetTierData(tierKey)
	self.CastBonus = Config.CAST_BONUSES[castKey] or Config.CAST_BONUSES.GOOD
	self.Melody = Config.MELODIES[math.random(1, #Config.MELODIES)]

	local baseTarget = self.Tier.targetNotes or 30
	self.TargetNotes = baseTarget + (islandMod.targetNotesBonus or 0)

	local startRatio = self.CastBonus.startRatio or 0.10
	self.CurrentNotes = math.max(1, math.floor(startRatio * self.TargetNotes))
	self.Progress = startRatio

	local basePenalty = self.Tier.basePenaltyNotes or 3
	self.PenaltyNotes = math.max(1, math.floor(basePenalty * (self.CastBonus.penaltyMult or 1.0) * (islandMod.penaltyMultiplier or 1.0)))

	local rawSpeed = options.speed or self.Tier.speed or self.Melody.baseSpeed or 0.35
	self.Speed = math.clamp(rawSpeed * (islandMod.speedMultiplier or 1.0), 0.2, 1.4)

	self.State = "IDLE"
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
	self.LastColumn = -1
	self.LastColPressTime = { 0, 0, 0, 0 }

	self.StartTime = 0
	self.Connections = {}
	self.OnWin = nil
	self.OnLose = nil

	return self
end

function PianoSession:IsActive()
	return self.State == "PLAYING"
end

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
	performance.mistakes = self.Mistakes
	performance.maxCombo = self.MaxCombo
	performance.targetNotes = self.TargetNotes
	return performance
end

function PianoSession:Start(onWin, onLose)
	if self.State ~= "IDLE" then return false end
	if not PianoUI.Create() then return false end

	self.OnWin = onWin
	self.OnLose = onLose
	self.State = "PLAYING"
	self.StartTime = os.clock()

	PianoUI.UpdateHeader(self.CastBonus.label, self.CastBonus.color, self.Melody.name)
	PianoUI.HideResult()
	PianoUI.SetEnabled(true)
	PianoUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	self:_bindInput()
	self:_spawnTile()
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

function PianoSession:_spawnTile()
	if self.State ~= "PLAYING" then return end

	local available = {}
	for i = 1, Config.COLUMN_COUNT do
		if i ~= self.LastColumn then table.insert(available, i) end
	end
	local col = available[math.random(1, #available)]
	self.LastColumn = col

	local entry = {
		frame = nil,
		column = col,
		y = -Config.TILE_HEIGHT,
		noteIndex = self.MelodyIndex,
		hit = false,
	}

	entry.frame = PianoUI.CreateTile(col, entry.y)
	if entry.frame then table.insert(self.Tiles, entry) end

	self.MelodyIndex = (self.MelodyIndex % #self.Melody.notes) + 1
end

function PianoSession:_clearTiles()
	for _, entry in ipairs(self.Tiles) do
		if entry.frame then PianoUI.DestroyTile(entry.frame) end
	end
	table.clear(self.Tiles)
end

function PianoSession:_registerHit(entry, y)
	if self.State ~= "PLAYING" or entry.hit then return end
	entry.hit = true

	local note = self.Melody.notes[entry.noteIndex] or 0
	playPianoNote(note)

	self.Score += 1
	self.Combo += 1
	if self.Combo > self.MaxCombo then self.MaxCombo = self.Combo end

	local delta = math.abs(y - Config.HIT_LINE)
	local ratingKey = "GOOD"
	if delta <= Config.HIT_RATINGS.PERFECT.window then
		ratingKey = "PERFECT"
		self.PerfectHits += 1
	elseif delta <= Config.HIT_RATINGS.GREAT.window then
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

	self.CurrentNotes = math.clamp(self.CurrentNotes - self.PenaltyNotes, 0, self.TargetNotes)
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
	if now - (self.LastColPressTime[column] or 0) < 0.06 then return end
	self.LastColPressTime[column] = now

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

function PianoSession:_update(dt)
	if self.State ~= "PLAYING" then return end

	self.SpawnAccum += dt
	local interval = math.clamp(0.42 / self.Speed, 0.28, 0.90)
	if self.SpawnAccum >= interval then
		self.SpawnAccum = 0
		self:_spawnTile()
	end

	local i = 1
	while i <= #self.Tiles do
		local entry = self.Tiles[i]
		entry.y += self.Speed * dt
		if not entry.hit then
			if entry.y > Config.MISS_LINE then
				PianoUI.DestroyTile(entry.frame)
				table.remove(self.Tiles, i)
				self:_registerMistake(entry.column)
			else
				PianoUI.MoveTile(entry.frame, entry.y)
				i += 1
			end
		else
			PianoUI.DestroyTile(entry.frame)
			table.remove(self.Tiles, i)
		end
	end
end

function PianoSession:_bindInput()
	self:_unbindInput()

	ContextActionService:BindActionAtPriority(
		Config.ACTION_INPUT,
		function(actionName, inputState, inputObj)
			if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
			for idx, key in ipairs(Config.KEYS) do
				if inputObj.KeyCode == key then
					self:HandleColumnInput(idx)
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
		Config.KEYS[4]
	)

	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))

	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local arena = PianoUI.GetArenaFrame()
			if not arena then return end
			local mousePos = input.Position
			local absPos = arena.AbsolutePosition
			local absSize = arena.AbsoluteSize
			if mousePos.X >= absPos.X and mousePos.X <= (absPos.X + absSize.X)
				and mousePos.Y >= absPos.Y and mousePos.Y <= (absPos.Y + absSize.Y) then
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
