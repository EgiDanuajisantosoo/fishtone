--[[
    PianoTilesUI
    FISH!TUNE — Piano Tiles Minigame UI & Visual Hit Feedback (FISH-013)

    Menyediakan rendering antarmuka Piano Tiles, visual timing feedback
    (PERFECT, GREAT, GOOD, MISS), floating judgement badges, dynamic column flashes,
    hit line ripples, serta layar hasil akhir dengan grade & multiplier.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(
	Shared:WaitForChild("Config"):WaitForChild("PianoTilesConfig")
)
local PerformanceCalculator = require(
	Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator")
)

local PianoTilesUI = {}

--==================================================
-- REFERENCES
--==================================================

local gui
local arenaContainer
local arenaFrame

local castBonusLabel
local songLabel
local comboLabel
local centerJudgementLabel
local hitLine

local resultOverlay
local resultLabel
local gradeBadgeLabel
local gradeTitleLabel
local statsDetailLabel
local multiplierDetailLabel

local progressContainer
local progressFill
local progressLabel
local progressGlow
local fish

local columns = {}
local columnFlashes = {}

--==================================================
-- PLAYER GUI
--==================================================

local function getPlayerGui()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	return player:FindFirstChild("PlayerGui")
		or player:WaitForChild("PlayerGui", 5)
end

--==================================================
-- DYNAMIC FALLBACK GUI BUILDER
--==================================================

local function buildDynamicGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PianoTilesGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Arena Container
	local container = Instance.new("Frame")
	container.Name = "ArenaContainer"
	container.Size = UDim2.new(0, 360, 0, 500)
	container.Position = UDim2.new(0.5, -180, 0.5, -250)
	container.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	container.BackgroundTransparency = 0.20
	container.BorderSizePixel = 0
	container.Parent = screenGui
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(0, 200, 255)
	cStroke.Thickness = 2
	cStroke.Transparency = 0.3
	cStroke.Parent = container

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundTransparency = 1
	header.Parent = container

	local castBonus = Instance.new("TextLabel")
	castBonus.Name = "CastBonusLabel"
	castBonus.Size = UDim2.new(0.48, 0, 0, 24)
	castBonus.Position = UDim2.new(0.04, 0, 0, 6)
	castBonus.BackgroundTransparency = 1
	castBonus.Text = "PERFECT CAST"
	castBonus.TextColor3 = Color3.fromRGB(50, 255, 140)
	castBonus.Font = Enum.Font.GothamBlack
	castBonus.TextSize = 13
	castBonus.TextXAlignment = Enum.TextXAlignment.Left
	castBonus.Parent = header

	local song = Instance.new("TextLabel")
	song.Name = "SongLabel"
	song.Size = UDim2.new(0.48, 0, 0, 24)
	song.Position = UDim2.new(0.48, 0, 0, 6)
	song.BackgroundTransparency = 1
	song.Text = "Melodi: Canon in D"
	song.TextColor3 = Color3.fromRGB(200, 230, 255)
	song.Font = Enum.Font.GothamMedium
	song.TextSize = 11
	song.TextXAlignment = Enum.TextXAlignment.Right
	song.Parent = header

	local combo = Instance.new("TextLabel")
	combo.Name = "ComboLabel"
	combo.Size = UDim2.new(1, 0, 0, 22)
	combo.Position = UDim2.new(0, 0, 0, 28)
	combo.BackgroundTransparency = 1
	combo.Text = "COMBO x0"
	combo.TextColor3 = Color3.fromRGB(255, 215, 0)
	combo.Font = Enum.Font.GothamBlack
	combo.TextSize = 15
	combo.Visible = false
	combo.Parent = header

	-- Arena Frame
	local arena = Instance.new("Frame")
	arena.Name = "ArenaFrame"
	arena.Size = UDim2.new(0.92, 0, 0.67, 0)
	arena.Position = UDim2.new(0.04, 0, 0, 56)
	arena.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
	arena.BackgroundTransparency = 0.4
	arena.BorderSizePixel = 0
	arena.ClipsDescendants = true
	arena.Parent = container
	Instance.new("UICorner", arena).CornerRadius = UDim.new(0, 10)

	-- 4 Columns
	for i = 1, Config.COLUMN_COUNT do
		local col = Instance.new("Frame")
		col.Name = "Column" .. i
		col.Size = UDim2.new(1 / Config.COLUMN_COUNT, 0, 1, 0)
		col.Position = UDim2.new((i - 1) / Config.COLUMN_COUNT, 0, 0, 0)
		col.BackgroundTransparency = (i % 2 == 0) and 0.95 or 1
		col.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		col.BorderSizePixel = 0
		col.Parent = arena
	end

	-- Keybind Guide Label bar
	local keyLabels = Config.KEY_LABELS or { "A", "W", "S", "D" }
	for i = 1, Config.COLUMN_COUNT do
		local keyLbl = Instance.new("TextLabel")
		keyLbl.Name = "Key_" .. i
		keyLbl.Size = UDim2.new(1 / Config.COLUMN_COUNT, 0, 0, 24)
		keyLbl.Position = UDim2.new((i - 1) / Config.COLUMN_COUNT, 0, Config.HIT_LINE - 0.02, 0)
		keyLbl.BackgroundTransparency = 1
		keyLbl.Text = "[" .. (keyLabels[i] or tostring(i)) .. "]"
		keyLbl.TextColor3 = Color3.fromRGB(180, 210, 240)
		keyLbl.Font = Enum.Font.GothamBold
		keyLbl.TextSize = 12
		keyLbl.Parent = arena
	end

	-- HitLine
	local hLine = Instance.new("Frame")
	hLine.Name = "HitLine"
	hLine.Size = UDim2.new(1, 0, 0, 4)
	hLine.Position = UDim2.new(0, 0, Config.HIT_LINE + 0.05, 0)
	hLine.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	hLine.BorderSizePixel = 0
	hLine.ZIndex = 12
	hLine.Parent = arena

	local hLineStroke = Instance.new("UIStroke")
	hLineStroke.Color = Color3.fromRGB(150, 240, 255)
	hLineStroke.Thickness = 1.5
	hLineStroke.Transparency = 0.4
	hLineStroke.Parent = hLine

	-- Center Judgement Feedback Label (Large animated timing banner)
	local centerJudge = Instance.new("TextLabel")
	centerJudge.Name = "CenterJudgementLabel"
	centerJudge.Size = UDim2.new(0.9, 0, 0, 36)
	centerJudge.Position = UDim2.new(0.5, 0, Config.HIT_LINE - 0.16, 0)
	centerJudge.AnchorPoint = Vector2.new(0.5, 0.5)
	centerJudge.BackgroundTransparency = 1
	centerJudge.Font = Enum.Font.GothamBlack
	centerJudge.TextSize = 22
	centerJudge.TextColor3 = Color3.fromRGB(255, 215, 0)
	centerJudge.Text = ""
	centerJudge.ZIndex = 35
	centerJudge.Parent = arena

	local judgeStroke = Instance.new("UIStroke")
	judgeStroke.Thickness = 2
	judgeStroke.Color = Color3.fromRGB(0, 0, 0)
	judgeStroke.Transparency = 0.3
	judgeStroke.Parent = centerJudge

	-- Progress Bar Container
	local pBar = Instance.new("Frame")
	pBar.Name = "ProgressBar"
	pBar.Size = UDim2.new(0.92, 0, 0, 16)
	pBar.Position = UDim2.new(0.04, 0, 0.83, 0)
	pBar.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
	pBar.BorderSizePixel = 0
	pBar.Parent = container
	Instance.new("UICorner", pBar).CornerRadius = UDim.new(0, 8)

	local pFill = Instance.new("Frame")
	pFill.Name = "Fill"
	pFill.Size = UDim2.new(0.1, 0, 1, 0)
	pFill.Position = UDim2.new(0, 0, 0, 0)
	pFill.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	pFill.BorderSizePixel = 0
	pFill.Parent = pBar
	Instance.new("UICorner", pFill).CornerRadius = UDim.new(0, 8)

	local fishIcon = Instance.new("TextLabel")
	fishIcon.Name = "Fish"
	fishIcon.Size = UDim2.new(0, 22, 0, 22)
	fishIcon.Position = UDim2.new(0.1, -11, 0.5, -11)
	fishIcon.BackgroundTransparency = 1
	fishIcon.Text = "🐟"
	fishIcon.TextSize = 15
	fishIcon.Parent = pBar

	local pLabel = Instance.new("TextLabel")
	pLabel.Name = "ProgressLabel"
	pLabel.Size = UDim2.new(0.92, 0, 0, 20)
	pLabel.Position = UDim2.new(0.04, 0, 0.89, 0)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "0% Completed, 0 / 30 Notes"
	pLabel.TextColor3 = Color3.fromRGB(200, 225, 255)
	pLabel.Font = Enum.Font.GothamMedium
	pLabel.TextSize = 12
	pLabel.Parent = container

	-- Result Overlay
	local result = Instance.new("Frame")
	result.Name = "ResultOverlay"
	result.Size = UDim2.fromScale(1, 1)
	result.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	result.BackgroundTransparency = 0.15
	result.BorderSizePixel = 0
	result.Visible = false
	result.ZIndex = 25
	result.Parent = container
	Instance.new("UICorner", result).CornerRadius = UDim.new(0, 16)

	local resLabel = Instance.new("TextLabel")
	resLabel.Name = "ResultLabel"
	resLabel.Size = UDim2.new(1, 0, 0, 36)
	resLabel.Position = UDim2.new(0, 0, 0.14, 0)
	resLabel.BackgroundTransparency = 1
	resLabel.Text = "BERHASIL DITANGKAP!"
	resLabel.TextColor3 = Color3.fromRGB(60, 240, 140)
	resLabel.Font = Enum.Font.GothamBlack
	resLabel.TextSize = 22
	resLabel.ZIndex = 26
	resLabel.Parent = result

	return screenGui
end

--==================================================
-- CREATE / LOAD UI
--==================================================

function PianoTilesUI.Create()
	local playerGui = getPlayerGui()
	if not playerGui then
		warn("[PianoTilesUI] PlayerGui tidak ditemukan.")
		return false
	end

	-- Ambil GUI dari StarterGui yang sudah di-clone, atau bangun fallback secara dinamis
	gui = playerGui:FindFirstChild("PianoTilesGui")
	if not gui then
		gui = buildDynamicGui(playerGui)
	end

	if not gui then
		warn("[PianoTilesUI] Gagal menginisialisasi PianoTilesGui.")
		return false
	end

	arenaContainer = gui:FindFirstChild("ArenaContainer") or gui:WaitForChild("ArenaContainer", 3)
	if not arenaContainer then
		warn("[PianoTilesUI] ArenaContainer tidak ditemukan.")
		return false
	end

	arenaFrame = arenaContainer:FindFirstChild("ArenaFrame") or arenaContainer:WaitForChild("ArenaFrame", 3)
	if not arenaFrame then
		warn("[PianoTilesUI] ArenaFrame tidak ditemukan.")
		return false
	end

	--==================================================
	-- HITLINE & JUDGEMENT LABELS
	--==================================================
	hitLine = arenaFrame:FindFirstChild("HitLine")

	centerJudgementLabel = arenaFrame:FindFirstChild("CenterJudgementLabel")
	if not centerJudgementLabel then
		centerJudgementLabel = Instance.new("TextLabel")
		centerJudgementLabel.Name = "CenterJudgementLabel"
		centerJudgementLabel.Size = UDim2.new(0.9, 0, 0, 36)
		centerJudgementLabel.Position = UDim2.new(0.5, 0, Config.HIT_LINE - 0.16, 0)
		centerJudgementLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		centerJudgementLabel.BackgroundTransparency = 1
		centerJudgementLabel.Font = Enum.Font.GothamBlack
		centerJudgementLabel.TextSize = 22
		centerJudgementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		centerJudgementLabel.Text = ""
		centerJudgementLabel.ZIndex = 35
		centerJudgementLabel.Parent = arenaFrame

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Transparency = 0.3
		stroke.Parent = centerJudgementLabel
	end

	--==================================================
	-- COLUMNS & FLASHES
	--==================================================
	table.clear(columns)
	table.clear(columnFlashes)

	for i = 1, Config.COLUMN_COUNT do
		local column = arenaFrame:WaitForChild("Column" .. i, 5)
		if not column then
			warn("[PianoTilesUI] Column" .. i .. " tidak ditemukan.")
			return false
		end

		columns[i] = column

		-- Flash Frame (mendukung warna Gold, Cyan, Green, Red)
		local flash = column:FindFirstChild("ColumnFlash") or column:FindFirstChild("MissFlash")
		if not flash then
			flash = Instance.new("Frame")
			flash.Name = "ColumnFlash"
			flash.Size = UDim2.fromScale(1, 1)
			flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			flash.BackgroundTransparency = 1
			flash.BorderSizePixel = 0
			flash.Visible = false
			flash.ZIndex = 20
			flash.Parent = column
		end

		columnFlashes[i] = flash
	end

	--==================================================
	-- HEADER
	--==================================================
	local header = arenaContainer:WaitForChild("Header", 5)
	if header then
		castBonusLabel = header:WaitForChild("CastBonusLabel", 5)
		songLabel = header:WaitForChild("SongLabel", 5)
		comboLabel = header:WaitForChild("ComboLabel", 5)
	else
		warn("[PianoTilesUI] Header tidak ditemukan.")
	end

	--==================================================
	-- PROGRESS
	--==================================================
	progressContainer = arenaContainer:WaitForChild("ProgressBar", 5)
	if progressContainer then
		progressFill = progressContainer:WaitForChild("Fill", 5)
		fish = progressContainer:FindFirstChild("Fish")
		progressGlow = progressContainer:FindFirstChild("UIStroke")
	end

	progressLabel = arenaContainer:WaitForChild("ProgressLabel", 5)

	--==================================================
	-- RESULT
	--==================================================
	resultOverlay = arenaContainer:WaitForChild("ResultOverlay", 5)
	if resultOverlay then
		resultLabel = resultOverlay:WaitForChild("ResultLabel", 5)
	end

	--==================================================
	-- INITIAL STATE
	--==================================================
	gui.Enabled = false

	if centerJudgementLabel then
		centerJudgementLabel.Text = ""
	end

	if comboLabel then
		comboLabel.Visible = false
	end

	if resultOverlay then
		resultOverlay.Visible = false
	end

	return true
end

--==================================================
-- GETTERS
--==================================================

function PianoTilesUI.GetGui()
	return gui
end

function PianoTilesUI.GetArenaFrame()
	return arenaFrame
end

function PianoTilesUI.GetArenaContainer()
	return arenaContainer
end

function PianoTilesUI.GetColumns()
	return columns
end

function PianoTilesUI.GetHeaderElements()
	return {
		castBonusLabel = castBonusLabel,
		songLabel = songLabel,
		comboLabel = comboLabel,
	}
end

function PianoTilesUI.GetProgressElements()
	return {
		container = progressContainer,
		fill = progressFill,
		label = progressLabel,
		glow = progressGlow,
	}
end

function PianoTilesUI.GetResultElements()
	return {
		overlay = resultOverlay,
		label = resultLabel,
	}
end

--==================================================
-- ENABLE
--==================================================

function PianoTilesUI.SetEnabled(enabled)
	if gui then
		gui.Enabled = enabled
	end
end

--==================================================
-- TILE CREATION & MOVEMENT
--==================================================

function PianoTilesUI.CreateTile(column, y)
	local parent = columns[column]
	if not parent then
		return nil
	end

	local tile = Instance.new("ImageLabel")
	tile.Name = "Tile"
	tile.Size = UDim2.new(0.88, 0, Config.TILE_HEIGHT, 0)
	tile.Position = UDim2.new(0.06, 0, y, 0)
	tile.BackgroundTransparency = 1
	tile.Image = Config.TILE_IMAGES[column]
	tile.ScaleType = Enum.ScaleType.Fit
	tile.BorderSizePixel = 0
	tile.ZIndex = 5
	tile.Parent = parent

	-- Menjaga tile berbentuk square
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Name = "SquareConstraint"
	aspect.AspectRatio = 1
	aspect.Parent = tile

	return tile
end

function PianoTilesUI.MoveTile(tile, y)
	if tile and tile.Parent then
		tile.Position = UDim2.new(0.06, 0, y, 0)
	end
end

function PianoTilesUI.DestroyTile(tile)
	if tile and tile.Parent then
		tile:Destroy()
	end
end

--==================================================
-- TIMING JUDGEMENT FEEDBACK (PERFECT / GREAT / GOOD / MISS)
--==================================================

function PianoTilesUI.ShowHitRating(ratingKey, column, y)
	if not arenaFrame then return end

	ratingKey = ratingKey or "GOOD"
	local ratingData = (Config.HIT_RATINGS and Config.HIT_RATINGS[ratingKey]) or {
		text = ratingKey,
		symbol = ratingKey,
		color = Color3.fromRGB(80, 235, 120),
		glowColor = Color3.fromRGB(180, 255, 200),
		flashColor = Color3.fromRGB(70, 220, 110),
		score = 80,
		scale = 1.0,
	}

	-- 1. Update Center Judgement Banner
	if centerJudgementLabel then
		centerJudgementLabel.Text = ratingData.symbol
		centerJudgementLabel.TextColor3 = ratingData.color
		centerJudgementLabel.TextTransparency = 0

		local stroke = centerJudgementLabel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = ratingData.glowColor
			stroke.Transparency = 0.15
		end

		-- Punchy pop bounce animation
		centerJudgementLabel.TextSize = math.floor(18 * ratingData.scale)
		TweenService:Create(
			centerJudgementLabel,
			TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = math.floor(25 * ratingData.scale) }
		):Play()

		-- Fade out automatically
		task.delay(0.40, function()
			if centerJudgementLabel and centerJudgementLabel.Text == ratingData.symbol then
				TweenService:Create(
					centerJudgementLabel,
					TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 1 }
				):Play()
			end
		end)
	end

	-- 2. Floating Popup Badge above Column Hit Position
	local posX = column and ((column - 0.5) / Config.COLUMN_COUNT) or 0.5
	local posY = (y or Config.HIT_LINE) - 0.04

	local popup = Instance.new("TextLabel")
	popup.Name = "HitRatingPopup"
	popup.Size = UDim2.new(0, 120, 0, 32)
	popup.Position = UDim2.new(posX, 0, posY, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBlack
	popup.Text = ratingData.symbol
	popup.TextColor3 = ratingData.color
	popup.TextSize = math.floor(12 * ratingData.scale)
	popup.ZIndex = 45
	popup.Parent = arenaFrame

	local pStroke = Instance.new("UIStroke")
	pStroke.Thickness = 2
	pStroke.Color = ratingData.glowColor
	pStroke.Transparency = 0.2
	pStroke.Parent = popup

	-- Score badge indicator (+300, +180, +80)
	if ratingData.score and ratingData.score > 0 then
		local scoreLabel = Instance.new("TextLabel")
		scoreLabel.Name = "ScoreBadge"
		scoreLabel.Size = UDim2.new(1, 0, 0, 14)
		scoreLabel.Position = UDim2.new(0, 0, 1, -2)
		scoreLabel.BackgroundTransparency = 1
		scoreLabel.Font = Enum.Font.GothamBold
		scoreLabel.Text = string.format("+%d", ratingData.score)
		scoreLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
		scoreLabel.TextSize = 11
		scoreLabel.ZIndex = 46
		scoreLabel.Parent = popup
	end

	-- Scale Pop-in & Upward Float Animation
	local popTween = TweenService:Create(
		popup,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			TextSize = math.floor(18 * ratingData.scale),
			Position = UDim2.new(posX, 0, posY - 0.02, 0),
		}
	)
	popTween:Play()

	popTween.Completed:Once(function()
		local floatTween = TweenService:Create(
			popup,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(posX, 0, posY - 0.07, 0),
				TextTransparency = 1,
			}
		)
		if pStroke then
			TweenService:Create(
				pStroke,
				TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			):Play()
		end
		for _, child in ipairs(popup:GetChildren()) do
			if child:IsA("TextLabel") then
				TweenService:Create(
					child,
					TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 1 }
				):Play()
			end
		end

		floatTween:Play()
		floatTween.Completed:Once(function()
			if popup and popup.Parent then
				popup:Destroy()
			end
		end)
	end)

	-- 3. Hit Ripple / Expanding Shockwave Effect
	local ripple = Instance.new("Frame")
	ripple.Name = "HitRipple"
	ripple.Size = UDim2.new(0, 16, 0, 16)
	ripple.Position = UDim2.new(posX, 0, y or Config.HIT_LINE, 0)
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.BackgroundColor3 = ratingData.flashColor
	ripple.BackgroundTransparency = 0.45
	ripple.BorderSizePixel = 0
	ripple.ZIndex = 25
	ripple.Parent = arenaFrame
	Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = ratingData.glowColor
	rStroke.Thickness = 2
	rStroke.Transparency = 0.2
	rStroke.Parent = ripple

	TweenService:Create(
		ripple,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 68, 0, 68),
			BackgroundTransparency = 1,
		}
	):Play()
	TweenService:Create(
		rStroke,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1, Thickness = 0.5 }
	):Play()

	task.delay(0.24, function()
		if ripple and ripple.Parent then
			ripple:Destroy()
		end
	end)

	-- 4. HitLine Glow Reaction
	if hitLine then
		hitLine.BackgroundColor3 = ratingData.flashColor
		TweenService:Create(
			hitLine,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Color3.fromRGB(0, 220, 255) }
		):Play()
	end
end

--==================================================
-- HIT EFFECT (TILE + RATING + FLASH)
--==================================================

function PianoTilesUI.PlayHitEffect(tile, y, ratingKey, column)
	ratingKey = ratingKey or "GOOD"
	column = column or (tile and tile.Parent and tonumber(string.match(tile.Parent.Name, "%d+")))

	-- Trigger Rating Popup & Column Flash
	PianoTilesUI.ShowHitRating(ratingKey, column, y)
	if column then
		PianoTilesUI.FlashColumn(column, ratingKey)
	end

	if not tile or not tile.Parent then
		return
	end

	local tween = TweenService:Create(
		tile,
		TweenInfo.new(
			0.14,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			ImageTransparency = 1,
			Size = UDim2.new(
				0.98,
				0,
				Config.TILE_HEIGHT * 1.25,
				0
			),
			Position = UDim2.new(
				0.01,
				0,
				y - 0.02,
				0
			),
		}
	)

	tween:Play()
	tween.Completed:Once(function()
		if tile and tile.Parent then
			tile:Destroy()
		end
	end)
end

--==================================================
-- COLUMN FLASH WITH JUDGEMENT COLORS
--==================================================

function PianoTilesUI.FlashColumn(column, ratingKey)
	local flash = columnFlashes[column]
	if not flash then
		return
	end

	ratingKey = ratingKey or "MISS"
	local ratingData = (Config.HIT_RATINGS and Config.HIT_RATINGS[ratingKey]) or {
		flashColor = (ratingKey == "MISS" and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 215, 0))
	}

	flash.BackgroundColor3 = ratingData.flashColor
	flash.BackgroundTransparency = (ratingKey == "MISS" and 0.40 or 0.60)
	flash.Visible = true

	local tween = TweenService:Create(
		flash,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()

	task.delay(0.20, function()
		if flash and flash.Parent then
			flash.Visible = false
		end
	end)
end

--==================================================
-- HUD UPDATE
--==================================================

function PianoTilesUI.UpdateHUD(
	progress,
	combo,
	currentNotes, 
	targetNotes,
	liveMetrics
)
	-- 1. COMBO BADGE WITH DYNAMIC COLORS & SCALE BOUNCE
	if comboLabel then
		if combo and combo >= 2 then
			local comboColor = Color3.fromRGB(80, 235, 120) -- Emerald Green
			local comboPrefix = "COMBO"

			if combo >= 10 then
				comboColor = Color3.fromRGB(255, 215, 0) -- Gold
				comboPrefix = "🔥 COMBO"
			elseif combo >= 5 then
				comboColor = Color3.fromRGB(0, 230, 255) -- Cyan
				comboPrefix = "✨ COMBO"
			end

			comboLabel.Text = string.format("%s x%d", comboPrefix, combo)
			comboLabel.TextColor3 = comboColor
			comboLabel.Visible = true

			-- Pop animation
			comboLabel.TextSize = 13
			TweenService:Create(
				comboLabel,
				TweenInfo.new(0.09, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ TextSize = 16 }
			):Play()
		else
			comboLabel.Visible = false
		end
	end

	-- 2. PROGRESS BAR & FISH
	if progressFill then
		local percent = math.clamp(progress or 0, 0, 1)
		
		progressFill.AnchorPoint = Vector2.new(0, 0)
		progressFill.Position = UDim2.fromScale(0, 0)

		TweenService:Create(
			progressFill,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(percent, 1) }
		):Play()

		local barColor = Color3.fromRGB(0, 220, 255)
		if percent >= 0.75 then
			barColor = Color3.fromRGB(60, 240, 140) -- Emerald
		elseif percent <= 0.25 then
			barColor = Color3.fromRGB(255, 180, 50) -- Amber warning
		end

		progressFill.BackgroundColor3 = barColor

		if progressGlow then
			progressGlow.Color = barColor
		end
		
		if fish and progressContainer then
			TweenService:Create(
				fish,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(percent, -11, 0.5, -11) }
			):Play()
		end
	end

	-- 3. PROGRESS & LIVE ACCURACY LABEL
	if progressLabel then
		local percent = math.clamp(progress or 0, 0, 1)
		local percentInt = math.floor(percent * 100)

		if liveMetrics and liveMetrics.accuracy then
			progressLabel.Text = string.format(
				"%d%% Ditangkap  •  %d/%d Notes  •  🎯 %.0f%% Akurasi",
				percentInt,
				currentNotes or 0,
				targetNotes or 0,
				liveMetrics.accuracy
			)
		else
			progressLabel.Text = string.format(
				"%d%% Selesai  •  %d / %d Notes",
				percentInt,
				currentNotes or 0,
				targetNotes or 0
			)
		end
	end
end

--==================================================
-- HEADER
--==================================================

function PianoTilesUI.UpdateHeader(
	castLabel,
	castColor,
	melodyName
)
	if castBonusLabel then
		castBonusLabel.Text = castLabel or ""
		castBonusLabel.TextColor3 = castColor or Color3.fromRGB(255, 255, 255)
	end

	if songLabel then
		songLabel.Text = "Melodi: " .. tostring(melodyName or "")
	end
end

--==================================================
-- SHAKE
--==================================================

function PianoTilesUI.ShakeArena()
	if not arenaContainer then
		return
	end

	local originalPosition = arenaContainer.Position

	local shakeTween = TweenService:Create(
		arenaContainer,
		TweenInfo.new(
			0.06,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			3,
			true
		),
		{
			Position = originalPosition + UDim2.new(
				0,
				math.random(-6, 6),
				0,
				math.random(-3, 3)
			)
		}
	)

	shakeTween:Play()

	task.delay(0.2, function()
		if arenaContainer then
			arenaContainer.Position = originalPosition
		end
	end)
end

--==================================================
-- RESULT OVERLAY
--==================================================

local function ensureResultDetails()
	if not resultOverlay then return end

	if not gradeBadgeLabel or gradeBadgeLabel.Parent ~= resultOverlay then
		gradeBadgeLabel = resultOverlay:FindFirstChild("GradeBadgeLabel")
		if not gradeBadgeLabel then
			gradeBadgeLabel = Instance.new("TextLabel")
			gradeBadgeLabel.Name = "GradeBadgeLabel"
			gradeBadgeLabel.Size = UDim2.new(1, 0, 0, 52)
			gradeBadgeLabel.Position = UDim2.new(0, 0, 0.32, 0)
			gradeBadgeLabel.BackgroundTransparency = 1
			gradeBadgeLabel.Font = Enum.Font.GothamBlack
			gradeBadgeLabel.TextSize = 46
			gradeBadgeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			gradeBadgeLabel.Text = "S+"
			gradeBadgeLabel.ZIndex = 30
			gradeBadgeLabel.Parent = resultOverlay
		end
	end

	if not gradeTitleLabel or gradeTitleLabel.Parent ~= resultOverlay then
		gradeTitleLabel = resultOverlay:FindFirstChild("GradeTitleLabel")
		if not gradeTitleLabel then
			gradeTitleLabel = Instance.new("TextLabel")
			gradeTitleLabel.Name = "GradeTitleLabel"
			gradeTitleLabel.Size = UDim2.new(1, 0, 0, 24)
			gradeTitleLabel.Position = UDim2.new(0, 0, 0.54, 0)
			gradeTitleLabel.BackgroundTransparency = 1
			gradeTitleLabel.Font = Enum.Font.GothamBold
			gradeTitleLabel.TextSize = 16
			gradeTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			gradeTitleLabel.Text = "ALL PERFECT"
			gradeTitleLabel.ZIndex = 30
			gradeTitleLabel.Parent = resultOverlay
		end
	end

	if not statsDetailLabel or statsDetailLabel.Parent ~= resultOverlay then
		statsDetailLabel = resultOverlay:FindFirstChild("StatsDetailLabel")
		if not statsDetailLabel then
			statsDetailLabel = Instance.new("TextLabel")
			statsDetailLabel.Name = "StatsDetailLabel"
			statsDetailLabel.Size = UDim2.new(1, -20, 0, 20)
			statsDetailLabel.Position = UDim2.new(0, 10, 0.68, 0)
			statsDetailLabel.BackgroundTransparency = 1
			statsDetailLabel.Font = Enum.Font.GothamMedium
			statsDetailLabel.TextSize = 13
			statsDetailLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
			statsDetailLabel.Text = ""
			statsDetailLabel.ZIndex = 30
			statsDetailLabel.Parent = resultOverlay
		end
	end

	if not multiplierDetailLabel or multiplierDetailLabel.Parent ~= resultOverlay then
		multiplierDetailLabel = resultOverlay:FindFirstChild("MultiplierDetailLabel")
		if not multiplierDetailLabel then
			multiplierDetailLabel = Instance.new("TextLabel")
			multiplierDetailLabel.Name = "MultiplierDetailLabel"
			multiplierDetailLabel.Size = UDim2.new(1, -20, 0, 20)
			multiplierDetailLabel.Position = UDim2.new(0, 10, 0.80, 0)
			multiplierDetailLabel.BackgroundTransparency = 1
			multiplierDetailLabel.Font = Enum.Font.GothamBold
			multiplierDetailLabel.TextSize = 12
			multiplierDetailLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
			multiplierDetailLabel.Text = ""
			multiplierDetailLabel.ZIndex = 30
			multiplierDetailLabel.Parent = resultOverlay
		end
	end
end

function PianoTilesUI.ShowResult(
	win,
	message,
	performance
)
	if not resultOverlay or not resultLabel then
		return
	end

	resultLabel.Text = message or (win and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!")
	resultLabel.TextColor3 = win and Color3.fromRGB(60, 240, 140) or Color3.fromRGB(255, 70, 70)

	ensureResultDetails()

	if performance and gradeBadgeLabel and gradeTitleLabel then
		local gradeColor = performance.gradeColor or PerformanceCalculator.GetGradeColor(performance.grade)
		gradeBadgeLabel.Text = tostring(performance.grade or (win and "A" or "D"))
		gradeBadgeLabel.TextColor3 = gradeColor
		gradeBadgeLabel.Visible = true

		local title = performance.gradeTitle or (performance.isAllPerfect and "ALL PERFECT" or (performance.isFullCombo and "FULL COMBO" or (win and "CLEARED" or "FAILED")))
		gradeTitleLabel.Text = title
		gradeTitleLabel.TextColor3 = performance.glowColor or Color3.fromRGB(255, 255, 255)
		gradeTitleLabel.Visible = true

		if statsDetailLabel then
			local acc = performance.accuracy or 0
			local maxCombo = (performance.breakdown and performance.breakdown.maxCombo) or performance.maxCombo or 0
			local pCount = (performance.breakdown and performance.breakdown.perfect) or performance.perfectHits or 0
			local gCount = (performance.breakdown and performance.breakdown.great) or performance.greatHits or 0
			local okCount = (performance.breakdown and performance.breakdown.good) or performance.goodHits or 0
			local mCount = (performance.breakdown and performance.breakdown.miss) or performance.mistakes or 0

			statsDetailLabel.Text = string.format("🎯 Akurasi: %.1f%%  •  🔥 Max Combo: %d\n[ P: %d  G: %d  OK: %d  M: %d ]", acc, maxCombo, pCount, gCount, okCount, mCount)
			statsDetailLabel.Size = UDim2.new(1, -20, 0, 34)
			statsDetailLabel.Visible = true
		end

		if multiplierDetailLabel then
			if win then
				local xpMult = performance.xpMultiplier or 1.0
				local coinMult = performance.coinMultiplier or 1.0
				local luckBonus = performance.performanceLuckBonus or 0
				multiplierDetailLabel.Text = string.format("⭐ EXP x%.2f  •  💰 Koin x%.2f  •  🍀 +%.1f Luck", xpMult, coinMult, luckBonus)
				multiplierDetailLabel.Visible = true
			else
				multiplierDetailLabel.Visible = false
			end
		end

		-- Animasi TextSize Bounce pada gradeBadge
		gradeBadgeLabel.TextSize = 24
		TweenService:Create(
			gradeBadgeLabel,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = 48 }
		):Play()
	else
		if gradeBadgeLabel then gradeBadgeLabel.Visible = false end
		if gradeTitleLabel then gradeTitleLabel.Visible = false end
		if statsDetailLabel then statsDetailLabel.Visible = false end
		if multiplierDetailLabel then multiplierDetailLabel.Visible = false end
	end

	resultOverlay.Visible = true
end

function PianoTilesUI.HideResult()
	if resultOverlay then
		resultOverlay.Visible = false
	end

	if gradeBadgeLabel then gradeBadgeLabel.Visible = false end
	if gradeTitleLabel then gradeTitleLabel.Visible = false end
	if statsDetailLabel then statsDetailLabel.Visible = false end
	if multiplierDetailLabel then multiplierDetailLabel.Visible = false end
end

--==================================================
-- DESTROY
--==================================================

function PianoTilesUI.Destroy()
	if gui then
		gui.Enabled = false
	end

	gui = nil
	arenaContainer = nil
	arenaFrame = nil

	castBonusLabel = nil
	songLabel = nil
	comboLabel = nil
	centerJudgementLabel = nil
	hitLine = nil

	resultOverlay = nil
	resultLabel = nil
	gradeBadgeLabel = nil
	gradeTitleLabel = nil
	statsDetailLabel = nil
	multiplierDetailLabel = nil

	progressContainer = nil
	progressFill = nil
	progressLabel = nil
	progressGlow = nil
	fish = nil

	table.clear(columns)
	table.clear(columnFlashes)
end

return PianoTilesUI