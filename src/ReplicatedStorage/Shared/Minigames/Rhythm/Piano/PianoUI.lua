--[[
    PianoUI (ModuleScript)
    FISH!TUNE — Authentic Tropical Fishing × Rhythm Minigame UI (100% Matching Stagging Image)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = ReplicatedStorage:FindFirstChild("PianoTilesConfig")
	and require(ReplicatedStorage.PianoTilesConfig)
	or require(Shared:WaitForChild("Config"):WaitForChild("PianoTilesConfig"))
local AudioEffectsSystem = require(Shared:WaitForChild("Systems"):WaitForChild("AudioEffectsSystem"))
local MobileResponsiveHelper = require(Shared:WaitForChild("Systems"):WaitForChild("MobileResponsiveHelper"))
local KeybindSystem = require(Shared:WaitForChild("Systems"):WaitForChild("KeybindSystem"))

local PianoUI = {}

local gui, arenaContainer, arenaFrame
local castBonusLabel, songLabel, comboLabel, centerJudgementLabel, hitLine, perfectZoneGuide
local resultOverlay, resultLabel, gradeBadgeLabel, gradeTitleLabel, statsDetailLabel, multiplierDetailLabel
local progressContainer, progressFill, progressLabel, progressGlow, fish
local columns, columnFlashes, receptorPads, receptorLabels = {}, {}, {}, {}

local function getPlayerGui()
	local player = Players.LocalPlayer
	return player and (player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5))
end

local DEFAULT_RATINGS = {

	PERFECT = {
		flashColor = Color3.fromRGB(255, 215, 0),
		color = Color3.fromRGB(255, 215, 0),
		symbol = "PERFECT",
		scale = 1.25,
	},

	GREAT = {
		flashColor = Color3.fromRGB(0, 240, 255),
		color = Color3.fromRGB(0, 240, 255),
		symbol = "GREAT",
		scale = 1.15,
	},

	GOOD = {
		flashColor = Color3.fromRGB(0, 220, 255),
		color = Color3.fromRGB(0, 220, 255),
		symbol = "GOOD",
		scale = 1,
	},

	MISS = {
		flashColor = Color3.fromRGB(255, 70, 70),
		color = Color3.fromRGB(255, 70, 70),
		symbol = "MISS",
		scale = 1,
	},

}

local function getRatingData(ratingKey)
	local ratings = Config.HIT_RATINGS or DEFAULT_RATINGS
	return ratings[ratingKey or "GOOD"] or ratings.GOOD or DEFAULT_RATINGS.GOOD
end

local function buildHybridGui(playerGui)
	-- =========================================================
	-- HYBRID GUI MODE
	-- 1. Pakai object yang SUDAH dibuat manual oleh user.
	-- 2. Kalau object fitur teman belum ada, baru dibuat sementara.
	-- 3. Tidak pernah Destroy() / replace PianoTilesGui milik user.
	-- =========================================================

	local screenGui = playerGui:FindFirstChild("PianoTilesGui")
	if not screenGui then
		warn("[PianoUI] PianoTilesGui tidak ditemukan di PlayerGui. Pastikan GUI manual sudah dibuat di StarterGui.")
		return nil
	end

	local container = screenGui:FindFirstChild("ArenaContainer")
	if not container then
		warn("[PianoUI] ArenaContainer tidak ditemukan. GUI manual user harus memiliki ArenaContainer.")
		return nil
	end

	-- Auto-fit ArenaContainer untuk layar HP/Tablet (FISH-037)
	MobileResponsiveHelper.AttachResponsiveScale(container, 520, 480, 1.0, 20)

	local arena = container:FindFirstChild("ArenaFrame")
	if not arena then
		warn("[PianoUI] ArenaFrame tidak ditemukan. GUI manual user harus memiliki ArenaFrame.")
		return nil
	end


	-- =========================================================
	-- EXISTING USER UI: HEADER
	-- Tidak membuat ulang kalau sudah ada.
	-- =========================================================
	local header = container:FindFirstChild("Header")
	if header then
		-- Semua label ini dicari dari Header milik user.
		-- Tidak ada styling/layout yang ditimpa.
	end

	-- Tombol Kustomisasi Keybind di Minigame (FISH-045)
	local settingsBtn = container:FindFirstChild("KeybindSettingsBtn")
	if not settingsBtn then
		settingsBtn = Instance.new("TextButton")
		settingsBtn.Name = "KeybindSettingsBtn"
		settingsBtn.AnchorPoint = Vector2.new(1, 0)
		settingsBtn.Size = UDim2.new(0, 32, 0, 32)
		settingsBtn.Position = UDim2.new(1, -10, 0, 8)
		settingsBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
		settingsBtn.BorderSizePixel = 0
		settingsBtn.Text = "⚙️"
		settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		settingsBtn.Font = Enum.Font.GothamBold
		settingsBtn.TextSize = 16
		settingsBtn.ZIndex = 30
		settingsBtn.Parent = container

		Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 8)
		local sStroke = Instance.new("UIStroke")
		sStroke.Color = Color3.fromRGB(0, 210, 255)
		sStroke.Thickness = 1.2
		sStroke.Transparency = 0.5
		sStroke.Parent = settingsBtn

		settingsBtn.MouseButton1Click:Connect(function()
			local KeybindSettingsUI = require(Shared:WaitForChild("Minigames"):WaitForChild("KeybindSettingsUI"))
			KeybindSettingsUI.Toggle(screenGui)
		end)
	end

	-- =========================================================
	-- EXISTING USER UI: ARENA COLUMNS
	-- =========================================================
	table.clear(columns)
	table.clear(columnFlashes)
	table.clear(receptorPads)
	table.clear(receptorLabels)

	local columnCount = Config.COLUMN_COUNT or 4

	for i = 1, columnCount do
		local col = arena:FindFirstChild("Column" .. i)

		columns[i] = col

		-- =====================================================
		-- FEATURE TEMAN: ColumnFlash
		-- Belum ada di GUI user -> dibuat sementara.
		-- =====================================================
		local flash = col:FindFirstChild("ColumnFlash")
		if not flash then
			flash = Instance.new("Frame")
			flash.Name = "ColumnFlash"
			flash.Size = UDim2.fromScale(1, 1)
			flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			flash.BackgroundTransparency = 1
			flash.BorderSizePixel = 0
			flash.Visible = false
			flash.ZIndex = 20
			flash.Parent = col
		end
		columnFlashes[i] = flash

		-- =====================================================
		-- FEATURE TEMAN: FishingHook
		-- Kalau belum ada, buat sementara.
		-- =====================================================
		local hookHolder = col:FindFirstChild("FishingHook" .. i)
		if not hookHolder then
			hookHolder = Instance.new("Frame")
			hookHolder.Name = "FishingHook" .. i
			hookHolder.Size = UDim2.new(0, 24, 0, 36)
			hookHolder.Position = UDim2.new(0.5, -12, 1, -82)
			hookHolder.BackgroundTransparency = 1
			hookHolder.ZIndex = 11
			hookHolder.Parent = col

			local eyelet = Instance.new("Frame")
			eyelet.Name = "Eyelet"
			eyelet.Size = UDim2.new(0, 8, 0, 8)
			eyelet.Position = UDim2.new(0.5, -4, 0, 0)
			eyelet.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
			eyelet.BorderSizePixel = 0
			eyelet.ZIndex = 11
			eyelet.Parent = hookHolder
			Instance.new("UICorner", eyelet).CornerRadius = UDim.new(1, 0)

			local shank = Instance.new("Frame")
			shank.Name = "Shank"
			shank.Size = UDim2.new(0, 3, 0, 20)
			shank.Position = UDim2.new(0.5, -1.5, 0, 6)
			shank.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
			shank.BorderSizePixel = 0
			shank.ZIndex = 11
			shank.Parent = hookHolder

			local bend = Instance.new("Frame")
			bend.Name = "Bend"
			bend.Size = UDim2.new(0, 16, 0, 14)
			bend.Position = UDim2.new(0.5, -8, 0, 20)
			bend.BackgroundTransparency = 1
			bend.ZIndex = 11
			bend.Parent = hookHolder
			local bendStroke = Instance.new("UIStroke")
			bendStroke.Color = Color3.fromRGB(240, 245, 255)
			bendStroke.Thickness = 2.5
			bendStroke.Parent = bend
			Instance.new("UICorner", bend).CornerRadius = UDim.new(0, 7)
		end

		-- =====================================================
		-- FEATURE RECEPTOR: Re-use Key1..Key4 di ArenaContainer (Studio-authored GUI)
		-- =====================================================
		local studioKey = container:FindFirstChild("Key" .. i) or container:FindFirstChild("Key_" .. i)
		if studioKey then
			studioKey.BackgroundTransparency = 1
			for _, ch in ipairs(studioKey:GetDescendants()) do
				if ch:IsA("GuiObject") and not (ch:IsA("TextLabel") or ch:IsA("TextButton")) then
					ch.BackgroundTransparency = 1
				end
			end
		end

		local receptor = studioKey or col:FindFirstChild("ReceptorPad")
		if studioKey then
			receptor:SetAttribute("IsStudioKey", true)
		end
		if not receptor then
			receptor = Instance.new("Frame")
			receptor.Name = "ReceptorPad"
			receptor.Size = UDim2.new(0.72, 0, 0, 44)
			receptor.Position = UDim2.new(0.14, 0, 1, -54)
			receptor.BackgroundColor3 = Color3.fromRGB(0, 162, 232)
			receptor.BorderSizePixel = 0
			receptor.ZIndex = 12
			receptor.Parent = col
			Instance.new("UICorner", receptor).CornerRadius = UDim.new(0, 8)

			local rAspect = Instance.new("UIAspectRatioConstraint")
			rAspect.AspectRatio = 1
			rAspect.Parent = receptor

			local rStroke = Instance.new("UIStroke")
			rStroke.Color = Color3.fromRGB(255, 255, 255)
			rStroke.Thickness = 2.5
			rStroke.Parent = receptor
		end

		if studioKey == nil then
			local targetNotch = receptor:FindFirstChild("PerfectTargetNotch")
			if not targetNotch then
				targetNotch = Instance.new("Frame")
				targetNotch.Name = "PerfectTargetNotch"
				targetNotch.Size = UDim2.new(0.6, 0, 0, 2)
				targetNotch.Position = UDim2.new(0.2, 0, 0.5, -1)
				targetNotch.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				targetNotch.BackgroundTransparency = 0.3
				targetNotch.BorderSizePixel = 0
				targetNotch.ZIndex = 14
				targetNotch.Parent = receptor
			end
		end

		local keyText = nil
		if receptor:IsA("TextLabel") or receptor:IsA("TextButton") then
			keyText = receptor
		else
			keyText = receptor:FindFirstChild("KeyLabel")
				or receptor:FindFirstChildWhichIsA("TextLabel")
				or receptor:FindFirstChildWhichIsA("TextButton")
				or receptor:FindFirstChild("TextLabel")
				or receptor:FindFirstChild("Label")
		end

		if not keyText then
			for _, child in ipairs(receptor:GetChildren()) do
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					keyText = child
					break
				end
			end
		end

		if not keyText and studioKey == nil then
			keyText = Instance.new("TextLabel")
			keyText.Name = "KeyLabel"
			keyText.Size = UDim2.fromScale(1, 1)
			keyText.BackgroundTransparency = 1
			keyText.TextColor3 = Color3.fromRGB(255, 255, 255)
			keyText.Font = Enum.Font.FredokaOne
			keyText.TextSize = 20
			keyText.ZIndex = 13
			keyText.Parent = receptor
		end

		local activeKeyLabel = KeybindSystem.GetKeyLabel(i)
		if keyText then
			keyText.Text = activeKeyLabel
		end

		-- Update semua TextLabel / TextButton di receptor atau col
		if receptor:IsA("TextLabel") or receptor:IsA("TextButton") then
			receptor.Text = activeKeyLabel
		end
		for _, desc in ipairs(receptor:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextButton") then
				desc.Text = activeKeyLabel
			end
		end
		for _, desc in ipairs(col:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextButton") then
				local name = desc.Name:lower()
				if name:find("key") or name:find("label") or #desc.Text <= 4 then
					desc.Text = activeKeyLabel
				end
			end
		end

		receptorPads[i] = receptor
		receptorLabels[i] = keyText
	end

	-- =========================================================
	-- FEATURE TEMAN: HitLine / PerfectBadge
	-- HitLine milik user diprioritaskan.
	-- =========================================================
	hitLine = container:FindFirstChild("HitLine")
	if not hitLine then
		hitLine = Instance.new("Frame")
		hitLine.Name = "HitLine"
		hitLine.Size = UDim2.new(1, 0, 0, 2)
		hitLine.Position = UDim2.new(0, 0, 0.78, 0)
		hitLine.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		hitLine.BorderSizePixel = 0
		hitLine.ZIndex = 14
		hitLine.Parent = arena
	end

	local perfectBadge = hitLine:FindFirstChild("PerfectBadge")
	if not perfectBadge then
		perfectBadge = Instance.new("TextLabel")
		perfectBadge.Name = "PerfectBadge"
		perfectBadge.Size = UDim2.new(0, 70, 0, 14)
		perfectBadge.Position = UDim2.new(0, 6, 0, -15)
		perfectBadge.BackgroundTransparency = 1
		perfectBadge.Text = "★ PERFECT"
		perfectBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
		perfectBadge.Font = Enum.Font.FredokaOne
		perfectBadge.TextSize = 10
		perfectBadge.TextXAlignment = Enum.TextXAlignment.Left
		perfectBadge.ZIndex = 15
		perfectBadge.Parent = hitLine
	end

	-- =========================================================
	-- FEATURE: CenterJudgementLabel
	-- Prioritaskan label yang sudah ada di GUI Studio (header/arenaFrame/container),
	-- jika belum ada, buat sebagai fallback non-destruktif.
	-- =========================================================
	centerJudgementLabel = (header and (header:FindFirstChild("CenterJudgementLabel") or header:FindFirstChild("JudgementLabel") or header:FindFirstChild("RatingLabel")))
		or (arena:FindFirstChild("CenterJudgementLabel") or arena:FindFirstChild("JudgementLabel") or arena:FindFirstChild("RatingLabel"))
		or (container:FindFirstChild("CenterJudgementLabel", true) or container:FindFirstChild("JudgementLabel", true))

	if not centerJudgementLabel then
		centerJudgementLabel = Instance.new("TextLabel")
		centerJudgementLabel.Name = "CenterJudgementLabel"
		centerJudgementLabel.Size = UDim2.new(0, 220, 0, 40)
		centerJudgementLabel.Position = UDim2.new(0.5, -110, 0.42, 0)
		centerJudgementLabel.BackgroundTransparency = 1
		centerJudgementLabel.Text = ""
		centerJudgementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		centerJudgementLabel.Font = Enum.Font.FredokaOne
		centerJudgementLabel.TextSize = 26
		centerJudgementLabel.ZIndex = 25
		centerJudgementLabel.Visible = false
		centerJudgementLabel.Parent = arena

		local jStroke = Instance.new("UIStroke")
		jStroke.Name = "Stroke"
		jStroke.Color = Color3.fromRGB(0, 0, 0)
		jStroke.Thickness = 2
		jStroke.Transparency = 0.3
		jStroke.Parent = centerJudgementLabel
	end

	-- =========================================================
	-- USER PROGRESS BAR
	-- Jangan replace. Kalau belum ada, baru buat fallback.
	-- =========================================================
	local pBar = container:FindFirstChild("ProgressBar")

	local pFill = pBar:FindFirstChild("Fill")

	local fishIcon = pBar:FindFirstChild("Fish")


	-- =========================================================
	-- USER PROGRESS LABEL / RESULT OVERLAY
	-- =========================================================
	local pLabel = container:FindFirstChild("ProgressLabel")
	if not pLabel then
		pLabel = Instance.new("TextLabel")
		pLabel.Name = "ProgressLabel"
		pLabel.Size = UDim2.new(0, 320, 0, 26)
		pLabel.Position = UDim2.new(0, 185, 0, 468)
		pLabel.BackgroundTransparency = 1
		pLabel.Text = "🎣 PROGRES: 0% • 0/30 NOT"
		pLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		pLabel.Font = Enum.Font.FredokaOne
		pLabel.TextSize = 15
		pLabel.TextXAlignment = Enum.TextXAlignment.Right
		pLabel.Parent = container
	end

	local result = arena:FindFirstChild("ResultOverlay") or container:FindFirstChild("ResultOverlay")
	if not result then
		result = Instance.new("Frame")
		result.Name = "ResultOverlay"
		result.Size = UDim2.fromScale(1, 1)
		result.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
		result.BackgroundTransparency = 0.12
		result.BorderSizePixel = 0
		result.Visible = false
		result.ZIndex = 30
		result.Parent = arena
	end

	local resLabel = result:FindFirstChild("ResultLabel")
	if not resLabel then
		resLabel = Instance.new("TextLabel")
		resLabel.Name = "ResultLabel"
		resLabel.Size = UDim2.new(1, 0, 0, 36)
		resLabel.Position = UDim2.new(0, 0, 0.12, 0)
		resLabel.BackgroundTransparency = 1
		resLabel.Text = "BERHASIL DITANGKAP!"
		resLabel.TextColor3 = Color3.fromRGB(60, 240, 140)
		resLabel.Font = Enum.Font.FredokaOne
		resLabel.TextSize = 22
		resLabel.ZIndex = 32
		resLabel.Parent = result
	end

	return screenGui
end

function PianoUI.Create()
	local playerGui = getPlayerGui()
	if not playerGui then return false end

	-- Jangan Destroy GUI user. Ambil GUI yang sudah ada dan hanya
	-- tambahkan fitur tambahan yang belum tersedia.
	gui = buildHybridGui(playerGui)
	if not gui then return false end

	arenaContainer = gui:FindFirstChild("ArenaContainer")
	if not arenaContainer then return false end

	arenaFrame = arenaContainer:FindFirstChild("ArenaFrame")
	if not arenaFrame then return false end

	hitLine = arenaContainer:FindFirstChild("HitLine") or arenaFrame:FindFirstChild("HitLine")
	perfectZoneGuide = arenaFrame:FindFirstChild("PerfectZoneGuide")
	if not centerJudgementLabel or not centerJudgementLabel.Parent then
		centerJudgementLabel = arenaFrame:FindFirstChild("CenterJudgementLabel")
			or (arenaContainer and arenaContainer:FindFirstChild("CenterJudgementLabel", true))
	end

	castBonusLabel = arenaContainer:FindFirstChild("CastBonusLabel", true)
	songLabel = arenaContainer:FindFirstChild("SongLabel", true)
	comboLabel = arenaContainer:FindFirstChild("ComboLabel", true)

	progressContainer = arenaContainer:FindFirstChild("ProgressBar")
	if progressContainer then
		progressFill = progressContainer:FindFirstChild("Fill")
		fish = progressContainer:FindFirstChild("Fish")
		progressGlow = progressContainer:FindFirstChild("UIStroke")
	end
	progressLabel = arenaContainer:FindFirstChild("ProgressLabel")

	resultOverlay = arenaFrame:FindFirstChild("ResultOverlay") or arenaContainer:FindFirstChild("ResultOverlay", true)
	if resultOverlay then
		resultLabel = resultOverlay:FindFirstChild("ResultLabel")
	end

	gui.Enabled = false
	PianoUI.UpdateKeyLabels()
	return true
end

function PianoUI.SetEnabled(enabled)
	if gui then
		gui.Enabled = enabled
		if enabled then
			PianoUI.UpdateKeyLabels()
		end
	end
end

function PianoUI.GetArenaFrame()
	return arenaFrame
end

function PianoUI.CreateTile(column, y, isChord)
	local parent = columns[column]
	if not parent then return nil end

	local tile = Instance.new("Frame")
	tile.Name = isChord and "ChordTile" or "Tile"
	tile.Size = UDim2.new(0.82, 0, Config.TILE_HEIGHT, 0)
	tile.Position = UDim2.new(0.09, 0, y, 0)
	-- Not sejajar / CHORD berwarna emas bersinar, sedangkan not biasa berwarna biru tropis
	tile.BackgroundColor3 = isChord and Color3.fromRGB(255, 195, 25) or Color3.fromRGB(0, 162, 232)
	tile.BorderSizePixel = 0
	tile.ZIndex = 15
	tile.Parent = parent
	Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 8)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = tile

	local fishImg = Instance.new("ImageLabel")
	fishImg.Name = "FishImage"
	fishImg.Size = UDim2.new(1, 0, 1, 0)
	fishImg.Position = UDim2.new(0, 0, 0, 0)
	fishImg.BackgroundTransparency = 1
	fishImg.Image = (Config.TILE_IMAGES and Config.TILE_IMAGES[column]) or "rbxassetid://81497165860027"
	fishImg.ScaleType = Enum.ScaleType.Fit
	fishImg.BorderSizePixel = 0
	fishImg.ZIndex = 16
	fishImg.Parent = tile

	local glow = Instance.new("UIStroke")
	glow.Name = "TileGlow"
	glow.Color = isChord and Color3.fromRGB(255, 225, 40) or Color3.fromRGB(255, 255, 255)
	glow.Thickness = isChord and 4.0 or 2.5
	glow.Transparency = 0
	glow.Parent = tile

	if isChord then
		tile:SetAttribute("IsChord", true)

		-- Badge "✦ CHORD ✦" mencolok pada not sejajar
		local chordBadge = Instance.new("TextLabel")
		chordBadge.Name = "ChordBadge"
		chordBadge.Size = UDim2.new(1, 0, 0, 14)
		chordBadge.Position = UDim2.new(0, 0, 1, -16)
		chordBadge.BackgroundTransparency = 1
		chordBadge.Text = "✦ CHORD ✦"
		chordBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		chordBadge.TextStrokeColor3 = Color3.fromRGB(180, 100, 0)
		chordBadge.TextStrokeTransparency = 0
		chordBadge.Font = Enum.Font.GothamBold
		chordBadge.TextSize = 10
		chordBadge.ZIndex = 19
		chordBadge.Parent = tile
	end

	return tile
end

function PianoUI.CreateHoldTile(column, y, tailLength)
	local parent = columns[column]
	if not parent then return nil end

	tailLength = math.max(0.18, tailLength or 0.40)
	local tileHeight = Config.TILE_HEIGHT or 0.16

	-- Container frame untuk not tahan
	local holdTile = Instance.new("Frame")
	holdTile.Name = "HoldTile"
	holdTile.Size = UDim2.new(0.82, 0, tileHeight, 0)
	holdTile.Position = UDim2.new(0.09, 0, y, 0)
	holdTile.BackgroundTransparency = 1
	holdTile.BorderSizePixel = 0
	holdTile.ZIndex = 15
	holdTile.Parent = parent

	-- Konversi tailLength (skala arena/kolom) ke skala child di dalam holdTile
	local tailScaleInHold = tailLength / tileHeight

	-- 1. Hold Tail (Ekor pita neon menyala panjang ke atas)
	local tail = Instance.new("Frame")
	tail.Name = "HoldTail"
	tail.Size = UDim2.new(0.60, 0, tailScaleInHold, 0)
	tail.Position = UDim2.new(0.20, 0, -tailScaleInHold + 0.15, 0)
	tail.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	tail.BackgroundTransparency = 0.25
	tail.BorderSizePixel = 0
	tail.ZIndex = 14
	tail.Parent = holdTile
	Instance.new("UICorner", tail).CornerRadius = UDim.new(0, 8)

	local tailStroke = Instance.new("UIStroke")
	tailStroke.Name = "TailStroke"
	tailStroke.Color = Color3.fromRGB(180, 245, 255)
	tailStroke.Thickness = 2.5
	tailStroke.Transparency = 0.1
	tailStroke.Parent = tail

	local tailGrad = Instance.new("UIGradient")
	tailGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0, 180, 240)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 120, 200)),
	})
	tailGrad.Rotation = 90
	tailGrad.Parent = tail

	-- 2. Tail Cap (Ujung ekor bercahaya mutiara)
	local cap = Instance.new("Frame")
	cap.Name = "TailCap"
	cap.Size = UDim2.new(1.25, 0, 0, 12)
	cap.Position = UDim2.new(-0.125, 0, 0, -6)
	cap.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cap.BorderSizePixel = 0
	cap.ZIndex = 16
	cap.Parent = tail
	Instance.new("UICorner", cap).CornerRadius = UDim.new(1, 0)
	local capStroke = Instance.new("UIStroke")
	capStroke.Color = Color3.fromRGB(0, 230, 255)
	capStroke.Thickness = 2
	capStroke.Parent = cap

	-- 3. Head Tile (Kepala tuts penekan)
	local head = Instance.new("Frame")
	head.Name = "HeadTile"
	head.Size = UDim2.new(1, 0, 1, 0)
	head.Position = UDim2.new(0, 0, 0, 0)
	head.BackgroundColor3 = Color3.fromRGB(0, 175, 245)
	head.BorderSizePixel = 0
	head.ZIndex = 17
	head.Parent = holdTile
	Instance.new("UICorner", head).CornerRadius = UDim.new(0, 8)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = head

	local fishImg = Instance.new("ImageLabel")
	fishImg.Name = "FishImage"
	fishImg.Size = UDim2.new(0.75, 0, 0.75, 0)
	fishImg.Position = UDim2.new(0.125, 0, 0.125, 0)
	fishImg.BackgroundTransparency = 1
	fishImg.Image = (Config.TILE_IMAGES and Config.TILE_IMAGES[column]) or "rbxassetid://81497165860027"
	fishImg.ScaleType = Enum.ScaleType.Fit
	fishImg.BorderSizePixel = 0
	fishImg.ZIndex = 18
	fishImg.Parent = head

	-- Label "★ HOLD ★" mencolok di kepala tuts
	local holdBadge = Instance.new("TextLabel")
	holdBadge.Name = "HoldBadge"
	holdBadge.Size = UDim2.new(1, 0, 0, 14)
	holdBadge.Position = UDim2.new(0, 0, 1, -16)
	holdBadge.BackgroundTransparency = 1
	holdBadge.Text = "★ HOLD ★"
	holdBadge.TextColor3 = Color3.fromRGB(255, 235, 100)
	holdBadge.TextStrokeColor3 = Color3.fromRGB(0, 40, 80)
	holdBadge.TextStrokeTransparency = 0
	holdBadge.Font = Enum.Font.GothamBold
	holdBadge.TextSize = 10
	holdBadge.ZIndex = 19
	holdBadge.Parent = head

	local glow = Instance.new("UIStroke")
	glow.Name = "TileGlow"
	glow.Color = Color3.fromRGB(255, 230, 80)
	glow.Thickness = 3.5
	glow.Transparency = 0
	glow.Parent = head

	return holdTile
end

function PianoUI.UpdateHoldTile(holdTile, y, initialTailLength, isHolding, remainingRatio)
	if not holdTile or not holdTile.Parent then return end
	initialTailLength = math.max(0.18, initialTailLength or 0.40)
	remainingRatio = math.clamp(remainingRatio or 1.0, 0, 1.0)
	local tileHeight = Config.TILE_HEIGHT or 0.16

	local tail = holdTile:FindFirstChild("HoldTail")
	local head = holdTile:FindFirstChild("HeadTile")
	local glow = head and head:FindFirstChild("TileGlow")

	local fullTailScale = initialTailLength / tileHeight

	if not isHolding then
		-- Falling downwards normally
		holdTile.Position = UDim2.new(0.09, 0, y, 0)
		if tail then
			tail.Size = UDim2.new(0.60, 0, fullTailScale, 0)
			tail.Position = UDim2.new(0.20, 0, -fullTailScale + 0.15, 0)
		end
		if glow then
			local delta = math.abs(y - Config.HIT_LINE)
			if delta <= 0.05 then
				glow.Color = Color3.fromRGB(255, 215, 0)
				glow.Thickness = 4.0
			else
				glow.Color = Color3.fromRGB(255, 230, 80)
				glow.Thickness = 3.0
			end
		end
	else
		-- Actively being held: head locks onto HIT_LINE, tail shrinks smoothly
		holdTile.Position = UDim2.new(0.09, 0, Config.HIT_LINE, 0)
		local curTailScale = fullTailScale * remainingRatio
		if tail then
			tail.Size = UDim2.new(0.60, 0, curTailScale, 0)
			tail.Position = UDim2.new(0.20, 0, -curTailScale + 0.15, 0)
			tail.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			tail.BackgroundTransparency = 0.15
			local tailStroke = tail:FindFirstChild("TailStroke")
			if tailStroke then
				tailStroke.Color = Color3.fromRGB(255, 245, 160)
				tailStroke.Transparency = 0
			end
		end
		if glow then
			glow.Color = Color3.fromRGB(255, 215, 0)
			glow.Thickness = 4.5
		end
	end
end

function PianoUI.MoveTile(tile, y)
	if tile and tile.Parent then
		tile.Position = UDim2.new(0.09, 0, y, 0)
		local isChord = tile:GetAttribute("IsChord") == true
		local glow = tile:FindFirstChild("TileGlow")
		if glow then
			local delta = math.abs(y - Config.HIT_LINE)
			if delta <= 0.05 then
				-- Zone PERFECT: Radiant Gold Glow
				glow.Color = Color3.fromRGB(255, 215, 0)
				glow.Thickness = isChord and 4.5 or 3.5
				glow.Transparency = 0
			elseif delta <= 0.09 then
				-- Zone GREAT: Vibrant Cyan Glow
				glow.Color = isChord and Color3.fromRGB(255, 235, 80) or Color3.fromRGB(0, 240, 255)
				glow.Thickness = isChord and 4.0 or 2.5
				glow.Transparency = 0.1
			else
				-- Normal State: Tetap Emas Menyala untuk Chord, Putih untuk Tap
				glow.Color = isChord and Color3.fromRGB(255, 225, 40) or Color3.fromRGB(255, 255, 255)
				glow.Thickness = isChord and 3.5 or 2.5
				glow.Transparency = 0
			end
		end
	end
end

function PianoUI.DestroyTile(tile)
	if tile and tile.Parent then tile:Destroy() end
end

function PianoUI.TriggerReceptorPress(column, ratingKey)
	local pad = receptorPads[column]
	if not pad then return end

	local ratingData = getRatingData(ratingKey)
	if pad:GetAttribute("IsStudioKey") or pad:IsA("ImageLabel") or pad:IsA("ImageButton") then
		pad.BackgroundTransparency = 1
		local origColor = pad:GetAttribute("OrigImageColor")
		if not origColor and (pad:IsA("ImageLabel") or pad:IsA("ImageButton")) then
			origColor = pad.ImageColor3
			pad:SetAttribute("OrigImageColor", origColor)
		end
		if pad:IsA("ImageLabel") or pad:IsA("ImageButton") then
			pad.ImageColor3 = ratingData.flashColor
			TweenService:Create(pad, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageColor3 = origColor or Color3.fromRGB(255, 255, 255),
			}):Play()
		end
	else
		pad.BackgroundColor3 = ratingData.flashColor
		pad.BackgroundTransparency = 0.2

		TweenService:Create(pad, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(0, 162, 232),
			BackgroundTransparency = 0,
		}):Play()
	end
end

function PianoUI.ShowHitRating(ratingKey, column, y)
	if not centerJudgementLabel or not centerJudgementLabel.Parent then
		centerJudgementLabel = (arenaFrame and arenaFrame:FindFirstChild("CenterJudgementLabel"))
			or (arenaContainer and arenaContainer:FindFirstChild("CenterJudgementLabel", true))
		if not centerJudgementLabel then return end
	end

	local ratingData = getRatingData(ratingKey)
	centerJudgementLabel.Text = ratingData.symbol or tostring(ratingKey)
	centerJudgementLabel.TextColor3 = ratingData.color or Color3.fromRGB(255, 255, 255)
	centerJudgementLabel.TextTransparency = 0
	centerJudgementLabel.Visible = true

	local stroke = centerJudgementLabel:FindFirstChild("Stroke") or centerJudgementLabel:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Transparency = 0.2 end

	-- Animasi Punch & Fade Out Halus
	local popTween = TweenService:Create(centerJudgementLabel, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = math.floor(26 * (ratingData.scale or 1.15)),
	})
	popTween:Play()

	task.delay(0.28, function()
		if centerJudgementLabel and centerJudgementLabel.Text == (ratingData.symbol or tostring(ratingKey)) then
			local fade = TweenService:Create(centerJudgementLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1,
				TextSize = 26,
			})
			fade:Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Transparency = 1,
				}):Play()
			end
		end
	end)
end

function PianoUI.TriggerHoldActive(column, isHolding)
	local pad = receptorPads[column]
	if not pad then return end

	if pad:GetAttribute("IsStudioKey") or pad:IsA("ImageLabel") or pad:IsA("ImageButton") then
		pad.BackgroundTransparency = 1
		local origColor = pad:GetAttribute("OrigImageColor")
		if not origColor and (pad:IsA("ImageLabel") or pad:IsA("ImageButton")) then
			origColor = pad.ImageColor3
			pad:SetAttribute("OrigImageColor", origColor)
		end
		if pad:IsA("ImageLabel") or pad:IsA("ImageButton") then
			if isHolding then
				pad.ImageColor3 = Color3.fromRGB(255, 235, 120)
			else
				TweenService:Create(pad, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageColor3 = origColor or Color3.fromRGB(255, 255, 255),
				}):Play()
			end
		end
	else
		if isHolding then
			pad.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			pad.BackgroundTransparency = 0.1
		else
			TweenService:Create(pad, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(0, 162, 232),
				BackgroundTransparency = 0,
			}):Play()
		end
	end
end

function PianoUI.PlayHoldComplete(holdTile, column)
	if column then
		PianoUI.TriggerHoldActive(column, false)
		PianoUI.TriggerReceptorPress(column, "HOLD_OK")
		PianoUI.FlashColumn(column, "HOLD_OK")
	end
	PianoUI.ShowHitRating("HOLD_OK", column, Config.HIT_LINE)
	AudioEffectsSystem.PlayNoteHit("PERFECT")

	if holdTile and holdTile.Parent then
		local tween = TweenService:Create(holdTile, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = holdTile.Position - UDim2.new(0, 0, 0.03, 0)
		})
		tween:Play()
		tween.Completed:Once(function()
			if holdTile and holdTile.Parent then holdTile:Destroy() end
		end)
	end
end

function PianoUI.PlayHoldDrop(holdTile, column)
	if column then
		PianoUI.TriggerHoldActive(column, false)
		PianoUI.TriggerReceptorPress(column, "HOLD_DROPPED")
		PianoUI.FlashColumn(column, "HOLD_DROPPED")
	end
	PianoUI.ShowHitRating("HOLD_DROPPED", column, Config.HIT_LINE)
	PianoUI.ShakeArena()

	if holdTile and holdTile.Parent then
		local tail = holdTile:FindFirstChild("HoldTail")
		if tail then
			tail.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		end
		task.delay(0.12, function()
			if holdTile and holdTile.Parent then holdTile:Destroy() end
		end)
	end
end

function PianoUI.PlayChordSync(column1, column2)
	if column1 then
		PianoUI.TriggerReceptorPress(column1, "CHORD_SYNC")
		PianoUI.FlashColumn(column1, "CHORD_SYNC")
	end
	if column2 then
		PianoUI.TriggerReceptorPress(column2, "CHORD_SYNC")
		PianoUI.FlashColumn(column2, "CHORD_SYNC")
	end
	PianoUI.ShowHitRating("CHORD_SYNC", column1, Config.HIT_LINE)
	AudioEffectsSystem.PlayNoteHit("PERFECT")
end

function PianoUI.PlayHitEffect(tile, y, ratingKey, column)
	if column then
		PianoUI.TriggerReceptorPress(column, ratingKey)
		PianoUI.FlashColumn(column, ratingKey)
	end
	PianoUI.ShowHitRating(ratingKey, column, y)
	AudioEffectsSystem.PlayNoteHit(ratingKey)

	if tile and tile.Parent then
		local tween = TweenService:Create(tile, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.98, 0, Config.TILE_HEIGHT * 1.25, 0),
			Position = UDim2.new(0.01, 0, y - 0.02, 0),
		})
		tween:Play()
		tween.Completed:Once(function()
			if tile and tile.Parent then tile:Destroy() end
		end)
	end
end

function PianoUI.FlashColumn(column, ratingKey)
	local flash = columnFlashes[column]
	if not flash then return end
	local ratingData = getRatingData(ratingKey or "MISS")

	flash.BackgroundColor3 = ratingData.flashColor
	flash.BackgroundTransparency = (ratingKey == "MISS" and 0.40 or 0.60)
	flash.Visible = true

	local tween = TweenService:Create(flash, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})
	tween:Play()
	task.delay(0.20, function()
		if flash and flash.Parent then flash.Visible = false end
	end)
end

function PianoUI.UpdateHUD(progress, combo, currentNotes, targetNotes, liveMetrics)
	if comboLabel then
		if combo and combo >= 2 then
			comboLabel.Text = string.format("x%d", combo)
			comboLabel.Visible = true
		else
			comboLabel.Visible = false
		end
	end

	local percent = math.clamp(progress or 0, 0, 1)

	if progressFill then
		local percent = math.clamp(progress or 0, 0, 1)

		-- JANGAN ubah posisi X
		-- Fill tetap berada di posisi desain Studio

		progressFill.AnchorPoint = Vector2.new(0, 0)
		progressFill.Position = UDim2.new(
			0.45, 0,
			0, 0
		)

		TweenService:Create(
			progressFill,
			TweenInfo.new(
				0.4,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Size = UDim2.new(
					0.07, 0,
					1 - percent, 0
				),
			}
		):Play()
	end


	if fish then

		TweenService:Create(
			fish,

			TweenInfo.new(
				0.4,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Position = UDim2.fromScale(
					fish.Position.X.Scale,
					1 - percent
				)
			}

		):Play()

	end

	if progressLabel then

		local percent =
			math.clamp(progress, 0, 1)

		local percentInt =
			math.floor(percent * 100)

		progressLabel.Text =
			string.format(
				"%d%% \n\n%d/%d",
				percentInt,
				currentNotes or 0,
				targetNotes or 0
			)

	end
end

function PianoUI.UpdateHeader(castLabel, castColor, melodyName)
	if castBonusLabel then
		castBonusLabel.Text = "✨ " .. tostring(castLabel or "PERFECT CAST")
		castBonusLabel.TextColor3 = castColor or Color3.fromRGB(255, 255, 255)
	end
	if songLabel then
		songLabel.Text = "🎵 " .. tostring(melodyName or "RIVER FLOWS IN YOU"):upper()
	end
end

function PianoUI.ShakeArena()
	if not arenaContainer then return end
	local orig = arenaContainer.Position
	local tween = TweenService:Create(arenaContainer, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {
		Position = orig + UDim2.new(0, math.random(-6, 6), 0, math.random(-3, 3))
	})
	tween:Play()
	task.delay(0.2, function()
		if arenaContainer then arenaContainer.Position = orig end
	end)
end

function PianoUI.ShowResult(win, message, performance)
	if not resultOverlay or not resultLabel then return end
	resultLabel.Text = message or (win and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!")
	resultLabel.TextColor3 = win and Color3.fromRGB(60, 240, 140) or Color3.fromRGB(255, 70, 70)
	resultOverlay.Visible = true
end

function PianoUI.HideResult()
	if resultOverlay then resultOverlay.Visible = false end
end

-- ============ DYNAMIC KEYBIND LABELS (FISH-045) ============
local function formatKeyText(originalText, newKey)
	if originalText and (originalText:find("%[") or originalText:find("%]")) then
		return "[" .. newKey .. "]"
	end
	return newKey
end

function PianoUI.UpdateKeyLabels()
	local pGui = getPlayerGui()
	local screenGui = (gui and gui.Parent and gui) or (pGui and pGui:FindFirstChild("PianoTilesGui"))
	if screenGui then
		local container = screenGui:FindFirstChild("ArenaContainer") or screenGui:FindFirstChildWhichIsA("Frame")
		if container then
			local arena = container:FindFirstChild("ArenaFrame") or container
			for i = 1, 4 do
				local newLabel = KeybindSystem.GetKeyLabel(i)

				-- 1. Studio-authored GUI: Update Key1..Key4 langsung di ArenaContainer
				local studioKey = container:FindFirstChild("Key" .. i) or container:FindFirstChild("Key_" .. i)
				if studioKey then
					studioKey.BackgroundTransparency = 1
					for _, ch in ipairs(studioKey:GetDescendants()) do
						if ch:IsA("GuiObject") and not (ch:IsA("TextLabel") or ch:IsA("TextButton")) then
							ch.BackgroundTransparency = 1
						end
					end
					if studioKey:IsA("TextLabel") or studioKey:IsA("TextButton") then
						studioKey.Text = formatKeyText(studioKey.Text, newLabel)
					end
					for _, desc in ipairs(studioKey:GetDescendants()) do
						if desc:IsA("TextLabel") or desc:IsA("TextButton") then
							desc.Text = formatKeyText(desc.Text, newLabel)
						end
					end
				end

				-- 2. Cached receptor pad
				local receptor = receptorPads[i]
				if receptor and receptor ~= studioKey then
					if receptor:IsA("TextLabel") or receptor:IsA("TextButton") then
						receptor.Text = formatKeyText(receptor.Text, newLabel)
					end
					for _, desc in ipairs(receptor:GetDescendants()) do
						if desc:IsA("TextLabel") or desc:IsA("TextButton") then
							desc.Text = formatKeyText(desc.Text, newLabel)
						end
					end
				end

				-- 3. Cek di dalam arena columns jika ada
				local col = (columns and columns[i])
					or (arena and (arena:FindFirstChild("Column" .. i)
						or arena:FindFirstChild("Column_" .. i)
						or arena:FindFirstChild("Col" .. i)
						or arena:FindFirstChild("Lane" .. i)))
				if col then
					local colReceptor = col:FindFirstChild("ReceptorPad")
						or col:FindFirstChild("Receptor")
						or col:FindFirstChild("HitZone")
						or col:FindFirstChild("Pad")

					if colReceptor and colReceptor ~= receptor and colReceptor ~= studioKey then
						if colReceptor:IsA("TextLabel") or colReceptor:IsA("TextButton") then
							colReceptor.Text = formatKeyText(colReceptor.Text, newLabel)
						end
						for _, child in ipairs(colReceptor:GetChildren()) do
							if child:IsA("TextLabel") or child:IsA("TextButton") then
								child.Text = formatKeyText(child.Text, newLabel)
							end
						end
					end

					for _, desc in ipairs(col:GetDescendants()) do
						if desc:IsA("TextLabel") or desc:IsA("TextButton") then
							local name = desc.Name:lower()
							local text = desc.Text
							local isKeyCandidate = name:find("key") or name:find("label") or name:find("receptor") or name:find("pad") or #text <= 4
							if isKeyCandidate then
								desc.Text = formatKeyText(text, newLabel)
							end
						end
					end
				end
			end
		end
	end

	-- Update array cached receptorLabels
	if receptorLabels then
		for i = 1, 4 do
			local lbl = receptorLabels[i]
			if lbl then
				lbl.Text = formatKeyText(lbl.Text, KeybindSystem.GetKeyLabel(i))
			end
		end
	end
end

-- Inisialisasi awal saat script diload dan listener ChildAdded jika PianoTilesGui dimuat belakangan
task.defer(function()
	PianoUI.UpdateKeyLabels()
	local pGui = getPlayerGui()
	if pGui then
		pGui.ChildAdded:Connect(function(child)
			if child.Name == "PianoTilesGui" then
				task.defer(PianoUI.UpdateKeyLabels)
			end
		end)
	end
end)

-- Dengarkan perubahan keybind secara realtime agar ReceptorPad langsung update seketika
KeybindSystem.OnKeybindsChanged:Connect(function()
	PianoUI.UpdateKeyLabels()
end)

return PianoUI