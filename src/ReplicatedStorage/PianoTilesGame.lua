--[[
	PianoTilesGame (ModuleScript)
	Mini-game Piano Tiles dengan tema Glassmorphism Semi-Transparan,
	ritme melodi seirama dengan ketukan tile, feedback visual & audio yang elegan,
	serta SISTEM INDIKATOR PROGRESS TANGKAPAN DINAMIS BERDASARKAN KUALITAS LEMPARAN & TIER IKAN.
	
	Mekanisme:
	1. Progress Bar Awal Dinamis:
	   - Ditentukan dari Kualitas Lemparan (PERFECT: +25%, GREAT: +12%, GOOD: +0%).
	   - Dan Tier Ikan (BIASA: 40%, SEDANG: 35%, LANGKA: 30%, LEGENDARIS: 25%).
	2. Pengurangan Bar (Miss Penalty) & Penambahan Bar (Hit Gain) Berskala:
	   - Ikan LEGENDARIS lebih kuat & agresif (Penalti kesalahan lebih berat, penambahan bar lebih menantang).
	   - Lemparan PERFECT mengurangi beban penalti kesalahan (ikan tertegun).
	3. Kondisi Menang & Kalah:
	   - Bar Penuh 100%: BERHASIL DITANGKAP!
	   - Bar Habis 0%: IKAN TERLEPAS!
	4. Continuous Melody Spawn: Nada melodi terus mengalir secara dinamis.
	5. Anti-Spam & Anti-Gerak Karakter (ContextActionService Sink).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local FishingRaritySystem = require(ReplicatedStorage:WaitForChild("FishingRaritySystem"))

local PianoTilesGame = {}

-- ============ KONFIGURASI UMUM ============
local ACTION_PIANO_INPUT = "PianoTilesInputSink"
local KEYS = { Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K }
local KEY_LABELS = { "D", "F", "J", "K" }
local COLUMN_COUNT = 4
local TILE_HEIGHT = 0.16
local HIT_LINE = 0.78
local MISS_LINE = 0.94

-- ============ KONFIGURASI 6 TIER IKAN ============
local TIER_CONFIGS = {
	EX = FishingRaritySystem.TIERS.EX,
	UR = FishingRaritySystem.TIERS.UR,
	SSR = FishingRaritySystem.TIERS.SSR,
	SUPERRARE = FishingRaritySystem.TIERS.SuperRare,
	SR = FishingRaritySystem.TIERS.SuperRare,
	RARE = FishingRaritySystem.TIERS.Rare,
	COMMON = FishingRaritySystem.TIERS.Common,
	-- Backward compatibility alias
	LEGENDARIS = FishingRaritySystem.TIERS.SSR,
	LANGKA = FishingRaritySystem.TIERS.SuperRare,
	SEDANG = FishingRaritySystem.TIERS.Rare,
	BIASA = FishingRaritySystem.TIERS.Common,
}

-- ============ KONFIGURASI BONUS LEMPARAN AWAL ============
local CAST_BONUSES = {
	PERFECT = {
		startBonus = 0.25,      -- +25% Bar Awal
		gainBonus = 0.02,       -- +2% per hit
		penaltyMult = 0.75,     -- Penalti salah berkurang 25%
		label = "⭐ PERFECT CAST (+25% Bar Start)",
		color = Color3.fromRGB(255, 215, 0),
	},
	GREAT = {
		startBonus = 0.12,      -- +12% Bar Awal
		gainBonus = 0.01,
		penaltyMult = 0.90,     -- Penalti salah berkurang 10%
		label = "✨ GREAT CAST (+12% Bar Start)",
		color = Color3.fromRGB(0, 220, 255),
	},
	GOOD = {
		startBonus = 0.00,      -- Standar
		gainBonus = 0.00,
		penaltyMult = 1.00,
		label = "👍 GOOD CAST",
		color = Color3.fromRGB(220, 230, 255),
	},
}

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
local progress = 0.35
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

-- Nilai kalkulasi dinamis untuk ronde aktif
local activeTier = TIER_CONFIGS.BIASA
local activeCast = CAST_BONUSES.GOOD
local activeHitGain = 0.10
local activeComboHitGain = 0.14
local activeMissPenalty = 0.15

-- Referensi GUI
local gui, arenaContainer, arenaFrame, songLabel, tierLabel, castBonusLabel, comboLabel, resultOverlay, resultLabel
local progressContainer, progressFill, progressLabel, progressGlow
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
	if comboLabel then
		if combo >= 2 then
			comboLabel.Text = "🔥 COMBO x" .. combo .. (combo >= 3 and " (+Bonus Tenaga!)" or "")
			comboLabel.Visible = true
		else
			comboLabel.Visible = false
		end
	end

	-- Update Bar Indikator Tangkapan di Bawah
	if progressFill and progressLabel then
		local percent = math.clamp(progress, 0, 1)
		local percentInt = math.floor(percent * 100)

		-- Animasi perubahan panjang bar
		TweenService:Create(progressFill, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(percent, 1)
		}):Play()

		-- Warna dinamis berdasarkan status tarikan
		local barColor = Color3.fromRGB(0, 210, 255)
		if percent >= 0.70 then
			barColor = Color3.fromRGB(50, 250, 130) -- Hijau Kemenangan
		elseif percent <= 0.25 then
			barColor = Color3.fromRGB(255, 65, 65)  -- Merah Bahaya
		else
			barColor = Color3.fromRGB(0, 205, 255)  -- Cyan Stabil
		end

		progressFill.BackgroundColor3 = barColor
		if progressGlow then
			progressGlow.Color = barColor
		end

		progressLabel.Text = "🎣 TARIKAN: " .. percentInt .. "%"
	end
end

local function spawnTile()
	if state ~= "Playing" or progress >= 1.0 or progress <= 0 then return end
	spawnedCount += 1

	local notes = currentMelody.notes
	local semitone = notes[((melodyIndex - 1) % #notes) + 1]
	melodyIndex += 1

	local col = math.random(1, COLUMN_COUNT)
	if col == lastColumn and math.random() < 0.75 then
		col = (col % COLUMN_COUNT) + 1
	end
	lastColumn = col

	local tileColor = activeTier.color or Color3.fromRGB(0, 200, 255)

	local tile = mk("Frame", {
		Name = "Tile_" .. spawnedCount,
		Size = UDim2.fromScale(0.88, TILE_HEIGHT),
		Position = UDim2.new(0.06, 0, -TILE_HEIGHT, 0),
		BackgroundColor3 = tileColor,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, columns[col])
	
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, tile)
	
	local stroke = mk("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1.5,
		Transparency = 0.3,
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

	combo = 0
	progress = math.clamp(progress - activeMissPenalty, 0, 1.0)
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

	-- Cek apakah bar habis (0%) -> Ikan Lepas!
	if progress <= 0 then
		endRound(false, "IKAN TERLEPAS!\n(Tarikan Habis)")
	end
end

local function hitTile(entry)
	local idx = table.find(tiles, entry)
	if idx then
		table.remove(tiles, idx)
	end

	score += 1
	combo += 1

	-- Tambah progress bar sesuai kalkulasi tier & combo aktif
	local gain = (combo >= 3 and activeComboHitGain or activeHitGain)
	progress = math.clamp(progress + gain, 0, 1.0)
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

	-- Jika bar terisi penuh 100%, menang!
	if progress >= 1.0 then
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

	-- Terus spawn tile melodi selama bar belum penuh (100%) dan belum habis (0%)
	spawnAccum += dt
	local interval = TILE_HEIGHT / speed
	while spawnAccum >= interval and progress < 1.0 and progress > 0 and state == "Playing" do
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

-- ============ MEMBANGUN GUI GLASSMORPHISM DENGAN TIER & CAST BADGE ============
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
		Size = UDim2.new(0, 390, 0.88, 0),
		Position = UDim2.new(0.5, -195, 0.06, 0),
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

	-- Header Atas (Nama Lagu, Tier Ikan & Bonus Lemparan)
	local header = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
	}, arenaContainer)

	tierLabel = mk("TextLabel", {
		Name = "TierLabel",
		Size = UDim2.new(0.55, 0, 0, 22),
		Position = UDim2.new(0.04, 0, 0, 6),
		BackgroundTransparency = 1,
		Text = "🌟 IKAN: LEGENDARIS",
		TextColor3 = Color3.fromRGB(255, 215, 0),
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	castBonusLabel = mk("TextLabel", {
		Name = "CastBonusLabel",
		Size = UDim2.new(0.92, 0, 0, 18),
		Position = UDim2.new(0.04, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = "⭐ PERFECT CAST (+25% Bar Start)",
		TextColor3 = Color3.fromRGB(255, 225, 120),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	songLabel = mk("TextLabel", {
		Name = "SongLabel",
		Size = UDim2.new(0.92, 0, 0, 16),
		Position = UDim2.new(0.04, 0, 0, 46),
		BackgroundTransparency = 1,
		Text = "🎵 Melodi: Canon in D",
		TextColor3 = Color3.fromRGB(180, 220, 255),
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	comboLabel = mk("TextLabel", {
		Name = "ComboLabel",
		Size = UDim2.new(0.38, 0, 0, 22),
		Position = UDim2.new(0.58, 0, 0, 6),
		BackgroundTransparency = 1,
		Text = "🔥 COMBO x2",
		TextColor3 = Color3.fromRGB(255, 205, 60),
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Visible = false,
	}, header)

	-- Arena Kolom Piano Tiles
	arenaFrame = mk("Frame", {
		Name = "ArenaColumns",
		Size = UDim2.new(1, 0, 1, -114),
		Position = UDim2.new(0, 0, 0, 68),
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

	-- ============ INDIKATOR BAR TANGKAPAN DI BAGIAN BAWAH ============
	progressContainer = mk("Frame", {
		Name = "ProgressContainer",
		Size = UDim2.new(0.92, 0, 0, 32),
		Position = UDim2.new(0.04, 0, 1, -40),
		BackgroundColor3 = Color3.fromRGB(15, 20, 32),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, arenaContainer)
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, progressContainer)

	progressGlow = mk("UIStroke", {
		Color = Color3.fromRGB(0, 200, 255),
		Thickness = 1.5,
		Transparency = 0.3,
	}, progressContainer)

	progressFill = mk("Frame", {
		Name = "ProgressFill",
		Size = UDim2.fromScale(progress, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 210, 255),
		BorderSizePixel = 0,
	}, progressContainer)
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, progressFill)

	progressLabel = mk("TextLabel", {
		Name = "ProgressLabel",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		Text = "🎣 TARIKAN: 35%",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		ZIndex = 2,
	}, progressContainer)

	-- Overlay Hasil Akhir
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
	local tierKey = tostring(config.tier or "BIASA"):upper()
	local castKey = tostring(config.castQuality or "GOOD"):upper()

	activeTier = TIER_CONFIGS[tierKey] or TIER_CONFIGS.BIASA
	activeCast = CAST_BONUSES[castKey] or CAST_BONUSES.GOOD

	-- 1. Hitung Progress Awal Berdasarkan Tier Ikan & Kualitas Lemparan
	local startProgress = math.clamp(activeTier.baseStart + activeCast.startBonus, 0.12, 0.85)
	progress = startProgress

	-- 2. Hitung Nilai Penambahan & Pengurangan Aktif
	activeHitGain = activeTier.baseHitGain + activeCast.gainBonus
	activeComboHitGain = activeTier.comboHitGain + activeCast.gainBonus
	activeMissPenalty = activeTier.baseMissPenalty * activeCast.penaltyMult

	currentMelody = MELODIES[math.random(1, #MELODIES)]
	speed = math.clamp(config.speed or activeTier.speed or currentMelody.baseSpeed, 0.2, 1.2)
	
	-- Update Tampilan Info Header
	if tierLabel then
		tierLabel.Text = "🐟 IKAN: " .. activeTier.name .. " " .. activeTier.stars
		tierLabel.TextColor3 = activeTier.color
	end
	if castBonusLabel then
		castBonusLabel.Text = activeCast.label
		castBonusLabel.TextColor3 = activeCast.color
	end
	if songLabel then
		songLabel.Text = "🎵 Melodi: " .. currentMelody.name
	end

	roundToken += 1
	winCb, loseCb = onWin, onLose
	score, combo = 0, 0
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
