--[[
    PianoUI (ModuleScript)
    FISH!TUNE — High-Contrast Modern Piano Tiles Rhythm Minigame UI
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared:WaitForChild("Config"):WaitForChild("PianoConfig"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))

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

local function buildDynamicGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PianoTilesGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "ArenaContainer"
	container.Size = UDim2.new(0, 380, 0, 530)
	container.Position = UDim2.new(0.5, -190, 0.5, -265)
	container.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	container.BackgroundTransparency = 0.12
	container.BorderSizePixel = 0
	container.Parent = screenGui
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 18)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(0, 210, 255)
	cStroke.Thickness = 2.5
	cStroke.Transparency = 0.2
	cStroke.Parent = container

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundTransparency = 1
	header.Parent = container

	local castPill = Instance.new("Frame")
	castPill.Name = "CastPill"
	castPill.Size = UDim2.new(0.30, 0, 0, 26)
	castPill.Position = UDim2.new(0.03, 0, 0, 6)
	castPill.BackgroundColor3 = Color3.fromRGB(20, 36, 45)
	castPill.BackgroundTransparency = 0.2
	castPill.BorderSizePixel = 0
	castPill.Parent = header
	Instance.new("UICorner", castPill).CornerRadius = UDim.new(0, 13)

	local castBonus = Instance.new("TextLabel")
	castBonus.Name = "CastBonusLabel"
	castBonus.Size = UDim2.fromScale(1, 1)
	castBonus.BackgroundTransparency = 1
	castBonus.Text = "✨ PERFECT"
	castBonus.TextColor3 = Color3.fromRGB(60, 255, 150)
	castBonus.Font = Enum.Font.GothamBlack
	castBonus.TextSize = 11
	castBonus.Parent = castPill

	local instPill = Instance.new("Frame")
	instPill.Name = "InstrumentPill"
	instPill.Size = UDim2.new(0.32, 0, 0, 26)
	instPill.Position = UDim2.new(0.34, 0, 0, 6)
	instPill.BackgroundColor3 = Color3.fromRGB(18, 30, 48)
	instPill.BackgroundTransparency = 0.2
	instPill.BorderSizePixel = 0
	instPill.Parent = header
	Instance.new("UICorner", instPill).CornerRadius = UDim.new(0, 13)

	local instBadge = Instance.new("TextLabel")
	instBadge.Name = "InstrumentBadgeLabel"
	instBadge.Size = UDim2.fromScale(1, 1)
	instBadge.BackgroundTransparency = 1
	instBadge.Text = "🎹 PIANO"
	instBadge.TextColor3 = Color3.fromRGB(0, 210, 255)
	instBadge.Font = Enum.Font.GothamBlack
	instBadge.TextSize = 11
	instBadge.Parent = instPill

	local songPill = Instance.new("Frame")
	songPill.Name = "SongPill"
	songPill.Size = UDim2.new(0.30, 0, 0, 26)
	songPill.Position = UDim2.new(0.67, 0, 0, 6)
	songPill.BackgroundColor3 = Color3.fromRGB(18, 28, 48)
	songPill.BackgroundTransparency = 0.2
	songPill.BorderSizePixel = 0
	songPill.Parent = header
	Instance.new("UICorner", songPill).CornerRadius = UDim.new(0, 13)

	local song = Instance.new("TextLabel")
	song.Name = "SongLabel"
	song.Size = UDim2.fromScale(1, 1)
	song.BackgroundTransparency = 1
	song.Text = "🎵 Canon in D"
	song.TextColor3 = Color3.fromRGB(210, 240, 255)
	song.Font = Enum.Font.GothamBold
	song.TextSize = 11
	song.TextTruncate = Enum.TextTruncate.AtEnd
	song.Parent = songPill

	local combo = Instance.new("TextLabel")
	combo.Name = "ComboLabel"
	combo.Size = UDim2.new(1, 0, 0, 22)
	combo.Position = UDim2.new(0, 0, 0, 36)
	combo.BackgroundTransparency = 1
	combo.Text = "COMBO x0"
	combo.TextColor3 = Color3.fromRGB(255, 215, 0)
	combo.Font = Enum.Font.GothamBlack
	combo.TextSize = 16
	combo.Visible = false
	combo.Parent = header

	local arena = Instance.new("Frame")
	arena.Name = "ArenaFrame"
	arena.Size = UDim2.new(0.92, 0, 0.67, 0)
	arena.Position = UDim2.new(0.04, 0, 0, 62)
	arena.BackgroundColor3 = Color3.fromRGB(8, 14, 24)
	arena.BackgroundTransparency = 0.35
	arena.BorderSizePixel = 0
	arena.ClipsDescendants = true
	arena.Parent = container
	Instance.new("UICorner", arena).CornerRadius = UDim.new(0, 12)

	for i = 1, Config.COLUMN_COUNT do
		local col = Instance.new("Frame")
		col.Name = "Column" .. i
		col.Size = UDim2.new(1 / Config.COLUMN_COUNT, 0, 1, 0)
		col.Position = UDim2.new((i - 1) / Config.COLUMN_COUNT, 0, 0, 0)
		col.BackgroundTransparency = (i % 2 == 0) and 0.94 or 0.98
		col.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		col.BorderSizePixel = 0
		col.Parent = arena

		if i < Config.COLUMN_COUNT then
			local divider = Instance.new("Frame")
			divider.Name = "Divider" .. i
			divider.Size = UDim2.new(0, 1, 1, 0)
			divider.Position = UDim2.new(i / Config.COLUMN_COUNT, -0.5, 0, 0)
			divider.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
			divider.BackgroundTransparency = 0.6
			divider.BorderSizePixel = 0
			divider.ZIndex = 8
			divider.Parent = arena
		end
	end

	local pZoneBand = Instance.new("Frame")
	pZoneBand.Name = "PerfectZoneGuide"
	pZoneBand.Size = UDim2.new(1, 0, Config.TILE_HEIGHT, 0)
	pZoneBand.Position = UDim2.new(0, 0, Config.HIT_LINE, 0)
	pZoneBand.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
	pZoneBand.BackgroundTransparency = 0.92
	pZoneBand.BorderSizePixel = 0
	pZoneBand.ZIndex = 9
	pZoneBand.Parent = arena

	local hLine = Instance.new("Frame")
	hLine.Name = "HitLine"
	hLine.Size = UDim2.new(1, 0, 0, 3)
	hLine.Position = UDim2.new(0, 0, Config.HIT_LINE, 0)
	hLine.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
	hLine.BorderSizePixel = 0
	hLine.ZIndex = 14
	hLine.Parent = arena

	local keyLabels = Config.KEY_LABELS or { "A", "W", "S", "D" }
	for i = 1, Config.COLUMN_COUNT do
		local col = arena:FindFirstChild("Column" .. i)
		if col then
			local receptor = Instance.new("Frame")
			receptor.Name = "ReceptorPad"
			receptor.Size = UDim2.new(0.88, 0, Config.TILE_HEIGHT, 0)
			receptor.Position = UDim2.new(0.06, 0, Config.HIT_LINE, 0)
			receptor.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
			receptor.BackgroundTransparency = 0.85
			receptor.BorderSizePixel = 0
			receptor.ZIndex = 11
			receptor.Parent = col
			Instance.new("UICorner", receptor).CornerRadius = UDim.new(0, 8)

			local rAspect = Instance.new("UIAspectRatioConstraint")
			rAspect.AspectRatio = 1
			rAspect.Parent = receptor

			local rStroke = Instance.new("UIStroke")
			rStroke.Color = Color3.fromRGB(0, 220, 255)
			rStroke.Thickness = 2
			rStroke.Transparency = 0.3
			rStroke.Parent = receptor

			local keyText = Instance.new("TextLabel")
			keyText.Name = "KeyLabel"
			keyText.Size = UDim2.fromScale(1, 1)
			keyText.BackgroundTransparency = 1
			keyText.Text = "[" .. (keyLabels[i] or tostring(i)) .. "]"
			keyText.TextColor3 = Color3.fromRGB(240, 250, 255)
			keyText.Font = Enum.Font.GothamBlack
			keyText.TextSize = 16
			keyText.ZIndex = 12
			keyText.Parent = receptor

			local ktStroke = Instance.new("UIStroke")
			ktStroke.Color = Color3.fromRGB(0, 0, 0)
			ktStroke.Thickness = 2
			ktStroke.Transparency = 0.2
			ktStroke.Parent = keyText
		end
	end

	local centerJudge = Instance.new("TextLabel")
	centerJudge.Name = "CenterJudgementLabel"
	centerJudge.Size = UDim2.new(0.9, 0, 0, 38)
	centerJudge.Position = UDim2.new(0.5, 0, 0.44, 0)
	centerJudge.AnchorPoint = Vector2.new(0.5, 0.5)
	centerJudge.BackgroundTransparency = 1
	centerJudge.Font = Enum.Font.GothamBlack
	centerJudge.TextSize = 24
	centerJudge.TextColor3 = Color3.fromRGB(255, 215, 0)
	centerJudge.Text = ""
	centerJudge.ZIndex = 40
	centerJudge.Parent = arena

	-- Progress Bar
	local pBar = Instance.new("Frame")
	pBar.Name = "ProgressBar"
	pBar.Size = UDim2.new(0.92, 0, 0, 18)
	pBar.Position = UDim2.new(0.04, 0, 0.815, 0)
	pBar.BackgroundColor3 = Color3.fromRGB(16, 24, 38)
	pBar.BorderSizePixel = 0
	pBar.Parent = container
	Instance.new("UICorner", pBar).CornerRadius = UDim.new(0, 9)

	local pFill = Instance.new("Frame")
	pFill.Name = "Fill"
	pFill.Size = UDim2.new(0.1, 0, 1, 0)
	pFill.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	pFill.BorderSizePixel = 0
	pFill.Parent = pBar
	Instance.new("UICorner", pFill).CornerRadius = UDim.new(0, 9)

	local fishIcon = Instance.new("TextLabel")
	fishIcon.Name = "Fish"
	fishIcon.Size = UDim2.new(0, 24, 0, 24)
	fishIcon.Position = UDim2.new(0.1, -12, 0.5, -12)
	fishIcon.BackgroundTransparency = 1
	fishIcon.Text = "🐟"
	fishIcon.TextSize = 16
	fishIcon.ZIndex = 5
	fishIcon.Parent = pBar

	local pLabel = Instance.new("TextLabel")
	pLabel.Name = "ProgressLabel"
	pLabel.Size = UDim2.new(0.92, 0, 0, 22)
	pLabel.Position = UDim2.new(0.04, 0, 0.88, 0)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "🎣 Progres: 0%  •  0 / 30 Not  •  🎯 Akurasi: 100%"
	pLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
	pLabel.Font = Enum.Font.GothamBold
	pLabel.TextSize = 12
	pLabel.Parent = container

	local result = Instance.new("Frame")
	result.Name = "ResultOverlay"
	result.Size = UDim2.fromScale(1, 1)
	result.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	result.BackgroundTransparency = 0.12
	result.BorderSizePixel = 0
	result.Visible = false
	result.ZIndex = 30
	result.Parent = container
	Instance.new("UICorner", result).CornerRadius = UDim.new(0, 18)

	local resLabel = Instance.new("TextLabel")
	resLabel.Name = "ResultLabel"
	resLabel.Size = UDim2.new(1, 0, 0, 36)
	resLabel.Position = UDim2.new(0, 0, 0.12, 0)
	resLabel.BackgroundTransparency = 1
	resLabel.Text = "BERHASIL DITANGKAP!"
	resLabel.TextColor3 = Color3.fromRGB(60, 240, 140)
	resLabel.Font = Enum.Font.GothamBlack
	resLabel.TextSize = 22
	resLabel.ZIndex = 32
	resLabel.Parent = result

	return screenGui
end

function PianoUI.Create()
	local playerGui = getPlayerGui()
	if not playerGui then return false end

	local existing = playerGui:FindFirstChild("PianoTilesGui")
	if existing then
		existing:Destroy()
	end
	gui = buildDynamicGui(playerGui)
	if not gui then return false end

	arenaContainer = gui:FindFirstChild("ArenaContainer")
	if not arenaContainer then return false end

	arenaFrame = arenaContainer:FindFirstChild("ArenaFrame")
	if not arenaFrame then return false end

	hitLine = arenaFrame:FindFirstChild("HitLine")
	perfectZoneGuide = arenaFrame:FindFirstChild("PerfectZoneGuide")
	centerJudgementLabel = arenaFrame:FindFirstChild("CenterJudgementLabel")

	table.clear(columns)
	table.clear(columnFlashes)
	table.clear(receptorPads)
	table.clear(receptorLabels)

	for i = 1, Config.COLUMN_COUNT do
		local col = arenaFrame:WaitForChild("Column" .. i, 3)
		if col then
			columns[i] = col
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

			local receptor = col:FindFirstChild("ReceptorPad")
			if receptor then
				receptorPads[i] = receptor
				receptorLabels[i] = receptor:FindFirstChild("KeyLabel")
			end
		end
	end

	local header = arenaContainer:FindFirstChild("Header")
	if header then
		castBonusLabel = header:FindFirstChild("CastBonusLabel", true)
		songLabel = header:FindFirstChild("SongLabel", true)
		comboLabel = header:FindFirstChild("ComboLabel", true)
	end

	progressContainer = arenaContainer:FindFirstChild("ProgressBar")
	if progressContainer then
		progressFill = progressContainer:FindFirstChild("Fill")
		fish = progressContainer:FindFirstChild("Fish")
		progressGlow = progressContainer:FindFirstChild("UIStroke")
	end
	progressLabel = arenaContainer:FindFirstChild("ProgressLabel")

	resultOverlay = arenaContainer:FindFirstChild("ResultOverlay")
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

	local tile = Instance.new("ImageLabel")
	tile.Name = "Tile"
	tile.Size = UDim2.new(0.88, 0, Config.TILE_HEIGHT, 0)
	tile.Position = UDim2.new(0.06, 0, y, 0)
	tile.BackgroundTransparency = 1
	tile.Image = Config.TILE_IMAGES[column]
	tile.ScaleType = Enum.ScaleType.Fit
	tile.BorderSizePixel = 0
	tile.ZIndex = 15
	tile.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = tile
	return tile
end

function PianoUI.MoveTile(tile, y)
	if tile and tile.Parent then
		tile.Position = UDim2.new(0.06, 0, y, 0)
	end
end

function PianoUI.DestroyTile(tile)
	if tile and tile.Parent then tile:Destroy() end
end

function PianoUI.TriggerReceptorPress(column, ratingKey)
	local pad = receptorPads[column]
	if not pad then return end

	local ratingData = Config.HIT_RATINGS[ratingKey or "GOOD"] or Config.HIT_RATINGS.GOOD
	pad.BackgroundColor3 = ratingData.flashColor
	pad.BackgroundTransparency = 0.35

	TweenService:Create(pad, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(0, 160, 255),
		BackgroundTransparency = 0.85,
	}):Play()
end

function PianoUI.ShowHitRating(ratingKey, column, y)
	if not arenaFrame then return end
	local ratingData = Config.HIT_RATINGS[ratingKey or "GOOD"] or Config.HIT_RATINGS.GOOD

	if centerJudgementLabel then
		centerJudgementLabel.Text = ratingData.symbol
		centerJudgementLabel.TextColor3 = ratingData.color
		centerJudgementLabel.TextTransparency = 0
		TweenService:Create(centerJudgementLabel, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = math.floor(27 * ratingData.scale)
		}):Play()

		task.delay(0.42, function()
			if centerJudgementLabel and centerJudgementLabel.Text == ratingData.symbol then
				TweenService:Create(centerJudgementLabel, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 1
				}):Play()
			end
		end)
	end

	local posX = column and ((column - 0.5) / Config.COLUMN_COUNT) or 0.5
	local posY = (y or Config.HIT_LINE) - 0.08

	local popup = Instance.new("TextLabel")
	popup.Name = "HitRatingPopup"
	popup.Size = UDim2.new(0, 130, 0, 34)
	popup.Position = UDim2.new(posX, 0, posY, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBlack
	popup.Text = ratingData.symbol
	popup.TextColor3 = ratingData.color
	popup.TextSize = math.floor(13 * ratingData.scale)
	popup.ZIndex = 50
	popup.Parent = arenaFrame

	local popTween = TweenService:Create(popup, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = math.floor(19 * ratingData.scale),
		Position = UDim2.new(posX, 0, posY - 0.03, 0),
	})
	popTween:Play()
	popTween.Completed:Once(function()
		local floatTween = TweenService:Create(popup, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(posX, 0, posY - 0.09, 0),
			TextTransparency = 1,
		})
		floatTween:Play()
		floatTween.Completed:Once(function()
			if popup and popup.Parent then popup:Destroy() end
		end)
	end)
end

function PianoUI.PlayHitEffect(tile, y, ratingKey, column)
	if column then
		PianoUI.TriggerReceptorPress(column, ratingKey)
		PianoUI.FlashColumn(column, ratingKey)
	end
	PianoUI.ShowHitRating(ratingKey, column, y)

	if tile and tile.Parent then
		local tween = TweenService:Create(tile, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
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
	local ratingData = Config.HIT_RATINGS[ratingKey or "MISS"] or Config.HIT_RATINGS.MISS

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
			comboLabel.Text = string.format("🔥 COMBO x%d", combo)
			comboLabel.Visible = true
		else
			comboLabel.Visible = false
		end
	end

	if progressFill then
		local percent = math.clamp(progress or 0, 0, 1)
		TweenService:Create(progressFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(percent, 1)
		}):Play()

		if fish and progressContainer then
			TweenService:Create(fish, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(percent, -12, 0.5, -12)
			}):Play()
		end
	end

	if progressLabel then
		local percent = math.floor(math.clamp(progress or 0, 0, 1) * 100)
		if liveMetrics and liveMetrics.accuracy then
			progressLabel.Text = string.format("🎣 Progres: %d%%  •  %d/%d Not  •  🎯 Akurasi: %.1f%%", percent, currentNotes or 0, targetNotes or 0, liveMetrics.accuracy)
		else
			progressLabel.Text = string.format("🎣 Progres: %d%%  •  %d/%d Not", percent, currentNotes or 0, targetNotes or 0)
		end
	end
end

function PianoUI.UpdateHeader(castLabel, castColor, melodyName)
	if castBonusLabel then
		castBonusLabel.Text = "✨ " .. tostring(castLabel or "PERFECT CAST")
		castBonusLabel.TextColor3 = castColor or Color3.fromRGB(60, 255, 150)
	end
	if songLabel then
		songLabel.Text = "🎵 " .. tostring(melodyName or "Melodi Piano")
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
