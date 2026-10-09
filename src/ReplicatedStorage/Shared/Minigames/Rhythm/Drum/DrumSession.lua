--[[
    DrumSession (ModuleScript)
    FISH!TUNE — Isolated Drum Rhythm & Beat Timing Engine
]]

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("DrumConfig"))
local InstrumentConfig = require(Shared:WaitForChild("Config"):WaitForChild("InstrumentConfig"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))
local DrumUI = require(script.Parent:WaitForChild("DrumUI"))

local DrumSession = {}
DrumSession.__index = DrumSession

local function playDrumBeat(column)
	local pitches = { 0.70, 1.20, 0.55, 1.50 } -- Kick, Snare, Low Tom, Hi-Hat pitches
	local sound = Instance.new("Sound")
	sound.SoundId = Config.SOUND_ID
	sound.Volume = Config.VOLUME
	sound.PlaybackSpeed = pitches[column] or Config.BASE_PITCH
	sound.Parent = SoundService
	sound:Play()

	task.delay(0.8, function()
		if sound then sound:Destroy() end
	end)
end

local function playMissSound()
	local sound = Instance.new("Sound")
	sound.SoundId = Config.MISS_SOUND_ID
	sound.Volume = 0.8
	sound.PlaybackSpeed = 0.60
	sound.Parent = SoundService
	sound:Play()

	task.delay(1.0, function()
		if sound then sound:Destroy() end
	end)
end

function DrumSession.new(options)
	options = options or {}
	local self = setmetatable({}, DrumSession)

	local castKey = tostring(options.castQuality or "GOOD"):upper()
	local tierKey = tostring(options.tier or "COMMON"):upper()
	local islandMod = InstrumentConfig.GetIslandModifier(options.island)

	self.Tier = FishingRaritySystem.GetTierData(tierKey)
	self.CastBonus = Config.CAST_BONUSES[castKey] or Config.CAST_BONUSES.GOOD
	self.Groove = Config.GROOVES[math.random(1, #Config.GROOVES)]

	local baseTarget = self.Tier.targetNotes or 30
	self.TargetNotes = baseTarget + (islandMod.targetNotesBonus or 0)

	local startRatio = self.CastBonus.startRatio or 0.10
	self.CurrentNotes = math.max(1, math.floor(startRatio * self.TargetNotes))
	self.Progress = startRatio

	local basePenalty = self.Tier.basePenaltyNotes or 3
	self.PenaltyNotes = math.max(1, math.floor(basePenalty * (self.CastBonus.penaltyMult or 1.0) * (islandMod.penaltyMultiplier or 1.0)))

	local rawSpeed = options.speed or self.Tier.speed or self.Groove.baseSpeed or 0.40
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
	self.GrooveIndex = 1
	self.LastColumn = -1
	self.LastColPressTime = { 0, 0, 0, 0 }

	self.StartTime = 0
	self.Connections = {}
	self.OnWin = nil
	self.OnLose = nil

	return self
end

function DrumSession:IsActive()
	return self.State == "PLAYING"
end

function DrumSession:GetMetrics(won)
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

function DrumSession:Start(onWin, onLose)
	if self.State ~= "IDLE" then return false end
	if not DrumUI.Create() then return false end

	self.OnWin = onWin
	self.OnLose = onLose
	self.State = "PLAYING"
	self.StartTime = os.clock()

	DrumUI.UpdateHeader(self.CastBonus.label, self.CastBonus.color, self.Groove.name)
	DrumUI.HideResult()
	DrumUI.SetEnabled(true)
	DrumUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	self:_bindInput()
	self:_spawnTile()
	return true
end

function DrumSession:EndSession(won, message)
	if self.State ~= "PLAYING" then return end
	self.State = "RESULT"

	self:_unbindInput()
	self:_clearTiles()

	local metrics = self:GetMetrics(won)
	DrumUI.ShowResult(won, message, metrics)
	if not won then playMissSound() end

	local callback = won and self.OnWin or self.OnLose
	self.OnWin = nil
	self.OnLose = nil

	if callback then task.spawn(callback, metrics) end

	task.delay(1.8, function()
		DrumUI.HideResult()
		DrumUI.SetEnabled(false)
		self.State = "IDLE"
	end)
end

function DrumSession:Cancel()
	if self.State == "PLAYING" then
		self.State = "CANCELLED"
		self:_unbindInput()
		self:_clearTiles()
		DrumUI.HideResult()
		DrumUI.SetEnabled(false)
	end
end

function DrumSession:_spawnTile()
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
		noteIndex = self.GrooveIndex,
		hit = false,
	}

	entry.frame = DrumUI.CreateTile(col, entry.y)
	if entry.frame then table.insert(self.Tiles, entry) end

	self.GrooveIndex = (self.GrooveIndex % #self.Groove.notes) + 1
end

function DrumSession:_clearTiles()
	for _, entry in ipairs(self.Tiles) do
		if entry.frame then DrumUI.DestroyTile(entry.frame) end
	end
	table.clear(self.Tiles)
end

function DrumSession:_registerHit(entry, y)
	if self.State ~= "PLAYING" or entry.hit then return end
	entry.hit = true

	playDrumBeat(entry.column)

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

	DrumUI.PlayHitEffect(entry.frame, y, ratingKey, entry.column)

	self.CurrentNotes = math.clamp(self.CurrentNotes + 1, 0, self.TargetNotes)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)
	DrumUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	if self.CurrentNotes >= self.TargetNotes then
		self:EndSession(true, "BERHASIL DITANGKAP!")
	end
end

function DrumSession:_registerMistake(column)
	if self.State ~= "PLAYING" then return end

	self.Combo = 0
	self.Mistakes += 1
	playMissSound()

	local penalty = self.PenaltyNotes or 1
	self.CurrentNotes = math.max(0, self.CurrentNotes - penalty)
	self.Progress = math.clamp(self.CurrentNotes / self.TargetNotes, 0, 1)

	DrumUI.ShowHitRating("MISS", column, Config.HIT_LINE)
	if column then
		DrumUI.TriggerReceptorPress(column, "MISS")
	end
	DrumUI.ShakeArena()
	DrumUI.UpdateHUD(self.Progress, self.Combo, self.CurrentNotes, self.TargetNotes)

	if self.CurrentNotes <= 0 then
		self:EndSession(false, "IKAN TERLEPAS!")
	end
end

function DrumSession:HandleColumnInput(column)
	if self.State ~= "PLAYING" then return end
	local now = os.clock()
	if now - (self.LastColPressTime[column] or 0) < 0.05 then return end
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

	local hitThreshold = 0.28
	if bestEntry and bestEntry.y >= (Config.HIT_LINE - hitThreshold) and bestEntry.y <= (Config.MISS_LINE + 0.04) then
		self:_registerHit(bestEntry, bestEntry.y)
	else
		self:_registerMistake(column)
	end
end

function DrumSession:HandleAnyActiveInput()
	if self.State ~= "PLAYING" then return end
	-- Cari tile terdekat dengan hit line di seluruh kolom
	local bestEntry, bestDist = nil, math.huge
	for _, entry in ipairs(self.Tiles) do
		if not entry.hit then
			local dist = math.abs(entry.y - Config.HIT_LINE)
			if dist < bestDist then
				bestDist = dist
				bestEntry = entry
			end
		end
	end

	if bestEntry then
		self:HandleColumnInput(bestEntry.column)
	else
		self:_registerMistake(1)
	end
end

function DrumSession:_update(dt)
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
				DrumUI.DestroyTile(entry.frame)
				table.remove(self.Tiles, i)
				self:_registerMistake(entry.column)
			else
				DrumUI.MoveTile(entry.frame, entry.y)
				i += 1
			end
		else
			DrumUI.DestroyTile(entry.frame)
			table.remove(self.Tiles, i)
		end
	end
end

local DRUM_KEY_MAP = {
	[Enum.KeyCode.A] = 1,
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.H] = 1,

	[Enum.KeyCode.W] = 2,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.F] = 2,

	[Enum.KeyCode.S] = 3,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.J] = 3,

	[Enum.KeyCode.D] = 4,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.K] = 4,
	[Enum.KeyCode.L] = 4,
}

function DrumSession:_bindInput()
	self:_unbindInput()

	ContextActionService:BindActionAtPriority(
		Config.ACTION_INPUT,
		function(actionName, inputState, inputObj)
			if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
			if inputObj.KeyCode == Enum.KeyCode.Space then
				self:HandleAnyActiveInput()
				return Enum.ContextActionResult.Sink
			end
			local targetCol = DRUM_KEY_MAP[inputObj.KeyCode]
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
		Enum.KeyCode.F,
		Enum.KeyCode.H,
		Enum.KeyCode.J,
		Enum.KeyCode.K,
		Enum.KeyCode.L,
		Enum.KeyCode.Space,
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four
	)

	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))

	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe and input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local arena = DrumUI.GetArenaFrame()
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

function DrumSession:_unbindInput()
	pcall(function()
		ContextActionService:UnbindAction(Config.ACTION_INPUT)
	end)
	for _, conn in ipairs(self.Connections) do conn:Disconnect() end
	table.clear(self.Connections)
end

return DrumSession
