--[[
	PianoTilesGame (ModuleScript)
	Mini-game Piano Tiles dengan tema Glassmorphism Semi-Transparan,
	ritme melodi seirama dengan ketukan tile, feedback visual & audio yang elegan,
	serta SISTEM ANTI-SPAM, BATAS MAKSIMAL 3 KESALAHAN (3 LIVES),
	dan CONTINUOUS MELODY SPAWN (Nada tidak akan pernah habis meskipun ada nada terlewat).
	
	Fitur:
	1. Continuous Melody Spawn: Tile melodi akan terus muncul berkelanjutan sampai skor target tercapai
	   (nada tidak habis jika ada yang terlewat).
	2. Batas Kesalahan: Maksimal 3 kali salah (salah tekan tombol / tile terlewat).
	   Jika salah 3 kali, ikan langsung lepas!
	3. Anti-Spam: Menekan tombol di kolom kosong / tanpa tile akan langsung dihitung sebagai kesalahan (Wrong Press Penalty).
	4. Indikator Nyawa Visual: ❤️ ❤️ ❤️ yang berubah menjadi 🖤 saat terjadi kesalahan.
	5. Anti-Gerak Karakter: Menggunakan ContextActionService Sink dengan Prioritas Tinggi.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local PianoTilesGame = {}

-- ============ KONFIGURASI ============
local ACTION_PIANO_INPUT = "PianoTilesInputSink"
local KEYS = { Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K }
local KEY_LABELS = { "D", "F", "J", "K" }
local COLUMN_COUNT = 4
local TILE_HEIGHT = 0.16
local HIT_LINE = 0.80
local MISS_LINE = 0.94
local MAX_MISTAKES = 3

-- Bank Melodi Harmonis (Tangga nada semitone: 0 = C, 2 = D, 4 = E, 5 = F, 7 = G, 9 = A, 11 = B, 12 = C tinggi)
local MELODIES = {
	-- Canon in D (D Major)
	{
		name = "Canon in D",
		notes = { 2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7, 9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14 },
		baseSpeed = 0.38
	},
	-- Ode to Joy (Beethoven)
	{
		name = "Ode to Joy",
		notes = { 4, 4, 5, 7, 7, 5, 4, 2, 0, 0, 2, 4, 4, 2, 2, 4, 4, 5, 7, 7, 5, 4, 2, 0, 0, 2, 4, 2, 0 },
		baseSpeed = 0.36
	},
	-- Pentatonic River (Nuansa santai & melodius)
	{
		name = "River Flow",
		notes = { 0, 2, 4, 7, 9, 12, 14, 12, 9, 7, 4, 2, 4, 7, 9, 12, 16, 14, 12, 9, 7, 4, 2, 0 },
		baseSpeed = 0.35
	},
	-- Fur Elise Theme
	{
		name = "Für Elise",
		notes = { 7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0, 2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0 },
		baseSpeed = 0.40
	}
}

local function getPlayerGui()
	local p = Players.LocalPlayer
	if p then
		return p:FindFirstChild("PlayerGui") or p:WaitForChild("PlayerGui", 5)
	end
	return nil
end

-- ============ STATE ============
local state = "Idle" -- Idle | Playing | Result
local score, combo = 0, 0
local mistakes = 0
local targetTiles = 10
local speed = 0.35
local currentMelody = MELODIES[1]
local melodyIndex = 1
local spawnedCount = 0
local tiles = {}
local spawnAccum = 0
local lastColumn = -1
local roundToken = 0
local winCb, loseCb
local lastColPressTime = { 0, 0, 0, 0 }

-- Referensi GUI
local gui, arenaContainer, arenaFrame, scoreLabel, comboLabel, songLabel, livesLabel, resultOverlay, resultLabel
local columns, columnFlashes = {}, {}

local function mk(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function playPianoNote(semitone)
	semitone = semitone or 0
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.85
	s.PlaybackSpeed = 0.85 * (2 ^ (semitone / 12))
	s.Parent = SoundService
	s:Play()
	task.delay(1.2, function()
		s:Destroy()
	end)
end

local function playMissSound()
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/splat.wav"
	s.Volume = 0.8
	s.PlaybackSpeed = 0.65
	s.Parent = SoundService
	s:Play()
	task.delay(1, function()
		s:Destroy()
	end)
end

local function updateHud()
	if scoreLabel then
		scoreLabel.Text = "🎵 " .. score .. " / " .. targetTiles
	end
	if comboLabel then
		if combo >= 2 then
			comboLabel.Text = "🔥 COMBO x" .. combo
			comboLabel.Visible = true
		else
			comboLabel.Visible = false
		end
	end
	if livesLabel then
		local remaining = math.max(0, MAX_MISTAKES - mistakes)
		local hearts = ""
		for i = 1, MAX_MISTAKES do
			if i <= remaining then
				hearts = hearts .. "❤️ "
			else
				hearts = hearts .. "🖤 "
			end
		end
		livesLabel.Text = hearts .. " (" .. mistakes .. "/" .. MAX_MISTAKES .. " Salah)"
		if mistakes >= 2 then
			livesLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
		elseif mistakes == 1 then
			livesLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
		else
			livesLabel.TextColor3 = Color3.fromRGB(255, 120, 140)
		end
	end
end

local function spawnTile()
	if state ~= "Playing" or score >= targetTiles then return end
	spawnedCount += 1

	local notes = currentMelody.notes
	local semitone = notes[((melodyIndex - 1) % #notes) + 1]
	melodyIndex += 1

	local col = math.random(1, COLUMN_COUNT)
	if col == lastColumn and math.random() < 0.75 then
		col = (col % COLUMN_COUNT) + 1
	end
	lastColumn = col

	local tile = mk("Frame", {
		Name = "Tile_" .. spawnedCount,
		Size = UDim2.fromScale(0.88, TILE_HEIGHT),
		Position = UDim2.new(0.06, 0, -TILE_HEIGHT, 0),
		BackgroundColor3 = Color3.fromRGB(0, 200, 255),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, columns[col])
	
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, tile)
	
	local stroke = mk("UIStroke", {
		Color = Color3.fromRGB(150, 240, 255),
		Thickness = 1.5,
		Transparency = 0.2,
	}, tile)

	local inner = mk("Frame", {
		Size = UDim2.fromScale(0.7, 0.2),
		Position = UDim2.fromScale(0.15, 0.4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
	}, tile)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, inner)

	table.insert(tiles, {
		frame = tile,
		column = col,
		y = -TILE_HEIGHT,
		semitone = semitone,
		stroke = stroke
	})
end

local function clearTiles()
	for _, t in ipairs(tiles) do
		if t.frame and t.frame.Parent then
			t.frame:Destroy()
		end
	end
	table.clear(tiles)
end

local function unbindControls()
	pcall(function()
		ContextActionService:UnbindAction(ACTION_PIANO_INPUT)
	end)
end

local function endRound(win, message)
	if state ~= "Playing" then return end
	state = "Result"
	unbindControls()
	clearTiles()

	local defaultMsg = win and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!"
	resultLabel.Text = message or defaultMsg
	resultLabel.TextColor3 = win and Color3.fromRGB(60, 240, 140) or Color3.fromRGB(255, 70, 70)
	resultOverlay.Visible = true

	if not win then
		playMissSound()
	end

	local token = roundToken
	local cb = win and winCb or loseCb
	winCb, loseCb = nil, nil
	if cb then
		task.spawn(cb)
	end

	task.delay(1.4, function()
		if token ~= roundToken then return end
		resultOverlay.Visible = false
		if gui then
			gui.Enabled = false
		end
		state = "Idle"
	end)
end

local function registerMistake(reason, col)
	if state ~= "Playing" then return end

	mistakes += 1
	combo = 0
	updateHud()
	playMissSound()

	if col and columnFlashes[col] then
		local flash = columnFlashes[col]
		flash.Visible = true
		task.delay(0.18, function()
			flash.Visible = false
		end)
	end

	-- Efek getar merah pada arena frame saat salah
	if arenaContainer then
		local origPos = arenaContainer.Position
		local shakeTween = TweenService:Create(arenaContainer, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {
			Position = origPos + UDim2.new(0, math.random(-6, 6), 0, math.random(-3, 3))
		})
		shakeTween:Play()
		task.delay(0.2, function()
			if arenaContainer then arenaContainer.Position = origPos end
		end)
	end

	-- Cek apakah batas 3 kesalahan tercapai
	if mistakes >= MAX_MISTAKES then
		endRound(false, "IKAN TERLEPAS!\n(3x Salah Ketuk)")
	end
end

local function hitTile(entry)
	local idx = table.find(tiles, entry)
	if idx then
		table.remove(tiles, idx)
	end

	score += 1
	combo += 1
	updateHud()
	playPianoNote(entry.semitone)

	local f = entry.frame
	if f and f.Parent then
		f.BackgroundColor3 = Color3.fromRGB(60, 240, 130)
		if entry.stroke then
			entry.stroke.Color = Color3.fromRGB(120, 255, 180)
		end
		local tween = TweenService:Create(f, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.96, TILE_HEIGHT * 1.15),
			Position = UDim2.new(0.02, 0, entry.y - 0.01, 0)
		})
		tween:Play()
		tween.Completed:Once(function()
			f:Destroy()
		end)
	end

	-- Jika skor target tercapai, menang!
	if score >= targetTiles then
		endRound(true, "BERHASIL DITANGKAP!")
	end
end

local function handleColumn(col)
	if state ~= "Playing" then return end

	-- Debounce per kolom (mencegah double-input dalam frame mikro)
	local now = os.clock()
	if now - (lastColPressTime[col] or 0) < 0.08 then
		return
	end
	lastColPressTime[col] = now

	local target = nil
	local minValidY = HIT_LINE - (TILE_HEIGHT * 1.2) -- Jangkauan atas tile
	local maxValidY = MISS_LINE                     -- Jangkauan bawah tile

	for _, t in ipairs(tiles) do
		if t.column == col and t.y <= maxValidY and t.y >= minValidY then
			if not target or t.y > target.y then
				target = t
			end
		end
	end

	if target then
		hitTile(target)
	else
		-- Pemain salah tekan / spam kolom kosong!
		registerMistake("Salah Ketuk", col)
	end
end

local function onUpdate(dt)
	if state ~= "Playing" then return end
	dt = math.min(dt, 0.05)

	-- Terus spawn tile melodi selama score belum mencapai targetTiles
	spawnAccum += dt
	local interval = TILE_HEIGHT / speed
	while spawnAccum >= interval and score < targetTiles and state == "Playing" do
		spawnAccum -= interval
		spawnTile()
	end

	for i = #tiles, 1, -1 do
		local t = tiles[i]
		t.y += speed * dt
		t.frame.Position = UDim2.new(0.06, 0, t.y, 0)
		
		-- Jika tile terlewat melewati garis batas bawah (Miss Line)
		if t.y > MISS_LINE then
			if t.frame and t.frame.Parent then
				t.frame:Destroy()
			end
			table.remove(tiles, i)
			registerMistake("Tile Terlewat", t.column)
			if state ~= "Playing" then return end
		end
	end
end

-- Input Action Handler yang Mengkonsumsi (Sink) Tombol agar Tidak Menggerakkan Player
local function onContextAction(actionName, inputState, inputObject)
	if state ~= "Playing" then
		return Enum.ContextActionResult.Pass
	end

	if inputState == Enum.UserInputState.Begin then
		local col = table.find(KEYS, inputObject.KeyCode)
		if col then
			handleColumn(col)
		end
	end

	return Enum.ContextActionResult.Sink
end

local function onTouchOrClick(input, _)
	if state ~= "Playing" then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		if arenaFrame and arenaFrame.Parent then
			local abs, sz = arenaFrame.AbsolutePosition, arenaFrame.AbsoluteSize
			if pos.X >= abs.X and pos.X <= abs.X + sz.X and pos.Y >= abs.Y and pos.Y <= abs.Y + sz.Y then
				local c = math.clamp(math.floor((pos.X - abs.X) / (sz.X / COLUMN_COUNT)) + 1, 1, COLUMN_COUNT)
				handleColumn(c)
			end
		end
	end
end

-- ============ MEMBANGUN GUI GLASSMORPHISM ============
local function buildGui()
	local pGui = getPlayerGui()
	if not pGui then return end

	if gui and gui.Parent == pGui then return end
	if gui then gui:Destroy() end
	table.clear(columns)
	table.clear(columnFlashes)

	gui = mk("ScreenGui", {
		Name = "PianoTilesGui",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		Enabled = false,
	}, pGui)

	arenaContainer = mk("Frame", {
		Name = "ArenaContainer",
		Size = UDim2.new(0, 380, 0.84, 0),
		Position = UDim2.new(0.5, -190, 0.08, 0),
		BackgroundColor3 = Color3.fromRGB(12, 16, 24),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
	}, gui)
	mk("UICorner", { CornerRadius = UDim.new(0, 16) }, arenaContainer)
	
	mk("UIStroke", {
		Color = Color3.fromRGB(0, 190, 255),
		Thickness = 2,
		Transparency = 0.4,
	}, arenaContainer)

	local header = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundTransparency = 1,
	}, arenaContainer)

	songLabel = mk("TextLabel", {
		Size = UDim2.new(0.55, 0, 0, 30),
		Position = UDim2.new(0.05, 0, 0, 4),
		BackgroundTransparency = 1,
		Text = "🎵 Melodi: Canon in D",
		TextColor3 = Color3.fromRGB(180, 225, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	scoreLabel = mk("TextLabel", {
		Size = UDim2.new(0.35, 0, 0, 30),
		Position = UDim2.new(0.60, 0, 0, 4),
		BackgroundTransparency = 1,
		Text = "0 / 10",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, header)

	livesLabel = mk("TextLabel", {
		Size = UDim2.new(0.9, 0, 0, 26),
		Position = UDim2.new(0.05, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = "❤️ ❤️ ❤️ (0/3 Salah)",
		TextColor3 = Color3.fromRGB(255, 120, 140),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, header)

	comboLabel = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 68),
		BackgroundTransparency = 1,
		Text = "🔥 COMBO x2",
		TextColor3 = Color3.fromRGB(255, 200, 50),
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
		Visible = false,
	}, arenaContainer)

	arenaFrame = mk("Frame", {
		Name = "ArenaColumns",
		Size = UDim2.new(1, 0, 1, -74),
		Position = UDim2.new(0, 0, 0, 74),
		BackgroundTransparency = 1,
	}, arenaContainer)

	for i = 1, COLUMN_COUNT do
		local shade = (i % 2 == 0) and Color3.fromRGB(20, 28, 42) or Color3.fromRGB(15, 22, 34)
		local col = mk("Frame", {
			Name = "Column" .. i,
			Size = UDim2.fromScale(1 / COLUMN_COUNT, 1),
			Position = UDim2.fromScale((i - 1) / COLUMN_COUNT, 0),
			BackgroundColor3 = shade,
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
		}, arenaFrame)
		columns[i] = col

		if i > 1 then
			mk("Frame", {
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = Color3.fromRGB(0, 180, 255),
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
			}, col)
		end

		local flash = mk("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 40, 40),
			BackgroundTransparency = 0.6,
			Visible = false,
			BorderSizePixel = 0,
		}, col)
		columnFlashes[i] = flash

		local keyBadge = mk("Frame", {
			Size = UDim2.new(0, 36, 0, 36),
			Position = UDim2.new(0.5, -18, HIT_LINE + 0.04, 0),
			BackgroundColor3 = Color3.fromRGB(30, 42, 60),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
		}, col)
		mk("UICorner", { CornerRadius = UDim.new(0, 8) }, keyBadge)
		mk("UIStroke", {
			Color = Color3.fromRGB(0, 200, 255),
			Thickness = 1,
			Transparency = 0.5,
		}, keyBadge)

		mk("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = KEY_LABELS[i],
			TextColor3 = Color3.fromRGB(240, 245, 255),
			Font = Enum.Font.GothamBlack,
			TextSize = 18,
		}, keyBadge)
	end

	local hitLine = mk("Frame", {
		Name = "HitLine",
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.fromScale(0, HIT_LINE),
		BackgroundColor3 = Color3.fromRGB(0, 255, 200),
		BorderSizePixel = 0,
	}, arenaFrame)
	
	mk("UIStroke", {
		Color = Color3.fromRGB(0, 255, 220),
		Thickness = 2,
		Transparency = 0.2,
	}, hitLine)

	resultOverlay = mk("Frame", {
		Name = "ResultOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 14, 22),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Visible = false,
	}, arenaContainer)
	mk("UICorner", { CornerRadius = UDim.new(0, 16) }, resultOverlay)

	resultLabel = mk("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.4),
		Position = UDim2.fromScale(0.05, 0.3),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
	}, resultOverlay)

	RunService.RenderStepped:Connect(onUpdate)
	UserInputService.InputBegan:Connect(onTouchOrClick)
end

-- ============ API PUBLIK ============
function PianoTilesGame.IsPlaying()
	return state == "Playing"
end

function PianoTilesGame.Start(config, onWin, onLose)
	if state ~= "Idle" then
		return false
	end
	buildGui()
	if not gui then return false end

	config = config or {}
	targetTiles = math.max(4, math.floor(config.tiles or 10))
	
	currentMelody = MELODIES[math.random(1, #MELODIES)]
	speed = math.clamp(config.speed or currentMelody.baseSpeed, 0.2, 1.2)
	
	if songLabel then
		songLabel.Text = "🎵 " .. currentMelody.name
	end

	roundToken += 1
	winCb, loseCb = onWin, onLose
	score, combo = 0, 0
	mistakes = 0
	spawnAccum = 0
	melodyIndex = 1
	spawnedCount = 0
	lastColumn = -1
	lastColPressTime = { 0, 0, 0, 0 }
	clearTiles()

	ContextActionService:BindActionAtPriority(
		ACTION_PIANO_INPUT,
		onContextAction,
		false,
		Enum.ContextActionPriority.High.Value + 5000,
		Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.Space
	)

	gui.Enabled = true
	state = "Playing"
	updateHud()
	spawnTile()
	return true
end

return PianoTilesGame
