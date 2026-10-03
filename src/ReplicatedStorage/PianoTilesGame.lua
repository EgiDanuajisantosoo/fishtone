--[[
    PianoTilesGame (ModuleScript)

    GAMEPLAY / LOGIC SAJA.

    UI dipisahkan ke PianoTilesUI.
    Konfigurasi bersama dipusatkan di PianoTilesConfig.

    Tanggung jawab module ini:
    - State game
    - Score / combo / progress
    - Spawn dan movement tile
    - Hit / miss detection
    - Input D/F/J/K dan mouse/touch
    - Win / lose
    - Melody / audio
    - Callback hasil ronde
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local FishingRaritySystem = require(
	ReplicatedStorage:WaitForChild("FishingRaritySystem")
)

local Config = require(
	ReplicatedStorage:WaitForChild("PianoTilesConfig")
)

local PianoTilesUI = require(
	ReplicatedStorage:WaitForChild("PianoTilesUI")
)

local PianoTilesGame = {}

-- ============ STATE ============
local state = "Idle" -- Idle | Playing | Result

local score = 0
local combo = 0
local maxCombo = 0
local mistakes = 0

local progress = 0.40
local currentNotes = 12
local targetNotes = 30
local speed = 0.35

local currentMelody = Config.MELODIES[1]
local melodyIndex = 1
local spawnedCount = 0
local tiles = {}
local spawnAccum = 0
local lastColumn = -1
local roundToken = 0
local winCb
local loseCb
local lastColPressTime = { 0, 0, 0, 0 }
local gameStartTime = 0

-- Nilai dinamis untuk ronde aktif.
local activeTier = FishingRaritySystem.TIERS.COMMON
local activeCast = Config.CAST_BONUSES.GOOD
local activePenaltyNotes = 3

local inputConnections = {}

-- ============ AUDIO ============
local function playPianoNote(semitone)
	semitone = semitone or 0

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.85
	sound.PlaybackSpeed = 0.85 * (2 ^ (semitone / 12))
	sound.Parent = SoundService
	sound:Play()

	task.delay(1.2, function()
		if sound then
			sound:Destroy()
		end
	end)
end

local function playMissSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/splat.wav"
	sound.Volume = 0.8
	sound.PlaybackSpeed = 0.65
	sound.Parent = SoundService
	sound:Play()

	task.delay(1, function()
		if sound then
			sound:Destroy()
		end
	end)
end

-- ============ TILE MANAGEMENT ============
local function spawnTile()
	if state ~= "Playing" or progress >= 1.0 or progress <= 0 then
		return
	end

	spawnedCount += 1

	local notes = currentMelody.notes
	local semitone = notes[((melodyIndex - 1) % #notes) + 1]
	melodyIndex += 1

	local column = math.random(1, Config.COLUMN_COUNT)

	-- Hindari terlalu sering muncul di kolom yang sama.
	if column == lastColumn and math.random() < 0.75 then
		column = (column % Config.COLUMN_COUNT) + 1
	end

	lastColumn = column

	local tile = PianoTilesUI.CreateTile(
		column,
		-Config.TILE_HEIGHT
	)

	if not tile then
		return
	end

	table.insert(tiles, {
		frame = tile,
		column = column,
		y = -Config.TILE_HEIGHT,
		semitone = semitone,
	})
end

local function clearTiles()
	for _, entry in ipairs(tiles) do
		PianoTilesUI.DestroyTile(entry.frame)
	end

	table.clear(tiles)
end

-- ============ INPUT ============
local function unbindControls()
	pcall(function()
		ContextActionService:UnbindAction(Config.ACTION_PIANO_INPUT)
	end)
end

local handleColumn

local function onContextAction(_, inputState, inputObject)
	if state ~= "Playing" then
		return Enum.ContextActionResult.Pass
	end

	if inputState == Enum.UserInputState.Begin then
		local column = table.find(Config.KEYS, inputObject.KeyCode)

		if column and handleColumn then
			handleColumn(column)
		end
	end

	return Enum.ContextActionResult.Sink
end

local function onTouchOrClick(input)
	if state ~= "Playing" then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local arenaFrame = PianoTilesUI.GetArenaFrame()
	if not arenaFrame or not arenaFrame.Parent then
		return
	end

	local position = input.Position
	local absolutePosition = arenaFrame.AbsolutePosition
	local absoluteSize = arenaFrame.AbsoluteSize

	if position.X >= absolutePosition.X
		and position.X <= absolutePosition.X + absoluteSize.X
		and position.Y >= absolutePosition.Y
		and position.Y <= absolutePosition.Y + absoluteSize.Y then

		local column = math.clamp(
			math.floor(
				(position.X - absolutePosition.X)
					/ (absoluteSize.X / Config.COLUMN_COUNT)
			) + 1,
			1,
			Config.COLUMN_COUNT
		)

		handleColumn(column)
	end
end

local function disconnectInput()
	for _, connection in ipairs(inputConnections) do
		connection:Disconnect()
	end

	table.clear(inputConnections)
end

-- ============ ROUND / MISS / HIT ============
local registerMistake

local function endRound(win, message)
	if state ~= "Playing" then
		return
	end

	state = "Result"
	unbindControls()
	clearTiles()

	local duration = os.clock() - gameStartTime
	local totalAttempts = score + mistakes
	local accuracy = math.floor(
		(score / math.max(1, totalAttempts)) * 100
	)

	local metrics = {
		won = win,
		score = score,
		hits = score,
		mistakes = mistakes,
		maxCombo = maxCombo,
		duration = duration,
		targetNotes = targetNotes,
		accuracy = accuracy,
	}

	PianoTilesUI.ShowResult(
		win,
		message or (win and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!")
	)

	if not win then
		playMissSound()
	end

	local token = roundToken
	local callback = win and winCb or loseCb

	winCb = nil
	loseCb = nil

	if callback then
		task.spawn(function()
			callback(metrics)
		end)
	end

	task.delay(1.4, function()
		if token ~= roundToken then
			return
		end

		PianoTilesUI.HideResult()
		PianoTilesUI.SetEnabled(false)
		state = "Idle"
	end)
end

registerMistake = function(_, column)
	if state ~= "Playing" then
		return
	end

	combo = 0
	mistakes += 1

	currentNotes = math.max(
		0,
		currentNotes - activePenaltyNotes
	)

	progress = math.clamp(
		currentNotes / targetNotes,
		0,
		1
	)

	PianoTilesUI.UpdateHUD(progress, combo, currentNotes,
		targetNotes)
	playMissSound()

	if column then
		PianoTilesUI.FlashColumn(column)
	end

	PianoTilesUI.ShakeArena()

	if currentNotes <= 0 or progress <= 0 then
		endRound(
			false,
			"IKAN TERLEPAS!"
		)
	end
end

local function hitTile(entry)
	local index = table.find(tiles, entry)

	if index then
		table.remove(tiles, index)
	end

	score += 1
	combo += 1

	if combo > maxCombo then
		maxCombo = combo
	end

	-- Combo >= 3 memberi +2 nada.
	local gainNotes = 1

	if combo >= 50 then
		gainNotes = 10
	elseif combo >= 20 then
		gainNotes = 5
	elseif combo >= 10 then
		gainNotes = 3
	elseif combo >= 5 then
		gainNotes = 2
	end

	currentNotes = math.min(
		currentNotes + gainNotes,
		targetNotes
	)

	progress = math.clamp(
		currentNotes / targetNotes,
		0,
		1
	)

	PianoTilesUI.UpdateHUD(progress, combo, currentNotes,targetNotes)
	playPianoNote(entry.semitone)
	PianoTilesUI.PlayHitEffect(entry.frame, entry.y)

	if currentNotes >= targetNotes or progress >= 1.0 then
		endRound(true, "BERHASIL DITANGKAP!")
	end
end

handleColumn = function(column)
	if state ~= "Playing" then
		return
	end

	local now = os.clock()

	if now - (lastColPressTime[column] or 0) < 0.08 then
		return
	end

	lastColPressTime[column] = now

	local target = nil

	local minValidY = Config.HIT_LINE - (
		Config.TILE_HEIGHT * 1.2
	)

	local maxValidY = Config.MISS_LINE

	for _, entry in ipairs(tiles) do
		if entry.column == column
			and entry.y <= maxValidY
			and entry.y >= minValidY then

			if not target or entry.y > target.y then
				target = entry
			end
		end
	end

	if target then
		hitTile(target)
	else
		registerMistake("Salah Ketuk", column)
	end
end

-- ============ MOVEMENT LOOP ============
-- Pisahkan fungsi movement supaya miss tetap memakai gameplay logic.
local function updateTiles(dt)
	if state ~= "Playing" then
		return
	end

	dt = math.min(dt, 0.05)

	spawnAccum += dt

	local interval = Config.TILE_HEIGHT / speed

	while spawnAccum >= interval
		and progress < 1.0
		and progress > 0
		and state == "Playing" do

		spawnAccum -= interval
		spawnTile()
	end

	for index = #tiles, 1, -1 do
		local entry = tiles[index]

		entry.y += speed * dt
		PianoTilesUI.MoveTile(entry.frame, entry.y)

		if entry.y > Config.MISS_LINE then
			PianoTilesUI.DestroyTile(entry.frame)
			table.remove(tiles, index)
			registerMistake("Tile Terlewat", entry.column)

			if state ~= "Playing" then
				return
			end
		end
	end
end

-- Ganti connection RenderStepped sementara agar memakai updateTiles().
local function connectInputAndUpdate()
	disconnectInput()

	table.insert(
		inputConnections,
		RunService.RenderStepped:Connect(updateTiles)
	)

	table.insert(
		inputConnections,
		UserInputService.InputBegan:Connect(onTouchOrClick)
	)
end

-- ============ API PUBLIK ============
function PianoTilesGame.IsPlaying()
	return state == "Playing"
end

function PianoTilesGame.Start(config, onWin, onLose)
	if state ~= "Idle" then
		return false
	end

	if not PianoTilesUI.Create() then
		return false
	end

	config = config or {}

	local castKey = tostring(
		config.castQuality or "GOOD"
	):upper()

	activeTier = FishingRaritySystem.GetTierData(
		config.tier or "COMMON"
	)

	activeCast = Config.CAST_BONUSES[castKey]
		or Config.CAST_BONUSES.GOOD

	targetNotes = activeTier.targetNotes or 300

	local startRatio = activeCast.startRatio or 0.10

	currentNotes = math.max(
		1,
		math.floor(startRatio * targetNotes)
	)

	progress = startRatio

	activePenaltyNotes = math.max(
		1,
		math.floor(
			(activeTier.basePenaltyNotes or 3)
				* activeCast.penaltyMult
		)
	)

	currentMelody = Config.MELODIES[
	math.random(1, #Config.MELODIES)
	]

	speed = math.clamp(
		config.speed
			or activeTier.speed
			or currentMelody.baseSpeed,
		0.2,
		1.2
	)

	PianoTilesUI.UpdateHeader(
		activeCast.label,
		activeCast.color,
		currentMelody.name
	)

	roundToken += 1

	winCb = onWin
	loseCb = onLose

	score = 0
	combo = 0
	maxCombo = 0
	mistakes = 0

	spawnAccum = 0
	melodyIndex = 1
	spawnedCount = 0
	lastColumn = -1
	lastColPressTime = { 0, 0, 0, 0 }
	gameStartTime = os.clock()

	clearTiles()
	PianoTilesUI.HideResult()
	PianoTilesUI.SetEnabled(true)

	state = "Playing"

	ContextActionService:BindActionAtPriority(
		Config.ACTION_PIANO_INPUT,
		onContextAction,
		false,
		Enum.ContextActionPriority.High.Value + 5000,

		Config.KEYS[1],
		Config.KEYS[2],
		Config.KEYS[3],
		Config.KEYS[4],

		Enum.KeyCode.Space
	)

	connectInputAndUpdate()

	PianoTilesUI.UpdateHUD(progress, combo,currentNotes,
		targetNotes)
	spawnTile()

	return true
end

return PianoTilesGame
