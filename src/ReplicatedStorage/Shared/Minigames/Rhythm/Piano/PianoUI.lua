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
		-- FEATURE TEMAN: ReceptorPad + KeyLabel
		-- Kalau belum ada, dibuat sementara.
		-- =====================================================
		local receptor = col:FindFirstChild("ReceptorPad")
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

		local keyText = receptor:FindFirstChild("KeyLabel")
		if not keyText then
			keyText = Instance.new("TextLabel")
			keyText.Name = "KeyLabel"
			keyText.Size = UDim2.fromScale(1, 1)
			keyText.BackgroundTransparency = 1
			keyText.Text = (Config.KEY_LABELS and Config.KEY_LABELS[i]) or ({"A", "W", "S", "D"})[i]
			keyText.TextColor3 = Color3.fromRGB(255, 255, 255)
			keyText.Font = Enum.Font.FredokaOne
			keyText.TextSize = 20
			keyText.ZIndex = 13
			keyText.Parent = receptor
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
	-- FEATURE TEMAN: CenterJudgementLabel
	-- Belum ada di GUI user -> dibuat sementara.
	-- =========================================================
	centerJudgementLabel = header
		and header:FindFirstChild("CenterJudgementLabel")
		or nil

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

	hitLine = arenaContainer:FindFirstChild("HitLine")
	perfectZoneGuide = arenaFrame:FindFirstChild("PerfectZoneGuide")
	centerJudgementLabel = arenaFrame:FindFirstChild("CenterJudgementLabel")

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
	return true
end

function PianoUI.SetEnabled(enabled)
	if gui then gui.Enabled = enabled end
end

function PianoUI.GetArenaFrame()
	return arenaFrame
end

function PianoUI.CreateTile(column, y)
	local parent = columns[column]
	if not parent then return nil end

	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.Size = UDim2.new(0.82, 0, Config.TILE_HEIGHT, 0)
	tile.Position = UDim2.new(0.09, 0, y, 0)
	tile.BackgroundColor3 = Color3.fromRGB(0, 162, 232)
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
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.Thickness = 2.5
	glow.Transparency = 0
	glow.Parent = tile

	return tile
end

function PianoUI.MoveTile(tile, y)
	if tile and tile.Parent then
		tile.Position = UDim2.new(0.09, 0, y, 0)
		local glow = tile:FindFirstChild("TileGlow")
		if glow then
			local delta = math.abs(y - Config.HIT_LINE)
			if delta <= 0.05 then
				-- Zone PERFECT: Radiant Gold Glow
				glow.Color = Color3.fromRGB(255, 215, 0)
				glow.Thickness = 3.5
				glow.Transparency = 0
			elseif delta <= 0.09 then
				-- Zone GREAT: Vibrant Cyan Glow
				glow.Color = Color3.fromRGB(0, 240, 255)
				glow.Thickness = 2.5
				glow.Transparency = 0.15
			else
				-- Normal State: Crisp White Outline
				glow.Color = Color3.fromRGB(255, 255, 255)
				glow.Thickness = 2.5
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
	pad.BackgroundColor3 = ratingData.flashColor
	pad.BackgroundTransparency = 0.2

	TweenService:Create(pad, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(0, 162, 232),
		BackgroundTransparency = 0,
	}):Play()
end

function PianoUI.ShowHitRating(ratingKey, column, y)
	print("Rating diterima:", ratingKey)
	print("Label yang dipakai:", centerJudgementLabel)

	if not centerJudgementLabel then
		warn("CenterJudgementLabel tidak ditemukan!")
		return
	end

	local ratingData = getRatingData(ratingKey)
	print("Teks yang akan ditampilkan:", ratingData.symbol)

	centerJudgementLabel.Text = ratingData.symbol
	centerJudgementLabel.TextColor3 = ratingData.color
	centerJudgementLabel.TextTransparency = 0
	centerJudgementLabel.Visible = true
end

function PianoUI.PlayHitEffect(tile, y, ratingKey, column)
	if column then
		PianoUI.TriggerReceptorPress(column, ratingKey)
		PianoUI.FlashColumn(column, ratingKey)
	end
	PianoUI.ShowHitRating(ratingKey, column, y)

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

return PianoUI